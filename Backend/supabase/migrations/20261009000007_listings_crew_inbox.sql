-- Find a photographer directory, listings and open houses, activity inbox,
-- referrals and saved scripts.

-- ---------------------------------------------------------------- shooter directory

alter table shooters
  add column bio text,
  add column years_shooting int not null default 0,
  add column response_time text,
  add column gear text,
  add column background_checked boolean not null default false,
  add column insured boolean not null default false,
  add column city_id text references cities;

create table shooter_portfolio (
  id uuid primary key default gen_random_uuid(),
  shooter_id uuid not null references shooters on delete cascade,
  title text not null,
  storage_path text not null,
  is_video boolean not null default false,
  sort int not null default 0
);

create table favorite_shooters (
  profile_id uuid not null references profiles on delete cascade,
  shooter_id uuid not null references shooters on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, shooter_id)
);

-- Agents see active, vetted shooters only, and never their contact details.
-- All booking and messaging goes through #Cinema so clients stay with #Cinema.
create view shooter_directory with (security_invoker = false) as
select s.id, s.name, s.city_id, s.market, s.bio, s.skills, s.tier, s.rating, s.jobs_completed, s.five_star_count,
       s.years_shooting, s.response_time, s.background_checked, s.insured,
       (s.part107_expires_on is not null and s.part107_expires_on >= current_date) as has_part107
from shooters s
where s.status = 'active' and s.non_solicit_signed_at is not null;
grant select on shooter_directory to authenticated;

alter table bookings
  add column requested_shooter_id uuid references shooters,
  add column package_id text,
  add column add_ons text[] not null default '{}',
  add column estimated_total_cents int;

alter table shooter_portfolio enable row level security;
alter table favorite_shooters enable row level security;
create policy "portfolio readable" on shooter_portfolio for select using (auth.role() = 'authenticated');
create policy "own favorites" on favorite_shooters for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Crew applications from the app ("Join #Cinema Crew").
create table crew_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid references auth.users on delete set null,
  name text not null,
  email text not null,
  phone text,
  city_id text references cities,
  skills text[] not null default '{}',
  portfolio_url text,
  years_shooting int,
  has_insurance boolean not null default false,
  has_part107 boolean not null default false,
  agreed_non_solicit boolean not null,
  status text not null default 'new' check (status in ('new', 'reviewing', 'approved', 'declined')),
  created_at timestamptz not null default now()
);
alter table crew_applications enable row level security;
create policy "apply" on crew_applications for insert with check (agreed_non_solicit and (applicant_id is null or applicant_id = auth.uid()));
create policy "see own application" on crew_applications for select using (applicant_id = auth.uid());

-- ---------------------------------------------------------------- listings

create table listings (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  address text not null,
  city_id text references cities,
  status text not null default 'comingSoon' check (status in ('comingSoon', 'active', 'underContract', 'sold')),
  price_cents bigint,
  beds int,
  baths numeric,
  square_feet int,
  features text[] not null default '{}',
  description text,
  mls_number text,
  marketing_tasks jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table open_houses (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Visitors sign in on the agent's phone or by scanning the door QR code.
create table open_house_visitors (
  id uuid primary key default gen_random_uuid(),
  open_house_id uuid not null references open_houses on delete cascade,
  name text not null,
  phone text,
  email text,
  working_with_agent boolean not null default false,
  preapproved boolean not null default false,
  timeline text,
  lead_id uuid references leads on delete set null,
  created_at timestamptz not null default now()
);

alter table leads add column source text not null default 'comment' check (source in ('comment', 'openHouse', 'referral', 'manual'));

alter table listings enable row level security;
alter table open_houses enable row level security;
alter table open_house_visitors enable row level security;
create policy "own listings" on listings for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy "own open houses" on open_houses for all
  using (exists (select 1 from listings l where l.id = open_houses.listing_id and l.profile_id = auth.uid()))
  with check (exists (select 1 from listings l where l.id = open_houses.listing_id and l.profile_id = auth.uid()));
create policy "own visitors" on open_house_visitors for select
  using (exists (select 1 from open_houses o join listings l on l.id = o.listing_id where o.id = open_house_visitors.open_house_id and l.profile_id = auth.uid()));

-- QR sign in from a visitor's own phone (no account): goes through this function,
-- which also creates the lead for the listing agent.
create or replace function open_house_sign_in(
  p_open_house uuid, p_name text, p_phone text, p_email text,
  p_working_with_agent boolean, p_preapproved boolean, p_timeline text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_agent uuid;
  v_address text;
  v_lead uuid;
  v_visitor uuid;
begin
  select l.profile_id, l.address into v_agent, v_address
    from open_houses o join listings l on l.id = o.listing_id
    where o.id = p_open_house and now() between o.starts_at - interval '1 hour' and o.ends_at + interval '2 hours';
  if v_agent is null then raise exception 'open house is not running'; end if;
  insert into leads (profile_id, name, handle, platform, keyword, message, source)
  values (v_agent, p_name, coalesce(nullif(p_phone, ''), p_email), 'facebook', 'OPEN',
          concat_ws('. ', 'Signed in at ' || v_address, case when p_preapproved then 'Pre-approved' end,
                    case when p_working_with_agent then 'Has an agent' end, nullif(p_timeline, '')), 'openHouse')
  returning id into v_lead;
  insert into open_house_visitors (open_house_id, name, phone, email, working_with_agent, preapproved, timeline, lead_id)
  values (p_open_house, p_name, p_phone, p_email, p_working_with_agent, p_preapproved, p_timeline, v_lead)
  returning id into v_visitor;
  return v_visitor;
end;
$$;
grant execute on function open_house_sign_in(uuid, text, text, text, boolean, boolean, text) to anon, authenticated;

-- ---------------------------------------------------------------- activity inbox

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  kind text not null check (kind in ('edit', 'lead', 'booking', 'office', 'rating', 'referral', 'coach', 'system')),
  title text not null,
  detail text not null,
  route text,                    -- app route, for example 'clip:<uuid>' or 'leads'
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_profile_idx on notifications (profile_id, created_at desc);
alter table notifications enable row level security;
create policy "own notifications" on notifications for select using (profile_id = auth.uid());
create policy "mark own read" on notifications for update using (profile_id = auth.uid());
revoke update on notifications from anon, authenticated;
grant update (read_at) on notifications to authenticated;

-- Fill the inbox from the events that already happen in the database.
create or replace function notify_on_clip_ready() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'readyForReview' and old.status is distinct from 'readyForReview' then
    insert into notifications (profile_id, kind, title, detail, route)
    values (new.profile_id, 'edit', 'Your edit is ready', '"' || new.title || '" is ready for you to review and approve.', 'clip:' || new.id);
  end if;
  return new;
end;
$$;
create trigger clips_notify_ready after update of status on clips for each row execute function notify_on_clip_ready();

create or replace function notify_on_lead() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into notifications (profile_id, kind, title, detail, route)
  values (new.profile_id, 'lead',
          case when new.source = 'openHouse' then 'Open house sign in' else 'New lead from ' || coalesce(new.keyword, 'a comment') end,
          coalesce(new.name, 'Someone') || ': ' || coalesce(new.message, ''), 'leads');
  return new;
end;
$$;
create trigger leads_notify after insert on leads for each row execute function notify_on_lead();

create or replace function notify_on_deposit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'depositPaid' and old.status is distinct from 'depositPaid' then
    insert into notifications (profile_id, kind, title, detail, route)
    values (new.profile_id, 'booking', 'Shoot booked', 'Your deposit is in. ' || to_char(new.starts_at, 'Dy Mon DD at HH12:MI AM'), 'bookings');
  end if;
  return new;
end;
$$;
create trigger bookings_notify after update of status on bookings for each row execute function notify_on_deposit();

-- ---------------------------------------------------------------- referrals

alter table profiles add column referral_code text unique, add column referred_by uuid references profiles;

create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references profiles on delete cascade,
  referred_id uuid unique references profiles on delete cascade,
  invited_name text,
  status text not null default 'invited' check (status in ('invited', 'joined', 'rewarded')),
  created_at timestamptz not null default now(),
  rewarded_at timestamptz
);
alter table referrals enable row level security;
create policy "own referrals" on referrals for select using (referrer_id = auth.uid());

-- Called once after sign up with the code someone shared.
create or replace function redeem_referral(p_code text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_referrer uuid;
begin
  select id into v_referrer from profiles where referral_code = upper(trim(p_code));
  if v_referrer is null or v_referrer = auth.uid() then raise exception 'invalid code'; end if;
  update profiles set referred_by = v_referrer where id = auth.uid() and referred_by is null;
  if not found then raise exception 'already referred'; end if;
  insert into referrals (referrer_id, referred_id, status) values (v_referrer, auth.uid(), 'joined');
end;
$$;

-- Both get 2 credits when the new agent's first clip is submitted.
create or replace function reward_referral() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_ref referrals;
begin
  select * into v_ref from referrals where referred_id = new.profile_id and status = 'joined';
  if found then
    update referrals set status = 'rewarded', rewarded_at = now() where id = v_ref.id;
    update profiles set credits = credits + 2 where id in (v_ref.referrer_id, v_ref.referred_id);
    insert into notifications (profile_id, kind, title, detail, route)
    values (v_ref.referrer_id, 'referral', 'You earned 2 credits', 'An agent you invited filmed their first video.', 'referrals');
  end if;
  return new;
end;
$$;
create trigger clips_reward_referral after insert on clips for each row execute function reward_referral();

-- ---------------------------------------------------------------- saved scripts

alter table ideas drop constraint ideas_source_check;
alter table ideas add constraint ideas_source_check check (source in ('template', 'ai', 'community', 'seasonal', 'script'));
