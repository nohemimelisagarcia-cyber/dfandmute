import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'https://nxkjtuepsfnifllcerav.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_wEQMvMw4RKXyBdMrWoIxhg_-VKgr11m';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export const apiService = {
  // --- AUTENTICACIÓN ---
  async login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  },

  async signUp(email, password, nombre, apellido, rolId) {
    // 1. Crear usuario en Supabase Auth con metadatos
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          nombre: nombre,
          apellido: apellido,
          rol_id: rolId
        }
      }
    });
    if (error) throw error;

    // 2. Guardar datos complementarios en la tabla public.users
    if (data.user) {
      const { error: dbError } = await supabase.from('users').insert([
        { 
          id: data.user.id, // UUID retornado por Supabase Auth
          nombre: nombre, 
          apellido: apellido, 
          email: email, 
          rol_id: rolId,
          password_hash: 'AUTH_MANAGED' 
        }
      ]);
      if (dbError) console.error("Error al guardar en tabla users:", dbError);
    }
    return data;
  },

  // --- OBTENCIÓN DE DATOS DE PERFIL Y ROLES ---
  async getUserProfile(email) {
    const { data, error } = await supabase
      .from('users')
      .select('*, roles(nombre)')
      .eq('email', email)
      .single();
    if (error) console.warn("No se encontró perfil público:", error.message);
    return data;
  },

  // --- LECTURA DE LECCIONES Y CONTENIDO ---
  async getLevelsWithLessons() {
    const { data, error } = await supabase
      .from('levels')
      .select('*, lessons(*)')
      .eq('activo', true)
      .order('orden', { ascending: true });
    if (error) throw error;
    return data;
  },

  async getSigns() {
    const { data, error } = await supabase
      .from('signs')
      .select('*')
      .eq('activo', true)
      .order('orden', { ascending: true });
    if (error) throw error;
    return data;
  },

  // --- ESCRITURA Y ACTUALIZACIÓN DE PROGRESO ---
  async saveUserProgress(userId, lessonId, score) {
    const { data, error } = await supabase
      .from('progress')
      .upsert({
        user_id: userId,
        lesson_id: lessonId,
        score: score,
        completado: score >= 70,
        completed_at: new Date().toISOString()
      }, { onConflict: 'user_id,lesson_id' });
    if (error) throw error;
    return data;
  },

  // --- VISTAS DE ADMINISTRACIÓN Y AUDITORÍA ---
  async getUsersList() {
    const { data, error } = await supabase
      .from('users')
      .select('*, roles(nombre)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getAuditLogs() {
    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(20);
    if (error) throw error;
    return data;
  }
};