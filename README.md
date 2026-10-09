# #Cinema iOS app

The content and marketing hub for real estate agents and brokerages. SwiftUI, iOS 17+, Xcode 16+.

## Run it

1. Open `Cinema.xcodeproj` in Xcode.
2. Pick an iPhone simulator at the top and press Run (Cmd R).
3. Sign in with any email. Everything runs on sample data until the backend is connected.

To run on your iPhone: select the **Cinema** target > **Signing & Capabilities** > pick your Team. The camera and teleprompter only work on a real phone; the Simulator shows a demo screen so you can still walk the flow.

## What's in it

| Tab | Screens |
| --- | --- |
| Home | Idea of the day, streak and credits, clips to review, challenges, keep learning, coach note, next shoot |
| Create | Idea feed with AI refresh, idea detail with shot list and script, camera with teleprompter and framing guides, practice mode with coach notes, upload from camera roll, send to editing |
| Library | All clips with filters and search, video review with time-stamped notes, approve or request changes, 3 formats, post or share |
| Community | Feed with likes, remix an idea, report and block, success stories, groups |
| Me | Leads, coach, courses (lessons, filming assignments, certificates), challenges, content calendar, pro shoot booking with $500 deposit, connected accounts, plan and credits, brokerage dashboard |

## Project layout

```
Cinema/
  App/          App entry, tab bar, routes
  Theme/        Brand colors and shared components
  Models/       Data types
  Data/         Sample data (delete when the backend is live)
  Services/     CinemaStore (app state) and service protocols with mock versions
  Features/     One folder per feature
Backend/
  schema.sql    Supabase tables, row level security, credit function
```

The project uses Xcode's synced folders: any new `.swift` file you add inside `Cinema/` is picked up automatically.

## Connect the real backend, one piece at a time

Every outside system sits behind a protocol in `Services/Integrations.swift`. Each has a Mock version today. Replace one at a time and pass the real one into `CinemaStore(...)` in `CinemaApp.swift`.

1. **Supabase (logins and data).** Create a Supabase project, run `Backend/schema.sql` in the SQL editor, then in Xcode: File > Add Package Dependencies > `https://github.com/supabase/supabase-swift`. Put your URL and anon key in `AppConfig`.
2. **Video upload and playback.** Mux or Cloudinary. Upload the recording from `EditRequestView`, save the asset id on the clip.
3. **AI editing.** Implement `AIEditingService` on the backend (Submagic API first, your own Claude plus Shotstack pipeline later). Push status changes back with Supabase Realtime so the Library updates live.
4. **Payments.** Stripe for the $500 deposit and credit packs (`PaymentsService`). Use a web checkout link for memberships.
5. **Posting.** A unified posting API such as Ayrshare for Facebook, Instagram, TikTok and YouTube (`SocialPostingService`).
6. **Lead capture.** Zernio or Meta's private reply API for comment-to-DM, writing leads into the `leads` table.
7. **Ideas and coach.** `IdeaEngine` and `CoachService` call Claude from a Supabase Edge Function. Never put AI keys in the app.

## Before the App Store

- Add an app icon (1024 x 1024) to `Assets.xcassets/AppIcon`.
- Add Sign in with Apple (required when you offer other social logins).
- Report and block are in the community UI; connect them to the `reports` and `blocks` tables.
- Privacy policy URL and App Privacy answers in App Store Connect.
- TestFlight through Xcode Cloud, the same way as LegendaryVibez.
