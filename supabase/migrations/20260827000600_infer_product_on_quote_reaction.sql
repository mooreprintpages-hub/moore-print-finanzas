create or replace function public.infer_quote_reaction_product()
returns trigger
language plpgsql
set search_path=public
as $$
declare
  v_product uuid;
  v_count integer;
begin
  if new.product_id is not null or new.quote_version_id is null then return new; end if;

  select min(qi.product_id),count(distinct qi.product_id)
    into v_product,v_count
  from public.quote_items qi
  where qi.quote_version_id=new.quote_version_id;

  if v_count=1 then new.product_id=v_product; end if;
  return new;
end $$;

drop trigger if exists trg_infer_quote_reaction_product on public.quote_price_reactions;
create trigger trg_infer_quote_reaction_product
before insert or update of quote_version_id,product_id on public.quote_price_reactions
for each row execute function public.infer_quote_reaction_product();
