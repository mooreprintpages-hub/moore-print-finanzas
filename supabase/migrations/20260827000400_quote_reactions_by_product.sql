alter table public.quote_price_reactions
  add column if not exists product_id uuid references public.products(id) on delete set null;

create index if not exists quote_price_reactions_product_id_idx
  on public.quote_price_reactions(product_id);

create or replace view public.product_price_reaction_summary
with (security_invoker=true)
as
select qpr.business_id,qpr.product_id,p.name as product_name,
       count(*) filter (where qpr.reaction='accepted')::integer as accepted_count,
       count(*) filter (where qpr.reaction='uncomfortable')::integer as uncomfortable_count,
       count(*) filter (where qpr.reaction='negotiate')::integer as negotiate_count,
       count(*) filter (where qpr.reaction='rejected')::integer as rejected_count,
       count(*)::integer as total_reactions,
       case when count(*)>0
         then round((count(*) filter (where qpr.reaction='accepted'))::numeric/count(*)*100,2)
         else null end as acceptance_pct
from public.quote_price_reactions qpr
join public.products p on p.id=qpr.product_id
where qpr.product_id is not null
group by qpr.business_id,qpr.product_id,p.name;
