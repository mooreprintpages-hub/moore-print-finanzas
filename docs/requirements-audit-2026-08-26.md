# Auditoría de requisitos originales — Moore Print Finanzas

Fecha base: 2026-08-26 · actualización continua en PR #58

Leyenda: ✅ implementado/comprobado · 🟡 parcial o pendiente de UX/validación final · ❌ faltante real

## Negocio, usuarios y permisos
- ✅ App propia para finanzas, inventario, pedidos y análisis.
- ✅ Supabase Auth, negocio y membresías.
- ✅ Roles configurables y permisos por rol/empleado.
- ✅ Reporte por empleado y consolidado en Dashboard.
- ✅ Borrado lógico y Papelera visible en Administración.
- ✅ Papelera ampliada para Clientes, Proveedores, Productos, Materiales, Compras, Pedidos, Cotizaciones y otras entidades recuperables.

## Clientes y canales
- ✅ Clientes con nombre/alias, teléfono, correo, dirección, notas y activo/inactivo.
- ✅ Múltiples teléfonos y contactos desde la interfaz, con etiquetas y roles.
- ✅ Canal de venta/cotización (local, Facebook Marketplace, Instagram, WhatsApp, otro).
- ✅ Color/etiqueta de WhatsApp por cliente agregado a backend e interfaz.

## Cotizaciones y precios
- ✅ Cotizaciones versionadas e inmutabilidad de versión enviada.
- ✅ Conversión formal Cotización → Pedido.
- ✅ Pasar a pedido / Poner en espera.
- ✅ Recibo de cotización con subtotal, descuentos, entrega, impuestos, total y anticipo sugerido.
- ✅ Encuesta/reacción de precio con Aceptado, Incómodo/caro, Negociación y Rechazado; historial mostrado en español.
- ✅ Precios base, variantes, mayoreo/menudeo/especiales y precios especiales por cliente.
- 🟡 Sugerencia automática de precio/margen según demanda: ventas/frecuencia ya reportadas, falta convertirlas en recomendación explícita.
- 🟡 Ajuste por subida de insumos: historial/costos existen, falta alerta explícita de revisión de precio cuando suba un insumo.

## Pedidos
- ✅ Folio, cliente, partidas, cantidad, precio, subtotal, descuentos, impuestos, entrega y total.
- ✅ Prioridad, fecha prometida, cancelación y estados.
- ✅ Extra opcional separado y sumado realmente al total; prueba: $200 + $100 = $300.
- ✅ Recolección estructurada en pedido: Didi / Camión / Propio / Otro + costo.
- ✅ Variante de producto seleccionable por partida.
- ✅ Ancho y alto estructurados en partida para trabajos variables como lona.
- ✅ Talla/color/marca y otros atributos mediante variantes.
- ✅ Diseño/aprobación por partida con Pendiente, Aprobado, Solicita cambios y Rechazado.
- 🟡 El requisito simplificado “Diseño listo” existe funcionalmente como Aprobado, pero falta una acción rápida con ese texto en el flujo principal de Pedidos.

## Anticipos, pagos y cobros
- ✅ Anticipos/abonos/pagos con método, cuenta, referencia y estado.
- ✅ Efectivo y transferencia configurables.
- ✅ Sin vencimiento obligatorio de anticipo.
- ✅ Saldo por cobrar y cobro final.
- ✅ Caja real con apertura, movimientos, esperado vs contado y cierre.

## Gastos y finanzas
- ✅ Gastos del negocio y personales.
- ✅ Gastos recurrentes y estados Próximo/Por pagar/Vencido.
- ✅ Registrar pago recurrente genera gasto/movimiento real.
- ✅ Renta/luz/agua configurables como categorías separadas.
- 🟡 Camión ida/regreso y gasolina pueden registrarse como gasto y asignarse a pedido mediante estructuras existentes, pero falta captura guiada específica.
- ✅ Didi/Camión/Propio/Otro en pedido.
- 🟡 Didi/Camión/Propio/Otro en compra ya existe en backend; falta exposición en pantalla de Compras.
- ✅ Presupuestos, conciliaciones, transferencias, reembolsos, fondos, deudas, activos y metas.

## Proveedores y compras
- ✅ Proveedores, contacto, teléfono, email, dirección, notas.
- ✅ Materiales por proveedor, precios, historial, escalas, evaluaciones e incidencias.
- ✅ Compras, partidas, tránsito, recepción parcial y creación de lotes.
- ✅ Compra puede vincularse a un pedido (`source_order_id`) en backend.
- 🟡 Vinculación Compra ↔ Pedido pendiente de exposición en UI de Compras.
- ✅ Regla de compra mínima/incrementos DTF-vinil: mínimo 0.5 m e incrementos de 0.5.
- ✅ Prueba transaccional: 0.5 m aceptado; 0.25 y 0.75 bloqueados.
- ✅ Máximo por corte de vinil implementado mediante `max_cut_qty`.
- ✅ Prueba transaccional: 1 m aceptado; 1.5 m en una sola partida bloqueado.

## Inventario
- ✅ Inventario por material/variante, ubicación y lote.
- ✅ Movimientos, reservas y disponible físico/reservado/disponible.
- ✅ Consumo atómico de reserva, lote y movimiento.
- ✅ Validación de disponibilidad.
- ✅ Sobrantes y mermas.
- ✅ Stock mínimo configurable.
- ✅ Dashboard alerta cuando la disponibilidad llega o cae por debajo del mínimo configurado.

## Productos y costeo
- ✅ Productos fabricados, reventa, mixtos y servicios.
- ✅ Variantes flexibles y atributos.
- ✅ Atributos existentes: Talla, Color, Marca, Capacidad, Acabado, Modelo y Calidad.
- ✅ Agregados para requisitos originales: Adulto/Infantil, estampado Chico/Grande, Con/Sin capucha, Con/Sin bolsa.
- ✅ Playera con DTF, Lona y Taza existentes; Sudadera personalizada agregada sin imponer precio.
- ✅ Recetas/BOM, costos estimados/reales, mano de obra y rentabilidad.
- ✅ Regla de lona parametrizada: m² × tarifa (`pricing_rate`, referencia $90) y redondeo hacia arriba (`rounding_increment`).
- ✅ Prueba de fórmula: 2 × 1.04 × $90 = $187.20 → $190.
- 🟡 La fórmula de lona está comprobada en backend, pero falta botón/calculadora directa en cotización/pedido para rellenar automáticamente el precio.

## Producción y operación
- ✅ Workflow, dependencias, pasos y finalización.
- ✅ Asignación a empleados.
- ✅ Incidencias y autorizaciones.
- ✅ Diseño por partida.
- ✅ Costos y tiempos reales.
- ✅ Producción → costeo → entrega → cobro probado.

## Entregas y logística
- ✅ Entregas con tipo, costos estimado/real/cobrado, receptor, responsable, código y estado.
- ✅ Viajes/tareas logísticas existentes.
- ✅ Pedido identifica Didi/Camión/Propio/Otro.
- 🟡 Compra identifica esos métodos en backend; falta UI.

## Dashboard y reportes
- ✅ Cómo voy: valor de pedidos, pagos, por cobrar, efectivo y gastos.
- ✅ Pendientes: tareas, autorizaciones, pagos, stock y recurrentes.
- ✅ Reporte por empleado y consolidado.
- ✅ Tallas, colores, marcas y combinaciones más vendidas.
- ✅ Ventas por producto agregadas en PR #58.
- ✅ Frecuencia por producto agregada como cantidad de pedidos y unidades vendidas.
- ✅ Próximos gastos y compromisos 30 días.

## UX y administración
- ✅ Responsive/móvil.
- ✅ Navegación consolidada de Inventario, Proveedores, Operaciones y Finanzas.
- ✅ Papelera/restauración visible.
- ✅ Permisos principales en español.
- 🟡 Quedan códigos técnicos visibles en módulos secundarios (especialmente Compras, Producción e Inventario avanzado).
- 🟡 GitHub Actions no está disparando CI para la rama del PR #58; no fusionar hasta validar compilación actual por una vía confiable.

## Pendientes reales actuales
1. 🟡 Exponer en Compras: pedido relacionado + Didi/Camión/Propio/Otro + costo de recolección.
2. 🟡 Acción rápida “Diseño listo” en Pedidos/Producción.
3. 🟡 Calculadora de lona en UI usando ancho × alto × tarifa + redondeo.
4. 🟡 Alerta/recomendación cuando sube el costo de un insumo.
5. 🟡 Recomendación de precio/margen apoyada en frecuencia, demanda y rentabilidad, sin cambiar precios automáticamente.
6. 🟡 Captura guiada de camión ida/regreso y gasolina vinculada al pedido cuando corresponda.
7. 🟡 Traducir estados técnicos visibles restantes.
8. 🟡 Validar compilación completa del head actual antes de fusionar PR #58.
