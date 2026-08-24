create table public.customer_phones (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  label text,
  is_primary boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (customer_id, phone)
);

create table public.customer_contacts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.customer_contact_roles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  contact_id uuid not null references public.customer_contacts(id) on delete cascade,
  role text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (contact_id, role)
);

create table public.customer_tax_profiles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  tax_id text,
  legal_name text,
  fiscal_regime text,
  postal_code text,
  fiscal_address text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.customer_tags (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.customer_tag_assignments (
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  tag_id uuid not null references public.customer_tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (customer_id, tag_id)
);

create table public.customer_rules (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  min_deposit_percent numeric(5,2),
  credit_limit numeric(14,2),
  exposure_limit numeric(14,2),
  require_full_payment boolean not null default false,
  block_credit boolean not null default false,
  blocked boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(customer_id),
  check (min_deposit_percent is null or (min_deposit_percent >= 0 and min_deposit_percent <= 100)),
  check (credit_limit is null or credit_limit >= 0),
  check (exposure_limit is null or exposure_limit >= 0)
);

create table public.customer_price_agreements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  product_variant_id uuid references public.product_variants(id) on delete cascade,
  special_price numeric(14,2) not null check (special_price >= 0),
  review_date date,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.customer_price_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  agreement_id uuid not null references public.customer_price_agreements(id) on delete cascade,
  special_price numeric(14,2) not null check (special_price >= 0),
  effective_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create index customer_phones_business_idx on public.customer_phones(business_id);
create index customer_phones_customer_idx on public.customer_phones(customer_id);
create index customer_contacts_business_idx on public.customer_contacts(business_id);
create index customer_contacts_customer_idx on public.customer_contacts(customer_id);
create index customer_contact_roles_business_idx on public.customer_contact_roles(business_id);
create index customer_contact_roles_contact_idx on public.customer_contact_roles(contact_id);
create index customer_tax_profiles_business_idx on public.customer_tax_profiles(business_id);
create index customer_tax_profiles_customer_idx on public.customer_tax_profiles(customer_id);
create index customer_tags_business_idx on public.customer_tags(business_id);
create index customer_tag_assignments_business_idx on public.customer_tag_assignments(business_id);
create index customer_tag_assignments_tag_idx on public.customer_tag_assignments(tag_id);
create index customer_rules_business_idx on public.customer_rules(business_id);
create index customer_price_agreements_business_idx on public.customer_price_agreements(business_id);
create index customer_price_agreements_customer_idx on public.customer_price_agreements(customer_id);
create index customer_price_agreements_product_idx on public.customer_price_agreements(product_id);
create index customer_price_agreements_variant_idx on public.customer_price_agreements(product_variant_id);
create index customer_price_history_business_idx on public.customer_price_history(business_id);
create index customer_price_history_agreement_idx on public.customer_price_history(agreement_id);

alter table public.customer_phones enable row level security;
alter table public.customer_contacts enable row level security;
alter table public.customer_contact_roles enable row level security;
alter table public.customer_tax_profiles enable row level security;
alter table public.customer_tags enable row level security;
alter table public.customer_tag_assignments enable row level security;
alter table public.customer_rules enable row level security;
alter table public.customer_price_agreements enable row level security;
alter table public.customer_price_history enable row level security;

do $$
declare t text;
begin
  foreach t in array array['customer_phones','customer_contacts','customer_contact_roles','customer_tax_profiles','customer_tags','customer_tag_assignments','customer_rules','customer_price_agreements','customer_price_history']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (private.has_business_permission(business_id, ''customers.view''))', t || '_read', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id, ''customers.edit''))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id, ''customers.edit'')) with check (private.has_business_permission(business_id, ''customers.edit''))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id, ''customers.edit''))', t || '_delete', t);
    execute format('grant select,insert,update,delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into public.customer_tags (business_id,name)
select b.id, v.name
from public.businesses b
cross join (values ('Frecuente'),('Mayoreo'),('Problemático'),('Crédito'),('VIP'),('Nuevo')) v(name)
where b.name='Moore Print'
on conflict (business_id,name) do nothing;

create or replace function public.capture_customer_price_history()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op='INSERT' or new.special_price is distinct from old.special_price then
    insert into public.customer_price_history(business_id,agreement_id,special_price,effective_at)
    values(new.business_id,new.id,new.special_price,now());
  end if;
  return new;
end;
$$;
revoke all on function public.capture_customer_price_history() from public;

create trigger trg_customer_price_history
after insert or update of special_price on public.customer_price_agreements
for each row execute function public.capture_customer_price_history();