import * as THREE from 'three';
import { MTLLoader } from 'three/examples/jsm/loaders/MTLLoader.js';
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js';
import { GLTFExporter } from 'three/examples/jsm/exporters/GLTFExporter.js';

const normalizePath = value => decodeURIComponent(String(value || '').replaceAll('\\', '/').replace(/^\/+/, '').replace(/\/\.\//g, '/'));

function findBundleFile(files, wantedPath, root) {
  const target = normalizePath(wantedPath);
  const exact = files.find(file => {
    const path = normalizePath(file.webkitRelativePath || file.name);
    return path === target || path === `${root}/${target}`;
  });
  if (exact) return exact;
  const basename = target.split('/').pop();
  const matches = files.filter(file => file.name.toLowerCase() === basename.toLowerCase());
  return matches.length === 1 ? matches[0] : null;
}

function waitForTextures(manager, hasTextures) {
  if (!hasTextures) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Không tải xong texture OBJ. Kiểm tra file MTL và thư mục ảnh texture.')), 30000);
    manager.onLoad = () => { clearTimeout(timer); resolve(); };
  });
}

/** Convert an OBJ/MTL plus its texture files into a self-contained binary GLB. */
export async function convertObjBundleToGlb(inputFiles) {
  const files = Array.from(inputFiles || []);
  const objFiles = files.filter(file => /\.obj$/i.test(file.name));
  if (objFiles.length !== 1) throw new Error('Chọn đúng một file .obj, file .mtl tương ứng và các ảnh texture được model sử dụng. Có thể giữ Ctrl hoặc Shift để chọn nhiều file cùng lúc.');

  const objFile = objFiles[0];
  const objPath = normalizePath(objFile.webkitRelativePath || objFile.name);
  const root = objPath.includes('/') ? objPath.slice(0, objPath.lastIndexOf('/')) : '';
  const objText = await objFile.text();
  const materialName = objText.match(/^\s*mtllib\s+(.+)\s*$/im)?.[1]?.trim();
  const mtlFile = materialName
    ? findBundleFile(files, `${root ? `${root}/` : ''}${materialName}`, '') || findBundleFile(files, materialName, root)
    : files.find(file => /\.mtl$/i.test(file.name));
  if (!mtlFile) throw new Error('Không tìm thấy file .mtl mà OBJ tham chiếu. Hãy chọn OBJ cùng file MTL tương ứng.');

  const urls = new Map();
  const byPath = new Map();
  for (const file of files) {
    const path = normalizePath(file.webkitRelativePath || file.name);
    const relative = root && path.startsWith(`${root}/`) ? path.slice(root.length + 1) : path;
    const url = URL.createObjectURL(file);
    urls.set(url, url);
    byPath.set(path.toLowerCase(), url);
    byPath.set(relative.toLowerCase(), url);
    if (!byPath.has(file.name.toLowerCase())) byPath.set(file.name.toLowerCase(), url);
  }

  const textureErrors = [];
  const manager = new THREE.LoadingManager(undefined, undefined, url => textureErrors.push(url));
  manager.setURLModifier(url => {
    const clean = normalizePath(url.replace(/^bundle:\/\//, '').split(/[?#]/)[0]);
    const relative = root && clean.startsWith(`${root}/`) ? clean.slice(root.length + 1) : clean;
    return byPath.get(clean.toLowerCase()) || byPath.get(relative.toLowerCase()) || byPath.get(clean.split('/').pop().toLowerCase()) || url;
  });

  try {
    const mtlText = await mtlFile.text();
    const materials = new MTLLoader(manager).parse(mtlText, 'bundle://');
    const texturesReady = waitForTextures(manager, /^\s*(?:map_\w+|bump|norm|disp|decal)\s+/im.test(mtlText));
    materials.preload();
    await texturesReady;
    if (textureErrors.length) throw new Error(`Không tìm thấy ảnh texture: ${textureErrors[0]}`);

    const object = new OBJLoader(manager).setMaterials(materials).parse(objText);
    object.updateMatrixWorld(true);
    const exporter = new GLTFExporter();
    const result = await exporter.parseAsync(object, { binary: true, embedImages: true });
    const stem = objFile.name.replace(/\.obj$/i, '') || 'artifact-model';
    return new File([result], `${stem}.glb`, { type: 'model/gltf-binary' });
  } finally {
    urls.forEach(url => URL.revokeObjectURL(url));
  }
}
