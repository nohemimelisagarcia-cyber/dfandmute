import { apiService, supabase } from './supabaseClient.js';

// Mapeo oficial de Roles
const ROLES = {
    1: { id: 1, name: 'Admin', key: 'admin' },
    2: { id: 2, name: 'Usuario', key: 'user' },
    3: { id: 3, name: 'Auditor', key: 'auditor' }
};

let currentUser = null;

// ==================== NAVEGACIÓN Y PANTALLAS ====================
window.showScreen = async function(screenName) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    const screen = document.getElementById(`screen-${screenName}`);
    if (screen) { 
        screen.classList.add('active'); 
        window.scrollTo(0, 0); 
    }

    const header = document.getElementById('mainHeader');
    const footer = document.getElementById('mainFooter');

    if (currentUser) {
        if (header) header.style.display = 'flex';
        if (footer) footer.style.display = 'block';
        applyRoleVisibility();
    } else {
        if (header) header.style.display = 'none';
        if (footer) footer.style.display = 'none';
    }

    // Cargar datos reales desde el backend según la pantalla activa
    if (screenName === 'levels') cargarNivelesReales();
    if (screenName === 'admin') cargarAdminData();
    if (screenName === 'auditor') cargarAuditLogs();
};

window.toggleSidebar = function() {
    document.getElementById('sidebar')?.classList.toggle('open');
    document.querySelector('.sidebar-overlay')?.classList.toggle('active');
};

function applyRoleVisibility() {
    document.body.classList.remove('is-admin', 'is-user', 'is-auditor');
    if (!currentUser) return;

    const roleKey = currentUser.role?.key || 'user';
    document.body.classList.add(`is-${roleKey}`);

    const badge = document.getElementById('userRoleBadge');
    if (badge) {
        badge.textContent = currentUser.role?.name || 'Usuario';
        badge.className = `role-badge role-${roleKey}`;
    }
}

// ==================== AUTENTICACIÓN CON SUPABASE ====================
window.handleLogin = async function(e) {
    e.preventDefault();
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;

    try {
        // 1. Iniciar sesión real en Supabase Auth
        const authData = await apiService.login(email, password);
        
        // 2. Obtener datos del perfil desde public.users
        const userData = await apiService.getUserProfile(email);

        const roleId = userData ? userData.rol_id : 2;
        const roleObj = ROLES[roleId] || ROLES[2];

        currentUser = {
            id: userData ? userData.id : authData.user.id,
            name: userData ? `${userData.nombre} ${userData.apellido}` : email,
            email: authData.user.email,
            role: roleObj
        };

        // 3. Actualizar la interfaz
        const nameDisplay = document.getElementById('userNameDisplay');
        const profileName = document.getElementById('profileName');
        if (nameDisplay) nameDisplay.innerText = currentUser.name;
        if (profileName) profileName.innerText = currentUser.name;

        applyRoleVisibility();
        showToast(`¡Bienvenido, ${currentUser.name}!`, 'success');
        window.showScreen('home');

    } catch (err) {
        console.error("Error en inicio de sesión:", err);
        showToast("Correo o contraseña incorrectos", 'error');
    }
};

window.handleRegister = async function(e) {
    e.preventDefault();
    const nombre = document.getElementById('regName').value;
    const apellido = document.getElementById('regLastName').value;
    const email = document.getElementById('regEmail').value;
    const password = document.getElementById('regPassword').value;
    const pass2 = document.getElementById('regPassword2').value;
    const roleId = parseInt(document.getElementById('regRole').value);

    if (password !== pass2) { 
        showToast("Las contraseñas no coinciden", 'error'); 
        return; 
    }

    try {
        await apiService.signUp(email, password, nombre, apellido, roleId);
        showToast("Cuenta registrada en Supabase correctamente", 'success');
        window.showScreen('login');
    } catch (err) {
        console.error("Error en registro:", err);
        showToast("Error al registrar: " + err.message, 'error');
    }
};

window.logout = async function() {
    if (typeof supabase !== 'undefined') {
        await supabase.auth.signOut();
    }
    currentUser = null;
    document.body.classList.remove('is-admin', 'is-user', 'is-auditor');
    window.showScreen('login');
    showToast('Sesión cerrada', 'success');
};

// ==================== CARGA DE DATOS DESDE SUPABASE ====================

// 1. CONTROLADOR DE NIVELES
window.cargarNivelesReales = async function() {
    const container = document.getElementById('screen-levels');
    if (!container) return;

    try {
        const niveles = await apiService.getLevelsWithLessons();
        let html = `
            <div class="card">
                <h2>Niveles de Aprendizaje</h2>
                <p style="color: var(--text-light); margin-bottom: 2rem;">Contenido cargado en tiempo real desde Supabase</p>
                <div class="levels-grid">
        `;

        niveles.forEach(lvl => {
            const statusClass = lvl.activo ? 'active' : 'locked';
            html += `
                <div class="level-card ${statusClass}">
                    <div class="level-number">${lvl.orden}</div>
                    <div class="level-title">${lvl.nombre}</div>
                    <div class="level-desc">${lvl.descripcion || ''}</div>
                    <p style="font-size:0.8rem; margin-top:0.5rem; color:var(--text-light);">
                        Lecciones asociadas: ${lvl.lessons ? lvl.lessons.length : 0}
                    </p>
                    <div class="level-progress">
                        <div class="level-progress-bar" style="width: 0%"></div>
                    </div>
                </div>
            `;
        });

        html += '</div></div>';
        container.innerHTML = html;
    } catch (err) {
        console.error("Error al cargar niveles desde el backend:", err);
        showToast("Error al cargar niveles", "error");
    }
};

// 2. CONTROLADOR DEL PANEL DE ADMIN
window.cargarAdminData = async function() {
    try {
        const usuarios = await apiService.getUsersList();
        const tableBody = document.getElementById('adminUsersBody');
        if (!tableBody) return;

        tableBody.innerHTML = usuarios.map(u => `
            <tr>
                <td>${u.id}</td>
                <td>${u.nombre} ${u.apellido}</td>
                <td>${u.email}</td>
                <td><span class="role-badge role-${u.roles?.nombre.toLowerCase() || 'user'}">${u.roles?.nombre || 'Usuario'}</span></td>
                <td>${u.nivel_actual || 1}</td>
                <td><span class="status-dot ${u.activo ? 'status-active' : 'status-inactive'}"></span> ${u.activo ? 'Activo' : 'Inactivo'}</td>
                <td><button class="btn btn-secondary" style="padding:0.2rem 0.5rem; font-size:0.8rem;">Editar</button></td>
            </tr>
        `).join('');
    } catch (err) {
        console.error("Error al cargar datos de admin:", err);
    }
};

// 3. CONTROLADOR DE LOGS DE AUDITORÍA
window.cargarAuditLogs = async function() {
    try {
        const logs = await apiService.getAuditLogs();
        const container = document.getElementById('auditLogsContainer');
        if (!container) return;

        container.innerHTML = logs.map(log => `
            <div class="auditor-log-card">
                <div style="display:flex; justify-content:space-between;">
                    <span class="auditor-log-action">${log.accion} en ${log.tabla_afectada}</span>
                    <span class="auditor-log-time">${new Date(log.created_at).toLocaleString()}</span>
                </div>
                <div class="auditor-log-detail">Registro ID: ${log.registro_id || 'N/A'}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error("Error al cargar logs:", err);
    }
};

// ==================== UTILIDADES DE UI ====================
window.showToast = function(message, type = '') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.textContent = message;
    toast.className = `toast ${type} show`;
    setTimeout(() => toast.classList.remove('show'), 3000);
};

// Inicialización de la aplicación
document.addEventListener('DOMContentLoaded', () => {
    window.showScreen('login');
});