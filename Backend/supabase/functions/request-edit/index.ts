// Spends credits and queues an edit. AI first cut runs right away; Pro edits
// then go to the next available #Cinema editor (Serbia team) with a due time.
import { admin, HttpError, readJSON, requireUser, serve, json } from "../_shared/http.ts";

type Body = {
  clip_id: string;
  title: string;
  idea_id?: string;
  style: string;
  captions: boolean;
  music: boolean;
  brand_kit: boolean;
  rush: boolean;
  pro_edit: boolean;
  notes: string;
  raw_video_path?: string;
};

serve(async (req) => {
  const { user, db: userDB } = await requireUser(req);
  const body = await readJSON<Body>(req);
  const db = admin();
  const cost = (body.pro_edit ? 2 : 1) + (body.rush ? 1 : 0);

  const { error: clipError } = await db.from("clips").insert({
    id: body.clip_id,
    profile_id: user.id,
    idea_id: body.idea_id ?? null,
    title: body.title,
    source: "phoneEdit",
    status: "submitted",
    style: body.style,
    pro_edit: body.pro_edit,
    rush: body.rush,
    credit_cost: cost,
    raw_video_path: body.raw_video_path ?? null,
  });
  if (clipError) throw new HttpError(400, clipError.message);

  // Credits are spent in the database as the user, so the balance check is atomic.
  const { error: creditError } = await userDB.rpc("request_edit", { p_clip_id: body.clip_id, p_cost: cost });
  if (creditError) {
    await db.from("clips").delete().eq("id", body.clip_id);
    throw new HttpError(402, "Not enough credits");
  }

  // Pro edits: pick the active editor with the fewest open jobs.
  let editorID: string | null = null;
  let dueAt: string | null = null;
  if (body.pro_edit) {
    const { data: editors } = await db.from("editors").select("id, max_open_jobs").eq("active", true);
    let best: { id: string; open: number } | null = null;
    for (const editor of editors ?? []) {
      const { count } = await db.from("edit_jobs").select("id", { count: "exact", head: true })
        .eq("editor_id", editor.id).not("stage", "in", "(done,failed)");
      const open = count ?? 0;
      if (open < editor.max_open_jobs && (!best || open < best.open)) best = { id: editor.id, open };
    }
    editorID = best?.id ?? null;
    dueAt = new Date(Date.now() + (body.rush ? 24 : 48) * 3600 * 1000).toISOString();
  }

  const { data: job, error: jobError } = await db.from("edit_jobs").insert({
    clip_id: body.clip_id,
    stage: "queued",
    provider: Deno.env.get("EDIT_PROVIDER") ?? "internal",
    editor_id: editorID,
    due_at: dueAt,
    edit_plan: {
      style: body.style,
      captions: body.captions,
      music: body.music,
      brand_kit: body.brand_kit,
      notes: body.notes,
    },
  }).select("id").single();
  if (jobError) throw new HttpError(500, jobError.message);

  // Hand off to the AI editing worker (Submagic or the in-house Claude + Shotstack pipeline).
  const workerURL = Deno.env.get("EDIT_WORKER_URL");
  if (workerURL) {
    await fetch(workerURL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${Deno.env.get("EDIT_WORKER_TOKEN") ?? ""}` },
      body: JSON.stringify({ job_id: job.id, clip_id: body.clip_id, raw_video_path: body.raw_video_path }),
    }).catch((error) => console.error("worker unreachable", error));
  }

  return json({ clip_id: body.clip_id, job_id: job.id, credits_spent: cost });
});
