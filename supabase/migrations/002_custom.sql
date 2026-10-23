-- Custom questions: options = [{"key":"1","label":"Yes","concern":false},{"key":"2","label":"No","concern":true}]
create table questions(
  id uuid primary key default gen_random_uuid(), elder_id uuid references elders(id) not null,
  position int not null default 0, text text not null, audio_url text,
  options jsonb not null default '[{"key":"1","label":"Yes","concern":false},{"key":"2","label":"No","concern":true}]',
  enabled boolean not null default true, created_at timestamptz default now());
create table answers(
  id uuid primary key default gen_random_uuid(), checkin_id uuid references checkins(id) on delete cascade,
  question_id uuid, question_text text, key text, label text, created_at timestamptz default now());
-- Schedule: first call at start_at, then every interval_minutes, repeat_count calls in total.
create table call_schedules(
  id uuid primary key default gen_random_uuid(), elder_id uuid references elders(id) not null,
  start_at timestamptz not null, repeat_count int not null default 1 check (repeat_count >= 1),
  interval_minutes int not null default 1440 check (interval_minutes >= 1),
  runs_done int not null default 0, next_run_at timestamptz not null, active boolean not null default true,
  created_at timestamptz default now());
alter table questions enable row level security; alter table answers enable row level security; alter table call_schedules enable row level security;
create policy demo_all on questions for all using (true) with check (true);   -- DEMO ONLY
create policy demo_all on answers for all using (true) with check (true);
create policy demo_all on call_schedules for all using (true) with check (true);
alter publication supabase_realtime add table questions, call_schedules, answers;
do $$ begin alter publication supabase_realtime add table elders; exception when others then null; end $$;
insert into questions(elder_id, position, text) values
 ('00000000-0000-0000-0000-000000000001', 1, 'Have you eaten your food?'),
 ('00000000-0000-0000-0000-000000000001', 2, 'Have you taken your medicines on time?');
-- Server timer: every minute, ask run-schedules to place due calls. Replace SECRET with your WEBHOOK_SECRET.
create extension if not exists pg_net;
select cron.schedule('koode-run-schedules','* * * * *',
 $$select net.http_post(url:='https://gyxiihsdwhwjzgxjnmeg.supabase.co/functions/v1/run-schedules?k=SECRET')$$);