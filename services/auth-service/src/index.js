// services/auth-service/src/index.js
// ShopSecure — Auth Service (Node.js / Express)
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// ── Prometheus metrics ────────────────────────────────────────────────────────
const registry = new client.Registry();
client.collectDefaultMetrics({ register: registry });

const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [registry],
});

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency',
  labelNames: ['method', 'route'],
  registers: [registry],
});

app.use((req, res, next) => {
  const end = httpDuration.startTimer({ method: req.method, route: req.path });
  res.on('finish', () => {
    httpRequestCounter.inc({ method: req.method, route: req.path, status: res.statusCode });
    end();
  });
  next();
});

// ── Health endpoints ──────────────────────────────────────────────────────────
app.get('/health/live',  (_req, res) => res.json({ status: 'alive' }));
app.get('/health/ready', (_req, res) => res.json({ status: 'ready' }));
app.get('/metrics',      async (_req, res) => {
  res.set('Content-Type', registry.contentType);
  res.end(await registry.metrics());
});

// ── Auth endpoints ────────────────────────────────────────────────────────────
app.get('/api/v1/auth/status', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ authenticated: false });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret-change-me');
    return res.json({ authenticated: true, user: payload });
  } catch {
    return res.status(401).json({ authenticated: false, error: 'Invalid token' });
  }
});

app.post('/api/v1/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }
  // TODO: check if user exists in DB
  const hashed = await bcrypt.hash(password, 12);
  // TODO: persist user to DB
  const token = jwt.sign({ email, name }, process.env.JWT_SECRET || 'dev-secret-change-me', { expiresIn: '24h' });
  return res.status(201).json({ token, user: { email, name } });
});

app.post('/api/v1/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }
  // TODO: fetch user from DB and validate
  const token = jwt.sign({ email }, process.env.JWT_SECRET || 'dev-secret-change-me', { expiresIn: '24h' });
  return res.json({ token });
});

app.post('/api/v1/auth/refresh', (req, res) => {
  // TODO: Implement refresh token rotation
  res.status(501).json({ error: 'Not implemented yet' });
});

app.post('/api/v1/auth/logout', (req, res) => {
  // TODO: Blacklist token in Redis
  res.json({ message: 'Logged out successfully' });
});

// ── Start server ──────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`Auth service running on :${PORT}`);
});

module.exports = app;
