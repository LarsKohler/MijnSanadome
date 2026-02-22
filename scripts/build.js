const fs = require('fs');
const path = require('path');

const distDir = path.join(__dirname, '..', 'dist');
const rootDir = path.join(__dirname, '..');
const envLocalPath = path.join(rootDir, '.env.local');

function parseEnvFile(content) {
  const values = {};
  const lines = content.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIndex = trimmed.indexOf('=');
    if (eqIndex === -1) continue;

    const key = trimmed.slice(0, eqIndex).trim();
    let value = trimmed.slice(eqIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[key] = value;
  }
  return values;
}

let envFromFile = {};
if (fs.existsSync(envLocalPath)) {
  envFromFile = parseEnvFile(fs.readFileSync(envLocalPath, 'utf8'));
}

const url = process.env.SUPABASE_URL || envFromFile.SUPABASE_URL || '';
const key =
  process.env.SUPABASE_ANON_KEY ||
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  envFromFile.SUPABASE_ANON_KEY ||
  envFromFile.SUPABASE_PUBLISHABLE_KEY ||
  '';

if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const serviceRoleKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  envFromFile.SUPABASE_SERVICE_ROLE_KEY ||
  '';

const configContent = `// Gegenereerd bij build (Vercel). Niet bewerken.
window.SUPABASE_URL = ${JSON.stringify(url)};
window.SUPABASE_ANON_KEY = ${JSON.stringify(key)};
window.SUPABASE_SERVICE_ROLE_KEY = ${JSON.stringify(serviceRoleKey)};
`;

fs.writeFileSync(path.join(distDir, 'config.js'), configContent, 'utf8');
fs.copyFileSync(path.join(rootDir, 'index.html'), path.join(distDir, 'index.html'));
fs.copyFileSync(path.join(rootDir, 'dashboard.html'), path.join(distDir, 'dashboard.html'));
fs.copyFileSync(path.join(rootDir, 'gebruikers.html'), path.join(distDir, 'gebruikers.html'));
fs.copyFileSync(path.join(rootDir, 'rechten.html'), path.join(distDir, 'rechten.html'));
fs.copyFileSync(path.join(rootDir, 'nieuws.html'), path.join(distDir, 'nieuws.html'));
fs.copyFileSync(path.join(rootDir, 'artikel.html'), path.join(distDir, 'artikel.html'));
fs.copyFileSync(path.join(rootDir, 'onboarding.html'), path.join(distDir, 'onboarding.html'));
fs.copyFileSync(path.join(rootDir, 'profiel.html'), path.join(distDir, 'profiel.html'));
fs.copyFileSync(path.join(rootDir, 'debiteuren.html'), path.join(distDir, 'debiteuren.html'));

console.log('Build voltooid: dist/');
