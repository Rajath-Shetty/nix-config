# Role Explorer Progressive Web App

A modern, installable web app for exploring your NixOS role-based configuration.

## Features

- 🎨 **Modern UI**: Dark theme with gradient cards and smooth animations
- 📱 **Installable**: Add to home screen/desktop like a native app
- 🔄 **Auto-refresh**: Updates data every 30 seconds
- 📡 **Offline Support**: Service worker caches app for offline use
- 🚀 **Fast**: Single-page app with no build step needed
- 📊 **Real-time**: Live data from your flake configuration

## Running

```bash
# From your nixos-config directory
nix run .#role-explorer

# Custom port
PORT=3000 nix run .#role-explorer
```

## Installing as PWA

### Desktop (Chrome/Edge)
1. Open http://localhost:8080
2. Look for install prompt or click install button
3. Or: Browser menu → "Install NixOS Role Explorer"
4. App appears in your applications

### Mobile
1. Open in mobile browser
2. Tap "Add to Home Screen"
3. App icon appears on home screen
4. Opens fullscreen like native app

### Benefits of Installing
- Quick access from dock/app drawer
- Runs in standalone window (no browser chrome)
- App icon and splash screen
- Offline functionality
- OS-level integration

## Architecture

```
webapp/
├── index.html       # Main app UI (vanilla JS, no framework)
├── manifest.json    # PWA manifest
├── sw.js           # Service worker for offline support
├── icon.svg        # App icon (NixOS snowflake)
└── README.md       # This file
```

### Tech Stack
- **Frontend**: Vanilla JavaScript (no build step!)
- **Styling**: CSS with modern features (grid, gradients, animations)
- **Backend**: Python HTTP server (parts/role-explorer.py)
- **APIs**: `/api/roles`, `/api/hosts`
- **PWA**: Service Worker + Web App Manifest

## API Endpoints

### GET /api/roles
Returns array of available roles:
```json
[
  {
    "name": "gaming",
    "description": "Role: gaming",
    "packages": 15,
    "file": "modules/roles/gaming.nix"
  }
]
```

### GET /api/hosts
Returns array of configured hosts:
```json
[
  {
    "name": "gaming-rig",
    "roles": ["gaming", "development"],
    "config": "hosts/gaming-rig/default.nix"
  }
]
```

## Customization

### Changing Theme Colors
Edit [index.html](index.html) CSS variables:
```css
:root {
    --primary: #667eea;
    --primary-dark: #5568d3;
    --secondary: #764ba2;
    --background: #0f172a;
    /* ... */
}
```

### Changing Auto-refresh Interval
Edit [index.html](index.html) at the bottom:
```javascript
// Auto-refresh every 30 seconds
setInterval(loadData, 30000); // Change to 60000 for 1 minute
```

### Custom Port
```bash
PORT=9000 nix run .#role-explorer
```

## Troubleshooting

### Install prompt doesn't appear
- HTTPS required for PWA features (localhost works too)
- Try: Browser menu → "Install App"
- Chrome: chrome://flags → Enable "Desktop PWAs"

### Service worker not registering
- Check browser console for errors
- Ensure [sw.js](sw.js) is accessible at `/sw.js`
- Clear cache: DevTools → Application → Clear storage

### API returns empty data
- Ensure you're running from nixos-config directory
- Check that `modules/roles/` and `hosts/` exist
- Verify `parts/hosts.nix` has host configurations

## Development

Want to modify the app?

1. Edit files in `webapp/`
2. Refresh browser (service worker caches, so hard refresh: Ctrl+Shift+R)
3. No build step needed - it's vanilla JS!

### Testing
```bash
# Run the server
nix run .#role-explorer

# Open in browser
http://localhost:8080

# Check console for errors
# Inspect → Console
```

## Browser Support

- ✅ Chrome/Edge 90+
- ✅ Firefox 90+
- ✅ Safari 15+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## Screenshots

The app shows:
- 🎭 **Roles Section**: All available roles with package counts
- 🖥️ **Hosts Section**: All configured hosts with their assigned roles
- 🔄 **Refresh Button**: Manual refresh trigger
- 📱 **Install Prompt**: One-click install banner

Enjoy your installable NixOS config explorer! 🎉
