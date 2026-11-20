import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/automatic_location_service.dart';
import '../screens/museum/museum_detail_screen.dart';

class AutomaticArrivalCard extends StatelessWidget {
  const AutomaticArrivalCard({super.key, this.service});
  final AutomaticLocationService? service;
  @override
  Widget build(BuildContext context) {
    final location = service ?? AutomaticLocationService.instance;
    return ListenableBuilder(
      listenable: location,
      builder: (context, _) {
        if (location.status == AutomaticLocationStatus.idle ||
            location.status == AutomaticLocationStatus.paused) {
          return const SizedBox.shrink();
        }
        final museum = location.arrivedMuseum ?? location.nearbyMuseum;
        final blocked =
            location.status == AutomaticLocationStatus.denied ||
            location.status == AutomaticLocationStatus.deniedForever;
        final disabled = location.status == AutomaticLocationStatus.disabled;
        final message = blocked
            ? 'Cho phép vị trí trong Cài đặt để tự nhận biết bảo tàng.'
            : disabled
            ? 'Bật GPS để app tự nhận biết bảo tàng khi bạn đến.'
            : location.error ??
                  (location.arrivedMuseum != null
                      ? 'Đã đến khu vực ${museum!.name} (GPS).'
                      : museum != null
                      ? 'Đang ở gần ${museum.name}. Đang kiểm tra vị trí…'
                      : location.hasFreshLocation
                      ? 'Tự động cập nhật vị trí khi bạn đến bảo tàng.'
                      : 'Đang tự xác định vị trí của bạn…');
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: ListTile(
              leading: Icon(
                blocked || disabled
                    ? Icons.location_off_outlined
                    : Icons.my_location,
              ),
              title: Text(message),
              subtitle: location.arrivedMuseum == null
                  ? null
                  : const Text(
                      'Vị trí GPS ước tính; phòng/tầng được xác định qua QR.',
                    ),
              trailing: blocked || disabled || museum != null
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: blocked
                  ? () async {
                      await Geolocator.openAppSettings();
                    }
                  : disabled
                  ? () async {
                      await Geolocator.openLocationSettings();
                    }
                  : museum == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MuseumDetailScreen(museum: museum),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
