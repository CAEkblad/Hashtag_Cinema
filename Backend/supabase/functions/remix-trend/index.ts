// Writes an agent's own version of a trending video format with Claude:
// their city, optionally one of their listings, and optionally a video they pasted.
import { admin, HttpError, readJSON, requireUser, serve, json } from "../_shared/http.ts";
import { askClaudeJSON } from "../_shared/claude.ts";

type Body = {
  trend_id: string;
  trend_title: string;
  format: string;
  beats: string[];
  example_script: string;
  seconds: number;
  city_id: string;
  listing?: {
    address: string;
    city: string;
    price: number;
    beds: number;
    baths: number;
    square_feet?: number;
    features: string[];
    description: string;
  };
  pasted?: { platform?: string; url: string; caption?: string; creator?: string };
};

type Result = {
  title: string;
  hook: string;
  shots: string[];
  script: string;
  target_seconds: number;
  why_it_works: string;
};

serve(async (req) => {
  const { user } = await requireUser(req);
  const body = await readJSON<Body>(req);
  if (!body.trend_title || !body.format) throw new HttpError(400, "Missing the trend");
  const db = admin();

  const [{ data: profile }, { data: city }] = await Promise.all([
    db.from("profiles").select("name, niche").eq("id", user.id).single(),
    db.from("cities").select("name, county, traits, highlights, neighborhoods").eq("id", body.city_id).maybeSingle(),
  ]);

  // Keep agent pasted links for the team to review as possible examples. Never shown until approved.
  if (body.pasted?.url) {
    await db.from("trend_examples").upsert({
      url: body.pasted.url,
      platform: body.pasted.platform ?? "tiktok",
      caption: body.pasted.caption ?? null,
      creator: body.pasted.creator ?? null,
      source: "agent",
      submitted_by: user.id,
      trend_id: body.trend_id,
    }, { onConflict: "url", ignoreDuplicates: true });
  }

  const system = [
    "You adapt a trending short form video format into one ready to film video for a real estate agent.",
    "Keep the format's structure and pacing. Make every line specific to the agent's city and, if given, their listing.",
    "If a pasted video caption is given, borrow its idea and angle but never copy its wording. Write something original.",
    "Only use facts from the data provided. Where a number or detail is unknown, leave a short [bracket] for the agent to fill in.",
    "Follow fair housing rules: describe homes, places and amenities, never people or who should live somewhere.",
    "The script is spoken, plain words, about the target length, and ends with a comment keyword in capital letters.",
    "Do not use em dashes.",
    'Return only JSON: {"title", "hook", "shots" (3 to 6), "script", "target_seconds", "why_it_works"}.',
  ].join("\n");

  const prompt = JSON.stringify({
    agent: { name: profile?.name, niche: profile?.niche },
    city,
    trend: { title: body.trend_title, format: body.format, beats: body.beats, example_script: body.example_script, seconds: body.seconds },
    listing: body.listing ?? null,
    pasted_video: body.pasted ? { platform: body.pasted.platform, caption: body.pasted.caption } : null,
  });

  const result = await askClaudeJSON<Result>({ system, prompt, maxTokens: 1500 });
  if (!result.script || !result.shots?.length) throw new HttpError(502, "Claude returned an empty script");
  return json({ ...result, target_seconds: result.target_seconds || body.seconds });
});
