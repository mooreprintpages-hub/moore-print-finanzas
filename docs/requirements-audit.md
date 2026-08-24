# Moore Print Finanzas — Auditoría de requisitos aprobados

Fecha de revisión: 2026-08-24

Fuente funcional: `Moore_Print_Finanzas_Documento_Maestro.docx`.

## Criterio de terminado

Un requisito no se considera completamente terminado sólo porque exista una tabla. Para esta auditoría se usan cuatro niveles:

- **Operativo**: backend + RLS/permisos + interfaz + flujo utilizable.
- **Backend listo / UI pendiente**: estructura y reglas existen, pero no hay interfaz completa.
- **Parcial**: existe una parte, pero faltan piezas aprobadas.
- **Pendiente**: el requisito aprobado todavía no existe en el backend.

## 1. Core, seguridad y negocio

| Requisito | Estado | Observación |
|---|---|---|
| businesses / multi-negocio | Operativo | `business_id` es la base de aislamiento. |
| Supabase Auth | Operativo | Primer Propietario creado y asociado. |
| profiles / business_members | Operativo | Perfil automático + membresía real. |
| roles / permissions / role_permissions | Operativo backend | Propietario tiene permisos efectivos. |
| member_permissions | Backend listo / UI pendiente | Excepciones por empleado existen, falta administración desde UI. |
| permission_limits | Backend listo / UI pendiente | Límites existen, falta administración desde UI. |
| branches / areas / locations | Operativo básico | Setup permite sucursal/ubicación; áreas todavía no tienen administración completa. |
| approval_requests | **Pendiente** | Requisito aprobado para descuentos, compras grandes/urgentes, inventario negativo, entrega con saldo y precio bajo margen. |

## 2. Clientes

| Requisito | Estado | Observación |
|---|---|---|
| customers persona/empresa | Operativo | Alta, edición, búsqueda y detalle básico. |
| customer_phones | **Pendiente** | No existe tabla. |
| customer_contacts | **Pendiente** | No existe tabla; requisito de múltiples contactos de empresa. |
| customer_contact_roles | **Pendiente** | No existe tabla. |
| customer_tax_profiles | **Pendiente** | No existe tabla. |
| customer_tags / assignments | **Pendiente** | Frecuente, Mayoreo, Problemático, Crédito, VIP, Nuevo, etc. |
| customer_rules | **Pendiente** | Anticipo mínimo, límite de crédito, exposición, pago total, bloqueo. |
| customer_price_agreements | **Pendiente** | Precio especial por cliente/producto. |
| customer_price_history | **Pendiente** | Historial de acuerdos de precio. |
| customer_financial_summary | Backend listo | Vista consolidada existe; falta ampliar UI de cliente. |

## 3. Productos, variantes, materiales y precios

| Requisito | Estado | Observación |
|---|---|---|
| products | Backend listo / UI pendiente | No hay módulo de Productos en navegación. |
| product_variants | Parcial | Existe tabla, pero falta el modelo flexible aprobado de atributos. |
| variant_attributes | **Pendiente** | No existe. |
| variant_attribute_values | **Pendiente** | No existe. |
| product_variant_values | **Pendiente** | No existe. |
| análisis talla/color/marca/combinación | Parcial | La arquitectura actual no permite cubrirlo completamente hasta terminar atributos flexibles. |
| materials | Operativo parcial | Ya existe y ahora puede crearse también desde Proveedores. |
| material_variants | Operativo backend | Variante inicial se crea en setup/proveedor. |
| recetas/BOM | Backend listo / UI pendiente | `product_recipes` y `product_recipe_items`. |
| precios de producto | Backend listo / UI pendiente | `product_prices`. |
| costos de materiales | Backend listo / UI pendiente | Historial existe. |
| experimentos de precio | Pendiente opcional | Documento indicó preparar arquitectura, no necesariamente activar en V1. |

## 4. Proveedores

| Requisito | Estado | Observación |
|---|---|---|
| suppliers | Operativo | CRUD básico y detalle. |
| supplier_materials | **Operativo tras PR #18** | Permite existente o crear material nuevo y asociarlo. |
| proveedor preferido / marca / lead time / precio actual | Operativo | Capturable al asociar material. |
| supplier_price_history | Operativo parcial | Se registra precio inicial; falta UI de consulta/edición histórica. |
| supplier_price_tiers | Backend listo / UI pendiente | Escalas por cantidad existen en DB, falta UI. |
| supplier_reviews | **Operativo tras PR #18** | Captura entrega, exactitud y calidad. |
| supplier_incidents | Operativo parcial | Se pueden registrar; falta flujo UI para cerrar/resolver incidencia. |
| supplier_performance | Operativo | Se muestra desempeño calculado. |

## 5. Compras e inventario

| Requisito | Estado | Observación |
|---|---|---|
| purchases / purchase_items | Operativo básico | Crear compra, partidas y estados. |
| recepciones parciales | Operativo | Recepción genera lote/movimiento y actualiza cantidades. |
| inventario en tránsito | Operativo | Vista calculada. |
| inventory_lots | Operativo backend/UI lectura | Lotes visibles. |
| inventory_movements | Operativo | Historial + ajustes manuales. |
| físico / reservado / disponible | Operativo | Vista `inventory_availability`. |
| inventory_reservations | Backend listo / UI pendiente | Relacionadas a pedidos. |
| material_remnants | Backend listo / UI pendiente | Sobrantes DTF/vinil modelados, sin pantalla operativa. |
| waste_records | Backend listo / UI pendiente | Merma y recuperación modeladas, sin pantalla completa. |

## 6. Cotizaciones, pedidos y producción

| Requisito | Estado | Observación |
|---|---|---|
| quotes / versiones inmutables | Backend listo / UI pendiente | Reglas existen; no hay módulo de Cotizaciones. |
| quote_items / quote_options | Backend listo / UI pendiente | Estándar/Premium soportado. |
| quote_price_reactions | Backend listo / UI pendiente | Sin captura desde frontend. |
| orders / order_items | Operativo básico | Alta, edición, detalle y partidas. |
| workflows de producción | Backend listo / UI pendiente | Plantillas, pasos, dependencias y paralelismo existen. |
| estados de producción | Backend listo / UI pendiente | pending/in_progress/completed/blocked/cancelled. |
| aprobación de diseño | Backend listo / UI pendiente | Sin flujo visual completo. |
| costeo estimado vs real | Backend listo / UI pendiente | `order_cost_items` + `order_profitability`. |
| mano de obra y tiempos | Backend listo / UI pendiente | actividades/tarifas/registros existen. |

## 7. Finanzas

| Requisito | Estado | Observación |
|---|---|---|
| payment_methods | Operativo | Efectivo, Transferencia, Mercado Pago, Tarjeta y Depósito. |
| pagos / anticipos / abonos | Operativo básico | Registro y confirmación desde UI. |
| comisiones de pago | Backend listo / UI pendiente | Regla de deuda bruta vs neto en cuenta implementada. |
| financial_accounts / saldos | Operativo básico | Alta y saldo calculado. |
| expenses | Operativo básico | Registro y pago. |
| gastos mixtos / allocations | Backend listo / UI pendiente | Sin interfaz completa. |
| recurring_expenses | Backend listo / UI pendiente | Sin interfaz. |
| budgets | **Pendiente** | Requisito aprobado por categoría/periodo/monto. |
| account_transfers | Backend listo / UI pendiente | Transferencias internas no son ingreso/gasto. |
| cash_transits | Backend listo / UI pendiente | Sin interfaz. |
| cash_sessions | Backend listo / UI pendiente | Caja y ajustes sin interfaz completa. |
| reconciliations | Backend listo / UI pendiente | Sin interfaz. |
| customer credits | Backend listo / UI pendiente | Movimientos históricos existen. |
| payment_promises | Backend listo / UI pendiente | Sin interfaz. |
| payment_plans / installments | Backend listo / UI pendiente | Sin interfaz. |
| bad_debts / recoveries | Backend listo / UI pendiente | Sin interfaz. |
| refunds | Backend listo / UI pendiente | Sin interfaz. |
| owner transactions | Backend listo / UI pendiente | Aportaciones/retiros/distribución/reembolso. |
| owner compensation target | Backend listo / UI pendiente | Meta no se trata como pago. |
| funds | Backend listo / UI pendiente | Sin interfaz. |
| assets | Backend listo / UI pendiente | Sin interfaz. |
| debts / debt_payments | Backend listo / UI pendiente | Sin interfaz. |
| financial_goals | Backend listo / UI pendiente | Sin interfaz. |

## 8. Operación complementaria

| Requisito | Estado | Observación |
|---|---|---|
| deliveries / delivery_points | Backend listo / UI pendiente | Sin foto/firma inicial, como se acordó. |
| trips / tasks / transport segments | Backend listo / UI pendiente | Recorridos multimodal modelados. |
| tasks / recurrences | Backend listo / UI pendiente | Agenda y seguimiento a clientes sin pantalla. |
| promotions / customer groups | Backend listo / UI pendiente | Sin pantalla operativa. |
| order incidents / warranties | Backend listo / UI pendiente | Sin pantalla. |
| audit_log | Backend listo | Acciones críticas; falta visor administrativo. |
| papelera / soft delete | Parcial | Implementada en varias entidades importantes, falta UI central de restauración. |
| financial_periods / inventory snapshots | Backend listo / UI pendiente | Cierres y snapshot existen. |

## 9. Dashboard y reportes

| Requisito | Estado | Observación |
|---|---|---|
| dashboard_financial_summary | Operativo | Métricas financieras básicas visibles. |
| inventory_availability | Operativo | Visible en Inventario. |
| supplier_performance | Operativo | Visible en Proveedores. |
| order_profitability | Backend listo / UI pendiente | Falta mostrarlo por pedido/reportes. |
| product_profitability | Backend listo / UI pendiente | Falta módulo de productos/reportes. |
| customer_financial_summary | Backend listo / UI pendiente | Falta detalle financiero del cliente. |
| cash_position | Operativo básico | Usado por Dashboard/Finanzas. |
| análisis de tallas/colores/marcas | Pendiente por dependencia | Requiere completar atributos flexibles. |
| alertas visibles en dashboard | Parcial | Dashboard básico, falta sistema completo de alertas operativas. |

## Prioridad de cierre recomendada

1. **Corregir Proveedores/materiales** y desplegarlo.
2. **Completar clientes avanzados**: contactos, etiquetas, reglas y precios especiales.
3. **Completar variantes flexibles** para talla/color/marca/modelo/calidad/acabado/capacidad.
4. **Crear approval_requests** y conectar límites/autorizaciones.
5. **Crear módulo Productos** con variantes, precios, recetas y rentabilidad.
6. **Crear módulo Cotizaciones + Producción**.
7. **Ampliar Finanzas** con transferencias, caja, conciliaciones, créditos, planes, fondos, activos, deudas, metas y presupuestos.
8. **Crear Operaciones**: entregas, recorridos, agenda, promociones, incidencias y mano de obra.
9. **Crear administración de empleados/permisos/papelera**.
10. **Pruebas E2E** contra cada respuesta aprobada y cierre sólo cuando backend + RLS + UI + prueba estén completos.

## Conclusión

El sistema no está vacío ni mal encaminado: una parte grande del backend ya existe y está protegida con RLS. Sin embargo, **no debe considerarse todavía 100% terminado respecto al cuestionario original**. La brecha principal ya no es arquitectura: es terminar algunas estructuras aprobadas y exponer muchas funciones existentes mediante interfaz y pruebas operativas.