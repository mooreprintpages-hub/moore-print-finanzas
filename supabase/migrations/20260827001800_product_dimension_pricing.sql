alter table public.products
  add column if not exists pricing_formula text
  check (pricing_formula is null or pricing_formula in ('square_meter'));

alter table public.products
  add column if not exists pricing_rate numeric
  check (pricing_rate is null or pricing_rate >= 0);

alter table public.products
  add column if not exists rounding_increment numeric
  check (rounding_increment is null or rounding_increment > 0);

update public.products
set pricing_formula=coalesce(pricing_formula,'square_meter'),
    pricing_rate=coalesce(pricing_rate,90),
    rounding_increment=coalesce(rounding_increment,10)
where lower(name)='lona';

create or replace function public.calculate_product_dimension_price(
  p_product_id uuid,
  p_width numeric,
  p_height numeric
)
returns numeric
language plpgsql
stable
set search_path=public
as $$
declare
  v_rate numeric;
  v_round numeric;
  v_formula text;
  v_raw numeric;
begin
  if p_width is null or p_height is null or p_width<=0 or p_height<=0 then
    raise exception 'Ancho y alto deben ser mayores a cero';
  end if;

  select pricing_formula,pricing_rate,rounding_increment
    into v_formula,v_rate,v_round
  from public.products
  where id=p_product_id and active=true and deleted_at is null;

  if not found then raise exception 'Producto no encontrado'; end if;
  if v_formula is distinct from 'square_meter' or v_rate is null then
    raise exception 'Este producto no tiene tarifa por metro cuadrado configurada';
  end if;

  v_raw := p_width*p_height*v_rate;
  if v_round is not null and v_round>0 then
    return ceil(v_raw/v_round)*v_round;
  end if;
  return v_raw;
end $$;
