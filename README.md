# QERCIA · Tablero de negociaciones

Sitio estático (sin build): `index.html` + `config.js`, conectado a Supabase (Postgres + Realtime).

## Cómo queda la visibilidad (v2 — sin login individual)

Por ahora no hay correo ni contraseña: cada vez que se abre o recarga la página, se pide elegir
el nombre de una lista (no se queda guardado — sirve igual para un dispositivo compartido, como
una tablet de showroom, que para uno personal). Enrique, Javier y Gabriela están marcados como
`admin` en la tabla `equipo` y ven/editan todas las negociaciones; cada otro asesor ve y edita
las suyas — esto es un filtro de pantalla y un acuerdo de equipo, **no** un candado de base de
datos. Se puede volver a endurecer más adelante agregando login real (correo, magic link) sin
rehacer el resto.

## Puesta en marcha desde cero

1. **Base de datos** — En el proyecto de Supabase, abre SQL Editor y pega el contenido completo de
   `supabase/schema.sql`. Corre el script (esto borra y vuelve a crear las tablas — solo úsalo
   para arrancar de cero; si ya hay negociaciones reales capturadas, no lo corras, usa la
   migración de abajo).
2. **Config del frontend** — En `config.js`, la anon key y la URL de Supabase ya están puestas.
   Es seguro exponer la anon key: no hay más protección de datos que ella por ahora, así que este
   tablero no debe usarse para nada que no pueda ver cualquiera con el link.
3. **Deploy** — Cada push a `main` se despliega solo en Vercel.

## Actualizar una base que ya está viva (sin perder negociaciones)

`supabase/migracion_v3.sql` agrega el inventario real de 99 lotes (carga CAPI del 24 de agosto de
2026), las columnas que llena jurídico en cada lote (propietario, gravado, banco, disponible, y el
candado `se_puede_separar` que bloquea mover una negociación a la etapa Separación hasta que
jurídico lo confirme), le pone apellido a los asesores en `equipo` para que coincida con el
catálogo oficial, y agrega "Perdido" como opción 8 en el selector de Etapa al mover una
negociación (no es columna nueva del tablero: al elegirla se abre el mismo flujo de "Marcar
perdida" de siempre — motivo, objeción, etc.). No borra negociaciones existentes — pégalo y corre
en SQL Editor.

## Estructura

- `index.html` — toda la app (selector de usuario, tablero, captura, perdidas, ajustes, vocabulario).
  La Captura incluye ahora los campos de referido (tipo, quién lo refirió) y de bróker (agencia,
  bróker, fecha de registro), que solo aparecen según el Origen elegido, más la info del lote
  (tipología, m², precio) al seleccionarlo.
- `config.js` — URL y anon key de Supabase.
- `supabase/schema.sql` — instalación desde cero: tablas, catálogos, equipo y los 99 lotes.
- `supabase/migracion_v3.sql` — actualización sin pérdida de datos para una base que ya está viva.

## Quién llena qué en `lotes`

`propietario`, `gravado`, `banco` y `disponible` no vienen en la carga CAPI — los llena jurídico
con la propiedad, no ventas. Mientras `se_puede_separar` siga en `false` para un lote, la app no
deja mover ninguna negociación de ese lote a la etapa Separación (sí deja cotizar y visitar). Por
ahora esos cuatro campos se editan directo en la tabla `lotes` de Supabase; si hace falta, se le
puede agregar una pantalla dentro de Ajustes más adelante.
