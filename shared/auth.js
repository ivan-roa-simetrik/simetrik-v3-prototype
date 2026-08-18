// Wrapper mínimo sobre supabase-js — mismo patrón ya validado en
// mock-v3/shared/auth.js (repo hermano), adaptado a este proyecto Supabase
// separado. Requiere que supabase-config.js y el script de supabase-js (CDN)
// ya estén cargados antes de este archivo.

function getSupabaseClient() {
  if (!window.SIMETRIK_SUPABASE_CONFIG) {
    throw new Error('Falta cargar shared/supabase-config.js antes de shared/auth.js');
  }
  const { url, anonKey } = window.SIMETRIK_SUPABASE_CONFIG;
  return window.supabase.createClient(url, anonKey);
}

// Usar en cualquier pantalla que requiera sesión (hoy: flows/home/index.html).
// Si no hay sesión activa, redirige a loginPath y devuelve null.
async function requireSession(loginPath) {
  const client = getSupabaseClient();
  const { data } = await client.auth.getSession();
  if (!data.session) {
    window.location.href = loginPath;
    return null;
  }
  return { client, session: data.session };
}

async function signOutAndRedirect(client, loginPath) {
  await client.auth.signOut();
  window.location.href = loginPath;
}
