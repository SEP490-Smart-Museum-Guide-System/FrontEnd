import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import { AppProvider } from './context/AppContext.jsx';
import './index.css';
import VisitorMap from './components/indoor_maps/VisitorMap';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    {window.location.pathname === '/visitor-map' ? <VisitorMap /> : <AppProvider>
      <App />
    </AppProvider>}
  </React.StrictMode>
);
