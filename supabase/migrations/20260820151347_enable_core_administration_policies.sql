create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create policy "admins_update_business" on public.businesses
for update to authenticated
using (public.has_business_permission(id, 'users.manage'))
with check (public.has_business_permission(id, 'users.manage'));

create policy "admins_manage_roles" on public.roles
for all to authenticated
using (public.has_business_permission(business_id, 'users.manage'))
with check (public.has_business_permission(business_id, 'users.manage'));

create policy "admins_manage_memberships" on public.business_members
for all to authenticated
using (public.has_business_permission(business_id, 'users.manage'))
with check (public.has_business_permission(business_id, 'users.manage'));

create policy "admins_manage_role_permissions" on public.role_permissions
for all to authenticated
using (exists (
  select 1 from public.roles r
  where r.id = role_id
    and public.has_business_permission(r.business_id, 'users.manage')
))
with check (exists (
  select 1 from public.roles r
  where r.id = role_id
    and public.has_business_permission(r.business_id, 'users.manage')
));

create policy "admins_manage_member_permissions" on public.member_permissions
for all to authenticated
using (exists (
  select 1 from public.business_members bm
  where bm.id = member_id
    and public.has_business_permission(bm.business_id, 'users.manage')
))
with check (exists (
  select 1 from public.business_members bm
  where bm.id = member_id
    and public.has_business_permission(bm.business_id, 'users.manage')
));

create policy "admins_manage_permission_limits" on public.permission_limits
for all to authenticated
using (exists (
  select 1 from public.business_members bm
  where bm.id = member_id
    and public.has_business_permission(bm.business_id, 'users.manage')
))
with check (exists (
  select 1 from public.business_members bm
  where bm.id = member_id
    and public.has_business_permission(bm.business_id, 'users.manage')
));

create policy "admins_read_business_profiles" on public.profiles
for select to authenticated
using (
  id = (select auth.uid())
  or exists (
    select 1
    from public.business_members target_member
    join public.business_members current_member
      on current_member.business_id = target_member.business_id
    where target_member.user_id = profiles.id
      and current_member.user_id = (select auth.uid())
      and current_member.active = true
      and public.has_business_permission(target_member.business_id, 'users.manage')
  )
);

grant insert, update, delete on public.roles, public.business_members, public.role_permissions, public.member_permissions, public.permission_limits to authenticated;
grant update on public.businesses to authenticated;
