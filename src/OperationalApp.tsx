import { FormEvent, useEffect, useMemo, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { Boxes, Building2, ChevronRight, CircleDollarSign, ClipboardList, LayoutDashboard, LogOut, Menu, PackageCheck, ReceiptText, ShoppingCart, Users, WalletCards, X } from 'lucide-react'
import { isSupabaseConfigured, supabase } from './lib/supabase'
import { CustomersModule } from './modules/CustomersModule'
import { OrdersModule } from './modules/OrdersModule'
import './operations.css'

type Section = 'dashboard' | 'orders' | 'customers' | 'inventory' | 'purchases' | 'finance' | 'suppliers'
type DashboardSummary = { business_id: string; order_value: number | string | null; confirmed_payments: number | string | null; business_expenses: number | string | null; accounts_receivable: number | string | null; cash_position: number | string | null }

const sections = [
  { id: 'dashboard' as Section, label: 'Dashboard', icon: LayoutDashboard },
  { id: 'orders' as Section, label: 'Pedidos', icon: ClipboardList },
  { id: 'customers' as Section, label: 'Clientes', icon: Users },
  { id: 'inventory' as Section, label: 'Inventario', icon: Boxes },
  { id: 'purchases' as Section, label: 'Compras', icon: ShoppingCart },
  { id: 'finance' as Section, label: 'Finanzas', icon: WalletCards },
  { id: 'suppliers' as Section, label: 'Proveedores', icon: PackageCheck },
]

const money = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })
const n = (value: unknown) => Number.isFinite(Number(value ?? 0)) ? Number(value ?? 0) : 0

export default function OperationalApp() {
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
      const { data: membership, error } = await supabase.from('business_members').select('business_id').eq('user_id', session.user.id).eq('active', true).limit(1).maybeSingle()
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

  return <div className="app-shell">
    <aside className={`sidebar ${menuOpen ? 'sidebar--open' : ''}`}>
      <div className="brand"><div className="brand__mark">MP</div><div><strong>Moore Print</strong><span>Finanzas</span></div><button className="icon-button sidebar__close" onClick={() => setMenuOpen(false)}><X size={20} /></button></div>
      <nav className="nav-list">{sections.map((item) => { const Icon = item.icon; return <button key={item.id} className={`nav-item ${section === item.id ? 'nav-item--active' : ''}`} onClick={() => { setSection(item.id); setMenuOpen(false) }}><Icon size={19} /><span>{item.label}</span><ChevronRight size={16} className="nav-item__chevron" /></button> })}</nav>
      <div className="sidebar__footer"><span className="eyebrow">Sesión</span><strong>{session.user.email}</strong><button className="logout-button" onClick={() => void supabase?.auth.signOut()}><LogOut size={17} /> Cerrar sesión</button></div>
    </aside>
    {menuOpen && <button className="sidebar-overlay" onClick={() => setMenuOpen(false)} />}
    <main className="main-area">
      <header className="topbar"><button className="icon-button mobile-menu" onClick={() => setMenuOpen(true)}><Menu size={22} /></button><div><span className="eyebrow">Negocio activo</span><strong>{businessName}</strong></div><div className="topbar__avatar">{session.user.email?.slice(0,1).toUpperCase() ?? 'M'}</div></header>
      <section className="content-area">
        {section === 'dashboard' && <Dashboard businessId={businessId} />}
        {section === 'customers' && <CustomersModule businessId={businessId} />}
        {section === 'orders' && <OrdersModule businessId={businessId} userId={session.user.id} />}
        {!['dashboard','customers','orders'].includes(section) && <ModulePlaceholder section={section} />}
      </section>
    </main>
  </div>
}

function Dashboard({ businessId }: { businessId: string }) {
  const [data, setData] = useState<DashboardSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  useEffect(() => {
    if (!supabase) return
    let active = true
    setLoading(true)
    void supabase.from('dashboard_financial_summary').select('business_id,order_value,confirmed_payments,business_expenses,accounts_receivable,cash_position').eq('business_id', businessId).maybeSingle().then(({ data: result, error: queryError }) => {
      if (!active) return
      if (queryError) setError(queryError.message)
      setData(result as DashboardSummary | null); setLoading(false)
    })
    return () => { active = false }
  }, [businessId])
  const metrics = useMemo(() => [
    { label: 'Valor de pedidos', value: n(data?.order_value), icon: ReceiptText, note: 'Pedidos no cancelados' },
    { label: 'Pagos confirmados', value: n(data?.confirmed_payments), icon: CircleDollarSign, note: 'Cobros registrados' },
    { label: 'Cuentas por cobrar', value: n(data?.accounts_receivable), icon: WalletCards, note: 'Saldo pendiente' },
    { label: 'Posición de efectivo', value: n(data?.cash_position), icon: Building2, note: 'Cuentas activas' },
  ], [data])
  const expenses = n(data?.business_expenses); const payments = n(data?.confirmed_payments)
  return <><div className="page-heading"><div><span className="eyebrow">Resumen operativo</span><h1>Dashboard</h1><p>Información consolidada desde movimientos y vistas protegidas por RLS.</p></div></div>{error && <div className="notice notice--error">{error}</div>}<div className="metric-grid">{metrics.map(({ label,value,icon:Icon,note }) => <article className="metric-card" key={label}><div className="metric-card__icon"><Icon size={21} /></div><span>{label}</span><strong>{loading ? '—' : money.format(value)}</strong><small>{note}</small></article>)}</div><div className="dashboard-grid"><article className="panel"><span className="eyebrow">Flujo registrado</span><h2>Resultado operativo simple</h2><div className="balance-row"><span>Pagos confirmados</span><strong>{loading ? '—' : money.format(payments)}</strong></div><div className="balance-row"><span>Gastos pagados</span><strong>{loading ? '—' : money.format(expenses)}</strong></div><div className="balance-row balance-row--total"><span>Diferencia</span><strong>{loading ? '—' : money.format(payments-expenses)}</strong></div></article><article className="panel panel--accent"><span className="eyebrow">Frontend operativo</span><h2>Clientes y Pedidos activos</h2><p>Ya puedes consultar, crear y editar clientes, así como crear pedidos y agregar partidas.</p></article></div></>
}

function LoginScreen() {
  const [email,setEmail]=useState(''); const [password,setPassword]=useState(''); const [loading,setLoading]=useState(false); const [error,setError]=useState<string|null>(null)
  async function submit(event:FormEvent<HTMLFormElement>){ event.preventDefault(); if(!supabase)return; setLoading(true); setError(null); const {error:authError}=await supabase.auth.signInWithPassword({email,password}); if(authError)setError(authError.message); setLoading(false) }
  return <main className="auth-page"><section className="auth-card"><div className="brand brand--auth"><div className="brand__mark">MP</div><div><strong>Moore Print</strong><span>Finanzas</span></div></div><span className="eyebrow">Acceso interno</span><h1>Administra el negocio desde un solo lugar.</h1><p>Pedidos, inventario, compras, costos y finanzas conectados.</p><form className="auth-form" onSubmit={submit}><label>Correo<input type="email" value={email} onChange={(e)=>setEmail(e.target.value)} required /></label><label>Contraseña<input type="password" value={password} onChange={(e)=>setPassword(e.target.value)} required /></label>{error&&<div className="notice notice--error">{error}</div>}<button className="primary-button" disabled={loading}>{loading?'Ingresando…':'Iniciar sesión'}</button></form></section><aside className="auth-visual"><span className="eyebrow">Moore Print</span><h2>Operación clara.<br/>Finanzas confiables.</h2><p>Los permisos se validan en Supabase mediante RLS.</p></aside></main>
}

function ConfigurationScreen(){return <main className="center-page"><section className="state-card"><h1>Falta configurar Supabase</h1><p>Define <code>VITE_SUPABASE_URL</code> y <code>VITE_SUPABASE_PUBLISHABLE_KEY</code> en <code>.env.local</code>.</p></section></main>}
function MembershipPending({email}:{email:string}){return <main className="center-page"><section className="state-card"><span className="eyebrow">Cuenta autenticada</span><h1>Falta asociar esta cuenta a Moore Print.</h1><p>{email}</p><button className="secondary-button" onClick={()=>void supabase?.auth.signOut()}>Usar otra cuenta</button></section></main>}
function ModulePlaceholder({section}:{section:Section}){const current=sections.find((item)=>item.id===section)!;const Icon=current.icon;return <div className="module-placeholder"><div className="state-card__icon"><Icon size={28}/></div><span className="eyebrow">Siguiente etapa</span><h1>{current.label}</h1><p>El backend existe; la interfaz se habilitará progresivamente.</p></div>}
function LoadingScreen({text}:{text:string}){return <main className="center-page"><div className="loading-ring"/><p>{text}</p></main>}
