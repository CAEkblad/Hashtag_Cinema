// Starts a Stripe Checkout session for a $500 shoot deposit, a credit pack or a course.
// Partner agents (KW) get their signup discount on credits and courses.
// The deposit is not discounted: it goes toward the shoot.
import { admin, HttpError, readJSON, requireUser, serve, json, env } from "../_shared/http.ts";
import { stripe } from "../_shared/stripe.ts";

type Body = {
  kind: "deposit" | "credits" | "course";
  product_id?: string;
  amount_cents?: number;
  description: string;
  booking?: { service: string; starts_at: string; address?: string; notes?: string };
};

// Prices live on the server so the app cannot change them.
const CREDIT_PACKS: Record<string, { credits: number; cents: number }> = {
  "credits-5": { credits: 5, cents: 15000 },
  "credits-10": { credits: 10, cents: 27500 },
};
const DEPOSIT_CENTS = 50000;

serve(async (req) => {
  const { user, db: userDB } = await requireUser(req);
  const body = await readJSON<Body>(req);
  const db = admin();
  const { data: discount } = await userDB.rpc("my_discount_percent");
  const discountPercent = Number(discount ?? 0);

  let amount: number;
  let metadata: Record<string, string> = { profile_id: user.id, kind: body.kind };

  if (body.kind === "deposit") {
    amount = DEPOSIT_CENTS;
    if (body.booking) {
      const { data: booking, error } = await db.from("bookings").insert({
        profile_id: user.id,
        service: body.booking.service,
        starts_at: body.booking.starts_at,
        address: body.booking.address,
        notes: body.booking.notes,
        status: "depositPending",
        deposit_cents: DEPOSIT_CENTS,
      }).select("id").single();
      if (error) throw new HttpError(400, error.message);
      metadata = { ...metadata, booking_id: booking.id };
    }
  } else if (body.kind === "credits") {
    const pack = CREDIT_PACKS[body.product_id ?? "credits-5"];
    if (!pack) throw new HttpError(400, "Unknown credit pack");
    amount = Math.round(pack.cents * (100 - discountPercent) / 100);
    metadata = { ...metadata, credits: String(pack.credits), product_id: body.product_id ?? "credits-5" };
  } else if (body.kind === "course") {
    if (!body.product_id) throw new HttpError(400, "Missing course");
    const priceCents = Number(Deno.env.get("COURSE_PRICE_CENTS") ?? "19700");
    amount = Math.round(priceCents * (100 - discountPercent) / 100);
    metadata = { ...metadata, product_id: body.product_id };
  } else {
    throw new HttpError(400, "Unknown checkout kind");
  }

  const { data: purchase, error: purchaseError } = await db.from("purchases").insert({
    profile_id: user.id,
    kind: body.kind,
    product_id: body.product_id ?? null,
    amount_cents: amount,
    status: "pending",
  }).select("id").single();
  if (purchaseError) throw new HttpError(400, purchaseError.message);
  metadata = { ...metadata, purchase_id: purchase.id };

  const returnBase = Deno.env.get("CHECKOUT_RETURN_URL") ?? `${env("SUPABASE_URL")}/functions/v1/checkout-done`;
  const session = await stripe<{ id: string; url: string }>("checkout/sessions", {
    mode: "payment",
    customer_email: user.email,
    success_url: `${returnBase}?status=success&session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${returnBase}?status=cancel`,
    line_items: [{
      quantity: 1,
      price_data: {
        currency: "usd",
        unit_amount: amount,
        product_data: { name: body.description || "#Cinema" },
      },
    }],
    metadata,
    payment_intent_data: { metadata },
  });

  await db.from("purchases").update({ stripe_checkout_session: session.id }).eq("id", purchase.id);
  if (metadata.booking_id) {
    await db.from("bookings").update({ stripe_checkout_session: session.id }).eq("id", metadata.booking_id);
  }

  return json({ url: session.url, session_id: session.id, amount_cents: amount, discount_percent: discountPercent });
});
