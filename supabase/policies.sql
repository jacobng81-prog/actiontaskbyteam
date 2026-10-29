-- Lets the deployed site read and write the table with the publishable key.
-- Run once in the Supabase dashboard: SQL Editor > New query > paste > Run.
--
-- READ THIS FIRST: the publishable key is visible to anyone who opens the site,
-- so these policies mean anyone who knows the site address can read, add, tick
-- and delete actions. That is fine for an internal link shared with one team.
-- If the list must be private, add Supabase Auth and change `to anon, authenticated`
-- to `to authenticated` below.

drop policy if exists "actions_select" on public.meeting_actions;
drop policy if exists "actions_insert" on public.meeting_actions;
drop policy if exists "actions_update" on public.meeting_actions;
drop policy if exists "actions_delete" on public.meeting_actions;

create policy "actions_select" on public.meeting_actions
  for select to anon, authenticated using (true);

create policy "actions_insert" on public.meeting_actions
  for insert to anon, authenticated with check (true);

create policy "actions_update" on public.meeting_actions
  for update to anon, authenticated using (true) with check (true);

create policy "actions_delete" on public.meeting_actions
  for delete to anon, authenticated using (true);

-- Visitors may only change whether an action is done, not rewrite its text, owner or date.
revoke update on public.meeting_actions from anon, authenticated;
grant update (done) on public.meeting_actions to anon, authenticated;
