import { FormEvent, useEffect, useMemo, useState } from 'react'
import { PackageCheck, Plus, Search, Star, X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import './finance-suppliers.css'

type Supplier = {
  id: string
  name: string
  contact_name: string | null
  phone: string | null
  email: string | null
  tax_id: string | null
  address: string | null
  notes: string | null
  active: boolean
}

type Performance = {
  supplier_id: string
  name: string
  delivery_rating: number | string | null
  accuracy_rating: number | string | null
  quality_rating: number | string | null
  incident_count: number | string | null
  purchase_count: number | string | null
  purchase_value: number | string | null
}

type MaterialLink = {
  id: string
  supplier_id: string
  material_id: string
  preferred: boolean
  brand: string | null
  estimated_lead_days: number | null
  current_price: number | string | null
  currency: string
  materials: { name: string } | null
}

type Incident = {
  id: string
  supplier_id: string
  incident_type: string
  resolution: string | null
  description: string | null
  resolved_at: string | null
  created_at: string
}

type Material = { id: string; name: string }

const money = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })
const num = (value: unknown) => (Number.isFinite(Number(value ?? 0)) ? Number(value ?? 0) : 0)

export function SuppliersPage({ businessId, userId }: { businessId: string; userId: string }) {
  const [suppliers, setSuppliers] = useState<Supplier[]>([])
  const [performance, setPerformance] = useState<Performance[]>([])
  const [links, setLinks] = useState<MaterialLink[]>([])
  const [incidents, setIncidents] = useState<Incident[]>([])
  const [materials, setMaterials] = useState<Material[]>([])
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<Supplier | null>(null)
  const [modal, setModal] = useState<'supplier' | 'material' | 'incident' | 'review' | null>(null)
  const [editing, setEditing] = useState<Supplier | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    if (!supabase) return
    setLoading(true)
    setError(null)
    const [supplierResult, performanceResult, linksResult, incidentResult, materialsResult] = await Promise.all([
      supabase
        .from('suppliers')
        .select('id,name,contact_name,phone,email,tax_id,address,notes,active')
        .eq('business_id', businessId)
        .is('deleted_at', null)
        .order('name'),
      supabase.from('supplier_performance').select('*').eq('business_id', businessId),
      supabase
        .from('supplier_materials')
        .select('id,supplier_id,material_id,preferred,brand,estimated_lead_days,current_price,currency,materials(name)')
        .eq('business_id', businessId)
        .eq('active', true),
      supabase
        .from('supplier_incidents')
        .select('id,supplier_id,incident_type,resolution,description,resolved_at,created_at')
        .eq('business_id', businessId)
        .order('created_at', { ascending: false })
        .limit(100),
      supabase
        .from('materials')
        .select('id,name')
        .eq('business_id', businessId)
        .is('deleted_at', null)
        .eq('active', true)
        .order('name'),
    ])

    const firstError = [supplierResult, performanceResult, linksResult, incidentResult, materialsResult].find(
      (result) => result.error,
    )
    if (firstError?.error) setError(firstError.error.message)

    setSuppliers((supplierResult.data ?? []) as Supplier[])
    setPerformance((performanceResult.data ?? []) as Performance[])
    setLinks((linksResult.data ?? []) as unknown as MaterialLink[])
    setIncidents((incidentResult.data ?? []) as Incident[])
    setMaterials((materialsResult.data ?? []) as Material[])
    setLoading(false)
  }

  useEffect(() => {
    void load()
  }, [businessId])

  const visible = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    return suppliers.filter(
      (supplier) =>
        !normalized ||
        [supplier.name, supplier.contact_name, supplier.phone, supplier.email].some((value) =>
          value?.toLowerCase().includes(normalized),
        ),
    )
  }, [suppliers, query])

  const supplierPerformance = (supplierId: string) => performance.find((item) => item.supplier_id === supplierId)
  const selectedLinks = selected ? links.filter((item) => item.supplier_id === selected.id) : []
  const selectedIncidents = selected ? incidents.filter((item) => item.supplier_id === selected.id) : []

  return (
    <>
      <div className="page-heading page-heading--actions">
        <div>
          <span className="eyebrow">Abastecimiento</span>
          <h1>Proveedores</h1>
          <p>Contactos, materiales, precios y desempeño.</p>
        </div>
        <button
          className="primary-button primary-button--auto"
          onClick={() => {
            setEditing(null)
            setModal('supplier')
          }}
        >
          <Plus size={17} /> Nuevo proveedor
        </button>
      </div>

      <div className="toolbar">
        <div className="search-field">
          <Search size={17} />
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar proveedor…" />
        </div>
        <span className="toolbar__count">{visible.length} proveedores</span>
      </div>

      {error && <div className="notice notice--error">{error}</div>}

      <div className="data-card">
        <div className="data-list">
          {loading ? (
            <div className="empty-state">Cargando…</div>
          ) : visible.length === 0 ? (
            <div className="empty-state">
              <PackageCheck size={28} />
              <strong>Sin proveedores</strong>
            </div>
          ) : (
            visible.map((supplier) => {
              const currentPerformance = supplierPerformance(supplier.id)
              const ratings = [
                num(currentPerformance?.delivery_rating),
                num(currentPerformance?.accuracy_rating),
                num(currentPerformance?.quality_rating),
              ].filter((value) => value > 0)
              const average = ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : 0
              return (
                <button className="data-row" key={supplier.id} onClick={() => setSelected(supplier)}>
                  <div className="data-row__avatar">
                    <PackageCheck size={18} />
                  </div>
                  <div className="data-row__main">
                    <strong>{supplier.name}</strong>
                    <span>
                      {supplier.contact_name || 'Sin contacto'} · {supplier.phone || 'Sin teléfono'}
                    </span>
                  </div>
                  <div className="data-row__meta">
                    <strong>{currentPerformance ? money.format(num(currentPerformance.purchase_value)) : '$0.00'}</strong>
                    <span>
                      {currentPerformance?.purchase_count ?? 0} compras · {average ? `${average.toFixed(1)}★` : 'Sin evaluación'}
                    </span>
                  </div>
                </button>
              )
            })
          )}
        </div>
      </div>

      {selected && (
        <div className="drawer-backdrop">
          <aside className="detail-drawer detail-drawer--wide">
            <div className="drawer-header">
              <div>
                <span className="eyebrow">Proveedor</span>
                <h2>{selected.name}</h2>
                <p>{selected.contact_name || 'Sin contacto'}</p>
              </div>
              <button className="icon-button" onClick={() => setSelected(null)}>
                <X size={20} />
              </button>
            </div>

            <div className="supplier-actions">
              <button
                className="secondary-button"
                onClick={() => {
                  setEditing(selected)
                  setModal('supplier')
                }}
              >
                Editar
              </button>
              <button className="secondary-button" onClick={() => setModal('material')}>
                Agregar material
              </button>
              <button className="secondary-button" onClick={() => setModal('review')}>
                Evaluar proveedor
              </button>
              <button className="secondary-button" onClick={() => setModal('incident')}>
                Registrar incidencia
              </button>
            </div>

            <div className="detail-stack">
              <div className="detail-item"><div><span>Teléfono</span><strong>{selected.phone || '—'}</strong></div></div>
              <div className="detail-item"><div><span>Correo</span><strong>{selected.email || '—'}</strong></div></div>
              <div className="detail-item"><div><span>RFC</span><strong>{selected.tax_id || '—'}</strong></div></div>
              <div className="detail-item"><div><span>Dirección</span><strong>{selected.address || '—'}</strong></div></div>
            </div>

            <section className="drawer-section">
              <h3>Desempeño</h3>
              {(() => {
                const currentPerformance = supplierPerformance(selected.id)
                return currentPerformance ? (
                  <div className="supplier-metrics">
                    <div><Star size={16} /><span>Entrega</span><strong>{num(currentPerformance.delivery_rating).toFixed(1)}</strong></div>
                    <div><Star size={16} /><span>Exactitud</span><strong>{num(currentPerformance.accuracy_rating).toFixed(1)}</strong></div>
                    <div><Star size={16} /><span>Calidad</span><strong>{num(currentPerformance.quality_rating).toFixed(1)}</strong></div>
                    <div><span>Incidencias</span><strong>{currentPerformance.incident_count ?? 0}</strong></div>
                  </div>
                ) : (
                  <div className="empty-state empty-state--compact">Sin evaluaciones todavía.</div>
                )
              })()}
            </section>

            <section className="drawer-section">
              <h3>Materiales y precios</h3>
              {selectedLinks.length === 0 ? (
                <div className="empty-state empty-state--compact">Sin materiales asociados.</div>
              ) : (
                <div className="line-items">
                  {selectedLinks.map((link) => (
                    <div className="line-item" key={link.id}>
                      <div>
                        <strong>{link.materials?.name ?? 'Material'}</strong>
                        <span>{link.brand || 'Sin marca'} · {link.estimated_lead_days ?? '—'} días</span>
                      </div>
                      <div>
                        <strong>{link.current_price == null ? 'Sin precio' : money.format(num(link.current_price))}</strong>
                        <span>{link.preferred ? 'Preferido' : 'Alternativo'}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>

            <section className="drawer-section">
              <h3>Incidencias recientes</h3>
              {selectedIncidents.length === 0 ? (
                <div className="empty-state empty-state--compact">Sin incidencias.</div>
              ) : (
                <div className="line-items">
                  {selectedIncidents.slice(0, 8).map((incident) => (
                    <div className="line-item" key={incident.id}>
                      <div><strong>{incident.incident_type}</strong><span>{incident.description || 'Sin descripción'}</span></div>
                      <div><span>{incident.resolution || 'Pendiente'}</span></div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          </aside>
        </div>
      )}

      {modal === 'supplier' && (
        <SupplierModal
          businessId={businessId}
          editing={editing}
          close={() => setModal(null)}
          done={async () => {
            setModal(null)
            await load()
            if (editing) setSelected(null)
          }}
        />
      )}

      {modal === 'material' && selected && (
        <MaterialModal
          businessId={businessId}
          supplierId={selected.id}
          materials={materials}
          close={() => setModal(null)}
          done={async () => {
            setModal(null)
            await load()
          }}
        />
      )}

      {modal === 'review' && selected && (
        <ReviewModal
          businessId={businessId}
          supplierId={selected.id}
          userId={userId}
          close={() => setModal(null)}
          done={async () => {
            setModal(null)
            await load()
          }}
        />
      )}

      {modal === 'incident' && selected && (
        <IncidentModal
          businessId={businessId}
          supplierId={selected.id}
          userId={userId}
          close={() => setModal(null)}
          done={async () => {
            setModal(null)
            await load()
          }}
        />
      )}
    </>
  )
}

function SupplierModal({ businessId, editing, close, done }: { businessId: string; editing: Supplier | null; close: () => void; done: () => void }) {
  const [name, setName] = useState(editing?.name ?? '')
  const [contact, setContact] = useState(editing?.contact_name ?? '')
  const [phone, setPhone] = useState(editing?.phone ?? '')
  const [email, setEmail] = useState(editing?.email ?? '')
  const [tax, setTax] = useState(editing?.tax_id ?? '')
  const [address, setAddress] = useState(editing?.address ?? '')
  const [notes, setNotes] = useState(editing?.notes ?? '')
  const [error, setError] = useState<string | null>(null)

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!supabase) return
    const payload = {
      business_id: businessId,
      name,
      contact_name: contact || null,
      phone: phone || null,
      email: email || null,
      tax_id: tax || null,
      address: address || null,
      notes: notes || null,
    }
    const result = editing
      ? await supabase.from('suppliers').update(payload).eq('id', editing.id).eq('business_id', businessId)
      : await supabase.from('suppliers').insert(payload)
    if (result.error) setError(result.error.message)
    else done()
  }

  return (
    <Modal title={editing ? 'Editar proveedor' : 'Nuevo proveedor'} close={close}>
      <form className="entity-form" onSubmit={submit}>
        <div className="form-grid">
          <label>Nombre<input required value={name} onChange={(event) => setName(event.target.value)} /></label>
          <label>Contacto<input value={contact} onChange={(event) => setContact(event.target.value)} /></label>
          <label>Teléfono<input value={phone} onChange={(event) => setPhone(event.target.value)} /></label>
          <label>Correo<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} /></label>
          <label>RFC<input value={tax} onChange={(event) => setTax(event.target.value)} /></label>
          <label>Dirección<input value={address} onChange={(event) => setAddress(event.target.value)} /></label>
          <label className="form-span-2">Notas<textarea rows={3} value={notes} onChange={(event) => setNotes(event.target.value)} /></label>
        </div>
        {error && <div className="notice notice--error">{error}</div>}
        <Actions close={close} />
      </form>
    </Modal>
  )
}

function MaterialModal({ businessId, supplierId, materials, close, done }: { businessId: string; supplierId: string; materials: Material[]; close: () => void; done: () => void }) {
  const [mode, setMode] = useState<'existing' | 'new'>(materials.length ? 'existing' : 'new')
  const [material, setMaterial] = useState('')
  const [newName, setNewName] = useState('')
  const [unit, setUnit] = useState('pieza')
  const [category, setCategory] = useState('')
  const [minimumStock, setMinimumStock] = useState('0')
  const [brand, setBrand] = useState('')
  const [price, setPrice] = useState('')
  const [days, setDays] = useState('')
  const [preferred, setPreferred] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!supabase || saving) return
    setSaving(true)
    setError(null)

    let materialId = material

    if (mode === 'new') {
      const cleanName = newName.trim()
      if (!cleanName) {
        setError('Escribe el nombre del material.')
        setSaving(false)
        return
      }

      const { data: createdMaterial, error: materialError } = await supabase
        .from('materials')
        .insert({
          business_id: businessId,
          name: cleanName,
          unit,
          base_unit: unit,
          category: category.trim() || null,
          minimum_stock: num(minimumStock),
          track_inventory: true,
        })
        .select('id')
        .single()

      if (materialError || !createdMaterial) {
        setError(materialError?.message ?? 'No se pudo crear el material.')
        setSaving(false)
        return
      }

      materialId = createdMaterial.id

      const { error: variantError } = await supabase.from('material_variants').insert({
        business_id: businessId,
        material_id: materialId,
        name: cleanName,
        attributes: {},
      })

      if (variantError) {
        setError(`El material se creó, pero su variante inicial falló: ${variantError.message}`)
        setSaving(false)
        return
      }
    }

    if (!materialId) {
      setError('Selecciona o crea un material.')
      setSaving(false)
      return
    }

    const { data: link, error: linkError } = await supabase
      .from('supplier_materials')
      .insert({
        business_id: businessId,
        supplier_id: supplierId,
        material_id: materialId,
        brand: brand.trim() || null,
        current_price: price ? num(price) : null,
        estimated_lead_days: days ? Number(days) : null,
        preferred,
      })
      .select('id')
      .single()

    if (linkError || !link) {
      setError(linkError?.message ?? 'No se pudo asociar el material al proveedor.')
      setSaving(false)
      return
    }

    if (price) {
      const { error: historyError } = await supabase.from('supplier_price_history').insert({
        business_id: businessId,
        supplier_material_id: link.id,
        unit_price: num(price),
        currency: 'MXN',
        source: 'manual_supplier_link',
      })
      if (historyError) {
        setError(`La relación se creó, pero no se pudo guardar el historial de precio: ${historyError.message}`)
        setSaving(false)
        return
      }
    }

    setSaving(false)
    done()
  }

  return (
    <Modal title="Asociar material" close={close}>
      <form className="entity-form" onSubmit={submit}>
        <div className="supplier-actions">
          <button type="button" className={mode === 'existing' ? 'primary-button primary-button--auto' : 'secondary-button'} onClick={() => setMode('existing')} disabled={!materials.length}>
            Material existente
          </button>
          <button type="button" className={mode === 'new' ? 'primary-button primary-button--auto' : 'secondary-button'} onClick={() => setMode('new')}>
            Crear material nuevo
          </button>
        </div>

        {mode === 'existing' ? (
          <label>
            Material
            <select required value={material} onChange={(event) => setMaterial(event.target.value)}>
              <option value="">Selecciona</option>
              {materials.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
            </select>
          </label>
        ) : (
          <div className="form-grid">
            <label className="form-span-2">Nombre del material<input required value={newName} onChange={(event) => setNewName(event.target.value)} placeholder="Ej. DTF textil" /></label>
            <label>Unidad<select value={unit} onChange={(event) => setUnit(event.target.value)}><option value="pieza">Pieza</option><option value="metro">Metro</option><option value="centimetro">Centímetro</option><option value="m2">Metro²</option><option value="hoja">Hoja</option><option value="ml">Mililitro</option><option value="rollo">Rollo</option><option value="paquete">Paquete</option></select></label>
            <label>Categoría<input value={category} onChange={(event) => setCategory(event.target.value)} placeholder="Ej. DTF, Vinil, Lona" /></label>
            <label>Stock mínimo<input type="number" min="0" step="0.01" value={minimumStock} onChange={(event) => setMinimumStock(event.target.value)} /></label>
          </div>
        )}

        <div className="form-grid">
          <label>Marca<input value={brand} onChange={(event) => setBrand(event.target.value)} /></label>
          <label>Precio actual<input type="number" min="0" step="0.01" value={price} onChange={(event) => setPrice(event.target.value)} /></label>
          <label>Días estimados<input type="number" min="0" value={days} onChange={(event) => setDays(event.target.value)} /></label>
          <label className="checkbox-field"><input type="checkbox" checked={preferred} onChange={(event) => setPreferred(event.target.checked)} /> Proveedor preferido</label>
        </div>

        {!materials.length && mode === 'new' && <div className="notice">Todavía no hay materiales. Puedes crear el primero aquí y quedará disponible también en Inventario y Compras.</div>}
        {error && <div className="notice notice--error">{error}</div>}
        <div className="form-actions">
          <button type="button" className="secondary-button" onClick={close}>Cancelar</button>
          <button className="primary-button primary-button--auto" disabled={saving}>{saving ? 'Guardando…' : 'Guardar'}</button>
        </div>
      </form>
    </Modal>
  )
}

function ReviewModal({ businessId, supplierId, userId, close, done }: { businessId: string; supplierId: string; userId: string; close: () => void; done: () => void }) {
  const [delivery, setDelivery] = useState('5')
  const [accuracy, setAccuracy] = useState('5')
  const [quality, setQuality] = useState('5')
  const [notes, setNotes] = useState('')
  const [error, setError] = useState<string | null>(null)

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!supabase) return
    const { error: insertError } = await supabase.from('supplier_reviews').insert({
      business_id: businessId,
      supplier_id: supplierId,
      delivery_rating: Number(delivery),
      accuracy_rating: Number(accuracy),
      quality_rating: Number(quality),
      notes: notes.trim() || null,
      reviewed_by: userId,
    })
    if (insertError) setError(insertError.message)
    else done()
  }

  const ratingOptions = [1, 2, 3, 4, 5]
  return (
    <Modal title="Evaluar proveedor" close={close}>
      <form className="entity-form" onSubmit={submit}>
        <div className="form-grid">
          <label>Entrega<select value={delivery} onChange={(event) => setDelivery(event.target.value)}>{ratingOptions.map((value) => <option key={value} value={value}>{value}</option>)}</select></label>
          <label>Exactitud<select value={accuracy} onChange={(event) => setAccuracy(event.target.value)}>{ratingOptions.map((value) => <option key={value} value={value}>{value}</option>)}</select></label>
          <label>Calidad<select value={quality} onChange={(event) => setQuality(event.target.value)}>{ratingOptions.map((value) => <option key={value} value={value}>{value}</option>)}</select></label>
          <label className="form-span-2">Notas<textarea rows={3} value={notes} onChange={(event) => setNotes(event.target.value)} /></label>
        </div>
        {error && <div className="notice notice--error">{error}</div>}
        <Actions close={close} />
      </form>
    </Modal>
  )
}

function IncidentModal({ businessId, supplierId, userId, close, done }: { businessId: string; supplierId: string; userId: string; close: () => void; done: () => void }) {
  const [type, setType] = useState('missing')
  const [description, setDescription] = useState('')
  const [error, setError] = useState<string | null>(null)

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!supabase) return
    const { error: insertError } = await supabase.from('supplier_incidents').insert({
      business_id: businessId,
      supplier_id: supplierId,
      incident_type: type,
      description: description || null,
      created_by: userId,
    })
    if (insertError) setError(insertError.message)
    else done()
  }

  return (
    <Modal title="Registrar incidencia" close={close}>
      <form className="entity-form" onSubmit={submit}>
        <label>Tipo<select value={type} onChange={(event) => setType(event.target.value)}><option value="missing">Faltante</option><option value="incorrect_product">Producto incorrecto</option><option value="damaged">Dañado</option><option value="extra">Extra</option><option value="other">Otro</option></select></label>
        <label>Descripción<textarea rows={4} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
        {error && <div className="notice notice--error">{error}</div>}
        <Actions close={close} />
      </form>
    </Modal>
  )
}

function Modal({ title, close, children }: { title: string; close: () => void; children: React.ReactNode }) {
  return (
    <div className="modal-backdrop">
      <div className="form-modal form-modal--small">
        <div className="drawer-header"><h2>{title}</h2><button className="icon-button" onClick={close}><X size={19} /></button></div>
        {children}
      </div>
    </div>
  )
}

function Actions({ close }: { close: () => void }) {
  return <div className="form-actions"><button type="button" className="secondary-button" onClick={close}>Cancelar</button><button className="primary-button primary-button--auto">Guardar</button></div>
}
