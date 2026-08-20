create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.is_business_member(target_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.business_members bm
    where bm.business_id = target_business_id
      and bm.user_id = (select auth.uid())
      and bm.active = true
  );
$$;

create or replace function private.has_business_permission(target_business_id uuid, target_permission_code text)
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

create or replace function private.get_business_permission_limit(target_business_id uuid, target_limit_code text)
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

grant execute on function private.is_business_member(uuid) to authenticated;
grant execute on function private.has_business_permission(uuid, text) to authenticated;
grant execute on function private.get_business_permission_limit(uuid, text) to authenticated;

alter policy "members_read_business" on public.businesses using (private.is_business_member(id));
alter policy "members_read_memberships" on public.business_members using (user_id = (select auth.uid()) or private.is_business_member(business_id));
alter policy "members_read_roles" on public.roles using (private.is_business_member(business_id));
alter policy "members_read_role_permissions" on public.role_permissions using (exists (select 1 from public.roles r where r.id = role_id and private.is_business_member(r.business_id)));
alter policy "members_read_branches" on public.branches using (private.is_business_member(business_id));
alter policy "members_read_areas" on public.areas using (private.is_business_member(business_id));
alter policy "members_read_locations" on public.locations using (private.is_business_member(business_id));

alter policy "admins_update_business" on public.businesses
using (private.has_business_permission(id, 'users.manage'))
with check (private.has_business_permission(id, 'users.manage'));

alter policy "admins_manage_roles" on public.roles
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));

alter policy "admins_manage_memberships" on public.business_members
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));

alter policy "admins_manage_branches" on public.branches
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));

alter policy "admins_manage_areas" on public.areas
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));

alter policy "admins_manage_locations" on public.locations
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));

alter policy "admins_manage_role_permissions" on public.role_permissions
using (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')))
with check (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')));

alter policy "admins_manage_member_permissions" on public.member_permissions
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')))
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));

alter policy "admins_manage_permission_limits" on public.permission_limits
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')))
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));

alter policy "admins_read_business_profiles" on public.profiles
using (
  id = (select auth.uid())
  or exists (
    select 1
    from public.business_members target_member
    join public.business_members current_member on current_member.business_id = target_member.business_id
    where target_member.user_id = profiles.id
      and current_member.user_id = (select auth.uid())
      and current_member.active = true
      and private.has_business_permission(target_member.business_id, 'users.manage')
  )
);

drop function if exists public.get_business_permission_limit(uuid, text);
drop function if exists public.has_business_permission(uuid, text);
drop function if exists public.is_business_member(uuid);
