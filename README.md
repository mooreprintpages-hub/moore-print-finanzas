# Moore Print Finanzas

Sistema integral de administración, pedidos, inventario y finanzas de Moore Print.

## Stack

- React + TypeScript + Vite
- Supabase Auth
- Supabase PostgreSQL + RLS
- `@supabase/supabase-js`

## Desarrollo local

1. Instala dependencias:

```bash
npm install
```

2. Copia `.env.example` a `.env.local`.

3. Configura únicamente las variables públicas del frontend:

```env
VITE_SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

4. Inicia el proyecto:

```bash
npm run dev
```

## Seguridad

Nunca colocar en el frontend ni en GitHub:

- `service_role`
- secret keys
- contraseña de PostgreSQL
- credenciales privadas

La autorización real se aplica mediante Supabase Auth, `business_members`, roles/permisos y RLS.

## Base de datos

Las migraciones versionadas están en `supabase/migrations/`.
