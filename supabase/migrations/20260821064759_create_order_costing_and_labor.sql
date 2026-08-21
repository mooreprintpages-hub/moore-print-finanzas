insert into public.permissions(code,description) values
('costs.manage','Administrar costos y mano de obra')
on conflict (code) do nothing;
insert into public.role_permissions(role_id,permission_id,allowed)
select r.id,p.id,true from public.roles r cross join public.permissions p
where r.name='Propietario' and p.code='costs.manage'
on conflict(role_id,permission_id) do update set allowed=excluded.allowed;

create table public.cost_templates (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, product_id uuid references public.products(id) on delete set null,
 product_variant_id uuid references public.product_variants(id) on delete set null,
 active boolean not null default true, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.cost_template_items (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 template_id uuid not null references public.cost_templates(id) on delete cascade,
 concept_type text not null check(concept_type in ('material','labor','transport','service','other')),
 description text not null, material_id uuid references public.materials(id) on delete set null,
 estimated_quantity numeric(14,3) not null default 1, estimated_unit_cost numeric(14,4) not null default 0,
 sort_order integer not null default 1, notes text,
 created_at timestamptz not null default now()
);
create table public.order_cost_items (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 order_id uuid not null references public.orders(id) on delete cascade,
 order_item_id uuid references public.order_items(id) on delete set null,
 concept_type text not null check(concept_type in ('material','labor','transport','service','other')),
 description text not null, source_type text, source_id uuid,
 estimated_quantity numeric(14,3) not null default 0, estimated_unit_cost numeric(14,4) not null default 0,
 estimated_total numeric(14,2) generated always as (round(estimated_quantity*estimated_unit_cost,2)) stored,
 actual_quantity numeric(14,3) not null default 0, actual_unit_cost numeric(14,4) not null default 0,
 actual_total numeric(14,2) generated always as (round(actual_quantity*actual_unit_cost,2)) stored,
 notes text, created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.activity_types (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, calculation_method text not null check(calculation_method in ('batch','per_piece')),
 active boolean not null default true, created_at timestamptz not null default now(), unique(business_id,name)
);
create table public.activity_rates (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 activity_type_id uuid not null references public.activity_types(id) on delete cascade,
 hourly_rate numeric(14,4) not null default 0, effective_from date not null default current_date,
 effective_to date, active boolean not null default true, created_at timestamptz not null default now(),
 check(effective_to is null or effective_to>=effective_from)
);
create table public.order_time_records (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 order_id uuid not null references public.orders(id) on delete cascade,
 order_item_id uuid references public.order_items(id) on delete set null,
 activity_type_id uuid not null references public.activity_types(id) on delete restrict,
 user_id uuid references auth.users(id) on delete set null,
 started_at timestamptz not null, ended_at timestamptz,
 minutes_worked integer generated always as (case when ended_at is null then null else greatest(0,floor(extract(epoch from (ended_at-started_at))/60)::integer) end) stored,
 quantity_processed numeric(14,3), notes text, created_at timestamptz not null default now(),
 check(ended_at is null or ended_at>=started_at)
);

create index cost_templates_business_idx on public.cost_templates(business_id);
create index cost_templates_product_idx on public.cost_templates(product_id);
create index cost_templates_variant_idx on public.cost_templates(product_variant_id);
create index cost_template_items_template_idx on public.cost_template_items(template_id);
create index cost_template_items_material_idx on public.cost_template_items(material_id);
create index order_cost_items_business_order_idx on public.order_cost_items(business_id,order_id);
create index order_cost_items_order_item_idx on public.order_cost_items(order_item_id);
create index order_cost_items_created_by_idx on public.order_cost_items(created_by);
create index activity_types_business_idx on public.activity_types(business_id);
create index activity_rates_activity_idx on public.activity_rates(activity_type_id,effective_from);
create index order_time_records_business_order_idx on public.order_time_records(business_id,order_id);
create index order_time_records_order_item_idx on public.order_time_records(order_item_id);
create index order_time_records_activity_idx on public.order_time_records(activity_type_id);
create index order_time_records_user_idx on public.order_time_records(user_id);

alter table public.cost_templates enable row level security;
alter table public.cost_template_items enable row level security;
alter table public.order_cost_items enable row level security;
alter table public.activity_types enable row level security;
alter table public.activity_rates enable row level security;
alter table public.order_time_records enable row level security;

do $$ declare t text; begin
 foreach t in array array['cost_templates','cost_template_items','order_cost_items','activity_types','activity_rates','order_time_records'] loop
  execute format('create policy %I on public.%I for select to authenticated using (private.has_business_permission(business_id,''costs.view'') or private.has_business_permission(business_id,''costs.manage''))',t||'_read',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id,''costs.manage''))',t||'_insert',t);
  execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id,''costs.manage'')) with check (private.has_business_permission(business_id,''costs.manage''))',t||'_update',t);
  execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id,''costs.manage''))',t||'_delete',t);
 end loop;
end $$;

grant select,insert,update,delete on public.cost_templates,public.cost_template_items,public.order_cost_items,public.activity_types,public.activity_rates,public.order_time_records to authenticated;

create or replace view public.order_profitability
with (security_invoker=true) as
select o.business_id,o.id as order_id,o.total as revenue,
       coalesce(sum(c.estimated_total),0)::numeric(14,2) as estimated_cost,
       coalesce(sum(c.actual_total),0)::numeric(14,2) as actual_cost,
       (o.total-coalesce(sum(c.actual_total),0))::numeric(14,2) as actual_margin,
       case when o.total=0 then null else round(((o.total-coalesce(sum(c.actual_total),0))/o.total)*100,2) end as actual_margin_pct
from public.orders o
left join public.order_cost_items c on c.order_id=o.id
group by o.business_id,o.id,o.total;
grant select on public.order_profitability to authenticated;

insert into public.activity_types(business_id,name,calculation_method)
select b.id,v.name,v.method from public.businesses b cross join (values
('Diseño','batch'),('Producción','per_piece'),('Preparación','batch'),('Entrega','batch'),('Administración','batch')
) as v(name,method)
where b.name='Moore Print'
on conflict(business_id,name) do nothing;
