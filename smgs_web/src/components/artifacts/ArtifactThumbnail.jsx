import React, { useEffect, useState } from 'react';
import { getAuthToken } from '../../services/auth';

const ARTIFACT_IMAGE_PLACEHOLDER = '/assets/images/placeholder.svg';
const ARTIFACT_MEDIA_FILE_PATH = /^\/api\/artifacts\/\d+\/media\/\d+\/file$/;

export default function ArtifactThumbnail({ src, alt, style }) {
  const [displaySrc, setDisplaySrc] = useState(ARTIFACT_IMAGE_PLACEHOLDER);

  useEffect(() => {
    if (!src) {
      setDisplaySrc(ARTIFACT_IMAGE_PLACEHOLDER);
      return;
    }

    let objectUrl;
    const controller = new AbortController();
    const imageUrl = new URL(src, window.location.origin);
    const requiresApiAuth = ARTIFACT_MEDIA_FILE_PATH.test(imageUrl.pathname) && imageUrl.origin === window.location.origin;

    if (!requiresApiAuth) {
      setDisplaySrc(src);
      return () => controller.abort();
    }

    const token = getAuthToken();
    if (!token) {
      setDisplaySrc(ARTIFACT_IMAGE_PLACEHOLDER);
      return () => controller.abort();
    }

    setDisplaySrc(ARTIFACT_IMAGE_PLACEHOLDER);
    fetch(imageUrl.href, {
      headers: { Accept: 'image/*', Authorization: `Bearer ${token}` },
      signal: controller.signal,
    })
      .then(response => {
        if (!response.ok) throw new Error(`Ảnh hiện vật không tải được (${response.status}).`);
        return response.blob();
      })
      .then(blob => {
        if (controller.signal.aborted) return;
        if (!blob.type.startsWith('image/')) throw new Error('Phản hồi ảnh hiện vật không hợp lệ.');
        objectUrl = URL.createObjectURL(blob);
        setDisplaySrc(objectUrl);
      })
      .catch(() => {
        if (!controller.signal.aborted) setDisplaySrc(ARTIFACT_IMAGE_PLACEHOLDER);
      });

    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [src]);

  return <img src={displaySrc} alt={alt} style={style} onError={event => { if (event.currentTarget.getAttribute('src') !== ARTIFACT_IMAGE_PLACEHOLDER) event.currentTarget.src = ARTIFACT_IMAGE_PLACEHOLDER; }} />;
}
