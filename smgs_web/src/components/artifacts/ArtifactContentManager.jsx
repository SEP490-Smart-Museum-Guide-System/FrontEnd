import React from 'react';
import { backend } from '../../services/backend';
import { Empty, LoadState, useData } from '../common/BusinessUI';

export default function ArtifactContentManager({ artifactId }) {
  const resource = useData(
    `artifact-content:${artifactId}`,
    signal => backend(`artifacts/${artifactId}/contents/versions`, { signal }),
    [],
  );

  const latestByLanguage = new Map();
  for (const content of resource.data) {
    const previous = latestByLanguage.get(content.languageCode);
    if (!previous || content.versionNo > previous.versionNo) {
      latestByLanguage.set(content.languageCode, content);
    }
  }

  return (
    <section className="card business-card" style={{ padding: 16, marginTop: 20 }}>
      <h4 className="card-title">Nội dung đã nhập</h4>
      <LoadState resource={resource}>
        {latestByLanguage.size === 0 ? <Empty>Hiện vật chưa có nội dung đã nhập.</Empty> :
          [...latestByLanguage.values()].map(content => (
            <article key={content.languageCode} style={{ marginTop: 16 }}>
              <h5>{content.title} · {content.languageCode?.toUpperCase()}</h5>
              <p style={{ whiteSpace: 'pre-wrap' }}>{content.description}</p>
              {content.narrationText && content.narrationText.trim() !== content.description?.trim() && (
                <>
                  <strong>Kịch bản thuyết minh</strong>
                  <p style={{ whiteSpace: 'pre-wrap' }}>{content.narrationText}</p>
                </>
              )}
            </article>
          ))}
      </LoadState>
    </section>
  );
}
