// Comment-to-DM lead capture for Facebook Pages and Instagram business accounts.
// Meta sends new comments here. If a comment contains the post's keyword, we
// send the agent's message by private reply and save a lead. Deploy with --no-verify-jwt.
import { admin, env, hmacHex, safeEqual, serve, json } from "../_shared/http.ts";

const GRAPH = "https://graph.facebook.com/v21.0";

type Change = {
  field: string;
  value: { id?: string; comment_id?: string; text?: string; message?: string; from?: { id: string; username?: string; name?: string }; media?: { id: string }; post_id?: string; item?: string; verb?: string };
};

serve(async (req) => {
  const url = new URL(req.url);

  // Subscription check from Meta.
  if (req.method === "GET") {
    const ok = url.searchParams.get("hub.mode") === "subscribe" && url.searchParams.get("hub.verify_token") === env("META_VERIFY_TOKEN");
    return new Response(ok ? url.searchParams.get("hub.challenge") ?? "" : "forbidden", { status: ok ? 200 : 403 });
  }

  const payload = await req.text();
  const signature = (req.headers.get("X-Hub-Signature-256") ?? "").replace("sha256=", "");
  const expected = await hmacHex(env("META_APP_SECRET"), payload);
  if (!safeEqual(signature, expected)) return new Response("bad signature", { status: 401 });

  const body = JSON.parse(payload) as { object: string; entry: { id: string; changes?: Change[] }[] };
  const db = admin();

  for (const entry of body.entry ?? []) {
    for (const change of entry.changes ?? []) {
      const isInstagram = body.object === "instagram" && change.field === "comments";
      const isFacebook = body.object === "page" && change.field === "feed" && change.value.item === "comment" && change.value.verb === "add";
      if (!isInstagram && !isFacebook) continue;

      const commentID = isInstagram ? change.value.id : change.value.comment_id;
      const text = (isInstagram ? change.value.text : change.value.message) ?? "";
      const mediaID = isInstagram ? change.value.media?.id : change.value.post_id;
      if (!commentID || !mediaID) continue;

      // Which agent owns this page, and which of their posts is it?
      const { data: account } = await db.from("social_accounts").select("profile_id, page_id")
        .eq("platform", isInstagram ? "instagram" : "facebook").eq("page_id", entry.id).maybeSingle();
      if (!account) continue;

      const { data: posts } = await db.from("posts").select("id, lead_keyword, dm_message, external_ids")
        .eq("profile_id", account.profile_id).not("lead_keyword", "is", null).order("created_at", { ascending: false }).limit(50);
      const post = (posts ?? []).find((p) => JSON.stringify(p.external_ids ?? {}).includes(mediaID));
      if (!post?.lead_keyword || !text.toUpperCase().includes(post.lead_keyword.toUpperCase())) continue;

      const { error: duplicate } = await db.from("leads").insert({
        profile_id: account.profile_id,
        post_id: post.id,
        name: change.value.from?.name ?? change.value.from?.username ?? null,
        handle: change.value.from?.username ?? change.value.from?.id ?? null,
        platform: isInstagram ? "instagram" : "facebook",
        keyword: post.lead_keyword,
        message: text,
        external_comment_id: commentID,
      });
      if (duplicate) continue; // already handled this comment

      const message = post.dm_message ?? "Thanks for commenting! Here are the details. What is the best number to reach you?";
      const token = await pageToken(account.profile_id);
      if (!token) continue;
      if (isInstagram) {
        await fetch(`${GRAPH}/${entry.id}/messages?access_token=${token}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ recipient: { comment_id: commentID }, message: { text: message } }),
        });
      } else {
        await fetch(`${GRAPH}/${commentID}/private_replies?access_token=${token}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message }),
        });
      }
    }
  }
  return json({ received: true });
});

/** Page access tokens are stored as Supabase Vault secrets named meta_page_token_<profile id>. */
async function pageToken(profileID: string): Promise<string | null> {
  const { data } = await admin().rpc("read_secret", { secret_name: `meta_page_token_${profileID}` });
  return typeof data === "string" ? data : null;
}
