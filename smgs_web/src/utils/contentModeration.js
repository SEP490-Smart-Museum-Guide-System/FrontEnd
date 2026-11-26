const profanityTerms = [
  'dit',
  'dit me',
  'du ma',
  'deo',
  'cai lon',
  'cho lon',
  'con cac',
  'cai cac',
  'fuck',
  'fucking',
  'motherfucker',
  'shit',
  'bullshit',
  'bitch',
  'cunt',
  'asshole',
  'whore',
  'slut',
];

const hateTerms = [
  'nigger',
  'nigga',
  'chink',
  'gook',
  'spic',
  'kike',
  'wetback',
  'thang moi',
  'bon moi',
  'dan moi',
  'moi ro',
  'chung toc ha dang',
  'inferior race',
  'subhuman',
];

function normalizeForModeration(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/gi, 'd')
    .toLocaleLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function containsTerm(text, term) {
  const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const phrase = escaped.replace(/\s+/g, '\\s+');
  return new RegExp(`(?:^|\\s)${phrase}(?:$|\\s)`).test(text);
}

export function findContentWarnings(...values) {
  const text = normalizeForModeration(values.filter(Boolean).join(' '));
  if (!text) return [];

  const warnings = [];
  if (profanityTerms.some(term => containsTerm(text, term))) {
    warnings.push('Có thể chứa từ ngữ tục tĩu.');
  }
  if (hateTerms.some(term => containsTerm(text, term))) {
    warnings.push('Có thể chứa từ ngữ xúc phạm hoặc phân biệt chủng tộc.');
  }
  return warnings;
}

export const inappropriateContentWarning =
  'Hãy loại bỏ hoặc sửa nội dung này trước khi gửi duyệt. Bộ lọc phát hiện từ khóa nên có thể cần kiểm tra lại ngữ cảnh.';
