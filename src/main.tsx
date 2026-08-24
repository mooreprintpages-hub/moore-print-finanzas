import { Component, StrictMode, type ErrorInfo, type ReactNode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './styles.css'
import './modules/inventory-purchases.css'

type ErrorBoundaryState = { error: Error | null }

class AppErrorBoundary extends Component<{ children: ReactNode }, ErrorBoundaryState> {
  state: ErrorBoundaryState = { error: null }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('Moore Print frontend runtime error', error, info)
  }

  render() {
    if (this.state.error) {
      return (
        <main className="center-page">
          <section className="state-card">
            <div className="brand brand--auth"><div className="brand__mark">MP</div><div><strong>Moore Print</strong><span>Finanzas</span></div></div>
            <h1>La aplicación encontró un error.</h1>
            <p>Ya no mostraremos una pantalla en blanco. Recarga una vez; si continúa, comparte este mensaje:</p>
            <div className="notice notice--error"><code>{this.state.error.message || 'Error desconocido de ejecución'}</code></div>
            <button className="primary-button" onClick={() => window.location.reload()}>Recargar aplicación</button>
          </section>
        </main>
      )
    }
    return this.props.children
  }
}

const root = document.getElementById('root')
if (!root) throw new Error('No se encontró el contenedor principal de la aplicación')

createRoot(root).render(
  <StrictMode>
    <AppErrorBoundary>
      <App />
    </AppErrorBoundary>
  </StrictMode>,
)
