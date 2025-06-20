const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const LOKI_URL = process.env.LOKI_URL || 'http://loki:3100/loki/api/v1/push';

const app = express();
app.use(bodyParser.json({ limit: '10mb' }));

app.post('/logpush', async (req, res) => {
  const now = new Date().toISOString();

  const entries = req.body.map(log => ({
    ts: now,
    line: JSON.stringify(log)
  }));

  const payload = {
    streams: [
      {
        labels: '{job="cloudflare-logpush"}',
        entries
      }
    ]
  };

  try {
    await axios.post(LOKI_URL, payload, {
      headers: { 'Content-Type': 'application/json' }
    });
    console.log(`Successfully pushed ${entries.length} log entries to Loki`);
    res.sendStatus(200);
  } catch (err) {
    console.error('Loki push failed:', err.response?.data || err.message);
    res.sendStatus(500);
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Cloudflare Logpush -> Loki proxy running on port ${PORT}`)); 