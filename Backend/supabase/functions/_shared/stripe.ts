// Minimal Stripe REST client (form encoded) and webhook signature check.
import { env, HttpError, hmacHex, safeEqual } from "./http.ts";

function encode(params: Record<string, unknown>, prefix = ""): string[] {
  const parts: string[] = [];
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null) continue;
    const name = prefix ? `${prefix}[${key}]` : key;
    if (Array.isArray(value)) {
      value.forEach((item, index) => {
        if (typeof item === "object") parts.push(...encode(item as Record<string, unknown>, `${name}[${index}]`));
        else parts.push(`${encodeURIComponent(`${name}[${index}]`)}=${encodeURIComponent(String(item))}`);
      });
    } else if (typeof value === "object") {
      parts.push(...encode(value as Record<string, unknown>, name));
    } else {
      parts.push(`${encodeURIComponent(name)}=${encodeURIComponent(String(value))}`);
    }
  }
  return parts;
}

export async function stripe<T>(path: string, params: Record<string, unknown>): Promise<T> {
  const response = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env("STRIPE_SECRET_KEY")}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: encode(params).join("&"),
  });
  const data = await response.json();
  if (!response.ok) throw new HttpError(502, data?.error?.message ?? "Stripe request failed");
  return data as T;
}

/** Verifies the Stripe-Signature header (t=...,v1=...) with a 5 minute tolerance. */
export async function verifyStripeSignature(payload: string, header: string | null): Promise<void> {
  if (!header) throw new HttpError(400, "Missing Stripe-Signature");
  const parts = Object.fromEntries(header.split(",").map((kv) => kv.split("=") as [string, string]));
  const timestamp = parts["t"];
  const signatures = header.split(",").filter((kv) => kv.startsWith("v1=")).map((kv) => kv.slice(3));
  if (!timestamp || signatures.length === 0) throw new HttpError(400, "Bad Stripe-Signature");
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) throw new HttpError(400, "Stale webhook");
  const expected = await hmacHex(env("STRIPE_WEBHOOK_SECRET"), `${timestamp}.${payload}`);
  if (!signatures.some((sig) => safeEqual(sig, expected))) throw new HttpError(400, "Signature mismatch");
}
