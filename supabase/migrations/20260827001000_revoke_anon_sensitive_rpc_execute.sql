revoke execute on function public.consume_inventory_reservation(uuid) from public, anon;
revoke execute on function public.create_inventory_reservation(uuid,uuid,uuid,numeric,uuid,uuid,text) from public, anon;
revoke execute on function public.pay_recurring_expense(uuid,numeric,uuid,date) from public, anon;

grant execute on function public.consume_inventory_reservation(uuid) to authenticated;
grant execute on function public.create_inventory_reservation(uuid,uuid,uuid,numeric,uuid,uuid,text) to authenticated;
grant execute on function public.pay_recurring_expense(uuid,numeric,uuid,date) to authenticated;
