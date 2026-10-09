# #Cinema iOS app

The content and marketing hub for real estate agents and brokerages. SwiftUI, iOS 17+, Xcode 16+.

## Run it

1. Open `Cinema.xcodeproj` in Xcode.
2. Pick an iPhone simulator at the top and press Run (Cmd R).
3. Sign in with any email (use one ending in @kw.com to see KW mode). Everything runs on sample data until the backend is connected.

To run on your iPhone: select the **Cinema** target > **Signing & Capabilities** > pick your Team. The camera and teleprompter only work on a real phone; the Simulator shows a demo screen so you can still walk the flow.

## What's in it

| Tab | Screens |
| --- | --- |
| Home | Setup checklist, today's 4 step plan, weekly video goal, My market, idea of the day, posters, challenges, courses, coach note, next shoot, help |
| Create | Tips, upload, practice, poster maker, local idea pack, idea feed by category with city tags, camera with teleprompter, send to editing |
| Library | All clips with filters and search, review with time stamped notes, approve or request changes, 3 formats, post or share |
| Community | Feed, remix an idea, report and block, success stories, groups |
| Me | Keller Williams card and market center, leader tools (post as me, team or office, office content pool, join requests, revenue share), My market, leads, coach, courses, challenges, posters, calendar, pro shoots, reminders, connected accounts, plan and credits, help |

**Florida markets.** Every Florida city and town (787) with county, region, traits, highlights and neighborhoods is bundled in `Data/florida_cities.json`. The local idea engine (`Services/LocalIdeaEngine.swift`) writes ideas from city traits, the month (homestead deadline, hurricane season, snowbirds, spring training, property tax discount...), the agent's niche and goals, across their home city and up to 6 more cities they serve.

**Keller Williams.** Signing in with an `@kw.com` email turns on KW mode: KW card with their email, 10% off every plan and credit pack, and a required market center step (join code, or request and the MCA approves). Market centers earn 10% of their agents' revenue. Demo mode has sample market centers. Try code `TAMPA1`.

**Poster maker.** Just listed, coming soon, open house, under contract, price improved and just sold posters from up to 4 listing photos. Three styles, story, post and square sizes, auto caption with a comment keyword, share sheet. Posters go to the office content pool.

## Project layout

```
Cinema/
  App/          App entry, tab bar, routes, tips
  Theme/        Brand colors and shared components
  Models/       Data types, Florida markets, partners
  Data/         Sample data and florida_cities.json
  Services/     CinemaStore, local idea engine, reminders, service protocols
  Services/Backend/  Supabase client and live services
  Features/     One folder per feature
Backend/        Supabase migrations, Edge Functions and tools (see Backend/README.md)
```

The project uses Xcode's synced folders: any new file you add inside `Cinema/` is picked up automatically.

## Connect the real backend

Follow `Backend/README.md`, then put the Supabase URL and anon key in `AppConfig` (`Services/Integrations.swift`). The app switches from sample data to the live services on its own: email code sign in, AI ideas and coach, uploads and edit requests, Stripe Checkout, and posting. If the network fails, ideas fall back to the on-phone engine.

## Before the App Store

- Sign in is email code only, so Sign in with Apple is not required. Add it if you add Google or Facebook login.
- Report and block are in the community UI; connect them to the `reports` and `blocks` tables.
- Privacy policy URL and App Privacy answers in App Store Connect.
- TestFlight through Xcode Cloud, the same way as LegendaryVibez.
