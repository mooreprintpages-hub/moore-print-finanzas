alter table public.quote_items add column quote_option_id uuid references public.quote_options(id) on delete set null;
create index quote_items_option_id_idx on public.quote_items(quote_option_id);

create or replace function public.validate_quote_item_option()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  option_version uuid;
  option_business uuid;
begin
  if new.quote_option_id is null then return new; end if;
  select qo.quote_version_id, qo.business_id into option_version, option_business
  from public.quote_options qo where qo.id = new.quote_option_id;
  if option_version is distinct from new.quote_version_id or option_business is distinct from new.business_id then
    raise exception 'Quote option must belong to the same quote version and business';
  end if;
  return new;
end;
$$;
create trigger validate_quote_item_option_trigger
before insert or update of quote_option_id, quote_version_id, business_id on public.quote_items
for each row execute function public.validate_quote_item_option();

create or replace function public.prevent_sent_quote_version_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.sent_at is not null then
    raise exception 'Sent quote versions are immutable; create a new version instead';
  end if;
  return new;
end;
$$;
create trigger prevent_sent_quote_version_update_trigger
before update on public.quote_versions
for each row execute function public.prevent_sent_quote_version_update();

create or replace function public.prevent_sent_quote_child_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  target_version uuid;
  target_sent_at timestamptz;
begin
  target_version := coalesce(new.quote_version_id, old.quote_version_id);
  select qv.sent_at into target_sent_at from public.quote_versions qv where qv.id = target_version;
  if target_sent_at is not null then
    raise exception 'Items/options of a sent quote version are immutable; create a new version instead';
  end if;
  return coalesce(new, old);
end;
$$;
create trigger prevent_sent_quote_item_mutation_trigger
before insert or update or delete on public.quote_items
for each row execute function public.prevent_sent_quote_child_mutation();
create trigger prevent_sent_quote_option_mutation_trigger
before insert or update or delete on public.quote_options
for each row execute function public.prevent_sent_quote_child_mutation();

create or replace function public.recalculate_quote_version_totals(target_version uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  raw_subtotal numeric(14,2);
  item_discount numeric(14,2);
begin
  select coalesce(sum(qi.quantity * qi.unit_price),0), coalesce(sum(qi.discount),0)
    into raw_subtotal, item_discount
  from public.quote_items qi where qi.quote_version_id = target_version;

  update public.quote_versions qv
  set subtotal = raw_subtotal,
      total = greatest(raw_subtotal - item_discount - qv.discount + qv.tax + qv.delivery_fee, 0)
  where qv.id = target_version and qv.sent_at is null;
end;
$$;

create or replace function public.quote_item_totals_trigger()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE','DELETE') then perform public.recalculate_quote_version_totals(old.quote_version_id); end if;
  if tg_op in ('INSERT','UPDATE') then perform public.recalculate_quote_version_totals(new.quote_version_id); end if;
  return coalesce(new, old);
end;
$$;
create trigger quote_item_totals_after_change
after insert or update or delete on public.quote_items
for each row execute function public.quote_item_totals_trigger();

create or replace function public.quote_version_header_totals_trigger()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.sent_at is null and (new.discount is distinct from old.discount or new.tax is distinct from old.tax or new.delivery_fee is distinct from old.delivery_fee) then
    perform public.recalculate_quote_version_totals(new.id);
  end if;
  return new;
end;
$$;
create trigger quote_version_header_totals_after_change
after update of discount, tax, delivery_fee on public.quote_versions
for each row execute function public.quote_version_header_totals_trigger();

create or replace function public.recalculate_order_totals(target_order uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  raw_subtotal numeric(14,2);
  item_discount numeric(14,2);
begin
  select coalesce(sum(oi.quantity * oi.unit_price),0), coalesce(sum(oi.discount),0)
    into raw_subtotal, item_discount
  from public.order_items oi where oi.order_id = target_order;

  update public.orders o
  set subtotal = raw_subtotal,
      total = greatest(raw_subtotal - item_discount - o.discount + o.tax + o.delivery_fee, 0),
      updated_at = now()
  where o.id = target_order;
end;
$$;

create or replace function public.order_item_totals_trigger()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE','DELETE') then perform public.recalculate_order_totals(old.order_id); end if;
  if tg_op in ('INSERT','UPDATE') then perform public.recalculate_order_totals(new.order_id); end if;
  return coalesce(new, old);
end;
$$;
create trigger order_item_totals_after_change
after insert or update or delete on public.order_items
for each row execute function public.order_item_totals_trigger();

create or replace function public.order_header_totals_trigger()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.discount is distinct from old.discount or new.tax is distinct from old.tax or new.delivery_fee is distinct from old.delivery_fee then
    perform public.recalculate_order_totals(new.id);
  end if;
  return new;
end;
$$;
create trigger order_header_totals_after_change
after update of discount, tax, delivery_fee on public.orders
for each row execute function public.order_header_totals_trigger();

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
  if not public.private.has_business_permission(v_quote.business_id,'orders.create') then
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
grant execute on function public.convert_quote_version_to_order(uuid,text,text,timestamptz) to authenticated;

create or replace function public.instantiate_order_workflow()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  insert into public.order_workflow_steps(business_id, order_workflow_id, template_step_id, step_key, name, description, sort_order, status)
  select new.business_id, new.id, wts.id, wts.step_key, wts.name, wts.description, wts.sort_order, 'pending'
  from public.workflow_template_steps wts
  where wts.workflow_template_id = new.workflow_template_id
  order by wts.sort_order, wts.created_at;

  insert into public.order_workflow_step_dependencies(business_id, order_workflow_step_id, depends_on_order_workflow_step_id)
  select new.business_id, child.id, parent.id
  from public.workflow_step_dependencies d
  join public.order_workflow_steps child on child.order_workflow_id = new.id and child.template_step_id = d.step_id
  join public.order_workflow_steps parent on parent.order_workflow_id = new.id and parent.template_step_id = d.depends_on_step_id
  where d.business_id = new.business_id;

  return new;
end;
$$;
create trigger instantiate_order_workflow_trigger
after insert on public.order_workflows
for each row execute function public.instantiate_order_workflow();

create or replace function public.enforce_workflow_step_dependencies()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('in_progress','completed') and new.status is distinct from old.status then
    if exists (
      select 1
      from public.order_workflow_step_dependencies d
      join public.order_workflow_steps dep on dep.id = d.depends_on_order_workflow_step_id
      where d.order_workflow_step_id = new.id and dep.status <> 'completed'
    ) then
      raise exception 'Workflow step dependencies are not completed';
    end if;
  end if;
  if new.status = 'in_progress' and new.started_at is null then new.started_at := now(); end if;
  if new.status = 'completed' and new.completed_at is null then new.completed_at := now(); end if;
  return new;
end;
$$;
create trigger enforce_workflow_step_dependencies_trigger
before update of status on public.order_workflow_steps
for each row execute function public.enforce_workflow_step_dependencies();

create or replace function public.sync_order_workflow_status()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  total_steps integer;
  completed_steps integer;
  active_steps integer;
begin
  select count(*), count(*) filter (where status='completed'), count(*) filter (where status='in_progress')
  into total_steps, completed_steps, active_steps
  from public.order_workflow_steps where order_workflow_id = new.order_workflow_id;

  update public.order_workflows ow
  set status = case
      when total_steps > 0 and completed_steps = total_steps then 'completed'
      when active_steps > 0 or completed_steps > 0 then 'in_progress'
      else ow.status end,
      started_at = case when (active_steps > 0 or completed_steps > 0) and ow.started_at is null then now() else ow.started_at end,
      completed_at = case when total_steps > 0 and completed_steps = total_steps then coalesce(ow.completed_at,now()) else ow.completed_at end
  where ow.id = new.order_workflow_id;
  return new;
end;
$$;
create trigger sync_order_workflow_status_trigger
after update of status on public.order_workflow_steps
for each row execute function public.sync_order_workflow_status();

alter table public.inventory_reservations add constraint inventory_reservations_order_id_fkey foreign key (order_id) references public.orders(id) on delete cascade;
alter table public.material_remnants add constraint material_remnants_origin_order_id_fkey foreign key (origin_order_id) references public.orders(id) on delete set null;
alter table public.waste_records add constraint waste_records_order_id_fkey foreign key (order_id) references public.orders(id) on delete set null;
create index material_remnants_origin_order_id_idx on public.material_remnants(origin_order_id);
create index waste_records_order_id_idx on public.waste_records(order_id);
