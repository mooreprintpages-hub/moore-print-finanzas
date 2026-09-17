import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'
import {resolve} from 'node:path'

export default defineConfig({
  base:'/moore-print-finanzas/',
  plugins:[react()],
  build:{
    rollupOptions:{
      input:{
        public:resolve(import.meta.dirname,'index.html'),
        equipo:resolve(import.meta.dirname,'equipo.html')
      }
    }
  }
})
