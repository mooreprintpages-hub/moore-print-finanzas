create table public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_type text not null default 'person' check (customer_type in ('person','business')),
  name text not null,
  contact_name text,
  phone text,
  email text,
  tax_id text,
  address text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  contact_name text,
  phone text,
  email text,
  tax_id text,
  address text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  description text,
  product_type text not null default 'product' check (product_type in ('product','service')),
  category text,
  base_price numeric(14,2) check (base_price is null or base_price >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  sku text,
  name text not null,
  attributes jsonb not null default '{}'::jsonb,
  price numeric(14,2) check (price is null or price >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, sku)
);

create table public.materials (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  sku text,
  unit text not null default 'pieza',
  category text,
  minimum_stock numeric(14,4) not null default 0 check (minimum_stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, sku)
);

create index customers_business_id_idx on public.customers(business_id);
create index suppliers_business_id_idx on public.suppliers(business_id);
create index products_business_id_idx on public.products(business_id);
create index product_variants_business_id_idx on public.product_variants(business_id);
create index product_variants_product_id_idx on public.product_variants(product_id);
create index materials_business_id_idx on public.materials(business_id);

alter table public.customers enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.materials enable row level security;

create policy "members_read_customers" on public.customers for select to authenticated using (private.is_business_member(business_id));
create policy "members_insert_customers" on public.customers for insert to authenticated with check (private.has_business_permission(business_id,'customers.edit'));
create policy "members_update_customers" on public.customers for update to authenticated using (private.has_business_permission(business_id,'customers.edit')) with check (private.has_business_permission(business_id,'customers.edit'));
create policy "members_delete_customers" on public.customers for delete to authenticated using (private.has_business_permission(business_id,'customers.edit'));

create policy "members_read_suppliers" on public.suppliers for select to authenticated using (private.is_business_member(business_id));
create policy "admins_insert_suppliers" on public.suppliers for insert to authenticated with check (private.has_business_permission(business_id,'purchases.create'));
create policy "admins_update_suppliers" on public.suppliers for update to authenticated using (private.has_business_permission(business_id,'purchases.create')) with check (private.has_business_permission(business_id,'purchases.create'));
create policy "admins_delete_suppliers" on public.suppliers for delete to authenticated using (private.has_business_permission(business_id,'purchases.approve'));

create policy "members_read_products" on public.products for select to authenticated using (private.is_business_member(business_id));
create policy "catalog_manage_products_insert" on public.products for insert to authenticated with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "catalog_manage_products_update" on public.products for update to authenticated using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "catalog_manage_products_delete" on public.products for delete to authenticated using (private.has_business_permission(business_id,'inventory.adjust'));

create policy "members_read_product_variants" on public.product_variants for select to authenticated using (private.is_business_member(business_id));
create policy "catalog_manage_variants_insert" on public.product_variants for insert to authenticated with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "catalog_manage_variants_update" on public.product_variants for update to authenticated using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "catalog_manage_variants_delete" on public.product_variants for delete to authenticated using (private.has_business_permission(business_id,'inventory.adjust'));

create policy "members_read_materials" on public.materials for select to authenticated using (private.has_business_permission(business_id,'inventory.view'));
create policy "inventory_manage_materials_insert" on public.materials for insert to authenticated with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "inventory_manage_materials_update" on public.materials for update to authenticated using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "inventory_manage_materials_delete" on public.materials for delete to authenticated using (private.has_business_permission(business_id,'inventory.adjust'));

grant select, insert, update, delete on public.customers, public.suppliers, public.products, public.product_variants, public.materials to authenticated;