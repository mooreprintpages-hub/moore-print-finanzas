insert into public.permissions (code, description) values
('finance.manage','Administrar cuentas y movimientos financieros'),
('refunds.create','Registrar reembolsos'),
('cash.manage','Administrar sesiones de caja')
on conflict (code) do nothing;

insert into public.role_permissions (role_id, permission_id, allowed)
select r.id, p.id, true
from public.roles r
join public.businesses b on b.id = r.business_id and b.name = 'Moore Print'
join public.permissions p on p.code in ('finance.manage','refunds.create','cash.manage')
where r.name = 'Propietario'
on conflict (role_id, permission_id) do update set allowed = excluded.allowed;

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  method_type text not null check (method_type in ('cash','transfer','mercado_pago','card','deposit','other')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.payment_method_fees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  payment_method_id uuid not null references public.payment_methods(id) on delete cascade,
  fee_type text not null check (fee_type in ('fixed','percent','mixed')),
  fixed_amount numeric(14,2) not null default 0 check (fixed_amount >= 0),
  percent_rate numeric(7,4) not null default 0 check (percent_rate >= 0),
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.financial_accounts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  account_type text not null check (account_type in ('cash','bank','mercado_pago','personal_business_use','other')),
  currency text not null default 'MXN',
  opening_balance numeric(14,2) not null default 0,
  opening_date date not null default current_date,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.account_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete cascade,
  movement_type text not null check (movement_type in ('payment','expense','transfer','deposit','withdrawal','adjustment','refund','owner_contribution','owner_withdrawal')),
  amount numeric(14,2) not null check (amount <> 0),
  occurred_at timestamptz not null default now(),
  source_type text,
  source_id uuid,
  customer_id uuid references public.customers(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  supplier_id uuid references public.suppliers(id) on delete set null,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (account_id, source_type, source_id, movement_type)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete restrict,
  order_id uuid references public.orders(id) on delete set null,
  account_id uuid references public.financial_accounts(id) on delete set null,
  payment_method_id uuid references public.payment_methods(id) on delete set null,
  amount numeric(14,2) not null check (amount > 0),
  payment_type text not null default 'payment' check (payment_type in ('payment','deposit','installment')),
  status text not null default 'reported' check (status in ('reported','pending_confirmation','confirmed','not_received','cancelled')),
  reported_at timestamptz not null default now(),
  confirmed_at timestamptz,
  reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  confirmed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_fees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  payment_id uuid not null references public.payments(id) on delete cascade,
  account_id uuid references public.financial_accounts(id) on delete set null,
  amount numeric(14,2) not null check (amount >= 0),
  description text,
  created_at timestamptz not null default now(),
  unique (payment_id)
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category text not null,
  account_id uuid references public.financial_accounts(id) on delete set null,
  amount numeric(14,2) not null check (amount > 0),
  business_amount numeric(14,2) not null default 0 check (business_amount >= 0),
  personal_amount numeric(14,2) not null default 0 check (personal_amount >= 0),
  expense_date date not null default current_date,
  status text not null default 'recorded' check (status in ('recorded','paid','cancelled')),
  recurrence text,
  supplier_id uuid references public.suppliers(id) on delete set null,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (business_amount + personal_amount = amount)
);

create table public.expense_allocations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  expense_id uuid not null references public.expenses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  created_at timestamptz not null default now(),
  unique (expense_id, order_id)
);

create table public.recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category text not null,
  description text not null,
  amount_type text not null check (amount_type in ('fixed','variable')),
  expected_amount numeric(14,2) check (expected_amount is null or expected_amount >= 0),
  frequency text not null,
  account_id uuid references public.financial_accounts(id) on delete set null,
  next_due_date date,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.account_transfers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  source_account_id uuid not null references public.financial_accounts(id) on delete restrict,
  destination_account_id uuid not null references public.financial_accounts(id) on delete restrict,
  amount numeric(14,2) not null check (amount > 0),
  fee numeric(14,2) not null default 0 check (fee >= 0),
  status text not null default 'pending' check (status in ('pending','completed','cancelled')),
  transferred_at timestamptz,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (source_account_id <> destination_account_id)
);

create table public.cash_transits (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  source_account_id uuid not null references public.financial_accounts(id) on delete restrict,
  destination_account_id uuid not null references public.financial_accounts(id) on delete restrict,
  amount numeric(14,2) not null check (amount > 0),
  status text not null default 'in_transit' check (status in ('in_transit','received','cancelled')),
  departed_at timestamptz not null default now(),
  received_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create table public.cash_sessions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete restrict,
  responsible_user_id uuid references auth.users(id) on delete set null,
  opening_amount numeric(14,2) not null,
  opened_at timestamptz not null default now(),
  expected_close_amount numeric(14,2),
  actual_close_amount numeric(14,2),
  difference numeric(14,2) generated always as (case when actual_close_amount is null or expected_close_amount is null then null else actual_close_amount - expected_close_amount end) stored,
  closed_at timestamptz,
  status text not null default 'open' check (status in ('open','closed','cancelled')),
  notes text,
  created_at timestamptz not null default now()
);

create table public.cash_session_adjustments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  cash_session_id uuid not null references public.cash_sessions(id) on delete cascade,
  amount numeric(14,2) not null check (amount <> 0),
  reason text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.customer_credits (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  source_order_id uuid references public.orders(id) on delete set null,
  source_refund_id uuid,
  description text,
  created_at timestamptz not null default now()
);

create table public.customer_credit_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_credit_id uuid not null references public.customer_credits(id) on delete cascade,
  movement_type text not null check (movement_type in ('created','used','reversed')),
  amount numeric(14,2) not null check (amount > 0),
  order_id uuid references public.orders(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete restrict,
  payment_id uuid references public.payments(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  account_id uuid references public.financial_accounts(id) on delete set null,
  refund_type text not null check (refund_type in ('partial','full','store_credit')),
  amount numeric(14,2) not null check (amount > 0),
  reason text not null,
  status text not null default 'pending' check (status in ('pending','approved','completed','cancelled')),
  authorized_by uuid references auth.users(id) on delete set null,
  completed_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.customer_credits
  add constraint customer_credits_source_refund_fkey foreign key (source_refund_id) references public.refunds(id) on delete set null;

create table public.payment_promises (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  order_id uuid references public.orders(id) on delete cascade,
  promised_amount numeric(14,2) not null check (promised_amount > 0),
  promised_date date not null,
  status text not null default 'pending' check (status in ('pending','fulfilled','broken','cancelled')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index payment_methods_business_id_idx on public.payment_methods(business_id);
create index payment_method_fees_method_idx on public.payment_method_fees(payment_method_id);
create index financial_accounts_business_id_idx on public.financial_accounts(business_id);
create index account_movements_business_id_idx on public.account_movements(business_id);
create index account_movements_account_date_idx on public.account_movements(account_id, occurred_at);
create index account_movements_customer_idx on public.account_movements(customer_id);
create index account_movements_order_idx on public.account_movements(order_id);
create index account_movements_supplier_idx on public.account_movements(supplier_id);
create index account_movements_created_by_idx on public.account_movements(created_by);
create index payments_business_id_idx on public.payments(business_id);
create index payments_customer_idx on public.payments(customer_id);
create index payments_order_idx on public.payments(order_id);
create index payments_account_idx on public.payments(account_id);
create index payments_method_idx on public.payments(payment_method_id);
create index payments_created_by_idx on public.payments(created_by);
create index payments_confirmed_by_idx on public.payments(confirmed_by);
create index payment_fees_business_id_idx on public.payment_fees(business_id);
create index payment_fees_account_idx on public.payment_fees(account_id);
create index expenses_business_id_idx on public.expenses(business_id);
create index expenses_account_idx on public.expenses(account_id);
create index expenses_supplier_idx on public.expenses(supplier_id);
create index expenses_created_by_idx on public.expenses(created_by);
create index expense_allocations_business_id_idx on public.expense_allocations(business_id);
create index expense_allocations_order_idx on public.expense_allocations(order_id);
create index recurring_expenses_business_id_idx on public.recurring_expenses(business_id);
create index recurring_expenses_account_idx on public.recurring_expenses(account_id);
create index account_transfers_business_id_idx on public.account_transfers(business_id);
create index account_transfers_source_idx on public.account_transfers(source_account_id);
create index account_transfers_destination_idx on public.account_transfers(destination_account_id);
create index account_transfers_created_by_idx on public.account_transfers(created_by);
create index cash_transits_business_id_idx on public.cash_transits(business_id);
create index cash_transits_source_idx on public.cash_transits(source_account_id);
create index cash_transits_destination_idx on public.cash_transits(destination_account_id);
create index cash_transits_created_by_idx on public.cash_transits(created_by);
create index cash_sessions_business_id_idx on public.cash_sessions(business_id);
create index cash_sessions_account_idx on public.cash_sessions(account_id);
create index cash_sessions_responsible_idx on public.cash_sessions(responsible_user_id);
create index cash_session_adjustments_business_id_idx on public.cash_session_adjustments(business_id);
create index cash_session_adjustments_created_by_idx on public.cash_session_adjustments(created_by);
create index customer_credits_business_id_idx on public.customer_credits(business_id);
create index customer_credits_customer_idx on public.customer_credits(customer_id);
create index customer_credits_order_idx on public.customer_credits(source_order_id);
create index customer_credits_refund_idx on public.customer_credits(source_refund_id);
create index customer_credit_movements_business_id_idx on public.customer_credit_movements(business_id);
create index customer_credit_movements_order_idx on public.customer_credit_movements(order_id);
create index customer_credit_movements_created_by_idx on public.customer_credit_movements(created_by);
create index refunds_business_id_idx on public.refunds(business_id);
create index refunds_customer_idx on public.refunds(customer_id);
create index refunds_payment_idx on public.refunds(payment_id);
create index refunds_order_idx on public.refunds(order_id);
create index refunds_account_idx on public.refunds(account_id);
create index refunds_authorized_by_idx on public.refunds(authorized_by);
create index refunds_created_by_idx on public.refunds(created_by);
create index payment_promises_business_id_idx on public.payment_promises(business_id);
create index payment_promises_customer_idx on public.payment_promises(customer_id);
create index payment_promises_order_idx on public.payment_promises(order_id);
create index payment_promises_created_by_idx on public.payment_promises(created_by);

alter table public.payment_methods enable row level security;
alter table public.payment_method_fees enable row level security;
alter table public.financial_accounts enable row level security;
alter table public.account_movements enable row level security;
alter table public.payments enable row level security;
alter table public.payment_fees enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_allocations enable row level security;
alter table public.recurring_expenses enable row level security;
alter table public.account_transfers enable row level security;
alter table public.cash_transits enable row level security;
alter table public.cash_sessions enable row level security;
alter table public.cash_session_adjustments enable row level security;
alter table public.customer_credits enable row level security;
alter table public.customer_credit_movements enable row level security;
alter table public.refunds enable row level security;
alter table public.payment_promises enable row level security;

create policy finance_read_payment_methods on public.payment_methods for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy finance_manage_payment_methods on public.payment_methods for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_read_payment_method_fees on public.payment_method_fees for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy finance_manage_payment_method_fees on public.payment_method_fees for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_read_accounts on public.financial_accounts for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy finance_manage_accounts on public.financial_accounts for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_read_movements on public.account_movements for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy finance_manage_movements on public.account_movements for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy payments_read on public.payments for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy payments_write on public.payments for insert to authenticated with check (private.has_business_permission(business_id,'payments.create'));
create policy payments_update on public.payments for update to authenticated using (private.has_business_permission(business_id,'payments.create')) with check (private.has_business_permission(business_id,'payments.create'));
create policy payment_fees_read on public.payment_fees for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy payment_fees_write on public.payment_fees for all to authenticated using (private.has_business_permission(business_id,'payments.create')) with check (private.has_business_permission(business_id,'payments.create'));
create policy expenses_read on public.expenses for select to authenticated using (private.has_business_permission(business_id,'expenses.view'));
create policy expenses_write on public.expenses for insert to authenticated with check (private.has_business_permission(business_id,'expenses.create'));
create policy expenses_update on public.expenses for update to authenticated using (private.has_business_permission(business_id,'expenses.create')) with check (private.has_business_permission(business_id,'expenses.create'));
create policy expense_allocations_read on public.expense_allocations for select to authenticated using (private.has_business_permission(business_id,'expenses.view'));
create policy expense_allocations_write on public.expense_allocations for all to authenticated using (private.has_business_permission(business_id,'expenses.create')) with check (private.has_business_permission(business_id,'expenses.create'));
create policy recurring_expenses_read on public.recurring_expenses for select to authenticated using (private.has_business_permission(business_id,'expenses.view'));
create policy recurring_expenses_write on public.recurring_expenses for all to authenticated using (private.has_business_permission(business_id,'expenses.create')) with check (private.has_business_permission(business_id,'expenses.create'));
create policy transfers_read on public.account_transfers for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy transfers_write on public.account_transfers for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy cash_transits_read on public.cash_transits for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy cash_transits_write on public.cash_transits for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy cash_sessions_read on public.cash_sessions for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy cash_sessions_write on public.cash_sessions for all to authenticated using (private.has_business_permission(business_id,'cash.manage')) with check (private.has_business_permission(business_id,'cash.manage'));
create policy cash_adjustments_read on public.cash_session_adjustments for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy cash_adjustments_write on public.cash_session_adjustments for all to authenticated using (private.has_business_permission(business_id,'cash.manage')) with check (private.has_business_permission(business_id,'cash.manage'));
create policy credits_read on public.customer_credits for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy credits_write on public.customer_credits for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy credit_movements_read on public.customer_credit_movements for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy credit_movements_write on public.customer_credit_movements for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy refunds_read on public.refunds for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy refunds_write on public.refunds for all to authenticated using (private.has_business_permission(business_id,'refunds.create')) with check (private.has_business_permission(business_id,'refunds.create'));
create policy payment_promises_read on public.payment_promises for select to authenticated using (private.has_business_permission(business_id,'finance.view'));
create policy payment_promises_write on public.payment_promises for all to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));

grant select, insert, update, delete on public.payment_methods, public.payment_method_fees, public.financial_accounts, public.account_movements, public.payment_fees, public.expense_allocations, public.recurring_expenses, public.account_transfers, public.cash_transits, public.cash_sessions, public.cash_session_adjustments, public.customer_credits, public.customer_credit_movements, public.refunds, public.payment_promises to authenticated;
grant select, insert, update on public.payments, public.expenses to authenticated;

insert into public.payment_methods (business_id,name,method_type)
select id,'Efectivo','cash' from public.businesses where name='Moore Print'
on conflict (business_id,name) do nothing;
insert into public.payment_methods (business_id,name,method_type)
select id,'Transferencia','transfer' from public.businesses where name='Moore Print'
on conflict (business_id,name) do nothing;
insert into public.payment_methods (business_id,name,method_type)
select id,'Mercado Pago','mercado_pago' from public.businesses where name='Moore Print'
on conflict (business_id,name) do nothing;
insert into public.payment_methods (business_id,name,method_type)
select id,'Tarjeta','card' from public.businesses where name='Moore Print'
on conflict (business_id,name) do nothing;
insert into public.payment_methods (business_id,name,method_type)
select id,'Depósito','deposit' from public.businesses where name='Moore Print'
on conflict (business_id,name) do nothing;
