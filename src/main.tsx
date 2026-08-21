import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import OperationalApp from './OperationalApp'
import './styles.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <OperationalApp />
  </StrictMode>,
)
