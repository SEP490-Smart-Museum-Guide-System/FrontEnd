import React from 'react';
import { createRoot } from 'react-dom/client';
import ArtifactModelViewer from './src/components/common/ArtifactModelViewer.jsx';

const url = 'https://sketchfab.com/models/fdec4f06ed324054aea7bc3d14cdc819/embed';
createRoot(document.getElementById('root')).render(<main style={{ maxWidth: 960, margin: '30px auto', padding: 24, fontFamily: 'Arial, sans-serif', background: '#fff', borderRadius: 16 }}><h1 style={{ fontSize: 25 }}>Bia Tiến sĩ Văn Miếu 26-1715</h1><p>Mô hình 3D gắn bằng link Sketchfab</p><div style={{ height: 520, background: '#15191e', borderRadius: 12, overflow: 'hidden' }}><ArtifactModelViewer url={url} name="Bia Tiến sĩ Văn Miếu 26-1715" /></div></main>);
