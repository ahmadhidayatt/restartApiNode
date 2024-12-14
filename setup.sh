#!/bin/bash

# Menentukan direktori tempat skrip dijalankan
DIR=$(pwd)

# Install npm
echo "Installing npm"
sudo apt update
sudo apt install -y npm 

# Periksa versi Node.js yang terinstal
NODE_VERSION=$(node -v)
echo "Detected Node.js version: $NODE_VERSION"

# Tentukan apakah kita bisa menggunakan import atau harus menggunakan require
if [[ "$NODE_VERSION" > "v12" ]]; then
  MODULE_SYNTAX="import"
  echo "Node.js version is 12 or above, using 'import' syntax."
else
  MODULE_SYNTAX="require"
  echo "Node.js version is below 14, using 'require' syntax."
fi

# Buat package.json otomatis
echo "Creating package.json..."
npm init -y

# Install dependensi yang diperlukan
echo "Installing express and cors..."
npm install express cors

# Buat server.js dengan menulis seluruh kode sekaligus, sesuai dengan versi Node.js
echo "Creating server.js..."
if [[ "$MODULE_SYNTAX" == "import" ]]; then
cat << 'EOF' > server.js
import express from 'express';
import { exec } from 'child_process';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 1100;
app.use(cors());

// API untuk menjalankan cron job
app.get('/run-cron', (req, res) => {
  const startTime = new Date().toISOString();
  console.log(`[${startTime}] Received request to run cron job`);

  // Mendapatkan perintah cron dari crontab
  exec('crontab -l', (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();
      console.error(`[${errorTime}] Error fetching crontab: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();
      console.error(`[${stderrTime}] Error in crontab: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    const cronCommand = stdout.trim().split('\n')
      .map(line => line.split(' ').slice(5).join(' '))
      .join(' && ');

    if (!cronCommand) {
      const noCommandTime = new Date().toISOString();
      console.error(`[${noCommandTime}] No command found in crontab`);
      return res.status(500).json({ error: 'No command found in crontab' });
    }

    const runningTime = new Date().toISOString();
    console.log(`[${runningTime}] Running cron command: ${cronCommand}`);

    // Jalankan perintah cron
    exec(cronCommand, (execError, execStdout, execStderr) => {
      const finishTime = new Date().toISOString();
      if (execError) {
        console.error(`[${finishTime}] Error executing cron command: ${execError.message}`);
        return res.status(500).json({ error: execError.message });
      }
      if (execStderr) {
        console.error(`[${finishTime}] Error in execution: ${execStderr}`);
        return res.status(500).json({ error: execStderr });
      }
      console.log(`[${finishTime}] Cron job executed successfully`);
      res.json({ message: 'Cron job executed successfully', output: execStdout });
    });
  });
});

// API untuk menjalankan docker-compose down dan up
app.get('/run-docker-compose', (req, res) => {
  const { port } = req.query;  // Mendapatkan port dari parameter request

  if (!port) {
    return res.status(400).json({ error: 'Port parameter is required' });
  }

  let adjustedPort;
  if (port.length === 4) {
    adjustedPort = parseInt(port) - 3001;  // Jika panjang 4 digit, kurangi dengan 3001
  } else if (port.length === 5) {
    adjustedPort = parseInt(port) - 31001;  // Jika panjang 5 digit, kurangi dengan 31001
  } else {
    return res.status(400).json({ error: 'Invalid port length' });
  } // Kurangi port dengan 3001

  if (isNaN(adjustedPort)) {
    return res.status(400).json({ error: 'Invalid port parameter' });
  }

  const startTime = new Date().toISOString();
  console.log(`[${startTime}] Received request to run docker-compose commands for port: ${port}`);

  // Perintah untuk mendapatkan working directory dari container
  exec(`docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' $(docker ps -q) | head -n 1`, (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();
      console.error(`[${errorTime}] Error fetching docker-compose working directory: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();
      console.error(`[${stderrTime}] Error in docker inspect: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    const workingDir = stdout.trim();
    console.log(`[${startTime}] Docker-compose working directory: ${workingDir}`);

    // Jalankan perintah docker-compose down dan up
    exec(`cd ${workingDir} && docker-compose -f docker-compose${adjustedPort}.yaml down`, (downError, downStdout, downStderr) => {
      const downErrorTime = new Date().toISOString();
      console.log(`docker-compose -f docker-compose${adjustedPort}.yaml down`);
      if (downError) {
        console.error(`[${downErrorTime}] Error executing docker-compose down: ${downError.message}`);
       // return res.status(500).json({ error: downError.message });
      }
      if (downStderr) {
        console.error(`[${downErrorTime}] Error in docker-compose down: ${downStderr}`);
       // return res.status(500).json({ error: downStderr });
      }

      console.log(`[${startTime}] Docker-compose down executed successfully`);

      // Setelah down berhasil, jalankan up
      exec(`cd ${workingDir} && docker-compose -f docker-compose${adjustedPort}.yaml up -d`, (upError, upStdout, upStderr) => {
        const finishTime = new Date().toISOString();
        if (upError) {
          console.error(`[${finishTime}] Error executing docker-compose up: ${upError.message}`);
          return res.status(500).json({ error: upError.message });
        }
        console.log(`[${finishTime}] Docker-compose up executed successfully`);
        res.json({ message: 'Docker-compose down and up executed successfully', output: upStdout });
      });
    });
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

EOF
else 
 cat << 'EOF' > server.js
const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 1100;
app.use(cors());

// API untuk menjalankan cron job
app.get('/run-cron', (req, res) => {
  const startTime = new Date().toISOString();
  console.log(`[${startTime}] Received request to run cron job`);

  // Mendapatkan perintah cron dari crontab
  exec('crontab -l', (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();
      console.error(`[${errorTime}] Error fetching crontab: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();
      console.error(`[${stderrTime}] Error in crontab: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    const cronCommand = stdout.trim().split('\n')
      .map(line => line.split(' ').slice(5).join(' '))
      .join(' && ');

    if (!cronCommand) {
      const noCommandTime = new Date().toISOString();
      console.error(`[${noCommandTime}] No command found in crontab`);
      return res.status(500).json({ error: 'No command found in crontab' });
    }

    const runningTime = new Date().toISOString();
    console.log(`[${runningTime}] Running cron command: ${cronCommand}`);

    // Jalankan perintah cron
    exec(cronCommand, (execError, execStdout, execStderr) => {
      const finishTime = new Date().toISOString();
      if (execError) {
        console.error(`[${finishTime}] Error executing cron command: ${execError.message}`);
        return res.status(500).json({ error: execError.message });
      }
      if (execStderr) {
        console.error(`[${finishTime}] Error in execution: ${execStderr}`);
        return res.status(500).json({ error: execStderr });
      }
      console.log(`[${finishTime}] Cron job executed successfully`);
      res.json({ message: 'Cron job executed successfully', output: execStdout });
    });
  });
});

// API untuk menjalankan docker-compose down dan up
app.get('/run-docker-compose', (req, res) => {
  const { port } = req.query;  // Mendapatkan port dari parameter request

  if (!port) {
    return res.status(400).json({ error: 'Port parameter is required' });
  }

  let adjustedPort;
  if (port.length === 4) {
    adjustedPort = parseInt(port) - 3001;  // Jika panjang 4 digit, kurangi dengan 3001
  } else if (port.length === 5) {
    adjustedPort = parseInt(port) - 31001;  // Jika panjang 5 digit, kurangi dengan 31001
  } else {
    return res.status(400).json({ error: 'Invalid port length' });
  } // Kurangi port dengan 3001

  if (isNaN(adjustedPort)) {
    return res.status(400).json({ error: 'Invalid port parameter' });
  }

  const startTime = new Date().toISOString();
  console.log(`[${startTime}] Received request to run docker-compose commands for port: ${port}`);

  // Perintah untuk mendapatkan working directory dari container
  exec(`docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' $(docker ps -q) | head -n 1`, (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();
      console.error(`[${errorTime}] Error fetching docker-compose working directory: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();
      console.error(`[${stderrTime}] Error in docker inspect: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    const workingDir = stdout.trim();
    console.log(`[${startTime}] Docker-compose working directory: ${workingDir}`);

    // Jalankan perintah docker-compose down dan up
    exec(`cd ${workingDir} && docker-compose -f docker-compose${adjustedPort}.yaml down`, (downError, downStdout, downStderr) => {
      const downErrorTime = new Date().toISOString();
      console.log(`docker-compose -f docker-compose${adjustedPort}.yaml down`);
      if (downError) {
        console.error(`[${downErrorTime}] Error executing docker-compose down: ${downError.message}`);
       // return res.status(500).json({ error: downError.message });
      }
      if (downStderr) {
        console.error(`[${downErrorTime}] Error in docker-compose down: ${downStderr}`);
       // return res.status(500).json({ error: downStderr });
      }

      console.log(`[${startTime}] Docker-compose down executed successfully`);

      // Setelah down berhasil, jalankan up
      exec(`cd ${workingDir} && docker-compose -f docker-compose${adjustedPort}.yaml up -d`, (upError, upStdout, upStderr) => {
        const finishTime = new Date().toISOString();
        if (upError) {
          console.error(`[${finishTime}] Error executing docker-compose up: ${upError.message}`);
          return res.status(500).json({ error: upError.message });
        }
        console.log(`[${finishTime}] Docker-compose up executed successfully`);
        res.json({ message: 'Docker-compose down and up executed successfully', output: upStdout });
      });
    });
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
EOF
fi

# Verifikasi file dan package telah dibuat
if [ -f "server.js" ]; then
  echo "server.js has been created successfully!"
else
  echo "Error: server.js creation failed."
fi

if [ -f "package.json" ]; then
  echo "package.json has been created successfully!"
else
  echo "Error: package.json creation failed."
fi

echo "Server setup is complete!"
echo "You can now run 'nohup node server.js &' to start the application."
