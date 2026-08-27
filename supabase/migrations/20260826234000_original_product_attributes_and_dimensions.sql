alter table public.order_items add column if not exists width_m numeric check (width_m is null or width_m > 0);
alter table public.order_items add column if not exists height_m numeric check (height_m is null or height_m > 0);
alter table public.order_items add column if not exists custom_attributes jsonb not null default '{}'::jsonb;

insert into public.variant_attributes (business_id,name,code,active)
select b.id,v.name,v.code,true
from public.businesses b
cross join (values
 ('Grupo de edad','age_group'),
 ('Tamaño de estampado','print_size'),
 ('Capucha','hood'),
 ('Bolsa','pocket')
) as v(name,code)
on conflict (business_id,code) do nothing;

insert into public.variant_attribute_values (business_id,attribute_id,value,sort_order,active)
select a.business_id,a.id,v.value,v.sort_order,true
from public.variant_attributes a
join (values
 ('age_group','Adulto',1),('age_group','Infantil',2),
 ('print_size','Chico',1),('print_size','Grande',2),
 ('hood','Con capucha',1),('hood','Sin capucha',2),
 ('pocket','Con bolsa',1),('pocket','Sin bolsa',2)
) as v(code,value,sort_order) on v.code=a.code
on conflict (attribute_id,value) do nothing;

insert into public.products (business_id,name,description,product_type,category,active)
select b.id,'Sudadera personalizada','Sudadera configurable por talla, color, grupo de edad, capucha y bolsa.','manufactured','Sudaderas',true
from public.businesses b
where not exists (
 select 1 from public.products p where p.business_id=b.id and lower(p.name)=lower('Sudadera personalizada') and p.deleted_at is null
);
