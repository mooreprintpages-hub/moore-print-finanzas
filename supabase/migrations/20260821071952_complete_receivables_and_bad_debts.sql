create table public.payment_plans (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  total_amount numeric(14,2) not null,
  installment_count integer not null,
  start_date date not null,
  status text not null default 'active' check (status in ('draft','active','completed','cancelled','defaulted')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (total_amount > 0),
  check (installment_count > 0)
);

create table public.payment_plan_installments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  payment_plan_id uuid not null references public.payment_plans(id) on delete cascade,
  installment_number integer not null,
  due_date date not null,
  amount numeric(14,2) not null,
  status text not null default 'pending' check (status in ('pending','partial','paid','overdue','cancelled')),
  paid_amount numeric(14,2) not null default 0,
  paid_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(payment_plan_id, installment_number),
  check (amount > 0),
  check (paid_amount >= 0)
);

create table public.bad_debts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  amount numeric(14,2) not null,
  reason text,
  declared_at date not null default current_date,
  authorized_by uuid references auth.users(id) on delete set null,
  status text not null default 'written_off' check (status in ('written_off','partially_recovered','recovered','reversed')),
  created_at timestamptz not null default now(),
  check (amount > 0)
);

create table public.bad_debt_recoveries (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  bad_debt_id uuid not null references public.bad_debts(id) on delete cascade,
  payment_id uuid references public.payments(id) on delete set null,
  account_id uuid references public.financial_accounts(id) on delete set null,
  amount numeric(14,2) not null,
  recovered_at timestamptz not null default now(),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (amount > 0)
);

create index payment_plans_business_idx on public.payment_plans(business_id);
create index payment_plans_customer_idx on public.payment_plans(customer_id);
create index payment_plans_order_idx on public.payment_plans(order_id);
create index payment_plans_created_by_idx on public.payment_plans(created_by);
create index payment_plan_installments_business_idx on public.payment_plan_installments(business_id);
create index payment_plan_installments_plan_idx on public.payment_plan_installments(payment_plan_id);
create index payment_plan_installments_due_idx on public.payment_plan_installments(business_id,due_date,status);
create index bad_debts_business_idx on public.bad_debts(business_id);
create index bad_debts_customer_idx on public.bad_debts(customer_id);
create index bad_debts_order_idx on public.bad_debts(order_id);
create index bad_debts_authorized_by_idx on public.bad_debts(authorized_by);
create index bad_debt_recoveries_business_idx on public.bad_debt_recoveries(business_id);
create index bad_debt_recoveries_bad_debt_idx on public.bad_debt_recoveries(bad_debt_id);
create index bad_debt_recoveries_payment_idx on public.bad_debt_recoveries(payment_id);
create index bad_debt_recoveries_account_idx on public.bad_debt_recoveries(account_id);
create index bad_debt_recoveries_created_by_idx on public.bad_debt_recoveries(created_by);

alter table public.payment_plans enable row level security;
alter table public.payment_plan_installments enable row level security;
alter table public.bad_debts enable row level security;
alter table public.bad_debt_recoveries enable row level security;

create policy payment_plans_read on public.payment_plans for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy payment_plans_insert on public.payment_plans for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_plans_update on public.payment_plans for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_plans_delete on public.payment_plans for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

create policy payment_plan_installments_read on public.payment_plan_installments for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy payment_plan_installments_insert on public.payment_plan_installments for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_plan_installments_update on public.payment_plan_installments for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_plan_installments_delete on public.payment_plan_installments for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

create policy bad_debts_read on public.bad_debts for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy bad_debts_insert on public.bad_debts for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy bad_debts_update on public.bad_debts for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));

create policy bad_debt_recoveries_read on public.bad_debt_recoveries for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy bad_debt_recoveries_insert on public.bad_debt_recoveries for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));

grant select,insert,update,delete on public.payment_plans, public.payment_plan_installments to authenticated;
grant select,insert,update on public.bad_debts to authenticated;
grant select,insert on public.bad_debt_recoveries to authenticated;

create or replace view public.bad_debt_balances
with (security_invoker=true) as
select bd.id as bad_debt_id, bd.business_id, bd.customer_id, bd.order_id, bd.amount as written_off_amount,
       coalesce(sum(br.amount),0)::numeric(14,2) as recovered_amount,
       greatest(bd.amount-coalesce(sum(br.amount),0),0)::numeric(14,2) as remaining_amount
from public.bad_debts bd
left join public.bad_debt_recoveries br on br.bad_debt_id=bd.id
group by bd.id;
grant select on public.bad_debt_balances to authenticated;
