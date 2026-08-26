import { useState } from 'react'
import { OperationsPage } from './OperationsPage'
import { OperationsDetailedPage } from './OperationsDetailedPage'
import './modules.css'

type Tab='main'|'detail'
export function OperationsHubPage({businessId,userId}:{businessId:string;userId:string}){
 const [tab,setTab]=useState<Tab>('main')
 return <>
  <div className="page-heading"><div><span className="eyebrow">Trabajo diario</span><h1>Operaciones</h1><p>Seguimiento rápido y detalle operativo en una sola entrada.</p></div></div>
  <div className="module-tabs"><button className={tab==='main'?'active':''} onClick={()=>setTab('main')}>Vista rápida</button><button className={tab==='detail'?'active':''} onClick={()=>setTab('detail')}>Detalle</button></div>
  {tab==='main'?<OperationsPage businessId={businessId} userId={userId}/>:<OperationsDetailedPage businessId={businessId}/>} 
 </>
}
