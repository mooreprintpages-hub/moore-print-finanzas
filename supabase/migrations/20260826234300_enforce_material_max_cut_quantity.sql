create or replace function public.validate_purchase_item_material_rules()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_min numeric;
  v_inc numeric;
  v_max_cut numeric;
begin
  if new.material_variant_id is null then return new; end if;

  select m.minimum_purchase_qty,m.purchase_increment,m.max_cut_qty
    into v_min,v_inc,v_max_cut
  from public.material_variants mv
  join public.materials m on m.id=mv.material_id
  where mv.id=new.material_variant_id;

  if v_min is not null and new.quantity_ordered < v_min then
    raise exception 'La cantidad mínima de compra para este material es %',v_min;
  end if;

  if v_inc is not null and v_inc > 0 and mod(new.quantity_ordered,v_inc) <> 0 then
    raise exception 'La compra de este material debe hacerse en incrementos de %',v_inc;
  end if;

  if v_max_cut is not null and v_max_cut > 0 and new.quantity_ordered > v_max_cut then
    raise exception 'Este material admite máximo % por corte/partida de compra; agrega otra partida para cantidades mayores',v_max_cut;
  end if;

  return new;
end $$;
