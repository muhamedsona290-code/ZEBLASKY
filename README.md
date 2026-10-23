# Koode setup (5 steps)
1. `flutter create . --platforms=android,ios` (in this folder), then `flutter pub get`.
2. Supabase: run `supabase/migrations/001_koode.sql` in the SQL editor. Put your phone in `elders` row (+91...) and consent stays true.
3. Edit `lib/config.dart` (URL + anon key).
4. Deploy functions: `supabase functions deploy start-call exotel-webhook --no-verify-jwt`
   Secrets: `supabase secrets set EXOTEL_SID= EXOTEL_KEY= EXOTEL_TOKEN= EXOPHONE= EXOTEL_APP_ID= WEBHOOK_SECRET=<random>`
5. Exotel dashboard: build a flow: Greeting audio (Malayalam MP3 you record) -> Gather (food question, 1/2) -> Passthru
   `https://<proj>.supabase.co/functions/v1/exotel-webhook?k=<WEBHOOK_SECRET>&q=food` -> Gather (medicine question) -> Passthru `...&q=meds`.
   Use that flow's App ID as EXOTEL_APP_ID. Trial accounts only call verified numbers.
Run: `flutter run` on both phones; pick "Elder" on one and "Family" on the other.
# ZEBLASKY
