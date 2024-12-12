#!/bin/bash

# Menentukan direktori tempat skrip dijalankan
DIR=$(pwd)

# Install npm, Docker, dan Docker Compose
echo "Installing npm, Docker, and Docker Compose..."
sudo apt update
sudo apt install -y npm docker.io docker-compose

# Menentukan Docker service dan memastikan Docker berjalan
echo "Starting Docker service..."
sudo systemctl enable --now docker

# Buat package.json otomatis
echo "Creating package.json..."
npm init -y

# Install dependensi yang diperlukan
echo "Installing express..."
npm install express

# Buat server.js dengan menulis seluruh kode sekaligus
echo "Creating server.js..."
cat << 'EOF' > server.js
import express from 'express';
import { exec } from 'child_process';

const app = express();
const PORT = process.env.PORT || 1100;

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

# Buat Dockerfile
echo "Creating Dockerfile..."
cat << 'EOF' > Dockerfile
# Gunakan image Node.js yang sudah ada
FROM node:18

# Tentukan direktori kerja dalam container
WORKDIR /usr/src/app

# Salin file package.json dan install dependensi
COPY package*.json ./
RUN npm install

# Salin semua file proyek ke dalam container
COPY . .

# Expose port 1100
EXPOSE 1100

# Jalankan aplikasi dengan perintah node
CMD ["node", "server.js"]
EOF

# Buat file docker-compose.yml
echo "Creating docker-compose.yml..."
cat << 'EOF' > docker-compose.yml
version: '3'
services:
  app:
    build: .
    ports:
      - "1100:1100"
    volumes:
      - .:/usr/src/app
    environment:
      - NODE_ENV=production
EOF

# Verifikasi Dockerfile dan docker-compose.yml telah dibuat
if [ -f "Dockerfile" ]; then
  echo "Dockerfile has been created successfully!"
else
  echo "Error: Dockerfile creation failed."
fi

if [ -f "docker-compose.yml" ]; then
  echo "docker-compose.yml has been created successfully!"
else
  echo "Error: docker-compose.yml creation failed."
fi

echo "Server setup is complete!"
echo "You can now run 'docker-compose up' to start the application."
