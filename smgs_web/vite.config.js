import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const proxy = {
  '/api': { target: 'http://127.0.0.1:5169', changeOrigin: true },
  '/ai-tts': {
    target: 'http://127.0.0.1:8000',
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/ai-tts/, '')
  },
  '/ai-vision': {
    target: 'http://127.0.0.1:8001',
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/ai-vision/, '')
  },
  '/ai-scan': {
    target: 'http://127.0.0.1:8002',
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/ai-scan/, '')
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: { proxy },
  preview: { proxy },
})
