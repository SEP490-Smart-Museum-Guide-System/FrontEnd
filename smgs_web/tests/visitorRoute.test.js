import test from 'node:test';
import assert from 'node:assert/strict';
import { visitorRoute } from '../src/components/indoor_maps/visitorRoute.js';
import { visitorDemo } from '../src/components/indoor_maps/visitorDemo.js';
test('visitor routes respect direction, accessibility, shared destinations and missing nodes', () => {
  assert.deepEqual(visitorRoute(visitorDemo, 'entry', 'left', true).map(n => n.id), ['entry','center','left']);
  assert.deepEqual(visitorRoute(visitorDemo, 'left', 'left', false).map(n => n.id), ['left']);
  assert.equal(visitorRoute(visitorDemo, 'missing', 'left', false), null);
  const oneWay = {...visitorDemo, edges: visitorDemo.edges.map(e => ({...e,bidirectional:false,isAccessible:false}))};
  assert.equal(visitorRoute(oneWay, 'left', 'entry', false), null);
  assert.equal(visitorRoute(oneWay, 'entry', 'left', true), null);
  assert.equal(visitorRoute(oneWay, 'entry', 'left', false).length, 3);
});
