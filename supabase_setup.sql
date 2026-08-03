-- ============================================================
-- بوابة حي العمارات — Supabase Setup
-- Paste this entire file in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- 1) Join requests (household registrations pending approval)
create table join_requests (
  id bigint generated always as identity primary key,
  name text not null,
  household_size int,
  phone text not null,
  street int not null check (street between 1 and 61),
  bldg text not null default '—',
  tenure text not null default 'owner' check (tenure in ('owner','rent')),
  type text not null default 'house',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table join_requests enable row level security;

create policy "public can submit pending"
  on join_requests for insert to anon
  with check (status = 'pending');

create policy "public sees approved"
  on join_requests for select to anon
  using (status = 'approved');

create policy "admin full access"
  on join_requests for all to authenticated
  using (true) with check (true);

-- Public "who lives here" = names + street only (no phones ever)
create view public_residents as
  select name, street from join_requests where status = 'approved';

-- 2) Street representatives
create table street_reps (
  street int primary key check (street between 1 and 61),
  rep_name text not null,
  rep_phone text not null
);
alter table street_reps enable row level security;
create policy "public reads reps" on street_reps for select to anon using (true);
create policy "admin manages reps" on street_reps for all to authenticated using (true) with check (true);

-- Sample rep for Street 49 (Mohamed Idris — 07958289559)
insert into street_reps (street, rep_name, rep_phone)
  values (49, 'محمد إدريس', '447958289559');

-- 2) Street status (p=power w=water c=cleaning : 0=pending 1=in progress 2=done)
create table street_status (
  street int primary key check (street between 1 and 61),
  p int not null default 0 check (p between 0 and 2),
  w int not null default 0 check (w between 0 and 2),
  c int not null default 0 check (c between 0 and 2),
  updated_at timestamptz not null default now()
);

alter table street_status enable row level security;

create policy "public reads status"
  on street_status for select to anon
  using (true);

create policy "admin manages status"
  on street_status for all to authenticated
  using (true) with check (true);

-- 3) Seed all 31 odd streets
insert into street_status (street) select generate_series(1, 61, 2);

-- 4) Seed the currently known statuses (from the group signals)
update street_status set p=2, w=1, c=2 where street in (11, 47);
update street_status set p=1, w=0, c=2 where street in (1, 3, 5);
update street_status set p=1, w=1, c=2 where street = 15;
update street_status set p=1, w=1, c=1 where street = 35;
update street_status set p=1, w=0, c=1 where street in (7, 9, 13, 21, 37, 41, 49, 51);

-- Done! Next: Authentication → Users → Add user (the admin email + password)
