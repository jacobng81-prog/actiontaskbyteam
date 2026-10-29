# Action Tracker

A meeting action tracker for teams that keep forgetting what was agreed. Add an action with an owner and a due date, see actions grouped by owner with a tick box, and watch open, done and overdue counts. Overdue actions turn red.

It is one static page (`index.html`) that stores its data in Supabase, so everyone sees the same list.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole app. No build step. |
| `vercel.json` | Security headers for Vercel, including a policy that only lets the page talk to your Supabase project. |
| `supabase/setup.sql` | Creates the `meeting_actions` table. |
| `supabase/policies.sql` | Lets the site read and write the table. Read the warning at the top before running it. |

## Set up

1. In Supabase, open **SQL Editor** and run `supabase/setup.sql`, then `supabase/policies.sql`. (If the table already exists, only run `policies.sql`.)
2. In Vercel, choose **Add New > Project**, import this GitHub repo, leave every setting at its default (Framework Preset: **Other**, no build command, no output directory), and deploy.
3. Open the Vercel address. The corner of the page should say "Live".

## Supabase details

The page uses the project URL and publishable key near the top of the script in `index.html`. The publishable key is meant to be public, and what it can do is controlled by the policies in `supabase/policies.sql`. Never put a `service_role` or secret key in this repo.

If you move to a different Supabase project, change `SUPABASE_URL` and `SUPABASE_KEY` in `index.html` and the host in the `connect-src` part of `vercel.json`.

## Who can see the list

With the included policies, anyone who has the site address can read and change the list. Keep the address within your team, or add Supabase Auth and restrict the policies to signed-in users.
