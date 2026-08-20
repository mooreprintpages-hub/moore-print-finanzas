-- Core performance hardening identified by Supabase Database Advisor.

create index if not exists business_members_role_id_idx
  on public.business_members(role_id);

create index if not exists member_permissions_permission_id_idx
  on public.member_permissions(permission_id);

create index if not exists role_permissions_permission_id_idx
  on public.role_permissions(permission_id);

alter policy "users_read_own_profile" on public.profiles
using (id = (select auth.uid()));

alter policy "users_update_own_profile" on public.profiles
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

alter policy "members_read_memberships" on public.business_members
using (user_id = (select auth.uid()) or public.is_business_member(business_id));

alter policy "member_reads_own_overrides" on public.member_permissions
using (exists (
  select 1
  from public.business_members bm
  where bm.id = member_id
    and bm.user_id = (select auth.uid())
));

alter policy "member_reads_own_limits" on public.permission_limits
using (exists (
  select 1
  from public.business_members bm
  where bm.id = member_id
    and bm.user_id = (select auth.uid())
));
