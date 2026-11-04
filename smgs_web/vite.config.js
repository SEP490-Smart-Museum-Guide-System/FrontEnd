import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { createReadStream } from 'node:fs'
import { resolve } from 'node:path'

// Vite's SPA fallback otherwise serves the React index for /visitor/ in dev.
function visitorPreviewIndex() {
  return {
    name: 'visitor-preview-index',
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        const url = new URL(request.url, 'http://localhost')
        if (url.pathname !== '/visitor/' && url.pathname !== '/visitor') return next()
        if (url.pathname === '/visitor') {
          response.writeHead(302, { Location: `/visitor/${url.search}` })
          response.end()
          return
        }
        const file = createReadStream(resolve(server.config.publicDir, 'visitor/index.html'))
        file.on('error', () => {
          if (!response.headersSent) {
            response.writeHead(503, { 'Content-Type': 'text/plain; charset=utf-8' })
            response.end('Chưa có bản build Visitor. Hãy chạy tools/update-visitor-web.ps1.')
          } else response.destroy()
        })
        response.setHeader('Content-Type', 'text/html; charset=utf-8')
        response.setHeader('Cache-Control', 'no-cache')
        file.pipe(response)
      })
    },
  }
}

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
  plugins: [visitorPreviewIndex(), react()],
  server: { proxy },
  preview: { proxy },
})
