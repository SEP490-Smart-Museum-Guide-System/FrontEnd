import { getAuthToken } from './auth.js';

/**
 * TTS AI Integration Service
 * Sends speech requests through the BE gateway, which holds the Azure service key.
 */

const API_BASE = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

async function getTtsResponse(text, language) {
  const token = getAuthToken();
  return fetch(`${API_BASE}/tts/speech`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'audio/wav',
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({ text, language: language.startsWith('vi') ? 'vi-VN' : 'en-US' }),
    signal: AbortSignal.timeout(70000)
  });
}

// In-memory cache for audio blobs during the session
const audioCache = new Map();

/**
 * Check if the TTS Service is running and models are loaded
 * @returns {Promise<{ ok: boolean, status: string, service?: string, voice?: string }>}
 */
export async function checkTtsHealthApi() {
  try {
    const response = await fetch(`${API_BASE}/tts/health`, {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
      signal: AbortSignal.timeout(4000)
    });
    if (!response.ok) {
      return { ok: false, status: `HTTP ${response.status}` };
    }
    const data = await response.json();
    return {
      ok: data?.status === 'ok',
      status: data?.status || 'unknown',
      service: data?.service,
      voice: data?.voice
    };
  } catch (error) {
    return { ok: false, status: 'unavailable', error: error.message };
  }
}

/**
 * Generate WAV speech from Vietnamese narration text
 * @param {Object} options
 * @param {string} options.text - Curated narration text
 * @param {number} [options.speed=1.0] - Speech speed (0.75 - 1.25)
 * @param {string} [options.language='vi-VN'] - Language code
 * @returns {Promise<{ audioUrl: string, blob: Blob, voice: string, cacheHit: boolean }>}
 */
export async function generateSpeechApi({ text, speed = 1.0, language = 'vi-VN' }) {
  const cleanText = (text || '').trim();
  if (!cleanText) {
    throw new Error('Nội dung thuyết minh không được để trống.');
  }

  // Check client-side cache
  const cacheKey = `${language}:${speed.toFixed(2)}:${cleanText}`;
  if (audioCache.has(cacheKey)) {
    const cached = audioCache.get(cacheKey);
    return { ...cached, cacheHit: true };
  }

  const response = await getTtsResponse(cleanText, language);

  if (!response.ok) {
    let errorDetail = `Lỗi tạo thuyết minh âm thanh (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail || errJson?.message) errorDetail = errJson.detail || errJson.message;
    } catch {
      // response is not json
    }
    throw new Error(errorDetail);
  }

  const blob = await response.blob();
  const audioUrl = URL.createObjectURL(blob);
  const voice = response.headers.get('X-TTS-Voice') || 'Vietnamese Neural';
  const cacheHit = response.headers.get('X-TTS-Cache') === 'HIT';

  const result = { audioUrl, blob, voice, cacheHit };
  audioCache.set(cacheKey, result);
  return result;
}
