-- Trends feed: video formats that are working for agents on TikTok, Instagram
-- and Facebook, and real example videos for each one.
--
-- The app ships with its own list of formats (TrendLibrary in Models/Trends.swift).
-- Rows here add new formats or update the built in ones by id (heat, examples).
-- Examples come from three places:
--   instagram_api  trends-refresh pulls top media for real estate hashtags through
--                  the official Instagram Graph API (Instagram Public Content Access)
--   curator        the CloseUp team adds TikTok, Facebook or Instagram links by hand
--   agent          links agents paste into "Saw a video you liked?" (never shown until approved)
-- We store the link, caption and counts only, and always link out to the platform.

create table trends (
  id text primary key,
  title text not null,
  format text not null,
  platforms text[] not null default '{tiktok,instagram,facebook}',
  hashtags text[] not null default '{}',
  search_phrase text not null default '',
  hook text not null,
  why_it_works text not null default '',
  beats text[] not null default '{}',
  script text not null default '',
  seconds int not null default 30,
  category text not null default 'listingTour',
  heat int not null default 2 check (heat between 1 and 3),
  uses_listing boolean not null default false,
  keywords text[] not null default '{}',
  audio_tip text,
  active boolean not null default false,
  sort int not null default 100,
  updated_at timestamptz not null default now()
);

create table trend_examples (
  id uuid primary key default gen_random_uuid(),
  trend_id text references trends on delete set null,
  platform text not null check (platform in ('tiktok', 'instagram', 'facebook')),
  url text not null unique,
  caption text,
  creator text,
  views bigint,
  likes bigint,
  comments bigint,
  thumbnail_url text,
  posted_at timestamptz,
  source text not null default 'curator' check (source in ('instagram_api', 'curator', 'agent')),
  external_id text,
  approved boolean not null default false,
  classified_at timestamptz,
  submitted_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now()
);
create index trend_examples_trend on trend_examples (trend_id, approved, posted_at desc);
create index trend_examples_unclassified on trend_examples (created_at) where classified_at is null;

-- Instagram allows 30 unique hashtag searches per 7 days, so ids are looked up once and kept.
create table ig_hashtags (
  tag text primary key,
  hashtag_id text not null,
  looked_up_at timestamptz not null default now()
);

alter table trends enable row level security;
alter table trend_examples enable row level security;
alter table ig_hashtags enable row level security;

create policy "active trends readable" on trends for select using (auth.role() = 'authenticated' and active);
create policy "approved examples readable" on trend_examples for select using (auth.role() = 'authenticated' and approved);
-- Writes go through Edge Functions with the service role. No client policies for insert or update.

-- Heat follows how many approved examples each format picked up in the last 7 days.
create or replace function refresh_trend_heat() returns void language sql security definer set search_path = public as $$
  update trends t set heat = case
      when c.recent >= 8 then 3
      when c.recent >= 3 then 2
      else 1 end,
    updated_at = now()
  from (
    select t2.id, count(e.id) filter (where e.approved and coalesce(e.posted_at, e.created_at) > now() - interval '7 days') as recent
    from trends t2 left join trend_examples e on e.trend_id = t2.id
    group by t2.id
  ) c
  where c.id = t.id and t.active;
$$;
revoke all on function refresh_trend_heat() from public, anon, authenticated;

-- The built in formats, so heat and examples have something to attach to.
-- Text lives in the app; these rows only need ids and the fields the classifier reads.
insert into trends (id, title, format, hook, keywords, category, uses_listing, active, sort) values
  ('reverse-tour', 'The reverse tour', 'Show the best rooms first and hold the price until the very end.', 'Guess the price of this home before I tell you.', '{guess the price,price reveal,how much,tour}', 'listingTour', true, true, 1),
  ('what-price-gets', 'What this price gets you', 'Same budget, two or three neighborhoods, side by side.', 'Here''s what this price gets you here versus there.', '{gets you,budget,versus,for the price}', 'marketUpdate', false, true, 2),
  ('pov-keys', 'POV: you just got the keys', 'A closing day moment from your buyer''s point of view.', 'POV: you just got the keys.', '{pov,keys,closing day,first home,homeowner}', 'clientStory', false, true, 3),
  ('buyer-red-flags', 'Things I''d never do as a buyer', 'A fast countdown of mistakes, one per clip.', '3 things I''d never do when buying a home.', '{never,mistakes,red flags}', 'mythBuster', false, true, 4),
  ('green-screen-react', 'Green screen listing breakdown', 'Stand in front of your listing photos and point out what makes it special.', 'Let''s break down this listing.', '{green screen,breakdown,review,zillow}', 'listingTour', true, true, 5),
  ('hidden-feature', 'This house has a secret', 'Tease one surprising feature, then reveal it.', 'This home has a feature you''ll never guess.', '{secret,hidden,never guess,wait for it}', 'listingTour', true, true, 6),
  ('moving-here', 'Moving to your city? Watch this', 'A quick welcome tour with 4 or 5 things people should know.', 'Moving here? Here''s what nobody tells you.', '{moving to,relocating,nobody tells you,living in}', 'neighborhood', false, true, 7),
  ('day-in-life', 'A day in the life of an agent', 'Fast clips from your real day, start to finish.', 'A real day in the life of a real estate agent.', '{day in the life,ditl,realtor life,come with me}', 'dayInLife', false, true, 8),
  ('myth-fact', 'Myth or fact', 'Say a myth, slap a big MYTH on screen, then the truth.', 'You need 20% down to buy a home. Myth.', '{myth,fact,true or false,misconception}', 'mythBuster', false, true, 9),
  ('reply-comment', 'Replying to a comment', 'Pin a real comment or question on screen and answer it.', 'Someone asked me if now is a bad time to buy.', '{replying to,someone asked,you asked,question}', 'mythBuster', false, true, 10),
  ('almost-fell-apart', 'The deal that almost fell apart', 'A short story with one turning point and a happy ending.', 'This deal almost fell apart 3 days before closing.', '{almost fell apart,fell through,story time}', 'clientStory', false, true, 11),
  ('open-house-setup', 'Set up my open house with me', 'Time lapse of signs, lights and snacks, ending with the door opening.', 'Come set up my open house with me.', '{open house,set up with me}', 'openHouse', true, true, 12),
  ('tier-list', 'Ranking neighborhoods', 'A tier list of local areas from S to C with one reason each.', 'Ranking neighborhoods as an agent.', '{ranking,tier list,rating,best neighborhoods}', 'neighborhood', false, true, 13),
  ('staging-before-after', 'Before and after', 'Same angle, before and after the clean up, staging or photos.', 'Same house. Same room. Watch what a little prep did.', '{before and after,transformation,staging}', 'listingTour', true, true, 14);
