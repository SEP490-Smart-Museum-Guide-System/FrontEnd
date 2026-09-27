import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Sparkles,
  Layers,
  Volume2,
  HelpCircle,
  Globe,
  Bot,
  Send,
  Check,
  RefreshCw,
  Copy,
  ArrowRight,
  FileCheck,
  Play
} from 'lucide-react';

export default function AIContentStudio({ initialArtifact }) {
  const { artifacts, submitToCuration, showToast } = useApp();

  const [selectedArtifactId, setSelectedArtifactId] = useState(
    initialArtifact?.id || artifacts[0]?.id || ''
  );
  const [activeMode, setActiveMode] = useState('narration'); // narration | quiz | multilingual | knowledge
  const [audience, setAudience] = useState('children'); // children | general | scholar
  const [targetLang, setTargetLang] = useState('vi'); // vi | en | fr | ja
  const [tone, setTone] = useState('vivid'); // vivid | inspiring | academic | story
  const [quizCount, setQuizCount] = useState(3);
  const [difficulty, setDifficulty] = useState('medium'); // easy | medium | hard

  const [isGenerating, setIsGenerating] = useState(false);
  const [generatedOutput, setGeneratedOutput] = useState('');
  const [copied, setCopied] = useState(false);

  const selectedArtifact = artifacts.find(a => a.id === selectedArtifactId) || artifacts[0];

  useEffect(() => {
    if (initialArtifact?.id) {
      setSelectedArtifactId(initialArtifact.id);
    }
  }, [initialArtifact]);

  // Generate content simulation
  const handleGenerate = () => {
    setIsGenerating(true);
    setGeneratedOutput('');

    setTimeout(() => {
      let result = '';
      if (activeMode === 'narration') {
        if (audience === 'children') {
          result = `Chào các bạn nhỏ thân mến! Chào mừng các bạn đến với bảo tàng di sản.

Hôm nay, chúng mình hãy cùng làm quen với người bạn đặc biệt này nhé — đó chính là "${selectedArtifact.name}"!

Hiện vật này đã có tuổi đời hơn ${selectedArtifact.dating || '2.000 năm'} rồi đấy. Các bạn thử nhìn xem, toàn bộ được đúc bằng ${selectedArtifact.material || 'đồng thau'} vô cùng lấp lánh và tinh xảo!

Hãy chú ý vào các hoa văn sinh động trên bề mặt: có đàn chim đang sải cánh bay lượn, có những người đang giã gạo vui vẻ và cả những ngôi nhà sàn ấm cúng nữa. Người xưa tạo ra hiện vật này với ước mong cho mùa màng bội thu và mọi người luôn được bình an, mạnh khỏe.

Đố các bạn biết, bí mật nào đang ẩn giấu trong những hoa văn này nữa? Hãy tiếp tục khám phá nhé!`;
        } else if (audience === 'scholar') {
          result = `BẢN LUẬN THUYẾT MINH CHUYÊN KHẢO: ${selectedArtifact.name.toUpperCase()}

1. BỐI CẢNH LỊCH SỬ & KHẢO CỔ HỌC:
Hiện vật thuộc ${selectedArtifact.period}, đại diện cho giai đoạn phát triển rực rỡ của kỹ nghệ luyện kim và đúc kim khí tại lưu vực sông Hồng và văn minh Đại Việt cổ.

2. ĐẶC ĐIỂM HÌNH THÁI VÀ KỸ THUẬT CHẾ TÁC:
Chất liệu: ${selectedArtifact.material}.
Kỹ thuật đúc: Phương pháp đúc khuôn nhiều mang kết hợp chạm khắc hoa văn âm bản trực tiếp vào lòng khuôn trước khi rót hợp kim nóng chảy.

3. HỆ THỐNG BIỂU TƯỢNG VÀ THẾ GIỚI QUAN:
Mô thức hoa văn hình học đồng tâm kết hợp hình tượng nhân thần và linh vật phản ánh sâu sắc tư duy vũ trụ luận nhị nguyên (Âm - Dương, Đất - Trời) và tín ngưỡng sùng bái tự nhiên của cư dân nông nghiệp cổ đại.`;
        } else {
          // general
          result = `THUYẾT MINH DI SẢN: ${selectedArtifact.name}

Kính chào quý khách! Trước mắt quý vị là "${selectedArtifact.name}", một trong những báu vật tiêu biểu thuộc ${selectedArtifact.period}.

Hiện vật được làm bằng ${selectedArtifact.material}, minh chứng sống động cho trình độ thẩm mỹ và kỹ thuật chế tác bậc thầy của cha ông chúng ta cách đây ${selectedArtifact.dating || 'nhiều thế kỷ'}.

Điểm nhấn đặc biệt của hiện vật này nằm ở nghệ thuật trang trí hoa văn độc bản, tái hiện chân thực đời sống sinh hoạt, phong tục tập quán và khát vọng phồn vinh của dân tộc.

Kính mời quý khách dành ít phút chiêm ngưỡng từng đường nét hoa văn và sử dụng tính năng 3D AR trên ứng dụng di động để quan sát đa chiều ở độ phân giải cao nhất.`;
        }
      } else if (activeMode === 'quiz') {
        const sampleQuizzes = [
          {
            question: `Hiện vật "${selectedArtifact.name}" được chế tác chủ yếu bằng chất liệu gì?`,
            options: [selectedArtifact.material, 'Đất nung không men', 'Đá cẩm thạch trắng', 'Gỗ lim phủ sơn'],
            correctIndex: 0,
            explanation: `Hiện vật được đúc và chế tác hoàn toàn từ ${selectedArtifact.material}.`
          },
          {
            question: `Hiện vật "${selectedArtifact.name}" thuộc thời kỳ văn hóa / triều đại nào?`,
            options: [selectedArtifact.period, 'Thời kỳ Đồ đá cũ', 'Thời cận đại thế kỷ XX', 'Thời kỳ đồ gốm sơ khai'],
            correctIndex: 0,
            explanation: `Đây là hiện vật tiêu biểu của ${selectedArtifact.period}.`
          },
          {
            question: `Ý nghĩa biểu tượng nổi bật nhất trên hiện vật "${selectedArtifact.name}" là gì?`,
            options: ['Tín ngưỡng phồn thực và khát vọng mùa màng bội thu', 'Biểu tượng chiến tranh hủy diệt', 'Ký hiệu buôn bán thương mại phương Tây', 'Bản đồ thiên văn hiện đại'],
            correctIndex: 0,
            explanation: `Hoa văn trên hiện vật phản ánh sâu sắc thế giới quan nông nghiệp và tín ngưỡng dân gian cổ truyền.`
          }
        ];
        result = JSON.stringify(sampleQuizzes, null, 2);
      } else if (activeMode === 'multilingual') {
        result = `[ENGLISH TRANSLATION]
Title: ${selectedArtifact.altName || selectedArtifact.name}
Period: ${selectedArtifact.period}
Material: ${selectedArtifact.material}
Summary: ${selectedArtifact.shortDesc}

Historical Significance:
This masterpiece stands as an extraordinary testament to ancient Vietnamese craftsmanship, spiritual beliefs, and agricultural civilization. Displayed permanently at ${selectedArtifact.museumName}.`;
      } else {
        // knowledge
        result = `BỘ TRI THỨC HỎI - ĐÁP CHO AI ASSISTANT (${selectedArtifact.name}):

Q1: Hiện vật này có từ bao giờ?
A1: Hiện vật có niên đại ${selectedArtifact.dating || 'nhiều thế kỷ trước'}, thuộc ${selectedArtifact.period}.

Q2: Tôi có thể xem hiện vật này ở phòng trưng bày nào?
A2: Quý khách có thể chiêm ngưỡng trực tiếp tại ${selectedArtifact.galleryName} (${selectedArtifact.buildingName}).

Q3: Điểm đặc sắc nhất của hiện vật này là gì?
A3: ${selectedArtifact.shortDesc}

Q4: Hiện vật này có phải là Bảo vật Quốc gia không?
A4: ${selectedArtifact.isNationalTreasure ? 'Đúng vậy, hiện vật đã được Thủ tướng Chính phủ công nhận là Bảo vật Quốc gia vô giá của Việt Nam.' : 'Hiện vật là di sản tiêu biểu quý hiếm được bảo tồn nghiêm ngặt tại bảo tàng.'}`;
      }

      setGeneratedOutput(result);
      setIsGenerating(false);
      showToast('AI đã hoàn tất quá trình sinh nội dung di sản!');
    }, 1200);
  };

  // Submit to Curation Queue
  const handleSubmitForReview = () => {
    if (!generatedOutput) return;

    submitToCuration({
      type: activeMode === 'narration' ? 'audio_narration' : activeMode === 'quiz' ? 'quiz' : 'artifact_update',
      title: `AI Studio: ${activeMode === 'narration' ? 'Thuyết minh' : activeMode === 'quiz' ? 'Bộ câu hỏi Quiz' : 'Tư liệu di sản'} — ${selectedArtifact.name} (${audience === 'children' ? 'Thiếu nhi' : audience === 'scholar' ? 'Học thuật' : 'Phổ thông'})`,
      targetArtifactId: selectedArtifact.id,
      targetArtifactName: selectedArtifact.name,
      submittedBy: 'Nguyễn Mai Anh (Museum Staff)',
      priority: 'high',
      currentVersion: selectedArtifact.shortDesc || 'Bản cơ bản',
      proposedContent: generatedOutput,
      changesSummary: `Nội dung được tạo tự động bởi AI Content Studio với chế độ [${activeMode.toUpperCase()}] và phong cách [${audience}] dành riêng cho hiện vật ${selectedArtifact.name}.`,
      feedback: ''
    });
  };

  const handleCopy = () => {
    navigator.clipboard?.writeText(generatedOutput);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div>
      {/* Page Header */}
      <div style={{ marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '42px',
            height: '42px',
            borderRadius: '10px',
            background: 'linear-gradient(135deg, var(--color-gold-500), var(--color-burgundy-700))',
            color: '#FFFFFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: 'var(--shadow-gold)'
          }}>
            <Sparkles size={22} />
          </div>
          <div>
            <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
              AI Content Studio — Sáng Tạo Thuyết Minh & Quiz Di Sản
            </h2>
            <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '2px' }}>
              Trợ lý trí tuệ nhân tạo chuyên sâu giúp nhân viên tạo nhanh bài thuyết minh đa độ tuổi, trắc nghiệm tương tác và bản dịch đa ngữ
            </p>
          </div>
        </div>
      </div>

      {/* Main Studio Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '380px 1fr', gap: '28px' }}>
        {/* Left Column: Configuration & Prompting */}
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ fontSize: '1.125rem', fontWeight: '700', marginBottom: '16px', color: 'var(--color-charcoal-900)' }}>
            Cấu hình Tạo Nội Dung
          </h3>

          {/* 1. Select Artifact */}
          <div className="form-group">
            <label className="form-label">Chọn hiện vật mục tiêu *</label>
            <select
              className="form-select"
              value={selectedArtifactId}
              onChange={(e) => setSelectedArtifactId(e.target.value)}
            >
              {artifacts.map(a => (
                <option key={a.id} value={a.id}>
                  {a.name} ({a.code}) {a.isNationalTreasure ? '⭐' : ''}
                </option>
              ))}
            </select>
          </div>

          {/* Artifact Preview mini card */}
          {selectedArtifact && (
            <div style={{
              background: '#FAF7F2',
              padding: '12px',
              borderRadius: '8px',
              border: '1px solid var(--color-paper-border)',
              display: 'flex',
              gap: '12px',
              marginBottom: '20px'
            }}>
              <div style={{ width: '50px', height: '50px', borderRadius: '6px', overflow: 'hidden', flexShrink: 0, background: '#1A1F26' }}>
                <img
                  src={selectedArtifact.image || '/assets/images/ngoc-lu-web.jpg'}
                  alt=""
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
                />
              </div>
              <div style={{ overflow: 'hidden' }}>
                <div style={{ fontSize: '0.8125rem', fontWeight: '700', color: 'var(--color-burgundy-900)', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                  {selectedArtifact.name}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                  {selectedArtifact.galleryName} • {selectedArtifact.material}
                </div>
              </div>
            </div>
          )}

          {/* 2. Generation Mode Selector */}
          <div className="form-group">
            <label className="form-label">Chế độ tạo nội dung</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
              {[
                { id: 'narration', label: 'Thuyết minh Audio', icon: Volume2 },
                { id: 'quiz', label: 'Bộ Quiz trắc nghiệm', icon: HelpCircle },
                { id: 'multilingual', label: 'Dịch thuật đa ngữ', icon: Globe },
                { id: 'knowledge', label: 'Tri thức AI Bot', icon: Bot },
              ].map(m => {
                const Icon = m.icon;
                const isSelected = activeMode === m.id;
                return (
                  <button
                    key={m.id}
                    type="button"
                    onClick={() => setActiveMode(m.id)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      padding: '10px 12px',
                      borderRadius: '8px',
                      fontSize: '0.8125rem',
                      fontWeight: isSelected ? '600' : '500',
                      background: isSelected ? 'var(--color-burgundy-700)' : '#FFF',
                      color: isSelected ? '#FFF' : 'var(--color-charcoal-700)',
                      border: isSelected ? '1px solid var(--color-burgundy-800)' : '1px solid var(--color-paper-border)',
                      transition: 'all var(--transition-fast)'
                    }}
                  >
                    <Icon size={16} />
                    <span>{m.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 3. Sub-parameters based on Mode */}
          {activeMode === 'narration' && (
            <>
              <div className="form-group">
                <label className="form-label">Đối tượng tiếp nhận (Target Audience)</label>
                <select
                  className="form-select"
                  value={audience}
                  onChange={(e) => setAudience(e.target.value)}
                >
                  <option value="children">Thiếu nhi (6 - 12 tuổi, sinh động, dễ hiểu)</option>
                  <option value="general">Khách đại chúng (Hấp dẫn, truyền cảm, cô đọng)</option>
                  <option value="scholar">Học thuật / Nhà nghiên cứu (Chuyên sâu, khảo cổ)</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Phong cách & Ngữ điệu (Tone)</label>
                <select
                  className="form-select"
                  value={tone}
                  onChange={(e) => setTone(e.target.value)}
                >
                  <option value="vivid">Sinh động, kể chuyện (Storytelling)</option>
                  <option value="inspiring">Hào hùng, tôn vinh lịch sử dân tộc</option>
                  <option value="academic">Trang trọng, chuẩn mực bảo tàng</option>
                </select>
              </div>
            </>
          )}

          {activeMode === 'quiz' && (
            <>
              <div className="form-group">
                <label className="form-label">Số lượng câu hỏi trắc nghiệm</label>
                <select
                  className="form-select"
                  value={quizCount}
                  onChange={(e) => setQuizCount(Number(e.target.value))}
                >
                  <option value={3}>3 câu hỏi tương tác nhanh</option>
                  <option value={5}>5 câu hỏi khám phá sâu</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Độ khó câu hỏi</label>
                <select
                  className="form-select"
                  value={difficulty}
                  onChange={(e) => setDifficulty(e.target.value)}
                >
                  <option value="easy">Dễ (Dành cho khách tham quan đại chúng)</option>
                  <option value="medium">Trung bình (Tìm hiểu chi tiết hoa văn)</option>
                  <option value="hard">Thử thách (Dành cho người yêu sử học)</option>
                </select>
              </div>
            </>
          )}

          {activeMode === 'multilingual' && (
            <div className="form-group">
              <label className="form-label">Ngôn ngữ mục tiêu</label>
              <select
                className="form-select"
                value={targetLang}
                onChange={(e) => setTargetLang(e.target.value)}
              >
                <option value="en">English (Tiếng Anh chuyên ngành di sản)</option>
                <option value="fr">Français (Tiếng Pháp)</option>
                <option value="ja">日本語 (Tiếng Nhật Bản)</option>
              </select>
            </div>
          )}

          {/* Action Generate Button */}
          <button
            type="button"
            onClick={handleGenerate}
            disabled={isGenerating}
            className="btn btn-gold"
            style={{ width: '100%', padding: '12px', marginTop: '12px' }}
          >
            {isGenerating ? (
              <>
                <RefreshCw size={16} className="spin-animation" /> Đang xử lý tri thức AI...
              </>
            ) : (
              <>
                <Sparkles size={16} /> Sinh nội dung bằng AI
              </>
            )}
          </button>
        </div>

        {/* Right Column: Output & Action Studio */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column' }}>
          <div className="card-header" style={{ background: '#FAF7F2' }}>
            <div className="card-title">
              <FileCheck size={18} color="var(--color-burgundy-700)" />
              <span>Kết Quả & Trình Soạn Thảo Hiệu Đính</span>
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              {generatedOutput && (
                <button
                  type="button"
                  onClick={handleCopy}
                  className="btn btn-secondary btn-sm"
                >
                  {copied ? <Check size={14} color="var(--color-success)" /> : <Copy size={14} />}
                  <span>{copied ? 'Đã sao chép' : 'Sao chép'}</span>
                </button>
              )}
            </div>
          </div>

          <div className="card-body" style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
            {isGenerating ? (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 20px' }}>
                <div style={{
                  width: '60px',
                  height: '60px',
                  borderRadius: '50%',
                  background: 'var(--color-gold-100)',
                  color: 'var(--color-gold-600)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: '16px',
                  animation: 'pulse 1.5s infinite'
                }}>
                  <Sparkles size={32} />
                </div>
                <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
                  AI đang phân tích tư liệu hiện vật...
                </h4>
                <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
                  Áp dụng mô hình kiến thức bảo tàng để tạo nội dung chuẩn kiểm duyệt
                </p>
              </div>
            ) : generatedOutput ? (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <textarea
                  className="form-textarea"
                  style={{
                    flex: 1,
                    minHeight: '340px',
                    fontFamily: activeMode === 'quiz' ? 'monospace' : 'inherit',
                    fontSize: '0.875rem',
                    lineHeight: '1.7',
                    padding: '16px'
                  }}
                  value={generatedOutput}
                  onChange={(e) => setGeneratedOutput(e.target.value)}
                />

                <div style={{
                  marginTop: '16px',
                  padding: '14px 18px',
                  background: 'var(--color-paper-accent)',
                  borderRadius: '8px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  border: '1px solid var(--color-paper-border)'
                }}>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)' }}>
                    💡 Nhân viên có thể chỉnh sửa trực tiếp nội dung trên trước khi gửi sang Kiểm duyệt viên.
                  </div>

                  <button
                    type="button"
                    onClick={handleSubmitForReview}
                    className="btn btn-primary"
                  >
                    <Send size={16} /> Gửi sang Hàng đợi Kiểm duyệt
                  </button>
                </div>
              </div>
            ) : (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 20px', textAlign: 'center' }}>
                <Sparkles size={48} color="var(--color-charcoal-300)" style={{ marginBottom: '16px' }} />
                <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: 'var(--color-charcoal-800)' }}>
                  Sẵn sàng tạo nội dung di sản
                </h4>
                <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', maxWidth: '420px', marginTop: '6px' }}>
                  Chọn cấu hình ở cột bên trái và nhấn nút <strong>"Sinh nội dung bằng AI"</strong> để bắt đầu tạo kịch bản thuyết minh hoặc câu hỏi quiz tự động.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
