# QERCIA · Tablero de negociaciones

Sitio estático (sin build): `index.html` + `config.js`, conectado a Supabase (Postgres + Realtime).

## Cómo queda la visibilidad (v2 — sin login individual)

Por ahora no hay correo ni contraseña: cada quien elige su nombre de una lista al entrar y el
navegador lo recuerda (localStorage). Enrique, Javier y Gabriela están marcados como `admin` en
la tabla `equipo` y ven/editan todas las negociaciones; cada otro asesor ve y edita las suyas —
esto es un filtro de pantalla y un acuerdo de equipo, **no** un candado de base de datos. Se puede
volver a endurecer más adelante agregando login real (correo, magic link) sin rehacer el resto.

## Puesta en marcha (una sola vez)

1. **Base de datos** — En el proyecto de Supabase, abre SQL Editor y pega el contenido completo de
   `supabase/schema.sql`. Corre el script (esto borra y vuelve a crear las tablas — está pensado
   para partir de una base vacía, sin negociaciones reales todavía).
2. **Corrige los correos de placeholder** — el script deja a Erick, Alexis, Armando y Alejandra con
   un correo supuesto (`nombre@popinvestments.com`). Ajusta los que no sean correctos desde la
   pestaña Ajustes de la app, o directo en la tabla `equipo` en Supabase.
3. **Config del frontend** — En `config.js`, la anon key y la URL de Supabase ya están puestas.
   Es seguro exponer la anon key: no hay más protección de datos que ella por ahora, así que este
   tablero no debe usarse para nada que no pueda ver cualquiera con el link.
4. **Deploy** — Cada push a `main` se despliega solo en Vercel.

## Estructura

- `index.html` — toda la app (selector de usuario, tablero, captura, perdidas, ajustes, vocabulario).
- `config.js` — URL y anon key de Supabase.
- `supabase/schema.sql` — tablas, catálogos y equipo inicial. Es el origen de verdad del esquema;
  cualquier cambio de estructura se hace ahí y se vuelve a correr en SQL Editor.
