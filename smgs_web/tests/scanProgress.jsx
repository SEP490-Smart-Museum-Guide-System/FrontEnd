// Local UI fixture. All requests are intercepted; no real jobs or accounts.
import React from 'react';
import { createRoot } from 'react-dom/client';
import Artifact3DPanel from '../src/components/artifacts/Artifact3DPanel';
import '../src/index.css';
import '../src/components/common/business.css';
import '../src/components/common/refined.css';

const mode = new URLSearchParams(location.search).get('mode') || 'cameras';
let job = { scanJobId: 'ui-fixture', artifactId: 7, status: 'PROCESSING', progress: 10, imageCount: 180,
  activity: mode === 'matching' ? { stage: 'matching', title: 'Khớp đặc trưng giữa các ảnh', phase: 2, percent: 56.2, completed: 9, total: 16, detail: 'Đã khớp 9/16 nhóm ảnh.' }
    : { stage: 'cameras', title: 'Ước lượng và tối ưu camera', phase: 2, percent: null, detail: 'Đang đăng ký góc chụp và tối ưu điểm 3D; bước này không có tổng số vòng cố định.' } };
if (mode === 'legacy') delete job.activity;
if (mode === 'complete') job = { ...job, status: 'REVIEW_REQUIRED', progress: 100, activity: { stage: 'complete', title: 'Đã dựng xong mô hình', phase: 5, percent: 100, depthImages: 180, depthOperations: 540, detail: '' } };
window.fetch = async (url, options = {}) => {
  if (String(url).endsWith('/model-3d')) return new Response('{"message":"Chưa có mô hình"}', { status: 404 });
  if (options.method === 'POST' && String(url).endsWith('/cancel')) {
    job = { ...job, status: 'CANCELLED', error: 'Đã hủy tác vụ dựng 3D. Bộ ảnh và log được giữ lại.' };
    return new Response(JSON.stringify({ data: job }));
  }
  return new Response(JSON.stringify({ data: String(url).endsWith('/scans') ? (mode === 'upload' ? [] : [job]) : job }));
};
createRoot(document.getElementById('root')).render(<main style={{ maxWidth: 1200, margin: '24px auto', padding: 20 }}>
  <p>Kiểm tra giao diện với dữ liệu tạm · Không gọi API thật</p>
  <Artifact3DPanel artifactId={7} name="Hiện vật kiểm tra giao diện" canManage />
</main>);
