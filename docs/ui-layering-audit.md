# Auditoría de capas UI

Hallazgos revisados tras el problema de Proveedores:

- Proveedores: modal abierto desde drawer. Corregido.
- Pedidos: “Agregar partida” abre modal manteniendo el drawer del pedido. Requiere que modal > drawer.
- Compras: usa drawer secundario (`drawer-backdrop--top`) para agregar partidas y recibir material. Debe quedar entre drawer normal y modal.
- Clientes: al editar datos básicos primero cierra el drawer, por lo que no presenta superposición.
- Inventario: formularios principales usan drawer único, sin modal anidado.

Jerarquía objetivo: drawer normal 60, drawer secundario 90, modal 110.
