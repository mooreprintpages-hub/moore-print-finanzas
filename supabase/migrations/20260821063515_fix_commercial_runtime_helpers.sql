create or replace function public.prevent_sent_quote_child_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  target_version uuid;
  target_sent_at timestamptz;
begin
  if tg_op = 'DELETE' then target_version := old.quote_version_id; else target_version := new.quote_version_id; end if;
  select qv.sent_at into target_sent_at from public.quote_versions qv where qv.id = target_version;
  if target_sent_at is not null then
    raise exception 'Items/options of a sent quote version are immutable; create a new version instead';
  end if;
  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;

create or replace function public.convert_quote_version_to_order(
  target_quote_version_id uuid,
  target_folio text,
  target_priority text default 'normal',
  target_promised_at timestamptz default null
)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_quote public.quotes%rowtype;
  v_version public.quote_versions%rowtype;
  v_order_id uuid;
begin
  select * into v_version from public.quote_versions where id = target_quote_version_id;
  if not found then raise exception 'Quote version not found'; end if;
  select * into v_quote from public.quotes where id = v_version.quote_id and deleted_at is null;
  if not found then raise exception 'Quote not found'; end if;
  if not private.has_business_permission(v_quote.business_id,'orders.create') then
    raise exception 'Permission denied';
  end if;

  insert into public.orders(business_id, customer_id, source_quote_id, source_quote_version_id, folio, status, priority, promised_at, discount, tax, delivery_fee, created_by)
  values(v_quote.business_id, v_quote.customer_id, v_quote.id, v_version.id, target_folio, 'draft', target_priority, target_promised_at, 0, v_version.tax, v_version.delivery_fee, auth.uid())
  returning id into v_order_id;

  insert into public.order_items(business_id, order_id, product_id, product_variant_id, description, quantity, unit_price, discount, estimated_cost, status, promised_at)
  select qi.business_id, v_order_id, qi.product_id, qi.product_variant_id, qi.description, qi.quantity, qi.unit_price, qi.discount, qi.estimated_cost, 'pending', target_promised_at
  from public.quote_items qi where qi.quote_version_id = v_version.id;

  perform public.recalculate_order_totals(v_order_id);
  return v_order_id;
end;
$$;