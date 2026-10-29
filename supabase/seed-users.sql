-- Creates the first three team users in Supabase Auth (auth.users) with the
-- default password "password". Run after setup.sql. Safe to run more than once.
--
-- Sign in with the username only (priya, dan, marcus). The app turns it into
-- <username>@actiontracker.app, which is how Supabase Auth stores it.
--
-- CHANGE THESE PASSWORDS after first sign-in (Team > Change my password).

do $$
declare
  u record;
  uid uuid;
begin
  for u in
    select * from (values
      ('priya',  'Priya'),
      ('dan',    'Dan'),
      ('marcus', 'Marcus')
    ) as t(username, display_name)
  loop
    if exists (select 1 from auth.users where email = u.username || '@actiontracker.app') then
      continue;
    end if;
    uid := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) values (
      '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
      u.username || '@actiontracker.app',
      extensions.crypt('password', extensions.gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"],"team_member":true}'::jsonb,
      jsonb_build_object('username', u.username, 'display_name', u.display_name, 'email_verified', true),
      now(), now(),
      '', '', '', '', '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (
      gen_random_uuid(), uid, uid::text,
      jsonb_build_object('sub', uid::text, 'email', u.username || '@actiontracker.app', 'email_verified', true, 'phone_verified', false),
      'email', now(), now(), now()
    );
  end loop;
end $$;
