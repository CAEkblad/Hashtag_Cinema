// Stripe calls this when a payment finishes. Deploy with --no-verify-jwt.
// Marks the purchase paid (which accrues the market center revenue share),
// confirms deposits and opens a Crew job, adds credits, enrolls in courses.
import { admin, serve, json } from "../_shared/http.ts";
import { verifyStripeSignature } from "../_shared/stripe.ts";

type CheckoutSession = { id: string; metadata: Record<string, string>; amount_total: number; payment_status: string };

serve(async (req) => {
  const payload = await req.text();
  await verifyStripeSignature(payload, req.headers.get("Stripe-Signature"));
  const event = JSON.parse(payload) as { id: string; type: string; data: { object: CheckoutSession } };
  const db = admin();

  // Each event is handled once, even if Stripe retries.
  const { error: duplicate } = await db.from("webhook_events").insert({ id: event.id, source: "stripe", payload: event });
  if (duplicate) return json({ received: true, duplicate: true });

  if (event.type === "checkout.session.completed" && event.data.object.payment_status === "paid") {
    const session = event.data.object;
    const meta = session.metadata ?? {};

    if (meta.purchase_id) {
      await db.from("purchases").update({ status: "paid", amount_cents: session.amount_total }).eq("id", meta.purchase_id);
    }

    if (meta.kind === "deposit" && meta.booking_id) {
      const { data: booking } = await db.from("bookings")
        .update({ status: "depositPaid" }).eq("id", meta.booking_id)
        .select("id, service, profile_id").single();
      if (booking) {
        const { data: profile } = await db.from("profiles").select("market, city_id").eq("id", booking.profile_id).single();
        const rate = Number(Deno.env.get(`SHOOTER_RATE_${booking.service.toUpperCase()}`) ?? Deno.env.get("SHOOTER_RATE_DEFAULT") ?? "15000");
        const { data: job } = await db.from("jobs").insert({
          booking_id: booking.id,
          market: profile?.city_id ?? profile?.market ?? "unknown",
          job_type: booking.service,
          shooter_rate_cents: rate,
        }).select("id").single();
        if (job) {
          // Offer the job to the best nearby shooters.
          await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/crew-dispatch`, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ job_id: job.id }),
          }).catch((error) => console.error("dispatch failed", error));
        }
      }
    }

    if (meta.kind === "credits" && meta.credits) {
      await db.rpc("add_credits", { p_profile: meta.profile_id, p_count: Number(meta.credits) });
    }

    if (meta.kind === "course" && meta.product_id) {
      await db.from("course_enrollments").upsert({ profile_id: meta.profile_id, course_id: meta.product_id });
    }
  }

  await db.from("webhook_events").update({ processed_at: new Date().toISOString() }).eq("id", event.id);
  return json({ received: true });
});
