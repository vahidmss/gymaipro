import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ???? ?????? � ????? ?????? ???? + ?????? ????? ??? ???.
class ExerciseMuscleHeatmapWidget extends StatefulWidget {
  const ExerciseMuscleHeatmapWidget({
    required this.muscleTargets,
    this.compact = false,
    this.embedded = false,
    this.mapHeight,
    super.key,
  });

  final Map<String, int> muscleTargets;

  /// ???? ????? ???? ??????? � ???? ???? ? ???? ?????.
  final bool compact;

  /// ???? embedded � ???? ????? ? ???????? ???.
  final bool embedded;

  /// ?????? ???? ?? ???? compact (???????).
  final double? mapHeight;

  @override
  State<ExerciseMuscleHeatmapWidget> createState() =>
      _ExerciseMuscleHeatmapWidgetState();
}

class _ExerciseMuscleHeatmapWidgetState extends State<ExerciseMuscleHeatmapWidget> {
  late BodyView _view;
  String? _selectedKey;

  void _resetForTargets(Map<String, int> targets) {
    _view = MuscleTargets.preferredView(targets);
    _selectedKey = _defaultSelection(_view);
  }

  @override
  void initState() {
    super.initState();
    _resetForTargets(widget.muscleTargets);
  }

  @override
  void didUpdateWidget(ExerciseMuscleHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muscleTargets != widget.muscleTargets) {
      _resetForTargets(widget.muscleTargets);
    }
  }

  String? _defaultSelection(BodyView view) {
    for (final e in MuscleTargets.sortedEntries(widget.muscleTargets)) {
      final v = MuscleTargets.viewByKey[e.key];
      if (v == view || v == BodyView.both) return e.key;
    }
    return MuscleTargets.sortedEntries(widget.muscleTargets).isNotEmpty
        ? MuscleTargets.sortedEntries(widget.muscleTargets).first.key
        : null;
  }

  List<MapEntry<String, int>> _visibleEntries(BodyView view) {
    return MuscleTargets.sortedEntries(widget.muscleTargets).where((e) {
      final v = MuscleTargets.viewByKey[e.key];
      return v == view || v == BodyView.both;
    }).toList();
  }

  void _switchView(BodyView view) {
    setState(() {
      _view = view;
      final visible = _visibleEntries(view);
      if (_selectedKey == null ||
          !visible.any((e) => e.key == _selectedKey)) {
        _selectedKey = visible.isNotEmpty ? visible.first.key : null;
      }
    });
  }

  void _selectMuscle(String key) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _selectedKey = key);
  }

  @override
  Widget build(BuildContext context) {
    if (!MuscleTargets.hasData(widget.muscleTargets)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = _visibleEntries(_view);
    final selectedValue = _selectedKey != null
        ? (widget.muscleTargets[_selectedKey!] ?? 0)
        : 0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) _buildHeader(isDark),
        if (!widget.compact) SizedBox(height: 10.h),
        _buildViewToggle(isDark),
        SizedBox(height: widget.embedded ? 8.h : 10.h),
        _InteractiveBodyMap(
          targets: widget.muscleTargets,
          view: _view,
          selectedKey: _selectedKey,
          isDark: isDark,
          height: widget.mapHeight ?? (widget.compact ? 200.h : 300.h),
          onMuscleTap: _selectMuscle,
          onSuggestView: _switchView,
        ),
        if (!widget.compact) ...[
          SizedBox(height: 10.h),
          Text(
            '??? ????? ???? ??? ??? ???? ?????',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              color: isDark ? Colors.white38 : AppTheme.lightTextSecondary,
            ),
          ),
          if (visible.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _MuscleChips(
              entries: visible,
              selectedKey: _selectedKey,
              isDark: isDark,
              onSelect: _selectMuscle,
            ),
          ],
          if (_selectedKey != null && selectedValue > 0) ...[
            SizedBox(height: 12.h),
            _SelectedMuscleCard(
              muscleKey: _selectedKey!,
              value: selectedValue,
              isDark: isDark,
            ),
          ],
        ],
      ],
    );

    if (widget.embedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [const Color(0xFF161922), const Color(0xFF0E1016)]
                : [const Color(0xFFFFF8EC), const Color(0xFFFFEFD6)],
          ),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.45),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
            child: content,
          ),
        ),
      ).animate().fadeIn(duration: 260.ms),
    );
  }

  Widget _buildHeader(bool isDark) {
    final sorted = MuscleTargets.sortedEntries(widget.muscleTargets);
    final top = sorted.first;
    final heat = MuscleTargets.heatColor(top.value, isDark: isDark);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(LucideIcons.mousePointerClick, color: heat, size: 20.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '??? ????? ??????',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextColor,
                ),
              ),
              Text(
                '?????????? ????: ${MuscleTargets.label(top.key)}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          'GymAI',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: AppTheme.goldColor,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _viewTab('???? ???', BodyView.front, isDark),
          _viewTab('???? ???', BodyView.back, isDark),
        ],
      ),
    );
  }

  Widget _viewTab(String label, BodyView tabView, bool isDark) {
    final selected = _view == tabView;
    return Expanded(
      child: InkWell(
        onTap: () => _switchView(tabView),
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(4.w),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: selected ? AppTheme.goldColor : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppTheme.veryDarkBackground
                  : (isDark ? Colors.white60 : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveBodyMap extends StatelessWidget {
  const _InteractiveBodyMap({
    required this.targets,
    required this.view,
    required this.selectedKey,
    required this.isDark,
    required this.height,
    required this.onMuscleTap,
    required this.onSuggestView,
  });

  final Map<String, int> targets;
  final BodyView view;
  final String? selectedKey;
  final bool isDark;
  final double height;
  final ValueChanged<String> onMuscleTap;
  final ValueChanged<BodyView> onSuggestView;

  static const _minMapIntensity = 10;

  static const _frontAsset = 'images/gymai_body_front_premium.png';
  static const _backAsset = 'images/gymai_body_back_premium.png';

  BodyView? _suggestedView() {
    final current = _viewMuscleKeys(view);
    if (current.isNotEmpty) return null;

    final other = view == BodyView.front ? BodyView.back : BodyView.front;
    return _viewMuscleKeys(other).isNotEmpty ? other : null;
  }

  Iterable<String> _viewMuscleKeys(BodyView v) sync* {
    for (final e in targets.entries) {
      if (e.value < _minMapIntensity) continue;
      if (_belongsToView(e.key, v)) yield e.key;
    }
  }

  bool _showOnMap(String key, int value) {
    return value >= _minMapIntensity && _belongsToView(key, view);
  }

  bool _belongsToView(String key, BodyView v) {
    final side = MuscleTargets.viewByKey[key];
    return side == v || side == BodyView.both;
  }

  @override
  Widget build(BuildContext context) {
    final asset = view == BodyView.front ? _frontAsset : _backAsset;
    final hotspots = _MuscleHotspotLayout.forView(view);
    final frame = view == BodyView.front
        ? _BodyImageFrame.front
        : _BodyImageFrame.back;
    final suggestedView = _suggestedView();

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.22),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvas = Size(constraints.maxWidth, constraints.maxHeight);
              final layout = frame.layout(canvas);

              Offset spotCenter(_MuscleHotspot spot) {
                final ix = frame.viewport.left + spot.cx * frame.viewport.width;
                final iy = frame.viewport.top + spot.cy * frame.viewport.height;
                return Offset(
                  layout.imageRect.left + ix * layout.imageRect.width,
                  layout.imageRect.top + iy * layout.imageRect.height,
                );
              }

              double spotDiameter(_MuscleHotspot spot, int value) {
                final bodyW = frame.viewport.width * layout.imageRect.width;
                final bodyH = frame.viewport.height * layout.imageRect.height;
                final base = spot.radius * (bodyW + bodyH);
                // ????? ??????? ??????? ??? ?????????
                final t = (value.clamp(_minMapIntensity, 100) - _minMapIntensity) /
                    (100 - _minMapIntensity);
                return base * (0.62 + t * 0.38);
              }

              final sortedHotspots = [...hotspots]..sort((a, b) {
                  final va = targets[a.key] ?? 0;
                  final vb = targets[b.key] ?? 0;
                  return va.compareTo(vb);
                });

              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.05),
                        radius: 0.75,
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.09),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: layout.imageRect,
                    child: AppRemoteImage(
                      path: asset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                  ...sortedHotspots.map((spot) {
                    final value = targets[spot.key] ?? 0;
                    final selected = selectedKey == spot.key;
                    if (!_showOnMap(spot.key, value)) {
                      return const SizedBox.shrink();
                    }

                    final center = spotCenter(spot);
                    final diameter = spotDiameter(spot, value);
                    final w = diameter * spot.scaleX;
                    final h = diameter * spot.scaleY;

                    return Positioned(
                      left: center.dx - w / 2,
                      top: center.dy - h / 2,
                      width: w,
                      height: h,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onMuscleTap(spot.key),
                        child: _MuscleHeatOverlay(
                          intensity: value,
                          selected: selected,
                          isDark: isDark,
                        ),
                      ),
                    );
                  }),
                  if (suggestedView != null)
                    Positioned.fill(
                      child: Center(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            onTap: () => onSuggestView(suggestedView),
                            borderRadius: BorderRadius.circular(14.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.rotateCw,
                                    color: AppTheme.goldColor,
                                    size: 22.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    suggestedView == BodyView.back
                                        ? '??????? ????? ?? ???? ??? ???? ???'
                                        : '??????? ????? ?? ???? ??? ???? ???',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '???? ???? ???? ?? ???? ???? ?????',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 10.w,
                    bottom: 8.h,
                    child: Text(
                      'GymAI',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldColor.withValues(alpha: 0.35),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).animate(key: ValueKey(view)).fadeIn(duration: 260.ms);
  }
}

/// ???? ???? ??? ????  ???? ??? ????? ??????
class _MuscleHeatOverlay extends StatelessWidget {
  const _MuscleHeatOverlay({
    required this.intensity,
    required this.selected,
    required this.isDark,
  });

  final int intensity;
  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final heat = intensity > 0
        ? MuscleTargets.heatColor(intensity, isDark: isDark)
        : AppTheme.goldColor.withValues(alpha: 0.5);
    // ??? ????? = ???? ????????
    final strength = intensity.clamp(10, 100) / 100.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              heat.withValues(alpha: (selected ? 0.88 : 0.72) * strength),
              heat.withValues(alpha: (selected ? 0.35 : 0.24) * strength),
              heat.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: selected
              ? Border.all(color: AppTheme.goldColor, width: 2)
              : null,
        ),
      ),
    );
  }
}

class _MuscleChips extends StatelessWidget {
  const _MuscleChips({
    required this.entries,
    required this.selectedKey,
    required this.isDark,
    required this.onSelect,
  });

  final List<MapEntry<String, int>> entries;
  final String? selectedKey;
  final bool isDark;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: entries.map((e) {
        final selected = e.key == selectedKey;
        final color = MuscleTargets.heatColor(e.value, isDark: isDark);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(e.key),
            borderRadius: BorderRadius.circular(20.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.25)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.35),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${MuscleTargets.label(e.key)} ${e.value}%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectedMuscleCard extends StatelessWidget {
  const _SelectedMuscleCard({
    required this.muscleKey,
    required this.value,
    required this.isDark,
  });

  final String muscleKey;
  final int value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = MuscleTargets.heatColor(value, isDark: isDark);
    final label = MuscleTargets.intensityLabel(value);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, color: color, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  MuscleTargets.label(muscleKey),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.lightTextColor,
                  ),
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '????? ???????: $label',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.05, end: 0);
  }
}

/// ????? ??? ???? PNG ??????? (????????? ???? ??? ???)
enum _BodyImageFrame {
  front(
    imageAspect: 1536 / 1024,
    // bbox ????? ??? ?? PNG ??????? (???? ????? ????)
    viewport: Rect.fromLTWH(0.342, 0.027, 0.299, 0.972),
  ),
  back(
    imageAspect: 1536 / 1024,
    viewport: Rect.fromLTWH(0.365, 0.035, 0.265, 0.945),
  );

  const _BodyImageFrame({
    required this.imageAspect,
    required this.viewport,
  });

  final double imageAspect;
  final Rect viewport;

  /// ??? ??? ????? ??? ?? ?????? ??? ?? ???
  _BodyLayout layout(Size canvas) {
    final cx = viewport.left + viewport.width / 2;
    final cy = viewport.top + viewport.height / 2;

    final imgH = canvas.height / viewport.height;
    final imgW = imgH * imageAspect;

    final offsetX = canvas.width / 2 - cx * imgW;
    final offsetY = canvas.height / 2 - cy * imgH;

    return _BodyLayout(
      imageRect: Rect.fromLTWH(offsetX, offsetY, imgW, imgH),
    );
  }
}

class _BodyLayout {
  const _BodyLayout({required this.imageRect});
  final Rect imageRect;
}

/// ???? ? ???? ????  ???? ?? bbox ??? (??)
class _MuscleHotspot {
  const _MuscleHotspot(
    this.key,
    this.cx,
    this.cy,
    this.radius, {
    this.scaleX = 1,
    this.scaleY = 1,
  });

  final String key;
  final double cx;
  final double cy;
  final double radius;
  /// ???? ????? ????? ??? ?????? / ????
  final double scaleX;
  final double scaleY;
}

class _MuscleHotspotLayout {
  _MuscleHotspotLayout._();

  static List<_MuscleHotspot> forView(BodyView view) =>
      view == BodyView.front ? _front : _back;

  /// ?????? ??????? ??? PNG ???????  (cx, cy, radius) ???? bbox ???
  static const _front = <_MuscleHotspot>[
    _MuscleHotspot('chest_upper', 0.524, 0.19, 0.11),
    _MuscleHotspot('chest_middle', 0.524, 0.24, 0.12),
    _MuscleHotspot('chest_lower', 0.524, 0.29, 0.10),
    _MuscleHotspot('shoulder_anterior', 0.355, 0.15, 0.065),
    _MuscleHotspot('shoulder_anterior', 0.693, 0.15, 0.065),
    _MuscleHotspot('shoulder_lateral', 0.428, 0.13, 0.058),
    _MuscleHotspot('shoulder_lateral', 0.620, 0.13, 0.058),
    _MuscleHotspot('biceps', 0.200, 0.27, 0.075),
    _MuscleHotspot('biceps', 0.848, 0.27, 0.075),
    _MuscleHotspot('forearms', 0.090, 0.39, 0.065),
    _MuscleHotspot('forearms', 0.910, 0.39, 0.065),
    _MuscleHotspot('abs', 0.524, 0.35, 0.11),
    _MuscleHotspot('quads', 0.380, 0.57, 0.095),
    _MuscleHotspot('quads', 0.668, 0.57, 0.095),
    _MuscleHotspot('calf', 0.350, 0.74, 0.075),
    _MuscleHotspot('calf', 0.698, 0.74, 0.075),
  ];

  static const _back = <_MuscleHotspot>[
    // ??????  ???? ??? ????? ??? (??? ????? ????? ??????)
    _MuscleHotspot('back_trap', 0.519, 0.145, 0.105, scaleX: 1.65, scaleY: 0.88),
    _MuscleHotspot('shoulder_posterior', 0.444, 0.128, 0.050),
    _MuscleHotspot('shoulder_posterior', 0.562, 0.128, 0.050),
    _MuscleHotspot('back_lat', 0.180, 0.21, 0.11),
    _MuscleHotspot('back_lat', 0.820, 0.21, 0.11),
    _MuscleHotspot('triceps', 0.166, 0.241, 0.065),
    _MuscleHotspot('triceps', 0.834, 0.241, 0.065),
    _MuscleHotspot('forearms', 0.090, 0.39, 0.065),
    _MuscleHotspot('forearms', 0.910, 0.39, 0.065),
    _MuscleHotspot('lower_back', 0.500, 0.33, 0.10),
    _MuscleHotspot('glutes', 0.500, 0.41, 0.12),
    _MuscleHotspot('hamstrings', 0.380, 0.54, 0.095),
    _MuscleHotspot('hamstrings', 0.668, 0.54, 0.095),
    _MuscleHotspot('calf', 0.350, 0.72, 0.075),
    _MuscleHotspot('calf', 0.698, 0.72, 0.075),
  ];
}
