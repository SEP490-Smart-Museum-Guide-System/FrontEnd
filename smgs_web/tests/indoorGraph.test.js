import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizePoint, removeObject, hasOverlappingEdge, zoomAt } from '../src/components/indoor_maps/indoorGraph.js';

test('normalized positions preserve image aspect ratio and stay inside the plan', () => {
  assert.deepEqual(normalizePoint(500, 125, 1000, 500), { x: .5, y: .25 });
  assert.deepEqual(normalizePoint(-10, 700, 1000, 500), { x: 0, y: 1 });
});
test('deleting a node removes edges and clears marker links without deleting the marker', () => {
  const draft = { nodes: [{ id: 'a' }, { id: 'b' }], markers: [{ id: 'qr', nodeId: 'a' }], edges: [{ id: 'e', fromNodeId: 'a', toNodeId: 'b' }] };
  const next = removeObject(draft, 'nodes', 'a');
  assert.deepEqual(next.nodes, [{ id: 'b' }]); assert.equal(next.edges.length, 0); assert.equal(next.markers[0].nodeId, null);
  assert.equal(draft.nodes.length, 2); assert.equal(draft.markers[0].nodeId, 'a');
});
test('duplicate edges account for direction', () => {
  const edges = [{ fromNodeId: 'a', toNodeId: 'b', bidirectional: false }];
  assert.equal(hasOverlappingEdge(edges, 'b', 'a', true), true);
  assert.equal(hasOverlappingEdge(edges, 'b', 'a', false), false);
  assert.equal(hasOverlappingEdge(edges, 'a', 'b', false), true);
});

test('zoom keeps the cursor anchor fixed after panning and clamps scale without drifting', () => {
  const view = { x: 120, y: -80, scale: 2 };
  const anchor = { x: 430, y: 250 };
  const next = zoomAt(view, 1.25, anchor);
  assert.equal((anchor.x - view.x) * view.scale, (anchor.x - next.x) * next.scale);
  assert.equal((anchor.y - view.y) * view.scale, (anchor.y - next.y) * next.scale);
  assert.deepEqual(zoomAt(next, 0.8, anchor), view);
  const max = zoomAt(view, 1000, anchor);
  assert.equal(max.scale, 8);
  assert.deepEqual(zoomAt(max, 2, anchor), max);
  const min = zoomAt(view, .001, anchor);
  assert.equal(min.scale, .5);
  assert.deepEqual(zoomAt(min, .5, anchor), min);
});
