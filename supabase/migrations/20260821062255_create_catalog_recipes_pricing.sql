create table public.product_recipes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete cascade,
  name text not null default 'Receta principal',
  version integer not null default 1 check (version > 0),
  yield_quantity numeric(14,4) not null default 1 check (yield_quantity > 0),
  yield_unit text not null default 'pieza',
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint product_recipes_target_check check ((product_id is not null and variant_id is null) or (product_id is null and variant_id is not null))
);

create table public.product_recipe_items (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.product_recipes(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete restrict,
  quantity numeric(14,4) not null check (quantity > 0),
  unit text not null,
  waste_percent numeric(7,4) not null default 0 check (waste_percent between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  unique (recipe_id, material_id)
);

create table public.product_prices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete cascade,
  price_type text not null default 'retail' check (price_type in ('retail','wholesale','special')),
  min_quantity numeric(14,4) not null default 1 check (min_quantity > 0),
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null default 'MXN',
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint product_prices_target_check check ((product_id is not null and variant_id is null) or (product_id is null and variant_id is not null)),
  constraint product_prices_dates_check check (valid_to is null or valid_to > valid_from)
);

create table public.material_costs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  unit_cost numeric(14,4) not null check (unit_cost >= 0),
  currency text not null default 'MXN',
  effective_at timestamptz not null default now(),
  source text not null default 'manual' check (source in ('manual','purchase','adjustment')),
  notes text,
  created_at timestamptz not null default now()
);

create index product_recipes_business_id_idx on public.product_recipes(business_id);
create index product_recipes_product_id_idx on public.product_recipes(product_id) where product_id is not null;
create index product_recipes_variant_id_idx on public.product_recipes(variant_id) where variant_id is not null;
create unique index product_recipes_active_product_uidx on public.product_recipes(product_id) where product_id is not null and active = true;
create unique index product_recipes_active_variant_uidx on public.product_recipes(variant_id) where variant_id is not null and active = true;
create index product_recipe_items_material_id_idx on public.product_recipe_items(material_id);
create index product_prices_business_id_idx on public.product_prices(business_id);
create index product_prices_product_id_idx on public.product_prices(product_id) where product_id is not null;
create index product_prices_variant_id_idx on public.product_prices(variant_id) where variant_id is not null;
create index product_prices_lookup_idx on public.product_prices(business_id, price_type, active, valid_from desc);
create index material_costs_business_id_idx on public.material_costs(business_id);
create index material_costs_material_effective_idx on public.material_costs(material_id, effective_at desc);
create index material_costs_supplier_id_idx on public.material_costs(supplier_id) where supplier_id is not null;

alter table public.product_recipes enable row level security;
alter table public.product_recipe_items enable row level security;
alter table public.product_prices enable row level security;
alter table public.material_costs enable row level security;

create policy product_recipes_read on public.product_recipes for select to authenticated using ((select private.is_business_member(business_id)) and ((select private.has_business_permission(business_id,'costs.view')) or (select private.has_business_permission(business_id,'inventory.view'))));
create policy product_recipes_write on public.product_recipes for all to authenticated using ((select private.has_business_permission(business_id,'inventory.adjust'))) with check ((select private.has_business_permission(business_id,'inventory.adjust')));
create policy product_recipe_items_read on public.product_recipe_items for select to authenticated using (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.is_business_member(r.business_id)) and ((select private.has_business_permission(r.business_id,'costs.view')) or (select private.has_business_permission(r.business_id,'inventory.view')))));
create policy product_recipe_items_write on public.product_recipe_items for all to authenticated using (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust')))) with check (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust'))));
create policy product_prices_read on public.product_prices for select to authenticated using ((select private.is_business_member(business_id)) and ((select private.has_business_permission(business_id,'orders.view')) or (select private.has_business_permission(business_id,'quotes.view')) or (select private.has_business_permission(business_id,'margins.view'))));
create policy product_prices_write on public.product_prices for all to authenticated using ((select private.has_business_permission(business_id,'margins.view'))) with check ((select private.has_business_permission(business_id,'margins.view')));
create policy material_costs_read on public.material_costs for select to authenticated using ((select private.is_business_member(business_id)) and ((select private.has_business_permission(business_id,'costs.view')) or (select private.has_business_permission(business_id,'purchases.view'))));
create policy material_costs_write on public.material_costs for all to authenticated using ((select private.has_business_permission(business_id,'purchases.create'))) with check ((select private.has_business_permission(business_id,'purchases.create')));

grant select, insert, update, delete on public.product_recipes, public.product_recipe_items, public.product_prices, public.material_costs to authenticated;
