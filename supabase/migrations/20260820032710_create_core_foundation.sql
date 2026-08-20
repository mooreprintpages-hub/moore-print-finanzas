create extension if not exists pgcrypto;

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  currency text not null default 'MXN',
  country text not null default 'MX',
  timezone text not null default 'America/Mexico_City',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  description text,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id uuid references public.roles(id) on delete set null,
  active boolean not null default true,
  joined_at timestamptz not null default now(),
  unique (business_id, user_id)
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  allowed boolean not null default true,
  primary key (role_id, permission_id)
);

create table public.member_permissions (
  member_id uuid not null references public.business_members(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  allowed boolean not null,
  primary key (member_id, permission_id)
);

create table public.permission_limits (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.business_members(id) on delete cascade,
  limit_code text not null,
  numeric_value numeric(14,2),
  created_at timestamptz not null default now(),
  unique (member_id, limit_code)
);

create index business_members_user_idx on public.business_members(user_id) where active = true;
create index business_members_business_idx on public.business_members(business_id) where active = true;

alter table public.businesses enable row level security;
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.business_members enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.member_permissions enable row level security;
alter table public.permission_limits enable row level security;

create or replace function public.is_business_member(target_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.business_members bm
    where bm.business_id = target_business_id
      and bm.user_id = auth.uid()
      and bm.active = true
  );
$$;

revoke all on function public.is_business_member(uuid) from public;
grant execute on function public.is_business_member(uuid) to authenticated;

create policy "members_read_business" on public.businesses
for select to authenticated
using (public.is_business_member(id));

create policy "users_read_own_profile" on public.profiles
for select to authenticated
using (id = auth.uid());

create policy "users_update_own_profile" on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "members_read_memberships" on public.business_members
for select to authenticated
using (user_id = auth.uid() or public.is_business_member(business_id));

create policy "members_read_roles" on public.roles
for select to authenticated
using (public.is_business_member(business_id));

create policy "authenticated_read_permission_catalog" on public.permissions
for select to authenticated
using (true);

create policy "members_read_role_permissions" on public.role_permissions
for select to authenticated
using (exists (
  select 1 from public.roles r
  where r.id = role_id and public.is_business_member(r.business_id)
));

create policy "member_reads_own_overrides" on public.member_permissions
for select to authenticated
using (exists (
  select 1 from public.business_members bm
  where bm.id = member_id and bm.user_id = auth.uid()
));

create policy "member_reads_own_limits" on public.permission_limits
for select to authenticated
using (exists (
  select 1 from public.business_members bm
  where bm.id = member_id and bm.user_id = auth.uid()
));

-- New Supabase projects no longer auto-expose public tables to the Data API.
grant usage on schema public to authenticated;
grant select on public.businesses, public.business_members, public.roles, public.permissions, public.role_permissions, public.member_permissions, public.permission_limits to authenticated;
grant select, update on public.profiles to authenticated;

insert into public.businesses (name, legal_name) values ('Moore Print', 'Moore Print');

insert into public.permissions (code, description) values
('dashboard.view','Ver dashboard'),
('orders.view','Ver pedidos'),
('orders.create','Crear pedidos'),
('orders.edit','Editar pedidos'),
('quotes.view','Ver cotizaciones'),
('quotes.create','Crear cotizaciones'),
('customers.view','Ver clientes'),
('customers.edit','Editar clientes'),
('inventory.view','Ver inventario'),
('inventory.adjust','Ajustar inventario'),
('purchases.view','Ver compras'),
('purchases.create','Crear compras'),
('purchases.approve','Autorizar compras'),
('payments.create','Registrar pagos'),
('costs.view','Ver costos'),
('margins.view','Ver márgenes'),
('expenses.view','Ver gastos'),
('expenses.create','Registrar gastos'),
('finance.view','Ver información financiera'),
('users.manage','Administrar usuarios');
