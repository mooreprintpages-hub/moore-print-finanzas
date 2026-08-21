create index activity_rates_business_idx on public.activity_rates(business_id);
create index cost_template_items_business_idx on public.cost_template_items(business_id);
create index deliveries_order_idx on public.deliveries(order_id);
create index delivery_points_business_idx on public.delivery_points(business_id);
create index order_cost_items_order_idx on public.order_cost_items(order_id);
create index order_incidents_order_idx on public.order_incidents(order_id);
create index order_time_records_order_idx on public.order_time_records(order_id);
create index trip_tasks_business_idx on public.trip_tasks(business_id);
create index trip_transport_segments_business_idx on public.trip_transport_segments(business_id);

drop policy if exists promotion_products_write on public.promotion_products;
create policy promotion_products_insert on public.promotion_products for insert to authenticated with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy promotion_products_update on public.promotion_products for update to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage'))) with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy promotion_products_delete on public.promotion_products for delete to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));

drop policy if exists promotion_customer_groups_write on public.promotion_customer_groups;
create policy promotion_customer_groups_insert on public.promotion_customer_groups for insert to authenticated with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy promotion_customer_groups_update on public.promotion_customer_groups for update to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage'))) with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy promotion_customer_groups_delete on public.promotion_customer_groups for delete to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));

drop policy if exists customer_group_members_write on public.customer_group_members;
create policy customer_group_members_insert on public.customer_group_members for insert to authenticated with check (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage')));
create policy customer_group_members_update on public.customer_group_members for update to authenticated using (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage'))) with check (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage')));
create policy customer_group_members_delete on public.customer_group_members for delete to authenticated using (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage')));
