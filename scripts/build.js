const fs = require('fs');
const path = require('path');

const distDir = path.join(__dirname, '..', 'dist');
const rootDir = path.join(__dirname, '..');

const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || '';

if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const configContent = `// Gegenereerd bij build (Vercel). Niet bewerken.
window.SUPABASE_URL = ${JSON.stringify(url)};
window.SUPABASE_ANON_KEY = ${JSON.stringify(key)};
`;

fs.writeFileSync(path.join(distDir, 'config.js'), configContent, 'utf8');
fs.copyFileSync(path.join(rootDir, 'index.html'), path.join(distDir, 'index.html'));
fs.copyFileSync(path.join(rootDir, 'dashboard.html'), path.join(distDir, 'dashboard.html'));

console.log('Build voltooid: dist/');
