# Action Tracker

A meeting action tracker for teams that keep forgetting what was agreed. Team members sign in, add an action with an owner and a due date, tick actions off, and see open, done and overdue counts. Actions are grouped by owner and overdue ones turn red.

It is one static page (`index.html`) backed by Supabase: Supabase Auth for sign in, a Postgres table for the data, and one edge function for adding users.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole app. No build step. |
| `vercel.json` | Security headers for Vercel, including a policy that only lets the page talk to your Supabase project. |
| `supabase/setup.sql` | Tables (`meeting_actions`, `profiles`), the link to `auth.users`, and the security rules. |
| `supabase/seed-users.sql` | Creates the first users: `priya`, `dan`, `marcus`. |
| `supabase/functions/create-user/index.ts` | Edge function that lets a signed-in team member add a user with an initial password. |

## How sign in works

- Users live in Supabase's built-in `auth.users` table, so passwords are stored as hashes by Supabase. The app never stores or sees them.
- You sign in with a **username**. Behind the scenes it is stored as `<username>@actiontracker.app`. No email is ever sent.
- `public.profiles` links each auth user to a username and display name. Actions are linked to a user through `meeting_actions.owner_id`.
- Only accounts marked `team_member` in Supabase Auth can read or change data. Anyone else, including a stranger who registers with the public key, sees nothing.

## Sample users

| Username | Initial password |
| --- | --- |
| `priya` | `password` |
| `dan` | `password` |
| `marcus` | `password` |

`password` is a placeholder. Each person should change it after their first sign in: **Team > Change my password**.

## Set up (new project)

1. Supabase SQL Editor: run `supabase/setup.sql`, then `supabase/seed-users.sql`.
2. Deploy the edge function: `supabase functions deploy create-user`. Keep JWT verification on.
3. Supabase dashboard, **Authentication > Sign In / Providers**: turn off **Allow new users to sign up**. This stops strangers creating accounts, on top of the database rules.
4. In `index.html`, set `SUPABASE_URL` and `SUPABASE_KEY` (the publishable key) near the top of the script. Update the host in `connect-src` in `vercel.json` to match.
5. Vercel: **Add New > Project**, import this repo, leave every setting at its default (Framework Preset **Other**, no build command, no output directory), and deploy.

Never put a `service_role` or secret key in this repo. The edge function reads its own key from Supabase.

## Adding users

Open **Team**, enter a username, display name and an initial password (8 characters or more), and press **Add user**. Any signed-in team member can do this. Give the person their initial password directly.

To limit this to certain people, add an `is_admin` flag to `profiles` and check it in `create-user/index.ts`.
