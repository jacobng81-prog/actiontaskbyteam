-- Creates the table behind the Action Tracker. Safe to run more than once.
-- Run in the Supabase dashboard: SQL Editor > New query > paste > Run.

create extension if not exists pgcrypto;

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
