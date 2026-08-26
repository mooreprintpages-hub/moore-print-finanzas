import { useState } from 'react'
import { InventoryPage } from './InventoryPage'
import { InventoryAdvancedPage } from './InventoryAdvancedPage'
import './modules.css'

type Tab='stock'|'advanced'
export function InventoryHubPage({businessId,userId}:{businessId:string;userId:string}){
 const [tab,setTab]=useState<Tab>('stock')
 return <>
  <div className="page-heading"><div><span className="eyebrow">Control de materiales</span><h1>Inventario</h1><p>Existencias, movimientos, lotes, reservas y ajustes en un solo lugar.</p></div></div>
  <div className="module-tabs"><button className={tab==='stock'?'active':''} onClick={()=>setTab('stock')}>Existencias</button><button className={tab==='advanced'?'active':''} onClick={()=>setTab('advanced')}>Movimientos, lotes y reservas</button></div>
  {tab==='stock'?<InventoryPage businessId={businessId} userId={userId}/>:<InventoryAdvancedPage businessId={businessId} userId={userId}/>} 
 </>
}
