create or replace function public.recalculate_order_totals(target_order uuid)
returns void
language plpgsql
set search_path=''
as $$
declare raw_subtotal numeric(14,2); item_discount numeric(14,2);
begin
  select coalesce(sum(oi.quantity*oi.unit_price),0),coalesce(sum(oi.discount),0)
    into raw_subtotal,item_discount
  from public.order_items oi where oi.order_id=target_order;
  update public.orders o
  set subtotal=raw_subtotal,
      total=greatest(raw_subtotal-item_discount-o.discount+o.tax+o.delivery_fee+coalesce(o.optional_extra,0),0),
      updated_at=now()
  where o.id=target_order;
end $$;

create or replace function public.order_header_totals_trigger()
returns trigger
language plpgsql
set search_path=''
as $$
begin
  if new.discount is distinct from old.discount
     or new.tax is distinct from old.tax
     or new.delivery_fee is distinct from old.delivery_fee
     or new.optional_extra is distinct from old.optional_extra then
    perform public.recalculate_order_totals(new.id);
  end if;
  return new;
end $$;
