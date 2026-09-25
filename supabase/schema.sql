-- JORNY OG database schema — one shared dataset for every device (no login).
-- Run in Supabase: SQL Editor → New query → paste → Run.
-- Safe to run again; it also migrates the earlier per-user version.

create table if not exists public.trips (
  id          text primary key,
  name        text not null,
  destination text not null,
  start_date  date not null,
  end_date    date not null check (end_date >= start_date),
  budget      numeric not null check (budget >= 0),
  currency    text not null default 'THB',
  created_at  timestamptz not null default now()
);

create table if not exists public.activities (
  id         text primary key,
  trip_id    text not null references public.trips (id) on delete cascade,
  date       date not null,
  minutes    int not null check (minutes between 0 and 1439),
  name       text not null,
  note       text not null default '',
  image_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id         text primary key,
  trip_id    text not null references public.trips (id) on delete cascade,
  date       date not null,
  minutes    int not null check (minutes between 0 and 1439),
  title      text not null,
  amount     numeric not null check (amount >= 0),
  category   text not null,
  payment    text not null,
  created_at timestamptz not null default now()
);

create index if not exists activities_trip_id_idx on public.activities (trip_id);
create index if not exists expenses_trip_id_idx on public.expenses (trip_id);

-- Migrate from the per-user version: drop owner policies and columns.
drop policy if exists "own trips" on public.trips;
drop policy if exists "own activities" on public.activities;
drop policy if exists "own expenses" on public.expenses;
alter table public.trips      drop column if exists user_id;
alter table public.activities drop column if exists user_id;
alter table public.expenses   drop column if exists user_id;

-- RLS stays on, with policies that let the app (publishable key) use every row.
-- Anyone who has the app can read and edit all data.
alter table public.trips      enable row level security;
alter table public.activities enable row level security;
alter table public.expenses   enable row level security;

drop policy if exists "shared trips" on public.trips;
create policy "shared trips" on public.trips
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "shared activities" on public.activities;
create policy "shared activities" on public.activities
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "shared expenses" on public.expenses;
create policy "shared expenses" on public.expenses
  for all to anon, authenticated using (true) with check (true);

-- Read-only views for browsing in the Table Editor: each row shows the name
-- of the trip it belongs to. The app itself reads the base tables.
create or replace view public.expense_details
with (security_invoker = true) as
select
  t.name        as trip_name,
  e.date,
  to_char(make_time(e.minutes / 60, e.minutes % 60, 0), 'HH24:MI') as time,
  e.title,
  e.amount,
  t.currency,
  e.category,
  e.payment,
  e.id,
  e.trip_id
from public.expenses e
join public.trips t on t.id = e.trip_id
order by t.name, e.date, e.minutes;

create or replace view public.activity_details
with (security_invoker = true) as
select
  t.name        as trip_name,
  a.date,
  to_char(make_time(a.minutes / 60, a.minutes % 60, 0), 'HH24:MI') as time,
  a.name        as place,
  a.note,
  a.id,
  a.trip_id
from public.activities a
join public.trips t on t.id = a.trip_id
order by t.name, a.date, a.minutes;
