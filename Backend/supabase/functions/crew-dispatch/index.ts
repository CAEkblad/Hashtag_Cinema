// #Cinema Crew dispatch: offers a paid booking to the best shooters nearby.
// Higher tiers (Pro, Elite, Legend) see jobs first, then rating, then distance.
// Called by stripe-webhook with the service role key.
import { admin, HttpError, readJSON, serve, json, env, safeEqual } from "../_shared/http.ts";

type Body = { job_id: string; limit?: number };

const SKILL_FOR_SERVICE: Record<string, string> = {
  listing: "listing",
  drone: "drone",
  brandVideo: "brandVideo",
  headshots: "listing",
  podcast: "podcast",
  studio: "brandVideo",
};

serve(async (req) => {
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  if (!safeEqual(token, env("SUPABASE_SERVICE_ROLE_KEY"))) throw new HttpError(403, "Internal only");
  const body = await readJSON<Body>(req);
  const db = admin();

  const { data: job } = await db.from("jobs").select("id, market, job_type, status").eq("id", body.job_id).single();
  if (!job || job.status !== "open") return json({ offered: 0 });

  const { data: city } = await db.from("cities").select("lat, lng").eq("id", job.market).maybeSingle();
  const skill = SKILL_FOR_SERVICE[job.job_type] ?? "listing";

  const { data: shooters } = await db.from("shooters")
    .select("id, name, home_lat, home_lng, rating, tier, skills, shooter_tiers(rank)")
    .eq("status", "active")
    .not("non_solicit_signed_at", "is", null)
    .contains("skills", [skill]);

  const miles = (lat?: number | null, lng?: number | null) => {
    if (!city || lat == null || lng == null) return 50;
    const dLat = Number(city.lat) - lat;
    const dLng = (Number(city.lng) - lng) * Math.cos((lat * Math.PI) / 180);
    return Math.sqrt(dLat * dLat + dLng * dLng) * 69;
  };

  const ranked = (shooters ?? [])
    .map((s) => ({
      id: s.id as string,
      rank: tierRank(s.shooter_tiers),
      rating: Number(s.rating ?? 5),
      distance: miles(s.home_lat as number | null, s.home_lng as number | null),
    }))
    .filter((s) => s.distance <= Number(Deno.env.get("CREW_RADIUS_MILES") ?? "45"))
    .sort((a, b) => b.rank - a.rank || b.rating - a.rating || a.distance - b.distance)
    .slice(0, body.limit ?? 3);

  if (ranked.length === 0) {
    console.warn(`No shooters for job ${job.id} in ${job.market}`);
    return json({ offered: 0 });
  }

  await db.from("job_offers").insert(ranked.map((s) => ({ job_id: job.id, shooter_id: s.id })));
  await db.from("jobs").update({ status: "offered" }).eq("id", job.id);
  // Push notifications to the #Cinema Crew app go here once it ships (APNs via the devices table).
  return json({ offered: ranked.length, shooters: ranked.map((s) => s.id) });
});

/** The embedded tier comes back as an object or a one item array depending on the relation. */
function tierRank(value: unknown): number {
  const tier = Array.isArray(value) ? value[0] : value;
  return typeof tier === "object" && tier && "rank" in tier ? Number((tier as { rank: number }).rank) : 1;
}
