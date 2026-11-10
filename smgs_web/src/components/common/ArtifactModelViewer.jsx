import React from 'react';

export const isSketchfabUrl = url => /^https:\/\/sketchfab\.com\/models\/[0-9a-f]{32}\/embed$/i.test(url || '');

export default function ArtifactModelViewer({ url, name = 'Mô hình hiện vật', style }) {
  if (isSketchfabUrl(url)) return <iframe title={name} src={url} allow="autoplay; fullscreen; xr-spatial-tracking" allowFullScreen referrerPolicy="strict-origin-when-cross-origin" style={{ border: 0, width: '100%', height: '100%', ...style }} />;
  return <model-viewer src={url} alt={name} auto-rotate camera-controls ar shadow-intensity="1" style={{ width: '100%', height: '100%', ...style }} />;
}
