// Posts or schedules an approved clip to Facebook, Instagram, TikTok and YouTube
// through Ayrshare (one API for all four). Saves the comment keyword so the
// Meta webhook can turn comments into leads.
import { admin, HttpError, readJSON, requireUser, serve, json, env } from "../_shared/http.ts";

type Body = {
  post_id: string;
  clip_id: string;
  platforms: string[];
  caption: string;
  scheduled_for: string;
  post_now: boolean;
  lead_keyword?: string;
  dm_message?: string;
};

serve(async (req) => {
  const { user } = await requireUser(req);
  const body = await readJSON<Body>(req);
  const db = admin();

  const { data: clip } = await db.from("clips").select("id, title, vertical_url, wide_url, profile_id").eq("id", body.clip_id).single();
  if (!clip || clip.profile_id !== user.id) throw new HttpError(404, "Clip not found");
  if (!clip.vertical_url) throw new HttpError(409, "This clip is not finished rendering yet");

  const { data: profile } = await db.from("profiles").select("city_id").eq("id", user.id).single();
  const { data: account } = await db.from("social_accounts").select("provider_profile_key")
    .eq("profile_id", user.id).not("provider_profile_key", "is", null).limit(1).maybeSingle();

  // Deliverables are private: give Ayrshare a signed link that lasts a day.
  const { data: signed } = await db.storage.from("deliverables").createSignedUrl(clip.vertical_url, 60 * 60 * 24);
  const mediaURL = signed?.signedUrl ?? clip.vertical_url;

  const keywordLine = body.lead_keyword ? `\n\nComment ${body.lead_keyword.toUpperCase()} and I will send you the details.` : "";
  const request: Record<string, unknown> = {
    post: `${body.caption}${keywordLine}`,
    platforms: body.platforms,
    mediaUrls: [mediaURL],
    isVideo: true,
    youTubeOptions: { title: clip.title.slice(0, 100), visibility: "public", shorts: true },
  };
  if (!body.post_now) request.scheduleDate = body.scheduled_for;

  const headers: Record<string, string> = {
    Authorization: `Bearer ${env("AYRSHARE_API_KEY")}`,
    "Content-Type": "application/json",
  };
  if (account?.provider_profile_key) headers["Profile-Key"] = account.provider_profile_key;

  const response = await fetch("https://api.ayrshare.com/api/post", { method: "POST", headers, body: JSON.stringify(request) });
  const result = await response.json();
  if (!response.ok || result.status === "error") {
    await db.from("posts").upsert({
      id: body.post_id, profile_id: user.id, clip_id: body.clip_id, platforms: body.platforms, caption: body.caption,
      scheduled_for: body.scheduled_for, status: "failed", lead_keyword: body.lead_keyword ?? null, external_ids: result,
    });
    throw new HttpError(502, result?.message ?? "Posting failed");
  }

  await db.from("posts").upsert({
    id: body.post_id,
    profile_id: user.id,
    clip_id: body.clip_id,
    platforms: body.platforms,
    caption: body.caption,
    scheduled_for: body.post_now ? new Date().toISOString() : body.scheduled_for,
    status: body.post_now ? "posted" : "scheduled",
    lead_keyword: body.lead_keyword?.toUpperCase() ?? null,
    dm_message: body.dm_message ?? null,
    external_ids: result,
    city_id: profile?.city_id ?? null,
  });

  return json({ status: body.post_now ? "posted" : "scheduled" });
});
