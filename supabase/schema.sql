-- ============================================================
-- QERCIA ¬∑ Tablero de negociaciones ‚Äî esquema Supabase
-- Copiar y pegar completo en Supabase ‚Üí SQL Editor ‚Üí Run
-- ============================================================
-- ANTES DE CORRER: reemplaza estos dos correos por los reales
-- de Enrique y Javier (los dos que ven todo el tablero).
-- Los dem√°s asesores empiezan con rol 'asesor' autom√°ticamente
-- al entrar por primera vez con su magic link, y un admin los
-- puede promover a 'admin' luego desde la pesta√±a Ajustes.
-- ============================================================
do $$
begin
  perform 1;
end $$;

create extension if not exists pgcrypto;

-- ---------- equipo ----------
create table if not exists public.equipo (
  id          uuid primary key references auth.users(id) on delete cascade,
  nombre      text not null,
  email       text not null unique,
  color       text not null default '#A9A296',
  rol         text not null default 'asesor' check (rol in ('asesor','admin')),
  activo      boolean not null default true,
  creado_en   timestamptz not null default now()
);

-- ---------- cat√°logos editables desde Ajustes ----------
create table if not exists public.motivos_perdida (
  id      uuid primary key default gen_random_uuid(),
  texto   text not null,
  orden   int not null default 0,
  activo  boolean not null default true
);

create table if not exists public.formas_pago (
  id      uuid primary key default gen_random_uuid(),
  texto   text not null,
  orden   int not null default 0,
  activo  boolean not null default true
);

create table if not exists public.origenes (
  id      uuid primary key default gen_random_uuid(),
  texto   text not null,
  orden   int not null default 0,
  activo  boolean not null default true
);

create table if not exists public.etapas (
  id        int primary key,
  nombre    text not null,
  meta      text not null default '',
  es_admin  boolean not null default false,
  orden     int not null default 0
);

-- ---------- lotes (carga CAPI) ----------
create table if not exists public.lotes (
  clave                text primary key,
  manzana              text,
  tipologia            text,
  m2                   numeric,
  precio               numeric,
  catastro_verificado  text
);

-- ---------- negociaciones ----------
create table if not exists public.negociaciones (
  id                    uuid primary key default gen_random_uuid(),
  cliente               text not null,
  telefono              text,
  origen                text,
  asesor_id             uuid not null references public.equipo(id),
  lote_clave            text references public.lotes(clave),
  forma_pago            text,
  etapa                 int not null default 0,
  cancha                text not null default 'nuestra' check (cancha in ('nuestra','cliente','tercero')),
  fecha_ultimo_contacto date,
  fecha_ultima_respuesta date,
  siguiente_paso        text,
  fecha_compromiso      date,
  notas                 text,
  agencia               text,
  broker                text,
  fecha_registro_broker date,
  reftipo               text,
  refquien              text,
  perdida               boolean not null default false,
  motivo_perdida        text,
  objecion              text,
  competidor            text,
  recontactar           date,
  etapa_muerte          int,
  creado_en             timestamptz not null default now(),
  actualizado_en        timestamptz not null default now()
);

create table if not exists public.bitacora (
  id              uuid primary key default gen_random_uuid(),
  negociacion_id  uuid not null references public.negociaciones(id) on delete cascade,
  fecha           date not null default current_date,
  texto           text not null,
  etapa           int,
  cancha          text,
  creado_en       timestamptz not null default now()
);

-- ---------- trigger: alta autom√°tica en equipo al primer login ----------
create or replace function public.on_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  es_admin_inicial boolean;
begin
  es_admin_inicial := new.email in (
    'enrique@popinvestments.com',
    'javier@popinvestments.com'
  );
  insert into public.equipo (id, nombre, email, rol)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    case when es_admin_inicial then 'admin' else 'asesor' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.on_auth_user_created();

-- ---------- helper: rol del usuario actual ----------
create or replace function public.es_admin()
returns boolean
language sql
security definer
stable
as $$
  select coalesce((select rol = 'admin' from public.equipo where id = auth.uid()), false);
$$;

-- ---------- RLS ----------
alter table public.equipo           enable row level security;
alter table public.negociaciones    enable row level security;
alter table public.bitacora         enable row level security;
alter table public.motivos_perdida  enable row level security;
alter table public.formas_pago      enable row level security;
alter table public.origenes         enable row level security;
alter table public.etapas           enable row level security;
alter table public.lotes            enable row level security;

-- equipo: todos leen (necesario para due√±os/colores/selects), solo admin edita
drop policy if exists equipo_select_all on public.equipo;
create policy equipo_select_all on public.equipo for select using (true);
drop policy if exists equipo_admin_write on public.equipo;
create policy equipo_admin_write on public.equipo for all using (public.es_admin()) with check (public.es_admin());

-- negociaciones: cada quien ve/edita solo las suyas; admin ve/edita todas
drop policy if exists negs_select on public.negociaciones;
create policy negs_select on public.negociaciones for select
  using (asesor_id = auth.uid() or public.es_admin());
drop policy if exists negs_insert on public.negociaciones;
create policy negs_insert on public.negociaciones for insert
  with check (asesor_id = auth.uid() or public.es_admin());
drop policy if exists negs_update on public.negociaciones;
create policy negs_update on public.negociaciones for update
  using (asesor_id = auth.uid() or public.es_admin());
drop policy if exists negs_delete on public.negociaciones;
create policy negs_delete on public.negociaciones for delete
  using (public.es_admin());

-- bit√°cora: sigue la visibilidad de la negociaci√≥n a la que pertenece
drop policy if exists bit_select on public.bitacora;
create policy bit_select on public.bitacora for select using (
  exists (select 1 from public.negociaciones n
          where n.id = negociacion_id and (n.asesor_id = auth.uid() or public.es_admin()))
);
drop policy if exists bit_insert on public.bitacora;
create policy bit_insert on public.bitacora for insert with check (
  exists (select 1 from public.negociaciones n
          where n.id = negociacion_id and (n.asesor_id = auth.uid() or public.es_admin()))
);

-- cat√°logos: todos leen, solo admin escribe
drop policy if exists cat_sel_motivos on public.motivos_perdida;
create policy cat_sel_motivos on public.motivos_perdida for select using (true);
drop policy if exists cat_adm_motivos on public.motivos_perdida;
create policy cat_adm_motivos on public.motivos_perdida for all using (public.es_admin()) with check (public.es_admin());

drop policy if exists cat_sel_pago on public.formas_pago;
create policy cat_sel_pago on public.formas_pago for select using (true);
drop policy if exists cat_adm_pago on public.formas_pago;
create policy cat_adm_pago on public.formas_pago for all using (public.es_admin()) with check (public.es_admin());

drop policy if exists cat_sel_origenes on public.origenes;
create policy cat_sel_origenes on public.origenes for select using (true);
drop policy if exists cat_adm_origenes on public.origenes;
create policy cat_adm_origenes on public.origenes for all using (public.es_admin()) with check (public.es_admin());

drop policy if exists cat_sel_etapas on public.etapas;
create policy cat_sel_etapas on public.etapas for select using (true);
drop policy if exists cat_adm_etapas on public.etapas;
create policy cat_adm_etapas on public.etapas for all using (public.es_admin()) with check (public.es_admin());

drop policy if exists lotes_select on public.lotes;
create policy lotes_select on public.lotes for select using (true);
drop policy if exists lotes_admin_write on public.lotes;
create policy lotes_admin_write on public.lotes for all using (public.es_admin()) with check (public.es_admin());

-- ---------- datos iniciales de cat√°logos ----------
insert into public.etapas (id, nombre, meta, es_admin, orden) values
  (0,'Registro','sale al contactarlo ¬∑ 15 min', false, 0),
  (1,'Contactado','sale al calificarlo ¬∑ SLA sin definir', false, 1),
  (2,'Prospecto','sale al agendar visita ¬∑ 72 h', false, 2),
  (3,'Visita','sale al cotizar ¬∑ mismo d√≠a', false, 3),
  (4,'Cotizaci√≥n','sale al acordar condiciones ¬∑ SLA sin definir', false, 4),
  (5,'Negociaci√≥n','sale al separar ¬∑ 24 h', false, 5),
  (6,'Separaci√≥n','sale al firmar contrato ¬∑ SLA sin definir', false, 6),
  (7,'Contrato','administraci√≥n de ventas', true, 7),
  (8,'Escrituraci√≥n','depende de la liberaci√≥n', true, 8)
on conflict (id) do nothing;

insert into public.motivos_perdida (texto, orden) values
  ('Precio arriba de su presupuesto',1),
  ('No calific√≥ para el cr√©dito',2),
  ('Compr√≥ en otro desarrollo',3),
  ('Ubicaci√≥n o distancia',4),
  ('Topograf√≠a o pendiente del lote',5),
  ('Urbanizaci√≥n o servicios pendientes',6),
  ('Tiempos de escrituraci√≥n',7),
  ('No volvi√≥ a responder',8),
  ('Solo estaba explorando',9),
  ('Se pospuso, recontactar despu√©s',10),
  ('Otro',11)
on conflict do nothing;

insert into public.formas_pago (texto, orden) values
  ('Por definir',1),('Contado',2),('Cr√©dito hipotecario',3),
  ('Plazo con el desarrollador',4),('Otro',5)
on conflict do nothing;

insert into public.origenes (texto, orden) values
  ('Meta',1),('Google',2),('Portal inmobiliario',3),
  ('Br√≥ker externo',4),('Referido',5),('Caseta o visita espont√°nea',6),('Otro',7)
on conflict do nothing;

