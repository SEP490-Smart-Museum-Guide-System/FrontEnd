import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const proxy = { '/api': { target: 'http://127.0.0.1:5169', changeOrigin: true } }

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: { proxy },
  preview: { proxy },
})
