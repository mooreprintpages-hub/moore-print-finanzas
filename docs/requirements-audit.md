# Moore Print Finanzas — Auditoría de requisitos aprobados

Fecha de revisión: 2026-08-25

Fuente funcional: `Moore_Print_Finanzas_Documento_Maestro.docx`.

## Criterio de terminado

- **Operativo**: backend + RLS/permisos + interfaz + flujo utilizable a nivel de implementación.
- **Validación pendiente**: implementación completa, falta ejecutar prueba E2E con sesión real y confirmar RLS.
- **Pendiente**: requisito aprobado aún no implementado.

## Estado consolidado después del PR #37

| Bloque | Estado de implementación | Observación |
|---|---|---|
| Core / multi-negocio / Auth / membresías | Operativo | Aislamiento por `business_id`, perfiles, membresías, roles y permisos. |
| Equipo / roles / excepciones / límites | Operativo | Administración desde UI. |
| Sucursales / áreas / ubicaciones | Operativo | Áreas por sucursal, activación y ubicaciones asociadas. |
| Autorizaciones | Operativo | Solicitud, aprobación y rechazo de excepciones. |
| Papelera | Operativo | Restauración de entidades con soft delete. |
| Clientes básicos y avanzados | Operativo | Persona/empresa, contactos, teléfonos, fiscal, etiquetas, reglas y precios especiales. |
| Finanzas del cliente | Operativo | Ventas, pagos confirmados, saldo por cobrar, incobrable y actividad reciente. |
| Productos / servicios | Operativo | Fabricado, Reventa, Mixto y Servicio. |
| Variantes flexibles | Operativo | Talla, Color, Marca, Modelo, Calidad, Acabado y Capacidad. |
| BOM / precios / rentabilidad | Operativo | Recetas, merma, precios y consulta de rentabilidad. |
| Reportes talla/color/marca | Operativo | Cantidades, ingresos y combinaciones vendidas. |
| Proveedores | Operativo | Materiales, preferido, marca, lead time, precio, historial, escalas, evaluaciones e incidencias. |
| Compras | Operativo | Partidas, estados y recepciones parciales. |
| Inventario | Operativo | Lotes, movimientos, físico/reservado/disponible, reservas, sobrantes y merma. |
| Cotizaciones | Operativo | Versiones, Estándar/Premium, reacción al precio, envío y conversión a pedido. |
| Pedidos | Operativo | Partidas y flujo comercial. |
| Producción | Operativo | Workflows, dependencias, diseño, costos y mano de obra. |
| Métodos de pago / pagos / anticipos | Operativo | Registro, confirmación y comisiones. |
| Cuentas y saldos | Operativo | Saldos calculados. |
| Gastos / recurrentes / allocations / presupuestos | Operativo | Incluye gasto mixto y asignación a pedidos. |
| Transferencias / efectivo en tránsito | Operativo | Flujos entre cuentas sin tratarlos como venta. |
| Caja | Operativo | Apertura, cierre y ajustes. |
| Conciliaciones | Operativo | Comparación sistema vs real. |
| Créditos a favor | Operativo | Alta y movimientos created/used/reversed. |
| Promesas / planes de pago | Operativo | Seguimiento y parcialidades. |
| Incobrables / recuperaciones | Operativo | Registro y recuperación. |
| Reembolsos | Operativo | Parcial, total o crédito a favor. |
| Propietarios | Operativo | Aportaciones, retiros, distribuciones y meta de compensación. |
| Fondos / activos / deudas / metas | Operativo | Administración financiera avanzada. |
| Cierres mensuales / snapshots | Operativo | Cierre/reapertura y snapshot automático de inventario. |
| Auditoría | Operativo | Visor administrativo. |
| Entregas / puntos de entrega | Operativo | Alta y cierre. |
| Recorridos / segmentos / tareas / recurrencias | Operativo | Operación y agenda. |
| Promociones / grupos | Operativo | Segmentación y promociones. |
| Incidencias / garantías | Operativo | Registro y resolución básica. |
| Dashboard financiero | Operativo | Pedidos, pagos, cuentas por cobrar, efectivo y gastos. |
| Alertas | Operativo | Tareas vencidas/urgentes, autorizaciones, pagos por revisar e inventario negativo. |
| Reporte por empleado y consolidado | Operativo | Tareas y pasos de producción por asignación. |

## Brecha restante

La **implementación funcional del cuestionario está cubierta**. El único bloque abierto es la validación integral:

1. Ejecutar el checklist `docs/e2e-checklist.md` con una sesión real.
2. Validar RLS con Propietario y al menos un rol limitado.
3. Ejecutar un flujo completo controlado: cliente → cotización → pedido → anticipo → compra/recepción → inventario → producción → entrega → cobro → dashboard.
4. Corregir cualquier incidencia encontrada durante esas pruebas.
5. Revisar experiencia móvil y despliegue de GitHub Pages.

## Limitación actual de validación

El conector de Supabase disponible en este chat continúa rechazando incluso consultas SQL de lectura con `You do not have permission to perform this action`. Por ello, la implementación puede revisarse y compilarse desde GitHub, pero las pruebas E2E/RLS contra datos reales no deben marcarse como aprobadas hasta recuperar esa autorización o ejecutar el checklist desde una sesión real de la aplicación.

## Conclusión

Después de los PR #18–#37, ya no quedan módulos funcionales del cuestionario marcados como pendientes de implementación. La fase actual es **QA/E2E y endurecimiento final**, no construcción de módulos principales.
