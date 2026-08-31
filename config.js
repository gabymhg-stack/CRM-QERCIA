// Config del tablero QERCIA. La URL ya está puesta; falta la anon key.
// Se saca de Supabase → Project Settings → API → "anon public".
// Es segura de exponer aquí: las reglas RLS son las que de verdad protegen los datos.
window.QERCIA_CONFIG = {
  SUPABASE_URL: "https://nvvmqstcagskdkgfropc.supabase.co",
  SUPABASE_ANON_KEY: "PENDIENTE_PEGAR_ANON_KEY"
};
