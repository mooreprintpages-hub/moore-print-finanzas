create or replace view public.order_profitability as
select
  o.business_id,
  o.id as order_id,
  o.total as revenue,
  (coalesce(sum(c.estimated_total),0) + coalesce(o.pickup_cost,0))::numeric(14,2) as estimated_cost,
  (coalesce(sum(c.actual_total),0) + coalesce(o.pickup_cost,0))::numeric(14,2) as actual_cost,
  (o.total - coalesce(sum(c.actual_total),0) - coalesce(o.pickup_cost,0))::numeric(14,2) as actual_margin,
  case when o.total=0 then null
       else round((o.total - coalesce(sum(c.actual_total),0) - coalesce(o.pickup_cost,0))/o.total*100,2)
  end as actual_margin_pct
from public.orders o
left join public.order_cost_items c on c.order_id=o.id
group by o.business_id,o.id,o.total,o.pickup_cost;
