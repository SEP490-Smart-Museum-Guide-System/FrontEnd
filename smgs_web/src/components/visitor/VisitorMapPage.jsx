import React from 'react';
import { ArrowLeft, Landmark, MapPin, Navigation } from 'lucide-react';
import { useApp } from '../../context/AppContext';

const directionsUrl = (museum) => `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(museum.address)}`;

export default function VisitorMapPage() {
  const { museums, closeVisitorPreview } = useApp();
  const publicMuseums = museums.filter(museum => museum.googleMapsVisible);
  return <main className="visitor-page">
    <header className="visitor-topbar"><div className="visitor-brand"><Landmark size={22} /><span>SMGS · Cẩm nang bảo tàng</span></div><button className="btn btn-secondary btn-sm" onClick={closeVisitorPreview} type="button"><ArrowLeft size={15} /> Quay lại đăng nhập</button></header>
    <section className="visitor-hero"><span>KHÁM PHÁ DI SẢN VIỆT · TÀI KHOẢN KHÁCH</span><h1>Tìm một bảo tàng,<br />bắt đầu hành trình.</h1><p>Chọn bảo tàng và mở Google Maps để được chỉ đường. Chỉ các bảo tàng được công khai mới xuất hiện tại đây.</p></section>
    <section className="visitor-map-grid">
      {publicMuseums.map(museum => <article className="visitor-museum-card" key={museum.id}><img src={museum.image} alt="" /><div className="visitor-museum-body"><span className="visitor-category">Bảo tàng công khai</span><h2>{museum.name}</h2><p><MapPin size={15} /> {museum.address}</p><a className="btn btn-primary" href={directionsUrl(museum)} target="_blank" rel="noreferrer"><Navigation size={16} /> Chỉ đường với Google Maps</a></div></article>)}
      {!publicMuseums.length && <p className="visitor-empty">Hiện chưa có bảo tàng nào được công khai trên bản đồ.</p>}
    </section>
  </main>;
}
