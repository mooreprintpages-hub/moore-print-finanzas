create or replace function private.set_cash_session_expected_close()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_movements numeric(14,2);
  v_adjustments numeric(14,2);
begin
  if new.status = 'closed' and old.status is distinct from 'closed' then
    new.closed_at := coalesce(new.closed_at, now());

    select coalesce(sum(am.amount), 0)
      into v_movements
    from public.account_movements am
    where am.business_id = new.business_id
      and am.account_id = new.account_id
      and am.occurred_at >= new.opened_at
      and am.occurred_at <= new.closed_at;

    select coalesce(sum(csa.amount), 0)
      into v_adjustments
    from public.cash_session_adjustments csa
    where csa.business_id = new.business_id
      and csa.cash_session_id = new.id
      and csa.created_at <= new.closed_at;

    new.expected_close_amount := round(new.opening_amount + v_movements + v_adjustments, 2);
  end if;

  return new;
end;
$$;

drop trigger if exists cash_sessions_set_expected_close on public.cash_sessions;
create trigger cash_sessions_set_expected_close
before update on public.cash_sessions
for each row execute function private.set_cash_session_expected_close();
