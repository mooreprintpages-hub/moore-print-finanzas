create or replace function public.create_inventory_reservation(
  p_business_id uuid,
  p_material_variant_id uuid,
  p_location_id uuid,
  p_quantity numeric,
  p_order_id uuid default null,
  p_lot_id uuid default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation_id uuid;
  v_available numeric;
  v_lot_remaining numeric;
  v_lot_available numeric;
begin
  if (select auth.uid()) is null
     or not private.has_business_permission(p_business_id, 'inventory.adjust') then
    raise exception 'Insufficient inventory permission' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Reservation quantity must be greater than zero';
  end if;

  if not exists (
    select 1 from public.material_variants mv
    where mv.id = p_material_variant_id
      and mv.business_id = p_business_id
      and mv.active = true
  ) then
    raise exception 'Material variant does not belong to business';
  end if;

  if not exists (
    select 1 from public.locations l
    where l.id = p_location_id
      and l.business_id = p_business_id
      and l.active = true
  ) then
    raise exception 'Location does not belong to business';
  end if;

  if p_order_id is not null and not exists (
    select 1 from public.orders o
    where o.id = p_order_id
      and o.business_id = p_business_id
      and o.deleted_at is null
  ) then
    raise exception 'Order does not belong to business';
  end if;

  select ia.available_quantity
    into v_available
  from public.inventory_availability ia
  where ia.business_id = p_business_id
    and ia.material_variant_id = p_material_variant_id
    and ia.location_id = p_location_id;

  v_available := coalesce(v_available, 0);
  if v_available < p_quantity then
    raise exception 'Insufficient available inventory at location. Available: %', v_available;
  end if;

  if p_lot_id is not null then
    select il.quantity_remaining
      into v_lot_remaining
    from public.inventory_lots il
    where il.id = p_lot_id
      and il.business_id = p_business_id
      and il.material_variant_id = p_material_variant_id
    for update;

    if not found then
      raise exception 'Inventory lot does not match material variant';
    end if;

    select
      coalesce(sum(im.quantity) filter (
        where im.movement_type not in ('reservation','release')
      ), 0)
      - coalesce((
        select sum(ir.quantity)
        from public.inventory_reservations ir
        where ir.business_id = p_business_id
          and ir.material_variant_id = p_material_variant_id
          and ir.lot_id = p_lot_id
          and ir.location_id = p_location_id
          and ir.status = 'reserved'
      ), 0)
      into v_lot_available
    from public.inventory_movements im
    where im.business_id = p_business_id
      and im.material_variant_id = p_material_variant_id
      and im.lot_id = p_lot_id
      and im.location_id = p_location_id;

    v_lot_available := least(v_lot_remaining, coalesce(v_lot_available, 0));
    if v_lot_available < p_quantity then
      raise exception 'Insufficient inventory in selected lot at location. Available: %', v_lot_available;
    end if;
  end if;

  insert into public.inventory_reservations (
    business_id, material_variant_id, lot_id, location_id, order_id,
    quantity, status, created_by, notes
  ) values (
    p_business_id, p_material_variant_id, p_lot_id, p_location_id, p_order_id,
    p_quantity, 'reserved', (select auth.uid()), nullif(trim(p_notes), '')
  ) returning id into v_reservation_id;

  return v_reservation_id;
end;
$$;

revoke all on function public.create_inventory_reservation(uuid,uuid,uuid,numeric,uuid,uuid,text) from public;
grant execute on function public.create_inventory_reservation(uuid,uuid,uuid,numeric,uuid,uuid,text) to authenticated;

create or replace function public.consume_inventory_reservation(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.inventory_reservations%rowtype;
  v_lot_remaining numeric;
begin
  select * into r
  from public.inventory_reservations
  where id = p_reservation_id
  for update;

  if not found then
    raise exception 'Inventory reservation not found';
  end if;

  if (select auth.uid()) is null
     or not private.has_business_permission(r.business_id, 'inventory.adjust') then
    raise exception 'Insufficient inventory permission' using errcode = '42501';
  end if;

  if r.status <> 'reserved' then
    raise exception 'Inventory reservation is not active';
  end if;

  if r.location_id is null then
    raise exception 'Reservation has no inventory location; assign a location before consuming';
  end if;

  if r.lot_id is not null then
    select quantity_remaining into v_lot_remaining
    from public.inventory_lots
    where id = r.lot_id
      and business_id = r.business_id
      and material_variant_id = r.material_variant_id
    for update;

    if not found then
      raise exception 'Inventory lot not found for reservation';
    end if;
    if v_lot_remaining < r.quantity then
      raise exception 'Inventory lot has insufficient remaining quantity';
    end if;
  end if;

  insert into public.inventory_movements (
    business_id, material_variant_id, lot_id, location_id,
    movement_type, quantity, reference_type, reference_id, notes, created_by
  ) values (
    r.business_id, r.material_variant_id, r.lot_id, r.location_id,
    'consumption', -r.quantity, 'reservation', r.id,
    'Consumption from inventory reservation', (select auth.uid())
  );

  if r.lot_id is not null then
    update public.inventory_lots
    set quantity_remaining = quantity_remaining - r.quantity
    where id = r.lot_id;
  end if;

  update public.inventory_reservations
  set status = 'consumed', resolved_at = now()
  where id = r.id;
end;
$$;

revoke all on function public.consume_inventory_reservation(uuid) from public;
grant execute on function public.consume_inventory_reservation(uuid) to authenticated;
