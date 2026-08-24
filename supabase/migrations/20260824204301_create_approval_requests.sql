insert into public.permissions(code,description) values
('approvals.view','Ver solicitudes de autorización'),
('approvals.manage','Aprobar o rechazar solicitudes de autorización')
on conflict(code) do nothing;

insert into public.role_permissions(role_id,permission_id,allowed)
select r.id,p.id,true
from public.roles r
join public.businesses b on b.id=r.business_id
cross join public.permissions p
where b.name='Moore Print' and r.name='Propietario' and p.code in ('approvals.view','approvals.manage')
on conflict(role_id,permission_id) do update set allowed=true;

create table public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  request_type text not null check (request_type in (
    'discount_over_limit','large_purchase','urgent_purchase','negative_inventory',
    'delivery_with_balance','below_margin_price','other'
  )),
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  requested_by uuid not null references auth.users(id) on delete restrict,
  authorized_by uuid references auth.users(id) on delete restrict,
  reason text not null,
  entity_type text,
  entity_id uuid,
  requested_value numeric(14,2),
  requested_payload jsonb not null default '{}'::jsonb,
  decision_notes text,
  requested_at timestamptz not null default now(),
  decided_at timestamptz,
  check ((status='pending' and authorized_by is null and decided_at is null) or status<>'pending')
);

create index approval_requests_business_status_idx on public.approval_requests(business_id,status,requested_at desc);
create index approval_requests_requested_by_idx on public.approval_requests(requested_by);
create index approval_requests_authorized_by_idx on public.approval_requests(authorized_by);
create index approval_requests_entity_idx on public.approval_requests(entity_type,entity_id);

alter table public.approval_requests enable row level security;
grant select,insert,update on public.approval_requests to authenticated;

create policy approval_requests_read on public.approval_requests
for select to authenticated
using (
  private.is_business_member(business_id)
  and (requested_by=(select auth.uid()) or private.has_business_permission(business_id,'approvals.view'))
);

create policy approval_requests_insert on public.approval_requests
for insert to authenticated
with check (
  private.is_business_member(business_id)
  and requested_by=(select auth.uid())
  and status='pending'
  and authorized_by is null
  and decided_at is null
);

create policy approval_requests_update_requester on public.approval_requests
for update to authenticated
using (requested_by=(select auth.uid()) and status='pending')
with check (requested_by=(select auth.uid()) and status='cancelled' and authorized_by is null);

create policy approval_requests_update_manager on public.approval_requests
for update to authenticated
using (private.has_business_permission(business_id,'approvals.manage'))
with check (private.has_business_permission(business_id,'approvals.manage'));

create or replace function private.enforce_approval_decision()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if old.status='pending' and new.status in ('approved','rejected') then
    if new.authorized_by is null then new.authorized_by:=auth.uid(); end if;
    if new.decided_at is null then new.decided_at:=now(); end if;
  elsif old.status<>'pending' and new.status is distinct from old.status then
    raise exception 'Una solicitud ya decidida no puede cambiar de estado';
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_approval_decision() from public,anon,authenticated;

create trigger trg_enforce_approval_decision
before update on public.approval_requests
for each row execute function private.enforce_approval_decision();