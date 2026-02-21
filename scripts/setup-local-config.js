const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const envLocalPath = path.join(rootDir, '.env.local');
const configPath = path.join(rootDir, 'config.js');

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

const supabaseUrl = process.env.SUPABASE_URL || envFromFile.SUPABASE_URL || '';
const supabaseAnonKey =
  process.env.SUPABASE_ANON_KEY ||
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  envFromFile.SUPABASE_ANON_KEY ||
  envFromFile.SUPABASE_PUBLISHABLE_KEY ||
  '';

const supabaseServiceRoleKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  envFromFile.SUPABASE_SERVICE_ROLE_KEY ||
  '';

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Supabase-gegevens ontbreken.');
  console.error('Zet SUPABASE_URL en SUPABASE_ANON_KEY (of SUPABASE_PUBLISHABLE_KEY) in .env.local of als environment variables.');
  process.exit(1);
}

const configContent = `// Lokaal gegenereerd. Niet committen.\nwindow.SUPABASE_URL = ${JSON.stringify(supabaseUrl)};\nwindow.SUPABASE_ANON_KEY = ${JSON.stringify(supabaseAnonKey)};\nwindow.SUPABASE_SERVICE_ROLE_KEY = ${JSON.stringify(supabaseServiceRoleKey)};\n`;

fs.writeFileSync(configPath, configContent, 'utf8');
console.log('config.js aangemaakt voor lokaal gebruik.');
