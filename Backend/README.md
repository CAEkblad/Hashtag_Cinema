# #Cinema backend

Supabase (Postgres, Auth, Storage, Edge Functions) plus Stripe, Ayrshare, Meta and Claude.
The iOS app runs on sample data until `AppConfig` in `Cinema/Services/Integrations.swift` has a real Supabase URL and anon key.

```
Backend/
  supabase/
    config.toml                 CLI settings (webhooks skip JWT checks)
    migrations/
      ..._core.sql              profiles, ideas, clips, bookings, posts, leads, challenges, community, Crew
      ..._markets.sql           regions, cities, idea templates, seasonal moments, market stats
      ..._operations.sql        new user trigger, leader access, edit pipeline, payments, storage, Crew tiers
      ..._florida_cities.sql    every Florida city and town (generated)
      ..._partners.sql          Keller Williams: market centers, join codes, approvals, 10% off, 10% revenue share, office content pool, posters
      ..._hardening.sql         which columns the app may write
    functions/
      generate-ideas            Claude writes ideas for the agent's cities, month, niche and goals
      coach-feedback            Claude coach notes on a clip
      create-checkout           Stripe Checkout: $500 deposit, credit packs, courses (partner discount applied)
      stripe-webhook            marks payments paid, confirms deposits, opens a Crew job, adds credits
      checkout-done             the page people see after paying, with a button back to the app
      request-edit              spends credits, queues the AI cut, assigns a Pro edit to an editor
      publish-post              posts or schedules to Facebook, Instagram, TikTok, YouTube via Ayrshare
      meta-webhook              comment keyword to DM, saves the lead
      crew-dispatch             offers a paid shoot to the best nearby shooters, top tiers first
  tools/build_florida_cities.py rebuilds the city data for the app and the database
```

## How the pieces connect

1. **Sign in.** Email one-time code (no passwords). A trigger creates the profile and matches the partner from the email domain, so `@kw.com` agents are tagged Keller Williams automatically.
2. **Market center.** KW agents join with their MCA's join code (verified instantly) or request a market center and a leader approves it (`review_membership`). Join codes are hidden from agents. Leaders read theirs with `my_join_code()`.
3. **Money.** Every Stripe payment is a `purchases` row. When it is paid, a trigger writes 10% to `revenue_share_ledger` for the agent's verified market center. `market_center_revenue` totals it by month for payouts (Stripe Connect transfers).
4. **Ideas.** `generate-ideas` sends Claude the agent's cities (traits, highlights, neighborhoods), this month's seasonal moments, market stats and what performs locally. The app has the same engine on the phone for offline and demo use.
5. **Editing.** The app uploads the raw clip to `raw-videos/<user id>/`, then `request-edit` spends credits and queues an `edit_jobs` row. A worker (Submagic API first, then Claude plus Shotstack) moves the job through stages. A trigger keeps the clip status in sync for the app. Pro edits get the editor with the fewest open jobs and a 48 hour due time (24 with Rush).
6. **Office content pool.** When a listing clip is approved and the agent shares with their office (on by default), a trigger adds it to `office_assets`. Posters are added from the app. Leaders remix them into office posts with credit to the agent.
7. **Posting and leads.** `publish-post` sends the finished vertical cut to Ayrshare with the caption and keyword. `meta-webhook` watches comments, and when one contains the keyword it sends the agent's DM by private reply and saves a lead.
8. **Crew.** A paid deposit opens a `jobs` row and `crew-dispatch` offers it to up to 3 shooters within 45 miles who signed the non-solicit, ranked by tier, rating and distance. Ratings after each job update the shooter's tier (Rookie, Pro, Elite, Legend) and per job bonus.

## Set it up

1. Create a Supabase project. Install the CLI: `brew install supabase/tap/supabase`.
2. From `Backend/`: `supabase link --project-ref <your ref>` then `supabase db push`.
3. Auth > Email templates: put `{{ .Token }}` in the Magic Link template so emails show the 6 digit code.
4. Add secrets: `supabase secrets set ANTHROPIC_API_KEY=... STRIPE_SECRET_KEY=... STRIPE_WEBHOOK_SECRET=... AYRSHARE_API_KEY=... META_APP_SECRET=... META_VERIFY_TOKEN=...`
   Optional: `ANTHROPIC_MODEL`, `COURSE_PRICE_CENTS`, `SHOOTER_RATE_DEFAULT`, `CREW_RADIUS_MILES`, `EDIT_WORKER_URL`, `EDIT_WORKER_TOKEN`, `CHECKOUT_RETURN_URL`.
5. Deploy: `supabase functions deploy` (config.toml turns off JWT checks for the webhooks).
6. Stripe: add a webhook to `https://<ref>.supabase.co/functions/v1/stripe-webhook` for `checkout.session.completed`.
7. Meta: subscribe the app to Page `feed` and Instagram `comments` with callback `.../functions/v1/meta-webhook`. Store each agent's page token in Vault as `meta_page_token_<profile id>`.
8. Add market centers: `insert into market_centers (partner_id, name, city_id, group_name) values ('kw', 'Keller Williams ...', 'tampa-hillsborough', 'KW Impact');` A join code is generated. Give it to the MCA.
9. In Xcode, put the project URL and anon key in `AppConfig`. Never put the service role key in the app.

## Rebuild the city data

```
python3 Backend/tools/build_florida_cities.py <folder with geonames_fl.json and us_cities.csv>
```
Curated traits, highlights and neighborhoods live at the top of the script. Add cities, towns or other states there.

## Tested

All migrations were applied to Postgres 15 with Supabase-style roles, then checked: partner tagging, join codes hidden from agents, request and approval, the 10% ledger and leader-only revenue view, edit stage to clip status sync, the office pool trigger, and that agents cannot change their own credits, role or verification. Edge Functions pass `deno check` and `deno lint`.
