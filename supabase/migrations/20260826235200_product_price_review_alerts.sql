create or replace view public.supplier_price_increase_alerts
with (security_invoker=true)
as
with ranked as (
  select sph.business_id,sph.supplier_material_id,sph.unit_price,sph.effective_at,
         row_number() over(partition by sph.supplier_material_id order by sph.effective_at desc,sph.created_at desc) as rn
  from public.supplier_price_history sph
), pairs as (
  select a.business_id,a.supplier_material_id,a.unit_price as latest_price,b.unit_price as previous_price,a.effective_at
  from ranked a
  join ranked b on b.supplier_material_id=a.supplier_material_id and b.rn=2
  where a.rn=1 and a.unit_price>b.unit_price and b.unit_price>0
)
select p.business_id,sm.id as supplier_material_id,sm.material_id,m.name as material_name,
       sm.supplier_id,s.name as supplier_name,p.previous_price,p.latest_price,
       round(((p.latest_price-p.previous_price)/p.previous_price)*100,2) as increase_pct,p.effective_at
from pairs p
join public.supplier_materials sm on sm.id=p.supplier_material_id
join public.materials m on m.id=sm.material_id
join public.suppliers s on s.id=sm.supplier_id
where sm.active=true and m.active=true and s.active=true;

create or replace view public.product_price_review_alerts
with (security_invoker=true)
as
select distinct a.business_id,
       coalesce(r.product_id,pv.product_id) as product_id,
       pr.name as product_name,
       pr.base_price,
       a.material_id,a.material_name,a.supplier_name,a.previous_price,a.latest_price,a.increase_pct,a.effective_at,
       pp.actual_margin_pct
from public.supplier_price_increase_alerts a
join public.product_recipe_items ri on ri.material_id=a.material_id
join public.product_recipes r on r.id=ri.recipe_id and r.business_id=a.business_id and r.active=true
left join public.product_variants pv on pv.id=r.variant_id
join public.products pr on pr.id=coalesce(r.product_id,pv.product_id) and pr.active=true and pr.deleted_at is null
left join public.product_profitability pp on pp.business_id=a.business_id and pp.product_id=pr.id;
