# കൂടെ · KOODE
> **"Together, Beside You"** — The Cloud-to-Cellular Elder Safety & Automated Check-In Platform.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase%20%7C%20Postgres-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Exotel](https://img.shields.io/badge/Telephony-Exotel%20IVR%20GSM-008BD2?logo=phone&logoColor=white)](https://exotel.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Feature%20Phone-black)](https://github.com/muhamedsona290-code/ZEBLASKY)
[![Status](https://img.shields.io/badge/Status-Live%20%26%20Functional-brightgreen)](https://github.com/muhamedsona290-code/ZEBLASKY)

---

## 📌 Executive Summary (For Judges & Evaluators)

In India, millions of elderly parents and grandparents live alone while their children work in different cities or abroad. Most existing elder-care tech solutions fail for one fundamental reason: **they force seniors to learn complex smartphone applications, install apps, and maintain active Wi-Fi or data connections.**

**Koode (കൂടെ)** reverses this paradigm. It bridges cloud intelligence with physical telecom networks:
1. **Zero Tech Barrier for Elders:** The grandparent receives a **real cellular phone call (GSM)** on their regular phone (whether a smartphone or a basic ₹1,000 keypad phone) with **no internet required**.
2. **Local Voice Interaction:** The call plays interactive voice prompts in **Malayalam** (or custom voice recordings from their children/grandchildren).
3. **Dialpad Response:** The elder simply presses **`1`** for *"Yes / All is well"* or **`2`** for *"No / Need help"*.
4. **24/7 Cloud Automation:** Calls are dispatched automatically by a backend cloud cron scheduler — ringing the phone even when the family app is closed or the elder's phone is locked.
5. **Real-Time Family Escalation:** Family members monitor daily safety on a real-time dashboard with an automated 3-tier emergency escalation engine if a check-in is missed or distress is flagged.

---

## 🧭 Repository Branch Guide

This project is partitioned into specialized development tracks:

| Branch | Status | Scope & Deliverables |
|:---|:---:|:---|
| **`main`** *(Active)* | **Production / Core** | **Full End-to-End System:** Real Exotel GSM cellular calling, 24/7 cloud scheduler (`pg_cron`), custom voice & text question recorder, family guardian dashboard, accessible senior screen, emergency SOS trigger, and 30-second escalation engine. |
| **`koode-development`** | **Extended Features** | **Child Dashboard & Engagement:** Grandchild-to-grandparent interaction workflows, kid-friendly voice recording modules, interactive family bonding features, and specialized child interface. |
| **`dev_koode__call_working`** | **Release Snapshot** | Verified telephony and cloud Edge Functions snapshot branch. |

---

## ⚡ Quick 2-Minute Judge Walkthrough (How to Evaluate)

You can evaluate the entire Koode system in two modes:

### Mode A: Full Real Telecom Test (Live Physical SIM Call)
1. **Launch the App:** Run `flutter run` on an Android device or simulator.
2. **Select Role:** Tap **Family Phone** from the role selector.
3. **Save Elder Phone:** Tap the **Customize (Tune)** icon in the top right $\rightarrow$ scroll to **Grandparent phone details** $\rightarrow$ enter your real mobile number (e.g. `+918714127772`) and toggle Consent **ON**.
4. **Trigger Cellular Call:** Tap **"Call Lakshmi Amma now"** on the home screen.
5. **Experience the Telecom Call:** Within seconds, Exotel initiates an outbound GSM call from the virtual ExoPhone (`09513886363`) directly to your physical SIM. Answer on your phone dialer, listen to the Malayalam voice prompt, and press `1` or `2` on your dialpad.
6. **Watch Real-Time Dashboard:** The Family dashboard updates instantaneously via Supabase Realtime to show the response!

### Mode B: Single-Phone Simulator (Zero Setup Needed)
Don't have an active Exotel telecom account linked? The app includes built-in single-device demo tools:
1. Tap **Family Phone** $\rightarrow$ scroll down and expand **"Demo tools (quick single-phone simulate)"**.
2. Tap **"Simulate: Press 1 (Fine)"** or **"Simulate: Press 2 (Concern)"**.
3. Observe the real-time check-in stream, color-coded health badges, and automatic 30-second emergency incident escalation stages.

---

## 🏗️ Technical Architecture

Koode uses an event-driven, cloud-first telecom architecture:

```
                                  ┌───────────────────────────────┐
                                  │      Supabase PostgreSQL      │
                                  │   (Database + pg_cron Engine) │
                                  └───────────────┬───────────────┘
                                                  │ Every 60 seconds
                                                  ▼
                                  ┌───────────────────────────────┐
                                  │   Edge Function: run-schedules│
                                  └───────────────┬───────────────┘
                                                  │ Due check-in detected
                                                  ▼
┌────────────────────────┐        ┌───────────────────────────────┐        ┌───────────────────────────────┐
│  Family Guardian App   │───────▶│    Edge Function: start-call  │───────▶│    Exotel Telephony Gateway   │
│  (Flutter / Android)   │ (HTTP) └───────────────────────────────┘ (API)  │    (Mumbai / Asia Cluster)    │
└────────────────────────┘                                                 └───────────────┬───────────────┘
            ▲                                                                              │
            │ Real-time                                                                    │ GSM Cellular
            │ WebSocket                                                                    │ Network
            ▼                                                                              ▼
┌────────────────────────┐        ┌───────────────────────────────┐        ┌───────────────────────────────┐
│   Check-in & Incident  │◀───────│  Edge Function: exotel-webhook│◀───────│       Elder Phone             │
│   Realtime Stream      │ (HTTP) │   (Receives Keypad 1 or 2)    │ (DTMF) │    (Keypad / Smartphone SIM)  │
└────────────────────────┘        └───────────────────────────────┘        └───────────────────────────────┘
```

---

## 🌟 Core Features Breakdown

### 1. Cellular GSM Telephony & IVR Keypad Routing
- **Native Telecom Dialing:** Bypasses internet restrictions by initiating outbound telecom calls via Exotel API directly to physical SIM cards.
- **Indian Number Sanitization:** Auto-formats 10-digit Indian numbers (`0XXXXXXXXXX`) and strips spaces, hyphens, and country code prefixes to guarantee telecom gateway compliance.
- **Dual-Cluster Host Failover:** Auto-connects across Mumbai (`api.in.exotel.com`) and Global (`api.exotel.com`) Exotel clusters.
- **Transparent Diagnosis:** Diagnostic dialogs report exact telecom gateway error codes (e.g. un-whitelisted trial numbers, balance limits) instead of concealing errors.

### 2. 24/7 Cloud Calling (Autonomous Background Scheduler)
- **Runs With App Closed:** Android OS terminates in-app Flutter timers when apps are swiped away. Koode solves this with server-side autonomous cron scheduling via Supabase `pg_cron` and `pg_net`.
- **Scheduled Check-In Rules:** Supports recurring daily check-ins, custom intervals (in minutes), test presets ("In 1 minute"), and repeat counters.

### 3. Voice Question Customization & Malayalam Audio Streaming
- **Direct Microphone Recording:** Built-in in-app audio recorder widget (`record: ^7.1.2` & `audioplayers: ^6.0.0`) allows families and children to record custom questions in their own voices.
- **Storage Bucket Integration:** Voice audio is uploaded to Supabase Storage (`audio-prompts`) with base64 data URI fallback.
- **Dynamic IVR Streaming:** The `ivr` edge function serves recorded voice prompts dynamically to Exotel during the call.
- **Full CRUD Management:** Create, toggle active status, reorder, and delete questions with confirmation dialogs.

### 4. Family Guardian Dashboard
- **Live Status Feed:** Instant stream of elder check-ins (`FINE`, `CONCERN`, `PENDING`).
- **Emergency Incident Escalation:** If an elder presses `2` or triggers SOS, an incident is registered with a 30-second escalation level (Level 1 $\rightarrow$ Level 2 $\rightarrow$ Level 3) notifying emergency contacts.
- **Resolution Tracking:** One-tap acknowledgment and resolution logging with user attribution.

### 5. Elder Senior Mode
- **Designed for Seniors:** High-contrast color palette, uncluttered UI, and oversized touch buttons.
- **One-Touch SOS:** Prominent emergency button triggering instant cloud alerts.
- **In-App Ringing & Haptics:** Telephony audio ringtone loop and haptic vibration for in-app fallback testing.

### 6. Design & Brand Identity
- **Centered Clean Vector Logo:** Transparent vector canvas eliminating all background screenshot grid artifacts.
- **Smooth `AnimatedSwitcher`:** Non-blocking splash lifecycle preventing navigation freeze bugs.
- **Native Android Launchers:** Crisp adaptive launcher icons across all standard Android densities (`mdpi` to `xxxhdpi`).

---

## 🗄️ Database Schema & Data Models

| Table | Purpose | Key Attributes |
|---|---|---|
| **`elders`** | Senior profile & settings | `id`, `name`, `phone`, `consent`, `consent_at` |
| **`checkins`** | Master log of all calls | `id`, `elder_id`, `source`, `call_sid`, `call_status`, `result`, `food`, `meds` |
| **`questions`** | Dynamic check-in question sequence | `id`, `elder_id`, `position`, `text`, `audio_url`, `options` (JSONB), `enabled` |
| **`answers`** | Granular responses per question | `id`, `checkin_id`, `question_id`, `question_text`, `key`, `label` |
| **`call_schedules`** | Recurrence rules for cloud cron | `id`, `elder_id`, `start_at`, `interval_minutes`, `runs_done`, `next_run_at`, `active` |
| **`incidents`** | Emergency escalation tracker | `id`, `elder_id`, `trigger`, `status` (`OPEN`, `RESOLVED`, `CANCELLED`), `escalation_level` |

---

## 🛠️ Tech Stack & Dependencies

- **Frontend:** Flutter 3.x (Dart), Material 3, `supabase_flutter: ^2.5.0`, `audioplayers: ^6.0.0`, `record: ^7.1.2`, `shared_preferences: ^2.2.0`, `intl: ^0.19.0`.
- **Backend & Cloud:** Supabase PostgreSQL, Row Level Security (RLS), Supabase Realtime, Supabase Storage (`audio-prompts`).
- **Serverless Compute:** Supabase Edge Functions (Deno / TypeScript):
  - `start-call`: Telecom call placement & Exotel API dispatcher.
  - `ivr`: Dynamic voice prompt & audio streaming server.
  - `run-schedules`: Cloud cron evaluator.
  - `exotel-webhook`: Real-time DTMF keypad answer listener.
- **Telephony Infrastructure:** Exotel Cloud Telephony (Outbound Call API, ExoML flows, ExoPhone virtual numbers).

---

## 🚀 Setup & Installation Guide

### Prerequisites
- Flutter SDK (3.19+)
- Supabase Account & Project
- Exotel Developer Account

### 1. Database Migrations
Execute these SQL scripts in order inside the **Supabase SQL Editor**:
1. Run `supabase/migrations/001_koode.sql` (Creates core tables, RLS policies, and seeded records).
2. Run `supabase/migrations/002_custom.sql` (Creates questions, schedules, audio buckets, and `pg_cron` jobs).

### 2. Configure Supabase Secrets
Under **Supabase Dashboard $\rightarrow$ Project Settings $\rightarrow$ Edge Functions $\rightarrow$ Secrets**, add:
```env
EXOTEL_SID=zeblasky1
EXOTEL_KEY=your_exotel_api_key
EXOTEL_TOKEN=your_exotel_api_token
EXOPHONE=09513886363
EXOTEL_APP_ID=your_exotel_app_id
EXOTEL_HOST=api.in.exotel.com
WEBHOOK_SECRET=koode123
```

### 3. Deploy Edge Functions
```bash
supabase functions deploy start-call --no-verify-jwt
supabase functions deploy exotel-webhook --no-verify-jwt
supabase functions deploy run-schedules --no-verify-jwt
supabase functions deploy ivr --no-verify-jwt
```

### 4. Run Flutter App
```bash
flutter pub get
flutter run
```

---

## 🏆 Project Impact
**Koode** eliminates the digital literacy requirement for senior citizens. By meeting elders where they already are — on their standard telephone keypad — while empowering families with modern cloud intelligence, Koode delivers peace of mind to families across distances.

**Team ZEBLASKY** · Koode (Since 2026)
