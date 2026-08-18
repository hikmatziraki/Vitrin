-- VOIDRUN content expansion: launch content, balance data, decision events, explorers, cosmetics, recipes.
create table if not exists public.decision_event_bank(
  id serial primary key,
  zone_id int not null references public.zones(id) on delete cascade,
  clue text not null,
  choices jsonb not null,
  correct_choice int not null check(correct_choice >= 0),
  explanation text not null
);
create table if not exists public.explorer_catalog(
  id serial primary key,
  name text unique not null,
  rarity text not null check(rarity in('Common','Rare','Epic','Legendary')),
  stats jsonb not null,
  base_level int not null default 1,
  description text not null
);
create table if not exists public.cosmetics(
  id serial primary key,
  name text unique not null,
  slot text not null,
  rarity text not null,
  price_shards numeric(20,4),
  metadata jsonb not null default '{}'
);
create table if not exists public.guild_invites(
  id uuid primary key default gen_random_uuid(),
  inviter_id uuid not null references auth.users(id) on delete cascade,
  invitee_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  qualified_at timestamptz
);
create table if not exists public.economy_daily(
  day date primary key,
  credit_minted numeric not null default 0,
  credit_sink numeric not null default 0,
  shard_minted numeric not null default 0,
  shard_converted numeric not null default 0,
  shard_burned numeric not null default 0,
  market_volume numeric not null default 0,
  active_users int not null default 0,
  faucet_sink_ratio numeric,
  created_at timestamptz not null default now()
);

alter table public.ledger add column if not exists prev_hash text;
alter table public.ledger add column if not exists entry_hash text;
alter table public.ledger add column if not exists nonce bigint;
alter table public.market_trades add column if not exists reason text;
alter table public.items add column if not exists bound boolean not null default false;
alter table public.items add column if not exists created_at timestamptz not null default now();
alter table public.explorers add column if not exists xp bigint not null default 0;
alter table public.explorers add column if not exists ascension_level int not null default 0;

create index if not exists mission_events_zone on public.mission_events(mission_id);
create index if not exists ledger_user_created on public.ledger(user_id,created_at desc);
create index if not exists audit_user_created on public.audit_logs(user_id,created_at desc);
create index if not exists economy_daily_day on public.economy_daily(day desc);

-- Exact launch balance, kept in DB so no redeploy is required for balancing.
insert into public.balance_config(key,value) values
('zones','{"T1":{"hazard":0.10,"energy":10,"duration":180,"credit":10,"shard":0.2,"rep":0},"T2":{"hazard":0.25,"energy":18,"duration":360,"credit":22,"shard":0.6,"rep":0},"T3":{"hazard":0.40,"energy":28,"duration":720,"credit":45,"shard":1.5,"rep":0},"T4":{"hazard":0.60,"energy":40,"duration":1500,"credit":90,"shard":3.5,"rep":3},"T5":{"hazard":0.80,"energy":55,"duration":2700,"credit":170,"shard":8,"rep":5},"Raid":{"hazard":0.90,"energy":80,"duration":3600,"credit":400,"shard":20,"players":[2,4]}}'::jsonb),
('modules_formula','{"cost_base":{"energy":100,"workshop":120,"storage":110,"lab":140},"time_base_minutes":{"energy":2,"workshop":2,"storage":2,"lab":2},"cost_multiplier":1.35,"time_multiplier":1.25}'::jsonb),
('energy','{"base_cap":100,"cap_per_level":20,"regen_per_hour_base":5,"regen_per_level":1,"emergency_cell":40}'::jsonb),
('mission_formula','{"base":0.75,"stat_match":0.15,"gear_score":0.10,"hazard_weight":0.90,"min":0.15,"max":0.95,"critical_multiplier":0.15,"critical_yield":1.30,"partial_yield":0.50,"correct_hazard_delta":-0.15,"correct_yield_delta":0.15}'::jsonb),
('market_tax','{"total":0.05,"burn":0.02,"treasury":0.02,"rewards":0.01,"listing_credit":2}'::jsonb),
('prestige','{"required_module_level":15,"yield_per_mark":0.05,"max_marks":10,"reset":["modules","credit"],"keep":["explorers","items","nfts","cosmetics","shards"]}'::jsonb),
('season','{"duration_days":56,"premium_cost_shards":150,"max_leaderboard_reward_rank":100}'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

-- 60 deterministic recipes; later rows are higher-tier recipes and remain server-authoritative.
insert into public.recipes(id,name,materials,credit_cost,time_minutes)
select i, case when i=1 then 'Reinforced Suit' else 'Field Pattern '||lpad(i::text,2,'0') end,
       jsonb_build_object('Metal',2+(i%5),'Polymer',1+(i%3),'Crystal',i%4),
       80+(i*20), 30+(i*10)
from generate_series(1,60) i
on conflict(id) do update set name=excluded.name,materials=excluded.materials,credit_cost=excluded.credit_cost,time_minutes=excluded.time_minutes;

-- 40 learnable decision events, 8 per zone for T1-T5.
insert into public.decision_event_bank(zone_id,clue,choices,correct_choice,explanation)
select z,
       'Signal pattern '||n||': observe the stable frequency before committing.',
       jsonb_build_array('Follow the stable frequency','Follow the loudest spike','Ignore the scanner'),
       0,
       'Stable frequency is the safer route in this event family.'
from generate_series(1,5) z cross join generate_series(1,8) n
on conflict do nothing;

insert into public.explorer_catalog(name,rarity,stats,description) values
('Mara Voss','Common','{"Speed":6,"Luck":4,"Strength":5,"Focus":5}','Practical scout trained for short runs.'),
('Ilan Rook','Common','{"Speed":5,"Luck":5,"Strength":6,"Focus":4}','Reliable field technician.'),
('Sera Kade','Common','{"Speed":4,"Luck":6,"Strength":5,"Focus":5}','Pattern reader with strong intuition.'),
('Nox Vale','Rare','{"Speed":7,"Luck":6,"Strength":5,"Focus":6}','Fast reconnaissance specialist.'),
('Tarin Quell','Rare','{"Speed":5,"Luck":7,"Strength":7,"Focus":5}','High-risk salvage expert.'),
('Aya Renn','Rare','{"Speed":6,"Luck":5,"Strength":6,"Focus":8}','Focused systems analyst.'),
('Kest Arin','Epic','{"Speed":8,"Luck":7,"Strength":7,"Focus":7}','Elite Void Runner.'),
('Veyra Sol','Epic','{"Speed":7,"Luck":9,"Strength":6,"Focus":8}','Exceptional anomaly reader.'),
('Orin Hex','Epic','{"Speed":9,"Luck":6,"Strength":8,"Focus":7}','Aggressive extraction specialist.'),
('Nyx Prime','Legendary','{"Speed":9,"Luck":9,"Strength":8,"Focus":9}','Station-class explorer.'),
('Cael Zero','Legendary','{"Speed":8,"Luck":10,"Strength":9,"Focus":8}','Master of dangerous routes.'),
('Iris Null','Legendary','{"Speed":10,"Luck":8,"Strength":8,"Focus":10}','Legendary decision strategist.')
on conflict(name) do update set rarity=excluded.rarity,stats=excluded.stats,description=excluded.description;

insert into public.cosmetics(name,slot,rarity,price_shards,metadata)
select 'Void Frame '||lpad(i::text,2,'0'), 'frame', case when i<=15 then 'Rare' when i<=25 then 'Epic' else 'Legendary' end, 30+(i*10), '{}'::jsonb
from generate_series(1,30) i
on conflict(name) do nothing;

-- Public read policies for content. Mutations remain server/RPC controlled.
alter table public.zones enable row level security;
alter table public.recipes enable row level security;
alter table public.balance_config enable row level security;
alter table public.decision_event_bank enable row level security;
alter table public.explorer_catalog enable row level security;
alter table public.cosmetics enable row level security;
alter table public.seasons enable row level security;
alter table public.leaderboard_snapshots enable row level security;

drop policy if exists zones_public on public.zones;
create policy zones_public on public.zones for select using(true);
drop policy if exists recipes_public on public.recipes;
create policy recipes_public on public.recipes for select using(true);
drop policy if exists balance_public on public.balance_config;
create policy balance_public on public.balance_config for select using(true);
drop policy if exists decision_public on public.decision_event_bank;
create policy decision_public on public.decision_event_bank for select using(true);
drop policy if exists explorers_catalog_public on public.explorer_catalog;
create policy explorers_catalog_public on public.explorer_catalog for select using(true);
drop policy if exists cosmetics_public on public.cosmetics;
create policy cosmetics_public on public.cosmetics for select using(true);

-- Server-side formulas and atomic market operation.
create or replace function public.module_upgrade_cost(p_type text,p_level int) returns bigint language sql immutable as $$
 select round((case p_type when 'energy' then 100 when 'workshop' then 120 when 'storage' then 110 when 'lab' then 140 else 0 end)*power(1.35,greatest(p_level,1)-1))::bigint $$;
create or replace function public.module_upgrade_minutes(p_level int) returns int language sql immutable as $$ select ceil(2*power(1.25,greatest(p_level,1)-1))::int $$;
create or replace function public.energy_cap(p_level int) returns int language sql immutable as $$ select 100+20*(greatest(p_level,1)-1) $$;
create or replace function public.energy_regen_hour(p_level int) returns int language sql immutable as $$ select 5+(greatest(p_level,1)-1) $$;
create or replace function public.mission_probability(p_stat numeric,p_gear numeric,p_hazard numeric,p_fatigue numeric) returns numeric language sql immutable as $$
 select greatest(.15,least(.95,.75+.15*greatest(0,least(1,p_stat))+.10*greatest(0,least(1,p_gear))-.9*p_hazard-p_fatigue)) $$;

create or replace function public.buy_market_item(p_buyer_id uuid,p_listing_id uuid) returns jsonb
language plpgsql security definer set search_path=public as $$
declare l record; buyer record; seller record; burn numeric; treasury numeric; rewards numeric; flagged boolean;
begin
 if auth.uid() is null or auth.uid()<>p_buyer_id then raise exception 'UNAUTHORIZED'; end if;
 select * into l from market_listings where id=p_listing_id and status='active' for update;
 if not found then raise exception 'LISTING_NOT_AVAILABLE'; end if;
 if l.seller_id=p_buyer_id then raise exception 'SELF_TRADE'; end if;
 select * into buyer from currencies where user_id=p_buyer_id for update;
 select * into seller from currencies where user_id=l.seller_id for update;
 if buyer.credit<l.price then raise exception 'INSUFFICIENT_CREDIT'; end if;
 flagged := exists(select 1 from market_trades t where t.item_id=l.item_id and ((t.buyer_id=p_buyer_id and t.seller_id=l.seller_id) or (t.buyer_id=l.seller_id and t.seller_id=p_buyer_id)) and t.created_at>now()-interval '24 hours');
 burn:=l.price*.02; treasury:=l.price*.02; rewards:=l.price*.01;
 update currencies set credit=credit-l.price where user_id=p_buyer_id;
 update currencies set credit=credit+(l.price-burn-treasury-rewards) where user_id=l.seller_id;
 update market_listings set status='sold' where id=l.id;
 update items set user_id=p_buyer_id where id=l.item_id;
 insert into market_trades(listing_id,item_id,buyer_id,seller_id,price,tax_burn,tax_treasury,tax_rewards,flagged,reason) values(l.id,l.item_id,p_buyer_id,l.seller_id,l.price,burn,treasury,rewards,flagged,case when flagged then 'WASH_TRADE_FLAG' else 'NORMAL' end);
 insert into audit_logs(user_id,action,details) values(p_buyer_id,'market.buy',jsonb_build_object('listing',l.id,'price',l.price,'flagged',flagged));
 return jsonb_build_object('ok',true,'price',l.price,'tax',l.price*.05,'flagged',flagged);
end $$;

create or replace function public.economy_dashboard() returns jsonb
language plpgsql security definer set search_path=public as $$
declare r record; credit_in numeric; credit_out numeric; shard_in numeric; shard_out numeric; volume numeric;
begin
 select coalesce(sum(case when amount_change>0 then amount_change else 0 end),0),coalesce(sum(case when amount_change<0 then -amount_change else 0 end),0) into credit_in,credit_out from inventory_ledger where created_at>now()-interval '7 days';
 select coalesce(sum(case when shard_delta>0 then shard_delta else 0 end),0),coalesce(sum(case when shard_delta<0 then -shard_delta else 0 end),0) into shard_in,shard_out from ledger where created_at>now()-interval '7 days';
 select coalesce(sum(price),0) into volume from market_trades where created_at>now()-interval '7 days';
 return jsonb_build_object('credit_faucets',credit_in,'credit_sinks',credit_out,'shard_faucets',shard_in,'shard_conversions',shard_out,'market_volume',volume,'faucet_sink_ratio',case when credit_out>0 then round(credit_in/credit_out,4) else null end,'window_days',7);
end $$;

-- Ledger is append-only to authenticated clients; only server functions should write it.
drop policy if exists ledger_insert_none on public.ledger;
create policy ledger_select_self on public.ledger for select using(auth.uid()=user_id);

comment on table public.ledger is 'Append-only off-chain Shard ledger. Phase 4 can snapshot this table into a Merkle root.';
comment on table public.balance_config is 'Single source of truth for game balance; server reads this table before authoritative calculations.';
