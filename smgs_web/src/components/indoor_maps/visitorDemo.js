export const visitorDemo = {
  name: 'Không gian di sản Việt', imageWidth: 1000, imageHeight: 650,
  nodes: [
    { id: 'entry', label: 'Sảnh đón tiếp', x: .5, y: .86 },
    { id: 'center', label: 'Hành lang trung tâm', x: .5, y: .53 },
    { id: 'left', label: 'Khu cổ vật', x: .23, y: .53 },
    { id: 'right', label: 'Khu mỹ thuật', x: .77, y: .53 },
    { id: 'top', label: 'Khu gốm', x: .5, y: .22 },
  ],
  edges: [['entry','center'], ['center','left'], ['center','right'], ['center','top']].map(([fromNodeId,toNodeId]) => ({ fromNodeId,toNodeId,bidirectional:true,isAccessible:true })),
  markers: [
    { id:'a', label:'Trống đồng Đông Sơn', type:'artifact', nodeId:'left', x:.2,y:.35 },
    { id:'b', label:'Bình gốm hoa lam', type:'artifact', nodeId:'top', x:.5,y:.16 },
    { id:'c', label:'Tranh sơn mài', type:'artifact', nodeId:'right', x:.8,y:.35 },
    { id:'d', label:'Quầy thông tin', type:'information', nodeId:'entry', x:.62,y:.86 },
  ].map(m => ({...m,isActive:true,isDestination:true})),
};
