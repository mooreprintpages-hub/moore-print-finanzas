alter table public.businesses add column if not exists target_margin_pct numeric
  check (target_margin_pct is null or (target_margin_pct >= 0 and target_margin_pct <= 100));

alter table public.businesses add column if not exists high_demand_orders_30d integer
  check (high_demand_orders_30d is null or high_demand_orders_30d > 0);

alter table public.businesses add column if not exists high_demand_units_30d numeric
  check (high_demand_units_30d is null or high_demand_units_30d > 0);

create or replace view public.product_pricing_signals
with (security_invoker=true)
as
with sales30 as (
  select o.business_id,oi.product_id,
         count(distinct o.id)::integer as orders_30d,
         coalesce(sum(oi.quantity),0)::numeric as units_30d,
         coalesce(sum(oi.line_total),0)::numeric as revenue_30d
  from public.orders o
  join public.order_items oi on oi.order_id=o.id and oi.business_id=o.business_id
  where o.deleted_at is null and o.status <> 'cancelled' and o.created_at >= now()-interval '30 days'
  group by o.business_id,oi.product_id
), cost_alert as (
  select business_id,product_id,max(increase_pct) as max_input_increase_pct
  from public.product_price_review_alerts
  group by business_id,product_id
)
select p.business_id,p.id as product_id,p.name as product_name,p.base_price,
       coalesce(s.orders_30d,0) as orders_30d,coalesce(s.units_30d,0) as units_30d,coalesce(s.revenue_30d,0) as revenue_30d,
       pp.actual_margin_pct,b.target_margin_pct,b.high_demand_orders_30d,b.high_demand_units_30d,
       ca.max_input_increase_pct,
       case
         when ca.max_input_increase_pct is not null then 'Revisar precio: subió el costo de un insumo'
         when b.target_margin_pct is null then 'Configurar margen objetivo para generar recomendación'
         when pp.actual_margin_pct is not null and pp.actual_margin_pct < b.target_margin_pct then 'Revisar precio: margen real debajo del objetivo'
         when (b.high_demand_orders_30d is not null and coalesce(s.orders_30d,0) >= b.high_demand_orders_30d)
           or (b.high_demand_units_30d is not null and coalesce(s.units_30d,0) >= b.high_demand_units_30d)
           then 'Demanda alta: revisar capacidad, margen y posible ajuste controlado'
         else 'Mantener y observar'
       end as recommendation
from public.products p
join public.businesses b on b.id=p.business_id
left join sales30 s on s.business_id=p.business_id and s.product_id=p.id
left join public.product_profitability pp on pp.business_id=p.business_id and pp.product_id=p.id
left join cost_alert ca on ca.business_id=p.business_id and ca.product_id=p.id
where p.active=true and p.deleted_at is null;
