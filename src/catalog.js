export async function loadCatalog(supabase) {
  if (!supabase) return { categories: [], products: [] }
  const [categoriesResult, productsResult, imagesResult] = await Promise.all([
    supabase.from('categories').select('id,name,slug,description,sort_order').eq('is_active',true).order('sort_order'),
    supabase.from('products').select('id,category_id,name,slug,short_description,pricing_mode,base_price,unit_label,is_featured').eq('is_active',true).order('name'),
    supabase.from('product_images').select('product_id,image_url,alt_text,is_primary,sort_order').order('sort_order')
  ])
  if (categoriesResult.error) throw categoriesResult.error
  if (productsResult.error) throw productsResult.error
  if (imagesResult.error) throw imagesResult.error
  const imageByProduct={}
  for(const img of imagesResult.data??[]){if(!imageByProduct[img.product_id]||img.is_primary) imageByProduct[img.product_id]=img}
  const products=(productsResult.data??[]).map(p=>({...p,image:imageByProduct[p.id]||null}))
  return { categories: categoriesResult.data ?? [], products }
}

export async function loadPriceTiers(supabase,productId){
  if(!supabase||!productId) return []
  const {data,error}=await supabase.from('product_price_tiers').select('min_quantity,max_quantity,unit_price,label').eq('product_id',productId).order('min_quantity')
  if(error) throw error
  return data ?? []
}

export function quoteForQuantity(product,tiers,quantity){
  const qty=Math.max(1,Number(quantity)||1)
  const tier=tiers.find(t=>qty>=t.min_quantity&&(t.max_quantity==null||qty<=t.max_quantity))
  const unitPrice=tier?.unit_price ?? product?.base_price
  if(unitPrice==null) return null
  return {quantity:qty,unitPrice:Number(unitPrice),total:Number(unitPrice)*qty,label:tier?.label||null}
}
