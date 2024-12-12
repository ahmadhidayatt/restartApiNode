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
