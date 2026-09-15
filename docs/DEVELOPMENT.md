# Flujo de desarrollo Moore Print

Este proyecto adopta Superpowers (obra/superpowers) como metodología de desarrollo.

## Flujo obligatorio
1. Brainstorming antes de funciones grandes.
2. Writing plans para dividir implementación.
3. Subagent-driven development / parallel agents cuando las tareas sean independientes.
4. Test-driven development para lógica crítica, especialmente precios, permisos y cotizaciones.
5. Systematic debugging ante errores.
6. Requesting/receiving code review antes de cerrar cambios relevantes.
7. Verification before completion antes de considerar una función terminada.

Referencia: https://github.com/obra/superpowers

## Arquitectura objetivo
- Sitio público: catálogo y cotizador, sin inicio de sesión visible.
- Portal privado: empleados y jefes autorizados mediante Supabase Auth.
- Supabase: datos, Auth, Storage, RLS y funciones de cotización.
- GitHub: código, historial y despliegue.

Nunca exponer claves secretas o service_role en el frontend.
