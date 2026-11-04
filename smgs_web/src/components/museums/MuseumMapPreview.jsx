import React from 'react';
import { ExternalLink, MapPin, Navigation, ShieldCheck } from 'lucide-react';

const directionsUrl = (museum) => `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(museum.address)}`;

export default function MuseumMapPreview({ museums }) {
  const publicMuseums = museums.filter(museum => museum.googleMapsVisible);

  return (
    <section className="google-maps-card card" aria-labelledby="google-maps-title">
      <div className="google-maps-heading">
        <div>
          <span className="google-maps-kicker"><MapPin size={14} /> Điểm đến từ máy chủ</span>
          <h3 id="google-maps-title">Google Maps · Điểm đến bảo tàng</h3>
          <p>Danh sách bảo tàng công khai. Hiện vật, phòng trưng bày và dữ liệu nội bộ không xuất hiện trên bản đồ khách.</p>
        </div>
        <span className="google-maps-count"><ShieldCheck size={15} /> {publicMuseums.length} bảo tàng công khai</span>
      </div>

      <div className="google-maps-layout">
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
                {visible ? (
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
      <p>Trạng thái công khai theo dữ liệu bảo tàng trên máy chủ. Mở Google Maps để xem vị trí và chỉ đường.</p>
    </section>
  );
}
