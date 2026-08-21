import { FormEvent, useEffect, useMemo, useState } from 'react'
import { CalendarClock, ClipboardList, PackagePlus, Pencil, Plus, Search, ShoppingBag, UserRound, X } from 'lucide-react'
import { supabase } from '../lib/supabase'

type CustomerOption = { id: string; name: string }
type ProductOption = { id: string; name: string }

type Order = {
  id: string
  business_id: string
  customer_id: string
  folio: string
  status: string
  priority: string
  promised_at: string | null
  delivered_at: string | null
  subtotal: number | string
  discount: number | string
  tax: number | string
  delivery_fee: number | string
  total: number | string
  notes: string | null
  created_at: string
  customer?: { name: string } | null
}

type OrderItem = {
  id: string
  product_id: string
  description: string | null
  quantity: number | string
  unit_price: number | string
  discount: number | string
  line_total: number | string | null
  status: string
  promised_at: string | null
  product?: { name: string } | null
}

type OrderForm = {
  customer_id: string
  folio: string
  status: string
  priority: string
  promised_at: string
  discount: string
  tax: string
  delivery_fee: string
  notes: string
}

type ItemForm = {
  product_id: string
  description: string
  quantity: string
  unit_price: string
  discount: string
  promised_at: string
}

const money = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })

function toNumber(value: number | string | null | undefined) {
  const parsed = Number(value ?? 0)
  return Number.isFinite(parsed) ? parsed : 0
}

function localDateTimeValue(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  const offset = date.getTimezoneOffset() * 60_000
  return new Date(date.getTime() - offset).toISOString().slice(0, 16)
}

function generatedFolio() {
  const now = new Date()
  const stamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`
  return `MP-${stamp}`
}

export function OrdersPage({ businessId, userId }: { businessId: string; userId: string }) {
  const [orders, setOrders] = useState<Order[]>([])
  const [customers, setCustomers] = useState<CustomerOption[]>([])
  const [products, setProducts] = useState<ProductOption[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<Order | null>(null)
  const [items, setItems] = useState<OrderItem[]>([])
  const [itemsLoading, setItemsLoading] = useState(false)
  const [editing, setEditing] = useState<Order | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [saving, setSaving] = useState(false)
  const [showItemForm, setShowItemForm] = useState(false)
  const [savingItem, setSavingItem] = useState(false)
  const [form, setForm] = useState<OrderForm>({ customer_id: '', folio: generatedFolio(), status: 'draft', priority: 'normal', promised_at: '', discount: '0', tax: '0', delivery_fee: '0', notes: '' })
  const [itemForm, setItemForm] = useState<ItemForm>({ product_id: '', description: '', quantity: '1', unit_price: '0', discount: '0', promised_at: '' })

  async function loadBaseData() {
    if (!supabase) return
    setLoading(true)
    setError(null)
    const [ordersResult, customersResult, productsResult] = await Promise.all([
      supabase.from('orders').select('id,business_id,customer_id,folio,status,priority,promised_at,delivered_at,subtotal,discount,tax,delivery_fee,total,notes,created_at,customer:customers(name)').eq('business_id', businessId).is('deleted_at', null).order('created_at', { ascending: false }),
      supabase.from('customers').select('id,name').eq('business_id', businessId).eq('active', true).is('deleted_at', null).order('name'),
      supabase.from('products').select('id,name').eq('business_id', businessId).eq('active', true).is('deleted_at', null).order('name'),
    ])

    const firstError = ordersResult.error ?? customersResult.error ?? productsResult.error
    if (firstError) setError(firstError.message)
    setOrders((ordersResult.data ?? []) as unknown as Order[])
    setCustomers((customersResult.data ?? []) as CustomerOption[])
    setProducts((productsResult.data ?? []) as ProductOption[])
    setLoading(false)
  }

  async function loadItems(orderId: string) {
    if (!supabase) return
    setItemsLoading(true)
    const { data, error: queryError } = await supabase.from('order_items').select('id,product_id,description,quantity,unit_price,discount,line_total,status,promised_at,product:products(name)').eq('business_id', businessId).eq('order_id', orderId).order('created_at')
    if (queryError) setError(queryError.message)
    setItems((data ?? []) as unknown as OrderItem[])
    setItemsLoading(false)
  }

  useEffect(() => { void loadBaseData() }, [businessId])

  const filtered = useMemo(() => {
    const term = query.trim().toLocaleLowerCase('es-MX')
    if (!term) return orders
    return orders.filter((order) => [order.folio, order.status, order.priority, order.customer?.name].filter(Boolean).some((value) => String(value).toLocaleLowerCase('es-MX').includes(term)))
  }, [orders, query])

  function openCreate() {
    setEditing(null)
    setForm({ customer_id: customers[0]?.id ?? '', folio: generatedFolio(), status: 'draft', priority: 'normal', promised_at: '', discount: '0', tax: '0', delivery_fee: '0', notes: '' })
    setShowForm(true)
  }

  function openEdit(order: Order) {
    setEditing(order)
    setForm({ customer_id: order.customer_id, folio: order.folio, status: order.status, priority: order.priority, promised_at: localDateTimeValue(order.promised_at), discount: String(order.discount ?? 0), tax: String(order.tax ?? 0), delivery_fee: String(order.delivery_fee ?? 0), notes: order.notes ?? '' })
    setShowForm(true)
  }

  async function saveOrder(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase) return
    setSaving(true)
    setError(null)
    const payload = {
      business_id: businessId,
      customer_id: form.customer_id,
      folio: form.folio.trim(),
      status: form.status,
      priority: form.priority,
      promised_at: form.promised_at ? new Date(form.promised_at).toISOString() : null,
      discount: Number(form.discount || 0),
      tax: Number(form.tax || 0),
      delivery_fee: Number(form.delivery_fee || 0),
      notes: form.notes.trim() || null,
      created_by: userId,
      updated_at: new Date().toISOString(),
    }

    const operation = editing
      ? supabase.from('orders').update(payload).eq('id', editing.id).eq('business_id', businessId)
      : supabase.from('orders').insert(payload).select('id').single()

    const { data, error: saveError } = await operation
    if (saveError) {
      setError(saveError.message)
      setSaving(false)
      return
    }

    setShowForm(false)
    setSaving(false)
    await loadBaseData()
    if (!editing && data && 'id' in data) {
      const created = await supabase.from('orders').select('id,business_id,customer_id,folio,status,priority,promised_at,delivered_at,subtotal,discount,tax,delivery_fee,total,notes,created_at,customer:customers(name)').eq('id', String(data.id)).single()
      if (created.data) {
        setSelected(created.data as unknown as Order)
        await loadItems(String(data.id))
      }
    }
  }

  async function openDetail(order: Order) {
    setSelected(order)
    await loadItems(order.id)
  }

  async function addItem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !selected) return
    setSavingItem(true)
    setError(null)
    const { error: saveError } = await supabase.from('order_items').insert({
      business_id: businessId,
      order_id: selected.id,
      product_id: itemForm.product_id,
      description: itemForm.description.trim() || null,
      quantity: Number(itemForm.quantity),
      unit_price: Number(itemForm.unit_price),
      discount: Number(itemForm.discount || 0),
      promised_at: itemForm.promised_at ? new Date(itemForm.promised_at).toISOString() : null,
    })
    if (saveError) {
      setError(saveError.message)
      setSavingItem(false)
      return
    }
    setShowItemForm(false)
    setSavingItem(false)
    setItemForm({ product_id: products[0]?.id ?? '', description: '', quantity: '1', unit_price: '0', discount: '0', promised_at: '' })
    await loadItems(selected.id)
    await loadBaseData()
    const refreshed = await supabase.from('orders').select('id,business_id,customer_id,folio,status,priority,promised_at,delivered_at,subtotal,discount,tax,delivery_fee,total,notes,created_at,customer:customers(name)').eq('id', selected.id).single()
    if (refreshed.data) setSelected(refreshed.data as unknown as Order)
  }

  function beginAddItem() {
    setItemForm({ product_id: products[0]?.id ?? '', description: '', quantity: '1', unit_price: '0', discount: '0', promised_at: '' })
    setShowItemForm(true)
  }

  return (
    <div>
      <div className="page-heading page-heading--actions">
        <div><span className="eyebrow">Comercial</span><h1>Pedidos</h1><p>Seguimiento de pedidos y sus partidas de producción.</p></div>
        <button className="primary-button primary-button--auto" onClick={openCreate} disabled={customers.length === 0}><Plus size={18} /> Nuevo pedido</button>
      </div>
      {customers.length === 0 && !loading && <div className="notice">Para crear un pedido primero registra al menos un cliente activo.</div>}
      {error && <div className="notice notice--error">{error}</div>}

      <div className="toolbar">
        <label className="search-field"><Search size={18} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar folio, cliente, estado o prioridad" /></label>
        <span className="toolbar__count">{filtered.length} pedido{filtered.length === 1 ? '' : 's'}</span>
      </div>

      <div className="data-card">
        {loading ? <div className="empty-state">Cargando pedidos…</div> : filtered.length === 0 ? (
          <div className="empty-state"><ClipboardList size={30} /><strong>No hay pedidos que mostrar</strong><span>Crea el primero o cambia la búsqueda.</span></div>
        ) : (
          <div className="data-list">
            {filtered.map((order) => (
              <button key={order.id} className="data-row" onClick={() => void openDetail(order)}>
                <div className="data-row__avatar"><ShoppingBag size={18} /></div>
                <div className="data-row__main"><strong>{order.folio}</strong><span>{order.customer?.name ?? 'Cliente'}</span></div>
                <div className="data-row__meta"><strong>{money.format(toNumber(order.total))}</strong><span className="badge">{order.status}</span></div>
              </button>
            ))}
          </div>
        )}
      </div>

      {selected && (
        <div className="drawer-backdrop" onClick={() => setSelected(null)}>
          <aside className="detail-drawer detail-drawer--wide" onClick={(event) => event.stopPropagation()}>
            <div className="drawer-header">
              <div><span className="eyebrow">Pedido</span><h2>{selected.folio}</h2><p>{selected.customer?.name}</p></div>
              <button className="icon-button" onClick={() => setSelected(null)} aria-label="Cerrar"><X size={20} /></button>
            </div>
            <div className="order-summary-grid">
              <div><span>Estado</span><strong>{selected.status}</strong></div>
              <div><span>Prioridad</span><strong>{selected.priority}</strong></div>
              <div><span>Total</span><strong>{money.format(toNumber(selected.total))}</strong></div>
              <div><span>Prometido</span><strong>{selected.promised_at ? new Date(selected.promised_at).toLocaleString('es-MX') : 'Sin fecha'}</strong></div>
            </div>
            <div className="drawer-actions"><button className="secondary-button" onClick={() => { setSelected(null); openEdit(selected) }}><Pencil size={17} /> Editar pedido</button><button className="primary-button primary-button--auto" onClick={beginAddItem} disabled={products.length === 0}><PackagePlus size={17} /> Agregar partida</button></div>
            {products.length === 0 && <div className="notice">Para agregar partidas primero debe existir un producto activo en Catálogo.</div>}
            <div className="section-heading"><div><span className="eyebrow">Contenido</span><h3>Partidas</h3></div><strong>{items.length}</strong></div>
            {itemsLoading ? <div className="empty-state">Cargando partidas…</div> : items.length === 0 ? <div className="empty-state empty-state--compact">Este pedido todavía no tiene partidas.</div> : (
              <div className="line-items">
                {items.map((item) => <div className="line-item" key={item.id}><div><strong>{item.product?.name ?? 'Producto'}</strong><span>{item.description || item.status}</span></div><div><span>{toNumber(item.quantity)} × {money.format(toNumber(item.unit_price))}</span><strong>{money.format(toNumber(item.line_total))}</strong></div></div>)}
              </div>
            )}
            {selected.notes && <div className="detail-notes"><span className="eyebrow">Notas</span><p>{selected.notes}</p></div>}
          </aside>
        </div>
      )}

      {showForm && (
        <div className="modal-backdrop" onClick={() => setShowForm(false)}><div className="form-modal" onClick={(event) => event.stopPropagation()}>
          <div className="drawer-header"><div><span className="eyebrow">{editing ? 'Editar' : 'Alta'}</span><h2>{editing ? editing.folio : 'Nuevo pedido'}</h2></div><button className="icon-button" onClick={() => setShowForm(false)}><X size={20} /></button></div>
          <form className="entity-form" onSubmit={saveOrder}>
            <div className="form-grid">
              <label>Cliente<select required value={form.customer_id} onChange={(event) => setForm({ ...form, customer_id: event.target.value })}><option value="">Selecciona un cliente</option>{customers.map((customer) => <option value={customer.id} key={customer.id}>{customer.name}</option>)}</select></label>
              <label>Folio<input required value={form.folio} onChange={(event) => setForm({ ...form, folio: event.target.value })} /></label>
              <label>Estado<select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })}><option value="draft">Borrador</option><option value="confirmed">Confirmado</option><option value="in_production">En producción</option><option value="ready">Listo</option><option value="delivered">Entregado</option><option value="cancelled">Cancelado</option></select></label>
              <label>Prioridad<select value={form.priority} onChange={(event) => setForm({ ...form, priority: event.target.value })}><option value="low">Baja</option><option value="normal">Normal</option><option value="high">Alta</option><option value="urgent">Urgente</option></select></label>
              <label className="form-span-2">Fecha prometida<input type="datetime-local" value={form.promised_at} onChange={(event) => setForm({ ...form, promised_at: event.target.value })} /></label>
              <label>Descuento<input min="0" step="0.01" type="number" value={form.discount} onChange={(event) => setForm({ ...form, discount: event.target.value })} /></label>
              <label>Impuesto<input min="0" step="0.01" type="number" value={form.tax} onChange={(event) => setForm({ ...form, tax: event.target.value })} /></label>
              <label className="form-span-2">Costo de entrega<input min="0" step="0.01" type="number" value={form.delivery_fee} onChange={(event) => setForm({ ...form, delivery_fee: event.target.value })} /></label>
              <label className="form-span-2">Notas<textarea rows={4} value={form.notes} onChange={(event) => setForm({ ...form, notes: event.target.value })} /></label>
            </div>
            <div className="form-actions"><button type="button" className="secondary-button" onClick={() => setShowForm(false)}>Cancelar</button><button className="primary-button primary-button--auto" disabled={saving}>{saving ? 'Guardando…' : 'Guardar pedido'}</button></div>
          </form>
        </div></div>
      )}

      {showItemForm && selected && (
        <div className="modal-backdrop" onClick={() => setShowItemForm(false)}><div className="form-modal form-modal--small" onClick={(event) => event.stopPropagation()}>
          <div className="drawer-header"><div><span className="eyebrow">{selected.folio}</span><h2>Nueva partida</h2></div><button className="icon-button" onClick={() => setShowItemForm(false)}><X size={20} /></button></div>
          <form className="entity-form" onSubmit={addItem}>
            <div className="form-grid">
              <label className="form-span-2">Producto<select required value={itemForm.product_id} onChange={(event) => setItemForm({ ...itemForm, product_id: event.target.value })}><option value="">Selecciona un producto</option>{products.map((product) => <option value={product.id} key={product.id}>{product.name}</option>)}</select></label>
              <label>Cantidad<input required min="0.001" step="0.001" type="number" value={itemForm.quantity} onChange={(event) => setItemForm({ ...itemForm, quantity: event.target.value })} /></label>
              <label>Precio unitario<input required min="0" step="0.01" type="number" value={itemForm.unit_price} onChange={(event) => setItemForm({ ...itemForm, unit_price: event.target.value })} /></label>
              <label>Descuento de partida<input min="0" step="0.01" type="number" value={itemForm.discount} onChange={(event) => setItemForm({ ...itemForm, discount: event.target.value })} /></label>
              <label><CalendarClock size={14} /> Prometido<input type="datetime-local" value={itemForm.promised_at} onChange={(event) => setItemForm({ ...itemForm, promised_at: event.target.value })} /></label>
              <label className="form-span-2">Descripción<input value={itemForm.description} onChange={(event) => setItemForm({ ...itemForm, description: event.target.value })} placeholder="Ej. Playera negra talla M, impresión al frente" /></label>
            </div>
            <div className="form-actions"><button type="button" className="secondary-button" onClick={() => setShowItemForm(false)}>Cancelar</button><button className="primary-button primary-button--auto" disabled={savingItem}>{savingItem ? 'Agregando…' : 'Agregar partida'}</button></div>
          </form>
        </div></div>
      )}
    </div>
  )
}
