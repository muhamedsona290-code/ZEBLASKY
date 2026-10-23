import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async (req) => {
  if (new URL(req.url).searchParams.get("k") !== Deno.env.get("WEBHOOK_SECRET")) return new Response("forbidden", { status: 401 });
  const url = Deno.env.get("SUPABASE_URL")!, svc = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const db = createClient(url, svc);
  const { data: due } = await db.from("call_schedules").select("*").eq("active", true).lte("next_run_at", new Date().toISOString()).limit(20);
  let placed = 0;
  for (const s of due ?? []) {
    const done = s.runs_done + 1;
    const next = new Date(new Date(s.next_run_at).getTime() + s.interval_minutes * 60000).toISOString();
    // atomic claim: only one scheduler run can advance this row, so no duplicate calls
    const { data: claimed } = await db.from("call_schedules")
      .update({ runs_done: done, next_run_at: next, active: done < s.repeat_count })
      .eq("id", s.id).eq("next_run_at", s.next_run_at).select();
    if (!claimed?.length) continue;
    await fetch(`${url}/functions/v1/start-call`, { method: "POST",
      headers: { Authorization: `Bearer ${svc}`, "Content-Type": "application/json" },
      body: JSON.stringify({ elder_id: s.elder_id }) });
    placed++;
  }
  return new Response(JSON.stringify({ placed }));
});