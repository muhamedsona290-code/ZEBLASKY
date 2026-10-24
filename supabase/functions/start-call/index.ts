import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
  "Content-Type": "application/json"
};

function cleanSecret(val: string | undefined): string {
  if (!val) return "";
  return val.trim().replace(/^["']|["']$/g, "");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { elder_id } = await req.json();
    if (!elder_id) {
      return new Response(JSON.stringify({ error: "Missing elder_id parameter" }), { status: 400, headers: cors });
    }

    const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: elder, error: elderErr } = await db.from("elders").select("*").eq("id", elder_id).single();
    if (elderErr || !elder) {
      return new Response(JSON.stringify({ error: "Elder record not found in database", details: elderErr }), { status: 404, headers: cors });
    }
    if (!elder.consent) {
      return new Response(JSON.stringify({ error: "Consent not given by elder" }), { status: 403, headers: cors });
    }

    // Sanitize and validate phone number
    const rawPhone = elder.phone ?? "";
    const digitsOnly = rawPhone.replace(/[^\d]/g, "");
    if (digitsOnly.length < 10 || rawPhone.includes("X") || rawPhone.includes("x")) {
      return new Response(JSON.stringify({
        error: `Invalid phone number configured: "${rawPhone}". Please set a valid 10-digit mobile number in Customize -> Grandparent phone details.`
      }), { status: 400, headers: cors });
    }

    // Exotel requires Indian mobile numbers to have '0' prefix (e.g. 09876543210)
    let cleanPhone = digitsOnly;
    if (cleanPhone.startsWith("91") && cleanPhone.length === 12) {
      cleanPhone = "0" + cleanPhone.substring(2);
    } else if (cleanPhone.length === 10 && !cleanPhone.startsWith("0")) {
      cleanPhone = "0" + cleanPhone;
    }

    const sid = cleanSecret(Deno.env.get("EXOTEL_SID"));
    const key = cleanSecret(Deno.env.get("EXOTEL_KEY"));
    const tok = cleanSecret(Deno.env.get("EXOTEL_TOKEN"));
    const exophone = cleanSecret(Deno.env.get("EXOPHONE"));
    const appId = cleanSecret(Deno.env.get("EXOTEL_APP_ID"));

    const missingSecrets: string[] = [];
    if (!sid) missingSecrets.push("EXOTEL_SID");
    if (!key) missingSecrets.push("EXOTEL_KEY");
    if (!tok) missingSecrets.push("EXOTEL_TOKEN");
    if (!exophone) missingSecrets.push("EXOPHONE");
    if (!appId) missingSecrets.push("EXOTEL_APP_ID");

    if (missingSecrets.length > 0) {
      return new Response(JSON.stringify({
        error: `Missing required Supabase Edge Function Secrets: ${missingSecrets.join(", ")}.`
      }), { status: 500, headers: cors });
    }

    const secret = cleanSecret(Deno.env.get("WEBHOOK_SECRET")) || "koode123";
    const hook = `${Deno.env.get("SUPABASE_URL")}/functions/v1/exotel-webhook?k=${secret}`;
    const body = new URLSearchParams({
      From: cleanPhone,
      CallerId: exophone,
      Url: `http://my.exotel.com/${sid}/exoml/start_voice/${appId}`,
      StatusCallback: hook + "&q=status",
      CustomField: elder_id
    });

    const configuredHost = cleanSecret(Deno.env.get("EXOTEL_HOST"));
    const hostsToTry = Array.from(new Set([
      configuredHost || "api.in.exotel.com",
      "api.in.exotel.com",
      "api.exotel.com"
    ]));

    // Try both auth schemes in case key and sid were confused
    const authHeadersToTry = [
      "Basic " + btoa(`${key}:${tok}`),
      "Basic " + btoa(`${sid}:${tok}`)
    ];

    let lastResult: any = null;
    let callSid: string | null = null;
    let successfulHost = "";

    outerLoop:
    for (const host of hostsToTry) {
      for (const authHeader of authHeadersToTry) {
        try {
          console.log(`Attempting Exotel call on ${host} to ${cleanPhone}...`);
          const r = await fetch(`https://${host}/v1/Accounts/${sid}/Calls/connect.json`, {
            method: "POST",
            body,
            headers: { Authorization: authHeader }
          });
          const j = await r.json();
          lastResult = j;
          if (r.ok && j?.Call?.Sid) {
            callSid = j.Call.Sid;
            successfulHost = host;
            break outerLoop;
          }
        } catch (netErr) {
          lastResult = { network_error: String(netErr) };
        }
      }
    }

    if (!callSid) {
      const restMsg = lastResult?.RestException?.Message || lastResult?.error || JSON.stringify(lastResult);
      console.error("Exotel Call Error:", restMsg);
      return new Response(JSON.stringify({
        error: restMsg,
        code: lastResult?.RestException?.Code,
        details: lastResult,
        dialed_phone: cleanPhone,
        account_sid_used: sid
      }), { status: 502, headers: cors });
    }

    await db.from("checkins").insert({
      elder_id,
      source: "call",
      call_sid: callSid,
      call_status: "INITIATED",
      result: "PENDING"
    });

    return new Response(JSON.stringify({
      success: true,
      call_sid: callSid,
      host: successfulHost,
      dialed_phone: cleanPhone
    }), { headers: cors });

  } catch (err: any) {
    console.error("Unhandled start-call error:", err);
    return new Response(JSON.stringify({ error: err.message || String(err) }), { status: 500, headers: cors });
  }
});
