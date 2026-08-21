create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  purchase_number text,
  status text not null default 'draft' check (status in ('draft','submitted','approved','partially_received','received','cancelled')),
  ordered_at timestamptz,
  expected_at timestamptz,
  currency text not null default 'MXN',
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  total numeric(14,2) not null default 0 check (total >= 0),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, purchase_number)
);

create table public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  description text,
  quantity_ordered numeric(14,4) not null check (quantity_ordered > 0),
  quantity_received numeric(14,4) not null default 0 check (quantity_received >= 0),
  unit_cost numeric(14,4) not null check (unit_cost >= 0),
  tax_rate numeric(7,4) not null default 0 check (tax_rate >= 0),
  status text not null default 'open' check (status in ('open','partially_received','received','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (quantity_received <= quantity_ordered)
);

create table public.purchase_receipts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete restrict,
  received_at timestamptz not null default now(),
  received_by uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create table public.purchase_receipt_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  receipt_id uuid not null references public.purchase_receipts(id) on delete cascade,
  purchase_item_id uuid not null references public.purchase_items(id) on delete restrict,
  material_variant_id uuid not null references public.material_variants(id) on delete restrict,
  quantity_received numeric(14,4) not null check (quantity_received > 0),
  unit_cost numeric(14,4) not null check (unit_cost >= 0),
  lot_number text,
  expiration_date date,
  review_date date,
  inventory_lot_id uuid references public.inventory_lots(id) on delete set null,
  created_at timestamptz not null default now()
);

create index purchases_business_id_idx on public.purchases(business_id);
create index purchases_supplier_id_idx on public.purchases(supplier_id);
create index purchases_created_by_idx on public.purchases(created_by);
create index purchases_approved_by_idx on public.purchases(approved_by);
create index purchase_items_business_id_idx on public.purchase_items(business_id);
create index purchase_items_purchase_id_idx on public.purchase_items(purchase_id);
create index purchase_items_material_variant_id_idx on public.purchase_items(material_variant_id);
create index purchase_receipts_business_id_idx on public.purchase_receipts(business_id);
create index purchase_receipts_purchase_id_idx on public.purchase_receipts(purchase_id);
create index purchase_receipts_location_id_idx on public.purchase_receipts(location_id);
create index purchase_receipts_received_by_idx on public.purchase_receipts(received_by);
create index purchase_receipt_items_business_id_idx on public.purchase_receipt_items(business_id);
create index purchase_receipt_items_receipt_id_idx on public.purchase_receipt_items(receipt_id);
create index purchase_receipt_items_purchase_item_id_idx on public.purchase_receipt_items(purchase_item_id);
create index purchase_receipt_items_material_variant_id_idx on public.purchase_receipt_items(material_variant_id);
create index purchase_receipt_items_inventory_lot_id_idx on public.purchase_receipt_items(inventory_lot_id);

alter table public.inventory_lots
  add constraint inventory_lots_purchase_item_id_fkey
  foreign key (purchase_item_id) references public.purchase_items(id) on delete set null;
create index if not exists inventory_lots_purchase_item_id_idx on public.inventory_lots(purchase_item_id);

create or replace function private.validate_purchase_approval()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    if coalesce(auth.role(),'') <> 'service_role' and not private.has_business_permission(new.business_id, 'purchases.approve') then
      raise exception 'purchases.approve permission required';
    end if;
    new.approved_by := coalesce(new.approved_by, auth.uid());
    new.approved_at := coalesce(new.approved_at, now());
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_validate_purchase_approval
before update on public.purchases
for each row execute function private.validate_purchase_approval();

create or replace function private.process_purchase_receipt_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_receipt public.purchase_receipts%rowtype;
  v_item public.purchase_items%rowtype;
  v_purchase public.purchases%rowtype;
  v_lot_id uuid;
  v_total_items integer;
  v_received_items integer;
  v_partial_items integer;
begin
  select * into v_receipt from public.purchase_receipts where id = new.receipt_id;
  if not found then raise exception 'receipt not found'; end if;

  select * into v_item from public.purchase_items where id = new.purchase_item_id for update;
  if not found then raise exception 'purchase item not found'; end if;

  select * into v_purchase from public.purchases where id = v_item.purchase_id for update;

  if v_receipt.business_id <> new.business_id or v_item.business_id <> new.business_id or v_purchase.business_id <> new.business_id then
    raise exception 'business mismatch';
  end if;
  if v_receipt.purchase_id <> v_item.purchase_id then
    raise exception 'receipt and purchase item belong to different purchases';
  end if;
  if v_item.material_variant_id <> new.material_variant_id then
    raise exception 'material variant mismatch';
  end if;
  if v_item.quantity_received + new.quantity_received > v_item.quantity_ordered then
    raise exception 'received quantity exceeds ordered quantity';
  end if;

  insert into public.inventory_lots (
    business_id, material_variant_id, supplier_id, purchase_item_id, lot_number,
    quantity_initial, quantity_remaining, unit_cost, received_at, expiration_date, review_date
  ) values (
    new.business_id, new.material_variant_id, v_purchase.supplier_id, new.purchase_item_id, new.lot_number,
    new.quantity_received, new.quantity_received, new.unit_cost, v_receipt.received_at, new.expiration_date, new.review_date
  ) returning id into v_lot_id;

  new.inventory_lot_id := v_lot_id;

  insert into public.inventory_movements (
    business_id, material_variant_id, lot_id, location_id, movement_type, quantity,
    unit_cost, reference_type, reference_id, notes, created_by, occurred_at
  ) values (
    new.business_id, new.material_variant_id, v_lot_id, v_receipt.location_id, 'purchase_receipt', new.quantity_received,
    new.unit_cost, 'purchase_receipt_item', new.id, v_receipt.notes, v_receipt.received_by, v_receipt.received_at
  );

  update public.purchase_items
  set quantity_received = quantity_received + new.quantity_received,
      status = case
        when quantity_received + new.quantity_received >= quantity_ordered then 'received'
        else 'partially_received'
      end,
      updated_at = now()
  where id = new.purchase_item_id;

  select count(*),
         count(*) filter (where status = 'received'),
         count(*) filter (where status = 'partially_received')
  into v_total_items, v_received_items, v_partial_items
  from public.purchase_items
  where purchase_id = v_item.purchase_id and status <> 'cancelled';

  update public.purchases
  set status = case
      when v_total_items > 0 and v_received_items = v_total_items then 'received'
      when v_received_items > 0 or v_partial_items > 0 then 'partially_received'
      else status
    end,
    updated_at = now()
  where id = v_item.purchase_id;

  return new;
end;
$$;

create trigger trg_process_purchase_receipt_item
before insert on public.purchase_receipt_items
for each row execute function private.process_purchase_receipt_item();

create or replace view public.purchase_in_transit
with (security_invoker = true)
as
select
  pi.business_id,
  p.id as purchase_id,
  p.purchase_number,
  p.supplier_id,
  pi.id as purchase_item_id,
  pi.material_variant_id,
  greatest(pi.quantity_ordered - pi.quantity_received, 0) as quantity_in_transit,
  pi.unit_cost,
  p.expected_at
from public.purchase_items pi
join public.purchases p on p.id = pi.purchase_id
where p.status in ('submitted','approved','partially_received')
  and pi.status in ('open','partially_received')
  and pi.quantity_received < pi.quantity_ordered;

alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.purchase_receipts enable row level security;
alter table public.purchase_receipt_items enable row level security;

grant select on public.purchases, public.purchase_items, public.purchase_receipts, public.purchase_receipt_items, public.purchase_in_transit to authenticated;
grant insert, update on public.purchases, public.purchase_items, public.purchase_receipts, public.purchase_receipt_items to authenticated;

create policy purchases_read on public.purchases
for select to authenticated
using (private.has_business_permission(business_id, 'purchases.view'));
create policy purchases_insert on public.purchases
for insert to authenticated
with check (private.has_business_permission(business_id, 'purchases.create'));
create policy purchases_update on public.purchases
for update to authenticated
using (private.has_business_permission(business_id, 'purchases.create') or private.has_business_permission(business_id, 'purchases.approve'))
with check (private.has_business_permission(business_id, 'purchases.create') or private.has_business_permission(business_id, 'purchases.approve'));

create policy purchase_items_read on public.purchase_items
for select to authenticated
using (private.has_business_permission(business_id, 'purchases.view'));
create policy purchase_items_insert on public.purchase_items
for insert to authenticated
with check (private.has_business_permission(business_id, 'purchases.create'));
create policy purchase_items_update on public.purchase_items
for update to authenticated
using (private.has_business_permission(business_id, 'purchases.create'))
with check (private.has_business_permission(business_id, 'purchases.create'));

create policy purchase_receipts_read on public.purchase_receipts
for select to authenticated
using (private.has_business_permission(business_id, 'purchases.view'));
create policy purchase_receipts_insert on public.purchase_receipts
for insert to authenticated
with check (private.has_business_permission(business_id, 'purchases.create'));
create policy purchase_receipts_update on public.purchase_receipts
for update to authenticated
using (private.has_business_permission(business_id, 'purchases.create'))
with check (private.has_business_permission(business_id, 'purchases.create'));

create policy purchase_receipt_items_read on public.purchase_receipt_items
for select to authenticated
using (private.has_business_permission(business_id, 'purchases.view'));
create policy purchase_receipt_items_insert on public.purchase_receipt_items
for insert to authenticated
with check (private.has_business_permission(business_id, 'purchases.create'));
create policy purchase_receipt_items_update on public.purchase_receipt_items
for update to authenticated
using (private.has_business_permission(business_id, 'purchases.create'))
with check (private.has_business_permission(business_id, 'purchases.create'));
