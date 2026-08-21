create index account_reconciliations_reconciled_by_idx on public.account_reconciliations(reconciled_by);
create index owner_transactions_created_by_idx on public.owner_transactions(created_by);

drop policy audit_log_insert on public.audit_log;
create policy audit_log_insert on public.audit_log
for insert to authenticated
with check (private.is_business_member(business_id) and user_id = (select auth.uid()));