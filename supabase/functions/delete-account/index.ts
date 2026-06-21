// delete-account — permanently deletes the calling user's account.
//
// Deleting the auth.users row cascades through the DB (profiles → posts, likes,
// follows, collections, collection_items, blocks, posts_private — all FK
// `on delete cascade`). Storage objects are NOT cascaded, so we remove the
// user's media (post-media/posts/{uid}/ and avatars/{uid}/) first.
//
// Requires a valid user JWT (verify_jwt = true). Uses the service-role key
// (server-side only, never shipped to the client) for the admin delete.
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// deno-lint-ignore no-explicit-any
async function removePrefix(admin: any, bucket: string, prefix: string) {
  const { data, error } = await admin.storage
    .from(bucket)
    .list(prefix, { limit: 1000 });
  if (error || !data) return;
  const files: string[] = [];
  for (const item of data) {
    // In Supabase storage list, folders come back with a null id.
    if (item.id === null) {
      await removePrefix(admin, bucket, `${prefix}/${item.name}`);
    } else {
      files.push(`${prefix}/${item.name}`);
    }
  }
  if (files.length) await admin.storage.from(bucket).remove(files);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Identify the caller from their JWT.
  const userClient = createClient(url, anon, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const admin = createClient(url, service);

  // Best-effort media cleanup (don't block deletion on storage errors).
  try {
    await removePrefix(admin, "post-media", `posts/${user.id}`);
    await removePrefix(admin, "avatars", user.id);
  } catch (_) {
    // ignore — orphaned media is acceptable; the account delete is what matters
  }

  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) {
    return new Response(JSON.stringify({ error: delErr.message }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
