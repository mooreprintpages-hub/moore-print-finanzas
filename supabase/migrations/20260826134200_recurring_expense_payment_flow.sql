alter table public.expenses add column if not exists recurring_expense_id uuid references public.recurring_expenses(id) on delete set null;
create index if not exists expenses_recurring_expense_id_idx on public.expenses(recurring_expense_id);

alter table public.recurring_expenses add column if not exists last_paid_at timestamptz;
alter table public.recurring_expenses add column if not exists last_paid_amount numeric;
alter table public.recurring_expenses add column if not exists last_expense_id uuid references public.expenses(id) on delete set null;

create or replace function public.pay_recurring_expense(
  p_recurring_expense_id uuid,
  p_amount numeric default null,
  p_account_id uuid default null,
  p_paid_date date default current_date
)
returns table(expense_id uuid, next_due_date date, paid_amount numeric)
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.recurring_expenses%rowtype;
  v_amount numeric;
  v_account uuid;
  v_expense uuid;
  v_next date;
begin
  select * into r from public.recurring_expenses where id=p_recurring_expense_id for update;
  if not found then raise exception 'Gasto recurrente no encontrado'; end if;
  if not r.active then raise exception 'El gasto recurrente está inactivo'; end if;
  if not private.has_business_permission(r.business_id,'expenses.create') then raise exception 'No tienes permiso para registrar gastos'; end if;

  v_amount := coalesce(p_amount,r.expected_amount);
  if v_amount is null or v_amount <= 0 then raise exception 'Ingresa un monto válido'; end if;
  v_account := coalesce(p_account_id,r.account_id);
  if v_account is null then raise exception 'Selecciona una cuenta financiera'; end if;
  if not exists(select 1 from public.financial_accounts a where a.id=v_account and a.business_id=r.business_id and a.active) then raise exception 'La cuenta no pertenece al negocio o está inactiva'; end if;

  insert into public.expenses(business_id,category,account_id,amount,business_amount,personal_amount,expense_date,status,recurrence,notes,created_by,recurring_expense_id)
  values(r.business_id,r.category,v_account,v_amount,v_amount,0,p_paid_date,'paid',r.frequency,coalesce(r.notes,r.description),auth.uid(),r.id)
  returning id into v_expense;

  if r.next_due_date is null then
    v_next := null;
  else
    case lower(trim(r.frequency))
      when 'daily' then v_next := r.next_due_date + 1;
      when 'diario' then v_next := r.next_due_date + 1;
      when 'weekly' then v_next := r.next_due_date + 7;
      when 'semanal' then v_next := r.next_due_date + 7;
      when 'biweekly' then v_next := r.next_due_date + 14;
      when 'quincenal' then v_next := r.next_due_date + 14;
      when 'monthly' then v_next := (r.next_due_date + interval '1 month')::date;
      when 'mensual' then v_next := (r.next_due_date + interval '1 month')::date;
      when 'bimonthly' then v_next := (r.next_due_date + interval '2 months')::date;
      when 'bimestral' then v_next := (r.next_due_date + interval '2 months')::date;
      when 'quarterly' then v_next := (r.next_due_date + interval '3 months')::date;
      when 'trimestral' then v_next := (r.next_due_date + interval '3 months')::date;
      when 'semiannual' then v_next := (r.next_due_date + interval '6 months')::date;
      when 'semestral' then v_next := (r.next_due_date + interval '6 months')::date;
      when 'yearly' then v_next := (r.next_due_date + interval '1 year')::date;
      when 'annual' then v_next := (r.next_due_date + interval '1 year')::date;
      when 'anual' then v_next := (r.next_due_date + interval '1 year')::date;
      else raise exception 'Frecuencia no compatible: %',r.frequency;
    end case;
  end if;

  update public.recurring_expenses
    set next_due_date=v_next,last_paid_at=now(),last_paid_amount=v_amount,last_expense_id=v_expense,account_id=v_account,updated_at=now()
  where id=r.id;

  return query select v_expense,v_next,v_amount;
end;
$$;

revoke all on function public.pay_recurring_expense(uuid,numeric,uuid,date) from public;
grant execute on function public.pay_recurring_expense(uuid,numeric,uuid,date) to authenticated;
