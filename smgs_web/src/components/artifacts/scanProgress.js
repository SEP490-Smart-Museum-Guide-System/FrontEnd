export function scanProgress({ uploading = false, uploadProgress = 0, job, hasPreview = false }) {
  const running = ['QUEUED', 'PROCESSING', 'FINALIZING'].includes(job?.status);
  const review = job?.status === 'REVIEW_REQUIRED';
  const percent = Math.max(0, Math.min(100, Number(uploading ? uploadProgress : job?.progress) || 0));
  return { running, review, percent, step: uploading ? 2 : review || hasPreview || job?.status === 'COMPLETED' ? 4 : running ? 3 : 1 };
}
