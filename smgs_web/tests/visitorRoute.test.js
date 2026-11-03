import test from 'node:test';
import assert from 'node:assert/strict';
import { visitorRoute } from '../src/components/indoor_maps/visitorRoute.js';
// Minimal graph fixture lives only in the test bundle.
const visitorDemo = {
  imageWidth: 100, imageHeight: 100,
  nodes: [{ id: 'entry', x: 0, y: 0 }, { id: 'center', x: .5, y: .5 }, { id: 'left', x: 0, y: 1 }],
  edges: [{ fromNodeId: 'entry', toNodeId: 'center', bidirectional: true, isAccessible: true }, { fromNodeId: 'center', toNodeId: 'left', bidirectional: true, isAccessible: true }],
};
test('visitor routes respect direction, accessibility, shared destinations and missing nodes', () => {
  assert.deepEqual(visitorRoute(visitorDemo, 'entry', 'left', true).map(n => n.id), ['entry','center','left']);
  assert.deepEqual(visitorRoute(visitorDemo, 'left', 'left', false).map(n => n.id), ['left']);
  assert.equal(visitorRoute(visitorDemo, 'missing', 'left', false), null);
  const oneWay = {...visitorDemo, edges: visitorDemo.edges.map(e => ({...e,bidirectional:false,isAccessible:false}))};
  assert.equal(visitorRoute(oneWay, 'left', 'entry', false), null);
  assert.equal(visitorRoute(oneWay, 'entry', 'left', true), null);
  assert.equal(visitorRoute(oneWay, 'entry', 'left', false).length, 3);
});
