import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';

class PickedMapLocation {
  final double latitude;
  final double longitude;
  final String mapUrl;
  final String addressLabel;

  const PickedMapLocation({
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
    required this.addressLabel,
  });
}

class MapLocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const MapLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  static const double _minLat = 12.0;
  static const double _maxLat = 19.5;
  static const double _minLng = 42.0;
  static const double _maxLng = 54.8;

  late double _latitude;
  late double _longitude;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _latitude = _clamp(widget.initialLatitude ?? 15.3694, _minLat, _maxLat);
    _longitude = _clamp(widget.initialLongitude ?? 44.1910, _minLng, _maxLng);
    _latController = TextEditingController(text: _latitude.toStringAsFixed(7));
    _lngController = TextEditingController(text: _longitude.toStringAsFixed(7));
    _addressController =
        TextEditingController(text: (widget.initialAddress ?? '').trim());
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double _clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  String get _mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=${_latitude.toStringAsFixed(7)},${_longitude.toStringAsFixed(7)}';

  String get _addressLabel {
    final typed = _addressController.text.trim();
    if (typed.isNotEmpty) return typed;
    return '${context.tr('auth.map.selected_location')} (${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)})';
  }

  void _syncControllers() {
    _latController.text = _latitude.toStringAsFixed(7);
    _lngController.text = _longitude.toStringAsFixed(7);
  }

  void _setFromTap(Offset localPosition, Size size) {
    final dx = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final dy = (localPosition.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _longitude = _minLng + ((_maxLng - _minLng) * dx);
      _latitude = _maxLat - ((_maxLat - _minLat) * dy);
      _syncControllers();
    });
  }

  void _applyManualCoordinates() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null ||
        lng == null ||
        lat < _minLat ||
        lat > _maxLat ||
        lng < _minLng ||
        lng > _maxLng) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('auth.map.location_outside_yemen'))));
      return;
    }
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _syncControllers();
    });
  }

  void _confirm() {
    Navigator.of(context).pop(PickedMapLocation(
      latitude: _latitude,
      longitude: _longitude,
      mapUrl: _mapUrl,
      addressLabel: _addressLabel,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auth.map.pick_title')),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.headerGradient)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = constraints.maxHeight < 700
              ? constraints.maxHeight * 0.48
              : constraints.maxHeight * 0.58;
          return Column(
            children: [
              SizedBox(
                height: mapHeight.clamp(260.0, 520.0),
                width: double.infinity,
                child: _OfflineYemenMap(
                  latitude: _latitude,
                  longitude: _longitude,
                  minLat: _minLat,
                  maxLat: _maxLat,
                  minLng: _minLng,
                  maxLng: _maxLng,
                  onTap: _setFromTap,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.tr('auth.map.instructions'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          SizedBox(
                            width: 220,
                            child: AppTextField(
                              controller: _latController,
                              label: context.tr('auth.latitude'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.\-]'))
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: AppTextField(
                              controller: _lngController,
                              label: context.tr('auth.longitude'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.\-]'))
                              ],
                            ),
                          ),
                          SizedBox(
                              width: 180,
                              child: AppButton(
                                  text: context.tr('common.save'),
                                  onPressed: _applyManualCoordinates)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _addressController,
                        label: context.tr('auth.address'),
                        hint: context.tr('auth.map.address_hint'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SelectableText(_mapUrl,
                          style: const TextStyle(color: AppColors.primary)),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                          text: context.tr('auth.map.confirm_location'),
                          onPressed: _confirm),
                    ],
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

class _OfflineYemenMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final void Function(Offset localPosition, Size size) onTap;

  const _OfflineYemenMap({
    required this.latitude,
    required this.longitude,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final x = ((longitude - minLng) / (maxLng - minLng)).clamp(0.0, 1.0);
    final y = ((maxLat - latitude) / (maxLat - minLat)).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: (details) => onTap(details.localPosition, size),
          onPanUpdate: (details) => onTap(details.localPosition, size),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F3F6), Color(0xFFF8EFE5)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(painter: _YemenMapPainter())),
                Positioned(
                  left: (size.width - (AppSpacing.lg * 2)) * x +
                      AppSpacing.lg -
                      24,
                  top: (size.height - (AppSpacing.lg * 2)) * y +
                      AppSpacing.lg -
                      48,
                  child: const Icon(Icons.location_on,
                      color: AppColors.error, size: 56),
                ),
                PositionedDirectional(
                  start: AppSpacing.lg,
                  top: AppSpacing.lg,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Text(context.tr('auth.map.offline_mode'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                PositionedDirectional(
                  end: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Text(
                        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YemenMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final dx = size.width * i / 6;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      final dy = size.height * i / 6;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final land = Paint()..color = const Color(0xFFDDE8CB);
    final border = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.36, size.height * 0.16,
          size.width * 0.58, size.height * 0.20)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.24,
          size.width * 0.84, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.57,
          size.width * 0.64, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.43, size.height * 0.83,
          size.width * 0.22, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.53,
          size.width * 0.18, size.height * 0.30)
      ..close();
    canvas.drawPath(path, land);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
