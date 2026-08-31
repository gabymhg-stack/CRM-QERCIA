# QERCIA · Tablero de negociaciones

Sitio estático (sin build): `index.html` + `config.js`, conectado a Supabase (Postgres + Auth + Row Level Security).

## Cómo queda la visibilidad

Enrique y Javier (marcados como `admin` en la tabla `equipo`) ven y editan todas las negociaciones.
Cada otro asesor solo ve y edita las suyas. Esto no es un filtro de pantalla: lo aplican las políticas
RLS en Postgres (`supabase/schema.sql`), así que ni con las herramientas de desarrollador del navegador
se puede ver lo de otro asesor.

## Puesta en marcha (una sola vez)

1. **Base de datos** — En el proyecto de Supabase, abre SQL Editor y pega el contenido completo de
   `supabase/schema.sql`. Antes de correrlo, reemplaza `CORREO_DE_ENRIQUE_AQUI` y `CORREO_DE_JAVIER_AQUI`
   por sus correos reales de POP — son los dos que arrancan como `admin` en cuanto entren por primera vez.
2. **Auth** — En Authentication → Providers, confirma que Email esté activo y que "Confirm email" / el modo
   OTP-magic-link esté habilitado (es el default de Supabase).
3. **URLs permitidas** — En Authentication → URL Configuration, agrega la URL real del sitio en Vercel
   (Site URL y Redirect URLs) en cuanto exista, o el magic link redirige mal.
4. **Config del frontend** — En `config.js`, reemplaza `SUPABASE_ANON_KEY` por la anon public key del
   proyecto (Project Settings → API). Es segura de exponer: la protección real son las políticas RLS.
5. **Deploy** — Cada push a `main` se despliega solo en Vercel.

## Estructura

- `index.html` — toda la app (tablero, captura, perdidas, ajustes, vocabulario).
- `config.js` — URL y anon key de Supabase.
- `supabase/schema.sql` — tablas, triggers y políticas RLS. Es el origen de verdad del esquema; cualquier
  cambio de estructura se hace ahí y se vuelve a correr en SQL Editor.
