// Daily job: pulls top Instagram media for real estate hashtags through the
// official Graph API, sorts new videos into formats with Claude, and updates heat.
// TikTok and Facebook have no API for this, so the team adds those links by hand
// (insert into trend_examples with source 'curator' and approved true).
//
// Run it once a day with pg_cron + pg_net (see Backend/README.md) using the service role key.
// Secrets: IG_USER_ID (an Instagram professional account), IG_ACCESS_TOKEN (a long lived
// token with instagram_basic and Instagram Public Content Access), optional IG_HASHTAGS.
import { admin, env, HttpError, safeEqual, serve, json } from "../_shared/http.ts";
import { askClaudeJSON } from "../_shared/claude.ts";

const GRAPH = "https://graph.facebook.com/v21.0";
const DEFAULT_TAGS = ["realestate", "realtor", "realtorlife", "housetour", "justlisted", "firsttimehomebuyer"];

type Media = {
  id: string;
  caption?: string;
  media_type: string;
  permalink: string;
  like_count?: number;
  comments_count?: number;
  timestamp?: string;
};

async function graph<T>(path: string, params: Record<string, string>): Promise<T> {
  const url = new URL(`${GRAPH}/${path}`);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  url.searchParams.set("access_token", env("IG_ACCESS_TOKEN"));
  const res = await fetch(url);
  if (!res.ok) throw new HttpError(502, `Instagram ${path} failed (${res.status}): ${await res.text()}`);
  return await res.json() as T;
}

serve(async (req) => {
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  if (!safeEqual(token, env("SUPABASE_SERVICE_ROLE_KEY"))) throw new HttpError(403, "Internal only");
  const db = admin();
  const report = { fetched: 0, added: 0, classified: 0, errors: [] as string[] };

  // 1. Instagram top media per hashtag.
  if (Deno.env.get("IG_USER_ID") && Deno.env.get("IG_ACCESS_TOKEN")) {
    const userID = env("IG_USER_ID");
    const tags = (Deno.env.get("IG_HASHTAGS") ?? DEFAULT_TAGS.join(",")).split(",").map((t) => t.trim().toLowerCase()).filter(Boolean).slice(0, 10);
    const { data: known } = await db.from("ig_hashtags").select("tag, hashtag_id").in("tag", tags);
    const ids = new Map((known ?? []).map((row) => [row.tag, row.hashtag_id]));
    const since = Date.now() - 14 * 86400_000;

    for (const tag of tags) {
      try {
        let hashtagID = ids.get(tag);
        if (!hashtagID) {
          const found = await graph<{ data: { id: string }[] }>("ig_hashtag_search", { user_id: userID, q: tag });
          hashtagID = found.data?.[0]?.id;
          if (!hashtagID) continue;
          await db.from("ig_hashtags").upsert({ tag, hashtag_id: hashtagID });
        }
        const top = await graph<{ data: Media[] }>(`${hashtagID}/top_media`, {
          user_id: userID,
          fields: "id,caption,media_type,permalink,like_count,comments_count,timestamp",
          limit: "50",
        });
        const videos = (top.data ?? []).filter((m) => m.media_type === "VIDEO" && (!m.timestamp || Date.parse(m.timestamp) > since));
        report.fetched += videos.length;
        if (videos.length === 0) continue;
        const { count } = await db.from("trend_examples").upsert(videos.map((m) => ({
          url: m.permalink,
          platform: "instagram",
          caption: m.caption?.slice(0, 600) ?? null,
          likes: m.like_count ?? null,
          comments: m.comments_count ?? null,
          posted_at: m.timestamp ?? null,
          source: "instagram_api",
          external_id: m.id,
        })), { onConflict: "url", ignoreDuplicates: true, count: "exact" });
        report.added += count ?? 0;
      } catch (error) {
        report.errors.push(`${tag}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  // 2. Sort new examples into formats. Claude also drops anything that isn't a US real estate video.
  const [{ data: pending }, { data: trends }] = await Promise.all([
    db.from("trend_examples").select("id, platform, caption, source").is("classified_at", null).neq("source", "agent").limit(120),
    db.from("trends").select("id, title, format, keywords").eq("active", true),
  ]);

  if (pending?.length && trends?.length) {
    const system = [
      "You sort short form real estate videos into known video formats using only their captions.",
      "keep is true only when the caption is clearly an English language, US based real estate video an agent could learn from.",
      "Drop ads, spam, giveaways, non US listings, and anything about people rather than homes or the process.",
      "trend_id is the best matching format id, or null if none fits well.",
      'Return only JSON: {"results": [{"id", "trend_id", "keep"}]}.',
    ].join("\n");
    const prompt = JSON.stringify({ formats: trends, videos: pending.map((p) => ({ id: p.id, caption: p.caption ?? "" })) });
    try {
      const { results } = await askClaudeJSON<{ results: { id: string; trend_id: string | null; keep: boolean }[] }>({ system, prompt, maxTokens: 6000 });
      const valid = new Set(trends.map((t) => t.id));
      const now = new Date().toISOString();
      for (const r of results ?? []) {
        const trendID = r.trend_id && valid.has(r.trend_id) ? r.trend_id : null;
        await db.from("trend_examples").update({
          trend_id: trendID,
          approved: Boolean(r.keep && trendID),
          classified_at: now,
        }).eq("id", r.id);
        report.classified += 1;
      }
    } catch (error) {
      report.errors.push(`classify: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // 3. Heat from the last 7 days of approved examples.
  await db.rpc("refresh_trend_heat");
  return json(report);
});
