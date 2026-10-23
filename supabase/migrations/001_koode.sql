create table elders(id uuid primary key, name text not null, phone text, consent boolean not null default false, consent_at timestamptz);
create table checkins(
  id uuid primary key default gen_random_uuid(), elder_id uuid references elders(id) not null,
  source text not null default 'app', call_sid text unique, call_status text default 'SCHEDULED',
  food boolean, meds boolean, result text not null default 'PENDING'
    check (result in ('PENDING','FINE','CONCERN','UNANSWERED')),
  created_at timestamptz not null default now());
create table incidents(
  id uuid primary key default gen_random_uuid(), elder_id uuid references elders(id) not null,
  trigger text not null, status text not null default 'LEVEL_1_NOTIFIED'
    check (status in ('ACTIVE','LEVEL_1_NOTIFIED','LEVEL_2_NOTIFIED','LEVEL_3_ESCALATION','ACKNOWLEDGED','EN_ROUTE','ARRIVED','RESOLVED','CANCELLED')),
  level int not null default 1, acknowledged_by text, notes text,
  created_at timestamptz not null default now(), last_escalated_at timestamptz not null default now(), resolved_at timestamptz);
create unique index one_open_incident on incidents(elder_id) where status not in ('RESOLVED','CANCELLED');
create table incident_events(id uuid primary key default gen_random_uuid(), incident_id uuid references incidents(id), event text not null, created_at timestamptz default now());

-- Escalation: 30s demo timeout per level. Runs on the server, never in the app.
create or replace function escalate_incidents() returns void language plpgsql as $$
begin
  update incidents set level=2, status='LEVEL_2_NOTIFIED', last_escalated_at=now()
    where status='LEVEL_1_NOTIFIED' and last_escalated_at < now()-interval '30 seconds';
  update incidents set level=3, status='LEVEL_3_ESCALATION', last_escalated_at=now()
    where status='LEVEL_2_NOTIFIED' and last_escalated_at < now()-interval '30 seconds';
end $$;
create or replace function log_incident() returns trigger language plpgsql as $$
begin insert into incident_events(incident_id,event) values (new.id, 'status: '||new.status); return new; end $$;
create trigger incident_audit after insert or update of status on incidents for each row execute function log_incident();

create extension if not exists pg_cron;
select cron.schedule('koode-escalate','30 seconds','select escalate_incidents()');

-- DEMO-ONLY open policies (no login). Replace with auth + per-family RLS before any real use.
alter table elders enable row level security; alter table checkins enable row level security;
alter table incidents enable row level security; alter table incident_events enable row level security;
create policy demo_all on elders for all using (true) with check (true);
create policy demo_all on checkins for all using (true) with check (true);
create policy demo_all on incidents for all using (true) with check (true);
create policy demo_all on incident_events for all using (true) with check (true);
alter publication supabase_realtime add table checkins, incidents, incident_events;

insert into elders values ('00000000-0000-0000-0000-000000000001','Lakshmi Amma','+91XXXXXXXXXX',true,now());
