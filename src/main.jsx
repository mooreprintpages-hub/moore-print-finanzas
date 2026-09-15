import React,{useEffect,useMemo,useState} from 'react';
import {createRoot} from 'react-dom/client';
import {Search,ArrowRight,Shirt,Coffee,Flag,Image as ImageIcon,Sparkles,MessageCircle,Package} from 'lucide-react';
import {supabase} from './lib/supabase';
import {loadCatalog} from './catalog';
import './styles.css';

const iconMap={playeras:Shirt,tazas:Coffee,lonas:ImageIcon,banderas:Flag};

function App(){
 const [catalog,setCatalog]=useState({categories:[],products:[]});
 const [loading,setLoading]=useState(true);
 const [error,setError]=useState('');
 const [search,setSearch]=useState('');
 useEffect(()=>{let active=true;loadCatalog(supabase).then(data=>{if(active)setCatalog(data)}).catch(()=>{if(active)setError('No pudimos cargar el catálogo en este momento.')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[]);
 const categoryName=useMemo(()=>Object.fromEntries(catalog.categories.map(c=>[c.id,c.name])),[catalog.categories]);
 const products=useMemo(()=>catalog.products.filter(p=>`${p.name} ${p.short_description||''}`.toLowerCase().includes(search.toLowerCase().trim())),[catalog.products,search]);
 return <div className="app">
 <header><a className="brand" href="#">MOORE <b>PRINT</b></a><nav><a href="#catalogo">Productos</a><a href="#como">Cómo funciona</a><a className="quote" href="#catalogo">Cotizar</a></nav></header>
 <main>
 <section className="hero"><div className="eyebrow"><Sparkles size={16}/> Impresión y personalizados</div><h1>Tu idea.<br/><span>Nosotros la imprimimos.</span></h1><p>Explora nuestros productos, personalízalos y obtén una cotización rápida desde tu celular.</p><div className="actions"><a className="primary" href="#catalogo">Cotiza ahora <ArrowRight size={18}/></a><a className="secondary" href="#productos">Ver productos</a></div><div className="search"><Search size={20}/><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="¿Qué quieres personalizar?"/></div></section>
 <section id="catalogo" className="section"><div className="sectionTitle"><div><small>EXPLORA</small><h2>¿Qué quieres crear?</h2></div><a href="#productos">Ver todo <ArrowRight size={16}/></a></div>{loading?<div className="catalogState">Cargando catálogo…</div>:error?<div className="catalogState">{error}</div>:catalog.categories.length===0?<div className="catalogState"><Package/><b>Estamos preparando el catálogo.</b><span>Pronto encontrarás aquí todos los productos de Moore Print.</span></div>:<div className="categories">{catalog.categories.map(c=>{const Icon=iconMap[c.slug]||Package;return <button className="category" key={c.id}><span><Icon/></span><strong>{c.name}</strong><small>{c.description||'Personaliza a tu estilo'}</small><ArrowRight className="go"/></button>})}</div>}</section>
 <section id="productos" className="section products"><div className="sectionTitle"><div><small>CATÁLOGO</small><h2>{search?'Resultados':'Nuestros productos'}</h2></div></div>{!loading&&!error&&products.length===0?<div className="catalogState"><Package/><b>{search?'No encontramos ese producto.':'Aún no hay productos publicados.'}</b><span>{search?'Prueba con otra palabra.':'Los productos aparecerán aquí al publicarlos.'}</span></div>:<div className="productGrid">{products.map((p,i)=><article className="product" key={p.id}><div className={'productVisual v'+(i%3)}>{p.featured&&<span>Destacado</span>}<div className="placeholder">MOORE<br/>PRINT</div></div><div className="productInfo"><small>{categoryName[p.category_id]||'Moore Print'}</small><h3>{p.name}</h3><p>{p.short_description||'Personalízalo a tu gusto'}</p><button>Cotizar <ArrowRight size={16}/></button></div></article>)}</div>}</section>
 <section id="como" className="how"><small>FÁCIL Y RÁPIDO</small><h2>Cotiza en minutos</h2><div className="steps"><div><b>01</b><h3>Elige</h3><p>Selecciona el producto que necesitas.</p></div><div><b>02</b><h3>Personaliza</h3><p>Indica cantidad, medida y opciones.</p></div><div><b>03</b><h3>Cotiza</h3><p>Conoce tu precio y solicita tu pedido.</p></div></div></section>
 </main><a className="whatsapp" href="#catalogo" aria-label="Cotizar"><MessageCircle/></a><footer><b>MOORE PRINT</b><span>Personaliza · Cotiza · Ordena</span></footer>
 </div>
}
createRoot(document.getElementById('root')).render(<App/>);
