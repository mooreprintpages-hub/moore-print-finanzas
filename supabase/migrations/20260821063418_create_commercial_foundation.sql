create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id),
  folio text not null,
  status text not null default 'draft',
  valid_until date,
  channel text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references auth.users(id),
  unique (business_id, folio)
);

create table public.quote_versions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  subtotal numeric(14,2) not null default 0,
  discount numeric(14,2) not null default 0,
  tax numeric(14,2) not null default 0,
  delivery_fee numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  deposit_suggested numeric(14,2) not null default 0,
  notes text,
  sent_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (quote_id, version_number)
);

create table public.quote_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  quote_version_id uuid not null references public.quote_versions(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_variant_id uuid references public.product_variants(id),
  description text,
  quantity numeric(14,4) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  line_total numeric(14,2) generated always as (greatest((quantity * unit_price) - discount, 0)) stored,
  estimated_cost numeric(14,2) not null default 0 check (estimated_cost >= 0),
  created_at timestamptz not null default now()
);

create table public.quote_options (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  quote_version_id uuid not null references public.quote_versions(id) on delete cascade,
  name text not null,
  description text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.quote_price_reactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  quote_version_id uuid references public.quote_versions(id) on delete set null,
  reaction text not null,
  requested_price numeric(14,2),
  reason text,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id),
  source_quote_id uuid references public.quotes(id) on delete set null,
  source_quote_version_id uuid references public.quote_versions(id) on delete set null,
  folio text not null,
  status text not null default 'draft',
  priority text not null default 'normal',
  promised_at timestamptz,
  delivered_at timestamptz,
  subtotal numeric(14,2) not null default 0,
  discount numeric(14,2) not null default 0,
  tax numeric(14,2) not null default 0,
  delivery_fee numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references auth.users(id),
  unique (business_id, folio)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_variant_id uuid references public.product_variants(id),
  description text,
  quantity numeric(14,4) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  line_total numeric(14,2) generated always as (greatest((quantity * unit_price) - discount, 0)) stored,
  estimated_cost numeric(14,2) not null default 0 check (estimated_cost >= 0),
  status text not null default 'pending',
  promised_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workflow_templates (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  description text,
  version integer not null default 1 check (version > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name, version)
);

create table public.workflow_template_steps (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  workflow_template_id uuid not null references public.workflow_templates(id) on delete cascade,
  step_key text not null,
  name text not null,
  description text,
  sort_order integer not null default 0,
  estimated_minutes integer check (estimated_minutes is null or estimated_minutes >= 0),
  created_at timestamptz not null default now(),
  unique (workflow_template_id, step_key)
);

create table public.workflow_step_dependencies (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  step_id uuid not null references public.workflow_template_steps(id) on delete cascade,
  depends_on_step_id uuid not null references public.workflow_template_steps(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (step_id <> depends_on_step_id),
  unique (step_id, depends_on_step_id)
);

create table public.order_workflows (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  order_item_id uuid references public.order_items(id) on delete cascade,
  workflow_template_id uuid not null references public.workflow_templates(id),
  status text not null default 'pending' check (status in ('pending','in_progress','completed','blocked','cancelled')),
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.order_workflow_steps (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_workflow_id uuid not null references public.order_workflows(id) on delete cascade,
  template_step_id uuid references public.workflow_template_steps(id) on delete set null,
  step_key text not null,
  name text not null,
  description text,
  sort_order integer not null default 0,
  status text not null default 'pending' check (status in ('pending','in_progress','completed','blocked','cancelled')),
  assigned_to uuid references auth.users(id),
  started_at timestamptz,
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (order_workflow_id, step_key)
);

create table public.order_workflow_step_dependencies (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_workflow_step_id uuid not null references public.order_workflow_steps(id) on delete cascade,
  depends_on_order_workflow_step_id uuid not null references public.order_workflow_steps(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (order_workflow_step_id <> depends_on_order_workflow_step_id),
  unique (order_workflow_step_id, depends_on_order_workflow_step_id)
);

create table public.order_design_approvals (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_item_id uuid not null references public.order_items(id) on delete cascade,
  status text not null default 'pending',
  approval_method text,
  approved_at timestamptz,
  approved_by_user uuid references auth.users(id),
  change_rounds integer not null default 0 check (change_rounds >= 0),
  approximate_design_time integer check (approximate_design_time is null or approximate_design_time >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.permissions(code, description) values
('quotes.edit','Editar cotizaciones'),
('workflows.manage','Administrar flujos de producción')
on conflict (code) do nothing;

insert into public.role_permissions(role_id, permission_id, allowed)
select r.id, p.id, true
from public.roles r
join public.permissions p on p.code in ('quotes.edit','workflows.manage')
where r.name = 'Propietario'
on conflict (role_id, permission_id) do update set allowed = excluded.allowed;

create index quotes_business_id_idx on public.quotes(business_id);
create index quotes_customer_id_idx on public.quotes(customer_id);
create index quotes_created_by_idx on public.quotes(created_by);
create index quotes_deleted_by_idx on public.quotes(deleted_by);
create index quote_versions_business_id_idx on public.quote_versions(business_id);
create index quote_versions_quote_id_idx on public.quote_versions(quote_id);
create index quote_versions_created_by_idx on public.quote_versions(created_by);
create index quote_items_business_id_idx on public.quote_items(business_id);
create index quote_items_version_idx on public.quote_items(quote_version_id);
create index quote_items_product_idx on public.quote_items(product_id);
create index quote_items_variant_idx on public.quote_items(product_variant_id);
create index quote_options_business_id_idx on public.quote_options(business_id);
create index quote_options_version_idx on public.quote_options(quote_version_id);
create index quote_price_reactions_business_id_idx on public.quote_price_reactions(business_id);
create index quote_price_reactions_quote_idx on public.quote_price_reactions(quote_id);
create index quote_price_reactions_version_idx on public.quote_price_reactions(quote_version_id);
create index quote_price_reactions_created_by_idx on public.quote_price_reactions(created_by);
create index orders_business_id_idx on public.orders(business_id);
create index orders_customer_id_idx on public.orders(customer_id);
create index orders_source_quote_idx on public.orders(source_quote_id);
create index orders_source_quote_version_idx on public.orders(source_quote_version_id);
create index orders_created_by_idx on public.orders(created_by);
create index orders_deleted_by_idx on public.orders(deleted_by);
create index order_items_business_id_idx on public.order_items(business_id);
create index order_items_order_id_idx on public.order_items(order_id);
create index order_items_product_id_idx on public.order_items(product_id);
create index order_items_variant_id_idx on public.order_items(product_variant_id);
create index workflow_templates_business_id_idx on public.workflow_templates(business_id);
create index workflow_template_steps_business_id_idx on public.workflow_template_steps(business_id);
create index workflow_template_steps_template_id_idx on public.workflow_template_steps(workflow_template_id);
create index workflow_step_dependencies_business_id_idx on public.workflow_step_dependencies(business_id);
create index workflow_step_dependencies_step_idx on public.workflow_step_dependencies(step_id);
create index workflow_step_dependencies_depends_idx on public.workflow_step_dependencies(depends_on_step_id);
create index order_workflows_business_id_idx on public.order_workflows(business_id);
create index order_workflows_order_id_idx on public.order_workflows(order_id);
create index order_workflows_order_item_id_idx on public.order_workflows(order_item_id);
create index order_workflows_template_id_idx on public.order_workflows(workflow_template_id);
create index order_workflows_created_by_idx on public.order_workflows(created_by);
create index order_workflow_steps_business_id_idx on public.order_workflow_steps(business_id);
create index order_workflow_steps_workflow_id_idx on public.order_workflow_steps(order_workflow_id);
create index order_workflow_steps_template_step_idx on public.order_workflow_steps(template_step_id);
create index order_workflow_steps_assigned_to_idx on public.order_workflow_steps(assigned_to);
create index order_workflow_step_dependencies_business_id_idx on public.order_workflow_step_dependencies(business_id);
create index order_workflow_step_dependencies_step_idx on public.order_workflow_step_dependencies(order_workflow_step_id);
create index order_workflow_step_dependencies_depends_idx on public.order_workflow_step_dependencies(depends_on_order_workflow_step_id);
create index order_design_approvals_business_id_idx on public.order_design_approvals(business_id);
create index order_design_approvals_order_item_idx on public.order_design_approvals(order_item_id);
create index order_design_approvals_approved_by_idx on public.order_design_approvals(approved_by_user);

alter table public.quotes enable row level security;
alter table public.quote_versions enable row level security;
alter table public.quote_items enable row level security;
alter table public.quote_options enable row level security;
alter table public.quote_price_reactions enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.workflow_templates enable row level security;
alter table public.workflow_template_steps enable row level security;
alter table public.workflow_step_dependencies enable row level security;
alter table public.order_workflows enable row level security;
alter table public.order_workflow_steps enable row level security;
alter table public.order_workflow_step_dependencies enable row level security;
alter table public.order_design_approvals enable row level security;

grant select, insert, update on public.quotes, public.quote_versions, public.quote_items, public.quote_options, public.quote_price_reactions, public.orders, public.order_items, public.workflow_templates, public.workflow_template_steps, public.workflow_step_dependencies, public.order_workflows, public.order_workflow_steps, public.order_workflow_step_dependencies, public.order_design_approvals to authenticated;

create policy quotes_read on public.quotes for select to authenticated using (private.has_business_permission(business_id,'quotes.view'));
create policy quotes_insert on public.quotes for insert to authenticated with check (private.has_business_permission(business_id,'quotes.create'));
create policy quotes_update on public.quotes for update to authenticated using (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create')) with check (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create'));
create policy quote_versions_read on public.quote_versions for select to authenticated using (private.has_business_permission(business_id,'quotes.view'));
create policy quote_versions_insert on public.quote_versions for insert to authenticated with check (private.has_business_permission(business_id,'quotes.create'));
create policy quote_versions_update on public.quote_versions for update to authenticated using (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create')) with check (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create'));
create policy quote_items_read on public.quote_items for select to authenticated using (private.has_business_permission(business_id,'quotes.view'));
create policy quote_items_insert on public.quote_items for insert to authenticated with check (private.has_business_permission(business_id,'quotes.create'));
create policy quote_items_update on public.quote_items for update to authenticated using (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create')) with check (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create'));
create policy quote_options_read on public.quote_options for select to authenticated using (private.has_business_permission(business_id,'quotes.view'));
create policy quote_options_insert on public.quote_options for insert to authenticated with check (private.has_business_permission(business_id,'quotes.create'));
create policy quote_options_update on public.quote_options for update to authenticated using (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create')) with check (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create'));
create policy quote_reactions_read on public.quote_price_reactions for select to authenticated using (private.has_business_permission(business_id,'quotes.view'));
create policy quote_reactions_insert on public.quote_price_reactions for insert to authenticated with check (private.has_business_permission(business_id,'quotes.edit') or private.has_business_permission(business_id,'quotes.create'));
create policy quote_reactions_update on public.quote_price_reactions for update to authenticated using (private.has_business_permission(business_id,'quotes.edit')) with check (private.has_business_permission(business_id,'quotes.edit'));
create policy orders_read on public.orders for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy orders_insert on public.orders for insert to authenticated with check (private.has_business_permission(business_id,'orders.create'));
create policy orders_update on public.orders for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_items_read on public.order_items for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy order_items_insert on public.order_items for insert to authenticated with check (private.has_business_permission(business_id,'orders.create'));
create policy order_items_update on public.order_items for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
create policy workflow_templates_read on public.workflow_templates for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy workflow_templates_insert on public.workflow_templates for insert to authenticated with check (private.has_business_permission(business_id,'workflows.manage'));
create policy workflow_templates_update on public.workflow_templates for update to authenticated using (private.has_business_permission(business_id,'workflows.manage')) with check (private.has_business_permission(business_id,'workflows.manage'));
create policy workflow_template_steps_read on public.workflow_template_steps for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy workflow_template_steps_insert on public.workflow_template_steps for insert to authenticated with check (private.has_business_permission(business_id,'workflows.manage'));
create policy workflow_template_steps_update on public.workflow_template_steps for update to authenticated using (private.has_business_permission(business_id,'workflows.manage')) with check (private.has_business_permission(business_id,'workflows.manage'));
create policy workflow_step_dependencies_read on public.workflow_step_dependencies for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy workflow_step_dependencies_insert on public.workflow_step_dependencies for insert to authenticated with check (private.has_business_permission(business_id,'workflows.manage'));
create policy workflow_step_dependencies_update on public.workflow_step_dependencies for update to authenticated using (private.has_business_permission(business_id,'workflows.manage')) with check (private.has_business_permission(business_id,'workflows.manage'));
create policy order_workflows_read on public.order_workflows for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy order_workflows_insert on public.order_workflows for insert to authenticated with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_workflows_update on public.order_workflows for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_workflow_steps_read on public.order_workflow_steps for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy order_workflow_steps_insert on public.order_workflow_steps for insert to authenticated with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_workflow_steps_update on public.order_workflow_steps for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_workflow_step_dependencies_read on public.order_workflow_step_dependencies for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy order_workflow_step_dependencies_insert on public.order_workflow_step_dependencies for insert to authenticated with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_workflow_step_dependencies_update on public.order_workflow_step_dependencies for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_design_approvals_read on public.order_design_approvals for select to authenticated using (private.has_business_permission(business_id,'orders.view'));
create policy order_design_approvals_insert on public.order_design_approvals for insert to authenticated with check (private.has_business_permission(business_id,'orders.edit'));
create policy order_design_approvals_update on public.order_design_approvals for update to authenticated using (private.has_business_permission(business_id,'orders.edit')) with check (private.has_business_permission(business_id,'orders.edit'));
