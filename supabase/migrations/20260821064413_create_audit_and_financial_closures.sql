create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create table public.financial_periods (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  year integer not null check (year between 2000 and 2200),
  month integer not null check (month between 1 and 12),
  status text not null default 'open' check (status in ('open','closed','reopened')),
  closed_at timestamptz,
  closed_by uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, year, month)
);

create table public.inventory_snapshots (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  financial_period_id uuid not null references public.financial_periods(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  location_id uuid not null references public.locations(id) on delete restrict,
  physical_quantity numeric(14,4) not null,
  reserved_quantity numeric(14,4) not null,
  available_quantity numeric(14,4) not null,
  captured_at timestamptz not null default now()
);

create index audit_log_business_created_idx on public.audit_log(business_id,created_at desc);
create index audit_log_user_idx on public.audit_log(user_id);
create index audit_log_entity_idx on public.audit_log(entity_type,entity_id);
create index financial_periods_business_idx on public.financial_periods(business_id,year,month);
create index financial_periods_closed_by_idx on public.financial_periods(closed_by);
create index inventory_snapshots_period_idx on public.inventory_snapshots(financial_period_id);
create index inventory_snapshots_business_idx on public.inventory_snapshots(business_id);
create index inventory_snapshots_variant_idx on public.inventory_snapshots(material_variant_id);
create index inventory_snapshots_location_idx on public.inventory_snapshots(location_id);

alter table public.audit_log enable row level security;
alter table public.financial_periods enable row level security;
alter table public.inventory_snapshots enable row level security;

create policy audit_log_read on public.audit_log
for select to authenticated
using (private.has_business_permission(business_id,'finance.view'));

create policy audit_log_insert on public.audit_log
for insert to authenticated
with check (private.is_business_member(business_id) and user_id = auth.uid());

create policy financial_periods_read on public.financial_periods
for select to authenticated
using (private.has_business_permission(business_id,'finance.view'));
create policy financial_periods_insert on public.financial_periods
for insert to authenticated
with check (private.has_business_permission(business_id,'finance.manage'));
create policy financial_periods_update on public.financial_periods
for update to authenticated
using (private.has_business_permission(business_id,'finance.manage'))
with check (private.has_business_permission(business_id,'finance.manage'));
create policy financial_periods_delete on public.financial_periods
for delete to authenticated
using (private.has_business_permission(business_id,'finance.manage'));

create policy inventory_snapshots_read on public.inventory_snapshots
for select to authenticated
using (private.has_business_permission(business_id,'finance.view'));

revoke update, delete on public.audit_log from authenticated;
grant select, insert on public.audit_log to authenticated;
grant select, insert, update, delete on public.financial_periods to authenticated;
grant select on public.inventory_snapshots to authenticated;

create or replace function private.handle_financial_period_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();

  if new.status = 'closed' and (tg_op = 'INSERT' or old.status is distinct from 'closed') then
    new.closed_at := now();
    new.closed_by := auth.uid();
  end if;

  return new;
end;
$$;

create trigger financial_periods_status_before
before insert or update on public.financial_periods
for each row execute function private.handle_financial_period_status();

create or replace function private.capture_inventory_on_period_close()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status='closed' and (tg_op='INSERT' or old.status is distinct from 'closed') then
    insert into public.inventory_snapshots(
      business_id,financial_period_id,material_variant_id,location_id,
      physical_quantity,reserved_quantity,available_quantity,captured_at
    )
    select ia.business_id,new.id,ia.material_variant_id,ia.location_id,
           ia.physical_quantity,ia.reserved_quantity,ia.available_quantity,now()
    from public.inventory_availability ia
    where ia.business_id=new.business_id;

    insert into public.audit_log(business_id,user_id,action,entity_type,entity_id,before_data,after_data)
    values (
      new.business_id,auth.uid(),'financial_period.closed','financial_period',new.id,
      case when tg_op='UPDATE' then jsonb_build_object('status',old.status) else null end,
      jsonb_build_object('year',new.year,'month',new.month,'status',new.status,'closed_at',new.closed_at)
    );
  elsif tg_op='UPDATE' and new.status='reopened' and old.status is distinct from 'reopened' then
    insert into public.audit_log(business_id,user_id,action,entity_type,entity_id,before_data,after_data)
    values (new.business_id,auth.uid(),'financial_period.reopened','financial_period',new.id,
            jsonb_build_object('status',old.status),jsonb_build_object('status',new.status));
  end if;
  return new;
end;
$$;

create trigger financial_periods_capture_after
after insert or update on public.financial_periods
for each row execute function private.capture_inventory_on_period_close();