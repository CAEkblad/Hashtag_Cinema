// Deletes the signed in user's account (App Store requirement).
// Profile rows cascade from auth.users. Storage files under the user's folder are removed first.
import { admin, requireUser, serve, json } from "../_shared/http.ts";

serve(async (req) => {
  const { user } = await requireUser(req);
  const db = admin();
  for (const bucket of ["raw-videos", "deliverables"]) {
    const { data: files } = await db.storage.from(bucket).list(user.id, { limit: 1000 });
    if (files && files.length > 0) {
      await db.storage.from(bucket).remove(files.map((f) => `${user.id}/${f.name}`));
    }
  }
  const { error } = await db.auth.admin.deleteUser(user.id);
  if (error) throw error;
  return json({});
});
