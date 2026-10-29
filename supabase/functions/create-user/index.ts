// Adds a team member to Supabase Auth with an initial password.
// Only a signed-in team member (app_metadata.team_member = true) may call it.
// The service role key stays on the server; the browser never sees it.
//
// Deploy: supabase functions deploy create-user   (JWT verification stays on)
import { createClient } from "npm:@supabase/supabase-js@2";

const EMAIL_DOMAIN = "actiontracker.app";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return reply(405, { error: "Use POST." });

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return reply(401, { error: "Sign in first." });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  const { data: caller, error: callerErr } = await admin.auth.getUser(token);
  if (callerErr || !caller?.user) return reply(401, { error: "Your session has expired. Sign in again." });
  if (caller.user.app_metadata?.team_member !== true) {
    return reply(403, { error: "Only team members can add users." });
  }

  let input: { username?: unknown; display_name?: unknown; password?: unknown };
  try { input = await req.json(); } catch { return reply(400, { error: "Send JSON." }); }

  const username = String(input.username ?? "").trim().toLowerCase();
  const displayName = String(input.display_name ?? "").trim();
  const password = String(input.password ?? "");

  if (!/^[a-z0-9_]{2,30}$/.test(username)) {
    return reply(400, { error: "Username must be 2 to 30 characters: lowercase letters, numbers or underscore." });
  }
  if (displayName.length < 1 || displayName.length > 60) {
    return reply(400, { error: "Enter a display name up to 60 characters." });
  }
  if (password.length < 8 || password.length > 72) {
    return reply(400, { error: "The initial password must be 8 to 72 characters." });
  }

  const { data, error } = await admin.auth.admin.createUser({
    email: `${username}@${EMAIL_DOMAIN}`,
    password,
    email_confirm: true,
    app_metadata: { team_member: true },
    user_metadata: { username, display_name: displayName },
  });

  if (error) {
    const msg = (error.message ?? "").toLowerCase();
    if (msg.includes("already") || msg.includes("exists") || msg.includes("registered")) {
      return reply(409, { error: `The username "${username}" is already taken.` });
    }
    if (msg.includes("password")) return reply(400, { error: error.message });
    return reply(400, { error: "Could not create the user." });
  }

  return reply(200, { id: data.user?.id, username, display_name: displayName });
});
