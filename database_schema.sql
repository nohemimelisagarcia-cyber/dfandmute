
-- ============================================================
-- DEAF AND MUTE - Base de Datos Relacional (2FN)
-- Hackathon MINED El Rama 2026
-- ============================================================

-- Eliminación segura de tablas
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS evaluations;
DROP TABLE IF EXISTS progress;
DROP TABLE IF EXISTS signs;
DROP TABLE IF EXISTS lessons;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- ============================================================
-- 1. TABLA ROLES (Catálogo independiente)
-- ============================================================
CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    permisos    JSONB DEFAULT '{}',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar los 3 roles requeridos
INSERT INTO roles (nombre, descripcion, permisos) VALUES
('Admin', 'Administrador del sistema. Gestiona usuarios, contenido y configuración.', 
 '{"users":["create","read","update","delete"],"content":["create","read","update","delete"],"reports":["read","export"],"audit":["read"]}'),

('Usuario', 'Estudiante de LSN. Accede a lecciones, práctica y evaluaciones.', 
 '{"users":["read","update_own"],"content":["read"],"progress":["create","read","update"],"evaluations":["create","read"]}'),

('Auditor', 'Supervisa actividades y genera reportes. Solo lectura en contenido.', 
 '{"users":["read"],"content":["read"],"reports":["read","export"],"audit":["read","export"],"logs":["read"]}');

-- ============================================================
-- 2. TABLA USUARIOS
-- ============================================================
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    rol_id          INTEGER NOT NULL DEFAULT 2,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    avatar_url      VARCHAR(255),
    nivel_actual    INTEGER DEFAULT 1,
    progreso_total  INTEGER DEFAULT 0,
    activo          BOOLEAN DEFAULT TRUE,
    email_verified  BOOLEAN DEFAULT FALSE,
    last_login      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_rol FOREIGN KEY (rol_id) REFERENCES roles(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Índices para búsquedas frecuentes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_rol ON users(rol_id);
CREATE INDEX idx_users_activo ON users(activo);

-- ============================================================
-- 3. TABLA NIVELES
-- ============================================================
CREATE TABLE levels (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    orden       INTEGER UNIQUE NOT NULL,
    total_lessons INTEGER DEFAULT 0,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO levels (nombre, descripcion, orden, total_lessons) VALUES
('Abecedario', 'Letras A-Z en LSN', 1, 26),
('Palabras Básicas', 'Saludos, familia, colores, números, días', 2, 23),
('Frases Básicas', 'Comunicación diaria esencial', 3, 8),
('Conversaciones', 'Diálogos en contextos reales', 4, 3),
('Historias y Situaciones', 'Narrativas y contextos avanzados', 5, 2);

-- ============================================================
-- 4. TABLA LECCIONES
-- ============================================================
CREATE TABLE lessons (
    id          SERIAL PRIMARY KEY,
    level_id    INTEGER NOT NULL,
    titulo      VARCHAR(150) NOT NULL,
    contenido   TEXT,
    tipo        VARCHAR(50) DEFAULT 'teoria', -- teoria, practica, evaluacion
    orden       INTEGER NOT NULL,
    puntaje_minimo INTEGER DEFAULT 70,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lesson_level FOREIGN KEY (level_id) REFERENCES levels(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_lessons_level ON lessons(level_id);
CREATE INDEX idx_lessons_tipo ON lessons(tipo);

-- ============================================================
-- 5. TABLA SEÑAS (Contenido didáctico)
-- ============================================================
CREATE TABLE signs (
    id          SERIAL PRIMARY KEY,
    lesson_id   INTEGER,
    palabra     VARCHAR(100) NOT NULL,
    signo_emojis VARCHAR(100),
    descripcion TEXT,
    categoria   VARCHAR(50), -- saludos, familia, colores, numeros, dias
    imagen_url  VARCHAR(255),
    video_url   VARCHAR(255),
    orden       INTEGER DEFAULT 0,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sign_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX idx_signs_categoria ON signs(categoria);
CREATE INDEX idx_signs_palabra ON signs(palabra);

-- ============================================================
-- 6. TABLA PROGRESO (Relación Usuario-Lección)
-- ============================================================
CREATE TABLE progress (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL,
    lesson_id   INTEGER NOT NULL,
    completado  BOOLEAN DEFAULT FALSE,
    score       INTEGER DEFAULT 0,
    intentos    INTEGER DEFAULT 0,
    tiempo_segundos INTEGER DEFAULT 0,
    completed_at TIMESTAMP,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_progress_user FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_progress_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_progress_user_lesson UNIQUE (user_id, lesson_id)
);

CREATE INDEX idx_progress_user ON progress(user_id);
CREATE INDEX idx_progress_completado ON progress(completado);

-- ============================================================
-- 7. TABLA EVALUACIONES
-- ============================================================
CREATE TABLE evaluations (
    id          SERIAL PRIMARY KEY,
    lesson_id   INTEGER NOT NULL,
    preguntas   JSONB NOT NULL, -- Array de preguntas y opciones
    duracion_min INTEGER DEFAULT 10,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_eval_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 8. TABLA RESULTADOS
-- ============================================================
CREATE TABLE results (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    evaluation_id   INTEGER NOT NULL,
    respuestas      JSONB,
    score           INTEGER NOT NULL,
    aprobado        BOOLEAN DEFAULT FALSE,
    tiempo_segundos INTEGER DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_result_user FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_result_eval FOREIGN KEY (evaluation_id) REFERENCES evaluations(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_results_user ON results(user_id);
CREATE INDEX idx_results_aprobado ON results(aprobado);

-- ============================================================
-- 9. TABLA AUDIT LOGS (Para rol Auditor)
-- ============================================================
CREATE TABLE audit_logs (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER,
    accion          VARCHAR(50) NOT NULL, -- CREATE, READ, UPDATE, DELETE, LOGIN, LOGOUT
    tabla_afectada  VARCHAR(50),
    registro_id     INTEGER,
    datos_anteriores JSONB,
    datos_nuevos    JSONB,
    ip_address      INET,
    user_agent      VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_accion ON audit_logs(accion);
CREATE INDEX idx_audit_tabla ON audit_logs(tabla_afectada);
CREATE INDEX idx_audit_fecha ON audit_logs(created_at);

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista: Progreso por usuario
CREATE VIEW v_user_progress AS
SELECT 
    u.id AS user_id,
    u.nombre || ' ' || u.apellido AS nombre_completo,
    r.nombre AS rol,
    l.nombre AS nivel,
    COUNT(DISTINCT p.lesson_id) AS lecciones_completadas,
    COUNT(DISTINCT les.id) AS total_lecciones_nivel,
    ROUND(COUNT(DISTINCT p.lesson_id) * 100.0 / NULLIF(COUNT(DISTINCT les.id), 0), 2) AS porcentaje
FROM users u
JOIN roles r ON u.rol_id = r.id
LEFT JOIN levels l ON l.orden = u.nivel_actual
LEFT JOIN lessons les ON les.level_id = l.id
LEFT JOIN progress p ON p.user_id = u.id AND p.completado = TRUE
WHERE u.activo = TRUE
GROUP BY u.id, u.nombre, u.apellido, r.nombre, l.nombre;

-- Vista: Actividad reciente para auditores
CREATE VIEW v_recent_activity AS
SELECT 
    a.id,
    u.email AS usuario,
    a.accion,
    a.tabla_afectada,
    a.registro_id,
    a.ip_address,
    a.created_at
FROM audit_logs a
LEFT JOIN users u ON a.user_id = u.id
ORDER BY a.created_at DESC;

-- ============================================================
-- FUNCION PARA REGISTRAR AUDITORÍA AUTOMÁTICA
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (user_id, accion, tabla_afectada, registro_id, datos_anteriores)
        VALUES (current_setting('app.current_user_id')::INTEGER, 'DELETE', TG_TABLE_NAME, OLD.id, row_to_json(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (user_id, accion, tabla_afectada, registro_id, datos_anteriores, datos_nuevos)
        VALUES (current_setting('app.current_user_id')::INTEGER, 'UPDATE', TG_TABLE_NAME, NEW.id, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (user_id, accion, tabla_afectada, registro_id, datos_nuevos)
        VALUES (current_setting('app.current_user_id')::INTEGER, 'CREATE', TG_TABLE_NAME, NEW.id, row_to_json(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a tablas críticas
CREATE TRIGGER trg_users_audit AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_progress_audit AFTER INSERT OR UPDATE OR DELETE ON progress
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_results_audit AFTER INSERT OR UPDATE OR DELETE ON results
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- ============================================================
-- DATOS DE EJEMPLO
-- ============================================================

-- Usuario Admin
INSERT INTO users (rol_id, nombre, apellido, email, password_hash, nivel_actual, activo)
VALUES (1, 'Administrador', 'Sistema', 'admin@deafmute.ni', '$2b$12$hashseguro123', 5, TRUE);

-- Usuario de prueba
INSERT INTO users (rol_id, nombre, apellido, email, password_hash, nivel_actual, activo)
VALUES (2, 'Estudiante', 'Prueba', 'estudiante@email.com', '$2b$12$hashseguro456', 1, TRUE);

-- Auditor de prueba
INSERT INTO users (rol_id, nombre, apellido, email, password_hash, nivel_actual, activo)
VALUES (3, 'Auditor', 'MINED', 'auditor@mined.ni', '$2b$12$hashseguro789', 1, TRUE);

-- Señas de ejemplo (Abecedario)
INSERT INTO signs (palabra, signo_emojis, descripcion, categoria, orden) VALUES
('A', '👊', 'Puño cerrado, pulgar al lado', 'abecedario', 1),
('B', '✋', 'Palma abierta, dedos juntos', 'abecedario', 2),
('C', '🤏', 'Forma de C con los dedos', 'abecedario', 3),
('D', '👆', 'Índice arriba, otros dedos cerrados', 'abecedario', 4),
('E', '✊', 'Dedos doblados, pulgar cruzado', 'abecedario', 5);

-- Señas de ejemplo (Palabras básicas)
INSERT INTO signs (palabra, signo_emojis, descripcion, categoria, orden) VALUES
('Hola', '✌️👌🤘✊', 'Saludo inicial', 'saludos', 1),
('Gracias', '🙏', 'Agradecimiento', 'saludos', 2),
('Mamá', '🫵✊🫵✊', 'Referencia a la madre', 'familia', 1),
('Papá', '👇✊👇✊', 'Referencia al padre', 'familia', 2),
('Rojo', '🔴🤞👌🤙👌', 'Color primario', 'colores', 1);

COMMIT;
