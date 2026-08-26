create index if not exists budgets_created_by_idx
  on public.budgets(created_by);

drop policy if exists approval_requests_update_manager on public.approval_requests;
drop policy if exists approval_requests_update_requester on public.approval_requests;

create policy approval_requests_update
on public.approval_requests
for update
to authenticated
using (
  private.has_business_permission(business_id, 'approvals.manage')
  or (
    requested_by = (select auth.uid())
    and status = 'pending'
  )
)
with check (
  private.has_business_permission(business_id, 'approvals.manage')
  or (
    requested_by = (select auth.uid())
    and status = 'cancelled'
    and authorized_by is null
  )
);
