const http = require('http');

const baseUrl = process.env.SMOKE_BASE_URL || `http://127.0.0.1:${process.env.PORT || 3000}/api/v1`;
const url = new URL('/health', baseUrl);

const req = http.get(url, (res) => {
  let body = '';
  res.on('data', (chunk) => { body += chunk; });
  res.on('end', () => {
    if (res.statusCode !== 200) {
      console.error(`Smoke check failed: ${res.statusCode} ${body}`);
      process.exit(1);
    }
    try {
      const json = JSON.parse(body);
      if (!json.success) throw new Error('success=false');
      console.log('Smoke check passed:', body);
    } catch (err) {
      console.error('Smoke check failed: invalid JSON response', err.message);
      process.exit(1);
    }
  });
});
req.on('error', (err) => {
  console.error(`Smoke check failed. Is the backend running at ${baseUrl}?`, err.message);
  process.exit(1);
});
req.setTimeout(8000, () => {
  console.error('Smoke check timed out.');
  req.destroy();
  process.exit(1);
});
