-- Operations: account creation, leader access, the edit pipeline, payments,
-- social accounts, push devices, webhooks, storage and Crew tiers.

-- ---------------------------------------------------------------- accounts

-- Every new sign in gets a profile row automatically.
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Helpers used by policies. Security definer avoids recursive RLS on profiles.
create or replace function my_brokerage() returns uuid
language sql stable security definer set search_path = public as $$
  select brokerage_id from profiles where id = auth.uid()
$$;

create or replace function i_am_leader() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('teamLead', 'marketCenter', 'brokerageAdmin', 'staff') from profiles where id = auth.uid()), false)
$$;

-- Team leads, MCAs and admins see their agents (free leader accounts).
create policy "leaders read their agents" on profiles for select
  using (i_am_leader() and brokerage_id = my_brokerage());
create policy "leaders read agent clips" on clips for select
  using (i_am_leader() and exists (select 1 from profiles p where p.id = clips.profile_id and p.brokerage_id = my_brokerage()));
create policy "leaders read agent posts" on posts for select
  using (i_am_leader() and exists (select 1 from profiles p where p.id = posts.profile_id and p.brokerage_id = my_brokerage()));

-- Only leaders can post as their brokerage, and only as their own.
drop policy "post as yourself" on community_posts;
create policy "post as yourself" on community_posts for insert with check (
  author_id = auth.uid()
  and (posted_as_brokerage_id is null or (i_am_leader() and posted_as_brokerage_id = my_brokerage()))
  and is_featured = (posted_as_brokerage_id is not null)
);

-- Reports and blocks (App Store requirement for user posts).
alter table reports enable row level security;
alter table blocks enable row level security;
create policy "file reports" on reports for insert with check (reporter_id = auth.uid());
create policy "own blocks" on blocks for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- ---------------------------------------------------------------- edit pipeline

create table editors (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  timezone text not null default 'Europe/Belgrade',
  active boolean not null default true,
  max_open_jobs int not null default 6
);

create table edit_jobs (
  id uuid primary key default gen_random_uuid(),
  clip_id uuid not null references clips on delete cascade,
  stage text not null default 'queued'
    check (stage in ('queued', 'transcribing', 'aiCut', 'rendering', 'editor', 'review', 'revisions', 'done', 'failed')),
  provider text,                 -- submagic, shotstack, internal
  provider_job_id text,
  editor_id uuid references editors,
  due_at timestamptz,
  attempts int not null default 0,
  error text,
  transcript text,
  edit_plan jsonb,               -- Claude's cut list: hook, b-roll, captions, music
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index edit_jobs_stage_idx on edit_jobs (stage, due_at);

alter table editors enable row level security;
alter table edit_jobs enable row level security;
create policy "editors see self" on editors for select using (id = auth.uid());
create policy "editors see their jobs" on edit_jobs for select using (editor_id = auth.uid());
create policy "editors update their jobs" on edit_jobs for update using (editor_id = auth.uid());
create policy "agents see jobs on own clips" on edit_jobs for select
  using (exists (select 1 from clips c where c.id = edit_jobs.clip_id and c.profile_id = auth.uid()));

-- Keep the agent facing clip status in sync with the job stage.
create or replace function sync_clip_status() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update clips set status = case new.stage
    when 'queued' then 'submitted'
    when 'transcribing' then 'submitted'
    when 'aiCut' then 'aiFirstCut'
    when 'rendering' then 'aiFirstCut'
    when 'editor' then 'editorPolish'
    when 'review' then 'readyForReview'
    when 'revisions' then 'revisions'
    when 'done' then 'approved'
    else status end
  where id = new.clip_id;
  new.updated_at = now();
  return new;
end;
$$;

create trigger edit_jobs_sync before insert or update of stage on edit_jobs
  for each row execute function sync_clip_status();

-- ---------------------------------------------------------------- payments

alter table bookings drop constraint bookings_status_check;
alter table bookings add constraint bookings_status_check
  check (status in ('depositPending', 'depositPaid', 'confirmed', 'completed', 'cancelled'));
alter table bookings add column stripe_checkout_session text;

create table purchases (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  kind text not null check (kind in ('deposit', 'credits', 'course', 'membership')),
  product_id text,
  amount_cents int not null,
  stripe_checkout_session text unique,
  status text not null default 'pending' check (status in ('pending', 'paid', 'refunded', 'failed')),
  created_at timestamptz not null default now()
);

create table course_enrollments (
  profile_id uuid not null references profiles on delete cascade,
  course_id text not null,
  enrolled_at timestamptz not null default now(),
  primary key (profile_id, course_id)
);

alter table purchases enable row level security;
alter table course_enrollments enable row level security;
create policy "own purchases" on purchases for select using (profile_id = auth.uid());
create policy "own enrollments" on course_enrollments for select using (profile_id = auth.uid());

create or replace function add_credits(p_profile uuid, p_count int) returns void
language sql security definer set search_path = public as $$
  update profiles set credits = credits + p_count where id = p_profile
$$;
revoke execute on function add_credits(uuid, int) from public, anon, authenticated;

-- ---------------------------------------------------------------- social and devices

-- Posting API profile keys and page tokens. No client policies: Edge Functions only.
create table social_accounts (
  profile_id uuid not null references profiles on delete cascade,
  platform text not null check (platform in ('facebook', 'instagram', 'tiktok', 'youtube')),
  provider text not null default 'ayrshare',
  provider_profile_key text,
  page_id text,                  -- Facebook Page or Instagram business account id
  connected_at timestamptz not null default now(),
  primary key (profile_id, platform)
);
alter table social_accounts enable row level security;

create table devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  apns_token text not null unique,
  updated_at timestamptz not null default now()
);
alter table devices enable row level security;
create policy "own devices" on devices for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Every webhook is stored once, so retries from Stripe or Meta never double count.
create table webhook_events (
  id text primary key,
  source text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);
alter table webhook_events enable row level security;

alter table posts add column city_id text references cities;
alter table leads add column external_comment_id text unique;

-- ---------------------------------------------------------------- storage

insert into storage.buckets (id, name, public) values ('raw-videos', 'raw-videos', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('deliverables', 'deliverables', false) on conflict (id) do nothing;

create policy "upload own raw videos" on storage.objects for insert to authenticated
  with check (bucket_id = 'raw-videos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "read own raw videos" on storage.objects for select to authenticated
  using (bucket_id in ('raw-videos', 'deliverables') and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------- #Cinema Crew tiers

-- Shooters level up on volume closed and five star ratings. Each tier pays a
-- bonus per job and unlocks perks, so the best shooters stay loyal.
create table shooter_tiers (
  id text primary key,
  rank int unique not null,
  name text not null,
  min_jobs int not null,
  min_five_star int not null,
  min_rating numeric not null,
  bonus_cents_per_job int not null default 0,
  level_up_bonus_cents int not null default 0,
  perks text[] not null default '{}'
);

insert into shooter_tiers (id, rank, name, min_jobs, min_five_star, min_rating, bonus_cents_per_job, level_up_bonus_cents, perks) values
  ('rookie', 1, 'Rookie', 0, 0, 0, 0, 0, array['Standard jobs in your market']),
  ('pro', 2, 'Pro', 25, 15, 4.6, 1000, 10000, array['First look at jobs for 15 minutes', 'Pro badge on your profile']),
  ('elite', 3, 'Elite', 100, 70, 4.8, 2500, 50000, array['First pick of luxury and brand shoots', 'Gear stipend', 'Quarterly prize drop']),
  ('legend', 4, 'Legend', 300, 230, 4.9, 5000, 150000, array['Market lead role and training pay', 'Revenue share on shooters you recruit', 'Annual trip']);

alter table shooters
  add column tier text not null default 'rookie' references shooter_tiers,
  add column non_solicit_signed_at timestamptz,
  add column jobs_completed int not null default 0,
  add column five_star_count int not null default 0;

create table job_ratings (
  job_id uuid primary key references jobs on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  rated_by uuid references profiles,
  created_at timestamptz not null default now()
);

alter table shooter_tiers enable row level security;
alter table job_ratings enable row level security;
create policy "tiers readable" on shooter_tiers for select using (true);
create policy "agents rate their shoots" on job_ratings for insert with check (
  rated_by = auth.uid() and exists (
    select 1 from jobs j join bookings b on b.id = j.booking_id
    where j.id = job_ratings.job_id and b.profile_id = auth.uid() and j.status = 'paid'
  )
);
create policy "shooters see their ratings" on job_ratings for select
  using (exists (select 1 from jobs j where j.id = job_ratings.job_id and j.shooter_id = auth.uid()));

-- Recompute a shooter's stats and tier after each rating.
create or replace function refresh_shooter_tier(p_shooter uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_jobs int;
  v_five int;
  v_rating numeric;
  v_tier text;
begin
  select count(*) into v_jobs from jobs where shooter_id = p_shooter and status = 'paid';
  select count(*), coalesce(avg(r.rating), 5) into v_five, v_rating
    from job_ratings r join jobs j on j.id = r.job_id where j.shooter_id = p_shooter;
  select count(*) into v_five from job_ratings r join jobs j on j.id = r.job_id
    where j.shooter_id = p_shooter and r.rating = 5;
  select id into v_tier from shooter_tiers
    where v_jobs >= min_jobs and v_five >= min_five_star and v_rating >= min_rating
    order by rank desc limit 1;
  update shooters set jobs_completed = v_jobs, five_star_count = v_five, rating = round(v_rating, 2), tier = coalesce(v_tier, 'rookie')
    where id = p_shooter;
  return coalesce(v_tier, 'rookie');
end;
$$;

create or replace function on_job_rated() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform refresh_shooter_tier((select shooter_id from jobs where id = new.job_id));
  return new;
end;
$$;

create trigger job_ratings_refresh after insert on job_ratings
  for each row execute function on_job_rated();

-- Third party tokens (Meta page tokens) live in Supabase Vault, read only by Edge Functions.
create or replace function read_secret(secret_name text) returns text
language sql security definer set search_path = public, vault as $$
  select decrypted_secret from vault.decrypted_secrets where name = secret_name limit 1
$$;
revoke execute on function read_secret(text) from public, anon, authenticated;
