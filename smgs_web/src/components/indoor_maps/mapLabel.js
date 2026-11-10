export function mapLabel(map, floor, building) {
  if (!floor) return `Mặt bằng chung — ${map.name}`;
  const buildingName = building?.name || floor.buildingName || 'Chưa đặt tên';
  const floorName = floor.name || `Tầng ${floor.levelNo}`;
  const scope = `Tòa nhà: ${buildingName} · Tầng: ${floorName}`;
  const generatedName = `${buildingName} / ${floorName}`;
  return map.name?.trim() === generatedName ? scope : `${scope} · Sơ đồ: ${map.name}`;
}
