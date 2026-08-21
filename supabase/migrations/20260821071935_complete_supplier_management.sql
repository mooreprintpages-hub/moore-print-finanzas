create table public.supplier_materials (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete cascade,
  preferred boolean not null default false,
  brand text,
  estimated_lead_days integer,
  current_price numeric(14,2),
  currency text not null default 'MXN',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (supplier_id, material_id)
);

create table public.supplier_price_tiers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_material_id uuid not null references public.supplier_materials(id) on delete cascade,
  min_quantity numeric(14,3) not null,
  max_quantity numeric(14,3),
  unit_price numeric(14,2) not null,
  effective_from date not null default current_date,
  effective_to date,
  created_at timestamptz not null default now(),
  check (min_quantity > 0),
  check (max_quantity is null or max_quantity >= min_quantity),
  check (unit_price >= 0)
);

create table public.supplier_price_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_material_id uuid not null references public.supplier_materials(id) on delete cascade,
  unit_price numeric(14,2) not null,
  currency text not null default 'MXN',
  effective_at timestamptz not null default now(),
  source text,
  notes text,
  created_at timestamptz not null default now(),
  check (unit_price >= 0)
);

create table public.supplier_reviews (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  delivery_rating integer check (delivery_rating between 1 and 5),
  accuracy_rating integer check (accuracy_rating between 1 and 5),
  quality_rating integer check (quality_rating between 1 and 5),
  notes text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz not null default now()
);

create table public.supplier_incidents (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  purchase_id uuid references public.purchases(id) on delete set null,
  incident_type text not null check (incident_type in ('missing','incorrect_product','damaged','extra','other')),
  resolution text check (resolution in ('replacement','return','store_credit','exchange','other')),
  description text,
  resolved_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index supplier_materials_business_idx on public.supplier_materials(business_id);
create index supplier_materials_supplier_idx on public.supplier_materials(supplier_id);
create index supplier_materials_material_idx on public.supplier_materials(material_id);
create index supplier_price_tiers_business_idx on public.supplier_price_tiers(business_id);
create index supplier_price_tiers_supplier_material_idx on public.supplier_price_tiers(supplier_material_id);
create index supplier_price_history_business_idx on public.supplier_price_history(business_id);
create index supplier_price_history_supplier_material_idx on public.supplier_price_history(supplier_material_id, effective_at desc);
create index supplier_reviews_business_idx on public.supplier_reviews(business_id);
create index supplier_reviews_supplier_idx on public.supplier_reviews(supplier_id);
create index supplier_reviews_reviewed_by_idx on public.supplier_reviews(reviewed_by);
create index supplier_incidents_business_idx on public.supplier_incidents(business_id);
create index supplier_incidents_supplier_idx on public.supplier_incidents(supplier_id);
create index supplier_incidents_purchase_idx on public.supplier_incidents(purchase_id);
create index supplier_incidents_created_by_idx on public.supplier_incidents(created_by);

alter table public.supplier_materials enable row level security;
alter table public.supplier_price_tiers enable row level security;
alter table public.supplier_price_history enable row level security;
alter table public.supplier_reviews enable row level security;
alter table public.supplier_incidents enable row level security;

create policy supplier_materials_read on public.supplier_materials for select to authenticated using (private.has_business_permission(business_id,'purchases.view'));
create policy supplier_materials_insert on public.supplier_materials for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_materials_update on public.supplier_materials for update to authenticated using (private.has_business_permission(business_id,'purchases.create')) with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_materials_delete on public.supplier_materials for delete to authenticated using (private.has_business_permission(business_id,'purchases.create'));

create policy supplier_price_tiers_read on public.supplier_price_tiers for select to authenticated using (private.has_business_permission(business_id,'purchases.view'));
create policy supplier_price_tiers_insert on public.supplier_price_tiers for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_price_tiers_update on public.supplier_price_tiers for update to authenticated using (private.has_business_permission(business_id,'purchases.create')) with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_price_tiers_delete on public.supplier_price_tiers for delete to authenticated using (private.has_business_permission(business_id,'purchases.create'));

create policy supplier_price_history_read on public.supplier_price_history for select to authenticated using (private.has_business_permission(business_id,'purchases.view'));
create policy supplier_price_history_insert on public.supplier_price_history for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));

create policy supplier_reviews_read on public.supplier_reviews for select to authenticated using (private.has_business_permission(business_id,'purchases.view'));
create policy supplier_reviews_insert on public.supplier_reviews for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_reviews_update on public.supplier_reviews for update to authenticated using (private.has_business_permission(business_id,'purchases.create')) with check (private.has_business_permission(business_id,'purchases.create'));

create policy supplier_incidents_read on public.supplier_incidents for select to authenticated using (private.has_business_permission(business_id,'purchases.view'));
create policy supplier_incidents_insert on public.supplier_incidents for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));
create policy supplier_incidents_update on public.supplier_incidents for update to authenticated using (private.has_business_permission(business_id,'purchases.create')) with check (private.has_business_permission(business_id,'purchases.create'));

grant select,insert,update,delete on public.supplier_materials, public.supplier_price_tiers to authenticated;
grant select,insert on public.supplier_price_history to authenticated;
grant select,insert,update on public.supplier_reviews, public.supplier_incidents to authenticated;
