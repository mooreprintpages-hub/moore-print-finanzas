create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category text not null,
  period_start date not null,
  period_end date not null,
  amount numeric(14,2) not null check(amount>=0),
  notes text,
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(period_end>=period_start),
  unique(business_id,category,period_start,period_end)
);
create index budgets_business_period_idx on public.budgets(business_id,period_start,period_end);
alter table public.budgets enable row level security;
grant select,insert,update,delete on public.budgets to authenticated;
create policy budgets_read on public.budgets for select to authenticated using(private.has_business_permission(business_id,'finance.view'));
create policy budgets_insert on public.budgets for insert to authenticated with check(private.has_business_permission(business_id,'finance.manage'));
create policy budgets_update on public.budgets for update to authenticated using(private.has_business_permission(business_id,'finance.manage')) with check(private.has_business_permission(business_id,'finance.manage'));
create policy budgets_delete on public.budgets for delete to authenticated using(private.has_business_permission(business_id,'finance.manage'));

create or replace view public.budget_status
with (security_invoker=true)
as
select b.id,b.business_id,b.category,b.period_start,b.period_end,b.amount as budget_amount,
       coalesce(sum(e.business_amount) filter(where e.status='paid'),0)::numeric(14,2) as spent_amount,
       (b.amount-coalesce(sum(e.business_amount) filter(where e.status='paid'),0))::numeric(14,2) as remaining_amount,
       case when b.amount=0 then null else round((coalesce(sum(e.business_amount) filter(where e.status='paid'),0)/b.amount)*100,2) end as used_percent,
       b.active
from public.budgets b
left join public.expenses e on e.business_id=b.business_id and e.category=b.category and e.expense_date between b.period_start and b.period_end
group by b.id,b.business_id,b.category,b.period_start,b.period_end,b.amount,b.active;
grant select on public.budget_status to authenticated;