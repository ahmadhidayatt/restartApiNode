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
if [[ "$NODE_VERSION" > "v14" ]]; then
  MODULE_SYNTAX="import"
  echo "Node.js version is 14 or above, using 'import' syntax."
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
app.get('/run-cron', (req, res) => {
  const startTime = new Date().toISOString();  // Waktu saat request diterima
  console.log(`[${startTime}] Received request to run cron job`);

  // Mendapatkan perintah cron dari crontab
  exec('crontab -l', (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();  // Waktu saat terjadi error
      console.error(`[${errorTime}] Error fetching crontab: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();  // Waktu saat stderr
      console.error(`[${stderrTime}] Error in crontab: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    // Ambil hanya perintah dari crontab, abaikan waktu dan jadwal
    const cronCommand = stdout.trim().split('\n')
      .map(line => line.split(' ').slice(5).join(' '))  // Ambil perintah cron setelah jadwal
      .join(' && '); // Gabungkan perintah cron jika ada lebih dari satu

    if (!cronCommand) {
      const noCommandTime = new Date().toISOString();  // Waktu jika tidak ada perintah dalam crontab
      console.error(`[${noCommandTime}] No command found in crontab`);
      return res.status(500).json({ error: 'No command found in crontab' });
    }

    const runningTime = new Date().toISOString();  // Waktu saat perintah cron mulai dijalankan
    console.log(`[${runningTime}] Running cron command: ${cronCommand}`);

    // Jalankan perintah cron
    exec(cronCommand, (execError, execStdout, execStderr) => {
      const finishTime = new Date().toISOString();  // Waktu selesai menjalankan perintah
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
app.get('/run-cron', (req, res) => {
  const startTime = new Date().toISOString();  // Waktu saat request diterima
  console.log(`[${startTime}] Received request to run cron job`);

  // Mendapatkan perintah cron dari crontab
  exec('crontab -l', (error, stdout, stderr) => {
    if (error) {
      const errorTime = new Date().toISOString();  // Waktu saat terjadi error
      console.error(`[${errorTime}] Error fetching crontab: ${error.message}`);
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      const stderrTime = new Date().toISOString();  // Waktu saat stderr
      console.error(`[${stderrTime}] Error in crontab: ${stderr}`);
      return res.status(500).json({ error: stderr });
    }

    // Ambil hanya perintah dari crontab, abaikan waktu dan jadwal
    const cronCommand = stdout.trim().split('\n')
      .map(line => line.split(' ').slice(5).join(' '))  // Ambil perintah cron setelah jadwal
      .join(' && '); // Gabungkan perintah cron jika ada lebih dari satu

    if (!cronCommand) {
      const noCommandTime = new Date().toISOString();  // Waktu jika tidak ada perintah dalam crontab
      console.error(`[${noCommandTime}] No command found in crontab`);
      return res.status(500).json({ error: 'No command found in crontab' });
    }

    const runningTime = new Date().toISOString();  // Waktu saat perintah cron mulai dijalankan
    console.log(`[${runningTime}] Running cron command: ${cronCommand}`);

    // Jalankan perintah cron
    exec(cronCommand, (execError, execStdout, execStderr) => {
      const finishTime = new Date().toISOString();  // Waktu selesai menjalankan perintah
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
