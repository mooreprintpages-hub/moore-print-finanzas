alter table public.purchases
  add column if not exists source_order_id uuid references public.orders(id) on delete set null;

alter table public.purchases
  add column if not exists pickup_method text
  check (pickup_method is null or pickup_method in ('didi','bus','own','other'));

alter table public.purchases
  add column if not exists pickup_cost numeric not null default 0
  check (pickup_cost >= 0);

create index if not exists purchases_source_order_id_idx on public.purchases(source_order_id);
