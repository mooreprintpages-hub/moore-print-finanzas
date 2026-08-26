# Moore Print Finanzas — Auditoría de requisitos aprobados

Fecha de revisión: 2026-08-25

Fuente funcional: `Moore_Print_Finanzas_Documento_Maestro.docx`.

## Criterio de terminado

- **Operativo**: backend + RLS/permisos + interfaz + flujo utilizable.
- **Parcial**: existe el flujo principal, pero faltan detalles o pruebas reales.
- **Backend listo / UI pendiente**: estructura y reglas existen, pero no hay interfaz completa.
- **Pendiente**: requisito aprobado aún no implementado.

## Estado consolidado

### Core, seguridad y administración

| Requisito | Estado | Observación |
|---|---|---|
| businesses / multi-negocio | Operativo | Aislamiento por `business_id`. |
| Supabase Auth + profiles + memberships | Operativo | Propietario real vinculado al negocio. |
| roles / permissions / member_permissions / permission_limits | Operativo | Administración central disponible en UI. |
| branches / locations | Operativo básico | Setup inicial disponible. |
| areas | Parcial | Estructura existe; falta una pantalla dedicada de administración completa. |
| approval_requests | Operativo | Solicitud, aprobación y rechazo de excepciones. |
| papelera / soft delete | Operativo | Restauración central desde Administración. |

### Clientes

| Requisito | Estado | Observación |
|---|---|---|
| customers persona/empresa | Operativo | Alta, edición, búsqueda y detalle. |
| teléfonos y múltiples contactos | Operativo | Incluye roles de contacto. |
| perfil fiscal | Operativo | Capturable desde detalle. |
| etiquetas / reglas | Operativo | Crédito, anticipo, bloqueo, etc. |
| precios especiales e historial | Operativo | Acuerdos e historial por cliente/producto. |
| customer_financial_summary | Parcial | Backend listo; falta una visualización financiera más completa en el detalle del cliente. |

### Productos, variantes y materiales

| Requisito | Estado | Observación |
|---|---|---|
| products / services | Operativo | Fabricado, Reventa, Mixto y Servicio. |
| variantes flexibles | Operativo | Talla, Color, Marca, Modelo, Calidad, Acabado y Capacidad. |
| recetas/BOM | Operativo | Captura de materiales y merma. |
| precios menudeo/mayoreo/especial | Operativo | UI disponible. |
| rentabilidad de producto | Operativo básico | Consulta disponible desde Productos. |
| materiales / variantes | Operativo | Alta y variante inicial desde Setup/Proveedores. |
| análisis agregado talla/color/marca | Parcial | Modelo ya lo soporta; falta reporte agregado específico. |

### Proveedores

| Requisito | Estado | Observación |
|---|---|---|
| suppliers / supplier_materials | Operativo | Material existente o nuevo desde proveedor. |
| proveedor preferido / marca / lead time / precio | Operativo | Capturable. |
| historial y escalas de precio | Operativo | UI avanzada disponible. |
| evaluaciones / desempeño | Operativo | Captura y lectura. |
| incidencias / resolución | Operativo | Registro y cierre con resoluciones válidas. |

### Compras e inventario

| Requisito | Estado | Observación |
|---|---|---|
| purchases / items | Operativo | Alta, partidas, estados. |
| recepciones parciales / lotes / tránsito | Operativo | Integrado a inventario. |
| movimientos / físico / reservado / disponible | Operativo | UI y vistas calculadas. |
| reservas por pedido | Operativo | Reservar, consumir y liberar. |
| sobrantes reutilizables | Operativo | Medidas y valor remanente. |
| mermas / recuperaciones | Operativo | Captura de costo y recuperación. |

### Cotizaciones, pedidos y producción

| Requisito | Estado | Observación |
|---|---|---|
| cotizaciones versionadas | Operativo | Versiones, envío y conversión a pedido. |
| opciones Estándar/Premium | Operativo | UI disponible. |
| reacción al precio | Operativo | Capturable desde Cotizaciones. |
| pedidos / partidas | Operativo | Flujo base usable. |
| workflows / pasos / dependencias | Operativo | Producción conectada. |
| aprobación de diseño | Operativo | UI disponible. |
| costeo estimado vs real / rentabilidad | Operativo | Producción muestra comparativos. |
| mano de obra / tiempos | Operativo básico | Registro disponible. |

### Finanzas

| Requisito | Estado | Observación |
|---|---|---|
| métodos de pago / pagos / anticipos | Operativo | Registro y confirmación. |
| cuentas / saldos | Operativo | Saldos calculados. |
| gastos / gastos mixtos / allocations | Operativo | Incluye asignación a pedidos. |
| gastos recurrentes | Operativo | Administración financiera. |
| presupuestos | Operativo | Por categoría/periodo/monto. |
| transferencias | Operativo | Entre cuentas propias. |
| efectivo en tránsito | Operativo | Confirmación de recepción. |
| caja | Operativo básico | Apertura y cierre; faltan ajustes manuales de caja en UI. |
| conciliaciones | Operativo | UI avanzada. |
| créditos a favor | Operativo básico | Alta visible; movimientos detallados todavía parciales. |
| promesas / planes de pago | Operativo | UI disponible. |
| incobrables / recuperaciones | Operativo | Administración financiera. |
| reembolsos | Operativo | UI avanzada. |
| propietarios | Operativo | Aportaciones, retiros y distribuciones. |
| meta de compensación de propietario | Backend listo / UI pendiente | `owner_compensation_targets` existe. |
| fondos / activos / deudas / pagos de deuda / metas | Operativo | UI disponible. |
| cierres mensuales / snapshots | Operativo | Cierre/reapertura con snapshot automático. |
| auditoría | Operativo | Visor disponible. |
| comisiones de pago | Parcial | Backend automático; falta pantalla detallada de comisiones por pago. |

### Operaciones

| Requisito | Estado | Observación |
|---|---|---|
| entregas | Operativo | Alta y cierre. |
| puntos de entrega | Operativo | UI detallada. |
| recorridos / tareas / segmentos de transporte | Operativo | UI básica y detallada. |
| recurrencias | Operativo | UI disponible. |
| promociones / grupos de clientes | Operativo | UI disponible. |
| incidencias / garantías | Operativo | Alta y resolución básica. |

### Dashboard y reportes

| Requisito | Estado | Observación |
|---|---|---|
| resumen financiero | Operativo | Pedidos, pagos, cuentas por cobrar y efectivo. |
| inventario / proveedor / rentabilidad | Operativo en módulos | Datos disponibles en sus módulos. |
| análisis color/talla/marca | Parcial | Falta reporte agregado. |
| alertas visibles | Parcial | Falta panel consolidado de alertas operativas/financieras. |
| reportes por empleado y consolidado | Parcial | Datos de usuario/actividad existen; falta reporte específico por empleado. |

## Brechas reales después del PR #32

1. Administración completa de **áreas** por sucursal.
2. Vista ampliada de **customer_financial_summary** en Clientes.
3. Reportes agregados de **talla, color, marca y combinaciones**.
4. **Ajustes de caja** (`cash_session_adjustments`) desde UI.
5. Movimientos detallados de **crédito a favor** (`customer_credit_movements`).
6. **Meta de compensación de propietarios** (`owner_compensation_targets`) desde UI.
7. Vista detallada de **comisiones de pago** (`payment_fees`).
8. **Panel de alertas** en Dashboard.
9. **Reporte por empleado** y consolidado.
10. Pruebas funcionales E2E con datos reales y validación final de RLS.

## Prioridad de cierre

1. Finanzas finas: ajustes de caja, créditos a favor, compensación de propietarios y comisiones.
2. Dashboard/alertas y reportes por empleado.
3. Reportes de talla/color/marca y detalle financiero de clientes.
4. Administración completa de áreas.
5. Pruebas E2E y corrección de incidencias encontradas.

## Conclusión

La aplicación ya cubre la mayor parte del cuestionario original tanto en backend como en interfaz. La fase actual ya no es construir los módulos principales, sino cerrar detalles administrativos/reportes y realizar pruebas integrales con datos reales. Ningún punto debe considerarse cerrado definitivamente hasta pasar prueba funcional y RLS en una sesión real.