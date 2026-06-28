const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const envPath = path.join(root, '.env');
const envExamplePath = path.join(root, '.env.example');

function parseEnv(content) {
  const result = {};
  for (const raw of content.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) continue;
    let value = match[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    result[match[1]] = value;
  }
  return result;
}

const envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
const exampleContent = fs.existsSync(envExamplePath) ? fs.readFileSync(envExamplePath, 'utf8') : '';
const fileEnv = parseEnv(envContent || exampleContent);
const env = { ...fileEnv, ...process.env };
const isProduction = env.NODE_ENV === 'production' || process.env.GHIYARAK_PREFLIGHT_MODE === 'production';

const requiredKeys = ['DATABASE_URL', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET'];
const missing = requiredKeys.filter((key) => !env[key]);
if (missing.length) {
  console.error('Preflight failed. Missing env keys:', missing.join(', '));
  process.exit(1);
}

if (isProduction && !envContent) {
  console.error('Preflight failed. Production mode requires backend/.env or real environment variables. Do not deploy from .env.example.');
  process.exit(1);
}

function rejectWeakSecret(key) {
  const value = String(env[key] || '');
  const weak = value.length < 32 || /change-me|change_me|paste_|your-|example|local_secret|ghiyarak_local/i.test(value);
  if (weak) {
    console.error(`Preflight failed. ${key} must be a real secret with at least 32 non-example characters.`);
    process.exit(1);
  }
}

if (isProduction || envContent) {
  rejectWeakSecret('JWT_ACCESS_SECRET');
  rejectWeakSecret('JWT_REFRESH_SECRET');
}

if (isProduction) {
  const origins = String(env.CORS_ORIGINS || '').split(',').map((item) => item.trim()).filter(Boolean);
  if (!origins.length || origins.some((origin) => origin === '*' || /localhost|127\.0\.0\.1/.test(origin))) {
    console.error('Preflight failed. Production CORS_ORIGINS must contain only real HTTPS origins.');
    process.exit(1);
  }
  if (!String(env.DATABASE_URL || '').startsWith('mysql://') && !String(env.DATABASE_URL || '').startsWith('mysqls://')) {
    console.error('Preflight failed. DATABASE_URL must point to MySQL/MariaDB.');
    process.exit(1);
  }
}

console.log('Preflight passed. Required environment keys and production safety checks are valid.');
