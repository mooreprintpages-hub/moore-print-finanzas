# Moore Print Finanzas — Checklist E2E y RLS

Fecha: 2026-08-25

## Criterio de aprobación

Cada prueba debe ejecutarse con una sesión real de Supabase Auth. Un flujo se marca **APROBADO** únicamente si la operación funciona desde la interfaz, los datos derivados se actualizan correctamente y RLS bloquea acciones que el rol no tiene permitidas.

Estados: `PENDIENTE`, `APROBADO`, `FALLÓ`, `BLOQUEADO`.

## 1. Acceso y aislamiento

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Login Propietario | Inicia sesión y reconoce Moore Print | PENDIENTE |
| Usuario sin membresía | No accede al negocio | PENDIENTE |
| Miembro activo | Sólo ve datos de su `business_id` | PENDIENTE |
| Miembro inactivo | Pierde acceso operativo | PENDIENTE |
| Rol sin `users.manage` | No puede administrar roles/áreas/papelera | PENDIENTE |

## 2. Configuración, sucursales y áreas

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Crear sucursal | Sucursal queda activa | PENDIENTE |
| Crear área ligada a sucursal | Área aparece bajo la sucursal correcta | PENDIENTE |
| Editar/desactivar área | Estado se refleja sin borrar historial | PENDIENTE |
| Ubicación con área | Relación sucursal/área/ubicación consistente | PENDIENTE |

## 3. Clientes

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Alta persona/empresa | Cliente visible y editable | PENDIENTE |
| Contactos/teléfonos múltiples | Se guardan roles y contactos | PENDIENTE |
| Etiquetas y reglas | Crédito/anticipo/bloqueo se conservan | PENDIENTE |
| Precio especial | Acuerdo queda vigente e historial registra cambio | PENDIENTE |
| Resumen financiero | Ventas, pagos, saldo e incobrable coinciden con transacciones | PENDIENTE |

## 4. Productos y reportes

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Crear producto Fabricado/Reventa/Mixto/Servicio | Tipo correcto | PENDIENTE |
| Crear variante | Puede asignar Talla/Color/Marca/etc. | PENDIENTE |
| BOM/receta | Materiales y merma quedan asociados | PENDIENTE |
| Precios | Menudeo/mayoreo/especial se guardan | PENDIENTE |
| Reporte Talla/Color/Marca | Cantidades e ingresos coinciden con pedidos no cancelados | PENDIENTE |
| Combinaciones | Producto + atributos agregan cantidades correctamente | PENDIENTE |

## 5. Proveedores y compras

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Crear proveedor | Proveedor visible | PENDIENTE |
| Crear material desde proveedor | Material + variante inicial + relación proveedor se crean | PENDIENTE |
| Precio inicial/historial | Historial registra precio | PENDIENTE |
| Escala por cantidad | Rango y precio quedan vigentes | PENDIENTE |
| Evaluación | Desempeño se recalcula | PENDIENTE |
| Incidencia/resolución | Cierre conserva trazabilidad | PENDIENTE |
| Compra con partidas | Total correcto | PENDIENTE |
| Recepción parcial | Lote/movimiento/inventario se actualizan | PENDIENTE |

## 6. Inventario

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Ajuste manual | Movimiento y disponibilidad coinciden | PENDIENTE |
| Reserva para pedido | Baja disponible, conserva físico | PENDIENTE |
| Liberar reserva | Disponible regresa | PENDIENTE |
| Consumir reserva | Movimiento refleja consumo | PENDIENTE |
| Sobrante | Registra medidas, cantidad y valor | PENDIENTE |
| Merma/recuperación | Costo y recuperación quedan registrados | PENDIENTE |
| Inventario negativo | Genera alerta/solicitud según regla | PENDIENTE |

## 7. Cotización → pedido → producción

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Crear cotización y versión | Versión editable mientras no se envía | PENDIENTE |
| Estándar/Premium | Opciones quedan asociadas | PENDIENTE |
| Reacción al precio | Se registra reacción y precio solicitado | PENDIENTE |
| Marcar versión enviada | Versión queda inmutable | PENDIENTE |
| Convertir a pedido | Pedido y partidas nacen desde versión elegida | PENDIENTE |
| Workflow | Pasos y dependencias se respetan | PENDIENTE |
| Aprobación de diseño | Estado y rondas se registran | PENDIENTE |
| Costeo estimado vs real | Margen/rentabilidad coinciden | PENDIENTE |
| Mano de obra | Tiempo asignado aparece en reporte de empleado | PENDIENTE |

## 8. Finanzas

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Anticipo/pago | Saldo de pedido se actualiza sólo al confirmar | PENDIENTE |
| Comisión de pago | Deuda bruta y entrada neta no se confunden | PENDIENTE |
| Gasto | Cuenta y dashboard reflejan salida | PENDIENTE |
| Gasto mixto | Personal + negocio = total | PENDIENTE |
| Allocation a pedido | Costeo del pedido recibe asignación | PENDIENTE |
| Transferencia interna | No se contabiliza como ingreso/gasto | PENDIENTE |
| Efectivo en tránsito | Origen/destino cambian al confirmar recepción | PENDIENTE |
| Caja apertura/cierre/ajuste | Diferencia y ajustes quedan trazables | PENDIENTE |
| Conciliación | Diferencia sistema vs real correcta | PENDIENTE |
| Crédito a favor | created/used/reversed mantienen saldo lógico | PENDIENTE |
| Promesa/plan de pago | Estados y parcialidades correctos | PENDIENTE |
| Incobrable/recuperación | Saldo incobrable disminuye al recuperar | PENDIENTE |
| Reembolso | Flujo parcial/total/crédito según tipo | PENDIENTE |
| Propietario | Aportación suma; retiro/distribución resta | PENDIENTE |
| Meta compensación | No se contabiliza como pago automáticamente | PENDIENTE |
| Fondo/activo/deuda/meta | CRUD y saldos coherentes | PENDIENTE |
| Presupuesto | Gasto real y porcentaje usado correctos | PENDIENTE |
| Cierre mensual | Captura snapshot de inventario + auditoría | PENDIENTE |

## 9. Operaciones

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Entrega | Pendiente → entregado con costo | PENDIENTE |
| Punto de entrega | Disponible para operación recurrente | PENDIENTE |
| Recorrido/segmentos | Orden y medios de transporte consistentes | PENDIENTE |
| Tarea/recurrencia | Seguimiento y vencimiento correctos | PENDIENTE |
| Promoción/grupo | Segmentación queda asociada | PENDIENTE |
| Incidencia/garantía | Apertura → resolución conserva descripción/costo | PENDIENTE |

## 10. Dashboard y empleados

| Prueba | Resultado esperado | Estado |
|---|---|---|
| Métricas financieras | Coinciden con órdenes/pagos/gastos reales | PENDIENTE |
| Alertas tareas | Detecta vencidas y urgentes | PENDIENTE |
| Alertas autorizaciones | Cuenta pendientes | PENDIENTE |
| Alertas pagos | Muestra reportados/por confirmar/no recibidos | PENDIENTE |
| Alerta inventario negativo | Detecta disponibilidad < 0 | PENDIENTE |
| Reporte empleado | Tareas/pasos abiertos y completados por asignación | PENDIENTE |
| Consolidado | Suma coincide con empleados activos | PENDIENTE |

## 11. RLS por rol

Crear temporalmente al menos un rol operativo limitado y validar:

| Permiso ausente | Acción que debe fallar | Estado |
|---|---|---|
| `users.manage` | Administrar equipo, roles, áreas, papelera | PENDIENTE |
| `finance.manage` | Crear/editar movimientos financieros administrativos | PENDIENTE |
| `inventory.adjust` | Ajustar inventario / atributos de variante | PENDIENTE |
| `purchases.manage` | Crear/modificar compras | PENDIENTE |
| `workflows.manage` | Administrar producción | PENDIENTE |
| `quotes.edit` | Modificar cotizaciones | PENDIENTE |

## Cierre de versión

La versión puede declararse operativa cuando:

1. No existan pruebas `FALLÓ` en los flujos críticos.
2. Las pruebas RLS de permisos limitados hayan sido aprobadas.
3. El flujo completo cliente → cotización → pedido → anticipo → compra/recepción → inventario → producción → entrega → cobro → dashboard haya sido ejecutado al menos una vez con datos controlados.
4. Se haya revisado el comportamiento en móvil.
5. GitHub Pages despliegue `main` sin errores y la aplicación no muestre errores de runtime.
