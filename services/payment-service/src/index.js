// services/payment-service/src/index.js
// ShopSecure — Payment Service (Node.js / Express)
const express = require('express');
const client  = require('prom-client');

const app  = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// ── Prometheus metrics ────────────────────────────────────────────────────────
const registry = new client.Registry();
client.collectDefaultMetrics({ register: registry });

const paymentCounter = new client.Counter({
  name: 'payments_total',
  help: 'Total payment attempts',
  labelNames: ['status', 'method'],
  registers: [registry],
});

const paymentAmount = new client.Histogram({
  name: 'payment_amount_dollars',
  help: 'Payment amounts in USD',
  buckets: [1, 10, 50, 100, 250, 500, 1000],
  registers: [registry],
});

// ── Health ────────────────────────────────────────────────────────────────────
app.get('/health/live',  (_req, res) => res.json({ status: 'alive' }));
app.get('/health/ready', (_req, res) => res.json({ status: 'ready' }));
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', registry.contentType);
  res.end(await registry.metrics());
});

// ── Payment endpoints ─────────────────────────────────────────────────────────
app.post('/api/v1/payments/intent', async (req, res) => {
  const { orderId, amount, currency = 'usd' } = req.body;

  if (!orderId || !amount) {
    return res.status(400).json({ error: 'orderId and amount are required' });
  }

  // TODO: Call Stripe API to create PaymentIntent
  // const paymentIntent = await stripe.paymentIntents.create({ amount, currency, metadata: { orderId } });
  paymentAmount.observe(amount / 100);

  res.status(201).json({
    clientSecret: 'pi_placeholder_secret',
    paymentIntentId: 'pi_placeholder',
    orderId,
    amount,
    currency,
    status: 'requires_payment_method',
  });
});

app.post('/api/v1/payments/confirm', async (req, res) => {
  const { paymentIntentId } = req.body;
  if (!paymentIntentId) {
    return res.status(400).json({ error: 'paymentIntentId required' });
  }
  // TODO: Confirm with Stripe, update order status via SQS
  paymentCounter.inc({ status: 'success', method: 'card' });
  res.json({ status: 'succeeded', paymentIntentId });
});

app.post('/api/v1/payments/refund', async (req, res) => {
  const { paymentIntentId, amount } = req.body;
  // TODO: Create refund via Stripe, update order in DB
  paymentCounter.inc({ status: 'refunded', method: 'card' });
  res.json({ status: 'refunded', paymentIntentId, amount });
});

// ── Stripe webhook ────────────────────────────────────────────────────────────
app.post('/api/v1/payments/webhook',
  express.raw({ type: 'application/json' }),
  (req, res) => {
    // TODO: Verify Stripe signature and process event
    const sig = req.headers['stripe-signature'];
    if (!sig) return res.status(400).json({ error: 'Missing stripe signature' });
    // Handle events: payment_intent.succeeded, payment_intent.payment_failed, etc.
    res.json({ received: true });
  }
);

app.listen(PORT, () => console.log(`Payment service running on :${PORT}`));
module.exports = app;
