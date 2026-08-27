# Auditoría de requisitos originales — Moore Print Finanzas

Fecha: 2026-08-26

Leyenda: ✅ implementado y comprobado · 🟡 parcial / existe backend pero falta exposición o regla exacta · ❌ faltante

## Negocio, usuarios y permisos

- ✅ App propia para finanzas, inventario, pedidos y análisis.
- ✅ Acceso con usuarios Supabase Auth y membresía por negocio.
- ✅ Propietario + roles configurables (Administrador, Encargado, Ventas, Producción, Compras e inventario, Finanzas y caja, Empleado).
- ✅ Permisos por rol + excepciones individuales por empleado, alineados con RLS.
- ✅ Karlita vinculada como Empleado.
- ✅ Reporte por empleado y consolidado en Dashboard basado en tareas/pasos asignados.
- ✅ Borrado lógico/papelera en entidades principales mediante deleted_at/deleted_by y RLS administrativo.
- 🟡 Papelera visible/recuperación desde UI: estructura existe, pero falta comprobar una pantalla única de restauración para todas las entidades.

## Clientes y canales

- ✅ Clientes con nombre, teléfono, correo, dirección, notas y activo/inactivo.
- ✅ Canal de cotización/pedido disponible en cotizaciones (`quotes.channel`).
- ❌ Color/etiqueta de WhatsApp por cliente no existe como campo funcional visible.
- 🟡 Múltiples teléfonos/contactos: existen tablas auxiliares, pero falta confirmar que la UI principal permita administrarlos de forma sencilla.

## Cotizaciones y precios

- ✅ Cotizaciones versionadas.
- ✅ Versión enviada queda inmutable.
- ✅ Conversión formal de cotización a pedido.
- ✅ Acción directa Pasar a pedido / Poner en espera.
- ✅ Resumen tipo recibo con subtotal, descuento, entrega, impuestos, total y anticipo sugerido.
- ✅ Backend de reacción de precio (`quote_price_reactions`) con reacción, precio solicitado, motivo y notas.
- 🟡 Encuesta exacta “incómodo / aceptado”: backend existe, pero falta confirmar/ajustar UI para que esas sean las opciones visibles exactas y alimentar análisis por producto.
- ✅ Precios base y variantes de producto.
- 🟡 Sugerencia automática de precio/margen según demanda: existen costos, márgenes e historial, pero no hay una recomendación automática integral comprobada.
- 🟡 Ajuste por subida de insumos: existe historial/costo de proveedor, pero falta comprobar alerta/recomendación automática de reajuste de precio.

## Pedidos

- ✅ Pedido con folio, cliente, partidas, cantidad, precio unitario, subtotal, descuento, impuestos, entrega y total.
- ✅ Estados y cancelación directa con confirmación.
- ✅ Prioridad y fecha prometida.
- ✅ Estados operativos/producción mediante workflows y pasos.
- ✅ Diseño: existe `order_design_approvals` para seguimiento de aprobación/cambios.
- 🟡 Regla original simplificada “diseño listo” como estado visible en pedido: existe infraestructura más avanzada, pero falta comprobar que sea fácil de marcar desde el flujo principal.
- ❌ Campo explícito de “extra opcional (~$100)” separado del precio/subtotal no existe en el pedido.
- ❌ Regla específica de redondeo de lona a favor (ej. 187→190) no está comprobada como automatización del pedido/cotización.
- 🟡 Medidas/material/talla/color: variantes JSONB y productos permiten atributos; falta comprobar que la captura de pedido exponga estas entradas de forma consistente para todos los trabajos.
- ✅ Tallas/colores/marca pueden almacenarse en variantes y los códigos de reporte size/color/brand existen.

## Anticipos, pagos y cobros

- ✅ Pagos/anticipos/abonos con método, cuenta, referencia y estado.
- ✅ Métodos de pago administrables.
- ✅ Sin vencimiento obligatorio de anticipos.
- ✅ Saldo por cobrar y cobro final probados E2E.
- ✅ Caja/cuentas financieras y movimientos reales.
- ✅ Apertura, ajustes y cierre de caja con esperado vs contado corregido y probado.

## Gastos y finanzas

- ✅ Gastos de negocio y parte personal.
- ✅ Gastos recurrentes con Próximo/Por pagar/Vencido.
- ✅ Registrar pago recurrente crea gasto real, afecta cuenta y avanza vencimiento.
- ✅ Renta/luz/agua pueden registrarse por categoría; renta recurrente ya probada sin dejar pago falso.
- 🟡 Pasajes de camión “ida y regreso” pueden registrarse como gasto, pero no existe una captura específica que fuerce dos trayectos o los relacione al pedido.
- 🟡 Gasolina puede registrarse como gasto, pero falta relación explícita con pedido/recolección cuando corresponda.
- ❌ Didi como opción explícita de recolección de proveedor→local por pedido/compra no está implementado como campo estructurado.
- 🟡 Existen `trips` y `trip_tasks` para logística, pero no traducen aún la regla de negocio Didi/camión/propio de forma directa en la UI.
- ✅ Presupuestos, conciliaciones, transferencias, reembolsos, fondos, deudas, activos y metas existen.
- ✅ Finanzas unificadas en un centro único (PR #54).

## Proveedores y compras

- ✅ Proveedores con contacto, teléfono, email, dirección, notas y activo/inactivo.
- ✅ Materiales por proveedor, precios, historial, escalas de precio, evaluaciones e incidencias.
- ✅ Compras con proveedor, partidas, cantidades, costo, recepción y creación de lotes.
- ✅ Inventario recibido queda relacionado con proveedor/lote.
- ❌ Regla automática de compra mínima DTF/vinil de 0.5 m o 1 m, sin fracciones menores, no está comprobada ni modelada como validación general.
- ❌ Regla “vinil no más de 1 m por corte” no está implementada como validación comprobada.
- 🟡 Gran parte del material comprado a proveedor/reventa: el modelo lo soporta, pero falta regla/UI específica para distinguir stock propio vs compra para pedido cuando sea necesario.

## Inventario

- ✅ Inventario por material/variante y ubicación.
- ✅ Inventario por lote.
- ✅ Movimientos, reservas, disponibilidad física/reservada/disponible.
- ✅ Consumo atómico de reserva + movimiento + reducción de lote.
- ✅ Validación de no reservar más de lo disponible.
- ✅ Ubicación obligatoria para reservas y lote opcional/relacionado.
- ✅ Remanentes, desperdicios y snapshots existen en esquema.
- ✅ Stock mínimo disponible en materiales.
- 🟡 Alertas de stock bajo: Dashboard detecta negativos; falta comprobar alerta configurable de mínimo para todos los materiales.

## Productos y costeo

- ✅ Productos/variantes con precio y atributos.
- ✅ Recetas/costos de materiales y plantillas de costo.
- ✅ Mano de obra, tiempo trabajado y costos reales probados.
- ✅ Margen real por pedido probado E2E.
- 🟡 Tipos específicos originales (playera grande/chico, niño/adulto, sudadera con/sin capucha/bolsa, tazas estándar, lonas por medida) se pueden modelar como productos/variantes, pero falta comprobar catálogo/flujo preparado para todos esos casos.
- ❌ Regla automática lona = m² × $90 + redondeo a favor no está confirmada como calculadora/validación en la UI.

## Producción y operación

- ✅ Workflow de producción con dependencias, pasos y finalización.
- ✅ Asignación de tareas/pasos a empleados.
- ✅ Incidencias y autorizaciones.
- ✅ Producción→costeo→entrega→cobro probados E2E.
- ✅ Operaciones e inventario/proveedores se están consolidando en centros con pestañas (PR #55).

## Entregas y logística

- ✅ Entregas con tipo, costos estimado/real/cobrado, persona que recibe, responsable, código y estado.
- 🟡 Viajes/tareas logísticas existen, pero faltan opciones de negocio directas “Didi / camión / propio”.
- ❌ Indicador estructurado “pedido recogido por Didi” no existe como campo/acción específica.

## Dashboard y reportes

- ✅ Cómo voy: valor de pedidos, pagos confirmados, cuentas por cobrar, posición de efectivo, gastos.
- ✅ Pendientes/alertas: tareas, autorizaciones, pagos, inventario y recurrentes.
- ✅ Reporte por empleado y consolidado.
- ✅ Análisis por talla/color/marca soportado y códigos confirmados.
- 🟡 Ventas por producto/frecuencia y colores/tallas más vendidos: existen bases de datos y reportes, pero falta comprobar todas las visualizaciones finales con datos reales.
- ✅ Próximos gastos recurrentes y compromisos próximos 30 días.
- ✅ Dashboard convertido en centro de acciones rápidas en PR #55.

## Reglas de UX y administración

- ✅ Interfaz móvil/responsive con menú scrollable y modales sobre drawers.
- ✅ Estados/permisos principales en español; códigos internos se mantienen en inglés.
- 🟡 Todavía hay valores técnicos de estado en algunos módulos secundarios; falta pasada global de traducción.
- ✅ Configuración de sucursales, ubicaciones y métodos de pago editable.
- ✅ Proveedores, Inventario, Operaciones y Finanzas se están simplificando para reducir módulos duplicados.

## Pendientes prioritarios derivados de esta auditoría

1. ❌ WhatsApp: color/etiqueta por cliente.
2. ❌ Logística estructurada: Didi / camión / propio y relación a pedido/compra/recolección.
3. ❌ Extra opcional separado en pedido/cotización.
4. ❌ Reglas de lona: m² × tarifa configurable + redondeo a favor.
5. ❌ Reglas de compra DTF/vinil: mínimo 0.5 m, incrementos permitidos y límite por corte de vinil.
6. 🟡 Exponer encuesta de precio con opciones exactas Incómodo/Aceptado y análisis.
7. 🟡 Alertas por stock mínimo, no sólo inventario negativo.
8. 🟡 Papelera/restauración visible y uniforme.
9. 🟡 Traducción global de estados visibles.
10. 🟡 Verificar catálogo/variantes para tipos de trabajo originales y captura de talla/color/medidas/material.
