create or replace function public.infer_quote_reaction_product()
returns trigger
language plpgsql
set search_path=''
as $$
declare
  v_product_id uuid;
  v_product_count integer;
begin
  if new.product_id is not null or new.quote_version_id is null then
    return new;
  end if;

  select (array_agg(distinct qi.product_id))[1], count(distinct qi.product_id)
    into v_product_id, v_product_count
  from public.quote_items qi
  where qi.quote_version_id = new.quote_version_id;

  if v_product_count = 1 then
    new.product_id := v_product_id;
  end if;

  return new;
end;
$$;
