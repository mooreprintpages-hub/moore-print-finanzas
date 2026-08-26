alter table public.material_costs
  drop constraint if exists material_costs_source_check;

alter table public.material_costs
  add constraint material_costs_source_check
  check (source in ('manual','purchase','purchase_receipt','adjustment'));
