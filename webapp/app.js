// NixOS Role Explorer - Main App Logic

// State
const state = {
    currentView: 'roles',
    roles: [],
    hosts: [],
    docs: {},
    theme: localStorage.getItem('theme') || 'dark'
};

// Theme Management
function initTheme() {
    const theme = localStorage.getItem('theme') || 'dark';
    document.body.setAttribute('data-theme', theme);
    updateThemeActiveState(theme);
}

function setTheme(themeName) {
    document.body.setAttribute('data-theme', themeName);
    localStorage.setItem('theme', themeName);
    state.theme = themeName;
    updateThemeActiveState(themeName);
    toggleThemeMenu();
}

function updateThemeActiveState(themeName) {
    document.querySelectorAll('.theme-option').forEach(btn => {
        btn.classList.remove('active');
    });
    const activeBtn = document.querySelector(`[data-theme="${themeName}"]`);
    if (activeBtn) {
        activeBtn.classList.add('active');
    }
}

function toggleThemeMenu() {
    const menu = document.getElementById('theme-menu');
    menu.classList.toggle('hidden');
}

// Navigation
function showView(viewName) {
    state.currentView = viewName;

    // Update nav
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-view="${viewName}"]`).classList.add('active');

    // Update views
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    document.getElementById(`${viewName}-view`).classList.add('active');

    // Load data if needed
    if (viewName === 'roles' && state.roles.length === 0) {
        loadRoles();
    } else if (viewName === 'hosts' && state.hosts.length === 0) {
        loadHosts();
    } else if (viewName === 'docs') {
        loadDocs();
    } else if (viewName === 'keybinds') {
        loadKeybinds();
    }
}

// Load Roles
async function loadRoles() {
    try {
        const response = await fetch('/api/roles');
        state.roles = await response.json();
        renderRoles();
    } catch (error) {
        console.error('Error loading roles:', error);
        document.getElementById('roles-content').innerHTML = renderEmpty('⚠️', 'Failed to load roles');
    }
}

function renderRoles() {
    const container = document.getElementById('roles-content');

    if (state.roles.length === 0) {
        container.innerHTML = renderEmpty('📦', 'No roles found');
        return;
    }

    container.innerHTML = `
        <div class="grid">
            ${state.roles.map(role => `
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">${role.name}</h3>
                        <span class="card-icon">🎭</span>
                    </div>
                    <div class="card-content">
                        <p>${role.description}</p>
                        <div class="card-meta">
                            <span>📦</span>
                            <span>~${role.packages} packages</span>
                        </div>
                    </div>
                    <div class="card-footer">${role.file}</div>
                </div>
            `).join('')}
        </div>
    `;
}

// Load Hosts
async function loadHosts() {
    try {
        const response = await fetch('/api/hosts');
        state.hosts = await response.json();
        renderHosts();
    } catch (error) {
        console.error('Error loading hosts:', error);
        document.getElementById('hosts-content').innerHTML = renderEmpty('⚠️', 'Failed to load hosts');
    }
}

function renderHosts() {
    const container = document.getElementById('hosts-content');

    if (state.hosts.length === 0) {
        container.innerHTML = renderEmpty('💻', 'No hosts configured');
        return;
    }

    container.innerHTML = `
        <div class="grid">
            ${state.hosts.map(host => `
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">${host.name}</h3>
                        <span class="card-icon">🖥️</span>
                    </div>
                    <div class="card-content">
                        <p><strong>Active Roles:</strong></p>
                        <div class="badges">
                            ${host.roles.length > 0
                                ? host.roles.map(role => `<span class="badge">${role}</span>`).join('')
                                : '<span style="color: var(--text-secondary)">No roles assigned</span>'
                            }
                        </div>
                    </div>
                    <div class="card-footer">${host.config}</div>
                </div>
            `).join('')}
        </div>
    `;
}

// Load Documentation
async function loadDocs() {
    try {
        const response = await fetch('/api/docs');
        state.docs = await response.json();
        renderDocs();
    } catch (error) {
        console.error('Error loading docs:', error);
        renderDocsError();
    }
}

function renderDocs() {
    const container = document.getElementById('docs-content');

    container.innerHTML = `
        <div class="docs-sidebar">
            <div class="docs-nav">
                <button class="docs-nav-item active" onclick="showDoc('quick-start')">📚 Quick Start</button>
                <button class="docs-nav-item" onclick="showDoc('roles')">🎭 Roles</button>
                <button class="docs-nav-item" onclick="showDoc('dev-env')">💻 Dev Environments</button>
                <button class="docs-nav-item" onclick="showDoc('hosts')">🖥️ Managing Hosts</button>
                <button class="docs-nav-item" onclick="showDoc('commands')">⌨️ Commands</button>
            </div>
        </div>
        <div class="docs-main" id="docs-main">
            ${renderDocContent('quick-start')}
        </div>
    `;
}

function showDoc(docName) {
    document.querySelectorAll('.docs-nav-item').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');

    document.getElementById('docs-main').innerHTML = renderDocContent(docName);
}

function renderDocContent(docName) {
    const docs = {
        'quick-start': `
            <h2>📚 Quick Start</h2>
            <div class="doc-content">
                <h3>Available Commands</h3>
                <div class="command-list">
                    <div class="command-item">
                        <code>nixos-docs</code>
                        <p>View documentation in terminal</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#role-explorer</code>
                        <p>Open this PWA</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#new-role NAME</code>
                        <p>Create a new role</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#new-host NAME</code>
                        <p>Create a new host</p>
                    </div>
                </div>

                <h3>Building Your System</h3>
                <pre><code>sudo nixos-rebuild switch --flake .#hostname</code></pre>

                <h3>Development Environments</h3>
                <pre><code>cd ~/myproject
echo "use flake ~/nixos-config#python" > .envrc
direnv allow</code></pre>
            </div>
        `,
        'roles': `
            <h2>🎭 Available Roles</h2>
            <div class="doc-content">
                ${state.roles.map(role => `
                    <div class="doc-section">
                        <h3>${role.name}</h3>
                        <p>${role.description}</p>
                        <p><strong>Packages:</strong> ~${role.packages}</p>
                        <p><strong>Location:</strong> <code>${role.file}</code></p>
                    </div>
                `).join('')}

                <h3>Using Roles</h3>
                <p>In <code>parts/hosts.nix</code>:</p>
                <pre><code>my-laptop = self.lib.mkSystem {
  hostname = "my-laptop";
  roles = [ "development" "niri-desktop" ];
};</code></pre>
            </div>
        `,
        'dev-env': `
            <h2>💻 Development Environments</h2>
            <div class="doc-content">
                <h3>Available Shells</h3>
                <ul>
                    <li><code>nix develop .#python</code> - Python 3.11, Poetry, pytest</li>
                    <li><code>nix develop .#rust</code> - Rust, Cargo, Clippy</li>
                    <li><code>nix develop .#node</code> - Node.js 20, npm, TypeScript</li>
                    <li><code>nix develop .#go</code> - Go toolchain</li>
                    <li><code>nix develop .#cpp</code> - GCC, Clang, CMake</li>
                    <li><code>nix develop .#web</code> - Full-stack (Node + Python)</li>
                </ul>

                <h3>Using direnv</h3>
                <pre><code># In your project directory
echo "use flake ~/nixos-config#python" > .envrc
direnv allow

# Environment auto-loads when you cd into directory!</code></pre>
            </div>
        `,
        'hosts': `
            <h2>🖥️ Managing Hosts</h2>
            <div class="doc-content">
                <h3>Current Hosts</h3>
                ${state.hosts.map(host => `
                    <div class="doc-section">
                        <h4>${host.name}</h4>
                        <p><strong>Roles:</strong> ${host.roles.join(', ') || 'None'}</p>
                        <p><strong>Config:</strong> <code>${host.config}</code></p>
                    </div>
                `).join('')}

                <h3>Adding a New Host</h3>
                <pre><code>nix run .#new-host my-laptop
# Edit hosts/my-laptop/default.nix
# Add to parts/hosts.nix
sudo nixos-rebuild switch --flake .#my-laptop</code></pre>
            </div>
        `,
        'commands': `
            <h2>⌨️ Command Reference</h2>
            <div class="doc-content">
                <div class="command-group">
                    <h3>Documentation</h3>
                    <div class="command-item">
                        <code>nixos-docs</code>
                        <p>CLI documentation viewer</p>
                    </div>
                    <div class="command-item">
                        <code>nixos-docs overview</code>
                        <p>System overview</p>
                    </div>
                    <div class="command-item">
                        <code>nixos-docs roles</code>
                        <p>List available roles</p>
                    </div>
                </div>

                <div class="command-group">
                    <h3>Tools</h3>
                    <div class="command-item">
                        <code>nix run .#role-explorer</code>
                        <p>Start this PWA</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#new-role NAME</code>
                        <p>Create new role</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#new-host NAME</code>
                        <p>Create new host</p>
                    </div>
                    <div class="command-item">
                        <code>nix run .#bootstrap URL HOST</code>
                        <p>Bootstrap fresh install</p>
                    </div>
                </div>
            </div>
        `
    };

    return docs[docName] || '<p>Documentation not found</p>';
}

function renderDocsError() {
    document.getElementById('docs-content').innerHTML = `
        <div class="doc-content">
            <h2>📚 Documentation</h2>
            <p>Documentation is available via CLI:</p>
            <pre><code>nixos-docs overview
nixos-docs roles
nixos-docs dev</code></pre>
        </div>
    `;
}

// Load Keybinds
function loadKeybinds() {
    const container = document.getElementById('keybinds-content');

    container.innerHTML = `
        <h2 style="margin-bottom: 1.5rem;">⌨️ Keyboard Shortcuts</h2>
        <div class="keybind-groups">
            <div class="keybind-group">
                <h3>System</h3>
                <div class="keybind-list">
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>Return</kbd>
                        <span>Open Terminal</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>D</kbd>
                        <span>Application Launcher</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>Q</kbd>
                        <span>Close Window</span>
                    </div>
                </div>
            </div>

            <div class="keybind-group">
                <h3>Window Management</h3>
                <div class="keybind-list">
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>H/L</kbd>
                        <span>Focus Left/Right</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>H/L</kbd>
                        <span>Move Window Left/Right</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>F</kbd>
                        <span>Toggle Fullscreen</span>
                    </div>
                </div>
            </div>

            <div class="keybind-group">
                <h3>Utilities</h3>
                <div class="keybind-list">
                    <div class="keybind-item">
                        <kbd>Print</kbd>
                        <span>Screenshot</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>L</kbd>
                        <span>Lock Screen</span>
                    </div>
                    <div class="keybind-item">
                        <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd>
                        <span>Exit/Logout</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="keybind-note">
            <p><strong>Note:</strong> These are default keybindings for Niri. Customize in your config file.</p>
            <p>Press <kbd>Super</kbd> + <kbd>?</kbd> to show this overlay anytime!</p>
        </div>
    `;
}

// Helpers
function renderEmpty(icon, message) {
    return `
        <div class="empty">
            <div class="empty-icon">${icon}</div>
            <p>${message}</p>
        </div>
    `;
}

// Refresh all data
async function refreshAll() {
    await Promise.all([loadRoles(), loadHosts()]);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    showView('roles');

    // Auto-refresh every 30 seconds
    setInterval(refreshAll, 30000);
});
