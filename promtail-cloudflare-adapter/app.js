const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const LOKI_URL = process.env.LOKI_URL || 'http://loki:3100/loki/api/v1/push';

const app = express();
app.use(bodyParser.json({ limit: '10mb' }));

app.post('/logpush', async (req, res) => {
  try {
    const now = new Date().toISOString();
    
    // Handle different input formats
    let logs = req.body;
    
    // Log the received data for debugging
    console.log('Received data type:', typeof logs);
    console.log('Received data:', JSON.stringify(logs).substring(0, 200) + '...');
    
    // Ensure we have an array of logs
    if (!logs) {
      console.error('No data received');
      return res.status(400).json({ error: 'No data received' });
    }
    
    if (!Array.isArray(logs)) {
      // If it's a single object, wrap it in an array
      if (typeof logs === 'object') {
        logs = [logs];
      } else {
        console.error('Invalid data format:', typeof logs);
        return res.status(400).json({ error: 'Data must be an array or object' });
      }
    }
    
    if (logs.length === 0) {
      console.warn('Empty array received');
      return res.status(200).json({ message: 'No logs to process' });
    }

    // Filter out empty or invalid log objects
    const validLogs = logs.filter(log => {
      if (!log || typeof log !== 'object') return false;
      // Check if object has at least some meaningful properties
      const keys = Object.keys(log);
      return keys.length > 0 && keys.some(key => log[key] !== null && log[key] !== undefined && log[key] !== '');
    });
    
    if (validLogs.length === 0) {
      console.warn('No valid log entries found in request');
      return res.status(200).json({ message: 'No valid logs to process' });
    }
    
    if (validLogs.length !== logs.length) {
      console.warn(`Filtered out ${logs.length - validLogs.length} invalid log entries`);
    }

    const entries = validLogs.map(log => ({
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

    await axios.post(LOKI_URL, payload, {
      headers: { 'Content-Type': 'application/json' }
    });
    
    console.log(`Successfully pushed ${entries.length} log entries to Loki`);
    res.status(200).json({ message: `Processed ${entries.length} valid log entries` });
    
  } catch (err) {
    console.error('Error processing logs:', err.message);
    if (err.response) {
      console.error('Loki response:', err.response.data);
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Cloudflare Logpush -> Loki proxy running on port ${PORT}`)); 