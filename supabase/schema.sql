-- Share Steps MVP schema for Supabase.
-- Run this file in Supabase SQL Editor after creating a project.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  target_steps integer not null default 8000 check (target_steps >= 1),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  created_by uuid references auth.users(id),
  created_at timestamp with time zone default now()
);

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  joined_at timestamp with time zone default now(),
  unique(group_id, user_id)
);

create table if not exists public.step_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  date date not null,
  steps integer not null check (steps >= 0),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(user_id, date)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_step_records_updated_at on public.step_records;
create trigger set_step_records_updated_at
before update on public.step_records
for each row execute function public.set_updated_at();

-- SECURITY DEFINER helpers avoid recursive RLS checks on group_members.
create or replace function public.is_group_member(target_group_id uuid, target_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.group_members
    where group_id = target_group_id
      and user_id = target_user_id
  );
$$;

create or replace function public.shares_group_with(target_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.group_members mine
    join public.group_members theirs on theirs.group_id = mine.group_id
    where mine.user_id = auth.uid()
      and theirs.user_id = target_user_id
  );
$$;

-- Safer MVP invite-code flow:
-- Instead of allowing all authenticated users to SELECT every group by invite_code,
-- the app calls this function. It returns only the joined group id and raises clear
-- errors for missing codes or duplicate membership.
create or replace function public.join_group_by_invite_code(invite_code_input text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  found_group_id uuid;
begin
  if auth.uid() is null then
    raise exception 'ログインが必要です。';
  end if;

  select id
  into found_group_id
  from public.groups
  where invite_code = upper(trim(invite_code_input));

  if found_group_id is null then
    raise exception '招待コードが存在しません。';
  end if;

  if public.is_group_member(found_group_id, auth.uid()) then
    raise exception 'すでに参加済みのグループです。';
  end if;

  insert into public.group_members (group_id, user_id)
  values (found_group_id, auth.uid());

  return found_group_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.step_records enable row level security;

drop policy if exists "profiles_select_own_or_group_members" on public.profiles;
create policy "profiles_select_own_or_group_members"
on public.profiles
for select
to authenticated
using (id = auth.uid() or public.shares_group_with(id));

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "groups_insert_authenticated" on public.groups;
create policy "groups_insert_authenticated"
on public.groups
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "groups_select_own_or_created" on public.groups;
create policy "groups_select_own_or_created"
on public.groups
for select
to authenticated
using (created_by = auth.uid() or public.is_group_member(id, auth.uid()));

drop policy if exists "group_members_select_same_group" on public.group_members;
create policy "group_members_select_same_group"
on public.group_members
for select
to authenticated
using (public.is_group_member(group_id, auth.uid()));

drop policy if exists "group_members_insert_self" on public.group_members;
create policy "group_members_insert_self"
on public.group_members
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "step_records_select_own_or_group_members" on public.step_records;
create policy "step_records_select_own_or_group_members"
on public.step_records
for select
to authenticated
using (user_id = auth.uid() or public.shares_group_with(user_id));

drop policy if exists "step_records_insert_own" on public.step_records;
create policy "step_records_insert_own"
on public.step_records
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "step_records_update_own" on public.step_records;
create policy "step_records_update_own"
on public.step_records
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create index if not exists group_members_group_id_idx on public.group_members(group_id);
create index if not exists group_members_user_id_idx on public.group_members(user_id);
create index if not exists step_records_user_date_idx on public.step_records(user_id, date);
