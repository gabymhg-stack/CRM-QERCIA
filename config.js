// Config del tablero QERCIA. La URL ya está puesta; falta la anon key.
// Se saca de Supabase → Project Settings → API → "anon public".
// Es segura de exponer aquí: las reglas RLS son las que de verdad protegen los datos.
window.QERCIA_CONFIG = {
  SUPABASE_URL: "https://nvvmqstcagskdkgfropc.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52dm1xc3RjYWdza2RrZ2Zyb3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxOTg0MTYsImV4cCI6MjEwMzc3NDQxNn0.YXDMO2AF7FaoIQpm4NIwWLdB8uaLjOR5eSPoLZo8iX8"
};
