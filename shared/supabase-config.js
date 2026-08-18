// Proyecto Supabase de Simetrik v3.1 — separado del que usa mock-v3 (decisión
// confirmada 2026-08-14, ver memoria "supabase-migration-diagnosis"). La
// publishable/anon key es segura para exponer en el cliente: el acceso real
// a los datos lo controla RLS en el servidor, no el secreto de esta key.
window.SIMETRIK_SUPABASE_CONFIG = {
  url: 'https://ponrsihkujkkqefkznor.supabase.co',
  anonKey: 'sb_publishable_xkhyIH9RwK886NqQLFjWCQ_ZTt-bq2K',
};
