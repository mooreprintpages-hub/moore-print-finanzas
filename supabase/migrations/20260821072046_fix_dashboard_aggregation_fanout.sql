create or replace view public.customer_financial_summary
with (security_invoker=true) as
with order_totals as (
  select business_id, customer_id, sum(total)::numeric(14,2) order_value
  from public.orders where deleted_at is null and status <> 'cancelled'
  group by business_id, customer_id
), payment_totals as (
  select business_id, customer_id, sum(amount)::numeric(14,2) confirmed_payments
  from public.payments where status='confirmed'
  group by business_id, customer_id
), receivable_totals as (
  select business_id, customer_id, sum(balance_due)::numeric(14,2) balance_due
  from public.order_receivables group by business_id, customer_id
), bad_debt_totals as (
  select business_id, customer_id, sum(remaining_amount)::numeric(14,2) bad_debt_remaining
  from public.bad_debt_balances group by business_id, customer_id
)
select c.business_id,c.id as customer_id,c.name,
       coalesce(ot.order_value,0)::numeric(14,2) order_value,
       coalesce(pt.confirmed_payments,0)::numeric(14,2) confirmed_payments,
       coalesce(rt.balance_due,0)::numeric(14,2) balance_due,
       coalesce(bt.bad_debt_remaining,0)::numeric(14,2) bad_debt_remaining
from public.customers c
left join order_totals ot on ot.business_id=c.business_id and ot.customer_id=c.id
left join payment_totals pt on pt.business_id=c.business_id and pt.customer_id=c.id
left join receivable_totals rt on rt.business_id=c.business_id and rt.customer_id=c.id
left join bad_debt_totals bt on bt.business_id=c.business_id and bt.customer_id=c.id
where c.deleted_at is null;

create or replace view public.supplier_performance
with (security_invoker=true) as
with reviews as (
  select business_id,supplier_id,avg(delivery_rating)::numeric(5,2) delivery_rating,
         avg(accuracy_rating)::numeric(5,2) accuracy_rating,
         avg(quality_rating)::numeric(5,2) quality_rating
  from public.supplier_reviews group by business_id,supplier_id
), incidents as (
  select business_id,supplier_id,count(*) incident_count
  from public.supplier_incidents group by business_id,supplier_id
), purchases_agg as (
  select business_id,supplier_id,count(*) purchase_count,sum(total)::numeric(14,2) purchase_value
  from public.purchases where deleted_at is null and status <> 'cancelled'
  group by business_id,supplier_id
)
select s.business_id,s.id supplier_id,s.name,
       coalesce(r.delivery_rating,0)::numeric(5,2) delivery_rating,
       coalesce(r.accuracy_rating,0)::numeric(5,2) accuracy_rating,
       coalesce(r.quality_rating,0)::numeric(5,2) quality_rating,
       coalesce(i.incident_count,0) incident_count,
       coalesce(pa.purchase_count,0) purchase_count,
       coalesce(pa.purchase_value,0)::numeric(14,2) purchase_value
from public.suppliers s
left join reviews r on r.business_id=s.business_id and r.supplier_id=s.id
left join incidents i on i.business_id=s.business_id and i.supplier_id=s.id
left join purchases_agg pa on pa.business_id=s.business_id and pa.supplier_id=s.id
where s.deleted_at is null;

create or replace view public.product_profitability
with (security_invoker=true) as
with revenue as (
  select oi.business_id,oi.product_id,sum(oi.line_total)::numeric(14,2) revenue
  from public.order_items oi
  join public.orders o on o.id=oi.order_id and o.business_id=oi.business_id
  where o.deleted_at is null and o.status <> 'cancelled'
  group by oi.business_id,oi.product_id
), costs as (
  select oci.business_id,oi.product_id,sum(oci.actual_total)::numeric(14,2) actual_cost
  from public.order_cost_items oci
  join public.order_items oi on oi.id=oci.order_item_id and oi.business_id=oci.business_id
  group by oci.business_id,oi.product_id
)
select p.business_id,p.id product_id,p.name product_name,
       coalesce(r.revenue,0)::numeric(14,2) revenue,
       coalesce(c.actual_cost,0)::numeric(14,2) actual_cost,
       (coalesce(r.revenue,0)-coalesce(c.actual_cost,0))::numeric(14,2) actual_margin,
       case when coalesce(r.revenue,0)=0 then null else round(((coalesce(r.revenue,0)-coalesce(c.actual_cost,0))/r.revenue)*100,2) end actual_margin_pct
from public.products p
left join revenue r on r.business_id=p.business_id and r.product_id=p.id
left join costs c on c.business_id=p.business_id and c.product_id=p.id
where p.deleted_at is null;
