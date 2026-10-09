// AI coach notes for a clip. Uses the transcript from the edit pipeline when
// it exists, otherwise coaches from the idea and title.
import { admin, readJSON, requireUser, serve, json } from "../_shared/http.ts";
import { askClaudeJSON } from "../_shared/claude.ts";

type Body = { clip_id?: string; clip_title?: string };
type Tip = { area: string; text: string };
const AREAS = ["hook", "framing", "lighting", "audio", "pacing", "energy"];

serve(async (req) => {
  const { user } = await requireUser(req);
  const body = await readJSON<Body>(req);
  const db = admin();

  let transcript: string | null = null;
  let idea: unknown = null;
  if (body.clip_id) {
    const { data: clip } = await db.from("clips").select("id, title, idea_id, profile_id").eq("id", body.clip_id).single();
    if (clip && clip.profile_id === user.id) {
      const { data: job } = await db.from("edit_jobs").select("transcript").eq("clip_id", clip.id).maybeSingle();
      transcript = job?.transcript ?? null;
      if (clip.idea_id) {
        const { data } = await db.from("ideas").select("title, hook, script, target_seconds").eq("id", clip.idea_id).single();
        idea = data;
      }
    }
  }

  const result = await askClaudeJSON<{ tips: Tip[] }>({
    system: [
      "You are a friendly on-camera coach for real estate agents.",
      "Give exactly 3 short, specific, encouraging tips. Start with what worked.",
      `Each tip has an area from: ${AREAS.join(", ")}.`,
      "No em dashes. Return only JSON: {\"tips\": [{\"area\", \"text\"}]}.",
    ].join("\n"),
    prompt: JSON.stringify({ clip_title: body.clip_title, transcript, idea }),
    maxTokens: 800,
  });

  const tips = (result.tips ?? []).slice(0, 3).map((tip) => ({
    area: AREAS.includes(tip.area) ? tip.area : "hook",
    text: tip.text,
  }));

  await db.from("coach_tips").insert(tips.map((tip) => ({
    profile_id: user.id,
    clip_id: body.clip_id ?? null,
    area: tip.area,
    body: tip.text,
  })));

  return json({ tips });
});
