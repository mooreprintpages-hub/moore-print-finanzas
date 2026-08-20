alter table public.businesses add column if not exists logo_url text;
alter table public.profiles add column if not exists avatar text;

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  address text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

create table if not exists public.areas (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (branch_id, name)
);

create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  area_id uuid references public.areas(id) on delete set null,
  parent_location_id uuid references public.locations(id) on delete set null,
  name text not null,
  location_type text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists branches_business_id_idx on public.branches(business_id);
create index if not exists areas_business_id_idx on public.areas(business_id);
create index if not exists areas_branch_id_idx on public.areas(branch_id);
create index if not exists locations_business_id_idx on public.locations(business_id);
create index if not exists locations_branch_id_idx on public.locations(branch_id);
create index if not exists locations_area_id_idx on public.locations(area_id);
create index if not exists locations_parent_location_id_idx on public.locations(parent_location_id);

alter table public.branches enable row level security;
alter table public.areas enable row level security;
alter table public.locations enable row level security;

create or replace function public.has_business_permission(target_business_id uuid, target_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select coalesce(mp.allowed, rp.allowed, false)
    from public.business_members bm
    join public.permissions p on p.code = target_permission_code
    left join public.member_permissions mp on mp.member_id = bm.id and mp.permission_id = p.id
    left join public.role_permissions rp on rp.role_id = bm.role_id and rp.permission_id = p.id
    where bm.business_id = target_business_id
      and bm.user_id = (select auth.uid())
      and bm.active = true
    limit 1
  ), false);
$$;

revoke all on function public.has_business_permission(uuid, text) from public, anon;
grant execute on function public.has_business_permission(uuid, text) to authenticated;

create or replace function public.get_business_permission_limit(target_business_id uuid, target_limit_code text)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select pl.numeric_value
  from public.business_members bm
  join public.permission_limits pl on pl.member_id = bm.id
  where bm.business_id = target_business_id
    and bm.user_id = (select auth.uid())
    and bm.active = true
    and pl.limit_code = target_limit_code
  limit 1;
$$;

revoke all on function public.get_business_permission_limit(uuid, text) from public, anon;
grant execute on function public.get_business_permission_limit(uuid, text) to authenticated;

insert into public.roles (business_id, name, description, is_system)
select b.id, 'Propietario', 'Acceso total al negocio', true
from public.businesses b
where b.name = 'Moore Print'
on conflict (business_id, name) do update
set description = excluded.description, is_system = true;

insert into public.role_permissions (role_id, permission_id, allowed)
select r.id, p.id, true
from public.roles r
join public.businesses b on b.id = r.business_id
cross join public.permissions p
where b.name = 'Moore Print' and r.name = 'Propietario'
on conflict (role_id, permission_id) do update set allowed = excluded.allowed;

create policy "members_read_branches" on public.branches for select to authenticated
using (public.is_business_member(business_id));
create policy "admins_manage_branches" on public.branches for all to authenticated
using (public.has_business_permission(business_id, 'users.manage'))
with check (public.has_business_permission(business_id, 'users.manage'));

create policy "members_read_areas" on public.areas for select to authenticated
using (public.is_business_member(business_id));
create policy "admins_manage_areas" on public.areas for all to authenticated
using (public.has_business_permission(business_id, 'users.manage'))
with check (public.has_business_permission(business_id, 'users.manage'));

create policy "members_read_locations" on public.locations for select to authenticated
using (public.is_business_member(business_id));
create policy "admins_manage_locations" on public.locations for all to authenticated
using (public.has_business_permission(business_id, 'users.manage'))
with check (public.has_business_permission(business_id, 'users.manage'));

grant select, insert, update, delete on public.branches, public.areas, public.locations to authenticated;
