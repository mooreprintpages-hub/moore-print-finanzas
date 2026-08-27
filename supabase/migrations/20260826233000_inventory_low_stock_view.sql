create or replace view public.inventory_low_stock
with (security_invoker=true)
as
select
  m.business_id,
  m.id as material_id,
  m.name as material_name,
  m.minimum_stock,
  coalesce(sum(ia.physical_quantity),0) as physical_quantity,
  coalesce(sum(ia.reserved_quantity),0) as reserved_quantity,
  coalesce(sum(ia.available_quantity),0) as available_quantity
from public.materials m
left join public.material_variants mv on mv.material_id=m.id and mv.business_id=m.business_id and mv.active=true
left join public.inventory_availability ia on ia.material_variant_id=mv.id and ia.business_id=m.business_id
where m.active=true and m.deleted_at is null and m.minimum_stock is not null
group by m.business_id,m.id,m.name,m.minimum_stock
having coalesce(sum(ia.available_quantity),0) <= m.minimum_stock;
