import 'package:flutter/material.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';

class ActiveProgramSelectorSheet extends StatefulWidget {
  const ActiveProgramSelectorSheet({
    required this.currentProgramId,
    super.key,
  });

  final String? currentProgramId;

  static Future<ActiveProgramOption?> show(
    BuildContext context, {
    String? currentProgramId,
  }) {
    return showModalBottomSheet<ActiveProgramOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ActiveProgramSelectorSheet(
        currentProgramId: currentProgramId,
      ),
    );
  }

  @override
  State<ActiveProgramSelectorSheet> createState() =>
      _ActiveProgramSelectorSheetState();
}

class _ActiveProgramSelectorSheetState extends State<ActiveProgramSelectorSheet> {
  final ActiveProgramCatalogService _catalog = ActiveProgramCatalogService();
  bool _loading = true;
  List<ActiveProgramOption> _programs = const <ActiveProgramOption>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final programs = await _catalog.listWorkoutPrograms();
    if (!mounted) return;
    setState(() {
      _programs = programs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: GymSpacing.lg,
          right: GymSpacing.lg,
          top: GymSpacing.lg,
          bottom: MediaQuery.paddingOf(context).bottom + GymSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'انتخاب برنامه تمرین',
              style: context.gymTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.gymTextPrimary,
              ),
            ),
            GymSpacing.gapSm,
            Text(
              'برنامه‌ای که می‌خواهی اجرا کنی را انتخاب کن. '
              'ثبت تمرین و تمرین زیر نظارت ${AppConfig.gymAiDisplayName} '
              'از همین انتخاب استفاده می‌کنند.',
              style: context.gymTextStyle(
                fontSize: 13,
                color: context.gymTextSecondary,
                height: 1.5,
              ),
            ),
            GymSpacing.gapLg,
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(GymSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_programs.isEmpty)
              Text(
                'برنامه‌ای پیدا نشد. از بخش برنامه‌های من یک برنامه فعال کن.',
                style: context.gymTextStyle(
                  fontSize: 14,
                  color: context.gymTextSecondary,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _programs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: GymSpacing.sm),
                  itemBuilder: (context, index) {
                    final program = _programs[index];
                    final selected = program.id == widget.currentProgramId;
                    return Material(
                      color: selected
                          ? context.gymPrimary.withValues(alpha: 0.1)
                          : context.gymElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(program),
                        child: Padding(
                          padding: const EdgeInsets.all(GymSpacing.md),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      program.title,
                                      style: context.gymTextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: context.gymTextPrimary,
                                      ),
                                    ),
                                    GymSpacing.gapXs,
                                    Text(
                                      program.displaySubtitle,
                                      style: context.gymTextStyle(
                                        fontSize: 13,
                                        color: context.gymTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle, color: context.gymPrimary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
