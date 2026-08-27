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
- ✅ Reacción puede asociarse a producto y existe resumen por producto con porcentaje de aceptación.
- ✅ Si una cotización contiene un solo producto, la reacción se asocia automáticamente a él.
- 🟡 Si una cotización contiene varios productos, falta selector explícito de producto al registrar la reacción.
- ✅ Precios base, variantes, mayoreo/menudeo/especiales y precios especiales por cliente.
- ✅ Ventas/frecuencia, margen real y señales de demanda se combinan en recomendaciones configurables.
- ✅ Margen objetivo y umbrales de demanda de 30 días son configurables; no se usan valores inventados.
- ✅ Subidas de costo de proveedor se comparan contra el precio anterior y generan señal de revisión para productos que usan ese material.
- ✅ Las recomendaciones se muestran en Reportes y nunca cambian precios automáticamente.

## Pedidos
- ✅ Folio, cliente, partidas, cantidad, precio, subtotal, descuentos, impuestos, entrega y total.
- ✅ Prioridad, fecha prometida, cancelación y estados.
- ✅ Extra opcional separado y sumado realmente al total; prueba: $200 + $100 = $300.
- ✅ Recolección estructurada en pedido: Didi / Camión / Propio / Otro + costo.
- ✅ Variante de producto seleccionable por partida.
- ✅ Ancho y alto estructurados en partida para trabajos variables como lona.
- ✅ Talla/color/marca y otros atributos mediante variantes.
- ✅ Diseño/aprobación por partida con Pendiente, Aprobado, Solicita cambios y Rechazado.
- 🟡 El requisito simplificado “Diseño listo” existe funcionalmente como Aprobado, pero falta una acción rápida con ese texto en el flujo principal.

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
- ✅ Didi/Camión/Propio/Otro + costo en Compras.
- ✅ Presupuestos, conciliaciones, transferencias, reembolsos, fondos, deudas, activos y metas.

## Proveedores y compras
- ✅ Proveedores, contacto, teléfono, email, dirección, notas.
- ✅ Materiales por proveedor, precios, historial, escalas, evaluaciones e incidencias.
- ✅ Compras, partidas, tránsito, recepción parcial y creación de lotes.
- ✅ Compra puede vincularse a un pedido (`source_order_id`).
- ✅ Pedido relacionado se selecciona y muestra desde la UI de Compras.
- ✅ Método/costo de recolección se captura y muestra desde la UI de Compras.
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
- 🟡 La fórmula de lona está comprobada en backend, pero falta calculadora directa en cotización/pedido para rellenar automáticamente el precio.

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
- ✅ Compra identifica Didi/Camión/Propio/Otro y costo desde UI.

## Dashboard y reportes
- ✅ Cómo voy: valor de pedidos, pagos, por cobrar, efectivo y gastos.
- ✅ Pendientes: tareas, autorizaciones, pagos, stock y recurrentes.
- ✅ Reporte por empleado y consolidado.
- ✅ Tallas, colores, marcas y combinaciones más vendidas.
- ✅ Ventas por producto y frecuencia por cantidad de pedidos/unidades.
- ✅ Encuesta de aceptación de precio resumida por producto.
- ✅ Recomendaciones configurables por margen, demanda y subida de insumos.
- ✅ Próximos gastos y compromisos 30 días.

## Seguridad y rendimiento
- ✅ RPC sensibles de inventario y gasto recurrente ya no pueden ejecutarse como `anon`; quedan disponibles sólo para autenticados y conservan validación interna de permisos del negocio.
- 🟡 El asesor sigue mostrando advertencias de `SECURITY DEFINER` para autenticados porque esas RPC deben ser llamadas por la app; sus funciones sí verifican permisos internamente.
- 🟡 Protección contra contraseñas filtradas de Supabase Auth continúa desactivada; requiere revisar configuración de Auth.
- ✅ Se agregó índice faltante para `recurring_expenses.last_expense_id`.
- ℹ️ Los avisos de índices “sin uso” no se están eliminando automáticamente: muchos corresponden a funciones nuevas o poco usadas y borrarlos sin evidencia sería riesgoso.

## UX y administración
- ✅ Responsive/móvil.
- ✅ Navegación consolidada de Inventario, Proveedores, Operaciones y Finanzas.
- ✅ Papelera/restauración visible.
- ✅ Estados principales de Compras ya traducidos.
- 🟡 Quedan códigos técnicos visibles en Producción e Inventario avanzado y algunos módulos secundarios.
- 🟡 GitHub Actions no está disparando CI/check-runs para la rama del PR #58; no fusionar hasta validar compilación actual por una vía confiable.

## Pendientes reales actuales
1. 🟡 Selector de producto en reacción de precio cuando una cotización contiene varios productos.
2. 🟡 Acción rápida “Diseño listo” en Pedidos/Producción.
3. 🟡 Calculadora de lona en UI usando ancho × alto × tarifa + redondeo.
4. 🟡 Captura guiada de camión ida/regreso y gasolina vinculada al pedido cuando corresponda.
5. 🟡 Traducir estados técnicos visibles restantes.
6. 🟡 Revisar/activar protección de contraseñas filtradas en Supabase Auth si la configuración disponible lo permite.
7. 🟡 Validar compilación completa del head actual antes de fusionar PR #58.
