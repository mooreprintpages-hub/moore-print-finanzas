alter table public.customers add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.suppliers add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.products add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.materials add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.purchases add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.deliveries add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.tasks add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.promotions add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;
alter table public.payment_plans add column if not exists deleted_at timestamptz, add column if not exists deleted_by uuid references auth.users(id) on delete set null;

create index if not exists customers_deleted_by_idx on public.customers(deleted_by);
create index if not exists suppliers_deleted_by_idx on public.suppliers(deleted_by);
create index if not exists products_deleted_by_idx on public.products(deleted_by);
create index if not exists materials_deleted_by_idx on public.materials(deleted_by);
create index if not exists purchases_deleted_by_idx on public.purchases(deleted_by);
create index if not exists deliveries_deleted_by_idx on public.deliveries(deleted_by);
create index if not exists tasks_deleted_by_idx on public.tasks(deleted_by);
create index if not exists promotions_deleted_by_idx on public.promotions(deleted_by);
create index if not exists payment_plans_deleted_by_idx on public.payment_plans(deleted_by);

create or replace view public.dashboard_financial_summary
with (security_invoker=true) as
select b.id as business_id,
       coalesce((select sum(o.total) from public.orders o where o.business_id=b.id and o.deleted_at is null and o.status <> 'cancelled'),0)::numeric(14,2) as order_value,
       coalesce((select sum(p.amount) from public.payments p where p.business_id=b.id and p.status='confirmed'),0)::numeric(14,2) as confirmed_payments,
       coalesce((select sum(e.business_amount) from public.expenses e where e.business_id=b.id and e.status='paid'),0)::numeric(14,2) as business_expenses,
       coalesce((select sum(r.balance_due) from public.order_receivables r where r.business_id=b.id),0)::numeric(14,2) as accounts_receivable,
       coalesce((select sum(fab.current_balance) from public.financial_account_balances fab where fab.business_id=b.id),0)::numeric(14,2) as cash_position
from public.businesses b;

create or replace view public.customer_financial_summary
with (security_invoker=true) as
select c.business_id,c.id as customer_id,c.name,
       coalesce(sum(distinct o.total) filter (where o.id is not null and o.deleted_at is null and o.status <> 'cancelled'),0)::numeric(14,2) as order_value,
       coalesce((select sum(p.amount) from public.payments p where p.customer_id=c.id and p.business_id=c.business_id and p.status='confirmed'),0)::numeric(14,2) as confirmed_payments,
       coalesce((select sum(r.balance_due) from public.order_receivables r where r.customer_id=c.id and r.business_id=c.business_id),0)::numeric(14,2) as balance_due,
       coalesce((select sum(cb.remaining_amount) from public.bad_debt_balances cb where cb.customer_id=c.id and cb.business_id=c.business_id),0)::numeric(14,2) as bad_debt_remaining
from public.customers c
left join public.orders o on o.customer_id=c.id and o.business_id=c.business_id
where c.deleted_at is null
group by c.business_id,c.id,c.name;

create or replace view public.supplier_performance
with (security_invoker=true) as
select s.business_id,s.id as supplier_id,s.name,
       coalesce(avg(sr.delivery_rating),0)::numeric(5,2) as delivery_rating,
       coalesce(avg(sr.accuracy_rating),0)::numeric(5,2) as accuracy_rating,
       coalesce(avg(sr.quality_rating),0)::numeric(5,2) as quality_rating,
       count(distinct si.id) as incident_count,
       count(distinct p.id) as purchase_count,
       coalesce(sum(distinct p.total) filter (where p.id is not null and p.status <> 'cancelled'),0)::numeric(14,2) as purchase_value
from public.suppliers s
left join public.supplier_reviews sr on sr.supplier_id=s.id and sr.business_id=s.business_id
left join public.supplier_incidents si on si.supplier_id=s.id and si.business_id=s.business_id
left join public.purchases p on p.supplier_id=s.id and p.business_id=s.business_id and p.deleted_at is null
where s.deleted_at is null
group by s.business_id,s.id,s.name;

create or replace view public.product_profitability
with (security_invoker=true) as
select oi.business_id,oi.product_id,p.name as product_name,
       coalesce(sum(oi.line_total),0)::numeric(14,2) as revenue,
       coalesce(sum(oc.actual_total),0)::numeric(14,2) as actual_cost,
       (coalesce(sum(oi.line_total),0)-coalesce(sum(oc.actual_total),0))::numeric(14,2) as actual_margin,
       case when coalesce(sum(oi.line_total),0)=0 then null else round(((coalesce(sum(oi.line_total),0)-coalesce(sum(oc.actual_total),0))/sum(oi.line_total))*100,2) end as actual_margin_pct
from public.order_items oi
join public.products p on p.id=oi.product_id and p.business_id=oi.business_id
left join public.order_cost_items oc on oc.order_item_id=oi.id and oc.business_id=oi.business_id
where p.deleted_at is null
group by oi.business_id,oi.product_id,p.name;

create or replace view public.cash_position
with (security_invoker=true) as
select fa.business_id,fa.id as account_id,fa.name,fa.account_type,fa.currency,fab.current_balance
from public.financial_accounts fa
join public.financial_account_balances fab on fab.account_id=fa.id and fab.business_id=fa.business_id
where fa.active=true;

grant select on public.dashboard_financial_summary, public.customer_financial_summary, public.supplier_performance, public.product_profitability, public.cash_position to authenticated;
