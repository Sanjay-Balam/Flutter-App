// Keep-alive script for Render free tier
// This script pings your API every 10 minutes to prevent sleeping

const SERVER_URL = 'https://business-sales-backend.onrender.com/health';
const PING_INTERVAL = 10 * 60 * 1000; // 10 minutes in milliseconds

async function pingServer() {
  try {
    const response = await fetch(SERVER_URL);
    const data = await response.json();
    console.log(`✅ Ping successful at ${new Date().toISOString()}:`, data.message);
  } catch (error) {
    console.error(`❌ Ping failed at ${new Date().toISOString()}:`, error.message);
  }
}

// Start pinging
console.log(`🚀 Starting keep-alive pinger for ${SERVER_URL}`);
console.log(`📡 Pinging every ${PING_INTERVAL / 1000 / 60} minutes`);

// Initial ping
pingServer();

// Set up interval
setInterval(pingServer, PING_INTERVAL);

// Keep the script running
process.on('SIGINT', () => {
  console.log('\n⏹️ Keep-alive pinger stopped');
  process.exit(0);
}); 