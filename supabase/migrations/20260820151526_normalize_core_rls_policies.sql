drop policy if exists "admins_manage_roles" on public.roles;
create policy "admins_insert_roles" on public.roles for insert to authenticated
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_update_roles" on public.roles for update to authenticated
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_delete_roles" on public.roles for delete to authenticated
using (private.has_business_permission(business_id, 'users.manage'));

drop policy if exists "admins_manage_memberships" on public.business_members;
create policy "admins_insert_memberships" on public.business_members for insert to authenticated
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_update_memberships" on public.business_members for update to authenticated
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_delete_memberships" on public.business_members for delete to authenticated
using (private.has_business_permission(business_id, 'users.manage'));

drop policy if exists "admins_manage_role_permissions" on public.role_permissions;
create policy "admins_insert_role_permissions" on public.role_permissions for insert to authenticated
with check (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')));
create policy "admins_update_role_permissions" on public.role_permissions for update to authenticated
using (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')))
with check (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')));
create policy "admins_delete_role_permissions" on public.role_permissions for delete to authenticated
using (exists (select 1 from public.roles r where r.id = role_id and private.has_business_permission(r.business_id, 'users.manage')));

drop policy if exists "admins_manage_member_permissions" on public.member_permissions;
create policy "admins_insert_member_permissions" on public.member_permissions for insert to authenticated
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));
create policy "admins_update_member_permissions" on public.member_permissions for update to authenticated
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')))
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));
create policy "admins_delete_member_permissions" on public.member_permissions for delete to authenticated
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));

drop policy if exists "admins_manage_permission_limits" on public.permission_limits;
create policy "admins_insert_permission_limits" on public.permission_limits for insert to authenticated
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));
create policy "admins_update_permission_limits" on public.permission_limits for update to authenticated
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')))
with check (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));
create policy "admins_delete_permission_limits" on public.permission_limits for delete to authenticated
using (exists (select 1 from public.business_members bm where bm.id = member_id and private.has_business_permission(bm.business_id, 'users.manage')));

drop policy if exists "admins_manage_branches" on public.branches;
create policy "admins_insert_branches" on public.branches for insert to authenticated
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_update_branches" on public.branches for update to authenticated
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_delete_branches" on public.branches for delete to authenticated
using (private.has_business_permission(business_id, 'users.manage'));

drop policy if exists "admins_manage_areas" on public.areas;
create policy "admins_insert_areas" on public.areas for insert to authenticated
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_update_areas" on public.areas for update to authenticated
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_delete_areas" on public.areas for delete to authenticated
using (private.has_business_permission(business_id, 'users.manage'));

drop policy if exists "admins_manage_locations" on public.locations;
create policy "admins_insert_locations" on public.locations for insert to authenticated
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_update_locations" on public.locations for update to authenticated
using (private.has_business_permission(business_id, 'users.manage'))
with check (private.has_business_permission(business_id, 'users.manage'));
create policy "admins_delete_locations" on public.locations for delete to authenticated
using (private.has_business_permission(business_id, 'users.manage'));

alter policy "users_read_own_profile" on public.profiles
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
drop policy if exists "admins_read_business_profiles" on public.profiles;
