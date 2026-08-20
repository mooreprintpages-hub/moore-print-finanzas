revoke all on function public.is_business_member(uuid) from public, anon, authenticated;
-- Policies may call this function internally; direct Data API/RPC execution is intentionally disabled.
