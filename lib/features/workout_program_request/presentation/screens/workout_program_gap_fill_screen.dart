import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_gap_fill_service.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_generation_service.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/features/workout_program_request/domain/workout_program_gap_answers.dart';
import 'package:gymaipro/features/workout_program_request/domain/workout_program_request_defaults.dart';
import 'package:gymaipro/features/workout_program_request/presentation/widgets/workout_program_access_sheet.dart';
import 'package:gymaipro/features/workout_program_request/presentation/widgets/workout_program_build_progress.dart';
import 'package:gymaipro/features/workout_today/navigation/workout_today_route.dart';
import 'package:gymaipro/payment/services/pending_direct_payment_tracker.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Asks useful essentials (+ optional advanced), then builds a real program.
///
/// Payment is requested only when the user taps Build (not on entry).
class WorkoutProgramGapFillScreen extends StatefulWidget {
  const WorkoutProgramGapFillScreen({
    this.gapFillService,
    this.generationService,
    this.tokenService,
    super.key,
  });

  final WorkoutProgramGapFillService? gapFillService;
  final WorkoutProgramGenerationService? generationService;
  final WorkoutProgramTokenService? tokenService;

  @override
  State<WorkoutProgramGapFillScreen> createState() =>
      _WorkoutProgramGapFillScreenState();
}

class _WorkoutProgramGapFillScreenState
    extends State<WorkoutProgramGapFillScreen>
    with WidgetsBindingObserver {
  late final WorkoutProgramGapFillService _gapFill;
  late final WorkoutProgramGenerationService _generation;
  late final WorkoutProgramTokenService _tokens;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  bool _loading = true;
  bool _generating = false;
  bool _showAdvanced = false;
  bool _askAge = false;
  bool _askHeight = true;
  bool _askWeight = true;
  bool _hasPaidPass = false;
  int? _derivedAge;
  String? _error;
  String _buildStatus = 'building';

  String _goal = WorkoutProgramRequestDefaults.goal;
  String _equipment = WorkoutProgramRequestDefaults.equipment;
  String _experience = WorkoutProgramRequestDefaults.experience;
  int _daysPerWeek = WorkoutProgramRequestDefaults.daysPerWeek;
  int _sessionMinutes = WorkoutProgramRequestDefaults.sessionMinutes;
  List<String> _injuries = <String>[WorkoutProgramRequestDefaults.noInjury];
  List<String> _priorityMuscles = <String>['بدون اولویت خاص'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WorkoutProgramRequestNavigation.paymentReturnTick.addListener(
      _onPaymentReturn,
    );
    _gapFill = widget.gapFillService ?? WorkoutProgramGapFillService();
    _generation =
        widget.generationService ?? WorkoutProgramGenerationService();
    _tokens = widget.tokenService ?? WorkoutProgramTokenService();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WorkoutProgramRequestNavigation.paymentReturnTick.removeListener(
      _onPaymentReturn,
    );
    WidgetsBinding.instance.removeObserver(this);
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onPaymentReturn() {
    unawaited(_refreshAccess(clearUnpaidError: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_generating) {
      unawaited(_refreshAccess(clearUnpaidError: true));
      // Verify/activate may finish a moment after resume.
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted || _generating) return;
        unawaited(_refreshAccess(clearUnpaidError: true));
      });
    }
  }

  Future<void> _refreshAccess({bool clearUnpaidError = false}) async {
    try {
      final access = await _tokens.checkAccess();
      if (!mounted) return;
      setState(() {
        _hasPaidPass = access.canBuild;
        if (clearUnpaidError && access.canBuild) {
          _error = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    try {
      final context = await _gapFill.loadContext();
      final seed = _gapFill.seedAnswers(context);
      final missing = _gapFill.missingEssentials(context);
      final access = await _tokens.checkAccess();

      if (!mounted) return;
      setState(() {
        _derivedAge = seed.age;
        _askAge = seed.age == null;
        _askHeight = missing.contains('height') || seed.height == null;
        _askWeight = missing.contains('weight') || seed.weight == null;
        _goal = seed.goal ?? WorkoutProgramRequestDefaults.goal;
        _equipment = seed.equipment ?? WorkoutProgramRequestDefaults.equipment;
        _experience =
            seed.experience ?? WorkoutProgramRequestDefaults.experience;
        _daysPerWeek =
            seed.daysPerWeek ?? WorkoutProgramRequestDefaults.daysPerWeek;
        _sessionMinutes = seed.sessionMinutes ??
            WorkoutProgramRequestDefaults.sessionMinutes;
        _injuries = seed.injuries.isEmpty
            ? <String>[WorkoutProgramRequestDefaults.noInjury]
            : List<String>.from(seed.injuries);
        if (seed.height != null) {
          _heightController.text = seed.height!.round().toString();
        }
        if (seed.weight != null) {
          _weightController.text = seed.weight!.round().toString();
        }
        _hasPaidPass = access.canBuild;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'بارگذاری اطلاعات ممکن نشد. اتصال اینترنت را بررسی کن.';
      });
    }
  }

  WorkoutProgramGapAnswers _collectAnswers() {
    return WorkoutProgramGapAnswers(
      age: _derivedAge ?? int.tryParse(_ageController.text.trim()),
      height: double.tryParse(_heightController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
      goal: _goal,
      equipment: _equipment,
      experience: _experience,
      daysPerWeek: _daysPerWeek,
      sessionMinutes: _sessionMinutes,
      injuries: List<String>.from(_injuries),
      priorityMuscles: List<String>.from(_priorityMuscles),
    );
  }

  bool _validate() {
    if (_askAge && int.tryParse(_ageController.text.trim()) == null) {
      return false;
    }
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    if (_askHeight && (height == null || height < 100 || height > 250)) {
      return false;
    }
    if (_askWeight && (weight == null || weight < 30 || weight > 300)) {
      return false;
    }
    if (_goal.trim().isEmpty || _equipment.trim().isEmpty) return false;
    return true;
  }

  Future<bool> _ensurePaidBeforeBuild() async {
    final access = await _tokens.checkAccess();
    if (!mounted) return false;

    if (access.canBuild) {
      setState(() => _hasPaidPass = true);
      return true;
    }

    // Persist answers before leaving for gateway so return can seed context.
    try {
      await _gapFill.persistAnswers(_collectAnswers());
    } catch (_) {}

    if (!mounted) return false;
    final purchased = await showWorkoutProgramAccessSheet(
      context,
      access: access,
      openProgramBuilderOnSuccess: false,
      returnTarget: PendingDirectPaymentTracker.returnTargetWorkoutBuilder,
    );
    if (!mounted) return false;

    if (purchased ?? false) {
      final again = await _tokens.checkAccess();
      if (!mounted) return false;
      setState(() => _hasPaidPass = again.canBuild);
      return again.canBuild;
    }

    // Zibal path pops false and leaves the app; refresh when they return.
    await _refreshAccess();
    return _hasPaidPass;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      setState(
        () => _error =
            'قد باید حدود ۱۰۰–۲۵۰ و وزن حدود ۳۰–۳۰۰ باشد. موارد لازم را کامل کن.',
      );
      return;
    }

    final paid = await _ensurePaidBeforeBuild();
    if (!mounted) return;
    if (!paid) {
      setState(
        () => _error = _hasPaidPass
            ? null
            : 'برای ساخت، اول باید پرداخت را کامل کنی. '
                'اگر الان پرداخت کردی، چند ثانیه صبر کن و دوباره «بساز» را بزن.',
      );
      return;
    }

    setState(() {
      _generating = true;
      _buildStatus = 'building';
      _error = null;
    });

    final outcome = await _generation.generateAndActivate(_collectAnswers());
    if (!mounted) return;

    if (!outcome.isSuccess) {
      setState(() {
        _buildStatus = 'error';
        _error = outcome.errorMessage;
      });
      return;
    }

    setState(() => _buildStatus = 'success');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() => _generating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          ProductCopy.programReadySnackbar,
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );

    // Always land on Workout Today — never leave the user on a blank stack.
    Navigator.of(context).pushNamedAndRemoveUntil(
      WorkoutTodayRoute.routeName,
      (route) {
        final name = route.settings.name ?? '';
        return route.isFirst || name == '/main' || name == '/coach';
      },
    );
  }

  void _toggleInjury(String value) {
    setState(() {
      if (value == WorkoutProgramRequestDefaults.noInjury) {
        _injuries = <String>[WorkoutProgramRequestDefaults.noInjury];
        return;
      }
      _injuries.remove(WorkoutProgramRequestDefaults.noInjury);
      if (_injuries.contains(value)) {
        _injuries.remove(value);
      } else {
        _injuries.add(value);
      }
      if (_injuries.isEmpty) {
        _injuries = <String>[WorkoutProgramRequestDefaults.noInjury];
      }
    });
  }

  void _toggleMuscle(String value) {
    setState(() {
      if (value == 'بدون اولویت خاص') {
        _priorityMuscles = <String>['بدون اولویت خاص'];
        return;
      }
      _priorityMuscles.remove('بدون اولویت خاص');
      if (_priorityMuscles.contains(value)) {
        _priorityMuscles.remove(value);
      } else {
        _priorityMuscles.add(value);
      }
      if (_priorityMuscles.isEmpty) {
        _priorityMuscles = <String>['بدون اولویت خاص'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_generating || _buildStatus == 'error',
      child: Stack(
        children: [
          GymPageScaffold(
            title: ProductCopy.requestWorkoutProgram,
            // Keep back visible even while PopScope blocks system dismiss mid-generate.
            showBack: true,
            onBack: () {
              if (_generating && _buildStatus != 'error') return;
              Navigator.of(context).maybePop();
            },
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : GymPagePadding(
                    child: ListView(
                      children: <Widget>[
                        Text(
                          _derivedAge != null
                              ? 'سن از تاریخ تولدت حساب شد ($_derivedAge سال). فقط همین موارد کوتاه را کامل کن.'
                              : 'چند سوال کوتاه — بقیه با پیش‌فرض‌های رایج پر می‌شود.',
                          style: context.gymTextStyle(
                            fontSize: 15,
                            color: context.gymTextSecondary,
                          ),
                        ),
                        GymSpacing.gapXl,
                        if (_askAge)
                          _NumberField(
                            label: 'سن (سال)',
                            controller: _ageController,
                            required: true,
                          ),
                        if (_askHeight)
                          _NumberField(
                            label: 'قد (سانتی‌متر)',
                            controller: _heightController,
                            required: true,
                          ),
                        if (_askWeight)
                          _NumberField(
                            label: 'وزن (کیلوگرم)',
                            controller: _weightController,
                            required: true,
                          ),
                        const _SectionLabel(
                          label: 'هدفت از تمرین',
                          required: true,
                        ),
                        _ChipRow(
                          options: WorkoutProgramRequestDefaults.goalOptions,
                          selected: _goal,
                          onSelected: (value) => setState(() => _goal = value),
                        ),
                        GymSpacing.gapLg,
                        const _SectionLabel(label: 'تجهیزات', required: true),
                        _ChipRow(
                          options:
                              WorkoutProgramRequestDefaults.equipmentOptions,
                          selected: _equipment,
                          onSelected: (value) =>
                              setState(() => _equipment = value),
                        ),
                        GymSpacing.gapLg,
                        const _SectionLabel(
                          label: 'سطح تجربه',
                          required: true,
                        ),
                        _ChipRow(
                          options:
                              WorkoutProgramRequestDefaults.experienceOptions,
                          selected: _experience,
                          onSelected: (value) =>
                              setState(() => _experience = value),
                        ),
                        GymSpacing.gapLg,
                        const _SectionLabel(
                          label: 'چند روز در هفته؟',
                          required: true,
                        ),
                        _ChipRow(
                          options: WorkoutProgramRequestDefaults
                              .daysPerWeekOptions
                              .map((d) => '$d روز')
                              .toList(),
                          selected: '$_daysPerWeek روز',
                          onSelected: (label) {
                            final parsed =
                                int.tryParse(label.split(' ').first);
                            if (parsed != null) {
                              setState(() => _daysPerWeek = parsed);
                            }
                          },
                        ),
                        GymSpacing.gapLg,
                        const _SectionLabel(label: 'آسیب یا محدودیت؟'),
                        _MultiChipRow(
                          options: WorkoutProgramRequestDefaults.injuryOptions,
                          selected: _injuries,
                          onToggle: _toggleInjury,
                        ),
                        GymSpacing.gapLg,
                        _AdvancedSection(
                          expanded: _showAdvanced,
                          onToggle: () =>
                              setState(() => _showAdvanced = !_showAdvanced),
                          sessionMinutes: _sessionMinutes,
                          onMinutes: (v) =>
                              setState(() => _sessionMinutes = v),
                          priorityMuscles: _priorityMuscles,
                          onToggleMuscle: _toggleMuscle,
                        ),
                        if (_error != null && !_generating) ...<Widget>[
                          GymSpacing.gapMd,
                          Text(
                            _error!,
                            style: context.gymTextStyle(
                              fontSize: 13,
                              color: GymColors.danger,
                            ),
                          ),
                        ],
                        GymSpacing.gapXxl,
                        GymButton(
                          label: ProductCopy.buildProgramCta,
                          fullWidth: true,
                          onPressed:
                              _generating ? null : () => unawaited(_submit()),
                        ),
                        GymSpacing.gapSm,
                        Text(
                          _hasPaidPass
                              ? ProductCopy.buildProgramAlreadyPaidHint
                              : ProductCopy.buildProgramPayOnBuildHint,
                          textAlign: TextAlign.center,
                          style: context.gymTextStyle(
                            fontSize: 12,
                            fontWeight: _hasPaidPass
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _hasPaidPass
                                ? context.gymPrimary
                                : context.gymTextSecondary,
                          ),
                        ),
                        const SizedBox(height: GymSpacing.massive),
                      ],
                    ),
                  ),
          ),
          if (_generating)
            Positioned.fill(
              child: WorkoutProgramBuildProgress(
                status: _buildStatus,
                error: _error,
                onDismissError: () {
                  setState(() {
                    _generating = false;
                    _buildStatus = 'building';
                    _error = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.sm),
      child: Text(
        required ? '$label *' : label,
        style: context.gymTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.gymTextPrimary,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.gymBorderSubtle),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.lg),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
        ],
        style: context.gymTextStyle(
          fontSize: 16,
          color: context.gymTextPrimary,
        ),
        cursorColor: context.gymPrimary,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: context.gymTextStyle(
            fontSize: 14,
            color: context.gymTextSecondary,
          ),
          floatingLabelStyle: context.gymTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.gymPrimary,
          ),
          filled: true,
          fillColor: context.gymIsDark
              ? context.gymElevated
              : Colors.white.withValues(alpha: 0.96),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: context.gymPrimary, width: 1.4),
          ),
          border: border,
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = context.gymIsDark;
    final selectedFill = context.gymPrimary.withValues(
      alpha: isDark ? 0.28 : 0.16,
    );
    final unselectedFill = isDark
        ? context.gymCard
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = context.gymBorderSubtle;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: selectedFill,
          backgroundColor: unselectedFill,
          side: BorderSide(
            color: isSelected
                ? context.gymPrimary.withValues(alpha: 0.55)
                : borderColor,
          ),
          checkmarkColor: context.gymPrimary,
          labelStyle: context.gymTextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? context.gymTextPrimary
                : context.gymTextSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _MultiChipRow extends StatelessWidget {
  const _MultiChipRow({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.gymIsDark;
    final selectedFill = context.gymPrimary.withValues(
      alpha: isDark ? 0.28 : 0.16,
    );
    final unselectedFill = isDark
        ? context.gymCard
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = context.gymBorderSubtle;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          selectedColor: selectedFill,
          backgroundColor: unselectedFill,
          side: BorderSide(
            color: isSelected
                ? context.gymPrimary.withValues(alpha: 0.55)
                : borderColor,
          ),
          checkmarkColor: context.gymPrimary,
          labelStyle: context.gymTextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? context.gymTextPrimary
                : context.gymTextSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.expanded,
    required this.onToggle,
    required this.sessionMinutes,
    required this.onMinutes,
    required this.priorityMuscles,
    required this.onToggleMuscle,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final int sessionMinutes;
  final ValueChanged<int> onMinutes;
  final List<String> priorityMuscles;
  final ValueChanged<String> onToggleMuscle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GymSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'تنظیمات بیشتر (اختیاری)',
                    style: context.gymTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.gymTextPrimary,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: context.gymTextSecondary,
                ),
              ],
            ),
          ),
        ),
        Text(
          'پیش‌فرض: ${WorkoutProgramRequestDefaults.sessionMinutes} دقیقه ≈ حدود ۶ حرکت در جلسه',
          style: context.gymTextStyle(
            fontSize: 12,
            color: context.gymTextSecondary,
          ),
        ),
        if (expanded) ...<Widget>[
          GymSpacing.gapLg,
          const _SectionLabel(label: 'مدت هر جلسه'),
          _ChipRow(
            options: WorkoutProgramRequestDefaults.sessionMinutesOptions
                .map((m) => '$m دقیقه')
                .toList(),
            selected: '$sessionMinutes دقیقه',
            onSelected: (label) {
              final parsed = int.tryParse(label.split(' ').first);
              if (parsed != null) onMinutes(parsed);
            },
          ),
          GymSpacing.gapLg,
          const _SectionLabel(label: 'اولویت عضلات'),
          _MultiChipRow(
            options: WorkoutProgramRequestDefaults.priorityMuscleOptions,
            selected: priorityMuscles,
            onToggle: onToggleMuscle,
          ),
        ],
      ],
    );
  }
}
