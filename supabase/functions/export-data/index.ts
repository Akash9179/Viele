// export-data — returns a full JSON export of the calling user's data.
//
// Uses the caller's own JWT (verify_jwt = true) so every read is gated by RLS:
// the function can only ever return data the user already owns, including the
// owner-only profiles_private row (weight). The client saves/shares the JSON.
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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
  const c = createClient(url, anon, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user } } = await c.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  const uid = user.id;

  const [
    profile,
    profilePrivate,
    posts,
    likes,
    following,
    followers,
    collections,
    collectionItems,
    blocks,
  ] = await Promise.all([
    c.from("profiles").select("*").eq("id", uid).maybeSingle(),
    c.from("profiles_private").select("*").eq("profile_id", uid).maybeSingle(),
    c.from("posts").select("*").eq("author_id", uid),
    c.from("likes").select("*").eq("user_id", uid),
    c.from("follows").select("*").eq("follower_id", uid),
    c.from("follows").select("*").eq("followee_id", uid),
    c.from("collections").select("*").eq("owner_id", uid),
    c.from("collection_items").select("*"),
    c.from("blocks").select("*").eq("blocker_id", uid),
  ]);

  const exportPayload = {
    generated_at: new Date().toISOString(),
    account: { id: uid, email: user.email },
    profile: profile.data ?? null,
    profile_private: profilePrivate.data ?? null,
    posts: posts.data ?? [],
    likes: likes.data ?? [],
    following: following.data ?? [],
    followers: followers.data ?? [],
    collections: collections.data ?? [],
    collection_items: collectionItems.data ?? [],
    blocks: blocks.data ?? [],
  };

  return new Response(JSON.stringify(exportPayload, null, 2), {
    headers: {
      ...cors,
      "Content-Type": "application/json",
      "Content-Disposition": 'attachment; filename="viele-export.json"',
    },
  });
});
