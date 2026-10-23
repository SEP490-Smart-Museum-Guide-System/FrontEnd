import { useEffect, useState } from 'react';

const apiBase = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

// shortcut: one fixed test artifact; replace with the artifact API list when staff CRUD is connected.
export default function QrTestArtifact() {
  const [artifact, setArtifact] = useState(null);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    fetch(`${apiBase}/artifacts/scan/SMGS-QR-DEMO-20261023`, { signal: controller.signal })
      .then(async response => {
        const body = await response.json();
        if (!response.ok || !body.data) throw new Error(body.message || 'Không tải được hiện vật mẫu.');
        setArtifact(body.data);
        setError('');
      }).catch(error => { if (error.name !== 'AbortError') setError(error.message); });
    return () => controller.abort();
  }, [attempt]);

  return <section className="card" style={{ padding: 24, marginBottom: 24 }} aria-label="Hiện vật mẫu kiểm thử QR">
    <h3>Hiện vật mẫu kiểm thử QR</h3>
    {error ? <p role="alert">{error} <button className="btn btn-secondary" onClick={() => setAttempt(value => value + 1)}>Thử lại</button></p>
      : !artifact ? <p>Đang tải hiện vật từ máy chủ…</p>
      : <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap', alignItems: 'center' }}>
        <img src={`${apiBase}/artifacts/${artifact.id}/qr-image`} width="280" height="280"
          alt={`Mã QR của ${artifact.name}`}
          onError={() => setError('Không tải được ảnh QR từ BE. Vui lòng thử lại.')} />
        <div style={{ flex: '1 1 260px' }}>
          <h4>{artifact.name}</h4>
          <p>{artifact.museumName}</p>
          <p>Mã kiểm tra: <strong>{artifact.code}</strong></p>
          <p><code>{artifact.qrCode}</code></p>
          <p>Mở Visitor trên điện thoại → Quét mã → Mở camera quét QR.</p>
          {artifact.contents.map(content => <p key={content.languageCode}>{content.title}</p>)}
          {!artifact.contents.length && <p>Chưa có nội dung xuất bản; Visitor vẫn xem được tên hiện vật và bảo tàng.</p>}
        </div>
      </div>}
  </section>;
}
