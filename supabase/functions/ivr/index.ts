// Supports both Exotel App Bazaar (Gather + Passthru loop) and JSON mode:
// 1. Gather applet (Dynamic prompt URL):
//    GET/HEAD .../functions/v1/ivr?k=SECRET&step=prompt
//    -> Returns Content-Type: text/plain with the next unanswered question's audio_url or TTS prompt text.
// 2. Passthru applet (Synchronous mode after Gather):
//    GET .../functions/v1/ivr?k=SECRET&step=answer
//    -> Records `digits` for the current question.
//    -> Returns HTTP 200 OK if more questions remain (or invalid digit -> repeats question): connect 200 branch back to Gather!
//    -> Returns HTTP 302 Found when all questions are answered: connect 302 branch to Hangup!
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const json = (o: unknown) => new Response(JSON.stringify(o), { headers: { "Content-Type": "application/json" } });
const text = (s: string, status = 200) => new Response(s, { status, headers: { "Content-Type": "text/plain; charset=utf-8" } });

Deno.serve(async (req) => {
  const u = new URL(req.url), p = u.searchParams;
  const secret = Deno.env.get("WEBHOOK_SECRET") ?? "koode123";
  if (p.get("k") !== secret) return new Response("forbidden", { status: 401 });
  if (req.method === "HEAD") return text("");

  const form = req.method === "POST" ? await req.formData() : new FormData();
  const get = (n: string) => p.get(n) ?? (form.get(n) as string | null);
  const sid = get("CallSid"), step = p.get("step"), qid = p.get("qid");
  const key = (get("digits") ?? get("Digits") ?? "").replace(/"/g, "").trim();

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: c } = await db.from("checkins").select("*").eq("call_sid", sid).maybeSingle();
  if (!c) return text("unknown call", 404);

  // Load all enabled questions and already-recorded answers for this checkin
  const { data: qs } = await db.from("questions").select("*").eq("elder_id", c.elder_id).eq("enabled", true).order("position");
  const { data: ans } = await db.from("answers").select("question_id").eq("checkin_id", c.id);
  const answeredIds = new Set((ans ?? []).map((a: any) => a.question_id));
  const remaining = (qs ?? []).filter((q: any) => !answeredIds.has(q.id));

  // --- EXOTEL GATHER DYNAMIC PROMPT (step=prompt) ---
  if (step === "prompt") {
    if (!remaining.length) return text("Thank you. Goodbye.");
    const q = remaining[0];
    if (q.audio_url) return text(q.audio_url);
    const optsText = (q.options as any[]).map((o) => `Press ${o.key} for ${o.label}`).join(". ");
    return text(`${q.text}. ${optsText}.`);
  }

  // --- EXOTEL PASSTHRU AFTER GATHER (step=answer) ---
  if (step === "answer") {
    if (!remaining.length) return text("done", 302);
    const q = remaining[0];
    const opt = (q.options as any[]).find((o) => String(o.key) === key);
    if (!opt) {
      // Invalid or missing key: return 200 OK so Passthru loops back to Gather and repeats the same question
      return text("repeat", 200);
    }
    await db.from("answers").insert({ checkin_id: c.id, question_id: q.id, question_text: q.text, key, label: opt.label });
    await db.from("checkins").update({ call_status: "ANSWERED" }).eq("id", c.id);
    if (opt.concern) {
      await db.from("checkins").update({ result: "CONCERN" }).eq("id", c.id);
      try { await db.from("incidents").insert({ elder_id: c.elder_id, trigger: `call: "${q.text}" -> ${opt.label}` }); } catch (_) {}
    }
    if (remaining.length <= 1) {
      // That was the last question!
      await db.from("checkins").update({ result: "FINE", call_status: "COMPLETED" }).eq("id", c.id).eq("result", "PENDING");
      return text("done", 302); // 302 Found -> routes Passthru to Hangup
    }
    return text("next", 200); // 200 OK -> routes Passthru back to Gather for the next question
  }

  // --- LEGACY JSON MODE ---
  const base = `${Deno.env.get("SUPABASE_URL")}/functions/v1/ivr?k=${p.get("k")}`;
  let pos = -1;
  if (qid) {
    const { data: q } = await db.from("questions").select("*").eq("id", qid).single();
    pos = q.position;
    const opt = q.options.find((o: any) => o.key === key);
    if (!opt) return json({ done: false, repeat: true, question: q, next_url: `${base}&qid=${q.id}` });
    await db.from("answers").insert({ checkin_id: c.id, question_id: q.id, question_text: q.text, key, label: opt.label });
    await db.from("checkins").update({ call_status: "ANSWERED" }).eq("id", c.id);
    if (opt.concern) {
      await db.from("checkins").update({ result: "CONCERN" }).eq("id", c.id);
      try { await db.from("incidents").insert({ elder_id: c.elder_id, trigger: `call: "${q.text}" -> ${opt.label}` }); } catch (_) {}
    }
  }
  const { data: next } = await db.from("questions").select("*").eq("elder_id", c.elder_id).eq("enabled", true).gt("position", pos).order("position").limit(1);
  if (!next?.length) {
    const { count } = await db.from("answers").select("id", { count: "exact", head: true }).eq("checkin_id", c.id);
    if ((count ?? 0) > 0) await db.from("checkins").update({ result: "FINE" }).eq("id", c.id).eq("result", "PENDING");
    return json({ done: true });
  }
  const q = next[0];
  return json({ done: false, question: { id: q.id, text: q.text, audio_url: q.audio_url, options: q.options }, next_url: `${base}&qid=${q.id}` });
});