alter table public.materials add column if not exists base_unit text;
alter table public.materials add column if not exists quality_level text;
alter table public.materials add column if not exists track_inventory boolean not null default true;
update public.materials set base_unit = unit where base_unit is null;

create table public.material_variants (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete cascade,
  name text not null,
  sku text,
  attributes jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, sku)
);

create table public.inventory_lots (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  supplier_id uuid references public.suppliers(id) on delete set null,
  purchase_item_id uuid,
  lot_number text,
  quantity_initial numeric(14,4) not null check (quantity_initial >= 0),
  quantity_remaining numeric(14,4) not null check (quantity_remaining >= 0),
  unit_cost numeric(14,4) not null default 0 check (unit_cost >= 0),
  received_at timestamptz not null default now(),
  expiration_date date,
  review_date date,
  created_at timestamptz not null default now(),
  check (quantity_remaining <= quantity_initial)
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  lot_id uuid references public.inventory_lots(id) on delete restrict,
  location_id uuid references public.locations(id) on delete restrict,
  movement_type text not null check (movement_type in ('purchase','reservation','release','consumption','transfer','adjustment','waste','return','supplier_return','sample','damage')),
  quantity numeric(14,4) not null check (quantity <> 0),
  unit_cost numeric(14,4) check (unit_cost is null or unit_cost >= 0),
  reference_type text,
  reference_id uuid,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  lot_id uuid references public.inventory_lots(id) on delete restrict,
  location_id uuid references public.locations(id) on delete restrict,
  order_id uuid,
  quantity numeric(14,4) not null check (quantity > 0),
  status text not null default 'reserved' check (status in ('reserved','consumed','released')),
  reserved_at timestamptz not null default now(),
  resolved_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  notes text
);

create table public.material_remnants (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  lot_id uuid references public.inventory_lots(id) on delete restrict,
  location_id uuid references public.locations(id) on delete restrict,
  width numeric(14,4),
  height numeric(14,4),
  equivalent_quantity numeric(14,4) not null check (equivalent_quantity > 0),
  remaining_value numeric(14,2) not null default 0 check (remaining_value >= 0),
  origin_order_id uuid,
  status text not null default 'available' check (status in ('available','reserved','used','sample','waste')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.waste_records (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  lot_id uuid references public.inventory_lots(id) on delete restrict,
  order_id uuid,
  quantity numeric(14,4) not null check (quantity > 0),
  unit_cost numeric(14,4) not null default 0 check (unit_cost >= 0),
  reason text not null,
  recovered_value numeric(14,2) not null default 0 check (recovered_value >= 0),
  recovery_type text,
  created_by uuid references public.profiles(id) on delete set null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index material_variants_business_id_idx on public.material_variants(business_id);
create index material_variants_material_id_idx on public.material_variants(material_id);
create index inventory_lots_business_id_idx on public.inventory_lots(business_id);
create index inventory_lots_material_variant_id_idx on public.inventory_lots(material_variant_id);
create index inventory_lots_supplier_id_idx on public.inventory_lots(supplier_id);
create index inventory_movements_business_id_idx on public.inventory_movements(business_id);
create index inventory_movements_variant_location_idx on public.inventory_movements(material_variant_id, location_id, occurred_at);
create index inventory_movements_lot_id_idx on public.inventory_movements(lot_id);
create index inventory_reservations_business_id_idx on public.inventory_reservations(business_id);
create index inventory_reservations_variant_status_idx on public.inventory_reservations(material_variant_id, status);
create index inventory_reservations_order_id_idx on public.inventory_reservations(order_id);
create index material_remnants_business_status_idx on public.material_remnants(business_id, status);
create index waste_records_business_id_idx on public.waste_records(business_id);
create index waste_records_variant_idx on public.waste_records(material_variant_id, occurred_at);

alter table public.material_variants enable row level security;
alter table public.inventory_lots enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.inventory_reservations enable row level security;
alter table public.material_remnants enable row level security;
alter table public.waste_records enable row level security;

grant select, insert, update, delete on public.material_variants, public.inventory_lots, public.inventory_movements, public.inventory_reservations, public.material_remnants, public.waste_records to authenticated;

create policy "material_variants_read" on public.material_variants for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "material_variants_insert" on public.material_variants for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "material_variants_update" on public.material_variants for update to authenticated
using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "material_variants_delete" on public.material_variants for delete to authenticated
using (private.has_business_permission(business_id,'inventory.adjust'));

create policy "inventory_lots_read" on public.inventory_lots for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "inventory_lots_insert" on public.inventory_lots for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "inventory_lots_update" on public.inventory_lots for update to authenticated
using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));

create policy "inventory_movements_read" on public.inventory_movements for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "inventory_movements_insert" on public.inventory_movements for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));

create policy "inventory_reservations_read" on public.inventory_reservations for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "inventory_reservations_insert" on public.inventory_reservations for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "inventory_reservations_update" on public.inventory_reservations for update to authenticated
using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));

create policy "material_remnants_read" on public.material_remnants for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "material_remnants_insert" on public.material_remnants for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));
create policy "material_remnants_update" on public.material_remnants for update to authenticated
using (private.has_business_permission(business_id,'inventory.adjust')) with check (private.has_business_permission(business_id,'inventory.adjust'));

create policy "waste_records_read" on public.waste_records for select to authenticated
using (private.is_business_member(business_id) and private.has_business_permission(business_id,'inventory.view'));
create policy "waste_records_insert" on public.waste_records for insert to authenticated
with check (private.has_business_permission(business_id,'inventory.adjust'));

create or replace view public.inventory_availability
with (security_invoker = true)
as
select
  mv.business_id,
  mv.id as material_variant_id,
  im.location_id,
  coalesce(sum(im.quantity) filter (where im.movement_type not in ('reservation','release')),0)::numeric(14,4) as physical_quantity,
  coalesce((select sum(ir.quantity) from public.inventory_reservations ir where ir.material_variant_id = mv.id and ir.location_id is not distinct from im.location_id and ir.status = 'reserved'),0)::numeric(14,4) as reserved_quantity,
  (coalesce(sum(im.quantity) filter (where im.movement_type not in ('reservation','release')),0) - coalesce((select sum(ir.quantity) from public.inventory_reservations ir where ir.material_variant_id = mv.id and ir.location_id is not distinct from im.location_id and ir.status = 'reserved'),0))::numeric(14,4) as available_quantity
from public.material_variants mv
left join public.inventory_movements im on im.material_variant_id = mv.id
group by mv.business_id, mv.id, im.location_id;

grant select on public.inventory_availability to authenticated;

-- order_id, origin_order_id and purchase_item_id are intentionally UUID placeholders for now.
-- Their foreign keys will be added when Compras/Comercial create the corresponding tables,
-- avoiding premature duplicate structures while preserving the approved relationships.
