const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const required = [
  'src/main.ts',
  'src/app.module.ts',
  'prisma/schema.prisma',
  'prisma/seed.ts',
  '.env.example',
  '../docs/PRODUCTION_ACCEPTANCE_CHECKLIST_AR.md',
];

const requiredModules = [
  'auth', 'users', 'organizations', 'locations', 'vehicles', 'catalog', 'listings', 'cart',
  'orders', 'workshops', 'payments', 'accounting', 'delivery', 'support', 'reviews',
  'wallet_loyalty', 'admin', 'quality', 'audit', 'events', 'notifications', 'employees', 'system'
];

const missing = [];
for (const item of required) {
  if (!fs.existsSync(path.join(root, item))) missing.push(item);
}
for (const moduleName of requiredModules) {
  if (!fs.existsSync(path.join(root, 'src', 'modules', moduleName))) missing.push(`src/modules/${moduleName}`);
}

const schema = fs.readFileSync(path.join(root, 'prisma/schema.prisma'), 'utf8');
for (const table of ['audit_logs', 'event_outbox', 'commerce_orders', 'payment_transactions', 'journal_entries', 'qa_test_runs', 'deployment_runs', 'translation_keys', 'translation_values']) {
  if (!schema.includes(`@@map("${table}")`)) missing.push(`Prisma table mapping ${table}`);
}



const projectRoot = path.resolve(root, '..');
const appScaffold = path.join(projectRoot, 'frontend', 'lib', 'shared', 'widgets', 'app_scaffold.dart');
const platformLayout = path.join(projectRoot, 'frontend', 'lib', 'core', 'platform', 'platform_layout.dart');
const accountingService = path.join(root, 'src', 'modules', 'accounting', 'accounting.service.ts');
if (!fs.existsSync(appScaffold) || !fs.readFileSync(appScaffold, 'utf8').includes('_DesktopSideNavigation')) missing.push('frontend desktop adaptive navigation shell');
if (!fs.existsSync(platformLayout) || !fs.readFileSync(platformLayout, 'utf8').includes('isDesktopShell')) missing.push('frontend platform-aware shell decision');
if (!fs.readFileSync(accountingService, 'utf8').includes('MERCHANT_BALANCE_CURRENCY_MISMATCH')) missing.push('accounting currency mismatch guard');
if (!fs.readFileSync(accountingService, 'utf8').includes('INVALID_JOURNAL_LINE_SIDE')) missing.push('journal line side validation');

if (missing.length) {
  console.error('Static QA failed. Missing:');
  for (const item of missing) console.error(`- ${item}`);
  process.exit(1);
}
console.log('Static QA passed. Required modules, schema mappings and core files exist.');
