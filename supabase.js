// ============================================================
// VALCRIUM — Supabase Client
// Include this before app.html scripts
// ============================================================

const SUPABASE_URL  = window.ENV_SUPABASE_URL  || 'YOUR_SUPABASE_URL';
const SUPABASE_ANON = window.ENV_SUPABASE_ANON || 'YOUR_SUPABASE_ANON_KEY';

const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON);

// ── Auth helpers ─────────────────────────────────────────────

async function signUp(email, password, fullName, firmName) {
  const { data, error } = await db.auth.signUp({
    email, password,
    options: { data: { full_name: fullName, firm_name: firmName } }
  });
  if (error) throw error;
  // Create profile
  await db.from('profiles').upsert({
    id: data.user.id,
    full_name: fullName,
    firm_name: firmName
  });
  return data;
}

async function signIn(email, password) {
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

async function signOut() {
  await db.auth.signOut();
  window.location.href = '/';
}

async function getUser() {
  const { data: { user } } = await db.auth.getUser();
  return user;
}

async function getProfile() {
  const user = await getUser();
  if (!user) return null;
  const { data } = await db.from('profiles').select('*').eq('id', user.id).single();
  return data;
}

// ── Companies ────────────────────────────────────────────────

async function getCompanies() {
  const { data, error } = await db.from('companies').select('*').order('name');
  if (error) throw error;
  return data;
}

async function saveCompany(company) {
  const user = await getUser();
  const { data, error } = await db.from('companies')
    .upsert({ ...company, user_id: user.id })
    .select().single();
  if (error) throw error;
  return data;
}

async function deleteCompany(id) {
  const { error } = await db.from('companies').delete().eq('id', id);
  if (error) throw error;
}

// ── Objectives ───────────────────────────────────────────────

async function getObjectives(companyId) {
  let q = db.from('objectives').select('*, companies(name, color)').order('created_at');
  if (companyId) q = q.eq('company_id', companyId);
  const { data, error } = await q;
  if (error) throw error;
  return data;
}

async function saveObjective(objective) {
  const user = await getUser();
  const { data, error } = await db.from('objectives')
    .upsert({ ...objective, user_id: user.id })
    .select().single();
  if (error) throw error;
  return data;
}

// ── Initiatives ──────────────────────────────────────────────

async function getInitiatives(companyId, objectiveId) {
  let q = db.from('initiatives')
    .select('*, companies(name, color), objectives(name)')
    .order('created_at');
  if (companyId)   q = q.eq('company_id', companyId);
  if (objectiveId) q = q.eq('objective_id', objectiveId);
  const { data, error } = await q;
  if (error) throw error;
  return data;
}

async function saveInitiative(initiative) {
  const user = await getUser();
  const { data, error } = await db.from('initiatives')
    .upsert({ ...initiative, user_id: user.id })
    .select().single();
  if (error) throw error;
  return data;
}

async function markComplete(initiativeId, completedDate, completedBy) {
  const { data, error } = await db.from('initiatives')
    .update({
      status: 'Completed',
      pct: 100,
      completed_date: completedDate,
      completed_by: completedBy,
      completed_at: new Date().toISOString()
    })
    .eq('id', initiativeId)
    .select().single();
  if (error) throw error;
  return data;
}

// ── KPI Data ─────────────────────────────────────────────────

async function getQuantitativeInitiatives() {
  const { data, error } = await db.from('initiatives')
    .select('*, companies(name)')
    .eq('is_quantitative', true)
    .order('title');
  if (error) throw error;
  return data;
}

async function saveKPIEntry(initiativeId, period, value, notes) {
  const user = await getUser();
  const { data, error } = await db.from('kpi_data')
    .insert({ initiative_id: initiativeId, period, value, notes, user_id: user.id })
    .select().single();
  if (error) throw error;
  return data;
}

async function getKPIData(initiativeId) {
  const { data, error } = await db.from('kpi_data')
    .select('*')
    .eq('initiative_id', initiativeId)
    .order('recorded_at', { ascending: false });
  if (error) throw error;
  return data;
}

// ── Notes ────────────────────────────────────────────────────

async function getNotes(entityType, entityId) {
  const { data, error } = await db.from('notes')
    .select('*')
    .eq('entity_type', entityType)
    .eq('entity_id', entityId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function addNote(entityType, entityId, text, authorName) {
  const user = await getUser();
  const { data, error } = await db.from('notes')
    .insert({ entity_type: entityType, entity_id: entityId, text, author_name: authorName, user_id: user.id })
    .select().single();
  if (error) throw error;
  return data;
}

// ── Auth state change listener ───────────────────────────────

db.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    window.location.href = '/';
  }
  if (event === 'SIGNED_IN' && window.location.pathname === '/') {
    window.location.href = '/app.html';
  }
});
