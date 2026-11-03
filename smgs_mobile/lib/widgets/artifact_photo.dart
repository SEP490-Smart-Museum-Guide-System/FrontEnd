import 'package:flutter/material.dart';
import '../models/artifact.dart';

class ArtifactPhoto extends StatelessWidget {
  const ArtifactPhoto({
    super.key,
    required this.artifact,
    required this.height,
  });
  final Artifact artifact;
  final double height;
  Widget get placeholder => SizedBox(
    height: height,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 36),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final url = artifact.imageUrl;
    if (url.isEmpty) return placeholder;
    if (Uri.tryParse(url)?.hasScheme == true) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: artifact.name,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image.asset(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: artifact.name,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
