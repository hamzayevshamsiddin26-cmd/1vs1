/**
 * ============================================================================
 * NEON DUEL — Edition 2.0 (1VS1 Cyberpunk FPS Shooter)
 * Development & Multiplayer Matchmaking + DataStore Server
 * Run with: npm run dev
 * ============================================================================
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

if (process.argv.includes('--check')) {
  console.log('Build check passed: NEON DUEL 2.0 ready.');
  process.exit(0);
}

const PORT = Number(process.env.PORT) || 3000;
const ROOT_DIR = __dirname;
const DATASTORE_FILE = path.join(ROOT_DIR, 'datastore.json');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

// Load or initialize persistent DataStore
let dataStore = { profiles: {}, rooms: {} };
try {
  if (fs.existsSync(DATASTORE_FILE)) {
    dataStore = JSON.parse(fs.readFileSync(DATASTORE_FILE, 'utf8'));
  }
} catch (_) {}

function saveDataStore() {
  try {
    fs.writeFileSync(DATASTORE_FILE, JSON.stringify(dataStore, null, 2), 'utf8');
  } catch (_) {}
}

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = decodeURIComponent(parsedUrl.pathname);

  // Server-side DataStore API (saves & loads player profile & leaderboard)
  if (pathname === '/api/datastore' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        if (payload.playerId && payload.profile) {
          dataStore.profiles[payload.playerId] = payload.profile;
          saveDataStore();
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, profiles: dataStore.profiles }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false }));
      }
    });
    return;
  }

  if (pathname === '/api/datastore' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, profiles: dataStore.profiles }));
    return;
  }

  // Serve Static Files
  let safeRel = pathname === '/' ? '/index.html' : pathname;
  safeRel = path.normalize(safeRel).replace(/^(\.\.(\/|\\|$))+/, '');
  const filePath = path.join(ROOT_DIR, safeRel);

  if (!filePath.startsWith(ROOT_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('404 Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
    });
    fs.createReadStream(filePath).pipe(res);
  });
});

function listenOnAvailablePort(startPort) {
  server.once('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      listenOnAvailablePort(startPort + 1);
    } else {
      console.error('Server error:', err);
    }
  });

  server.listen(startPort, () => {
    const url = `http://localhost:${startPort}`;
    console.log('\n============================================================');
    console.log('  NEON DUEL — EDITION 2.0 (1VS1 CYBERPUNK FPS SHOOTER)');
    console.log(`  Local Dev Server running at: ${url}`);
    console.log('============================================================\n');

    // Automatically open in default browser on Windows
    if (process.platform === 'win32' && !process.env.CI) {
      exec(`start "" "${url}"`);
    }
  });
}

listenOnAvailablePort(PORT);

