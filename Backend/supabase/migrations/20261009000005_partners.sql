-- Partner programs (Keller Williams first): email domain detection, market
-- centers with join codes, approvals, signup discount, the 10% revenue share
-- to market centers, and the office content pool leaders remix.

create table partners (
  id text primary key,                         -- 'kw'
  name text not null,
  short_name text not null,
  email_domains text[] not null,
  signup_discount_percent int not null default 0 check (signup_discount_percent between 0 and 100),
  revenue_share_percent int not null default 0 check (revenue_share_percent between 0 and 100),
  office_word text not null default 'office',
  active boolean not null default true
);

insert into partners (id, name, short_name, email_domains, signup_discount_percent, revenue_share_percent, office_word)
values ('kw', 'Keller Williams', 'KW', array['kw.com'], 10, 10, 'market center');

create table market_centers (
  id uuid primary key default gen_random_uuid(),
  partner_id text not null references partners,
  name text not null,
  city_id text references cities,
  group_name text,                             -- 'KW Impact'
  join_code text unique not null default upper(substr(md5(random()::text), 1, 6)),
  payout_email text,
  stripe_account_id text,                      -- Stripe Connect for revenue share payouts
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table profiles
  add column partner_id text references partners,
  add column market_center_id uuid references market_centers,
  add column membership_status text not null default 'none' check (membership_status in ('none', 'pending', 'approved')),
  add column team_name text,
  add column also_sells boolean not null default true,
  add column shares_with_office boolean not null default true;

-- Match the partner from the sign in email on every new account.
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_partner text;
begin
  select id into v_partner from partners
    where active and split_part(lower(new.email), '@', 2) = any (email_domains)
    limit 1;
  insert into profiles (id, name, email, partner_id)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)), new.email, v_partner)
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Join with the MCA's code: connects and verifies right away.
create or replace function join_market_center(p_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_center market_centers;
begin
  select * into v_center from market_centers where join_code = upper(trim(p_code)) and active;
  if not found then raise exception 'join code not found'; end if;
  update profiles set market_center_id = v_center.id, membership_status = 'approved',
    partner_id = coalesce(partner_id, v_center.partner_id)
  where id = auth.uid();
  return v_center.id;
end;
$$;

-- Without a code: request, and a leader of that market center approves.
create or replace function request_market_center(p_center uuid) returns void
language sql security definer set search_path = public as $$
  update profiles set market_center_id = p_center, membership_status = 'pending' where id = auth.uid();
$$;

create or replace function i_lead_market_center(p_center uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and market_center_id = p_center and membership_status = 'approved'
      and role in ('teamLead', 'marketCenter', 'brokerageAdmin', 'staff')
  )
$$;

create or replace function review_membership(p_agent uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_center uuid;
begin
  select market_center_id into v_center from profiles where id = p_agent and membership_status = 'pending';
  if v_center is null or not i_lead_market_center(v_center) then raise exception 'not allowed'; end if;
  update profiles
    set membership_status = case when p_approve then 'approved' else 'none' end,
        market_center_id = case when p_approve then market_center_id else null end
  where id = p_agent;
end;
$$;

alter table partners enable row level security;
alter table market_centers enable row level security;
create policy "partners readable" on partners for select using (true);
-- Join codes stay private: agents can read names and cities only. Leaders get their code from my_join_code().
create policy "market centers readable" on market_centers for select using (auth.role() = 'authenticated');
revoke select on market_centers from anon, authenticated;
grant select (id, partner_id, name, city_id, group_name, active, created_at) on market_centers to authenticated;

create or replace function my_join_code() returns text
language sql stable security definer set search_path = public as $$
  select m.join_code from market_centers m
  join profiles p on p.market_center_id = m.id
  where p.id = auth.uid() and i_lead_market_center(m.id)
$$;

create policy "leaders read market center agents" on profiles for select
  using (market_center_id is not null and i_lead_market_center(market_center_id));

-- ---------------------------------------------------------------- revenue share

-- 10% (per partner) of every paid purchase by a verified agent goes to their market center.
create table revenue_share_ledger (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid unique not null references purchases on delete cascade,
  market_center_id uuid not null references market_centers,
  agent_id uuid not null references profiles,
  gross_cents int not null,
  share_percent int not null,
  share_cents int not null,
  period date not null,                        -- first day of the month
  payout_status text not null default 'accrued' check (payout_status in ('accrued', 'paid', 'void')),
  stripe_transfer_id text,
  created_at timestamptz not null default now()
);

create or replace function accrue_revenue_share() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_profile profiles;
  v_percent int;
begin
  if new.status <> 'paid' or (tg_op = 'UPDATE' and old.status = 'paid') then return new; end if;
  select * into v_profile from profiles where id = new.profile_id;
  if v_profile.market_center_id is null or v_profile.membership_status <> 'approved' then return new; end if;
  select p.revenue_share_percent into v_percent
    from market_centers m join partners p on p.id = m.partner_id where m.id = v_profile.market_center_id;
  if coalesce(v_percent, 0) = 0 then return new; end if;
  insert into revenue_share_ledger (purchase_id, market_center_id, agent_id, gross_cents, share_percent, share_cents, period)
  values (new.id, v_profile.market_center_id, new.profile_id, new.amount_cents, v_percent,
          round(new.amount_cents * v_percent / 100.0), date_trunc('month', now())::date)
  on conflict (purchase_id) do nothing;
  return new;
end;
$$;

create trigger purchases_revenue_share after insert or update of status on purchases
  for each row execute function accrue_revenue_share();

create view market_center_revenue with (security_invoker = true) as
select market_center_id, period,
       count(distinct agent_id) as paying_agents,
       sum(gross_cents) as gross_cents,
       sum(share_cents) as share_cents,
       sum(share_cents) filter (where payout_status = 'paid') as paid_cents
from revenue_share_ledger
group by market_center_id, period;

alter table revenue_share_ledger enable row level security;
create policy "leaders see their office share" on revenue_share_ledger for select
  using (i_lead_market_center(market_center_id));

-- Partner discount used by create-checkout.
create or replace function my_discount_percent() returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select p.signup_discount_percent from profiles pr join partners p on p.id = pr.partner_id where pr.id = auth.uid() and p.active), 0)
$$;

-- ---------------------------------------------------------------- office content pool

create table office_assets (
  id uuid primary key default gen_random_uuid(),
  market_center_id uuid not null references market_centers on delete cascade,
  agent_id uuid not null references profiles on delete cascade,
  kind text not null check (kind in ('video', 'photos', 'poster')),
  title text not null,
  listing_address text,
  status text,                                 -- Just listed, Coming soon, Just sold...
  clip_id uuid references clips on delete set null,
  storage_path text,                           -- deliverables/<agent>/<file>
  remix_count int not null default 0,
  created_at timestamptz not null default now()
);
create index office_assets_center_idx on office_assets (market_center_id, created_at desc);

create table posters (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  kind text not null check (kind in ('justListed', 'comingSoon', 'openHouse', 'underContract', 'priceImproved', 'justSold')),
  address text,
  price_cents bigint,
  beds int,
  baths numeric,
  caption text,
  storage_path text,
  created_at timestamptz not null default now()
);

alter table office_assets enable row level security;
alter table posters enable row level security;
create policy "own posters" on posters for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy "agents add to their office pool" on office_assets for insert with check (
  agent_id = auth.uid() and exists (
    select 1 from profiles where id = auth.uid() and market_center_id = office_assets.market_center_id
      and membership_status = 'approved' and shares_with_office
  )
);
create policy "office members see the pool" on office_assets for select using (
  exists (select 1 from profiles where id = auth.uid() and market_center_id = office_assets.market_center_id and membership_status = 'approved')
);
create policy "agents remove their own" on office_assets for delete using (agent_id = auth.uid());

-- Approved listing clips flow into the pool automatically when sharing is on.
create or replace function share_clip_with_office() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_profile profiles;
begin
  if new.status <> 'approved' or old.status = 'approved' then return new; end if;
  if new.listing is null and new.source <> 'proShoot' then return new; end if;
  select * into v_profile from profiles where id = new.profile_id;
  if v_profile.market_center_id is null or v_profile.membership_status <> 'approved' or not v_profile.shares_with_office then
    return new;
  end if;
  insert into office_assets (market_center_id, agent_id, kind, title, listing_address, status, clip_id)
  values (v_profile.market_center_id, new.profile_id, 'video', new.title, new.listing,
          case when new.listing is not null then 'Just listed' end, new.id);
  return new;
end;
$$;

create trigger clips_share_with_office after update of status on clips
  for each row execute function share_clip_with_office();
