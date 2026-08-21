insert into public.permissions(code,description) values
('operations.view','Ver operación y logística'),
('operations.manage','Administrar operación y logística'),
('tasks.manage','Administrar tareas y agenda'),
('promotions.manage','Administrar promociones'),
('incidents.manage','Administrar incidencias y garantías')
on conflict (code) do nothing;

insert into public.role_permissions(role_id,permission_id,allowed)
select r.id,p.id,true
from public.roles r cross join public.permissions p
where r.name='Propietario' and p.code in ('operations.view','operations.manage','tasks.manage','promotions.manage','incidents.manage')
on conflict (role_id,permission_id) do update set allowed=excluded.allowed;

create table public.delivery_points (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, reference text, one_way_distance_km numeric(10,2), estimated_minutes integer,
 usual_cost numeric(14,2) not null default 0, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.deliveries (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 order_id uuid not null references public.orders(id) on delete restrict, delivery_type text not null,
 delivery_point_id uuid references public.delivery_points(id) on delete set null,
 estimated_cost numeric(14,2) not null default 0, actual_cost numeric(14,2) not null default 0,
 charged_cost numeric(14,2) not null default 0, received_by text, delivered_by uuid references auth.users(id) on delete set null,
 delivery_code text, delivered_at timestamptz, status text not null default 'pending' check(status in ('pending','scheduled','in_transit','delivered','cancelled')),
 notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.trips (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 title text not null, status text not null default 'planned' check(status in ('planned','in_progress','completed','cancelled')),
 planned_at timestamptz, started_at timestamptz, completed_at timestamptz,
 assigned_to uuid references auth.users(id) on delete set null, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.trip_tasks (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 trip_id uuid not null references public.trips(id) on delete cascade,
 task_type text not null check(task_type in ('pickup_material','purchase','delivery','errand','other')),
 order_id uuid references public.orders(id) on delete set null, supplier_id uuid references public.suppliers(id) on delete set null,
 delivery_id uuid references public.deliveries(id) on delete set null, description text not null,
 sequence_no integer not null default 1, status text not null default 'pending' check(status in ('pending','completed','cancelled')),
 completed_at timestamptz, created_at timestamptz not null default now()
);
create table public.trip_transport_segments (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 trip_id uuid not null references public.trips(id) on delete cascade,
 mode text not null, origin text, destination text, estimated_cost numeric(14,2) not null default 0,
 actual_cost numeric(14,2) not null default 0, sequence_no integer not null default 1, notes text,
 created_at timestamptz not null default now()
);
create table public.tasks (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 title text not null, task_type text not null, assigned_to uuid references auth.users(id) on delete set null,
 due_at timestamptz, priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
 status text not null default 'pending' check(status in ('pending','in_progress','completed','cancelled')),
 customer_id uuid references public.customers(id) on delete set null, quote_id uuid references public.quotes(id) on delete set null,
 order_id uuid references public.orders(id) on delete set null, reference_type text, reference_id uuid,
 recurrence_id uuid, notes text, completed_at timestamptz, created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.task_recurrences (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 title text not null, task_type text not null, recurrence_rule text not null, assigned_to uuid references auth.users(id) on delete set null,
 priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
 active boolean not null default true, starts_at timestamptz, ends_at timestamptz, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.tasks add constraint tasks_recurrence_id_fkey foreign key(recurrence_id) references public.task_recurrences(id) on delete set null;

create table public.customer_groups (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, description text, active boolean not null default true, created_at timestamptz not null default now(), unique(business_id,name)
);
create table public.promotions (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, starts_at timestamptz not null, ends_at timestamptz not null,
 promotion_type text not null, value numeric(14,4) not null, minimum_quantity numeric(14,3), minimum_amount numeric(14,2),
 active boolean not null default true, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(ends_at>starts_at)
);
create table public.promotion_products (
 promotion_id uuid not null references public.promotions(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade,
 primary key(promotion_id,product_id)
);
create table public.promotion_customer_groups (
 promotion_id uuid not null references public.promotions(id) on delete cascade,
 customer_group_id uuid not null references public.customer_groups(id) on delete cascade,
 primary key(promotion_id,customer_group_id)
);
create table public.customer_group_members (
 customer_group_id uuid not null references public.customer_groups(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade,
 primary key(customer_group_id,customer_id)
);
create table public.order_incidents (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 order_id uuid not null references public.orders(id) on delete restrict,
 order_item_id uuid references public.order_items(id) on delete set null,
 incident_type text not null check(incident_type in ('production_error','supplier','design','damage','other')),
 resolution text check(resolution in ('replacement','refund','discount','credit','repair','no_action')),
 cost_absorbed_by text, estimated_cost numeric(14,2) not null default 0, actual_cost numeric(14,2) not null default 0,
 description text not null, status text not null default 'open' check(status in ('open','resolved','cancelled')),
 resolved_at timestamptz, created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create index deliveries_business_order_idx on public.deliveries(business_id,order_id);
create index deliveries_point_idx on public.deliveries(delivery_point_id);
create index deliveries_delivered_by_idx on public.deliveries(delivered_by);
create index trips_business_idx on public.trips(business_id);
create index trips_assigned_to_idx on public.trips(assigned_to);
create index trip_tasks_trip_idx on public.trip_tasks(trip_id);
create index trip_tasks_order_idx on public.trip_tasks(order_id);
create index trip_tasks_supplier_idx on public.trip_tasks(supplier_id);
create index trip_tasks_delivery_idx on public.trip_tasks(delivery_id);
create index trip_transport_segments_trip_idx on public.trip_transport_segments(trip_id);
create index tasks_business_due_idx on public.tasks(business_id,due_at);
create index tasks_assigned_to_idx on public.tasks(assigned_to);
create index tasks_customer_idx on public.tasks(customer_id);
create index tasks_quote_idx on public.tasks(quote_id);
create index tasks_order_idx on public.tasks(order_id);
create index tasks_recurrence_idx on public.tasks(recurrence_id);
create index tasks_created_by_idx on public.tasks(created_by);
create index task_recurrences_business_idx on public.task_recurrences(business_id);
create index task_recurrences_assigned_to_idx on public.task_recurrences(assigned_to);
create index customer_groups_business_idx on public.customer_groups(business_id);
create index customer_group_members_customer_idx on public.customer_group_members(customer_id);
create index promotions_business_period_idx on public.promotions(business_id,starts_at,ends_at);
create index promotion_products_product_idx on public.promotion_products(product_id);
create index promotion_customer_groups_group_idx on public.promotion_customer_groups(customer_group_id);
create index order_incidents_business_order_idx on public.order_incidents(business_id,order_id);
create index order_incidents_order_item_idx on public.order_incidents(order_item_id);
create index order_incidents_created_by_idx on public.order_incidents(created_by);

alter table public.delivery_points enable row level security;
alter table public.deliveries enable row level security;
alter table public.trips enable row level security;
alter table public.trip_tasks enable row level security;
alter table public.trip_transport_segments enable row level security;
alter table public.tasks enable row level security;
alter table public.task_recurrences enable row level security;
alter table public.customer_groups enable row level security;
alter table public.promotions enable row level security;
alter table public.promotion_products enable row level security;
alter table public.promotion_customer_groups enable row level security;
alter table public.customer_group_members enable row level security;
alter table public.order_incidents enable row level security;

do $$
declare t text;
begin
 foreach t in array array['delivery_points','deliveries','trips','trip_tasks','trip_transport_segments'] loop
  execute format('create policy %I on public.%I for select to authenticated using (private.has_business_permission(business_id,''operations.view'') or private.has_business_permission(business_id,''operations.manage''))',t||'_read',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id,''operations.manage''))',t||'_insert',t);
  execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id,''operations.manage'')) with check (private.has_business_permission(business_id,''operations.manage''))',t||'_update',t);
  execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id,''operations.manage''))',t||'_delete',t);
 end loop;
 foreach t in array array['tasks','task_recurrences'] loop
  execute format('create policy %I on public.%I for select to authenticated using (private.is_business_member(business_id))',t||'_read',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id,''tasks.manage''))',t||'_insert',t);
  execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id,''tasks.manage'')) with check (private.has_business_permission(business_id,''tasks.manage''))',t||'_update',t);
  execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id,''tasks.manage''))',t||'_delete',t);
 end loop;
 foreach t in array array['customer_groups','promotions'] loop
  execute format('create policy %I on public.%I for select to authenticated using (private.is_business_member(business_id))',t||'_read',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (private.has_business_permission(business_id,''promotions.manage''))',t||'_insert',t);
  execute format('create policy %I on public.%I for update to authenticated using (private.has_business_permission(business_id,''promotions.manage'')) with check (private.has_business_permission(business_id,''promotions.manage''))',t||'_update',t);
  execute format('create policy %I on public.%I for delete to authenticated using (private.has_business_permission(business_id,''promotions.manage''))',t||'_delete',t);
 end loop;
end $$;

create policy promotion_products_read on public.promotion_products for select to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.is_business_member(p.business_id)));
create policy promotion_products_write on public.promotion_products for all to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage'))) with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy promotion_customer_groups_read on public.promotion_customer_groups for select to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.is_business_member(p.business_id)));
create policy promotion_customer_groups_write on public.promotion_customer_groups for all to authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage'))) with check (exists(select 1 from public.promotions p where p.id=promotion_id and private.has_business_permission(p.business_id,'promotions.manage')));
create policy customer_group_members_read on public.customer_group_members for select to authenticated using (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.is_business_member(g.business_id)));
create policy customer_group_members_write on public.customer_group_members for all to authenticated using (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage'))) with check (exists(select 1 from public.customer_groups g where g.id=customer_group_id and private.has_business_permission(g.business_id,'promotions.manage')));
create policy order_incidents_read on public.order_incidents for select to authenticated using (private.has_business_permission(business_id,'orders.view') or private.has_business_permission(business_id,'incidents.manage'));
create policy order_incidents_insert on public.order_incidents for insert to authenticated with check (private.has_business_permission(business_id,'incidents.manage'));
create policy order_incidents_update on public.order_incidents for update to authenticated using (private.has_business_permission(business_id,'incidents.manage')) with check (private.has_business_permission(business_id,'incidents.manage'));
create policy order_incidents_delete on public.order_incidents for delete to authenticated using (private.has_business_permission(business_id,'incidents.manage'));

grant select,insert,update,delete on public.delivery_points,public.deliveries,public.trips,public.trip_tasks,public.trip_transport_segments,public.tasks,public.task_recurrences,public.customer_groups,public.promotions,public.promotion_products,public.promotion_customer_groups,public.customer_group_members,public.order_incidents to authenticated;
