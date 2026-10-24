import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const secret = Deno.env.get("WEBHOOK_SECRET") ?? "koode123";
  const urlParamKey = new URL(req.url).searchParams.get("k");
  if (urlParamKey !== secret) {
    return new Response(JSON.stringify({ error: "forbidden: invalid secret key" }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const svc = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const db = createClient(url, svc);

  const nowIso = new Date().toISOString();
  const { data: due, error: dueErr } = await db
    .from("call_schedules")
    .select("*")
    .eq("active", true)
    .lte("next_run_at", nowIso)
    .limit(20);

  if (dueErr) {
    console.error("Error fetching due schedules:", dueErr);
    return new Response(JSON.stringify({ error: dueErr }), { status: 500 });
  }

  const results: any[] = [];
  let placedCount = 0;

  for (const s of due ?? []) {
    const done = (s.runs_done ?? 0) + 1;
    const intervalMin = s.interval_minutes ?? 1440;
    const repeatCount = s.repeat_count ?? 1;
    const baseTime = s.next_run_at ? new Date(s.next_run_at).getTime() : Date.now();
    const nextIso = new Date(baseTime + intervalMin * 60000).toISOString();

    await db.from("call_schedules")
      .update({
        runs_done: done,
        next_run_at: nextIso,
        active: done < repeatCount
      })
      .eq("id", s.id);

    try {
      const callRes = await fetch(`${url}/functions/v1/start-call`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${svc}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ elder_id: s.elder_id })
      });
      const callJson = await callRes.json();
      results.push({ schedule_id: s.id, success: callRes.ok, response: callJson });
      if (callRes.ok) placedCount++;
    } catch (e: any) {
      console.error(`Failed to invoke start-call for schedule ${s.id}:`, e);
      results.push({ schedule_id: s.id, success: false, error: String(e) });
    }
  }

  return new Response(JSON.stringify({
    success: true,
    due_count: due?.length ?? 0,
    placed_calls: placedCount,
    details: results
  }), { headers: { "Content-Type": "application/json" } });
});
