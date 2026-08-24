create table public.variant_attributes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  code text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(business_id,code),
  unique(business_id,name)
);

create table public.variant_attribute_values (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  attribute_id uuid not null references public.variant_attributes(id) on delete cascade,
  value text not null,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(attribute_id,value)
);

create table public.product_variant_values (
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_variant_id uuid not null references public.product_variants(id) on delete cascade,
  attribute_id uuid not null references public.variant_attributes(id) on delete cascade,
  value_id uuid not null references public.variant_attribute_values(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(product_variant_id,attribute_id)
);

create index variant_attributes_business_idx on public.variant_attributes(business_id);
create index variant_attribute_values_business_idx on public.variant_attribute_values(business_id);
create index variant_attribute_values_attribute_idx on public.variant_attribute_values(attribute_id);
create index product_variant_values_business_idx on public.product_variant_values(business_id);
create index product_variant_values_attribute_idx on public.product_variant_values(attribute_id);
create index product_variant_values_value_idx on public.product_variant_values(value_id);

alter table public.variant_attributes enable row level security;
alter table public.variant_attribute_values enable row level security;
alter table public.product_variant_values enable row level security;

do $$
declare t text;
begin
  foreach t in array array['variant_attributes','variant_attribute_values','product_variant_values']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (private.is_business_member(business_id))', t || '_read', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id, ''inventory.adjust''))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id, ''inventory.adjust'')) with check (private.has_business_permission(business_id, ''inventory.adjust''))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id, ''inventory.adjust''))', t || '_delete', t);
    execute format('grant select,insert,update,delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into public.variant_attributes(business_id,name,code)
select b.id,v.name,v.code from public.businesses b
cross join (values
 ('Talla','size'),
 ('Color','color'),
 ('Marca','brand'),
 ('Modelo','model'),
 ('Calidad','quality'),
 ('Acabado','finish'),
 ('Capacidad','capacity')
) v(name,code)
where b.name='Moore Print'
on conflict (business_id,code) do nothing;