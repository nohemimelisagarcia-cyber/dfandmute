-- ============================================================
-- POLÍTICAS DE SEGURIDAD (RLS) - DEAF AND MUTE
-- ============================================================

-- 1. Habilitar RLS en las tablas principales
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 2. Políticas para TABLA USERS
CREATE POLICY "Admins y Auditores leen todos los usuarios" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM roles r WHERE r.id = (SELECT rol_id FROM users WHERE email = auth.email())
      AND r.nombre IN ('Admin', 'Auditor')
    )
  );

CREATE POLICY "Usuarios gestionan su propio perfil" ON users
  FOR ALL USING (email = auth.email());

-- 3. Políticas para TABLA PROGRESS
CREATE POLICY "Progreso personal del usuario" ON progress
  FOR ALL USING (
    user_id = (SELECT id FROM users WHERE email = auth.email())
  );

CREATE POLICY "Lectura global de progreso" ON progress
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM roles r WHERE r.id = (SELECT rol_id FROM users WHERE email = auth.email())
      AND r.nombre IN ('Admin', 'Auditor')
    )
  );

-- 4. Políticas para TABLA AUDIT_LOGS
CREATE POLICY "Acceso restringido a logs" ON audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM roles r WHERE r.id = (SELECT rol_id FROM users WHERE email = auth.email())
      AND r.nombre IN ('Admin', 'Auditor')
    )
  );