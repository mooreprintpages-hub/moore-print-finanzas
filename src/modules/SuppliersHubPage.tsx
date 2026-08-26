import { useState } from 'react'
import { SuppliersPage } from './SuppliersPage'
import { SupplierAdvancedPage } from './SupplierAdvancedPage'
import './modules.css'

type Tab='main'|'advanced'
export function SuppliersHubPage({businessId,userId}:{businessId:string;userId:string}){
 const [tab,setTab]=useState<Tab>('main')
 return <>
  <div className="page-heading"><div><span className="eyebrow">Compras y abastecimiento</span><h1>Proveedores</h1><p>Datos, materiales, compras, evaluaciones e incidencias desde una sola pantalla.</p></div></div>
  <div className="module-tabs"><button className={tab==='main'?'active':''} onClick={()=>setTab('main')}>Directorio y materiales</button><button className={tab==='advanced'?'active':''} onClick={()=>setTab('advanced')}>Evaluaciones e incidencias</button></div>
  {tab==='main'?<SuppliersPage businessId={businessId} userId={userId}/>:<SupplierAdvancedPage businessId={businessId}/>} 
 </>
}
