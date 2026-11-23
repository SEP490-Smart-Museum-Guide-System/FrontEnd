import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../screens/museum/visitor_directory_screen.dart';

class MuseumExploration extends ChangeNotifier {
  int? museumId;
  String? _owner;
  int _revision = 0;
  static final instance = MuseumExploration();

  Future<void> restore(String? owner) async {
    final revision = ++_revision;
    _owner = owner;
    museumId = null;
    notifyListeners();
    if (owner == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_revision != revision) return;
    final saved = prefs.getInt('museum-exploration:$owner');
    if (museumId == null && saved != null && saved > 0) {
      museumId = saved;
      notifyListeners();
    }
  }

  Future<void> select(int? id) async {
    final revision = ++_revision;
    museumId = id;
    notifyListeners();
    final owner = _owner;
    if (owner == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_revision != revision) return;
    if (id == null) {
      await prefs.remove('museum-exploration:$owner');
    } else {
      await prefs.setInt('museum-exploration:$owner', id);
    }
  }
}

class ExplorationNavigator extends NavigatorObserver with ChangeNotifier {
  Route<dynamic>? current;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    current = topRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  bool get available =>
      current is PageRoute &&
      !const {
        'VisitorDirectoryScreen',
        'VisitorIndoorMapScreen',
        'AuthScreen',
      }.contains(current?.settings.name);
}

class ExplorationMapButton extends StatefulWidget {
  const ExplorationMapButton({super.key, required this.navigation});

  final ExplorationNavigator navigation;

  static void open(NavigatorState navigator, int museumId) {
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'VisitorDirectoryScreen'),
        builder: (_) => VisitorDirectoryScreen(museumId: museumId),
      ),
    );
  }

  @override
  State<ExplorationMapButton> createState() => _ExplorationMapButtonState();
}

class _ExplorationMapButtonState extends State<ExplorationMapButton> {
  Offset? _position;
  Offset _grabOffset = Offset.zero;
  bool _dragging = false;
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final exploration = MuseumExploration.instance;
    final navigation = widget.navigation;
    final padding = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: Listenable.merge([exploration, navigation]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final minX = padding.left + 8;
          final minY = padding.top + 8;
          final maxX = (size.width - padding.right - _size - 8).clamp(
            minX,
            double.infinity,
          );
          final maxY = (size.height - padding.bottom - _size - 8).clamp(
            minY,
            double.infinity,
          );
          Offset clamp(Offset offset) => Offset(
            offset.dx.clamp(minX, maxX).toDouble(),
            offset.dy.clamp(minY, maxY).toDouble(),
          );
          final scanner = const {
            'ArtifactQrScanner',
            'QRScanScreen',
          }.contains(navigation.current?.settings.name);
          final position = clamp(
            _position ?? Offset(maxX - 4, scanner ? minY + 52 : maxY - 94),
          );
          final target = Offset(
            size.width / 2,
            size.height - padding.bottom - 42,
          );
          final overTarget =
              (position + const Offset(_size / 2, _size / 2) - target)
                  .distance <=
              44;
          final id = exploration.museumId;
          final visible = id != null && navigation.available;
          return Stack(
            children: [
              if (_dragging && visible)
                Positioned(
                  key: const ValueKey('map-dismiss-target'),
                  left: target.dx - 32,
                  top: target.dy - 32,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: overTarget
                            ? AppColors.deepBurgundy
                            : Colors.black87,
                      ),
                      child: const SizedBox.square(
                        dimension: 64,
                        child: Icon(Icons.close, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
              Positioned(
                key: const ValueKey('floating-map-button'),
                left: position.dx,
                top: position.dy,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: visible
                        ? GestureDetector(
                            onPanDown: (event) {
                              final box =
                                  context.findRenderObject()! as RenderBox;
                              _grabOffset =
                                  box.globalToLocal(event.globalPosition) -
                                  position;
                            },
                            onPanStart: (_) => setState(() {
                              _dragging = true;
                              _position = position;
                            }),
                            onPanUpdate: (event) => setState(() {
                              final box =
                                  context.findRenderObject()! as RenderBox;
                              _position = clamp(
                                box.globalToLocal(event.globalPosition) -
                                    _grabOffset,
                              );
                            }),
                            onPanCancel: () =>
                                setState(() => _dragging = false),
                            onPanEnd: (_) {
                              final center =
                                  (_position ?? position) +
                                  const Offset(_size / 2, _size / 2);
                              final dismiss = (center - target).distance <= 44;
                              setState(() {
                                _dragging = false;
                                if (dismiss) _position = null;
                              });
                              if (dismiss) exploration.select(null);
                            },
                            child: Material(
                              elevation: 3,
                              color: AppColors.deepBurgundy,
                              borderRadius: BorderRadius.circular(16),
                              child: IconButton(
                                constraints: const BoxConstraints.tightFor(
                                  width: _size,
                                  height: _size,
                                ),
                                color: Colors.white,
                                icon: const Icon(
                                  Icons.map_outlined,
                                  semanticLabel: 'Sơ đồ bảo tàng đang khám phá',
                                ),
                                onPressed: () => ExplorationMapButton.open(
                                  navigation.navigator!,
                                  id,
                                ),
                                onLongPress: () async {
                                  final end = await showDialog<bool>(
                                    context: navigation.navigator!.context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Kết thúc khám phá?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Tiếp tục'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Kết thúc khám phá',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (end == true && exploration.museumId == id)
                                    await exploration.select(null);
                                },
                              ),
                            ),
                          )
                        : const SizedBox.square(dimension: _size),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
