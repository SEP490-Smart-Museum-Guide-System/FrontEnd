import { useEffect, useRef, useState } from 'react';
import { ArrowDown, ArrowRight, ArrowUp, Bell, BookOpen, Compass, Home, Map, ScanLine, User, X } from 'lucide-react';
import { mediaApi, uploadMedia, validateMediaFile } from '../../services/mediaApi';
import './visitorHomeEditor.css';

const API = (import.meta.env.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');
const FALLBACK = '/assets/images/national-museum-web.jpg';

async function optimizeCover(file) {
  if (file.size <= 350 * 1024) return file;

  let bitmap;
  try {
    bitmap = await createImageBitmap(file);
    const scale = Math.min(1, 1600 / Math.max(bitmap.width, bitmap.height));
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(bitmap.width * scale));
    canvas.height = Math.max(1, Math.round(bitmap.height * scale));
    canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    const webp = await new Promise(resolve => canvas.toBlob(resolve, 'image/webp', 0.85));
    if (webp?.type === 'image/webp' && webp.size < file.size) {
      return new File([webp], 'cover.webp', { type: webp.type });
    }
  } catch {
    // Some browsers cannot convert every supported image.
  } finally {
    bitmap?.close();
  }
  return file;
}

function HomePreview({ title, slides, index, onSelect, fallbackImage }) {
  const slide = slides[index];
  const image = slide?.url || fallbackImage || FALLBACK;
  return (
    <div className="home-cover-phone">
      <div className="home-cover-preview">
        <img key={image} src={image} alt="" onError={event => {
          if (!event.currentTarget.src.endsWith(FALLBACK)) event.currentTarget.src = FALLBACK;
        }} />
        <div className="home-cover-preview-actions" aria-hidden="true"><Bell size={16} /><BookOpen size={16} /></div>
        <div className={slides.length > 1 ? 'home-cover-copy has-dots' : 'home-cover-copy'}>
          <strong>{slide?.title?.trim() || title}</strong>
          {slide?.caption && <p>{slide.caption}</p>}
          <span>Khám phá thêm <ArrowRight size={14} /></span>
        </div>
        {slides.length > 1 && <div className="home-cover-dots">
          {slides.map((item, page) => (
            <button key={item.id} type="button" aria-label={`Xem ảnh ${page + 1}`}
              aria-pressed={page === index} onClick={() => onSelect(page)}><i /></button>
          ))}
        </div>}
      </div>
      <div className="home-cover-preview-nav" aria-hidden="true">
        <span><Home size={22} />Trang chủ</span>
        <span><Compass size={22} />Khám phá</span>
        <span><ScanLine size={22} />Quét mã</span>
        <span><Map size={22} />Hành trình</span>
        <span><User size={22} />Cá nhân</span>
      </div>
    </div>
  );
}

export default function VisitorHomeEditor({ fallbackMuseum, onClose, showToast }) {
  const dialog = useRef(null);
  const objectUrls = useRef(new Set());
  const submitLock = useRef(false);
  const [revision, setRevision] = useState(null);
  const [title, setTitle] = useState('');
  const [slides, setSlides] = useState([]);
  const [index, setIndex] = useState(0);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    const urls = objectUrls.current;
    dialog.current.showModal();
    mediaApi('visitor-home', { signal: controller.signal }).then(data => {
      if (controller.signal.aborted) return;
      setRevision(data.revision);
      setTitle(data.title);
      setSlides(data.slides.map(slide => ({
        ...slide,
        id: slide.name,
        url: `${API}/visitor-home/images/${encodeURIComponent(slide.name)}`,
      })));
    }).catch(cause => {
      if (!controller.signal.aborted) setError(cause.message);
    }).finally(() => {
      if (!controller.signal.aborted) setLoading(false);
    });
    return () => {
      controller.abort();
      for (const url of urls) URL.revokeObjectURL(url);
      urls.clear();
      dialog.current?.close();
    };
  }, []);

  function release(slide) {
    if (!slide.file) return;
    URL.revokeObjectURL(slide.url);
    objectUrls.current.delete(slide.url);
  }

  function chooseImages(event, position) {
    const files = Array.from(event.target.files);
    event.target.value = '';
    if (!files.length) return;
    try {
      if (position == null && slides.length + files.length > 10) throw new Error('Tối đa 10 ảnh.');
      files.forEach(file => validateMediaFile(file, false, 5));
      const additions = files.map(file => {
        const url = URL.createObjectURL(file);
        objectUrls.current.add(url);
        return { id: url, url, file, title: '', caption: '' };
      });
      if (position == null) {
        setSlides([...slides, ...additions]);
        setIndex(slides.length);
      } else {
        release(slides[position]);
        setSlides(slides.map((item, i) => i === position ? { ...additions[0], title: item.title, caption: item.caption } : item));
        setIndex(position);
      }
      setError('');
    } catch (cause) {
      setError(cause.message);
    }
  }

  function move(position, offset) {
    const reordered = [...slides];
    const [slide] = reordered.splice(position, 1);
    reordered.splice(position + offset, 0, slide);
    setSlides(reordered);
    setIndex(position + offset);
  }

  async function save(event) {
    event.preventDefault();
    if (!revision || submitLock.current) return;
    submitLock.current = true;
    setSaving(true);
    setError('');
    try {
      const form = new FormData();
      const rows = [];
      let fileIndex = 0;
      for (const slide of slides) {
        const { title, caption } = slide;
        if (slide.file) {
          form.append('files', await optimizeCover(slide.file));
          rows.push({ fileIndex: fileIndex++, title, caption });
        } else {
          rows.push({ name: slide.name, title, caption });
        }
      }
      form.append('draft', JSON.stringify({ revision, title, slides: rows }));
      await uploadMedia('visitor-home', form);
      showToast('Đã lưu trang chủ khách.');
      onClose();
    } catch (cause) {
      setError(cause.message);
    } finally {
      submitLock.current = false;
      setSaving(false);
    }
  }

  return (
    <dialog className="home-cover-dialog" ref={dialog} aria-labelledby="visitor-home-heading"
      onCancel={event => { event.preventDefault(); if (!saving) onClose(); }}>
      <form onSubmit={save}>
        <header>
          <h3 id="visitor-home-heading">Trang chủ khách</h3>
          <button type="button" className="btn btn-secondary" aria-label="Đóng" disabled={saving} onClick={onClose}><X size={18} /></button>
        </header>
        {error && <p className="home-cover-error" role="alert">{error}</p>}
        {loading && <p className="home-cover-error" role="status">Đang tải cấu hình…</p>}
        {revision && <div className="home-cover-editor-grid">
          <fieldset disabled={saving}>
            <p>Ảnh đầu tiên sẽ xuất hiện khi khách mở trang chủ.</p>
            <ol>
              {slides.map((slide, position) => <li key={slide.id}>
                <button type="button" className="home-cover-thumb" aria-label={`Xem trước ảnh ${position + 1}`}
                  aria-pressed={position === index} onClick={() => setIndex(position)}><img src={slide.url} alt="" /></button>
                <div className="home-cover-controls">
                  <label className="home-cover-field">Tiêu đề ảnh {position + 1}
                    <input maxLength={120} value={slide.title ?? ''} placeholder={title || fallbackMuseum?.name || 'Khám phá bảo tàng'}
                      onChange={event => {
                        const { value } = event.target;
                        setSlides(slides.map((item, i) => position === i ? { ...item, title: value } : item));
                        setIndex(position);
                      }} />
                  </label>

                  <label className="home-cover-field">Chú thích ảnh {position + 1}
                    <input maxLength={160} value={slide.caption} onChange={event => {
                      const { value } = event.target;
                      setSlides(slides.map((item, i) => position === i ? { ...item, caption: value } : item));
                      setIndex(position);
                    }} />
                  </label>
                  <div>
                    <label className="home-cover-file">Thay ảnh
                      <input type="file" accept=".jpg,.jpeg,.png,.webp" aria-label={`Thay ảnh ${position + 1}`}
                        onChange={event => chooseImages(event, position)} />
                    </label>
                    <button type="button" aria-label={`Đưa ảnh ${position + 1} lên`} disabled={position === 0}
                      onClick={() => move(position, -1)}><ArrowUp size={16} /></button>
                    <button type="button" aria-label={`Đưa ảnh ${position + 1} xuống`} disabled={position === slides.length - 1}
                      onClick={() => move(position, 1)}><ArrowDown size={16} /></button>
                    <button type="button" aria-label={`Xóa ảnh ${position + 1}`} onClick={() => {
                      release(slide);
                      setSlides(slides.filter((_, i) => i !== position));
                      setIndex(Math.min(position, Math.max(0, slides.length - 2)));
                    }}><X size={16} /></button>
                  </div>
                </div>
              </li>)}
            </ol>
            {slides.length < 10 && <label className="home-cover-field">Thêm ảnh
              <input type="file" multiple accept=".jpg,.jpeg,.png,.webp" onChange={event => chooseImages(event)} />
            </label>}
            <small>Tối đa 10 ảnh PNG, JPEG hoặc WebP, mỗi ảnh tối đa 5 MB.</small>
          </fieldset>
          <section className="home-cover-preview-panel" aria-label="Xem trước trên điện thoại">
            <h4>Xem trước trên điện thoại</h4>
            <HomePreview title={title.trim() || fallbackMuseum?.name || 'Khám phá bảo tàng'} slides={slides}
              index={index} onSelect={setIndex} fallbackImage={fallbackMuseum?.image} />
          </section>
        </div>}
        <footer>
          <button type="button" className="btn btn-secondary" disabled={saving} onClick={onClose}>Đóng</button>
          <button type="submit" className="btn btn-primary" disabled={!revision || saving}>{saving ? 'Đang lưu…' : 'Lưu trang chủ'}</button>
        </footer>
      </form>
    </dialog>
  );
}
