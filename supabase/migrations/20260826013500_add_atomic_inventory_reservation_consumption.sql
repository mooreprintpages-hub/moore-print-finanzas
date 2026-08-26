create or replace function public.consume_inventory_reservation(p_reservation_id uuid)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  r public.inventory_reservations%rowtype;
begin
  select * into r
  from public.inventory_reservations
  where id = p_reservation_id
  for update;

  if not found then
    raise exception 'Inventory reservation not found';
  end if;

  if r.status <> 'reserved' then
    raise exception 'Inventory reservation is not active';
  end if;

  insert into public.inventory_movements (
    business_id,
    material_variant_id,
    lot_id,
    location_id,
    movement_type,
    quantity,
    reference_type,
    reference_id,
    notes,
    created_by
  ) values (
    r.business_id,
    r.material_variant_id,
    r.lot_id,
    r.location_id,
    'consumption',
    -r.quantity,
    'reservation',
    r.id,
    'Consumption from inventory reservation',
    auth.uid()
  );

  update public.inventory_reservations
  set status = 'consumed',
      resolved_at = now()
  where id = r.id;
end;
$$;

revoke all on function public.consume_inventory_reservation(uuid) from public;
grant execute on function public.consume_inventory_reservation(uuid) to authenticated;
