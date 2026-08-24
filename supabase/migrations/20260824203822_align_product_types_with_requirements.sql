alter table public.products drop constraint if exists products_product_type_check;
update public.products set product_type='manufactured' where product_type='product';
alter table public.products alter column product_type set default 'manufactured';
alter table public.products add constraint products_product_type_check check (product_type in ('manufactured','resale','mixed','service'));