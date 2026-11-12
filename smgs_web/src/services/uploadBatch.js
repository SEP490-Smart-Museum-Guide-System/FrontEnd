// Keep successful files out of retry queues; stop cleanly when cancelled.
export async function uploadBatch(files, { upload, signal, onProgress = () => {} }) {
  const saved = [], failed = [];
  for (let index = 0; index < files.length; index++) {
    const file = files[index];
    if (signal?.aborted) {
      failed.push(...files.slice(index).map(file => ({ file, message: 'Chưa tải lên (đã hủy).' })));
      break;
    }
    try {
      const result = await upload(file, progress => onProgress({ file, index, total: files.length, progress }));
      saved.push({ file, result });
    } catch (error) {
      failed.push({ file, message: error.message || 'Không thể tải tệp.' });
    }
  }
  return { saved, failed };
}
