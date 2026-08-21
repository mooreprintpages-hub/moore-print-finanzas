create index cash_session_adjustments_session_idx on public.cash_session_adjustments(cash_session_id);
create index customer_credit_movements_credit_idx on public.customer_credit_movements(customer_credit_id);
create index payment_method_fees_business_id_idx on public.payment_method_fees(business_id);

drop policy if exists finance_manage_payment_methods on public.payment_methods;
create policy finance_insert_payment_methods on public.payment_methods for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_update_payment_methods on public.payment_methods for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_delete_payment_methods on public.payment_methods for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists finance_manage_payment_method_fees on public.payment_method_fees;
create policy finance_insert_payment_method_fees on public.payment_method_fees for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_update_payment_method_fees on public.payment_method_fees for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_delete_payment_method_fees on public.payment_method_fees for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists finance_manage_accounts on public.financial_accounts;
create policy finance_insert_accounts on public.financial_accounts for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_update_accounts on public.financial_accounts for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_delete_accounts on public.financial_accounts for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists finance_manage_movements on public.account_movements;
create policy finance_insert_movements on public.account_movements for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_update_movements on public.account_movements for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy finance_delete_movements on public.account_movements for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists payment_fees_write on public.payment_fees;
create policy payment_fees_insert on public.payment_fees for insert to authenticated with check (private.has_business_permission(business_id,'payments.create'));
create policy payment_fees_update on public.payment_fees for update to authenticated using (private.has_business_permission(business_id,'payments.create')) with check (private.has_business_permission(business_id,'payments.create'));
create policy payment_fees_delete on public.payment_fees for delete to authenticated using (private.has_business_permission(business_id,'payments.create'));

drop policy if exists expense_allocations_write on public.expense_allocations;
create policy expense_allocations_insert on public.expense_allocations for insert to authenticated with check (private.has_business_permission(business_id,'expenses.create'));
create policy expense_allocations_update on public.expense_allocations for update to authenticated using (private.has_business_permission(business_id,'expenses.create')) with check (private.has_business_permission(business_id,'expenses.create'));
create policy expense_allocations_delete on public.expense_allocations for delete to authenticated using (private.has_business_permission(business_id,'expenses.create'));

drop policy if exists recurring_expenses_write on public.recurring_expenses;
create policy recurring_expenses_insert on public.recurring_expenses for insert to authenticated with check (private.has_business_permission(business_id,'expenses.create'));
create policy recurring_expenses_update on public.recurring_expenses for update to authenticated using (private.has_business_permission(business_id,'expenses.create')) with check (private.has_business_permission(business_id,'expenses.create'));
create policy recurring_expenses_delete on public.recurring_expenses for delete to authenticated using (private.has_business_permission(business_id,'expenses.create'));

drop policy if exists transfers_write on public.account_transfers;
create policy transfers_insert on public.account_transfers for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy transfers_update on public.account_transfers for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy transfers_delete on public.account_transfers for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists cash_transits_write on public.cash_transits;
create policy cash_transits_insert on public.cash_transits for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy cash_transits_update on public.cash_transits for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy cash_transits_delete on public.cash_transits for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists cash_sessions_write on public.cash_sessions;
create policy cash_sessions_insert on public.cash_sessions for insert to authenticated with check (private.has_business_permission(business_id,'cash.manage'));
create policy cash_sessions_update on public.cash_sessions for update to authenticated using (private.has_business_permission(business_id,'cash.manage')) with check (private.has_business_permission(business_id,'cash.manage'));
create policy cash_sessions_delete on public.cash_sessions for delete to authenticated using (private.has_business_permission(business_id,'cash.manage'));

drop policy if exists cash_adjustments_write on public.cash_session_adjustments;
create policy cash_adjustments_insert on public.cash_session_adjustments for insert to authenticated with check (private.has_business_permission(business_id,'cash.manage'));
create policy cash_adjustments_update on public.cash_session_adjustments for update to authenticated using (private.has_business_permission(business_id,'cash.manage')) with check (private.has_business_permission(business_id,'cash.manage'));
create policy cash_adjustments_delete on public.cash_session_adjustments for delete to authenticated using (private.has_business_permission(business_id,'cash.manage'));

drop policy if exists credits_write on public.customer_credits;
create policy credits_insert on public.customer_credits for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy credits_update on public.customer_credits for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy credits_delete on public.customer_credits for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists credit_movements_write on public.customer_credit_movements;
create policy credit_movements_insert on public.customer_credit_movements for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy credit_movements_update on public.customer_credit_movements for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy credit_movements_delete on public.customer_credit_movements for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));

drop policy if exists refunds_write on public.refunds;
create policy refunds_insert on public.refunds for insert to authenticated with check (private.has_business_permission(business_id,'refunds.create'));
create policy refunds_update on public.refunds for update to authenticated using (private.has_business_permission(business_id,'refunds.create')) with check (private.has_business_permission(business_id,'refunds.create'));
create policy refunds_delete on public.refunds for delete to authenticated using (private.has_business_permission(business_id,'refunds.create'));

drop policy if exists payment_promises_write on public.payment_promises;
create policy payment_promises_insert on public.payment_promises for insert to authenticated with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_promises_update on public.payment_promises for update to authenticated using (private.has_business_permission(business_id,'finance.manage')) with check (private.has_business_permission(business_id,'finance.manage'));
create policy payment_promises_delete on public.payment_promises for delete to authenticated using (private.has_business_permission(business_id,'finance.manage'));
