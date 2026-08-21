import { FormEvent, useEffect, useMemo, useState } from 'react'
import { ClipboardList, Eye, Plus, Search, X } from 'lucide-react'
import { supabase } from '../lib/supabase'

type CustomerOption = { id: string; name: string }
type ProductOption = { id: string; name: string; base_price: number | string | null }

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
  customers: { name: string } | null
}

type OrderItem = {
  id: string
  product_id: string
  product_variant_id: string | null
  description: string | null
  quantity: number | string
  unit_price: number | string
  discount: number | string
  line_total: number | string | null
  status: string
  products: { name: string } | null
}

const money = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })
const dateTime = new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium', timeStyle: 'short' })

export function OrdersModule({ businessId, userId }: { businessId: string; userId: string }) {
  const [orders, setOrders] = useState<Order[]>([])
  const [customers, setCustomers] = useState<CustomerOption[]>([])
  const [products, setProducts] = useState<ProductOption[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<Order | null>(null)
  const [items, setItems] = useState<OrderItem[]>([])
  const [detailLoading, setDetailLoading] = useState(false)
  const [newOrderOpen, setNewOrderOpen] = useState(false)
  const [newItemOpen, setNewItemOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [orderForm, setOrderForm] = useState({ customer_id: '', folio: '', priority: 'normal', promised_at: '', notes: '' })
  const [itemForm, setItemForm] = useState({ product_id: '', description: '', quantity: '1', unit_price: '', discount: '0' })

  async function loadBase() {
    if (!supabase) return
    setLoading(true)
    setError(null)
    const [ordersResult, customersResult, productsResult] = await Promise.all([
      supabase
        .from('orders')
        .select('id,business_id,customer_id,folio,status,priority,promised_at,delivered_at,subtotal,discount,tax,delivery_fee,total,notes,created_at,customers(name)')
        .eq('business_id', businessId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false }),
      supabase.from('customers').select('id,name').eq('business_id', businessId).eq('active', true).is('deleted_at', null).order('name'),
      supabase.from('products').select('id,name,base_price').eq('business_id', businessId).eq('active', true).is('deleted_at', null).order('name'),
    ])

    const firstError = ordersResult.error || customersResult.error || productsResult.error
    if (firstError) setError(firstError.message)
    setOrders((ordersResult.data ?? []) as unknown as Order[])
    setCustomers((customersResult.data ?? []) as CustomerOption[])
    setProducts((productsResult.data ?? []) as ProductOption[])
    setLoading(false)
  }

  useEffect(() => { void loadBase() }, [businessId])

  const filtered = useMemo(() => {
    const q = search.trim().toLocaleLowerCase('es-MX')
    if (!q) return orders
    return orders.filter((order) => [order.folio, order.customers?.name, order.status].filter(Boolean).some((value) => value!.toLocaleLowerCase('es-MX').includes(q)))
  }, [orders, search])

  async function openDetail(order: Order) {
    if (!supabase) return
    setSelected(order)
    setDetailLoading(true)
    const { data, error: itemsError } = await supabase
      .from('order_items')
      .select('id,product_id,product_variant_id,description,quantity,unit_price,discount,line_total,status,products(name)')
      .eq('order_id', order.id)
      .eq('business_id', businessId)
      .order('created_at')
    if (itemsError) setError(itemsError.message)
    setItems((data ?? []) as unknown as OrderItem[])
    setDetailLoading(false)
  }

  async function createOrder(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !orderForm.customer_id || !orderForm.folio.trim()) return
    setSaving(true)
    setError(null)
    const { data, error: insertError } = await supabase
      .from('orders')
      .insert({
        business_id: businessId,
        customer_id: orderForm.customer_id,
        folio: orderForm.folio.trim(),
        priority: orderForm.priority,
        promised_at: orderForm.promised_at ? new Date(orderForm.promised_at).toISOString() : null,
        notes: orderForm.notes.trim() || null,
        created_by: userId,
      })
      .select('id,business_id,customer_id,folio,status,priority,promised_at,delivered_at,subtotal,discount,tax,delivery_fee,total,notes,created_at,customers(name)')
      .single()

    if (insertError) {
      setError(insertError.message)
      setSaving(false)
      return
    }

    setNewOrderOpen(false)
    setOrderForm({ customer_id: '', folio: '', priority: 'normal', promised_at: '', notes: '' })
    await loadBase()
    if (data) await openDetail(data as unknown as Order)
    setSaving(false)
  }

  function chooseProduct(productId: string) {
    const product = products.find((item) => item.id === productId)
    setItemForm({ ...itemForm, product_id: productId, unit_price: product?.base_price == null ? '' : String(product.base_price) })
  }

  async function addItem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !selected || !itemForm.product_id) return
    const quantity = Number(itemForm.quantity)
    const unitPrice = Number(itemForm.unit_price)
    const discount = Number(itemForm.discount || 0)
    if (!(quantity > 0) || unitPrice < 0 || discount < 0) return

    setSaving(true)
    setError(null)
    const { error: insertError } = await supabase.from('order_items').insert({
      business_id: businessId,
      order_id: selected.id,
      product_id: itemForm.product_id,
      description: itemForm.description.trim() || null,
      quantity,
      unit_price: unitPrice,
      discount,
    })

    if (insertError) {
      setError(insertError.message)
      setSaving(false)
      return
    }

    setNewItemOpen(false)
    setItemForm({ product_id: '', description: '', quantity: '1', unit_price: '', discount: '0' })
    await loadBase()
    const refreshed = orders.find((order) => order.id === selected.id) ?? selected
    await openDetail(refreshed)
    setSaving(false)
  }

  async function updateOrderStatus(status: string) {
    if (!supabase || !selected) return
    setSaving(true)
    const patch: Record<string, string | null> = { status, updated_at: new Date().toISOString() }
    if (status === 'delivered') patch.delivered_at = new Date().toISOString()
    const { error: updateError } = await supabase.from('orders').update(patch).eq('id', selected.id).eq('business_id', businessId)
    if (updateError) setError(updateError.message)
    await loadBase()
    setSelected((current) => current ? { ...current, status, delivered_at: status === 'delivered' ? new Date().toISOString() : current.delivered_at } : null)
    setSaving(false)
  }

  return (
    <>
      <div className="page-heading page-heading--actions">
        <div><span className="eyebrow">Comercial</span><h1>Pedidos</h1><p>Seguimiento operativo, partidas y totales calculados desde Supabase.</p></div>
        <button className="primary-button primary-button--inline" onClick={() => setNewOrderOpen(true)}><Plus size={18} /> Nuevo pedido</button>
      </div>

      <div className="toolbar">
        <label className="search-box"><Search size={18} /><input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Buscar por folio, cliente o estado" /></label>
        <span className="toolbar__count">{filtered.length} pedido{filtered.length === 1 ? '' : 's'}</span>
      </div>
      {error && <div className="notice notice--error">{error}</div>}

      <div className="data-card">
        {loading ? <div className="empty-state">Cargando pedidos…</div> : filtered.length === 0 ? (
          <div className="empty-state"><ClipboardList size={30} /><strong>No hay pedidos que mostrar</strong><span>{search ? 'Prueba con otra búsqueda.' : 'Crea el primer pedido para comenzar.'}</span></div>
        ) : (
          <div className="table-scroll"><table className="data-table"><thead><tr><th>Folio</th><th>Cliente</th><th>Estado</th><th>Promesa</th><th>Total</th><th /></tr></thead><tbody>
            {filtered.map((order) => <tr key={order.id} onClick={() => void openDetail(order)}><td><strong>{order.folio}</strong><small>{order.priority === 'urgent' ? 'Urgente' : 'Prioridad normal'}</small></td><td>{order.customers?.name ?? '—'}</td><td><span className="tag">{statusLabel(order.status)}</span></td><td>{order.promised_at ? dateTime.format(new Date(order.promised_at)) : '—'}</td><td><strong>{money.format(Number(order.total || 0))}</strong></td><td><button className="icon-button" onClick={(event) => { event.stopPropagation(); void openDetail(order) }}><Eye size={17} /></button></td></tr>)}
          </tbody></table></div>
        )}
      </div>

      {selected && (
        <div className="drawer-backdrop" onClick={() => setSelected(null)}><aside className="drawer drawer--wide" onClick={(e) => e.stopPropagation()}>
          <div className="drawer__header"><div><span className="eyebrow">Pedido</span><h2>{selected.folio}</h2><p>{selected.customers?.name}</p></div><button className="icon-button" onClick={() => setSelected(null)}><X size={20} /></button></div>
          <div className="detail-grid"><Detail label="Estado" value={statusLabel(selected.status)} /><Detail label="Prioridad" value={selected.priority === 'urgent' ? 'Urgente' : 'Normal'} /><Detail label="Promesa" value={selected.promised_at ? dateTime.format(new Date(selected.promised_at)) : '—'} /><Detail label="Total" value={money.format(Number(selected.total || 0))} /></div>
          <div className="drawer-section"><div className="drawer-section__heading"><h3>Partidas</h3><button className="secondary-button secondary-button--small" onClick={() => setNewItemOpen(true)}><Plus size={16} /> Agregar</button></div>
            {detailLoading ? <div className="empty-state empty-state--compact">Cargando partidas…</div> : items.length === 0 ? <div className="empty-state empty-state--compact">Este pedido todavía no tiene partidas.</div> : <div className="line-items">{items.map((item) => <div className="line-item" key={item.id}><div><strong>{item.products?.name ?? 'Producto'}</strong><span>{item.description || 'Sin descripción adicional'}</span></div><div><span>{Number(item.quantity)} × {money.format(Number(item.unit_price))}</span><strong>{money.format(Number(item.line_total || 0))}</strong></div></div>)}</div>}
          </div>
          <div className="totals-card"><div><span>Subtotal</span><strong>{money.format(Number(selected.subtotal || 0))}</strong></div><div><span>Descuento</span><strong>{money.format(Number(selected.discount || 0))}</strong></div><div><span>Entrega</span><strong>{money.format(Number(selected.delivery_fee || 0))}</strong></div><div className="totals-card__total"><span>Total</span><strong>{money.format(Number(selected.total || 0))}</strong></div></div>
          <div className="drawer-section"><h3>Cambiar estado</h3><div className="status-actions">{['draft','confirmed','in_production','ready','delivered','cancelled'].map((status) => <button key={status} className={selected.status === status ? 'status-button status-button--active' : 'status-button'} disabled={saving || selected.status === status} onClick={() => void updateOrderStatus(status)}>{statusLabel(status)}</button>)}</div></div>
        </aside></div>
      )}

      {newOrderOpen && <div className="drawer-backdrop" onClick={() => !saving && setNewOrderOpen(false)}><aside className="drawer" onClick={(e) => e.stopPropagation()}><div className="drawer__header"><div><span className="eyebrow">Alta</span><h2>Nuevo pedido</h2></div><button className="icon-button" onClick={() => setNewOrderOpen(false)}><X size={20} /></button></div><form className="form-grid" onSubmit={createOrder}>
        <label className="form-grid__wide">Cliente<select value={orderForm.customer_id} onChange={(e) => setOrderForm({ ...orderForm, customer_id: e.target.value })} required><option value="">Selecciona un cliente</option>{customers.map((customer) => <option key={customer.id} value={customer.id}>{customer.name}</option>)}</select></label>
        <label>Folio<input value={orderForm.folio} onChange={(e) => setOrderForm({ ...orderForm, folio: e.target.value })} placeholder="Ej. MP-2026-001" required /></label>
        <label>Prioridad<select value={orderForm.priority} onChange={(e) => setOrderForm({ ...orderForm, priority: e.target.value })}><option value="normal">Normal</option><option value="urgent">Urgente</option></select></label>
        <label className="form-grid__wide">Fecha prometida<input type="datetime-local" value={orderForm.promised_at} onChange={(e) => setOrderForm({ ...orderForm, promised_at: e.target.value })} /></label>
        <label className="form-grid__wide">Notas<textarea rows={3} value={orderForm.notes} onChange={(e) => setOrderForm({ ...orderForm, notes: e.target.value })} /></label>
        <div className="form-actions form-grid__wide"><button type="button" className="secondary-button" onClick={() => setNewOrderOpen(false)}>Cancelar</button><button className="primary-button primary-button--inline" disabled={saving}>{saving ? 'Creando…' : 'Crear pedido'}</button></div>
      </form></aside></div>}

      {newItemOpen && selected && <div className="drawer-backdrop drawer-backdrop--top" onClick={() => !saving && setNewItemOpen(false)}><aside className="drawer" onClick={(e) => e.stopPropagation()}><div className="drawer__header"><div><span className="eyebrow">{selected.folio}</span><h2>Agregar partida</h2></div><button className="icon-button" onClick={() => setNewItemOpen(false)}><X size={20} /></button></div><form className="form-grid" onSubmit={addItem}>
        <label className="form-grid__wide">Producto<select value={itemForm.product_id} onChange={(e) => chooseProduct(e.target.value)} required><option value="">Selecciona un producto</option>{products.map((product) => <option key={product.id} value={product.id}>{product.name}</option>)}</select></label>
        <label>Cantidad<input type="number" min="0.001" step="0.001" value={itemForm.quantity} onChange={(e) => setItemForm({ ...itemForm, quantity: e.target.value })} required /></label>
        <label>Precio unitario<input type="number" min="0" step="0.01" value={itemForm.unit_price} onChange={(e) => setItemForm({ ...itemForm, unit_price: e.target.value })} required /></label>
        <label>Descuento<input type="number" min="0" step="0.01" value={itemForm.discount} onChange={(e) => setItemForm({ ...itemForm, discount: e.target.value })} /></label>
        <label className="form-grid__wide">Descripción<textarea rows={3} value={itemForm.description} onChange={(e) => setItemForm({ ...itemForm, description: e.target.value })} /></label>
        <div className="form-actions form-grid__wide"><button type="button" className="secondary-button" onClick={() => setNewItemOpen(false)}>Cancelar</button><button className="primary-button primary-button--inline" disabled={saving}>{saving ? 'Guardando…' : 'Agregar partida'}</button></div>
      </form></aside></div>}
    </>
  )
}

function statusLabel(status: string) {
  const labels: Record<string,string> = { draft: 'Borrador', confirmed: 'Confirmado', in_production: 'En producción', ready: 'Listo', delivered: 'Entregado', cancelled: 'Cancelado' }
  return labels[status] ?? status.replaceAll('_',' ')
}

function Detail({ label, value }: { label: string; value: string }) { return <div className="detail-item"><span>{label}</span><strong>{value}</strong></div> }
