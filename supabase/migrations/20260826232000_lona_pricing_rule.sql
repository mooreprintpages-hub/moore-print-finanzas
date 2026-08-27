alter table public.materials add column if not exists pricing_rate numeric;
update public.materials
set pricing_rate=coalesce(pricing_rate,90), pricing_formula=coalesce(pricing_formula,'square_meter'), rounding_increment=coalesce(rounding_increment,10)
where lower(name) like '%lona%' or lower(category) like '%lona%';

create or replace function public.calculate_material_area_price(p_material_id uuid,p_width numeric,p_height numeric)
returns numeric
language plpgsql
stable
set search_path=public
as $$
declare v_rate numeric; v_round numeric; v_raw numeric;
begin
  if p_width <= 0 or p_height <= 0 then raise exception 'Las medidas deben ser mayores a cero'; end if;
  select pricing_rate,rounding_increment into v_rate,v_round from public.materials where id=p_material_id;
  if v_rate is null then raise exception 'El material no tiene tarifa por área configurada'; end if;
  v_raw:=p_width*p_height*v_rate;
  if v_round is null or v_round <= 0 then return round(v_raw,2); end if;
  return ceil(v_raw/v_round)*v_round;
end $$;
