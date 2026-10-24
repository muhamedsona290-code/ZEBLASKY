# കൂടെ · KOODE
### Automated Elder Check-In & Emergency Escalation Platform

**Koode** (*meaning "Together / Beside You" in Malayalam*) is an elder-care safety and automated check-in system designed specifically for Indian families. It bridges the digital divide by allowing elderly grandparents (who may use basic feature phones without internet) to receive automated local-language cellular voice calls, while family members monitor their well-being in real-time through an intuitive guardian app.

---

##  System Overview

Seniors often live alone and shouldn't need complex apps, smartphones, or high-speed data to stay safe. Koode automates routine daily check-ins ("Have you eaten?", "Have you taken your medicine?") through **cellular GSM phone calls** using **Exotel IVR** and **Malayalam voice prompts**. Grandparents simply answer on their normal phone keypad:

- **Press `1`** $\rightarrow$ "Yes / All is well"
- **Press `2`** $\rightarrow$ "No / Needs attention"
- **No answer / Press 2** $\rightarrow$ Automatically escalates to family members through a 3-tier emergency incident tracker.

---

##  Repository Branch Guide

This project is organized across dedicated branches:

| Branch | Description & Scope |
|---|---|
| **`main`** *(Active)* | **Core System + Complete Cellular Calling:** Full Exotel GSM telephony, 24/7 cloud scheduler (`pg_cron`), custom voice & text question recorder, family guardian dashboard, elder big-touch screen, and 30-second emergency escalation engine. |
| **`koode-development`** | **Child Dashboard & Extended Features:** Dedicated child/grandchild interaction features, kid-friendly voice recording modules, interactive family bonding elements, and customized child workflows. |
| **`dev_koode__call_working`** | Release snapshot branch preserving verified cellular telephony and backend edge function implementations. |

---

##  Key Features in the `main` Branch

### 1. Cellular GSM Calling via Exotel IVR
- **Real Phone Calls:** Initiates outbound telecom calls directly to physical SIM cards (Airtel, Jio, Vi, BSNL) from an Exotel virtual ExoPhone.
- **Auto-Formatting for India:** Automatic stripping of formatting artifacts and zero-prefixing (`0XXXXXXXXXX`) for compliant Indian telecom routing.
- **Dual-Cluster Failover:** Automatically handles connection across `api.in.exotel.com` (Mumbai) and `api.exotel.com`.
- **Transparent Error Reporting:** Real-time in-app diagnosis (e.g. unwhitelisted trial numbers, balance alerts, or authentication mismatch) instead of silent mock fallbacks.

### 2. 24/7 Cloud Calling (Rings Even When App is Closed)
- **Supabase Cloud Scheduler:** Runs autonomously in the PostgreSQL engine via `pg_cron` and `pg_net` every minute.
- **Zero App Dependency:** Calls fire regardless of whether the mobile app is swiped away, the phone screen is locked, or the device is turned off.
- **Customizable Intervals:** Supports daily recurring calls, weekly schedules, custom intervals in minutes, and run counters.

### 3. Voice & Text Question Customization
- **In-App Voice Recorder:** Family members and children can record questions in their own voice using the built-in microphone widget.
- **Audio Prompts Bucket:** Uploads voice recordings to Supabase Storage (`audio-prompts`) with base64 data fallback.
- **Dynamic IVR Playback:** Exotel streams the recorded family voice directly to the elder's call.
- **CRUD Question Management:** Add, enable/disable, reorder, and delete questions with confirmation protection.

### 4. Family Guardian Dashboard
- **Live Well-Being Feed:** Real-time check-in stream powered by Supabase Realtime subscriptions.
- **Instant Call Trigger:** One-tap button to ring the elder phone immediately.
- **Incident Escalation:** Visual cards for flagged concerns, tracking acknowledgement and resolution status.
- **Role Switcher:** Seamlessly toggle between Elder and Family screens anytime using the top-right `⇄` button.

### 5. Elder Friendly Screen
- **High-Contrast, Big Touch Targets:** Designed for low-vision seniors with soothing green and cream aesthetics.
- **One-Touch Emergency SOS:** Dedicated high-priority help button that triggers immediate incident escalation.
- **Built-in Ringtone & Haptics:** Public telecom audio ring loop and haptic vibration for in-app fallback testing.

### 6. Splash Screen & Brand Identity
- **Centered Clean Logo:** Zero background grid artifacts, natural aspect ratio, and custom 512×512 transparent vector canvas.
- **Smooth `AnimatedSwitcher`:** Non-blocking lifecycle animation preventing navigation stack freezes.
- **Native Android Icons:** Custom launcher icons across all screen densities (`mdpi` to `xxxhdpi`).

---

## 🏗️Architecture

```
                       ┌────────────────────────┐
                       │  Supabase Cloud Engine │
                       │   (Postgres + pg_cron) │
                       └───────────┬────────────┘
                                   │ (Every minute)
                                   ▼
                       ┌────────────────────────┐
                       │ Edge: `run-schedules`  │
                       └───────────┬────────────┘
                                   │
                                   ▼
┌──────────────────┐   ┌────────────────────────┐   ┌───────────────────────┐
│   Family App     │──▶│   Edge: `start-call`   │──▶│    Exotel Telephony   │
│ (Schedule/Voice) │   └────────────────────────┘   │       API Gateway     │
└──────────────────┘                                └───────────┬───────────┘
                                                                │ GSM Cellular
                                                                ▼
┌──────────────────┐   ┌────────────────────────┐   ┌───────────────────────┐
│ Supabase Realtime│◀──│ Edge: `exotel-webhook` │◀──│     Elder Phone       │
│    Dashboard     │   │   (Keypad 1 or 2)      │   │  (SIM Call / Dialpad) │
└──────────────────┘   └────────────────────────┘   └───────────────────────┘
```

---

##  Database Schema

- **`elders`**: Core profile, phone number, consent flags, and escalation settings.
- **`checkins`**: History of all initiated calls, timestamps, call status (`INITIATED`, `ANSWERED`, `COMPLETED`), and results (`FINE`, `CONCERN`, `PENDING`).
- **`incidents`**: Emergency events triggered by SOS buttons or pressed keypad answers, tracking 3 escalation stages.
- **`questions`**: Sequence of check-in questions, Malayalam text, custom audio URLs, and keypad options.
- **`answers`**: Granular elder answers recorded per question per call.
- **`call_schedules`**: Timing rules, next run dates, repeat limits, and recurrence intervals.

---

## Quick Start Setup

### 1. Database Setup
Execute the idempotent SQL migration scripts in your **Supabase SQL Editor**:
1. Run `supabase/migrations/001_koode.sql` (Creates base schema & demo records).
2. Run `supabase/migrations/002_custom.sql` (Sets up questions, schedules, audio storage & `pg_cron`).

### 2. Configure Supabase Secrets
In your Supabase project under **Project Settings $\rightarrow$ Edge Functions $\rightarrow$ Secrets**:
```env
EXOTEL_SID=zeblasky1
EXOTEL_KEY=your_exotel_api_key
EXOTEL_TOKEN=your_exotel_api_token
EXOPHONE=09513886363
EXOTEL_APP_ID=your_exotel_applet_id
EXOTEL_HOST=api.in.exotel.com
WEBHOOK_SECRET=koode123
```

### 3. Deploy Supabase Edge Functions
```bash
supabase functions deploy start-call --no-verify-jwt
supabase functions deploy exotel-webhook --no-verify-jwt
supabase functions deploy run-schedules --no-verify-jwt
supabase functions deploy ivr --no-verify-jwt
```

### 4. Run the Flutter App
Ensure Flutter 3.x is installed:
```bash
flutter pub get
flutter run
```

---

## 👥 Contributors & Brand
**ZEBLASKY** · Koode (Since 2026)  
Built with Flutter, Supabase & Exotel.
