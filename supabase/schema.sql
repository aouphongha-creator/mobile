-- JORNY OG database schema.
-- Run once in Supabase: SQL Editor → New query → paste → Run.
-- Also enable: Authentication → Sign In / Providers → "Allow anonymous sign-ins".

create table if not exists public.trips (
  id          text primary key,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
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
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
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
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
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

-- Row Level Security: each user (including anonymous ones) sees only their rows.
alter table public.trips      enable row level security;
alter table public.activities enable row level security;
alter table public.expenses   enable row level security;

drop policy if exists "own trips" on public.trips;
create policy "own trips" on public.trips
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "own activities" on public.activities;
create policy "own activities" on public.activities
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "own expenses" on public.expenses;
create policy "own expenses" on public.expenses
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
