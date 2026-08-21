create or replace function private.recalculate_purchase_totals()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_purchase_id uuid;
  v_subtotal numeric(14,2);
begin
  v_purchase_id := coalesce(new.purchase_id, old.purchase_id);

  select coalesce(sum(quantity_ordered * unit_cost), 0)::numeric(14,2)
  into v_subtotal
  from public.purchase_items
  where purchase_id = v_purchase_id and status <> 'cancelled';

  update public.purchases
  set subtotal = v_subtotal,
      total = v_subtotal + tax,
      updated_at = now()
  where id = v_purchase_id;

  return coalesce(new, old);
end;
$$;

create trigger trg_recalculate_purchase_totals
 after insert or update or delete on public.purchase_items
 for each row execute function private.recalculate_purchase_totals();

create or replace function private.keep_purchase_total_consistent()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.total := new.subtotal + new.tax;
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_keep_purchase_total_consistent
before insert or update of subtotal, tax on public.purchases
for each row execute function private.keep_purchase_total_consistent();

create or replace function private.record_purchase_material_cost()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_material_id uuid;
  v_supplier_id uuid;
  v_currency text;
  v_purchase_number text;
  v_effective_at timestamptz;
begin
  select mv.material_id, p.supplier_id, p.currency, p.purchase_number, pr.received_at
  into v_material_id, v_supplier_id, v_currency, v_purchase_number, v_effective_at
  from public.material_variants mv
  join public.purchase_items pi on pi.id = new.purchase_item_id
  join public.purchases p on p.id = pi.purchase_id
  join public.purchase_receipts pr on pr.id = new.receipt_id
  where mv.id = new.material_variant_id;

  insert into public.material_costs (
    business_id, material_id, supplier_id, unit_cost, currency, effective_at, source, notes
  ) values (
    new.business_id, v_material_id, v_supplier_id, new.unit_cost, v_currency,
    coalesce(v_effective_at, now()), 'purchase_receipt',
    case when v_purchase_number is null then null else 'Compra ' || v_purchase_number end
  );

  return new;
end;
$$;

create trigger trg_record_purchase_material_cost
 after insert on public.purchase_receipt_items
 for each row execute function private.record_purchase_material_cost();
