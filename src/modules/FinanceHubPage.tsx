import { useState } from 'react'
import { FinancePage } from './FinancePage'
import { FinanceAdvancedPage } from './FinanceAdvancedPage'
import { FinanceRemainingPage } from './FinanceRemainingPage'
import { FinanceAdminPage } from './FinanceAdminPage'
import { FinanceFinePage } from './FinanceFinePage'
import './modules.css'

type Tab='main'|'advanced'|'treasury'|'admin'|'detail'
const labels:Record<Tab,string>={main:'Caja y cuentas',advanced:'Control financiero',treasury:'Tesorería y cobranza',admin:'Gastos y administración',detail:'Reportes y detalle'}
export function FinanceHubPage({businessId,userId}:{businessId:string;userId:string}){
 const [tab,setTab]=useState<Tab>('main')
 return <>
  <div className="page-heading"><div><span className="eyebrow">Centro financiero</span><h1>Finanzas</h1><p>Todo el control financiero de Moore Print en un solo lugar.</p></div></div>
  <div className="module-tabs" aria-label="Secciones de finanzas">{(Object.keys(labels) as Tab[]).map(key=><button key={key} className={tab===key?'active':''} onClick={()=>setTab(key)}>{labels[key]}</button>)}</div>
  {tab==='main'&&<FinancePage businessId={businessId} userId={userId}/>} 
  {tab==='advanced'&&<FinanceAdvancedPage businessId={businessId} userId={userId}/>} 
  {tab==='treasury'&&<FinanceRemainingPage businessId={businessId} userId={userId}/>} 
  {tab==='admin'&&<FinanceAdminPage businessId={businessId} userId={userId}/>} 
  {tab==='detail'&&<FinanceFinePage businessId={businessId} userId={userId}/>} 
 </>
}
