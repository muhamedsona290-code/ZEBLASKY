import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const { elder_id } = await req.json();
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: elder } = await db.from("elders").select("*").eq("id", elder_id).single();
  if (!elder?.consent) return new Response(JSON.stringify({ error: "no consent" }), { status: 403, headers: cors });
  const sid = Deno.env.get("EXOTEL_SID")!, key = Deno.env.get("EXOTEL_KEY")!, tok = Deno.env.get("EXOTEL_TOKEN")!;
  const host = Deno.env.get("EXOTEL_HOST") ?? "api.exotel.com";
  const secret = Deno.env.get("WEBHOOK_SECRET") ?? "koode123";
  const hook = `${Deno.env.get("SUPABASE_URL")}/functions/v1/exotel-webhook?k=${secret}`;
  const body = new URLSearchParams({
    From: elder.phone, CallerId: Deno.env.get("EXOPHONE")!,
    Url: `http://my.exotel.com/${sid}/exoml/start_voice/${Deno.env.get("EXOTEL_APP_ID")}`,
    StatusCallback: hook + "&q=status", CustomField: elder_id });
  const r = await fetch(`https://${host}/v1/Accounts/${sid}/Calls/connect.json`, {
    method: "POST", body, headers: { Authorization: "Basic " + btoa(`${key}:${tok}`) } });
  const j = await r.json();
  const call_sid = j?.Call?.Sid;
  if (!r.ok || !call_sid) return new Response(JSON.stringify({ error: j }), { status: 502, headers: cors });
  await db.from("checkins").insert({ elder_id, source: "call", call_sid, call_status: "INITIATED" });
  return new Response(JSON.stringify({ call_sid }), { headers: cors });
});
