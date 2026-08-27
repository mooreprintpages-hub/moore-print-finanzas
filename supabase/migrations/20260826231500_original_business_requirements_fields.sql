alter table public.customers add column if not exists whatsapp_label_color text;
alter table public.orders add column if not exists optional_extra numeric not null default 0 check (optional_extra >= 0);
alter table public.orders add column if not exists pickup_method text check (pickup_method is null or pickup_method in ('didi','bus','own','other'));
alter table public.orders add column if not exists pickup_cost numeric not null default 0 check (pickup_cost >= 0);
alter table public.materials add column if not exists minimum_purchase_qty numeric;
alter table public.materials add column if not exists purchase_increment numeric;
alter table public.materials add column if not exists max_cut_qty numeric;
alter table public.materials add column if not exists pricing_formula text;
alter table public.materials add column if not exists rounding_increment numeric;

create or replace function public.validate_purchase_item_material_rules()
returns trigger
language plpgsql
set search_path = public
as $$
declare v_min numeric; v_inc numeric;
begin
  if new.material_variant_id is null then return new; end if;
  select m.minimum_purchase_qty,m.purchase_increment into v_min,v_inc
  from public.material_variants mv join public.materials m on m.id=mv.material_id
  where mv.id=new.material_variant_id;
  if v_min is not null and new.quantity_ordered < v_min then
    raise exception 'La cantidad mínima de compra para este material es %',v_min;
  end if;
  if v_inc is not null and v_inc > 0 and mod(new.quantity_ordered,v_inc) <> 0 then
    raise exception 'La compra de este material debe hacerse en incrementos de %',v_inc;
  end if;
  return new;
end $$;

drop trigger if exists trg_validate_purchase_item_material_rules on public.purchase_items;
create trigger trg_validate_purchase_item_material_rules
before insert or update of material_variant_id,quantity_ordered on public.purchase_items
for each row execute function public.validate_purchase_item_material_rules();

update public.materials set minimum_purchase_qty=coalesce(minimum_purchase_qty,0.5),purchase_increment=coalesce(purchase_increment,0.5)
where lower(name) like '%dtf%' or lower(name) like '%vinil%';
update public.materials set max_cut_qty=coalesce(max_cut_qty,1) where lower(name) like '%vinil%';
update public.materials set pricing_formula=coalesce(pricing_formula,'square_meter'),rounding_increment=coalesce(rounding_increment,10)
where lower(name) like '%lona%' or lower(category) like '%lona%';
