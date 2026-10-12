import React from 'react';
import { ExternalLink, MapPin, Navigation, ShieldCheck } from 'lucide-react';

const directionsUrl = (museum) => `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(museum.address)}`;

export default function MuseumMapPreview({ museums, currentRole, onToggleVisibility }) {
  const publicMuseums = museums.filter(museum => museum.googleMapsVisible);

  return (
    <section className="google-maps-card card" aria-labelledby="google-maps-title">
      <div className="google-maps-heading">
        <div>
          <span className="google-maps-kicker"><MapPin size={14} /> Bản mô phỏng tích hợp</span>
          <h3 id="google-maps-title">Google Maps · Điểm đến bảo tàng</h3>
          <p>Chỉ ghim bảo tàng công khai. Hiện vật, phòng trưng bày và dữ liệu nội bộ không xuất hiện trên bản đồ khách.</p>
        </div>
        <span className="google-maps-count"><ShieldCheck size={15} /> {publicMuseums.length} bảo tàng công khai</span>
      </div>

      <div className="google-maps-layout">
        <div className="google-map-simulation" role="img" aria-label={`${publicMuseums.length} bảo tàng đang hiển thị trên bản đồ mô phỏng`}>
          <span className="map-water map-water-one" />
          <span className="map-water map-water-two" />
          <span className="map-road map-road-one" />
          <span className="map-road map-road-two" />
          <span className="map-road map-road-three" />
          <span className="map-area-label map-area-label-one">BA ĐÌNH</span>
          <span className="map-area-label map-area-label-two">HOÀN KIẾM</span>
          {publicMuseums.map(museum => (
            <a
              className="google-map-pin"
              href={directionsUrl(museum)}
              target="_blank"
              rel="noreferrer"
              key={museum.id}
              style={{ left: `${museum.mapPosition?.x ?? 50}%`, top: `${museum.mapPosition?.y ?? 50}%` }}
              aria-label={`Chỉ đường đến ${museum.name} bằng Google Maps`}
              title={`Chỉ đường đến ${museum.name}`}
            >
              <MapPin size={22} fill="currentColor" />
              <span>{museum.shortName}</span>
            </a>
          ))}
          <div className="google-map-brand"><span>Google</span> Maps <small>Bản mô phỏng</small></div>
        </div>

        <div className="google-maps-list">
          {museums.map(museum => {
            const visible = museum.googleMapsVisible;
            return (
              <article className={`google-museum-row ${visible ? 'is-visible' : 'is-hidden'}`} key={museum.id}>
                <div className="google-museum-row-main">
                  <span className="google-museum-status" aria-hidden="true" />
                  <div>
                    <strong>{museum.name}</strong>
                    <small>{visible ? 'Khách có thể tìm và mở chỉ đường.' : 'Chưa hiển thị cho khách trên bản đồ.'}</small>
                  </div>
                </div>
                {currentRole === 'administrator' ? (
                  <button
                    type="button"
                    className={`map-visibility-toggle ${visible ? 'is-on' : ''}`}
                    aria-pressed={visible}
                    onClick={() => onToggleVisibility(museum.id)}
                  >
                    <span aria-hidden="true" />
                    {visible ? 'Đang hiển thị' : 'Đang ẩn'}
                  </button>
                ) : visible ? (
                  <a className="btn btn-secondary btn-sm" href={directionsUrl(museum)} target="_blank" rel="noreferrer">
                    <Navigation size={14} /> Chỉ đường <ExternalLink size={13} />
                  </a>
                ) : (
                  <span className="google-hidden-label">Chưa công khai</span>
                )}
              </article>
            );
          })}
        </div>
      </div>
      {currentRole === 'administrator' && <p className="google-maps-admin-note">Thay đổi ở đây là bản giả lập theo dữ liệu frontend. Khi có backend, trạng thái này sẽ được trả về cho ứng dụng Khách qua API danh sách bảo tàng công khai.</p>}
    </section>
  );
}
