drop policy product_recipes_write on public.product_recipes;
create policy product_recipes_insert on public.product_recipes for insert to authenticated with check ((select private.has_business_permission(business_id,'inventory.adjust')));
create policy product_recipes_update on public.product_recipes for update to authenticated using ((select private.has_business_permission(business_id,'inventory.adjust'))) with check ((select private.has_business_permission(business_id,'inventory.adjust')));
create policy product_recipes_delete on public.product_recipes for delete to authenticated using ((select private.has_business_permission(business_id,'inventory.adjust')));

drop policy product_recipe_items_write on public.product_recipe_items;
create policy product_recipe_items_insert on public.product_recipe_items for insert to authenticated with check (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust'))));
create policy product_recipe_items_update on public.product_recipe_items for update to authenticated using (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust')))) with check (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust'))));
create policy product_recipe_items_delete on public.product_recipe_items for delete to authenticated using (exists (select 1 from public.product_recipes r where r.id=recipe_id and (select private.has_business_permission(r.business_id,'inventory.adjust'))));

drop policy product_prices_write on public.product_prices;
create policy product_prices_insert on public.product_prices for insert to authenticated with check ((select private.has_business_permission(business_id,'margins.view')));
create policy product_prices_update on public.product_prices for update to authenticated using ((select private.has_business_permission(business_id,'margins.view'))) with check ((select private.has_business_permission(business_id,'margins.view')));
create policy product_prices_delete on public.product_prices for delete to authenticated using ((select private.has_business_permission(business_id,'margins.view')));

drop policy material_costs_write on public.material_costs;
create policy material_costs_insert on public.material_costs for insert to authenticated with check ((select private.has_business_permission(business_id,'purchases.create')));
create policy material_costs_update on public.material_costs for update to authenticated using ((select private.has_business_permission(business_id,'purchases.create'))) with check ((select private.has_business_permission(business_id,'purchases.create')));
create policy material_costs_delete on public.material_costs for delete to authenticated using ((select private.has_business_permission(business_id,'purchases.create')));
