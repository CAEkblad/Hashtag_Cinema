// The Trends feed for the app: new formats our team wrote, plus heat and the
// newest approved example videos for every format (built in ones included).
import { admin, requireUser, serve, json } from "../_shared/http.ts";

type TrendRow = {
  id: string;
  title: string;
  format: string;
  platforms: string[];
  hashtags: string[];
  search_phrase: string;
  hook: string;
  why_it_works: string;
  beats: string[];
  script: string;
  seconds: number;
  category: string;
  heat: number;
  uses_listing: boolean;
  keywords: string[];
  audio_tip: string | null;
  updated_at: string;
};

type ExampleRow = {
  trend_id: string;
  platform: string;
  url: string;
  caption: string | null;
  creator: string | null;
  views: number | null;
  likes: number | null;
  comments: number | null;
  thumbnail_url: string | null;
  posted_at: string | null;
};

const PER_TREND = 6;

serve(async (req) => {
  await requireUser(req);
  const db = admin();

  const [{ data: trends }, { data: examples }] = await Promise.all([
    db.from("trends").select("*").eq("active", true).order("sort"),
    db.from("trend_examples")
      .select("trend_id, platform, url, caption, creator, views, likes, comments, thumbnail_url, posted_at")
      .eq("approved", true)
      .not("trend_id", "is", null)
      .gte("created_at", new Date(Date.now() - 45 * 86400_000).toISOString())
      .order("likes", { ascending: false, nullsFirst: false })
      .limit(400),
  ]);

  const byTrend = new Map<string, ExampleRow[]>();
  for (const example of (examples ?? []) as ExampleRow[]) {
    const list = byTrend.get(example.trend_id) ?? [];
    if (list.length < PER_TREND) list.push(example);
    byTrend.set(example.trend_id, list);
  }

  const rows = (trends ?? []) as TrendRow[];
  // A row with its own script and beats is a whole format. Rows for the app's
  // built in formats only carry heat and examples.
  const full = rows.filter((t) => t.script && t.beats?.length).map((t) => ({ ...t, examples: byTrend.get(t.id) ?? [] }));
  const updates = rows.map((t) => ({ id: t.id, heat: t.heat, examples: byTrend.get(t.id) ?? [] }));
  const updatedAt = rows.reduce((latest, t) => (t.updated_at > latest ? t.updated_at : latest), "") || new Date().toISOString();

  return json({ trends: full, updates, updated_at: updatedAt });
});
