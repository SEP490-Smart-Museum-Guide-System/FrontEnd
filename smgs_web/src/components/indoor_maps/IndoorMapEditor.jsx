import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { useApp } from '../../context/AppContext';
import {
  getMyMuseumsApi,
  getIndoorStructureApi,
  updateIndoorStructureApi,
  createBuildingApi,
  createFloorApi,
  getIndoorMapsApi,
  createIndoorMapApi,
  getIndoorMapDraftApi,
  getIndoorMapLinksApi,
  updateIndoorMapDraftApi,
  uploadIndoorMapImageApi,
  fetchIndoorMapImageBlob,
  previewRouteApi,
  publishIndoorMapApi,
  unpublishIndoorMapApi,
  fetchArtifactQrBlob
} from '../../services/indoorMapApi';
import {
  Map as MapIcon,
  Layers,
  Move,
  Plus,
  Link2,
  Trash2,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Eye,
  Save,
  Upload,
  Share2,
  RotateCcw,
  CheckCircle,
  AlertCircle,
  AlertTriangle,
  ArrowRightLeft,
  QrCode,
  Navigation,
  Building,
  Check,
  X,
  Footprints,
  Maximize,
  Compass
} from 'lucide-react';

const NODE_TYPES = [
  { value: 'corridor', label: 'Hành lang' },
  { value: 'intersection', label: 'Ngã rẽ' },
  { value: 'door', label: 'Cửa' },
  { value: 'entrance', label: 'Lối vào sơ đồ' },
  { value: 'stair', label: 'Cầu thang bộ' },
  { value: 'elevator', label: 'Thang máy' }
];

const MARKER_TYPES = [
  { value: 'artifact', label: 'Hiện vật di sản' },
  { value: 'gallery', label: 'Phòng trưng bày' },
  { value: 'entrance', label: 'Cửa vào' },
  { value: 'exit', label: 'Cửa thoát hiểm' },
  { value: 'restroom', label: 'Nhà vệ sinh' },
  { value: 'information', label: 'Quầy thông tin' },
  { value: 'stair', label: 'Cầu thang' },
  { value: 'elevator', label: 'Thang máy' }
];

export default function IndoorMapEditor() {
  const { currentRole, currentMuseum } = useApp();

  // State: Museum & Indoor Structure
  const [museums, setMuseums] = useState([]);
  const [selectedMuseumId, setSelectedMuseumId] = useState(currentMuseum?.id || null);
  const [structure, setStructure] = useState(null); // { layout: 'unknown'|'single'|'floors', buildings: [] }
  const [mapsList, setMapsList] = useState([]);
  const [selectedMapId, setSelectedMapId] = useState(null);

  // State: Creation modals
  const [showNewMapModal, setShowNewMapModal] = useState(false);
  const [newMapName, setNewMapName] = useState('');
  const [newMapFloorId, setNewMapFloorId] = useState(null);
  const [newBuildingName, setNewBuildingName] = useState('');
  const [showBuildingModal, setShowBuildingModal] = useState(false);
  const [newFloorBuildingId, setNewFloorBuildingId] = useState(null);
  const [newFloorName, setNewFloorName] = useState('');
  const [newFloorLevel, setNewFloorLevel] = useState(1);
  const [showFloorModal, setShowFloorModal] = useState(false);

  // State: Current Map Draft
  const [draft, setDraft] = useState(null);
  const [imageUrl, setImageUrl] = useState(null);
  const [links, setLinks] = useState({ artifacts: [], galleries: [] });
  const [isDirty, setIsDirty] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [alertMsg, setAlertMsg] = useState(null); // { type: 'success'|'error'|'warning', text }

  // State: Tools & Selection
  // activeTool: 'select' | 'add_marker' | 'add_node' | 'add_edge' | 'add_stair' | 'add_elevator' | 'pan'
  const [activeTool, setActiveTool] = useState('select');
  const [selectedType, setSelectedType] = useState(null); // 'node' | 'marker' | 'edge'
  const [selectedId, setSelectedId] = useState(null);
  const [edgeSourceNodeId, setEdgeSourceNodeId] = useState(null);

  // State: Pan & Zoom Viewport
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const [panStart, setPanStart] = useState({ x: 0, y: 0 });

  // State: Dragging Node/Marker
  const [draggingObj, setDraggingObj] = useState(null); // { type, id, startX, startY, origX, origY, hasMoved }

  // State: Route preview
  const [routeFromNodeId, setRouteFromNodeId] = useState('');
  const [routeToNodeId, setRouteToNodeId] = useState('');
  const [routeAccessibleOnly, setRouteAccessibleOnly] = useState(false);
  const [previewRouteNodeIds, setPreviewRouteNodeIds] = useState([]);
  const [isPreviewingRoute, setIsPreviewingRoute] = useState(false);

  // State: Customer preview modal
  const [showVisitorPreview, setShowVisitorPreview] = useState(false);

  const containerRef = useRef(null);
  const svgRef = useRef(null);

  // 1. Initial Load: Get museums assigned to user
  useEffect(() => {
    getMyMuseumsApi()
      .then(res => {
        const list = res?.data || res || [];
        setMuseums(list);
        if (list.length > 0 && !selectedMuseumId) {
          setSelectedMuseumId(list[0].id);
        }
      })
      .catch(err => {
        setAlertMsg({ type: 'error', text: err.message });
      });
  }, []);

  // 2. When Museum changes, load its indoor structure and indoor maps list
  useEffect(() => {
    if (!selectedMuseumId) return;
    setAlertMsg(null);
    setDraft(null);
    setImageUrl(null);
    setSelectedMapId(null);
    setIsDirty(false);

    Promise.all([
      getIndoorStructureApi(selectedMuseumId),
      getIndoorMapsApi(selectedMuseumId)
    ])
      .then(([structRes, mapsRes]) => {
        setStructure(structRes?.data || structRes);
        const maps = mapsRes?.data || mapsRes || [];
        setMapsList(maps);
        if (maps.length > 0) {
          setSelectedMapId(maps[0].id);
        }
      })
      .catch(err => {
        setAlertMsg({ type: 'error', text: err.message });
      });
  }, [selectedMuseumId]);

  // 3. When Selected Map changes, load draft & links & image
  useEffect(() => {
    if (!selectedMapId) {
      setDraft(null);
      setImageUrl(null);
      return;
    }

    if (isDirty) {
      if (!window.confirm('Bạn có thay đổi chưa lưu trên sơ đồ hiện tại. Tiếp tục chuyển sơ đồ sẽ bỏ thay đổi này?')) {
        return;
      }
    }

    setAlertMsg(null);
    setIsDirty(false);
    setSelectedId(null);
    setSelectedType(null);
    setPreviewRouteNodeIds([]);
    setEdgeSourceNodeId(null);

    Promise.all([
      getIndoorMapDraftApi(selectedMapId),
      getIndoorMapLinksApi(selectedMapId)
    ])
      .then(async ([draftRes, linksRes]) => {
        const draftData = draftRes?.data || draftRes;
        setDraft(draftData);
        setLinks(linksRes?.data || linksRes || { artifacts: [], galleries: [] });

        if (draftData?.imageKey) {
          try {
            const blobUrl = await fetchIndoorMapImageBlob(selectedMapId, draftData.imageKey);
            setImageUrl(blobUrl);
          } catch (imgErr) {
            setAlertMsg({ type: 'warning', text: 'Chưa tải được ảnh sơ đồ: ' + imgErr.message });
          }
        } else {
          setImageUrl(null);
        }
      })
      .catch(err => {
        setAlertMsg({ type: 'error', text: err.message });
      });
  }, [selectedMapId]);

  // Window beforeunload check for unsaved changes
  useEffect(() => {
    const handleBeforeUnload = (e) => {
      if (isDirty) {
        e.preventDefault();
        e.returnValue = '';
      }
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [isDirty]);

  // Helper: Get node by ID
  const getNode = useCallback((id) => {
    return draft?.nodes?.find(n => n.id === id) || null;
  }, [draft]);

  // Helper: Get marker by ID
  const getMarker = useCallback((id) => {
    return draft?.markers?.find(m => m.id === id) || null;
  }, [draft]);

  // Helper: Get edge by ID
  const getEdge = useCallback((id) => {
    return draft?.edges?.find(e => e.id === id) || null;
  }, [draft]);

  // Convert SVG coordinates to Normalized [0, 1]
  const screenToNormalized = useCallback((clientX, clientY) => {
    if (!svgRef.current || !draft?.imageWidth || !draft?.imageHeight) return null;
    const rect = svgRef.current.getBoundingClientRect();
    const xOnSvg = (clientX - rect.left - pan.x) / zoom;
    const yOnSvg = (clientY - rect.top - pan.y) / zoom;

    const normX = Math.max(0, Math.min(1, xOnSvg / draft.imageWidth));
    const normY = Math.max(0, Math.min(1, yOnSvg / draft.imageHeight));
    return { x: Number(normX.toFixed(5)), y: Number(normY.toFixed(5)) };
  }, [zoom, pan, draft]);

  // Canvas Mouse Wheel: Zoom centered at cursor
  const handleWheel = (e) => {
    if (e.ctrlKey || e.metaKey || true) {
      e.preventDefault();
      const zoomFactor = e.deltaY < 0 ? 1.15 : 0.85;
      const newZoom = Math.max(0.3, Math.min(5, zoom * zoomFactor));

      if (svgRef.current) {
        const rect = svgRef.current.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

        // Zoom toward cursor
        const newPanX = mouseX - (mouseX - pan.x) * (newZoom / zoom);
        const newPanY = mouseY - (mouseY - pan.y) * (newZoom / zoom);

        setZoom(newZoom);
        setPan({ x: newPanX, y: newPanY });
      }
    }
  };

  // Canvas Mouse Down: Pan or Start Object Drag
  const handleMouseDown = (e) => {
    // Middle mouse button (button 1) or pan tool or empty space in select tool
    if (e.button === 1 || activeTool === 'pan' || (activeTool === 'select' && e.target === svgRef.current)) {
      e.preventDefault();
      setIsPanning(true);
      setPanStart({ x: e.clientX - pan.x, y: e.clientY - pan.y });
    }
  };

  const handleMouseMove = (e) => {
    if (isPanning) {
      setPan({ x: e.clientX - panStart.x, y: e.clientY - panStart.y });
      return;
    }

    if (draggingObj) {
      const deltaX = Math.abs(e.clientX - draggingObj.startX);
      const deltaY = Math.abs(e.clientY - draggingObj.startY);

      // Threshold ~4px to distinguish click vs drag
      if (!draggingObj.hasMoved && (deltaX > 4 || deltaY > 4)) {
        setDraggingObj(prev => ({ ...prev, hasMoved: true }));
      }

      const norm = screenToNormalized(e.clientX, e.clientY);
      if (norm) {
        if (draggingObj.type === 'node') {
          setDraft(prev => ({
            ...prev,
            nodes: prev.nodes.map(n => n.id === draggingObj.id ? { ...n, x: norm.x, y: norm.y } : n)
          }));
          setIsDirty(true);
        } else if (draggingObj.type === 'marker') {
          setDraft(prev => ({
            ...prev,
            markers: prev.markers.map(m => m.id === draggingObj.id ? { ...m, x: norm.x, y: norm.y } : m)
          }));
          setIsDirty(true);
        }
      }
    }
  };

  const handleMouseUp = () => {
    if (isPanning) {
      setIsPanning(false);
    }
    if (draggingObj) {
      setDraggingObj(null);
    }
  };

  // Canvas Click: Handle adding nodes, markers, connecting edges, or deselecting
  const handleSvgClick = (e) => {
    if (draggingObj?.hasMoved) return;

    // Clicked empty space
    if (e.target === svgRef.current) {
      const norm = screenToNormalized(e.clientX, e.clientY);
      if (!norm) return;

      if (activeTool === 'add_node' || activeTool === 'add_stair' || activeTool === 'add_elevator') {
        const type = activeTool === 'add_stair' ? 'stair' : activeTool === 'add_elevator' ? 'elevator' : 'corridor';
        const newNode = {
          id: crypto.randomUUID(),
          label: type === 'stair' ? 'Cầu thang' : type === 'elevator' ? 'Thang máy' : `Điểm ${draft.nodes.length + 1}`,
          type,
          x: norm.x,
          y: norm.y
        };
        setDraft(prev => ({ ...prev, nodes: [...prev.nodes, newNode] }));
        setIsDirty(true);
        setSelectedType('node');
        setSelectedId(newNode.id);
        setActiveTool('select'); // Auto exit add mode
      } else if (activeTool === 'add_marker') {
        const newMarker = {
          id: crypto.randomUUID(),
          label: `Vị trí ${draft.markers.length + 1}`,
          type: 'artifact',
          x: norm.x,
          y: norm.y,
          artifactId: null,
          galleryId: null,
          nodeId: null,
          isDestination: true,
          isActive: true
        };
        setDraft(prev => ({ ...prev, markers: [...prev.markers, newMarker] }));
        setIsDirty(true);
        setSelectedType('marker');
        setSelectedId(newMarker.id);
        setActiveTool('select'); // Auto exit add mode
      } else if (activeTool === 'select') {
        setSelectedType(null);
        setSelectedId(null);
        setEdgeSourceNodeId(null);
      }
    }
  };

  // Click on a Node
  const handleNodeClick = (node, e) => {
    e.stopPropagation();
    if (draggingObj?.hasMoved) return;

    if (activeTool === 'add_edge') {
      if (!edgeSourceNodeId) {
        setEdgeSourceNodeId(node.id);
      } else {
        if (edgeSourceNodeId === node.id) {
          alert('Không thể nối một điểm với chính nó.');
          return;
        }

        // Check if edge already exists
        const exists = draft.edges.some(
          edge => (edge.fromNodeId === edgeSourceNodeId && edge.toNodeId === node.id) ||
                  (edge.fromNodeId === node.id && edge.toNodeId === edgeSourceNodeId && edge.bidirectional)
        );
        if (exists) {
          alert('Đoạn nối giữa 2 điểm này đã tồn tại.');
          setEdgeSourceNodeId(null);
          return;
        }

        const newEdge = {
          id: crypto.randomUUID(),
          fromNodeId: edgeSourceNodeId,
          toNodeId: node.id,
          bidirectional: true,
          isAccessible: true
        };

        setDraft(prev => ({ ...prev, edges: [...prev.edges, newEdge] }));
        setIsDirty(true);
        setSelectedType('edge');
        setSelectedId(newEdge.id);
        setEdgeSourceNodeId(null);
        setActiveTool('select');
      }
    } else {
      setSelectedType('node');
      setSelectedId(node.id);
    }
  };

  // Click on a Marker
  const handleMarkerClick = (marker, e) => {
    e.stopPropagation();
    if (draggingObj?.hasMoved) return;
    setSelectedType('marker');
    setSelectedId(marker.id);
  };

  // Click on an Edge
  const handleEdgeClick = (edge, e) => {
    e.stopPropagation();
    setSelectedType('edge');
    setSelectedId(edge.id);
  };

  // Node Drag Start
  const handleNodeMouseDown = (node, e) => {
    if (e.button === 0) { // Left click
      e.stopPropagation();
      setDraggingObj({
        type: 'node',
        id: node.id,
        startX: e.clientX,
        startY: e.clientY,
        origX: node.x,
        origY: node.y,
        hasMoved: false
      });
    }
  };

  // Marker Drag Start
  const handleMarkerMouseDown = (marker, e) => {
    if (e.button === 0) {
      e.stopPropagation();
      setDraggingObj({
        type: 'marker',
        id: marker.id,
        startX: e.clientX,
        startY: e.clientY,
        origX: marker.x,
        origY: marker.y,
        hasMoved: false
      });
    }
  };

  // Delete Object (Node, Marker, or Edge)
  const handleDeleteSelected = () => {
    if (!selectedId || !selectedType) return;

    if (selectedType === 'node') {
      if (!window.confirm('Xóa điểm dẫn đường này sẽ xóa các đoạn nối liên quan và bỏ liên kết ở các điểm đánh dấu. Tiếp tục?')) {
        return;
      }
      setDraft(prev => ({
        ...prev,
        nodes: prev.nodes.filter(n => n.id !== selectedId),
        edges: prev.edges.filter(e => e.fromNodeId !== selectedId && e.toNodeId !== selectedId),
        markers: prev.markers.map(m => m.nodeId === selectedId ? { ...m, nodeId: null } : m)
      }));
    } else if (selectedType === 'marker') {
      setDraft(prev => ({
        ...prev,
        markers: prev.markers.filter(m => m.id !== selectedId)
      }));
    } else if (selectedType === 'edge') {
      setDraft(prev => ({
        ...prev,
        edges: prev.edges.filter(e => e.id !== selectedId)
      }));
    }

    setSelectedId(null);
    setSelectedType(null);
    setIsDirty(true);
  };

  // Keyboard Shortcuts: Esc exits tool, Delete/Backspace deletes selected object
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT' || e.target.tagName === 'TEXTAREA') {
        return;
      }
      if (e.key === 'Escape') {
        setActiveTool('select');
        setEdgeSourceNodeId(null);
      } else if (e.key === 'Delete' || e.key === 'Backspace') {
        handleDeleteSelected();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedId, selectedType]);

  // Save Draft API
  const handleSaveDraft = async () => {
    if (!draft || isSaving) return;
    setIsSaving(true);
    setAlertMsg(null);
    try {
      const res = await updateIndoorMapDraftApi(draft.id, {
        revision: draft.revision,
        nodes: draft.nodes,
        markers: draft.markers,
        edges: draft.edges
      });
      const updated = res?.data || res;
      setDraft(prev => ({ ...prev, revision: updated.revision || prev.revision + 1, warnings: updated.warnings || [] }));
      setIsDirty(false);
      setAlertMsg({ type: 'success', text: `Lưu bản nháp thành công! (Phiên bản ${updated.revision || draft.revision + 1})` });
    } catch (err) {
      setAlertMsg({ type: 'error', text: err.message });
    } finally {
      setIsSaving(false);
    }
  };

  // Reload Draft API
  const handleReloadDraft = async () => {
    if (isDirty) {
      if (!window.confirm('Bản vẽ có thay đổi chưa lưu. Tải lại sẽ khôi phục về trạng thái máy chủ đã lưu gần nhất?')) {
        return;
      }
    }
    setAlertMsg(null);
    try {
      const res = await getIndoorMapDraftApi(draft.id);
      const data = res?.data || res;
      setDraft(data);
      setIsDirty(false);
      setSelectedId(null);
      setSelectedType(null);
      setPreviewRouteNodeIds([]);
      setAlertMsg({ type: 'success', text: 'Đã tải lại bản nháp từ máy chủ.' });
    } catch (err) {
      setAlertMsg({ type: 'error', text: err.message });
    }
  };

  // Upload Map Image API
  const handleImageUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file || !draft) return;
    if (file.size > 10 * 1024 * 1024) {
      alert('Kích thước ảnh tối đa là 10 MB.');
      return;
    }

    const confirmChange = draft.imageKey ? window.confirm('Thay đổi ảnh sơ đồ có thể ảnh hưởng đến tỷ lệ và vị trí các điểm đã đặt. Bạn có chắc chắn muốn thay?') : true;
    if (!confirmChange) return;

    setAlertMsg(null);
    try {
      const res = await uploadIndoorMapImageApi(draft.id, file, draft.revision, true);
      const updated = res?.data || res;
      setDraft(prev => ({
        ...prev,
        revision: updated.revision || prev.revision,
        imageKey: updated.imageKey,
        imageWidth: updated.imageWidth,
        imageHeight: updated.imageHeight
      }));
      const blobUrl = await fetchIndoorMapImageBlob(draft.id, updated.imageKey);
      setImageUrl(blobUrl);
      setAlertMsg({ type: 'success', text: 'Tải lên ảnh sơ đồ thành công!' });
    } catch (err) {
      setAlertMsg({ type: 'error', text: err.message });
    } finally {
      e.target.value = '';
    }
  };

  // Publish Map API
  const handlePublish = async () => {
    if (!draft || isPublishing) return;
    if (isDirty) {
      alert('Vui lòng bấm "Lưu bản nháp" trước khi xuất bản.');
      return;
    }
    if (!window.confirm(`Xuất bản sơ đồ "${draft.name}" (phiên bản ${draft.revision}) cho khách tham quan?`)) {
      return;
    }
    setIsPublishing(true);
    setAlertMsg(null);
    try {
      const res = await publishIndoorMapApi(draft.id, draft.revision);
      const updated = res?.data || res;
      setDraft(prev => ({ ...prev, publishedAt: new Date().toISOString(), warnings: updated.warnings || [] }));
      setAlertMsg({ type: 'success', text: 'Đã xuất bản sơ đồ thành công! Khách tham quan đã có thể xem và tìm đường.' });
      if (updated.warnings?.length > 0) {
        setAlertMsg({ type: 'warning', text: 'Cảnh báo khi xuất bản: ' + updated.warnings.join('; ') });
      }
    } catch (err) {
      setAlertMsg({ type: 'error', text: err.message });
    } finally {
      setIsPublishing(false);
    }
  };

  // Unpublish Map API
  const handleUnpublish = async () => {
    if (!draft || isPublishing) return;
    if (!window.confirm(`Ngừng xuất bản sơ đồ "${draft.name}"? Khách tham quan sẽ tạm thời không xem được sơ đồ này.`)) {
      return;
    }
    setIsPublishing(true);
    setAlertMsg(null);
    try {
      await unpublishIndoorMapApi(draft.id, draft.revision);
      setDraft(prev => ({ ...prev, publishedAt: null }));
      setAlertMsg({ type: 'success', text: 'Đã ngừng xuất bản sơ đồ.' });
    } catch (err) {
      setAlertMsg({ type: 'error', text: err.message });
    } finally {
      setIsPublishing(false);
    }
  };

  // Route Preview in Editor API
  const handlePreviewRoute = async () => {
    if (!draft || !routeFromNodeId || !routeToNodeId) {
      alert('Vui lòng chọn cả điểm bắt đầu và điểm kết thúc.');
      return;
    }
    if (routeFromNodeId === routeToNodeId) {
      alert('Điểm bắt đầu và kết thúc trùng nhau.');
      return;
    }
    if (isDirty) {
      alert('Vui lòng bấm "Lưu bản nháp" trước khi thử đường đi.');
      return;
    }

    setIsPreviewingRoute(true);
    setAlertMsg(null);
    try {
      const res = await previewRouteApi(draft.id, {
        revision: draft.revision,
        fromNodeId: routeFromNodeId,
        toNodeId: routeToNodeId,
        accessibleOnly: routeAccessibleOnly
      });
      const data = res?.data || res;
      const nodeIds = data?.nodeIds || [];
      setPreviewRouteNodeIds(nodeIds);
      if (nodeIds.length > 0) {
        setAlertMsg({ type: 'success', text: `Tìm thấy lộ trình gồm ${nodeIds.length} điểm dẫn đường.` });
      }
    } catch (err) {
      setPreviewRouteNodeIds([]);
      setAlertMsg({ type: 'error', text: err.message });
    } finally {
      setIsPreviewingRoute(false);
    }
  };

  // Fit to screen view
  const handleFitView = () => {
    if (!containerRef.current || !draft?.imageWidth || !draft?.imageHeight) return;
    const cWidth = containerRef.current.clientWidth - 40;
    const cHeight = containerRef.current.clientHeight - 40;
    const scale = Math.min(cWidth / draft.imageWidth, cHeight / draft.imageHeight, 1);
    setZoom(scale);
    setPan({
      x: (cWidth - draft.imageWidth * scale) / 2 + 20,
      y: (cHeight - draft.imageHeight * scale) / 2 + 20
    });
  };

  // Create Map Modal Submit
  const handleCreateMapSubmit = async (e) => {
    e.preventDefault();
    if (!newMapName.trim()) return;
    try {
      const res = await createIndoorMapApi(selectedMuseumId, {
        floorId: structure?.layout === 'floors' ? newMapFloorId : null,
        name: newMapName.trim()
      });
      const newMap = res?.data || res;
      setMapsList(prev => [...prev, newMap]);
      setSelectedMapId(newMap.id);
      setShowNewMapModal(false);
      setNewMapName('');
      setAlertMsg({ type: 'success', text: `Đã tạo sơ đồ "${newMap.name}" thành công!` });
    } catch (err) {
      alert(err.message);
    }
  };

  // Create Building Modal Submit
  const handleCreateBuilding = async (e) => {
    e.preventDefault();
    if (!newBuildingName.trim()) return;
    try {
      await createBuildingApi(selectedMuseumId, { name: newBuildingName.trim() });
      const structRes = await getIndoorStructureApi(selectedMuseumId);
      setStructure(structRes?.data || structRes);
      setShowBuildingModal(false);
      setNewBuildingName('');
    } catch (err) {
      alert(err.message);
    }
  };

  // Create Floor Modal Submit
  const handleCreateFloor = async (e) => {
    e.preventDefault();
    if (!newFloorName.trim() || !newFloorBuildingId) return;
    try {
      await createFloorApi(selectedMuseumId, {
        buildingId: newFloorBuildingId,
        levelNo: Number(newFloorLevel),
        name: newFloorName.trim()
      });
      const structRes = await getIndoorStructureApi(selectedMuseumId);
      setStructure(structRes?.data || structRes);
      setShowFloorModal(false);
      setNewFloorName('');
    } catch (err) {
      alert(err.message);
    }
  };

  // Update structure layout if unknown
  const handleSetLayout = async (layout) => {
    try {
      await updateIndoorStructureApi(selectedMuseumId, layout);
      const structRes = await getIndoorStructureApi(selectedMuseumId);
      setStructure(structRes?.data || structRes);
    } catch (err) {
      alert(err.message);
    }
  };

  // Download Artifact QR
  const handleDownloadQr = async (marker) => {
    if (!marker.artifactId) return;
    try {
      const qrUrl = await fetchArtifactQrBlob(draft.id, marker.id);
      const a = document.createElement('a');
      a.href = qrUrl;
      a.download = `QR-${marker.label}.png`;
      a.click();
    } catch (err) {
      alert(err.message);
    }
  };

  const selectedNode = selectedType === 'node' ? getNode(selectedId) : null;
  const selectedMarker = selectedType === 'marker' ? getMarker(selectedId) : null;
  const selectedEdge = selectedType === 'edge' ? getEdge(selectedId) : null;

  return (
    <div className="indoor-map-editor-page" style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 72px)', background: '#F8F5EE' }}>
      {/* 1. Header Bar */}
      <header style={{
        background: '#FFF',
        borderBottom: '1px solid var(--color-paper-border)',
        padding: '12px 20px',
        display: 'flex',
        flexWrap: 'wrap',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '12px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '8px',
            background: 'var(--color-burgundy-700)',
            color: '#FFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <MapIcon size={20} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h1 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--color-burgundy-900)' }}>
                Bản đồ trong bảo tàng
              </h1>
              {draft && (
                <span style={{
                  fontSize: '0.7rem',
                  padding: '2px 8px',
                  borderRadius: '12px',
                  fontWeight: 600,
                  background: draft.publishedAt ? '#DCFCE7' : '#FEF3C7',
                  color: draft.publishedAt ? '#166534' : '#92400E'
                }}>
                  {draft.publishedAt ? 'Đã xuất bản' : 'Bản nháp'}
                </span>
              )}
              {isDirty && (
                <span style={{ fontSize: '0.7rem', color: '#B91C1C', fontWeight: 600 }}>• Chưa lưu</span>
              )}
            </div>
            <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--color-charcoal-600)' }}>
              Biên tập mạng lưới lối đi, ghim hiện vật và xuất bản sơ đồ dẫn đường cho khách tham quan.
            </p>
          </div>
        </div>

        {/* Museum, Structure & Map Selectors */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
          {/* Museum Selector */}
          <select
            value={selectedMuseumId || ''}
            onChange={(e) => setSelectedMuseumId(Number(e.target.value))}
            className="form-control"
            style={{ fontSize: '0.8rem', padding: '6px 10px', height: '34px', minWidth: '180px' }}
          >
            {museums.map(m => (
              <option key={m.id} value={m.id}>{m.name}</option>
            ))}
          </select>

          {/* Map Selector */}
          {mapsList.length > 0 && (
            <select
              value={selectedMapId || ''}
              onChange={(e) => setSelectedMapId(e.target.value)}
              className="form-control"
              style={{ fontSize: '0.8rem', padding: '6px 10px', height: '34px', minWidth: '160px', fontWeight: 600 }}
            >
              {mapsList.map(m => (
                <option key={m.id} value={m.id}>{m.name} {m.floorName ? `(${m.floorName})` : ''}</option>
              ))}
            </select>
          )}

          <button
            type="button"
            onClick={() => setShowNewMapModal(true)}
            className="btn btn-secondary btn-sm"
            style={{ height: '34px', padding: '0 10px' }}
          >
            <Plus size={14} /> Thêm sơ đồ
          </button>
        </div>

        {/* Actions (Save, Upload, Publish) */}
        {draft && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <label
              className="btn btn-secondary btn-sm"
              style={{ height: '34px', padding: '0 10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
              title="Tải ảnh PNG/JPG tối đa 10 MB"
            >
              <Upload size={14} /> Tải ảnh sơ đồ
              <input type="file" accept="image/png,image/jpeg" style={{ display: 'none' }} onChange={handleImageUpload} />
            </label>

            <button
              type="button"
              onClick={handleSaveDraft}
              disabled={isSaving}
              className="btn btn-primary btn-sm"
              style={{ height: '34px', padding: '0 12px' }}
              title="Lưu bản nháp sơ đồ"
            >
              <Save size={14} /> {isSaving ? 'Đang lưu...' : 'Lưu bản nháp'}
            </button>

            <button
              type="button"
              onClick={handleReloadDraft}
              className="btn btn-secondary btn-sm"
              style={{ height: '34px', padding: '0 8px' }}
              title="Tải lại từ máy chủ"
            >
              <RotateCcw size={14} />
            </button>

            {draft.publishedAt ? (
              <button
                type="button"
                onClick={handleUnpublish}
                disabled={isPublishing}
                className="btn btn-secondary btn-sm"
                style={{ height: '34px', padding: '0 10px', color: '#991B1B' }}
                title="Ngừng cung cấp sơ đồ cho khách"
              >
                Ngừng xuất bản
              </button>
            ) : (
              <button
                type="button"
                onClick={handlePublish}
                disabled={isPublishing || isDirty}
                className="btn btn-gold btn-sm"
                style={{ height: '34px', padding: '0 12px' }}
                title="Xuất bản sơ đồ cho khách tham quan"
              >
                <Share2 size={14} /> {isPublishing ? 'Đang xuất bản...' : 'Xuất bản'}
              </button>
            )}

            <button
              type="button"
              onClick={() => setShowVisitorPreview(true)}
              className="btn btn-secondary btn-sm"
              style={{ height: '34px', padding: '0 10px' }}
              title="Xem thử giao diện phía khách"
            >
              <Eye size={14} /> Xem thử
            </button>
          </div>
        )}
      </header>

      {/* Alert banner if any */}
      {alertMsg && (
        <div style={{
          padding: '8px 20px',
          fontSize: '0.8rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          background: alertMsg.type === 'error' ? '#FEF2F2' : alertMsg.type === 'warning' ? '#FFFBEB' : '#F0FDF4',
          color: alertMsg.type === 'error' ? '#991B1B' : alertMsg.type === 'warning' ? '#92400E' : '#166534',
          borderBottom: '1px solid rgba(0,0,0,0.06)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {alertMsg.type === 'error' ? <AlertCircle size={15} /> : alertMsg.type === 'warning' ? <AlertTriangle size={15} /> : <CheckCircle size={15} />}
            <span>{alertMsg.text}</span>
          </div>
          <button type="button" onClick={() => setAlertMsg(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'inherit' }}>
            <X size={14} />
          </button>
        </div>
      )}

      {/* Structure resolution prompt if layout is 'unknown' */}
      {structure?.layout === 'unknown' && (
        <div style={{ padding: '16px 20px', background: '#FFFDF9', borderBottom: '1px solid #EADCC8', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px' }}>
          <div>
            <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>Bảo tàng này chưa xác định cấu trúc mặt bằng:</strong>
            <p style={{ margin: '4px 0 0', fontSize: '0.8rem', color: 'var(--color-charcoal-700)' }}>
              Vui lòng chọn kiểu bố cục thực tế trước khi tạo sơ đồ. Lựa chọn này không thể tự ý thay đổi khi đã có sơ đồ phụ thuộc.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" onClick={() => handleSetLayout('single')} className="btn btn-secondary btn-sm">
              Mặt bằng chung (1 sơ đồ)
            </button>
            <button type="button" onClick={() => handleSetLayout('floors')} className="btn btn-primary btn-sm">
              Theo tòa nhà & tầng thực tế
            </button>
          </div>
        </div>
      )}

      {/* Main Workspace (Toolbar + Canvas + Properties) */}
      <div style={{ display: 'flex', flex: 1, minHeight: 0, overflow: 'hidden' }}>
        {/* Left / Center Area: Toolbar + Map Canvas + Bottom Route Preview */}
        <div style={{ display: 'flex', flexDirection: 'column', flex: 1, minWidth: 0, position: 'relative' }}>
          {/* Toolbar */}
          <div style={{
            background: '#FFF',
            borderBottom: '1px solid var(--color-paper-border)',
            padding: '6px 14px',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            flexWrap: 'wrap',
            zIndex: 10
          }}>
            {[
              { id: 'select', label: 'Chọn / Di chuyển', icon: Compass },
              { id: 'add_marker', label: '+ Điểm đánh dấu (Hiện vật)', icon: MapIcon },
              { id: 'add_node', label: '+ Điểm dẫn đường', icon: Footprints },
              { id: 'add_edge', label: 'Nối điểm', icon: Link2 },
              { id: 'add_stair', label: '+ Cầu thang', icon: Layers },
              { id: 'add_elevator', label: '+ Thang máy', icon: Building },
              { id: 'pan', label: 'Kéo sơ đồ', icon: Move }
            ].map(tool => {
              const Icon = tool.icon;
              const isActive = activeTool === tool.id;
              return (
                <button
                  key={tool.id}
                  type="button"
                  onClick={() => {
                    setActiveTool(tool.id);
                    setEdgeSourceNodeId(null);
                  }}
                  className={`btn btn-sm ${isActive ? 'btn-primary' : 'btn-secondary'}`}
                  style={{
                    padding: '4px 10px',
                    fontSize: '0.75rem',
                    height: '30px',
                    borderRadius: '6px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '5px'
                  }}
                  title={tool.label}
                >
                  <Icon size={14} />
                  <span>{tool.label}</span>
                </button>
              );
            })}

            <div style={{ width: '1px', height: '20px', background: '#E2E8F0', margin: '0 4px' }} />

            {/* Zoom Controls */}
            <button type="button" onClick={() => setZoom(z => Math.min(5, z * 1.2))} className="btn btn-secondary btn-sm" style={{ padding: '4px 8px', height: '30px' }} title="Phóng to">
              <ZoomIn size={14} />
            </button>
            <button type="button" onClick={() => setZoom(z => Math.max(0.3, z / 1.2))} className="btn btn-secondary btn-sm" style={{ padding: '4px 8px', height: '30px' }} title="Thu nhỏ">
              <ZoomOut size={14} />
            </button>
            <button type="button" onClick={handleFitView} className="btn btn-secondary btn-sm" style={{ padding: '4px 8px', height: '30px' }} title="Vừa khung">
              <Maximize2 size={14} />
            </button>
            <span style={{ fontSize: '0.725rem', color: 'var(--color-charcoal-500)', minWidth: '45px', textAlign: 'center' }}>
              {Math.round(zoom * 100)}%
            </span>

            {/* Delete Selected Item */}
            {selectedId && (
              <>
                <div style={{ width: '1px', height: '20px', background: '#E2E8F0', margin: '0 4px' }} />
                <button
                  type="button"
                  onClick={handleDeleteSelected}
                  className="btn btn-sm"
                  style={{ height: '30px', padding: '4px 10px', background: '#FEE2E2', color: '#991B1B', border: '1px solid #FCA5A5' }}
                  title="Xóa đối tượng đang chọn (Phím Delete)"
                >
                  <Trash2 size={14} /> Xóa {selectedType === 'node' ? 'Điểm' : selectedType === 'marker' ? 'Hiện vật' : 'Đoạn nối'}
                </button>
              </>
            )}

            {/* Edge creation prompt */}
            {activeTool === 'add_edge' && (
              <span style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)', fontWeight: 600, marginLeft: '8px' }}>
                {edgeSourceNodeId ? '👉 Nhấp điểm thứ 2 để hoàn thành đoạn nối' : '👉 Nhấp điểm dẫn đường thứ nhất'}
              </span>
            )}
          </div>

          {/* Canvas Viewport */}
          <div
            ref={containerRef}
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onWheel={handleWheel}
            style={{
              flex: 1,
              minHeight: 0,
              background: '#232830',
              overflow: 'hidden',
              position: 'relative',
              cursor: activeTool === 'pan' || isPanning ? 'grab' : activeTool.startsWith('add') ? 'crosshair' : 'default',
              userSelect: 'none'
            }}
          >
            {imageUrl ? (
              <svg
                ref={svgRef}
                onClick={handleSvgClick}
                width={draft?.imageWidth || 1200}
                height={draft?.imageHeight || 800}
                style={{
                  transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                  transformOrigin: '0 0',
                  boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
                  background: '#FFF'
                }}
              >
                {/* Background Floor Plan Image */}
                <image
                  href={imageUrl}
                  x={0}
                  y={0}
                  width={draft.imageWidth}
                  height={draft.imageHeight}
                  style={{ pointerEvents: 'none' }}
                />

                {/* Edges Layer */}
                {draft.edges.map(edge => {
                  const fromNode = getNode(edge.fromNodeId);
                  const toNode = getNode(edge.toNodeId);
                  if (!fromNode || !toNode) return null;

                  const x1 = fromNode.x * draft.imageWidth;
                  const y1 = fromNode.y * draft.imageHeight;
                  const x2 = toNode.x * draft.imageWidth;
                  const y2 = toNode.y * draft.imageHeight;

                  const isSelected = selectedType === 'edge' && selectedId === edge.id;
                  const isRoute = previewRouteNodeIds.length > 1 &&
                    previewRouteNodeIds.some((id, idx) =>
                      idx < previewRouteNodeIds.length - 1 &&
                      ((previewRouteNodeIds[idx] === edge.fromNodeId && previewRouteNodeIds[idx + 1] === edge.toNodeId) ||
                       (edge.bidirectional && previewRouteNodeIds[idx] === edge.toNodeId && previewRouteNodeIds[idx + 1] === edge.fromNodeId))
                    );

                  return (
                    <g key={edge.id} onClick={(e) => handleEdgeClick(edge, e)} style={{ cursor: 'pointer' }}>
                      {/* Wide invisible stroke for easy clicking */}
                      <line x1={x1} y1={y1} x2={x2} y2={y2} stroke="transparent" strokeWidth={18 / zoom} />
                      {/* Visible edge line */}
                      <line
                        x1={x1}
                        y1={y1}
                        x2={x2}
                        y2={y2}
                        stroke={isRoute ? '#227C64' : isSelected ? '#C5A059' : '#800020'}
                        strokeWidth={isRoute ? 6 / zoom : isSelected ? 4 / zoom : 2.5 / zoom}
                        strokeDasharray={edge.isAccessible ? 'none' : '4,4'}
                        opacity={isRoute ? 1 : 0.8}
                      />
                    </g>
                  );
                })}

                {/* Nodes Layer (Điểm dẫn đường) */}
                {draft.nodes.map(node => {
                  const cx = node.x * draft.imageWidth;
                  const cy = node.y * draft.imageHeight;
                  const isSelected = selectedType === 'node' && selectedId === node.id;
                  const isEdgeSource = edgeSourceNodeId === node.id;
                  const isRouteNode = previewRouteNodeIds.includes(node.id);

                  return (
                    <g
                      key={node.id}
                      onClick={(e) => handleNodeClick(node, e)}
                      onMouseDown={(e) => handleNodeMouseDown(node, e)}
                      style={{ cursor: 'move' }}
                    >
                      <circle
                        cx={cx}
                        cy={cy}
                        r={isSelected ? 10 / zoom : 7 / zoom}
                        fill={isEdgeSource ? '#F59E0B' : isRouteNode ? '#227C64' : isSelected ? '#C5A059' : '#800020'}
                        stroke="#FFF"
                        strokeWidth={2 / zoom}
                      />
                      {zoom > 0.8 && (
                        <text
                          x={cx}
                          y={cy - 10 / zoom}
                          textAnchor="middle"
                          fontSize={11 / zoom}
                          fontWeight="600"
                          fill="#1E232B"
                          stroke="#FFF"
                          strokeWidth={3 / zoom}
                          paintOrder="stroke"
                        >
                          {node.label}
                        </text>
                      )}
                    </g>
                  );
                })}

                {/* Markers Layer (Hiện vật, phòng, tiện ích) */}
                {draft.markers.map(marker => {
                  const mx = marker.x * draft.imageWidth;
                  const my = marker.y * draft.imageHeight;
                  const isSelected = selectedType === 'marker' && selectedId === marker.id;

                  return (
                    <g
                      key={marker.id}
                      onClick={(e) => handleMarkerClick(marker, e)}
                      onMouseDown={(e) => handleMarkerMouseDown(marker, e)}
                      style={{ cursor: 'move' }}
                    >
                      {/* Connection line to linked node if present */}
                      {marker.nodeId && (() => {
                        const targetNode = getNode(marker.nodeId);
                        if (!targetNode) return null;
                        return (
                          <line
                            x1={mx}
                            y1={my}
                            x2={targetNode.x * draft.imageWidth}
                            y2={targetNode.y * draft.imageHeight}
                            stroke="#C5A059"
                            strokeWidth={1.5 / zoom}
                            strokeDasharray="3,3"
                            opacity={0.7}
                          />
                        );
                      })()}

                      {/* Marker Pin */}
                      <circle
                        cx={mx}
                        cy={my}
                        r={isSelected ? 12 / zoom : 9 / zoom}
                        fill={marker.type === 'artifact' ? '#873C32' : '#2563EB'}
                        stroke="#FFF"
                        strokeWidth={2.5 / zoom}
                      />
                      <circle cx={mx} cy={my} r={3 / zoom} fill="#FFF" />

                      {/* Marker Label */}
                      <text
                        x={mx}
                        y={my + 16 / zoom}
                        textAnchor="middle"
                        fontSize={11 / zoom}
                        fontWeight="700"
                        fill={marker.type === 'artifact' ? '#800020' : '#1E40AF'}
                        stroke="#FFF"
                        strokeWidth={3 / zoom}
                        paintOrder="stroke"
                      >
                        {marker.label}
                      </text>
                    </g>
                  );
                })}
              </svg>
            ) : (
              <div style={{
                position: 'absolute',
                inset: 0,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#94A3B8',
                gap: '12px'
              }}>
                <MapIcon size={48} strokeWidth={1.2} />
                <p style={{ margin: 0, fontSize: '0.9rem' }}>Sơ đồ này chưa có ảnh mặt bằng.</p>
                <label className="btn btn-gold btn-sm" style={{ cursor: 'pointer' }}>
                  <Upload size={14} /> Tải ảnh sơ đồ (PNG/JPG)
                  <input type="file" accept="image/png,image/jpeg" style={{ display: 'none' }} onChange={handleImageUpload} />
                </label>
              </div>
            )}
          </div>

          {/* Bottom Route Preview Bar */}
          {draft && (
            <div style={{
              background: '#FFF',
              borderTop: '1px solid var(--color-paper-border)',
              padding: '10px 18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              flexWrap: 'wrap',
              zIndex: 10
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Navigation size={16} color="var(--color-burgundy-700)" />
                <strong style={{ fontSize: '0.8rem', color: 'var(--color-charcoal-900)' }}>Thử đường đi:</strong>
              </div>

              <select
                value={routeFromNodeId}
                onChange={(e) => setRouteFromNodeId(e.target.value)}
                className="form-control"
                style={{ fontSize: '0.78rem', height: '32px', minWidth: '150px' }}
              >
                <option value="">-- Điểm bắt đầu --</option>
                {draft.nodes.map(n => (
                  <option key={n.id} value={n.id}>{n.label} ({NODE_TYPES.find(t => t.value === n.type)?.label || n.type})</option>
                ))}
              </select>

              <span style={{ fontSize: '0.8rem', color: '#94A3B8' }}>➔</span>

              <select
                value={routeToNodeId}
                onChange={(e) => setRouteToNodeId(e.target.value)}
                className="form-control"
                style={{ fontSize: '0.78rem', height: '32px', minWidth: '150px' }}
              >
                <option value="">-- Điểm kết thúc --</option>
                {draft.nodes.map(n => (
                  <option key={n.id} value={n.id}>{n.label} ({NODE_TYPES.find(t => t.value === n.type)?.label || n.type})</option>
                ))}
              </select>

              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.78rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={routeAccessibleOnly}
                  onChange={(e) => setRouteAccessibleOnly(e.target.checked)}
                />
                <span>Phù hợp xe lăn</span>
              </label>

              <button
                type="button"
                onClick={handlePreviewRoute}
                disabled={isPreviewingRoute || !routeFromNodeId || !routeToNodeId}
                className="btn btn-primary btn-sm"
                style={{ height: '32px', padding: '0 12px' }}
              >
                {isPreviewingRoute ? 'Đang tính...' : 'Xem thử tuyến'}
              </button>

              {previewRouteNodeIds.length > 0 && (
                <button
                  type="button"
                  onClick={() => setPreviewRouteNodeIds([])}
                  className="btn btn-secondary btn-sm"
                  style={{ height: '32px', padding: '0 8px' }}
                  title="Xóa tuyến đang xem"
                >
                  <X size={14} /> Xóa tuyến
                </button>
              )}
            </div>
          )}
        </div>

        {/* Right Area: Properties Panel (280px) */}
        <aside style={{
          width: '280px',
          background: '#FFF',
          borderLeft: '1px solid var(--color-paper-border)',
          display: 'flex',
          flexDirection: 'column',
          minHeight: 0,
          overflowY: 'auto',
          padding: '16px'
        }}>
          <h3 style={{ fontSize: '0.9rem', fontWeight: 700, margin: '0 0 12px', color: 'var(--color-burgundy-900)' }}>
            Thuộc tính đối tượng
          </h3>

          {selectedNode ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div className="badge" style={{ alignSelf: 'flex-start', background: '#F1F5F9', color: '#475569', fontSize: '0.7rem' }}>
                Điểm dẫn đường (Node)
              </div>

              <div>
                <label className="form-label" style={{ fontSize: '0.75rem' }}>Tên hiển thị:</label>
                <input
                  type="text"
                  value={selectedNode.label}
                  onChange={(e) => {
                    const val = e.target.value;
                    setDraft(prev => ({
                      ...prev,
                      nodes: prev.nodes.map(n => n.id === selectedNode.id ? { ...n, label: val } : n)
                    }));
                    setIsDirty(true);
                  }}
                  className="form-control"
                  style={{ fontSize: '0.8rem', height: '32px' }}
                />
              </div>

              <div>
                <label className="form-label" style={{ fontSize: '0.75rem' }}>Loại điểm:</label>
                <select
                  value={selectedNode.type}
                  onChange={(e) => {
                    const val = e.target.value;
                    setDraft(prev => ({
                      ...prev,
                      nodes: prev.nodes.map(n => n.id === selectedNode.id ? { ...n, type: val } : n)
                    }));
                    setIsDirty(true);
                  }}
                  className="form-control"
                  style={{ fontSize: '0.8rem', height: '32px' }}
                >
                  {NODE_TYPES.map(t => (
                    <option key={t.value} value={t.value}>{t.label}</option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', fontSize: '0.75rem', color: '#64748B' }}>
                <div>Tọa độ X: <strong>{selectedNode.x}</strong></div>
                <div>Tọa độ Y: <strong>{selectedNode.y}</strong></div>
              </div>
            </div>
          ) : selectedMarker ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div className="badge" style={{ alignSelf: 'flex-start', background: '#FEF3C7', color: '#92400E', fontSize: '0.7rem' }}>
                Điểm đánh dấu (Marker)
              </div>

              <div>
                <label className="form-label" style={{ fontSize: '0.75rem' }}>Tên địa điểm:</label>
                <input
                  type="text"
                  value={selectedMarker.label}
                  onChange={(e) => {
                    const val = e.target.value;
                    setDraft(prev => ({
                      ...prev,
                      markers: prev.markers.map(m => m.id === selectedMarker.id ? { ...m, label: val } : m)
                    }));
                    setIsDirty(true);
                  }}
                  className="form-control"
                  style={{ fontSize: '0.8rem', height: '32px' }}
                />
              </div>

              <div>
                <label className="form-label" style={{ fontSize: '0.75rem' }}>Loại điểm:</label>
                <select
                  value={selectedMarker.type}
                  onChange={(e) => {
                    const val = e.target.value;
                    setDraft(prev => ({
                      ...prev,
                      markers: prev.markers.map(m => m.id === selectedMarker.id ? {
                        ...m,
                        type: val,
                        artifactId: val === 'artifact' ? m.artifactId : null,
                        galleryId: val === 'gallery' ? m.galleryId : null
                      } : m)
                    }));
                    setIsDirty(true);
                  }}
                  className="form-control"
                  style={{ fontSize: '0.8rem', height: '32px' }}
                >
                  {MARKER_TYPES.map(t => (
                    <option key={t.value} value={t.value}>{t.label}</option>
                  ))}
                </select>
              </div>

              {/* Linked Artifact Dropdown */}
              {selectedMarker.type === 'artifact' && (
                <div>
                  <label className="form-label" style={{ fontSize: '0.75rem' }}>Hiện vật liên kết (DB):</label>
                  <select
                    value={selectedMarker.artifactId || ''}
                    onChange={(e) => {
                      const val = e.target.value ? Number(e.target.value) : null;
                      const art = links.artifacts.find(a => a.id === val);
                      setDraft(prev => ({
                        ...prev,
                        markers: prev.markers.map(m => m.id === selectedMarker.id ? {
                          ...m,
                          artifactId: val,
                          label: art ? art.name : m.label
                        } : m)
                      }));
                      setIsDirty(true);
                    }}
                    className="form-control"
                    style={{ fontSize: '0.8rem', height: '32px' }}
                  >
                    <option value="">-- Chưa gán hiện vật --</option>
                    {links.artifacts.map(a => (
                      <option key={a.id} value={a.id}>{a.name}</option>
                    ))}
                  </select>
                </div>
              )}

              {/* Linked Gallery Dropdown */}
              {selectedMarker.type === 'gallery' && (
                <div>
                  <label className="form-label" style={{ fontSize: '0.75rem' }}>Phòng trưng bày liên kết:</label>
                  <select
                    value={selectedMarker.galleryId || ''}
                    onChange={(e) => {
                      const val = e.target.value ? Number(e.target.value) : null;
                      const gal = links.galleries.find(g => g.id === val);
                      setDraft(prev => ({
                        ...prev,
                        markers: prev.markers.map(m => m.id === selectedMarker.id ? {
                          ...m,
                          galleryId: val,
                          label: gal ? gal.name : m.label
                        } : m)
                      }));
                      setIsDirty(true);
                    }}
                    className="form-control"
                    style={{ fontSize: '0.8rem', height: '32px' }}
                  >
                    <option value="">-- Chưa gán phòng --</option>
                    {links.galleries.map(g => (
                      <option key={g.id} value={g.id}>{g.name}</option>
                    ))}
                  </select>
                </div>
              )}

              {/* Linked Navigation Node Dropdown */}
              <div>
                <label className="form-label" style={{ fontSize: '0.75rem' }}>Điểm dẫn đường liên kết:</label>
                <select
                  value={selectedMarker.nodeId || ''}
                  onChange={(e) => {
                    const val = e.target.value || null;
                    setDraft(prev => ({
                      ...prev,
                      markers: prev.markers.map(m => m.id === selectedMarker.id ? { ...m, nodeId: val } : m)
                    }));
                    setIsDirty(true);
                  }}
                  className="form-control"
                  style={{ fontSize: '0.8rem', height: '32px' }}
                >
                  <option value="">-- Chưa liên kết lối đi --</option>
                  {draft.nodes.map(n => (
                    <option key={n.id} value={n.id}>{n.label} ({NODE_TYPES.find(t => t.value === n.type)?.label || n.type})</option>
                  ))}
                </select>
                {!selectedMarker.nodeId && (
                  <p style={{ margin: '4px 0 0', fontSize: '0.7rem', color: '#B91C1C' }}>
                    * Bắt buộc liên kết với một điểm lối đi để dẫn đường.
                  </p>
                )}
              </div>

              {/* Checkboxes */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '0.78rem' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={selectedMarker.isDestination}
                    onChange={(e) => {
                      const val = e.target.checked;
                      setDraft(prev => ({
                        ...prev,
                        markers: prev.markers.map(m => m.id === selectedMarker.id ? { ...m, isDestination: val } : m)
                      }));
                      setIsDirty(true);
                    }}
                  />
                  <span>Là điểm đến có thể dẫn đường</span>
                </label>

                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={selectedMarker.isActive}
                    onChange={(e) => {
                      const val = e.target.checked;
                      setDraft(prev => ({
                        ...prev,
                        markers: prev.markers.map(m => m.id === selectedMarker.id ? { ...m, isActive: val } : m)
                      }));
                      setIsDirty(true);
                    }}
                  />
                  <span>Đang hoạt động trên sơ đồ</span>
                </label>
              </div>

              {/* Download QR button if artifact linked */}
              {selectedMarker.artifactId && selectedMarker.isActive && (
                <button
                  type="button"
                  onClick={() => handleDownloadQr(selectedMarker)}
                  className="btn btn-secondary btn-sm"
                  style={{ marginTop: '6px', fontSize: '0.75rem' }}
                >
                  <QrCode size={13} /> Tải mã QR hiện vật
                </button>
              )}
            </div>
          ) : selectedEdge ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div className="badge" style={{ alignSelf: 'flex-start', background: '#F1F5F9', color: '#475569', fontSize: '0.7rem' }}>
                Đoạn nối (Edge)
              </div>

              <div style={{ fontSize: '0.78rem', color: '#475569' }}>
                <div>Từ: <strong>{getNode(selectedEdge.fromNodeId)?.label || 'Điểm 1'}</strong></div>
                <div>Đến: <strong>{getNode(selectedEdge.toNodeId)?.label || 'Điểm 2'}</strong></div>
              </div>

              <button
                type="button"
                onClick={() => {
                  setDraft(prev => ({
                    ...prev,
                    edges: prev.edges.map(e => e.id === selectedEdge.id ? {
                      ...e,
                      fromNodeId: e.toNodeId,
                      toNodeId: e.fromNodeId
                    } : e)
                  }));
                  setIsDirty(true);
                }}
                className="btn btn-secondary btn-sm"
                style={{ fontSize: '0.75rem' }}
              >
                <ArrowRightLeft size={13} /> Đảo chiều di chuyển
              </button>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '0.78rem' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={selectedEdge.bidirectional}
                    onChange={(e) => {
                      const val = e.target.checked;
                      setDraft(prev => ({
                        ...prev,
                        edges: prev.edges.map(e => e.id === selectedEdge.id ? { ...e, bidirectional: val } : e)
                      }));
                      setIsDirty(true);
                    }}
                  />
                  <span>Đi được hai chiều</span>
                </label>

                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={selectedEdge.isAccessible}
                    onChange={(e) => {
                      const val = e.target.checked;
                      setDraft(prev => ({
                        ...prev,
                        edges: prev.edges.map(e => e.id === selectedEdge.id ? { ...e, isAccessible: val } : e)
                      }));
                      setIsDirty(true);
                    }}
                  />
                  <span>Phù hợp người đi xe lăn</span>
                </label>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', color: '#94A3B8', padding: '30px 10px', fontSize: '0.8rem' }}>
              <p>Chưa chọn đối tượng nào.</p>
              <p style={{ fontSize: '0.725rem' }}>
                Nhấp vào một điểm dẫn đường, điểm hiện vật hoặc đoạn nối trên sơ đồ để chỉnh sửa thuộc tính.
              </p>
            </div>
          )}

          {/* Map summary stats at bottom of panel */}
          {draft && (
            <div style={{ marginTop: 'auto', paddingTop: '16px', borderTop: '1px solid #E2E8F0', fontSize: '0.725rem', color: '#64748B' }}>
              <div>• {draft.nodes.length} điểm dẫn đường</div>
              <div>• {draft.markers.length} điểm đánh dấu</div>
              <div>• {draft.edges.length} đoạn đường nối</div>
              <div style={{ marginTop: '4px' }}>Phiên bản: <strong>r{draft.revision}</strong></div>
            </div>
          )}
        </aside>
      </div>

      {/* Modal: Create Map */}
      {showNewMapModal && (
        <div className="modal-overlay" onClick={() => setShowNewMapModal(false)}>
          <div className="modal-dialog" style={{ maxWidth: '420px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '1rem' }}>Tạo sơ đồ bản đồ mới</h3>
              <button type="button" onClick={() => setShowNewMapModal(false)} className="btn btn-secondary btn-sm"><X size={14} /></button>
            </div>
            <form onSubmit={handleCreateMapSubmit} className="modal-body">
              <div style={{ marginBottom: '14px' }}>
                <label className="form-label">Tên sơ đồ:</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Tầng 1 - Phòng Cổ vật"
                  value={newMapName}
                  onChange={(e) => setNewMapName(e.target.value)}
                  className="form-control"
                  required
                />
              </div>

              {structure?.layout === 'floors' && (
                <div style={{ marginBottom: '14px' }}>
                  <label className="form-label">Chọn tầng thực tế:</label>
                  <select
                    value={newMapFloorId || ''}
                    onChange={(e) => setNewMapFloorId(Number(e.target.value))}
                    className="form-control"
                    required
                  >
                    <option value="">-- Chọn tầng --</option>
                    {structure?.buildings?.flatMap(b => b.floors || []).map(f => (
                      <option key={f.id} value={f.id}>{f.name} (Tầng {f.levelNo})</option>
                    ))}
                  </select>
                  <div style={{ display: 'flex', gap: '8px', marginTop: '6px' }}>
                    <button type="button" onClick={() => setShowBuildingModal(true)} className="btn btn-secondary btn-sm" style={{ fontSize: '0.72rem' }}>
                      + Thêm tòa nhà
                    </button>
                    <button type="button" onClick={() => setShowFloorModal(true)} className="btn btn-secondary btn-sm" style={{ fontSize: '0.72rem' }}>
                      + Thêm tầng
                    </button>
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '20px' }}>
                <button type="button" onClick={() => setShowNewMapModal(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">Tạo sơ đồ</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Add Building */}
      {showBuildingModal && (
        <div className="modal-overlay" onClick={() => setShowBuildingModal(false)}>
          <div className="modal-dialog" style={{ maxWidth: '360px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '0.95rem' }}>Thêm tòa nhà thực tế</h3>
              <button type="button" onClick={() => setShowBuildingModal(false)} className="btn btn-secondary btn-sm"><X size={14} /></button>
            </div>
            <form onSubmit={handleCreateBuilding} className="modal-body">
              <div style={{ marginBottom: '14px' }}>
                <label className="form-label">Tên tòa nhà:</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Nhà Trưng bày Chính"
                  value={newBuildingName}
                  onChange={(e) => setNewBuildingName(e.target.value)}
                  className="form-control"
                  required
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                <button type="button" onClick={() => setShowBuildingModal(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">Lưu tòa nhà</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Add Floor */}
      {showFloorModal && (
        <div className="modal-overlay" onClick={() => setShowFloorModal(false)}>
          <div className="modal-dialog" style={{ maxWidth: '360px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '0.95rem' }}>Thêm tầng thực tế</h3>
              <button type="button" onClick={() => setShowFloorModal(false)} className="btn btn-secondary btn-sm"><X size={14} /></button>
            </div>
            <form onSubmit={handleCreateFloor} className="modal-body">
              <div style={{ marginBottom: '12px' }}>
                <label className="form-label">Tòa nhà:</label>
                <select
                  value={newFloorBuildingId || ''}
                  onChange={(e) => setNewFloorBuildingId(Number(e.target.value))}
                  className="form-control"
                  required
                >
                  <option value="">-- Chọn tòa nhà --</option>
                  {structure?.buildings?.map(b => (
                    <option key={b.id} value={b.id}>{b.name}</option>
                  ))}
                </select>
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label className="form-label">Số thứ tự tầng (Level No):</label>
                <input
                  type="number"
                  value={newFloorLevel}
                  onChange={(e) => setNewFloorLevel(Number(e.target.value))}
                  className="form-control"
                  required
                />
              </div>
              <div style={{ marginBottom: '14px' }}>
                <label className="form-label">Tên tầng:</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Tầng 1"
                  value={newFloorName}
                  onChange={(e) => setNewFloorName(e.target.value)}
                  className="form-control"
                  required
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                <button type="button" onClick={() => setShowFloorModal(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">Lưu tầng</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Visitor Preview (Read-only Draft View) */}
      {showVisitorPreview && draft && (
        <div className="modal-overlay" onClick={() => setShowVisitorPreview(false)}>
          <div className="modal-dialog" style={{ maxWidth: '900px', width: '90vw', height: '80vh', display: 'flex', flexDirection: 'column' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <h3 style={{ margin: 0, fontSize: '1rem', color: 'var(--color-burgundy-900)' }}>
                  Xem thử phía khách tham quan · {draft.name}
                </h3>
                <span style={{ fontSize: '0.72rem', color: '#64748B' }}>Chế độ chỉ đọc từ bản nháp đã lưu</span>
              </div>
              <button type="button" onClick={() => setShowVisitorPreview(false)} className="btn btn-secondary btn-sm"><X size={14} /></button>
            </div>
            <div className="modal-body" style={{ flex: 1, minHeight: 0, background: '#F8F5EE', position: 'relative', overflow: 'hidden' }}>
              {imageUrl ? (
                <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <img
                    src={imageUrl}
                    alt={draft.name}
                    style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }}
                  />
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '60px', color: '#94A3B8' }}>Chưa có ảnh sơ đồ.</div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
