-- Everything the Action Tracker needs in Supabase. Safe to run more than once.
-- Run in the Supabase dashboard: SQL Editor > New query > paste > Run.
-- Then run seed-users.sql to create the first users, and deploy the create-user function.

create extension if not exists pgcrypto;

-- 1. Actions
create table if not exists public.meeting_actions (
  id uuid primary key default gen_random_uuid(),
  what text not null check (char_length(what) between 1 and 300),
  owner text not null check (char_length(owner) between 1 and 80),
  due date not null,
  done boolean not null default false,
  is_example boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists meeting_actions_owner_idx on public.meeting_actions (owner);
create index if not exists meeting_actions_due_idx on public.meeting_actions (due);
alter table public.meeting_actions enable row level security;

-- 2. Profiles: one row per team member, linked to Supabase Auth (auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{2,30}$'),
  display_name text not null check (char_length(display_name) between 1 and 60),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- Create a profile automatically when a TEAM user is added to auth.users.
-- Only accounts flagged app_metadata.team_member = true get one, so a stranger
-- who self-registers with the public key gets no profile and no data access.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(new.raw_app_meta_data ->> 'team_member', '') = 'true' then
    insert into public.profiles (id, username, display_name)
    values (
      new.id,
      coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
      coalesce(new.raw_user_meta_data ->> 'display_name', initcap(split_part(new.email, '@', 1)))
    );
  end if;
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to supabase_auth_admin;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. Link actions to users
alter table public.meeting_actions
  add column if not exists owner_id uuid references public.profiles (id) on delete set null,
  add column if not exists created_by uuid default auth.uid() references auth.users (id) on delete set null;
create index if not exists meeting_actions_owner_id_idx on public.meeting_actions (owner_id);

-- Keep the readable owner name in step with the linked user
create or replace function public.sync_action_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.owner_id is not null then
    select p.display_name into new.owner from public.profiles p where p.id = new.owner_id;
  end if;
  return new;
end;
$$;
drop trigger if exists meeting_actions_sync_owner on public.meeting_actions;
create trigger meeting_actions_sync_owner
  before insert or update of owner_id on public.meeting_actions
  for each row execute function public.sync_action_owner();

-- 4. Access: signed-in team members only. The public key alone sees nothing.
drop policy if exists "actions_select" on public.meeting_actions;
drop policy if exists "actions_insert" on public.meeting_actions;
drop policy if exists "actions_update" on public.meeting_actions;
drop policy if exists "actions_delete" on public.meeting_actions;
drop policy if exists "profiles_select" on public.profiles;

create policy "actions_select" on public.meeting_actions for select to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true');
create policy "actions_insert" on public.meeting_actions for insert to authenticated
  with check ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true');
create policy "actions_update" on public.meeting_actions for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true');
create policy "actions_delete" on public.meeting_actions for delete to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true');
create policy "profiles_select" on public.profiles for select to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'team_member') = 'true');

revoke all on public.meeting_actions from anon;
revoke all on public.profiles from anon;
revoke insert, update, delete on public.profiles from authenticated;
revoke update on public.meeting_actions from authenticated;
grant update (done) on public.meeting_actions to authenticated;
