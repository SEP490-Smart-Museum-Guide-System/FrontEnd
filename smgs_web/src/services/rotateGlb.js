// Rotate the scene roots without decoding or changing geometry and textures.
export async function flipGlb(blob) {
  const bytes = new Uint8Array(await blob.arrayBuffer());
  const header = new DataView(bytes.buffer);
  if (bytes.length < 20 || header.getUint32(0, true) !== 0x46546c67 || header.getUint32(4, true) !== 2 || header.getUint32(8, true) !== bytes.length || header.getUint32(16, true) !== 0x4e4f534a) throw new Error('Chỉ hỗ trợ GLB 2 hợp lệ.');
  const oldLength = header.getUint32(12, true);
  const end = 20 + oldLength;
  if (end > bytes.length) throw new Error('GLB bị thiếu dữ liệu.');
  const document = JSON.parse(new TextDecoder().decode(bytes.subarray(20, end)).trim());
  if (!document.scenes?.length) throw new Error('GLB không có scene để xoay.');
  document.nodes ||= [];
  for (const scene of document.scenes) {
    if (!scene.nodes?.length) continue;
    const root = document.nodes.length;
    document.nodes.push({ name: 'Upright rotation', rotation: [1, 0, 0, 0], children: scene.nodes });
    scene.nodes = [root];
  }
  const json = new TextEncoder().encode(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const output = new Uint8Array(20 + length + bytes.length - end);
  output.set(bytes.subarray(0, 20));
  output.fill(32, 20, 20 + length);
  output.set(json, 20);
  output.set(bytes.subarray(end), 20 + length);
  const view = new DataView(output.buffer);
  view.setUint32(8, output.length, true);
  view.setUint32(12, length, true);
  return new File([output], 'model-upright.glb', { type: 'model/gltf-binary' });
}
