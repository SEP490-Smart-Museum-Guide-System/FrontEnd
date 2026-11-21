export function scanProgress({ uploading = false, uploadProgress = 0, job, hasPreview = false }) {
  const running = ['QUEUED', 'PROCESSING', 'FINALIZING'].includes(job?.status);
  const review = job?.status === 'REVIEW_REQUIRED';
  const percent = Math.max(0, Math.min(100, Number(uploading ? uploadProgress : job?.progress) || 0));
  return { running, review, percent, step: uploading ? 2 : review || hasPreview || job?.status === 'COMPLETED' ? 4 : running ? 3 : 1 };
}

export function scanActivity(job) {
  const p = Number(job?.progress) || 0;
  const fallback = job?.status === 'QUEUED' ? { title: 'Đang xếp hàng', phase: 0 }
    : p >= 90 ? { title: 'Tạo texture và đóng gói mô hình', phase: 4 }
    : p >= 70 ? { title: 'Dựng và tinh chỉnh bề mặt', phase: 3 }
    : p >= 45 ? { title: 'Ước lượng độ sâu ảnh', phase: 3 }
    : p >= 35 ? { title: 'Hiệu chỉnh ảnh theo camera', phase: 2 }
    : { title: 'Phân tích ảnh và tính camera', phase: 1 };
  const data = job?.activity;
  return {
    ...fallback,
    ...(data && typeof data === 'object' ? data : {}),
    // Missing native counters mean an indeterminate stage, not a timed estimate.
    percent: Number.isFinite(data?.percent) && data.percent >= 0 && data.percent <= 100 ? data.percent : null,
    detail: data?.detail || 'Máy chủ đang xử lý giai đoạn này; thời gian phụ thuộc vào bộ ảnh.',
  };
}
