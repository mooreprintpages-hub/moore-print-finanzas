import { FormEvent, useEffect, useMemo, useState } from 'react'
import { Building2, Mail, MapPin, Pencil, Phone, Plus, Search, UserRound, X } from 'lucide-react'
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

export function CustomersPage({ businessId }: { businessId: string }) {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<Customer | null>(null)
  const [editing, setEditing] = useState<Customer | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState<CustomerForm>(emptyForm)
  const [saving, setSaving] = useState(false)

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
    const term = query.trim().toLocaleLowerCase('es-MX')
    if (!term) return customers
    return customers.filter((customer) =>
      [customer.name, customer.contact_name, customer.phone, customer.email]
        .filter(Boolean)
        .some((value) => String(value).toLocaleLowerCase('es-MX').includes(term)),
    )
  }, [customers, query])

  function openCreate() {
    setEditing(null)
    setForm(emptyForm)
    setShowForm(true)
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
    setShowForm(true)
  }

  async function saveCustomer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase) return
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

    const operation = editing
      ? supabase.from('customers').update(payload).eq('id', editing.id).eq('business_id', businessId)
      : supabase.from('customers').insert(payload)

    const { error: saveError } = await operation
    if (saveError) {
      setError(saveError.message)
      setSaving(false)
      return
    }

    setShowForm(false)
    setEditing(null)
    setSaving(false)
    await loadCustomers()
  }

  return (
    <div>
      <div className="page-heading page-heading--actions">
        <div>
          <span className="eyebrow">Relaciones comerciales</span>
          <h1>Clientes</h1>
          <p>Personas y empresas registradas en Moore Print.</p>
        </div>
        <button className="primary-button primary-button--auto" onClick={openCreate}><Plus size={18} /> Nuevo cliente</button>
      </div>

      {error && <div className="notice notice--error">{error}</div>}

      <div className="toolbar">
        <label className="search-field">
          <Search size={18} />
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar por nombre, teléfono o correo" />
        </label>
        <span className="toolbar__count">{filtered.length} cliente{filtered.length === 1 ? '' : 's'}</span>
      </div>

      <div className="data-card">
        {loading ? (
          <div className="empty-state">Cargando clientes…</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state"><UserRound size={30} /><strong>No hay clientes que mostrar</strong><span>Crea el primero o cambia la búsqueda.</span></div>
        ) : (
          <div className="data-list">
            {filtered.map((customer) => (
              <button key={customer.id} className="data-row" onClick={() => setSelected(customer)}>
                <div className="data-row__avatar">{customer.customer_type === 'business' ? <Building2 size={18} /> : <UserRound size={18} />}</div>
                <div className="data-row__main">
                  <strong>{customer.name}</strong>
                  <span>{customer.customer_type === 'business' ? 'Empresa' : 'Persona'}{customer.contact_name ? ` · ${customer.contact_name}` : ''}</span>
                </div>
                <div className="data-row__meta">
                  <span>{customer.phone || 'Sin teléfono'}</span>
                  <span className={`badge ${customer.active ? 'badge--success' : ''}`}>{customer.active ? 'Activo' : 'Inactivo'}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {selected && (
        <div className="drawer-backdrop" onClick={() => setSelected(null)}>
          <aside className="detail-drawer" onClick={(event) => event.stopPropagation()}>
            <div className="drawer-header">
              <div><span className="eyebrow">Cliente</span><h2>{selected.name}</h2></div>
              <button className="icon-button" onClick={() => setSelected(null)} aria-label="Cerrar"><X size={20} /></button>
            </div>
            <div className="detail-stack">
              <Detail icon={<UserRound size={17} />} label="Tipo" value={selected.customer_type === 'business' ? 'Empresa' : 'Persona'} />
              {selected.contact_name && <Detail icon={<UserRound size={17} />} label="Contacto" value={selected.contact_name} />}
              <Detail icon={<Phone size={17} />} label="Teléfono" value={selected.phone || 'Sin registrar'} />
              <Detail icon={<Mail size={17} />} label="Correo" value={selected.email || 'Sin registrar'} />
              <Detail icon={<MapPin size={17} />} label="Dirección" value={selected.address || 'Sin registrar'} />
              {selected.tax_id && <Detail icon={<Building2 size={17} />} label="RFC / ID fiscal" value={selected.tax_id} />}
            </div>
            {selected.notes && <div className="detail-notes"><span className="eyebrow">Notas</span><p>{selected.notes}</p></div>}
            <button className="secondary-button" onClick={() => { setSelected(null); openEdit(selected) }}><Pencil size={17} /> Editar cliente</button>
          </aside>
        </div>
      )}

      {showForm && (
        <div className="modal-backdrop" onClick={() => setShowForm(false)}>
          <div className="form-modal" onClick={(event) => event.stopPropagation()}>
            <div className="drawer-header">
              <div><span className="eyebrow">{editing ? 'Editar' : 'Alta'}</span><h2>{editing ? editing.name : 'Nuevo cliente'}</h2></div>
              <button className="icon-button" onClick={() => setShowForm(false)} aria-label="Cerrar"><X size={20} /></button>
            </div>
            <form className="entity-form" onSubmit={saveCustomer}>
              <div className="form-grid">
                <label>Tipo<select value={form.customer_type} onChange={(event) => setForm({ ...form, customer_type: event.target.value as CustomerForm['customer_type'] })}><option value="person">Persona</option><option value="business">Empresa</option></select></label>
                <label>Nombre<input required value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} /></label>
                <label>Contacto<input value={form.contact_name} onChange={(event) => setForm({ ...form, contact_name: event.target.value })} /></label>
                <label>Teléfono<input value={form.phone} onChange={(event) => setForm({ ...form, phone: event.target.value })} /></label>
                <label>Correo<input type="email" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} /></label>
                <label>RFC / ID fiscal<input value={form.tax_id} onChange={(event) => setForm({ ...form, tax_id: event.target.value })} /></label>
                <label className="form-span-2">Dirección<input value={form.address} onChange={(event) => setForm({ ...form, address: event.target.value })} /></label>
                <label className="form-span-2">Notas<textarea rows={4} value={form.notes} onChange={(event) => setForm({ ...form, notes: event.target.value })} /></label>
              </div>
              <label className="checkbox-field"><input type="checkbox" checked={form.active} onChange={(event) => setForm({ ...form, active: event.target.checked })} /> Cliente activo</label>
              <div className="form-actions"><button type="button" className="secondary-button" onClick={() => setShowForm(false)}>Cancelar</button><button className="primary-button primary-button--auto" disabled={saving}>{saving ? 'Guardando…' : 'Guardar cliente'}</button></div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

function Detail({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return <div className="detail-item"><span className="detail-item__icon">{icon}</span><div><span>{label}</span><strong>{value}</strong></div></div>
}
