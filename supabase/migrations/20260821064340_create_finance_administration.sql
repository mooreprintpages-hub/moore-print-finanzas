create table public.account_reconciliations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete cascade,
  reconciliation_date date not null default current_date,
  system_balance numeric(14,2) not null,
  actual_balance numeric(14,2) not null,
  difference numeric(14,2) generated always as (actual_balance - system_balance) stored,
  status text not null default 'pending' check (status in ('pending','reconciled','cancelled')),
  reconciled_by uuid references auth.users(id) on delete set null,
  reconciled_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create table public.owner_transactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete restrict,
  user_id uuid references auth.users(id) on delete set null,
  transaction_type text not null check (transaction_type in ('contribution','withdrawal','profit_distribution','reimbursement')),
  amount numeric(14,2) not null check (amount > 0),
  occurred_at timestamptz not null default now(),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.owner_compensation_targets (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  monthly_target numeric(14,2) not null check (monthly_target >= 0),
  valid_from date not null,
  valid_to date,
  notes text,
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to >= valid_from)
);

create table public.business_funds (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  target_amount numeric(14,2) check (target_amount is null or target_amount >= 0),
  target_date date,
  priority smallint not null default 0,
  contribution_rule text,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.fund_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  fund_id uuid not null references public.business_funds(id) on delete cascade,
  movement_type text not null check (movement_type in ('allocation','release','adjustment')),
  amount numeric(14,2) not null check (amount <> 0),
  occurred_at timestamptz not null default now(),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.assets (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  purchase_date date,
  purchase_cost numeric(14,2) check (purchase_cost is null or purchase_cost >= 0),
  status text not null default 'active' check (status in ('active','maintenance','retired','sold','disposed')),
  replacement_target_date date,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.business_debts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  initial_principal numeric(14,2) not null check (initial_principal >= 0),
  current_balance numeric(14,2) not null check (current_balance >= 0),
  interest_rate numeric(8,4),
  scheduled_payment numeric(14,2),
  next_payment_date date,
  status text not null default 'active' check (status in ('active','paid','paused','cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.debt_payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  debt_id uuid not null references public.business_debts(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete restrict,
  principal_amount numeric(14,2) not null default 0 check (principal_amount >= 0),
  interest_amount numeric(14,2) not null default 0 check (interest_amount >= 0),
  fee_amount numeric(14,2) not null default 0 check (fee_amount >= 0),
  total_amount numeric(14,2) generated always as (principal_amount + interest_amount + fee_amount) stored,
  paid_at timestamptz not null default now(),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (principal_amount + interest_amount + fee_amount > 0)
);

create table public.financial_goals (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  goal_type text not null check (goal_type in ('sales','profit','expenses','additional_profit','cash_reserve')),
  period_type text not null check (period_type in ('month','year','custom')),
  target_amount numeric(14,2) not null check (target_amount >= 0),
  period_start date not null,
  period_end date not null,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (period_end >= period_start)
);

create index account_reconciliations_account_idx on public.account_reconciliations(account_id, reconciliation_date desc);
create index account_reconciliations_business_idx on public.account_reconciliations(business_id);
create index owner_transactions_account_idx on public.owner_transactions(account_id, occurred_at desc);
create index owner_transactions_business_idx on public.owner_transactions(business_id);
create index owner_transactions_user_idx on public.owner_transactions(user_id);
create index owner_compensation_targets_business_idx on public.owner_compensation_targets(business_id);
create index owner_compensation_targets_user_idx on public.owner_compensation_targets(user_id);
create index business_funds_business_idx on public.business_funds(business_id);
create index fund_movements_fund_idx on public.fund_movements(fund_id, occurred_at desc);
create index fund_movements_business_idx on public.fund_movements(business_id);
create index fund_movements_created_by_idx on public.fund_movements(created_by);
create index assets_business_idx on public.assets(business_id);
create index business_debts_business_idx on public.business_debts(business_id);
create index debt_payments_debt_idx on public.debt_payments(debt_id, paid_at desc);
create index debt_payments_business_idx on public.debt_payments(business_id);
create index debt_payments_account_idx on public.debt_payments(account_id);
create index debt_payments_created_by_idx on public.debt_payments(created_by);
create index financial_goals_business_idx on public.financial_goals(business_id);

alter table public.account_reconciliations enable row level security;
alter table public.owner_transactions enable row level security;
alter table public.owner_compensation_targets enable row level security;
alter table public.business_funds enable row level security;
alter table public.fund_movements enable row level security;
alter table public.assets enable row level security;
alter table public.business_debts enable row level security;
alter table public.debt_payments enable row level security;
alter table public.financial_goals enable row level security;

do $$
declare t text;
begin
  foreach t in array array['account_reconciliations','owner_transactions','owner_compensation_targets','business_funds','fund_movements','assets','business_debts','debt_payments','financial_goals'] loop
    execute format('create policy %I on public.%I for select to authenticated using (private.has_business_permission(business_id, ''finance.view''))', t || '_read', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id, ''finance.manage''))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id, ''finance.manage'')) with check (private.has_business_permission(business_id, ''finance.manage''))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id, ''finance.manage''))', t || '_delete', t);
  end loop;
end $$;

grant select, insert, update, delete on public.account_reconciliations, public.owner_transactions, public.owner_compensation_targets, public.business_funds, public.fund_movements, public.assets, public.business_debts, public.debt_payments, public.financial_goals to authenticated;

create or replace function private.set_reconciliation_system_balance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select fa.opening_balance + coalesce(sum(am.amount),0)
  into new.system_balance
  from public.financial_accounts fa
  left join public.account_movements am on am.account_id = fa.id and am.occurred_at < (new.reconciliation_date + 1)::timestamptz
  where fa.id = new.account_id and fa.business_id = new.business_id
  group by fa.opening_balance;

  if new.system_balance is null then
    raise exception 'Financial account does not belong to business';
  end if;

  if new.status = 'reconciled' and new.reconciled_at is null then
    new.reconciled_at := now();
    new.reconciled_by := coalesce(new.reconciled_by, auth.uid());
  end if;
  return new;
end;
$$;

create trigger account_reconciliations_set_balance
before insert or update of account_id, reconciliation_date, status on public.account_reconciliations
for each row execute function private.set_reconciliation_system_balance();

create or replace function private.post_owner_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare signed_amount numeric(14,2);
begin
  if exists (select 1 from public.account_movements where source_type='owner_transaction' and source_id=new.id) then
    return new;
  end if;
  signed_amount := case when new.transaction_type='contribution' then new.amount else -new.amount end;
  insert into public.account_movements(business_id,account_id,movement_type,amount,occurred_at,source_type,source_id,notes,created_by)
  values (new.business_id,new.account_id,
          case when new.transaction_type='contribution' then 'owner_contribution' else 'owner_withdrawal' end,
          signed_amount,new.occurred_at,'owner_transaction',new.id,new.notes,new.created_by);
  return new;
end;
$$;

create trigger owner_transactions_post_movement
after insert on public.owner_transactions
for each row execute function private.post_owner_transaction();

create or replace function private.post_debt_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.principal_amount > 0 then
    update public.business_debts
    set current_balance = greatest(0,current_balance-new.principal_amount),
        status = case when greatest(0,current_balance-new.principal_amount)=0 then 'paid' else status end,
        updated_at=now()
    where id=new.debt_id and business_id=new.business_id;
  end if;

  if not exists (select 1 from public.account_movements where source_type='debt_payment' and source_id=new.id) then
    insert into public.account_movements(business_id,account_id,movement_type,amount,occurred_at,source_type,source_id,notes,created_by)
    values (new.business_id,new.account_id,'expense',-new.total_amount,new.paid_at,'debt_payment',new.id,new.notes,new.created_by);
  end if;
  return new;
end;
$$;

create trigger debt_payments_post
after insert on public.debt_payments
for each row execute function private.post_debt_payment();

create or replace view public.fund_balances
with (security_invoker=true)
as
select f.id as fund_id, f.business_id, f.name, f.target_amount,
       coalesce(sum(case fm.movement_type when 'allocation' then fm.amount when 'release' then -abs(fm.amount) else fm.amount end),0)::numeric(14,2) as allocated_amount
from public.business_funds f
left join public.fund_movements fm on fm.fund_id=f.id
group by f.id,f.business_id,f.name,f.target_amount;

grant select on public.fund_balances to authenticated;