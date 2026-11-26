import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import { AppProvider } from './context/AppContext.jsx';
import { NotificationProvider } from './context/NotificationContext.jsx';
import { wakeAiSpacesOnAppOpen } from './services/spaceWakeup.js';
import './index.css';
import VisitorMap from './components/indoor_maps/VisitorMap';

if (window.location.pathname !== '/visitor-map') wakeAiSpacesOnAppOpen();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    {window.location.pathname === '/visitor-map' ? (
      <VisitorMap />
    ) : (
      <AppProvider>
        <NotificationProvider>
          <App />
        </NotificationProvider>
      </AppProvider>
    )}
  </React.StrictMode>
);
