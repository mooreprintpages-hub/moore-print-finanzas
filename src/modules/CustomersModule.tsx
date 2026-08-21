import { FormEvent, useEffect, useMemo, useState } from 'react'
import { Edit3, Plus, Search, UserRound, X } from 'lucide-react'
import { supabase } from '../lib/supabase'

type Customer = {
  id: string
  business_id: string
  customer_type: 'person' | 'business'
  name: string
  contact_name: string | null
  phone: string | null
  email: string | null
  tax_id: string | null
  address: string | null
  notes: string | null
  active: boolean
  created_at: string
}

type CustomerForm = {
  customer_type: 'person' | 'business'
  name: string
  contact_name: string
  phone: string
  email: string
  tax_id: string
  address: string
  notes: string
  active: boolean
}

const emptyForm: CustomerForm = {
  customer_type: 'person',
  name: '',
  contact_name: '',
  phone: '',
  email: '',
  tax_id: '',
  address: '',
  notes: '',
  active: true,
}

export function CustomersModule({ businessId }: { businessId: string }) {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [panelOpen, setPanelOpen] = useState(false)
  const [editing, setEditing] = useState<Customer | null>(null)
  const [form, setForm] = useState<CustomerForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [selected, setSelected] = useState<Customer | null>(null)

  async function loadCustomers() {
    if (!supabase) return
    setLoading(true)
    setError(null)

    const { data, error: queryError } = await supabase
      .from('customers')
      .select('id,business_id,customer_type,name,contact_name,phone,email,tax_id,address,notes,active,created_at')
      .eq('business_id', businessId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })

    if (queryError) setError(queryError.message)
    setCustomers((data ?? []) as Customer[])
    setLoading(false)
  }

  useEffect(() => {
    void loadCustomers()
  }, [businessId])

  const filtered = useMemo(() => {
    const q = search.trim().toLocaleLowerCase('es-MX')
    if (!q) return customers
    return customers.filter((customer) =>
      [customer.name, customer.contact_name, customer.phone, customer.email]
        .filter(Boolean)
        .some((value) => value!.toLocaleLowerCase('es-MX').includes(q)),
    )
  }, [customers, search])

  function openNew() {
    setEditing(null)
    setForm(emptyForm)
    setPanelOpen(true)
  }

  function openEdit(customer: Customer) {
    setEditing(customer)
    setForm({
      customer_type: customer.customer_type,
      name: customer.name,
      contact_name: customer.contact_name ?? '',
      phone: customer.phone ?? '',
      email: customer.email ?? '',
      tax_id: customer.tax_id ?? '',
      address: customer.address ?? '',
      notes: customer.notes ?? '',
      active: customer.active,
    })
    setPanelOpen(true)
  }

  async function saveCustomer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !form.name.trim()) return

    setSaving(true)
    setError(null)
    const payload = {
      business_id: businessId,
      customer_type: form.customer_type,
      name: form.name.trim(),
      contact_name: form.contact_name.trim() || null,
      phone: form.phone.trim() || null,
      email: form.email.trim() || null,
      tax_id: form.tax_id.trim() || null,
      address: form.address.trim() || null,
      notes: form.notes.trim() || null,
      active: form.active,
      updated_at: new Date().toISOString(),
    }

    const result = editing
      ? await supabase.from('customers').update(payload).eq('id', editing.id).eq('business_id', businessId)
      : await supabase.from('customers').insert(payload)

    if (result.error) {
      setError(result.error.message)
      setSaving(false)
      return
    }

    setPanelOpen(false)
    setEditing(null)
    setForm(emptyForm)
    await loadCustomers()
    setSaving(false)
  }

  return (
    <>
      <div className="page-heading page-heading--actions">
        <div>
          <span className="eyebrow">Comercial</span>
          <h1>Clientes</h1>
          <p>Personas y empresas vinculadas a cotizaciones, pedidos y pagos.</p>
        </div>
        <button className="primary-button primary-button--inline" onClick={openNew}>
          <Plus size={18} /> Nuevo cliente
        </button>
      </div>

      <div className="toolbar">
        <label className="search-box">
          <Search size={18} />
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Buscar por nombre, teléfono o correo" />
        </label>
        <span className="toolbar__count">{filtered.length} cliente{filtered.length === 1 ? '' : 's'}</span>
      </div>

      {error && <div className="notice notice--error">{error}</div>}

      <div className="data-card">
        {loading ? (
          <div className="empty-state">Cargando clientes…</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">
            <UserRound size={30} />
            <strong>No hay clientes que mostrar</strong>
            <span>{search ? 'Prueba con otra búsqueda.' : 'Crea el primer cliente para comenzar.'}</span>
          </div>
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr><th>Cliente</th><th>Tipo</th><th>Contacto</th><th>Estado</th><th /></tr>
              </thead>
              <tbody>
                {filtered.map((customer) => (
                  <tr key={customer.id} onClick={() => setSelected(customer)}>
                    <td><strong>{customer.name}</strong><small>{customer.email || 'Sin correo'}</small></td>
                    <td><span className="tag">{customer.customer_type === 'business' ? 'Empresa' : 'Persona'}</span></td>
                    <td>{customer.phone || '—'}</td>
                    <td><span className={`status-dot ${customer.active ? 'status-dot--ok' : ''}`} /> {customer.active ? 'Activo' : 'Inactivo'}</td>
                    <td>
                      <button className="icon-button" onClick={(event) => { event.stopPropagation(); openEdit(customer) }} aria-label="Editar cliente">
                        <Edit3 size={17} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selected && !panelOpen && (
        <div className="drawer-backdrop" onClick={() => setSelected(null)}>
          <aside className="drawer" onClick={(event) => event.stopPropagation()}>
            <div className="drawer__header">
              <div><span className="eyebrow">Detalle de cliente</span><h2>{selected.name}</h2></div>
              <button className="icon-button" onClick={() => setSelected(null)}><X size={20} /></button>
            </div>
            <div className="detail-grid">
              <Detail label="Tipo" value={selected.customer_type === 'business' ? 'Empresa' : 'Persona'} />
              <Detail label="Contacto" value={selected.contact_name || '—'} />
              <Detail label="Teléfono" value={selected.phone || '—'} />
              <Detail label="Correo" value={selected.email || '—'} />
              <Detail label="RFC / ID fiscal" value={selected.tax_id || '—'} />
              <Detail label="Estado" value={selected.active ? 'Activo' : 'Inactivo'} />
            </div>
            <Detail label="Dirección" value={selected.address || '—'} wide />
            <Detail label="Notas" value={selected.notes || '—'} wide />
            <button className="secondary-button" onClick={() => { setSelected(null); openEdit(selected) }}><Edit3 size={17} /> Editar cliente</button>
          </aside>
        </div>
      )}

      {panelOpen && (
        <div className="drawer-backdrop" onClick={() => !saving && setPanelOpen(false)}>
          <aside className="drawer drawer--wide" onClick={(event) => event.stopPropagation()}>
            <div className="drawer__header">
              <div><span className="eyebrow">{editing ? 'Editar' : 'Alta'}</span><h2>{editing ? editing.name : 'Nuevo cliente'}</h2></div>
              <button className="icon-button" onClick={() => setPanelOpen(false)} disabled={saving}><X size={20} /></button>
            </div>
            <form className="form-grid" onSubmit={saveCustomer}>
              <label>Tipo<select value={form.customer_type} onChange={(e) => setForm({ ...form, customer_type: e.target.value as CustomerForm['customer_type'] })}><option value="person">Persona</option><option value="business">Empresa</option></select></label>
              <label>Nombre<input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required /></label>
              <label>Contacto<input value={form.contact_name} onChange={(e) => setForm({ ...form, contact_name: e.target.value })} /></label>
              <label>Teléfono<input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></label>
              <label>Correo<input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></label>
              <label>RFC / ID fiscal<input value={form.tax_id} onChange={(e) => setForm({ ...form, tax_id: e.target.value })} /></label>
              <label className="form-grid__wide">Dirección<textarea rows={2} value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} /></label>
              <label className="form-grid__wide">Notas<textarea rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} /></label>
              <label className="check-field form-grid__wide"><input type="checkbox" checked={form.active} onChange={(e) => setForm({ ...form, active: e.target.checked })} /> Cliente activo</label>
              <div className="form-actions form-grid__wide"><button type="button" className="secondary-button" onClick={() => setPanelOpen(false)} disabled={saving}>Cancelar</button><button className="primary-button primary-button--inline" disabled={saving}>{saving ? 'Guardando…' : 'Guardar cliente'}</button></div>
            </form>
          </aside>
        </div>
      )}
    </>
  )
}

function Detail({ label, value, wide = false }: { label: string; value: string; wide?: boolean }) {
  return <div className={`detail-item ${wide ? 'detail-item--wide' : ''}`}><span>{label}</span><strong>{value}</strong></div>
}
