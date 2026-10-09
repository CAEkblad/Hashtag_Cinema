-- Markets: every Florida city, its traits, local idea templates, seasonal
-- moments and market stats. Ideas are written per city so the app works for
-- agents anywhere in the state (and later, any state).

create extension if not exists pg_trgm;

create table regions (
  id text primary key,
  state text not null default 'FL',
  name text not null,
  blurb text
);

insert into regions (id, name, blurb) values
  ('tampaBay', 'Tampa Bay', 'Hillsborough, Pinellas, Pasco and Hernando.'),
  ('suncoast', 'Sarasota and Manatee', 'Gulf beaches, master planned communities and snowbirds.'),
  ('southwest', 'Southwest Florida', 'Lee, Collier, Charlotte and inland counties.'),
  ('southFlorida', 'South Florida', 'Miami-Dade, Broward and Palm Beach.'),
  ('keys', 'Florida Keys', 'Monroe County.'),
  ('treasureCoast', 'Treasure Coast', 'Martin, St. Lucie, Indian River and Okeechobee.'),
  ('spaceCoast', 'Space Coast', 'Brevard County.'),
  ('centralFlorida', 'Central Florida', 'Orange, Seminole, Osceola, Lake and Sumter.'),
  ('heartland', 'Polk and the Heartland', 'Polk, Highlands and Hardee.'),
  ('natureCoast', 'Nature Coast', 'Citrus, Levy, Dixie and Taylor.'),
  ('northCentral', 'North Central Florida', 'Alachua, Marion and surrounding counties.'),
  ('daytonaFlagler', 'Daytona and Flagler', 'Volusia and Flagler.'),
  ('firstCoast', 'Jacksonville and the First Coast', 'Duval, St. Johns, Clay, Nassau and Baker.'),
  ('bigBend', 'Tallahassee and the Big Bend', 'Leon and the Big Bend.'),
  ('panhandle', 'Panhandle and Emerald Coast', 'Escambia to Gulf County.');

create table cities (
  id text primary key,                        -- 'tampa-hillsborough'
  name text not null,
  state text not null default 'FL',
  county text not null,
  region text not null references regions,
  population int,
  lat numeric not null,
  lng numeric not null,
  traits text[] not null default '{}',        -- beach, boating, golf, military, growth...
  highlights text[] not null default '{}',    -- 'Philadelphia Phillies spring training'
  neighborhoods text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create index cities_region_idx on cities (region);
create index cities_traits_idx on cities using gin (traits);
create index cities_name_trgm_idx on cities using gin (name gin_trgm_ops);

alter table profiles
  add column city_id text references cities,
  add column service_area_ids text[] not null default '{}',
  add column goals text[] not null default '{}',
  add column weekly_goal int not null default 3;

alter table ideas
  add column city_id text references cities,
  add column source text not null default 'template' check (source in ('template', 'ai', 'community', 'seasonal'));

create index ideas_profile_created_idx on ideas (profile_id, created_at desc);

-- Templates the local engine and the AI both use. {city}, {county}, {hood},
-- {highlight} and {KEY} are filled in per city.
create table idea_templates (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  category text not null,
  title text not null,
  hook text not null,
  shots text[] not null default '{}',
  script text not null,
  target_seconds int not null default 35,
  why_it_works text,
  keyword text,
  any_of_traits text[] not null default '{}',
  months int[] not null default '{}',
  niches text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Local events and seasonal topics. A row can target a city, a region, a trait or all of Florida.
create table seasonal_moments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  detail text not null,
  hook text not null,
  category text not null default 'neighborhood',
  months int[] not null,
  city_id text references cities,
  region text references regions,
  any_of_traits text[] not null default '{}',
  active boolean not null default true
);

-- Filled monthly by a data job (MLS feed or a market data API). Powers the
-- "{city} market in 30 seconds" script with real numbers.
create table market_stats (
  city_id text not null references cities on delete cascade,
  period date not null,                       -- first day of the month
  median_price int,
  median_days_on_market int,
  new_listings int,
  active_listings int,
  closed_sales int,
  source text,
  primary key (city_id, period)
);

-- What performs per city, learned from posts. The idea engine leans on it.
create view city_idea_performance with (security_invoker = true) as
select
  p.city_id,
  i.category,
  count(*) as posts,
  avg(po.views)::int as avg_views,
  avg(po.avg_watch_seconds) as avg_watch_seconds,
  sum(case when l.id is not null then 1 else 0 end) as leads
from posts po
join clips c on c.id = po.clip_id
join ideas i on i.id = c.idea_id
join profiles p on p.id = po.profile_id
left join leads l on l.post_id = po.id
where p.city_id is not null
group by p.city_id, i.category;

alter table regions enable row level security;
alter table cities enable row level security;
alter table idea_templates enable row level security;
alter table seasonal_moments enable row level security;
alter table market_stats enable row level security;

create policy "regions readable" on regions for select using (true);
create policy "cities readable" on cities for select using (true);
create policy "templates readable" on idea_templates for select using (auth.role() = 'authenticated');
create policy "moments readable" on seasonal_moments for select using (auth.role() = 'authenticated');
create policy "stats readable" on market_stats for select using (auth.role() = 'authenticated');
