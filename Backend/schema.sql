-- #Cinema backend schema for Supabase (Postgres).
-- Paste into Supabase > SQL Editor and run once.
-- Business rules (credits, challenge scoring) live in the backend so the
-- iOS, web and Android apps all share them.

create table brokerages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  seats int not null default 10,
  credit_pool int not null default 0,
  brand_kit jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  email text not null,
  brokerage_id uuid references brokerages,
  role text not null default 'agent' check (role in ('agent', 'teamLead', 'brokerageAdmin', 'staff')),
  plan text not null default 'starter' check (plan in ('starter', 'creator', 'pro', 'brokerage')),
  market text,
  niche text,
  credits int not null default 0,
  streak_days int not null default 0,
  points int not null default 0,
  created_at timestamptz not null default now()
);

create table ideas (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles on delete cascade, -- null = shared #Cinema idea
  title text not null,
  hook text not null,
  category text not null,
  shots text[] not null default '{}',
  script text not null,
  target_seconds int not null default 30,
  why_it_works text,
  remixed_from uuid,
  created_at timestamptz not null default now()
);

create table clips (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  idea_id uuid references ideas,
  title text not null,
  source text not null check (source in ('phoneEdit', 'proShoot')),
  listing text,
  status text not null default 'submitted'
    check (status in ('submitted', 'aiFirstCut', 'editorPolish', 'readyForReview', 'revisions', 'approved')),
  style text not null default 'bold',
  pro_edit boolean not null default false,
  rush boolean not null default false,
  credit_cost int not null default 1,
  raw_video_path text,          -- Supabase Storage or Mux upload id
  vertical_url text,            -- 9:16
  square_url text,              -- 1:1
  wide_url text,                -- 16:9
  duration_seconds int,
  is_favorite boolean not null default false,
  edit_tags jsonb not null default '{}'::jsonb, -- hook type, length, captions, music: feeds the "what works" loop
  created_at timestamptz not null default now()
);

create table clip_comments (
  id uuid primary key default gen_random_uuid(),
  clip_id uuid not null references clips on delete cascade,
  author_id uuid not null references profiles,
  timestamp_seconds numeric not null default 0,
  body text not null,
  created_at timestamptz not null default now()
);

create table bookings (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  service text not null,
  starts_at timestamptz not null,
  address text,
  notes text,
  status text not null default 'depositPaid' check (status in ('depositPaid', 'confirmed', 'completed', 'cancelled')),
  deposit_cents int not null default 50000,
  stripe_payment_intent text,
  calendar_event_id text,       -- Google Calendar "Shoots" event
  created_at timestamptz not null default now()
);

create table posts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  clip_id uuid not null references clips on delete cascade,
  platforms text[] not null,
  caption text not null,
  scheduled_for timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'posted', 'failed')),
  lead_keyword text,
  dm_message text,
  external_ids jsonb not null default '{}'::jsonb,
  views int not null default 0,
  likes int not null default 0,
  comments int not null default 0,
  avg_watch_seconds numeric,
  created_at timestamptz not null default now()
);

create table leads (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  post_id uuid references posts on delete set null,
  name text,
  handle text,
  platform text not null,
  keyword text,
  message text,
  status text not null default 'new' check (status in ('new', 'contacted', 'booked')),
  created_at timestamptz not null default now()
);

create table challenges (
  id uuid primary key default gen_random_uuid(),
  brokerage_id uuid references brokerages, -- null = national
  title text not null,
  subtitle text,
  total_days int not null,
  prize text,
  starts_on date not null default current_date
);

create table challenge_entries (
  challenge_id uuid not null references challenges on delete cascade,
  profile_id uuid not null references profiles on delete cascade,
  completed_days int not null default 0,
  last_check_in date,
  points int not null default 0,
  primary key (challenge_id, profile_id)
);

create table coach_tips (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  clip_id uuid references clips on delete cascade,
  area text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table community_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  detail text,
  icon text,
  brokerage_id uuid references brokerages, -- set = private office group
  created_at timestamptz not null default now()
);

create table group_members (
  group_id uuid not null references community_groups on delete cascade,
  profile_id uuid not null references profiles on delete cascade,
  primary key (group_id, profile_id)
);

create table community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles on delete cascade,
  group_id uuid references community_groups on delete cascade,
  kind text not null check (kind in ('win', 'idea', 'question', 'lesson')),
  body text not null,
  stat text,
  template_idea_id uuid references ideas,
  likes int not null default 0,
  replies int not null default 0,
  created_at timestamptz not null default now()
);

-- Apple requires report and block for apps with user posts.
create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references profiles,
  community_post_id uuid references community_posts on delete cascade,
  reason text,
  created_at timestamptz not null default now()
);

create table blocks (
  blocker_id uuid not null references profiles on delete cascade,
  blocked_id uuid not null references profiles on delete cascade,
  primary key (blocker_id, blocked_id)
);

-- Row level security: every agent sees only their own rows.
alter table profiles enable row level security;
alter table ideas enable row level security;
alter table clips enable row level security;
alter table clip_comments enable row level security;
alter table bookings enable row level security;
alter table posts enable row level security;
alter table leads enable row level security;
alter table coach_tips enable row level security;
alter table community_posts enable row level security;

create policy "own profile" on profiles for all using (auth.uid() = id);
create policy "own or shared ideas" on ideas for select using (profile_id is null or profile_id = auth.uid());
create policy "own ideas write" on ideas for insert with check (profile_id = auth.uid());
create policy "own clips" on clips for all using (profile_id = auth.uid());
create policy "own bookings" on bookings for all using (profile_id = auth.uid());
create policy "own posts" on posts for all using (profile_id = auth.uid());
create policy "own leads" on leads for all using (profile_id = auth.uid());
create policy "own coach tips" on coach_tips for select using (profile_id = auth.uid());
create policy "comments on own clips" on clip_comments for all
  using (exists (select 1 from clips c where c.id = clip_id and c.profile_id = auth.uid()));
create policy "community is readable" on community_posts for select using (auth.role() = 'authenticated');
create policy "post as yourself" on community_posts for insert with check (author_id = auth.uid());

-- Spend credits atomically when an edit is requested.
create or replace function request_edit(p_clip_id uuid, p_cost int)
returns void language plpgsql security definer as $$
begin
  update profiles set credits = credits - p_cost
  where id = auth.uid() and credits >= p_cost;
  if not found then
    raise exception 'not enough credits';
  end if;
  update clips set status = 'submitted', credit_cost = p_cost where id = p_clip_id and profile_id = auth.uid();
end;
$$;

-- #Cinema Crew (shooter app). Every booking becomes a job.
create table shooters (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  market text not null,
  home_lat numeric,
  home_lng numeric,
  skills text[] not null default '{}',           -- listing, drone, brandVideo, event, podcast
  status text not null default 'applied' check (status in ('applied', 'vetting', 'active', 'paused')),
  background_check_status text,
  insurance_expires_on date,
  part107_expires_on date,                        -- FAA drone certificate
  stripe_account_id text,                         -- Stripe Connect payouts and tax forms
  rating numeric not null default 5,
  created_at timestamptz not null default now()
);

create table jobs (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings on delete cascade,
  market text not null,
  job_type text not null,
  shooter_id uuid references shooters,
  status text not null default 'open'
    check (status in ('open', 'offered', 'accepted', 'checkedIn', 'uploaded', 'qcFailed', 'qcPassed', 'paid', 'cancelled')),
  shooter_rate_cents int not null,
  bonus_cents int not null default 0,
  checked_in_at timestamptz,
  uploaded_at timestamptz,
  qc_notes text,
  created_at timestamptz not null default now()
);

create table job_offers (
  job_id uuid not null references jobs on delete cascade,
  shooter_id uuid not null references shooters on delete cascade,
  offered_at timestamptz not null default now(),
  response text check (response in ('accepted', 'declined', 'expired')),
  primary key (job_id, shooter_id)
);

create table payouts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references jobs,
  shooter_id uuid not null references shooters,
  amount_cents int not null,
  stripe_transfer_id text,
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed')),
  created_at timestamptz not null default now()
);

alter table shooters enable row level security;
alter table jobs enable row level security;
alter table payouts enable row level security;
create policy "own shooter profile" on shooters for all using (auth.uid() = id);
create policy "see open jobs or own jobs" on jobs for select using (status = 'open' or shooter_id = auth.uid());
create policy "own payouts" on payouts for select using (shooter_id = auth.uid());
