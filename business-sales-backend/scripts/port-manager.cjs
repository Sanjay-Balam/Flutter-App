#!/usr/bin/env node

const { exec } = require('child_process');
const net = require('net');

const args = process.argv.slice(2);
const command = args[0];
const port = args[1] || 3000;

function checkPort(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.listen(port, () => {
      server.close();
      resolve(true); // Port is available
    });
    server.on('error', () => {
      resolve(false); // Port is in use
    });
  });
}

function killPort(port) {
  exec(`lsof -ti:${port}`, (error, stdout) => {
    if (stdout.trim()) {
      const pids = stdout.trim().split('\n');
      pids.forEach(pid => {
        exec(`kill -9 ${pid}`, (killError) => {
          if (!killError) {
            console.log(`✅ Killed process ${pid} using port ${port}`);
          }
        });
      });
    } else {
      console.log(`ℹ️  No process found using port ${port}`);
    }
  });
}

function findAvailablePort(startPort = 3000) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.listen(startPort, () => {
      const port = server.address().port;
      server.close();
      resolve(port);
    });
    server.on('error', () => {
      resolve(findAvailablePort(startPort + 1));
    });
  });
}

async function main() {
  switch (command) {
    case 'check':
      const available = await checkPort(port);
      console.log(`Port ${port} is ${available ? 'available' : 'in use'}`);
      break;
      
    case 'kill':
      killPort(port);
      break;
      
    case 'find':
      const availablePort = await findAvailablePort(port);
      console.log(availablePort);
      break;
      
    default:
      console.log('Usage:');
      console.log('  node scripts/port-manager.js check [port]  - Check if port is available');
      console.log('  node scripts/port-manager.js kill [port]   - Kill process using port');
      console.log('  node scripts/port-manager.js find [port]   - Find next available port');
  }
}

main(); 