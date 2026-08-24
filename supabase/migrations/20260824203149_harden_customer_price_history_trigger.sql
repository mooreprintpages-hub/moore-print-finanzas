drop trigger if exists trg_customer_price_history on public.customer_price_agreements;
drop function if exists public.capture_customer_price_history();

create or replace function private.capture_customer_price_history()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if tg_op='INSERT' or new.special_price is distinct from old.special_price then
    insert into public.customer_price_history(business_id,agreement_id,special_price,effective_at)
    values(new.business_id,new.id,new.special_price,now());
  end if;
  return new;
end;
$$;
revoke all on function private.capture_customer_price_history() from public, anon, authenticated;

create trigger trg_customer_price_history
after insert or update of special_price on public.customer_price_agreements
for each row execute function private.capture_customer_price_history();