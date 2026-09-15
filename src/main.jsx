import React from 'react';
import {createRoot} from 'react-dom/client';
import {Search, ArrowRight, Shirt, Coffee, Flag, Image as ImageIcon, Sparkles, MessageCircle} from 'lucide-react';
import './styles.css';

const categories=[
 {name:'Playeras',desc:'DTF, sublimación y más',icon:Shirt},
 {name:'Tazas',desc:'Personalizadas para cualquier ocasión',icon:Coffee},
 {name:'Lonas',desc:'Impresión para tu negocio o evento',icon:ImageIcon},
 {name:'Banderas',desc:'Haz que tu negocio destaque',icon:Flag},
];
const products=[
 {name:'Playera personalizada',category:'Playeras',price:'Desde $---',tag:'Más vendido'},
 {name:'Taza personalizada',category:'Tazas',price:'Desde $---',tag:'Popular'},
 {name:'Lona impresa',category:'Publicidad',price:'Cotiza por medida',tag:'Recomendado'},
];
function App(){return <div className="app">
<header><a className="brand" href="#">MOORE <b>PRINT</b></a><nav><a href="#catalogo">Productos</a><a href="#como">Cómo funciona</a><a className="quote" href="#catalogo">Cotizar</a></nav></header>
<main>
<section className="hero"><div className="eyebrow"><Sparkles size={16}/> Impresión y personalizados</div><h1>Tu idea.<br/><span>Nosotros la imprimimos.</span></h1><p>Explora nuestros productos, personalízalos y obtén una cotización rápida desde tu celular.</p><div className="actions"><a className="primary" href="#catalogo">Cotiza ahora <ArrowRight size={18}/></a><a className="secondary" href="#catalogo">Ver productos</a></div><div className="search"><Search size={20}/><input placeholder="¿Qué quieres personalizar?"/></div></section>
<section id="catalogo" className="section"><div className="sectionTitle"><div><small>EXPLORA</small><h2>¿Qué quieres crear?</h2></div><a href="#productos">Ver todo <ArrowRight size={16}/></a></div><div className="categories">{categories.map(({name,desc,icon:Icon})=><button className="category" key={name}><span><Icon/></span><strong>{name}</strong><small>{desc}</small><ArrowRight className="go"/></button>)}</div></section>
<section id="productos" className="section products"><div className="sectionTitle"><div><small>FAVORITOS</small><h2>Los más buscados</h2></div></div><div className="productGrid">{products.map((p,i)=><article className="product" key={p.name}><div className={'productVisual v'+i}><span>{p.tag}</span><div className="placeholder">MOORE<br/>PRINT</div></div><div className="productInfo"><small>{p.category}</small><h3>{p.name}</h3><p>{p.price}</p><button>Cotizar <ArrowRight size={16}/></button></div></article>)}</div></section>
<section id="como" className="how"><small>FÁCIL Y RÁPIDO</small><h2>Cotiza en minutos</h2><div className="steps"><div><b>01</b><h3>Elige</h3><p>Selecciona el producto que necesitas.</p></div><div><b>02</b><h3>Personaliza</h3><p>Indica cantidad, medida y opciones.</p></div><div><b>03</b><h3>Cotiza</h3><p>Conoce tu precio y solicita tu pedido.</p></div></div></section>
</main><a className="whatsapp" href="#catalogo" aria-label="Cotizar"><MessageCircle/></a><footer><b>MOORE PRINT</b><span>Personaliza · Cotiza · Ordena</span></footer>
</div>}
createRoot(document.getElementById('root')).render(<App/>);
