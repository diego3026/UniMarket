import 'package:url_launcher/url_launcher.dart';

/// Abre Google Maps (app o web) con la ruta hasta el punto.
Future<bool> openDirections(double latitude, double longitude) {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
