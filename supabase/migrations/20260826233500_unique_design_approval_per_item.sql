do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid='public.order_design_approvals'::regclass
      and conname='order_design_approvals_order_item_unique'
  ) then
    alter table public.order_design_approvals
      add constraint order_design_approvals_order_item_unique unique(order_item_id);
  end if;
end $$;
