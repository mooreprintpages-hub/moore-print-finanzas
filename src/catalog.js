export async function loadCatalog(supabase) {
  if (!supabase) return { categories: [], products: [] }

  const categoriesQuery = supabase
    .from('categories')
    .select('id,name,slug,description,sort_order')
    .eq('is_active', true)
    .order('sort_order')

  const productsQuery = supabase
    .from('products')
    .select('id,category_id,name,slug,short_description,featured')
    .eq('is_active', true)
    .order('name')

  const [categoriesResult, productsResult] = await Promise.all([categoriesQuery, productsQuery])
  if (categoriesResult.error) throw categoriesResult.error
  if (productsResult.error) throw productsResult.error

  return {
    categories: categoriesResult.data ?? [],
    products: productsResult.data ?? []
  }
}
