import { FormEvent, useEffect, useMemo, useState } from 'react'
import { Boxes, ChevronDown, History, Layers3, Plus, Search, X } from 'lucide-react'
import { supabase } from '../lib/supabase'

type Availability = { business_id:string; material_variant_id:string; location_id:string|null; physical_quantity:number|string|null; reserved_quantity:number|string|null; available_quantity:number|string|null }
type MaterialVariant = { id:string; name:string; sku:string|null; material_id:string; materials:{ name:string; unit:string; base_unit:string|null }|null }
type Location = { id:string; name:string }
type Lot = { id:string; material_variant_id:string; lot_number:string|null; quantity_initial:number|string; quantity_remaining:number|string; unit_cost:number|string; received_at:string; material_variants:{name:string; materials:{name:string}|null}|null }
type Movement = { id:string; material_variant_id:string; movement_type:string; quantity:number|string; unit_cost:number|string|null; notes:string|null; occurred_at:string; material_variants:{name:string; materials:{name:string}|null}|null; locations:{name:string}|null }

const movementTypes = ['adjustment','transfer','return','supplier_return','sample','damage','waste'] as const
const qty = (value:number|string|null|undefined) => Number(value ?? 0) || 0

export function InventoryPage({ businessId, userId }:{businessId:string; userId:string}) {
  const [availability,setAvailability]=useState<Availability[]>([])
  const [variants,setVariants]=useState<MaterialVariant[]>([])
  const [locations,setLocations]=useState<Location[]>([])
  const [lots,setLots]=useState<Lot[]>([])
  const [movements,setMovements]=useState<Movement[]>([])
  const [loading,setLoading]=useState(true)
  const [error,setError]=useState<string|null>(null)
  const [search,setSearch]=useState('')
  const [tab,setTab]=useState<'stock'|'lots'|'movements'>('stock')
  const [adjustOpen,setAdjustOpen]=useState(false)

  async function load(){
    if(!supabase)return
    setLoading(true);setError(null)
    const [a,v,l,lo,m]=await Promise.all([
      supabase.from('inventory_availability').select('business_id,material_variant_id,location_id,physical_quantity,reserved_quantity,available_quantity').eq('business_id',businessId),
      supabase.from('material_variants').select('id,name,sku,material_id,materials(name,unit,base_unit)').eq('business_id',businessId).eq('active',true).order('name'),
      supabase.from('locations').select('id,name').eq('business_id',businessId).eq('active',true).order('name'),
      supabase.from('inventory_lots').select('id,material_variant_id,lot_number,quantity_initial,quantity_remaining,unit_cost,received_at,material_variants(name,materials(name))').eq('business_id',businessId).order('received_at',{ascending:false}).limit(100),
      supabase.from('inventory_movements').select('id,material_variant_id,movement_type,quantity,unit_cost,notes,occurred_at,material_variants(name,materials(name)),locations(name)').eq('business_id',businessId).order('occurred_at',{ascending:false}).limit(100),
    ])
    const firstError=[a.error,v.error,l.error,lo.error,m.error].find(Boolean)
    if(firstError)setError(firstError.message)
    setAvailability((a.data??[]) as Availability[]);setVariants((v.data??[]) as unknown as MaterialVariant[]);setLocations((l.data??[]) as Location[]);setLots((lo.data??[]) as unknown as Lot[]);setMovements((m.data??[]) as unknown as Movement[]);setLoading(false)
  }
  useEffect(()=>{void load()},[businessId])

  const rows=useMemo(()=>availability.map(row=>({row,variant:variants.find(v=>v.id===row.material_variant_id),location:locations.find(l=>l.id===row.location_id)})).filter(({variant})=>{
    const q=search.trim().toLowerCase();if(!q)return true;return [variant?.name,variant?.sku,variant?.materials?.name].some(v=>v?.toLowerCase().includes(q))
  }),[availability,variants,locations,search])
  const totals=useMemo(()=>rows.reduce((a,{row})=>({physical:a.physical+qty(row.physical_quantity),reserved:a.reserved+qty(row.reserved_quantity),available:a.available+qty(row.available_quantity)}),{physical:0,reserved:0,available:0}),[rows])

  return <>
    <div className="page-heading page-heading--actions"><div><span className="eyebrow">Existencias por movimientos</span><h1>Inventario</h1><p>Físico, reservado y disponible se leen desde la vista consolidada del backend.</p></div><button className="primary-button primary-button--inline" onClick={()=>setAdjustOpen(true)}><Plus size={18}/> Registrar movimiento</button></div>
    {error&&<div className="notice notice--error">{error}</div>}
    <div className="metric-grid metric-grid--compact"><article className="metric-card"><span>Existencia física</span><strong>{totals.physical.toLocaleString('es-MX')}</strong><small>Unidades equivalentes</small></article><article className="metric-card"><span>Reservado</span><strong>{totals.reserved.toLocaleString('es-MX')}</strong><small>Comprometido a pedidos</small></article><article className="metric-card"><span>Disponible</span><strong>{totals.available.toLocaleString('es-MX')}</strong><small>Listo para usar</small></article></div>
    <div className="module-tabs"><button className={tab==='stock'?'module-tab module-tab--active':'module-tab'} onClick={()=>setTab('stock')}><Boxes size={16}/> Existencias</button><button className={tab==='lots'?'module-tab module-tab--active':'module-tab'} onClick={()=>setTab('lots')}><Layers3 size={16}/> Lotes</button><button className={tab==='movements'?'module-tab module-tab--active':'module-tab'} onClick={()=>setTab('movements')}><History size={16}/> Movimientos</button></div>
    {tab==='stock'&&<><div className="toolbar"><div className="search-box"><Search size={18}/><input placeholder="Buscar material, variante o SKU…" value={search} onChange={e=>setSearch(e.target.value)}/></div><span className="toolbar__count">{rows.length} registros</span></div><div className="data-card"><div className="table-scroll"><table className="data-table"><thead><tr><th>Material</th><th>Ubicación</th><th>Físico</th><th>Reservado</th><th>Disponible</th></tr></thead><tbody>{rows.map(({row,variant,location})=><tr key={`${row.material_variant_id}-${row.location_id??'none'}`}><td><strong>{variant?.materials?.name??'Material'}</strong><small>{variant?.name}{variant?.sku?` · ${variant.sku}`:''}</small></td><td>{location?.name??'Sin ubicación'}</td><td>{qty(row.physical_quantity).toLocaleString('es-MX')}</td><td>{qty(row.reserved_quantity).toLocaleString('es-MX')}</td><td><strong>{qty(row.available_quantity).toLocaleString('es-MX')}</strong></td></tr>)}</tbody></table></div>{!loading&&rows.length===0&&<div className="empty-state"><Boxes size={28}/><strong>Sin existencias registradas</strong><span>Los movimientos y recepciones irán alimentando esta vista.</span></div>}</div></>}
    {tab==='lots'&&<div className="data-card"><div className="table-scroll"><table className="data-table"><thead><tr><th>Material</th><th>Lote</th><th>Inicial</th><th>Restante</th><th>Costo</th><th>Recibido</th></tr></thead><tbody>{lots.map(lot=><tr key={lot.id}><td><strong>{lot.material_variants?.materials?.name??'Material'}</strong><small>{lot.material_variants?.name}</small></td><td>{lot.lot_number??'—'}</td><td>{qty(lot.quantity_initial)}</td><td>{qty(lot.quantity_remaining)}</td><td>${qty(lot.unit_cost).toLocaleString('es-MX',{minimumFractionDigits:2})}</td><td>{new Date(lot.received_at).toLocaleDateString('es-MX')}</td></tr>)}</tbody></table></div></div>}
    {tab==='movements'&&<div className="data-card"><div className="table-scroll"><table className="data-table"><thead><tr><th>Fecha</th><th>Material</th><th>Tipo</th><th>Cantidad</th><th>Ubicación</th><th>Notas</th></tr></thead><tbody>{movements.map(m=><tr key={m.id}><td>{new Date(m.occurred_at).toLocaleString('es-MX')}</td><td><strong>{m.material_variants?.materials?.name??'Material'}</strong><small>{m.material_variants?.name}</small></td><td><span className="tag">{m.movement_type}</span></td><td>{qty(m.quantity)}</td><td>{m.locations?.name??'—'}</td><td>{m.notes??'—'}</td></tr>)}</tbody></table></div></div>}
    {adjustOpen&&<MovementDrawer businessId={businessId} userId={userId} variants={variants} locations={locations} onClose={()=>setAdjustOpen(false)} onSaved={async()=>{setAdjustOpen(false);await load()}}/>}
  </>
}

function MovementDrawer({businessId,userId,variants,locations,onClose,onSaved}:{businessId:string;userId:string;variants:MaterialVariant[];locations:Location[];onClose:()=>void;onSaved:()=>Promise<void>}){
  const [variantId,setVariantId]=useState('');const [locationId,setLocationId]=useState('');const [type,setType]=useState<(typeof movementTypes)[number]>('adjustment');const [quantity,setQuantity]=useState('');const [unitCost,setUnitCost]=useState('');const [notes,setNotes]=useState('');const [saving,setSaving]=useState(false);const [error,setError]=useState<string|null>(null)
  async function submit(e:FormEvent){e.preventDefault();if(!supabase)return;setSaving(true);setError(null);const parsed=Number(quantity);if(!variantId||!Number.isFinite(parsed)||parsed===0){setError('Selecciona material e indica una cantidad distinta de cero.');setSaving(false);return}const {error:insertError}=await supabase.from('inventory_movements').insert({business_id:businessId,material_variant_id:variantId,location_id:locationId||null,movement_type:type,quantity:parsed,unit_cost:unitCost?Number(unitCost):null,notes:notes||null,created_by:userId});if(insertError){setError(insertError.message);setSaving(false);return}await onSaved()}
  return <div className="drawer-backdrop"><aside className="drawer"><div className="drawer__header"><div><span className="eyebrow">Inventario</span><h2>Registrar movimiento</h2></div><button className="icon-button" onClick={onClose}><X size={20}/></button></div><form className="form-grid" onSubmit={submit}><label className="form-grid__wide">Material / variante<select required value={variantId} onChange={e=>setVariantId(e.target.value)}><option value="">Selecciona…</option>{variants.map(v=><option key={v.id} value={v.id}>{v.materials?.name} · {v.name}</option>)}</select></label><label>Tipo<select value={type} onChange={e=>setType(e.target.value as (typeof movementTypes)[number])}>{movementTypes.map(t=><option key={t}>{t}</option>)}</select></label><label>Ubicación<select value={locationId} onChange={e=>setLocationId(e.target.value)}><option value="">Sin ubicación</option>{locations.map(l=><option key={l.id} value={l.id}>{l.name}</option>)}</select></label><label>Cantidad<input type="number" step="0.0001" value={quantity} onChange={e=>setQuantity(e.target.value)} required/></label><label>Costo unitario<input type="number" min="0" step="0.01" value={unitCost} onChange={e=>setUnitCost(e.target.value)}/></label><label className="form-grid__wide">Notas<textarea rows={4} value={notes} onChange={e=>setNotes(e.target.value)}/></label>{error&&<div className="notice notice--error form-grid__wide">{error}</div>}<div className="form-actions form-grid__wide"><button type="button" className="secondary-button" onClick={onClose}>Cancelar</button><button className="primary-button primary-button--inline" disabled={saving}>{saving?'Guardando…':'Registrar'}</button></div></form></aside></div>
}
