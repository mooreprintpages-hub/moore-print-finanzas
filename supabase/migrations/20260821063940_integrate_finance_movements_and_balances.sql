create or replace function private.sync_payment_account_movement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'confirmed' and (old.status is distinct from 'confirmed') then
    if new.account_id is null then
      raise exception 'A confirmed payment requires an account';
    end if;
    new.confirmed_at := coalesce(new.confirmed_at, now());
    insert into public.account_movements (
      business_id, account_id, movement_type, amount, occurred_at,
      source_type, source_id, customer_id, order_id, notes, created_by
    ) values (
      new.business_id, new.account_id, 'payment', new.amount, new.confirmed_at,
      'payment', new.id, new.customer_id, new.order_id, new.notes, coalesce(new.confirmed_by,new.created_by)
    ) on conflict (account_id, source_type, source_id, movement_type) do nothing;
  end if;
  return new;
end;
$$;

create trigger payments_sync_account_movement
before update on public.payments
for each row execute function private.sync_payment_account_movement();

create or replace function private.sync_payment_fee_movement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.payments;
  target_account uuid;
begin
  select * into p from public.payments where id = new.payment_id;
  if p.status <> 'confirmed' then
    return new;
  end if;
  target_account := coalesce(new.account_id, p.account_id);
  if new.amount > 0 and target_account is not null then
    insert into public.account_movements (
      business_id, account_id, movement_type, amount, occurred_at,
      source_type, source_id, customer_id, order_id, notes, created_by
    ) values (
      new.business_id, target_account, 'expense', -new.amount, coalesce(p.confirmed_at,now()),
      'payment_fee', new.id, p.customer_id, p.order_id, coalesce(new.description,'Comisión de pago'), p.confirmed_by
    ) on conflict (account_id, source_type, source_id, movement_type) do nothing;
  end if;
  return new;
end;
$$;

create trigger payment_fees_sync_account_movement
after insert or update on public.payment_fees
for each row execute function private.sync_payment_fee_movement();

create or replace function private.sync_expense_account_movement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'paid' and (tg_op = 'INSERT' or old.status is distinct from 'paid') then
    if new.account_id is null then
      raise exception 'A paid expense requires an account';
    end if;
    insert into public.account_movements (
      business_id, account_id, movement_type, amount, occurred_at,
      source_type, source_id, supplier_id, notes, created_by
    ) values (
      new.business_id, new.account_id, 'expense', -new.amount, new.expense_date::timestamptz,
      'expense', new.id, new.supplier_id, new.notes, new.created_by
    ) on conflict (account_id, source_type, source_id, movement_type) do nothing;
  end if;
  return new;
end;
$$;

create trigger expenses_sync_account_movement
after insert or update on public.expenses
for each row execute function private.sync_expense_account_movement();

create or replace function private.validate_expense_allocations()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  max_amount numeric(14,2);
  allocated numeric(14,2);
begin
  select business_amount into max_amount from public.expenses where id = new.expense_id;
  select coalesce(sum(amount),0) into allocated
  from public.expense_allocations
  where expense_id = new.expense_id and id <> new.id;
  if allocated + new.amount > max_amount then
    raise exception 'Order allocations cannot exceed the business portion of the expense';
  end if;
  return new;
end;
$$;

create trigger expense_allocations_validate
before insert or update on public.expense_allocations
for each row execute function private.validate_expense_allocations();

create or replace function private.sync_transfer_movements()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'completed' and (old.status is distinct from 'completed') then
    new.transferred_at := coalesce(new.transferred_at, now());
    insert into public.account_movements (
      business_id, account_id, movement_type, amount, occurred_at, source_type, source_id, notes, created_by
    ) values (
      new.business_id, new.source_account_id, 'transfer', -new.amount, new.transferred_at,
      'account_transfer', new.id, new.notes, new.created_by
    ) on conflict (account_id, source_type, source_id, movement_type) do nothing;

    insert into public.account_movements (
      business_id, account_id, movement_type, amount, occurred_at, source_type, source_id, notes, created_by
    ) values (
      new.business_id, new.destination_account_id, 'transfer', new.amount, new.transferred_at,
      'account_transfer', new.id, new.notes, new.created_by
    ) on conflict (account_id, source_type, source_id, movement_type) do nothing;

    if new.fee > 0 then
      insert into public.account_movements (
        business_id, account_id, movement_type, amount, occurred_at, source_type, source_id, notes, created_by
      ) values (
        new.business_id, new.source_account_id, 'expense', -new.fee, new.transferred_at,
        'account_transfer_fee', new.id, 'Comisión por transferencia', new.created_by
      ) on conflict (account_id, source_type, source_id, movement_type) do nothing;
    end if;
  end if;
  return new;
end;
$$;

create trigger account_transfers_sync_movements
before update on public.account_transfers
for each row execute function private.sync_transfer_movements();

create or replace function private.sync_refund_effect()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  credit_id uuid;
begin
  if new.status = 'completed' and (old.status is distinct from 'completed') then
    new.completed_at := coalesce(new.completed_at, now());
    if new.refund_type = 'store_credit' then
      insert into public.customer_credits (business_id, customer_id, source_order_id, source_refund_id, description)
      values (new.business_id, new.customer_id, new.order_id, new.id, 'Crédito generado por reembolso')
      returning id into credit_id;
      insert into public.customer_credit_movements (
        business_id, customer_credit_id, movement_type, amount, created_by, notes
      ) values (
        new.business_id, credit_id, 'created', new.amount, coalesce(new.authorized_by,new.created_by), 'Crédito por reembolso'
      );
    else
      if new.account_id is null then
        raise exception 'A cash refund requires an account';
      end if;
      insert into public.account_movements (
        business_id, account_id, movement_type, amount, occurred_at,
        source_type, source_id, customer_id, order_id, notes, created_by
      ) values (
        new.business_id, new.account_id, 'refund', -new.amount, new.completed_at,
        'refund', new.id, new.customer_id, new.order_id, new.reason, coalesce(new.authorized_by,new.created_by)
      ) on conflict (account_id, source_type, source_id, movement_type) do nothing;
    end if;
  end if;
  return new;
end;
$$;

create trigger refunds_sync_effect
before update on public.refunds
for each row execute function private.sync_refund_effect();

create or replace view public.financial_account_balances
with (security_invoker = true)
as
select
  a.id as account_id,
  a.business_id,
  a.name,
  a.account_type,
  a.currency,
  a.opening_balance,
  coalesce(sum(m.amount),0)::numeric(14,2) as movement_total,
  (a.opening_balance + coalesce(sum(m.amount),0))::numeric(14,2) as current_balance
from public.financial_accounts a
left join public.account_movements m on m.account_id = a.id
where a.active = true
group by a.id;

create or replace view public.customer_credit_balances
with (security_invoker = true)
as
select
  c.id as customer_credit_id,
  c.business_id,
  c.customer_id,
  c.source_order_id,
  coalesce(sum(case
    when m.movement_type = 'created' then m.amount
    when m.movement_type = 'used' then -m.amount
    when m.movement_type = 'reversed' then -m.amount
    else 0 end),0)::numeric(14,2) as balance
from public.customer_credits c
left join public.customer_credit_movements m on m.customer_credit_id = c.id
group by c.id;

create or replace view public.order_receivables
with (security_invoker = true)
as
with paid as (
  select order_id, sum(amount) as amount
  from public.payments
  where status = 'confirmed' and order_id is not null
  group by order_id
),
credit_used as (
  select m.order_id, sum(m.amount) as amount
  from public.customer_credit_movements m
  where m.movement_type = 'used' and m.order_id is not null
  group by m.order_id
),
cash_refunds as (
  select order_id, sum(amount) as amount
  from public.refunds
  where status = 'completed' and refund_type in ('partial','full') and order_id is not null
  group by order_id
)
select
  o.id as order_id,
  o.business_id,
  o.customer_id,
  o.total,
  coalesce(p.amount,0)::numeric(14,2) as confirmed_payments,
  coalesce(c.amount,0)::numeric(14,2) as credits_used,
  coalesce(r.amount,0)::numeric(14,2) as cash_refunds,
  greatest(o.total - coalesce(p.amount,0) - coalesce(c.amount,0) + coalesce(r.amount,0),0)::numeric(14,2) as balance_due
from public.orders o
left join paid p on p.order_id = o.id
left join credit_used c on c.order_id = o.id
left join cash_refunds r on r.order_id = o.id
where o.deleted_at is null and o.status <> 'cancelled';

grant select on public.financial_account_balances, public.customer_credit_balances, public.order_receivables to authenticated;
