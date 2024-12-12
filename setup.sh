#!/bin/bash

# Buat package.json otomatis
npm init -y

# Install dependensi yang diperlukan
npm install express

# Buat server.js
echo "import express from 'express';" > server.js
echo "import { exec } from 'child_process';" >> server.js
echo "
const app = express();
const PORT = process.env.PORT || 1100;

app.get('/run-cron', (req, res) => {
  const cronCommand = 'sudo /etc/init.d/cron restart';  // Ganti dengan perintah cron yang sesuai
  exec(cronCommand, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    if (stderr) {
      return res.status(500).json({ error: stderr });
    }
    res.json({ message: 'Cron job executed successfully', output: stdout });
  });
});

app.listen(PORT, () => {
  console.log(\`Server is running on http://localhost:${PORT}\`);
});
" >> server.js

echo "Server.js and package.json have been created!"
