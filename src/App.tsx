import { FormEvent, useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import {
  Boxes,
  Building2,
  ChevronRight,
  CircleDollarSign,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  Menu,
  PackageCheck,
  ReceiptText,
  ShoppingCart,
  Users,
  WalletCards,
  X,
} from 'lucide-react'
import { isSupabaseConfigured, supabase } from './lib/supabase'
import { CustomersPage } from './modules/CustomersPage'
import { OrdersPage } from './modules/OrdersPage'
import { InventoryPage } from './modules/InventoryPage'
import { PurchasesPage } from './modules/PurchasesPage'
import { FinancePage } from './modules/FinancePage'
import { SuppliersPage } from './modules/SuppliersPage'
import './modules/modules.css'

type Section = 'dashboard' | 'orders' | 'customers' | 'inventory' | 'purchases' | 'finance' | 'suppliers'

type DashboardSummary = {
  business_id: string
  order_value: number | string | null
  confirmed_payments: number | string | null
  business_expenses: number | string | null
  accounts_receivable: number | string | null
  cash_position: number | string | null
}

const sections: Array<{ id: Section; label: string; icon: typeof LayoutDashboard }> = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'orders', label: 'Pedidos', icon: ClipboardList },
  { id: 'customers', label: 'Clientes', icon: Users },
  { id: 'inventory', label: 'Inventario', icon: Boxes },
  { id: 'purchases', label: 'Compras', icon: ShoppingCart },
  { id: 'finance', label: 'Finanzas', icon: WalletCards },
  { id: 'suppliers', label: 'Proveedores', icon: PackageCheck },
]

const money = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 })

function numberValue(value: number | string | null | undefined) {
  const parsed = Number(value ?? 0)
  return Number.isFinite(parsed) ? parsed : 0
}

export default function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [authLoading, setAuthLoading] = useState(true)
  const [businessId, setBusinessId] = useState<string | null>(null)
  const [businessName, setBusinessName] = useState('Moore Print')
  const [membershipLoading, setMembershipLoading] = useState(false)
  const [section, setSection] = useState<Section>('dashboard')
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    if (!supabase) { setAuthLoading(false); return }
    void supabase.auth.getSession().then(({ data }) => { setSession(data.session); setAuthLoading(false) })
    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      if (!nextSession) { setBusinessId(null); setBusinessName('Moore Print') }
    })
    return () => listener.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!supabase || !session) return
    let active = true
    setMembershipLoading(true)
    void (async () => {
      const { data: membership, error } = await supabase
        .from('business_members').select('business_id').eq('user_id', session.user.id).eq('active', true).limit(1).maybeSingle()
      if (!active) return
      if (error || !membership?.business_id) { setBusinessId(null); setMembershipLoading(false); return }
      setBusinessId(membership.business_id)
      const { data: business } = await supabase.from('businesses').select('name').eq('id', membership.business_id).maybeSingle()
      if (active && business?.name) setBusinessName(business.name)
      if (active) setMembershipLoading(false)
    })()
    return () => { active = false }
  }, [session])

  if (!isSupabaseConfigured) return <ConfigurationScreen />
  if (authLoading) return <LoadingScreen text="Preparando Moore Print Finanzas…" />
  if (!session) return <LoginScreen />
  if (membershipLoading) return <LoadingScreen text="Validando acceso al negocio…" />
  if (!businessId) return <MembershipPending email={session.user.email ?? ''} />

  return (
    <div className="app-shell">
      <aside className={`sidebar ${menuOpen ? 'sidebar--open' : ''}`}>
        <div className="brand">
          <div className="brand__mark">MP</div>
          <div><strong>Moore Print</strong><span>Finanzas</span></div>
          <button className="icon-button sidebar__close" onClick={() => setMenuOpen(false)} aria-label="Cerrar menú"><X size={20} /></button>
        </div>
        <nav className="nav-list" aria-label="Navegación principal">
          {sections.map((item) => {
            const Icon = item.icon
            return <button key={item.id} className={`nav-item ${section === item.id ? 'nav-item--active' : ''}`} onClick={() => { setSection(item.id); setMenuOpen(false) }}><Icon size={19} /><span>{item.label}</span><ChevronRight size={16} className="nav-item__chevron" /></button>
          })}
        </nav>
        <div className="sidebar__footer">
          <span className="eyebrow">Sesión</span><strong>{session.user.email}</strong>
          <button className="logout-button" onClick={() => void supabase?.auth.signOut()}><LogOut size={17} /> Cerrar sesión</button>
        </div>
      </aside>
      {menuOpen && <button className="sidebar-overlay" onClick={() => setMenuOpen(false)} aria-label="Cerrar menú" />}
      <main className="main-area">
        <header className="topbar">
          <button className="icon-button mobile-menu" onClick={() => setMenuOpen(true)} aria-label="Abrir menú"><Menu size={22} /></button>
          <div><span className="eyebrow">Negocio activo</span><strong>{businessName}</strong></div>
          <div className="topbar__avatar">{session.user.email?.slice(0, 1).toUpperCase() ?? 'M'}</div>
        </header>
        <section className="content-area">
          {section === 'dashboard' && <Dashboard businessId={businessId} />}
          {section === 'customers' && <CustomersPage businessId={businessId} />}
          {section === 'orders' && <OrdersPage businessId={businessId} userId={session.user.id} />}
          {section === 'inventory' && <InventoryPage businessId={businessId} userId={session.user.id} />}
          {section === 'purchases' && <PurchasesPage businessId={businessId} userId={session.user.id} />}
          {section === 'finance' && <FinancePage businessId={businessId} userId={session.user.id} />}
          {section === 'suppliers' && <SuppliersPage businessId={businessId} userId={session.user.id} />}
        </section>
      </main>
    </div>
  )
}

function Dashboard({ businessId }: { businessId: string }) {
  const [data, setData] = useState<DashboardSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!supabase) return
    let active = true
    setLoading(true); setError(null)
    void supabase.from('dashboard_financial_summary').select('business_id,order_value,confirmed_payments,business_expenses,accounts_receivable,cash_position').eq('business_id', businessId).maybeSingle().then(({ data: summary, error: queryError }) => {
      if (!active) return
      if (queryError) setError(queryError.message)
      setData(summary as DashboardSummary | null); setLoading(false)
    })
    return () => { active = false }
  }, [businessId])

  const metrics = [
    ['Valor de pedidos', numberValue(data?.order_value), ReceiptText, 'Pedidos no cancelados'],
    ['Pagos confirmados', numberValue(data?.confirmed_payments), CircleDollarSign, 'Cobros registrados'],
    ['Cuentas por cobrar', numberValue(data?.accounts_receivable), WalletCards, 'Saldo pendiente'],
    ['Posición de efectivo', numberValue(data?.cash_position), Building2, 'Saldos de cuentas activas'],
  ] as const
  const expenses = numberValue(data?.business_expenses)
  const payments = numberValue(data?.confirmed_payments)

  return <>
    <div className="page-heading"><div><span className="eyebrow">Resumen operativo</span><h1>Dashboard</h1><p>Información consolidada desde Supabase y protegida por RLS.</p></div></div>
    {error && <div className="notice notice--error">No se pudo cargar el resumen: {error}</div>}
    <div className="metric-grid">
      {metrics.map(([label, value, Icon, note]) => <article className="metric-card" key={label}><div className="metric-card__icon"><Icon size={21} /></div><span>{label}</span><strong>{loading ? '—' : money.format(value)}</strong><small>{note}</small></article>)}
    </div>
    <div className="dashboard-grid">
      <article className="panel"><div className="panel__heading"><div><span className="eyebrow">Flujo registrado</span><h2>Resultado operativo simple</h2></div></div><div className="balance-row"><span>Pagos confirmados</span><strong>{loading ? '—' : money.format(payments)}</strong></div><div className="balance-row"><span>Gastos del negocio pagados</span><strong>{loading ? '—' : money.format(expenses)}</strong></div><div className="balance-row balance-row--total"><span>Diferencia</span><strong>{loading ? '—' : money.format(payments - expenses)}</strong></div><p className="panel__note">Lectura rápida de cobros confirmados menos gastos del negocio.</p></article>
      <article className="panel panel--accent"><span className="eyebrow">Operación</span><h2>Módulos principales activos</h2><p>Clientes, pedidos, inventario, compras, finanzas y proveedores ya trabajan directamente sobre el backend protegido.</p><div className="status-pill"><span /> Seguridad desde Supabase</div></article>
    </div>
  </>
}

function LoginScreen() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!supabase) return
    setLoading(true); setError(null)
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password })
    if (authError) setError(authError.message)
    setLoading(false)
  }
  return <main className="auth-page"><section className="auth-card"><div className="brand brand--auth"><div className="brand__mark">MP</div><div><strong>Moore Print</strong><span>Finanzas</span></div></div><span className="eyebrow">Acceso interno</span><h1>Administra el negocio desde un solo lugar.</h1><p>Pedidos, inventario, compras, costos y finanzas conectados a la misma base.</p><form onSubmit={handleSubmit} className="auth-form"><label>Correo<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required autoComplete="email" /></label><label>Contraseña<input type="password" value={password} onChange={(event) => setPassword(event.target.value)} required autoComplete="current-password" /></label>{error && <div className="notice notice--error">{error}</div>}<button className="primary-button" disabled={loading}>{loading ? 'Ingresando…' : 'Iniciar sesión'}</button></form></section><aside className="auth-visual"><span className="eyebrow">Moore Print</span><h2>Operación clara.<br />Finanzas confiables.</h2><p>La seguridad y los permisos se validan en la base mediante RLS.</p></aside></main>
}

function ConfigurationScreen() {
  return <main className="center-page"><section className="state-card"><div className="brand brand--auth"><div className="brand__mark">MP</div><div><strong>Moore Print</strong><span>Finanzas</span></div></div><h1>Falta configurar Supabase</h1><p>Crea <code>.env.local</code> a partir de <code>.env.example</code> y define únicamente la URL y la Publishable Key.</p><div className="notice">Nunca uses <code>service_role</code> en el frontend.</div></section></main>
}

function MembershipPending({ email }: { email: string }) {
  return <main className="center-page"><section className="state-card"><div className="state-card__icon"><Users size={28} /></div><span className="eyebrow">Cuenta autenticada</span><h1>Falta asociar esta cuenta a Moore Print.</h1><p>{email}</p><p>La cuenta todavía no tiene una membresía activa en <code>business_members</code>.</p><button className="secondary-button" onClick={() => void supabase?.auth.signOut()}>Usar otra cuenta</button></section></main>
}

function LoadingScreen({ text }: { text: string }) {
  return <main className="center-page"><div className="loading-ring" /><p>{text}</p></main>
}
