import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/curator/',
  plugins: [react()],
  build: {
    outDir: '../smgs_web/public/curator',
    emptyOutDir: true,
  },
});
