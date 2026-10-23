// Exotel Passthru applets (after each Gather) call this URL with ?k=SECRET&q=food|meds|status
// and params CallSid, digits, CallStatus. Secret token stands in for a signature (Exotel Passthru is unsigned).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async (req) => {
  const u = new URL(req.url);
  const secret = Deno.env.get("WEBHOOK_SECRET") ?? "koode123";
  if (u.searchParams.get("k") !== secret) return new Response("forbidden", { status: 401 });
  const p = u.searchParams, form = req.method === "POST" ? await req.formData() : new FormData();
  const get = (n: string) => p.get(n) ?? (form.get(n) as string | null);
  const sid = get("CallSid"), q = p.get("q"), digits = (get("digits") ?? "").replace(/"/g, "").trim();
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: c } = await db.from("checkins").select("*").eq("call_sid", sid).maybeSingle();
  if (!c) return new Response("unknown call", { status: 404 });
  if (q === "food" || q === "meds") {
    if (digits !== "1" && digits !== "2") return new Response("ignored"); // only explicit 1/2 counts
    const yes = digits === "1";
    const upd: any = { [q]: yes, call_status: "ANSWERED" };
    const food = q === "food" ? yes : c.food, meds = q === "meds" ? yes : c.meds;
    if (!yes) upd.result = "CONCERN";
    else if (food === true && meds === true) upd.result = "FINE";
    await db.from("checkins").update(upd).eq("id", c.id);
    if (!yes) await db.from("incidents").insert({ elder_id: c.elder_id, trigger: `call: pressed 2 (${q})` }); // unique index blocks duplicates
  } else if (q === "status") {
    const s = (get("CallStatus") ?? "").toLowerCase();
    if (["no-answer", "busy", "failed", "canceled"].includes(s))
      await db.from("checkins").update({ call_status: s === "failed" ? "FAILED" : "UNANSWERED", result: s === "failed" ? c.result : "UNANSWERED" }).eq("id", c.id).eq("result", "PENDING");
    else if (s === "completed") // connected but no explicit 1 => never FINE
      await db.from("checkins").update({ call_status: "COMPLETED", result: c.result === "PENDING" ? "UNANSWERED" : c.result }).eq("id", c.id);
  }
  return new Response("ok");
});
