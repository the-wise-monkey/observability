const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const zlib = require('zlib');
const { promisify } = require('util');

const gunzip = promisify(zlib.gunzip);

const LOKI_URL = process.env.LOKI_URL || 'http://loki:3100/loki/api/v1/push';

const app = express();

// Handle both regular JSON and gzip-compressed content
app.use('/logpush', (req, res, next) => {
  const contentEncoding = req.headers['content-encoding'];
  if (contentEncoding === 'gzip') {
    // For gzip content, we need raw buffer
    bodyParser.raw({ type: '*/*', limit: '50mb' })(req, res, next);
  } else {
    // For regular content, use JSON parser
    bodyParser.json({ limit: '10mb' })(req, res, next);
  }
});

app.post('/logpush', async (req, res) => {
  try {
    const contentEncoding = req.headers['content-encoding'];
    const contentType = req.headers['content-type'] || '';
    let logs = req.body;
    
    // Handle gzip-compressed logs
    if (contentEncoding === 'gzip') {
      console.log('Processing gzip-compressed logs');
      const decompressed = await gunzip(logs);
      const logData = decompressed.toString('utf8');
      
      // Split by newlines and filter empty lines
      const logLines = logData.split('\n').filter(line => line.trim() !== '');
      
      logs = logLines.map(line => {
        try {
          return JSON.parse(line);
        } catch (e) {
          // If line is not JSON, return as string
          return { message: line };
        }
      });
    }
    
    // Log the received data for debugging
    console.log('Content-Encoding:', contentEncoding);
    console.log('Content-Type:', contentType);
    console.log('Received data type:', typeof logs);
    console.log('Number of log entries:', Array.isArray(logs) ? logs.length : 1);
    
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

    // Create entries with proper timestamps
    const entries = validLogs.map(log => {
      // Use EdgeStartTimestamp if available, otherwise use current time
      let timestamp;
      if (log.EdgeStartTimestamp) {
        // EdgeStartTimestamp is usually in nanoseconds, convert to nanoseconds string
        timestamp = (log.EdgeStartTimestamp * 1000000).toString();
      } else {
        // Current time in nanoseconds
        timestamp = (Date.now() * 1000000).toString();
      }
      
      return {
        ts: timestamp,
        line: JSON.stringify(log)
      };
    });

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