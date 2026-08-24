import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Building2, CheckCircle2, CircleDollarSign, MapPin, PackagePlus, RefreshCw } from 'lucide-react'
import { supabase } from '../lib/supabase'
import './setup.css'

type SetupStatus = {
  branches: number
  locations: number
  accounts: number
  materials: number
  paymentMethods: number
}

const emptyStatus: SetupStatus = { branches: 0, locations: 0, accounts: 0, materials: 0, paymentMethods: 0 }

export function SetupPage({ businessId }: { businessId: string }) {
  const [status, setStatus] = useState<SetupStatus>(emptyStatus)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [branchName, setBranchName] = useState('')
  const [branchAddress, setBranchAddress] = useState('')
  const [areaName, setAreaName] = useState('')
  const [locationName, setLocationName] = useState('')
  const [locationType, setLocationType] = useState('storage')
  const [accountName, setAccountName] = useState('')
  const [accountType, setAccountType] = useState('cash')
  const [openingBalance, setOpeningBalance] = useState('0')
  const [materialName, setMaterialName] = useState('')
  const [variantName, setVariantName] = useState('Estándar')
  const [unit, setUnit] = useState('pieza')
  const [category, setCategory] = useState('')
  const [minimumStock, setMinimumStock] = useState('0')

  const loadStatus = useCallback(async () => {
    if (!supabase) return
    setLoading(true); setError(null)
    const [branches, locations, accounts, materials, methods] = await Promise.all([
      supabase.from('branches').select('id', { count: 'exact', head: true }).eq('business_id', businessId).eq('active', true),
      supabase.from('locations').select('id', { count: 'exact', head: true }).eq('business_id', businessId).eq('active', true),
      supabase.from('financial_accounts').select('id', { count: 'exact', head: true }).eq('business_id', businessId).eq('active', true),
      supabase.from('materials').select('id', { count: 'exact', head: true }).eq('business_id', businessId).is('deleted_at', null).eq('active', true),
      supabase.from('payment_methods').select('id', { count: 'exact', head: true }).eq('business_id', businessId).eq('active', true),
    ])
    const firstError = branches.error ?? locations.error ?? accounts.error ?? materials.error ?? methods.error
    if (firstError) setError(firstError.message)
    setStatus({ branches: branches.count ?? 0, locations: locations.count ?? 0, accounts: accounts.count ?? 0, materials: materials.count ?? 0, paymentMethods: methods.count ?? 0 })
    setLoading(false)
  }, [businessId])

  useEffect(() => { void loadStatus() }, [loadStatus])

  async function createBranch(event: FormEvent) {
    event.preventDefault(); if (!supabase) return
    setError(null); setMessage(null)
    const { data: branch, error: branchError } = await supabase.from('branches').insert({ business_id: businessId, name: branchName.trim(), address: branchAddress.trim() || null }).select('id').single()
    if (branchError || !branch) { setError(branchError?.message ?? 'No se pudo crear la sucursal.'); return }
    let areaId: string | null = null
    if (areaName.trim()) {
      const { data: area, error: areaError } = await supabase.from('areas').insert({ business_id: businessId, branch_id: branch.id, name: areaName.trim() }).select('id').single()
      if (areaError) { setError(`Sucursal creada, pero el área falló: ${areaError.message}`); await loadStatus(); return }
      areaId = area?.id ?? null
    }
    if (locationName.trim()) {
      const { error: locationError } = await supabase.from('locations').insert({ business_id: businessId, branch_id: branch.id, area_id: areaId, name: locationName.trim(), location_type: locationType || null })
      if (locationError) { setError(`Sucursal creada, pero la ubicación falló: ${locationError.message}`); await loadStatus(); return }
    }
    setBranchName(''); setBranchAddress(''); setAreaName(''); setLocationName(''); setMessage('Sucursal y ubicación guardadas.'); await loadStatus()
  }

  async function createAccount(event: FormEvent) {
    event.preventDefault(); if (!supabase) return
    setError(null); setMessage(null)
    const balance = Number(openingBalance)
    if (!Number.isFinite(balance)) { setError('El saldo inicial no es válido.'); return }
    const { error: insertError } = await supabase.from('financial_accounts').insert({ business_id: businessId, name: accountName.trim(), account_type: accountType, opening_balance: balance, currency: 'MXN' })
    if (insertError) { setError(insertError.message); return }
    setAccountName(''); setOpeningBalance('0'); setMessage('Cuenta financiera guardada.'); await loadStatus()
  }

  async function createMaterial(event: FormEvent) {
    event.preventDefault(); if (!supabase) return
    setError(null); setMessage(null)
    const min = Number(minimumStock)
    if (!Number.isFinite(min) || min < 0) { setError('El stock mínimo debe ser 0 o mayor.'); return }
    const { data: material, error: materialError } = await supabase.from('materials').insert({ business_id: businessId, name: materialName.trim(), unit, base_unit: unit, category: category.trim() || null, minimum_stock: min, track_inventory: true }).select('id').single()
    if (materialError || !material) { setError(materialError?.message ?? 'No se pudo crear el material.'); return }
    const { error: variantError } = await supabase.from('material_variants').insert({ business_id: businessId, material_id: material.id, name: variantName.trim() || 'Estándar' })
    if (variantError) { setError(`Material creado, pero la variante falló: ${variantError.message}`); await loadStatus(); return }
    setMaterialName(''); setVariantName('Estándar'); setCategory(''); setMinimumStock('0'); setMessage('Material y variante inicial guardados.'); await loadStatus()
  }

  const completed = status.branches > 0 && status.locations > 0 && status.accounts > 0 && status.materials > 0 && status.paymentMethods > 0

  return <>
    <div className="page-heading page-heading--actions"><div><span className="eyebrow">Primera configuración</span><h1>Preparar Moore Print</h1><p>Completa sólo los datos reales del negocio. Nada se inventa ni se sobrescribe.</p></div><button className="secondary-button primary-button--auto" onClick={() => void loadStatus()} disabled={loading}><RefreshCw size={16}/> Actualizar</button></div>
    {error && <div className="notice notice--error">{error}</div>}
    {message && <div className="notice">{message}</div>}
    {completed && <div className="notice setup-complete"><CheckCircle2 size={18}/> La configuración mínima para probar operaciones ya está completa.</div>}
    <div className="setup-status-grid">
      <StatusCard icon={Building2} label="Sucursales" value={status.branches} ready={status.branches > 0}/>
      <StatusCard icon={MapPin} label="Ubicaciones" value={status.locations} ready={status.locations > 0}/>
      <StatusCard icon={CircleDollarSign} label="Cuentas" value={status.accounts} ready={status.accounts > 0}/>
      <StatusCard icon={PackagePlus} label="Materiales" value={status.materials} ready={status.materials > 0}/>
      <StatusCard icon={CheckCircle2} label="Métodos de pago" value={status.paymentMethods} ready={status.paymentMethods > 0}/>
    </div>
    <div className="setup-grid">
      <form className="panel entity-form" onSubmit={createBranch}><div><span className="eyebrow">Paso 1</span><h2>Sucursal y ubicación</h2><p className="panel__note">La ubicación será necesaria para recepciones e inventario.</p></div><label>Nombre de sucursal<input value={branchName} onChange={e=>setBranchName(e.target.value)} required placeholder="Escribe el nombre real"/></label><label>Dirección<input value={branchAddress} onChange={e=>setBranchAddress(e.target.value)} placeholder="Opcional"/></label><div className="form-grid"><label>Área<input value={areaName} onChange={e=>setAreaName(e.target.value)} placeholder="Opcional, ej. Almacén"/></label><label>Ubicación<input value={locationName} onChange={e=>setLocationName(e.target.value)} required placeholder="Ej. Estante A"/></label></div><label>Tipo de ubicación<select value={locationType} onChange={e=>setLocationType(e.target.value)}><option value="storage">Almacén</option><option value="counter">Mostrador</option><option value="production">Producción</option><option value="office">Administración</option><option value="other">Otro</option></select></label><button className="primary-button">Guardar sucursal</button></form>
      <form className="panel entity-form" onSubmit={createAccount}><div><span className="eyebrow">Paso 2</span><h2>Primera cuenta financiera</h2><p className="panel__note">Usa el saldo real de arranque; después los movimientos actualizarán el saldo.</p></div><label>Nombre de la cuenta<input value={accountName} onChange={e=>setAccountName(e.target.value)} required placeholder="Ej. Caja local"/></label><label>Tipo<select value={accountType} onChange={e=>setAccountType(e.target.value)}><option value="cash">Efectivo</option><option value="bank">Banco</option><option value="mercado_pago">Mercado Pago</option><option value="personal_business_use">Personal usada para negocio</option><option value="other">Otra</option></select></label><label>Saldo inicial MXN<input type="number" step="0.01" value={openingBalance} onChange={e=>setOpeningBalance(e.target.value)} required/></label><button className="primary-button">Guardar cuenta</button></form>
      <form className="panel entity-form" onSubmit={createMaterial}><div><span className="eyebrow">Paso 3</span><h2>Primer material</h2><p className="panel__note">Se crea también una variante inicial para poder usarlo en compras e inventario.</p></div><label>Material<input value={materialName} onChange={e=>setMaterialName(e.target.value)} required placeholder="Ej. Playera algodón"/></label><div className="form-grid"><label>Variante<input value={variantName} onChange={e=>setVariantName(e.target.value)} required/></label><label>Unidad<input value={unit} onChange={e=>setUnit(e.target.value)} required placeholder="pieza, m, m²..."/></label></div><div className="form-grid"><label>Categoría<input value={category} onChange={e=>setCategory(e.target.value)} placeholder="Opcional"/></label><label>Stock mínimo<input type="number" min="0" step="0.01" value={minimumStock} onChange={e=>setMinimumStock(e.target.value)} required/></label></div><button className="primary-button">Guardar material</button></form>
    </div>
  </>
}

function StatusCard({ icon: Icon, label, value, ready }: { icon: typeof Building2; label:string; value:number; ready:boolean }) {
  return <article className={`setup-status ${ready ? 'setup-status--ready' : ''}`}><Icon size={19}/><div><span>{label}</span><strong>{value}</strong></div>{ready && <CheckCircle2 size={17}/>}</article>
}
