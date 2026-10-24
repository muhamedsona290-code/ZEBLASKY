# കൂടെ · KOODE 💚
> **Care Beyond Distance, Connected by a Call.**  
> An automated elder check-in and emergency escalation platform bridging cloud intelligence with cellular GSM telephony.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase%20%7C%20Postgres-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Exotel](https://img.shields.io/badge/Telephony-Exotel%20IVR%20GSM-008BD2?logo=phone&logoColor=white)](https://exotel.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Feature%20Phone-black)](https://github.com/muhamedsona290-code/ZEBLASKY)

---

## 📌 Overview

**Koode (കൂടെ)** is designed for elderly parents and grandparents living independently in India. Unlike conventional apps that require seniors to learn smartphone interfaces and maintain internet connectivity, Koode reaches elders through **automated cellular phone calls in Malayalam**. 

Elders simply answer on their regular phone keypad:
- **Press `1`** $\rightarrow$ "Yes / All is well"
- **Press `2`** $\rightarrow$ "No / Needs attention"
- **No answer or distress reported** $\rightarrow$ Automatically triggers a real-time multi-stage family escalation.

---

## 🧭 Repository Branch Guide

| Branch | Focus | Key Deliverables |
|:---|:---|:---|
| **`main`** *(Active)* | **Production Core & Telephony Engine** | • Live Exotel GSM cellular calls to physical SIMs<br>• 24/7 Cloud Background Scheduler (`pg_cron`)<br>• In-app microphone voice recorder for custom prompts<br>• Unified APK with seamless role switcher (Elder & Family)<br>• Live Realtime check-in feed & 3-stage emergency escalation |
| **`koode-development`** | **Extended Family & Child Dashboard** | • 4-Tab Guardian Portal (Home, Wellbeing, Care Plan, Emergency Network)<br>• 5-Stage Incident Timeline (`Alert Sent → Accepted → En Route → Arrived → Resolved`)<br>• Medication adherence tracking & shared care logbook<br>• Trusted neighbor & local emergency escalation matrix |
| **`dev_koode__call_working`** | **Release Snapshot** | • Verified telephony snapshot and cloud edge functions |

---

## 🏗️ Technical Architecture

```
                       ┌──────────────────────────────┐
                       │     Supabase PostgreSQL      │
                       │     (pg_cron / pg_net)       │
                       └──────────────┬───────────────┘
                                      │ Auto-triggers every minute
                                      ▼
                       ┌──────────────────────────────┐
                       │ Edge Function: run-schedules │
                       └──────────────┬───────────────┘
                                      │ Dispatches due calls
                                      ▼
┌───────────────────────┐      ┌──────────────────────────────┐      ┌──────────────────────────────┐
│ Family Guardian App   │─────▶│  Edge Function: start-call   │─────▶│   Exotel Telephony Gateway   │
│ (Customizes Schedule) │(HTTP)└──────────────────────────────┘(API) │    (Mumbai / Asia Cluster)   │
└───────────────────────┘                                            └──────────────┬───────────────┘
           ▲                                                                        │
           │ Realtime                                                               │ GSM Cellular
           │ WebSocket                                                              │ Network
           ▼                                                                        ▼
┌───────────────────────┐      ┌──────────────────────────────┐      ┌──────────────────────────────┐
│ Live Dashboard Feed   │◀─────│ Edge Function: exotel-webhook│◀─────│         Elder Phone          │
│ (Status & Escalation) │(HTTP)│   (Captures Keypad 1 or 2)   │(DTMF)│ (Feature Phone / Smartphone) │
└───────────────────────┘      └──────────────────────────────┘      └──────────────────────────────┘
```

---

## 🌟 Core Working Features (`main`)

### 1. Cellular GSM Telephony (Exotel IVR)
- **Direct SIM Dialing:** Dispatches real telephone calls over cellular networks from an Exotel ExoPhone (`09513886363`) directly to the elder's phone.
- **Indian Number Sanitization:** Automatically formats numbers with `0` prefixing (`0XXXXXXXXXX`) and strips spaces/hyphens for Indian telecom compliance.
- **Dual-Cluster Routing:** Connects with automatic failover across `api.in.exotel.com` (Mumbai) and `api.exotel.com`.
- **Diagnostic Feedback:** Surfaces clear alerts for telecom errors (e.g., trial whitelist status) instead of silent mock fallbacks.

### 2. 24/7 Cloud Background Calling
- **Runs With App Closed:** Database-level cron scheduling via `pg_cron` and `pg_net` runs autonomously in Supabase.
- **Zero App Dependency:** Scheduled calls ring the physical SIM even if the mobile app is killed or the phone is locked.

### 3. Voice Recording & Custom Malayalam Prompts
- **In-App Mic Recorder:** Built-in microphone widget allows family members to record questions in their own voices.
- **Dynamic Audio Streaming:** Uploads recordings to Supabase Storage (`audio-prompts`) and streams them dynamically via the `ivr` edge function.
- **Question Management:** Full CRUD support to add, edit, reorder, or delete check-in questions.

### 4. Dual-Mode Unified Mobile App
- **Elder Mode:** Clean, accessible high-contrast UI with oversized touch targets, big "I am Fine" button, and One-Touch SOS.
- **Family Dashboard:** Live stream of daily check-ins (`FINE`, `CONCERN`, `PENDING`), manual one-tap calling, and 3-stage emergency alerts.
- **Non-blocking UX:** Modern `AnimatedSwitcher` lifecycle preventing navigation freezes, with custom centered branding.

---

## 🛠️ Technology Stack

| Technology | Implementation |
|:---|:---|
| **Flutter & Dart** | Android app, accessible senior interface, caregiver dashboard, audio recorder |
| **Supabase** | Cloud PostgreSQL, Row Level Security (RLS), Realtime WebSockets, Storage (`audio-prompts`) |
| **PostgreSQL & pg_cron** | Background database scheduler automating recurring calls every minute |
| **Supabase Edge Functions** | Deno microservices: `start-call` (caller), `ivr` (audio server), `run-schedules` (cron runner), `exotel-webhook` (keypad listener) |
| **Exotel Telephony** | Cloud IVR gateway bridging cloud events to physical GSM telecom lines |

---

## ⚡ 2-Minute Judge Walkthrough

### Mode A: Real Cellular Call Test
1. Launch app (`flutter run`) $\rightarrow$ tap **Family Phone**.
2. Tap **Customize (Tune)** $\rightarrow$ scroll to **Grandparent phone details**.
3. Save your real mobile number (e.g. `+918714127772`) with Consent **ON**.
4. Tap **"Call Lakshmi Amma now"**.
5. Your physical phone will ring with an incoming GSM call from Exotel. Answer, listen to the Malayalam prompt, and press **`1`** or **`2`** on your keypad to watch the dashboard update live!

### Mode B: Single-Phone Simulator
1. On Family Phone, expand **"Demo tools (quick single-phone simulate)"**.
2. Tap **"Simulate: Press 1"** or **"Simulate: Press 2"**.
3. Observe the real-time check-in status update and emergency escalation stages.

---

## 🚀 Quick Setup

1. **Database:** Run `supabase/migrations/001_koode.sql` and `002_custom.sql` in Supabase SQL Editor.
2. **Secrets:** In Supabase **Project Settings $\rightarrow$ Edge Functions $\rightarrow$ Secrets**, configure:
   ```env
   EXOTEL_SID=zeblasky1
   EXOTEL_KEY=your_key
   EXOTEL_TOKEN=your_token
   EXOPHONE=09513886363
   EXOTEL_APP_ID=your_app_id
   EXOTEL_HOST=api.in.exotel.com
   WEBHOOK_SECRET=koode123
   ```
3. **Deploy Functions:**
   ```bash
   supabase functions deploy start-call --no-verify-jwt
   supabase functions deploy exotel-webhook --no-verify-jwt
   supabase functions deploy run-schedules --no-verify-jwt
   supabase functions deploy ivr --no-verify-jwt
   ```
4. **Run App:** `flutter pub get && flutter run`

---

**Team ZEBLASKY** · Koode 💚 (Since 2026)
