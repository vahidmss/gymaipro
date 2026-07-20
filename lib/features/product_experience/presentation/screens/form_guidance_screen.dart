import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade.dart';
import 'package:gymaipro/features/product_experience/application/form_guidance_facade.dart';
import 'package:gymaipro/features/product_experience/form_guidance/form_exercise_guidance.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';

/// Local-first form tips with catalog search; AI answers stay on this screen.
class FormGuidanceScreen extends StatefulWidget {
  const FormGuidanceScreen({
    this.sessionDay,
    this.catalogExerciseId,
    this.facade,
    this.chatFacade,
    super.key,
  });

  final String? sessionDay;
  final int? catalogExerciseId;
  final FormGuidanceFacade? facade;
  final CoachChatFacade? chatFacade;

  @override
  State<FormGuidanceScreen> createState() => _FormGuidanceScreenState();
}

class _FormGuidanceScreenState extends State<FormGuidanceScreen> {
  late final FormGuidanceFacade _facade;
  late final CoachChatFacade _chatFacade;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _loading = true;
  String? _error;
  FormGuidanceSession? _session;
  List<FormExerciseGuidance> _catalog = const <FormExerciseGuidance>[];
  List<FormExerciseGuidance> _searchResults = const <FormExerciseGuidance>[];
  FormExerciseGuidance? _selected;
  bool _searching = false;

  bool _askingCoach = false;
  String? _coachAnswer;
  String? _coachError;

  @override
  void initState() {
    super.initState();
    _facade = widget.facade ?? FormGuidanceFacade();
    _chatFacade = widget.chatFacade ?? CoachChatFacade();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _facade.load(
        sessionDay: widget.sessionDay,
        preferredExerciseId: widget.catalogExerciseId,
      );
      if (!mounted) return;
      final session = result.session;
      FormExerciseGuidance? selected =
          session.byCatalogId(result.initialExerciseId);
      if (selected == null && result.initialExerciseId != null) {
        for (final item in result.catalog) {
          if (item.catalogExerciseId == result.initialExerciseId) {
            selected = item;
            break;
          }
        }
      }
      selected ??= session.exercises.isNotEmpty
          ? session.exercises.first
          : (result.catalog.isNotEmpty ? result.catalog.first : null);

      setState(() {
        _session = session;
        _catalog = result.catalog;
        _searchResults = result.catalog.take(20).toList(growable: false);
        _selected = selected;
        _loading = false;
        _coachAnswer = null;
        _coachError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_runSearch(value));
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final results = await _facade.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _selectExercise(FormExerciseGuidance exercise) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _selected = exercise;
      _coachAnswer = null;
      _coachError = null;
    });
  }

  Future<void> _askCoachInline(FormExerciseGuidance exercise) async {
    await HapticFeedback.selectionClick();
    setState(() {
      _askingCoach = true;
      _coachError = null;
      _coachAnswer = null;
    });
    try {
      final response = await _chatFacade.send(exercise.askCoachPrompt);
      if (!mounted) return;
      final text = response.message.text.trim();
      setState(() {
        _askingCoach = false;
        if (text.isEmpty) {
          _coachError =
              'پاسخ واضحی نیامد. یک‌بار دیگر امتحان کن یا نام حرکت را دقیق‌تر بنویس.';
        } else {
          _coachAnswer = text;
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _askingCoach = false;
        _coachError = 'نتونستم نکته فرم را بگیرم: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: ProductCopy.askFormTip,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const GymPagePadding(
        child: Column(
          children: <Widget>[
            GymSkeleton(height: 120),
            SizedBox(height: GymSpacing.lg),
            GymSkeleton(height: 160),
          ],
        ),
      );
    }

    if (_error != null) {
      return GymPagePadding(
        child: GymErrorState(
          title: 'خطا در بارگذاری فرم اجرا',
          message: _error!,
          onRetry: () => unawaited(_load()),
        ),
      );
    }

    final session = _session;
    final selected = _selected;
    if (selected == null && (session == null || session.isEmpty) && _catalog.isEmpty) {
      return const GymPagePadding(
        child: GymEmptyState(
          title: 'کاتالوگ تمرین خالی است',
          message: 'هنوز تمرینی برای نمایش فرم اجرا در دسترس نیست.',
        ),
      );
    }

    final tips = selected?.displayTips ?? const <String>[];

    return GymPagePadding(
      child: ListView(
        children: <Widget>[
          Text(
            'هر حرکتی را جستجو کن یا از حرکات جلسه امروز انتخاب کن.',
            style: context.gymTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          GymSpacing.gapMd,
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'جستجوی حرکت… مثلاً اسکوات',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_searching) ...<Widget>[
            GymSpacing.gapSm,
            Text(
              'در حال جستجو…',
              style: context.gymTextStyle(
                fontSize: 12,
                color: context.gymTextSecondary,
              ),
            ),
          ],
          if (_searchResults.isNotEmpty) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              'نتایج جستجو',
              style: context.gymTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.gymTextSecondary,
              ),
            ),
            GymSpacing.gapSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchResults.take(12).map((exercise) {
                final isSelected = _isSame(exercise, selected);
                return ChoiceChip(
                  label: Text(
                    exercise.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  onSelected: (_) => _selectExercise(exercise),
                );
              }).toList(growable: false),
            ),
          ],
          if (session != null && session.exercises.isNotEmpty) ...<Widget>[
            GymSpacing.gapXl,
            Text(
              session.programTitle != null && session.programTitle!.isNotEmpty
                  ? 'حرکات ${session.sessionDay}'
                  : 'حرکات جلسه امروز',
              style: context.gymTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.gymTextSecondary,
              ),
            ),
            GymSpacing.gapSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.exercises.map((exercise) {
                final isSelected = _isSame(exercise, selected);
                return ChoiceChip(
                  label: Text(exercise.name),
                  selected: isSelected,
                  onSelected: (_) => _selectExercise(exercise),
                );
              }).toList(growable: false),
            ),
          ],
          if (selected != null) ...<Widget>[
            GymSpacing.gapXl,
            Text(
              selected.name,
              style: context.gymTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (selected.primaryMuscle != null &&
                selected.primaryMuscle!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'تمرکز عضلانی: ${selected.primaryMuscle}',
                style: context.gymTextStyle(
                  fontSize: 13,
                  color: context.gymTextSecondary,
                ),
              ),
            ],
            GymSpacing.gapLg,
            if (tips.isNotEmpty)
              CoachSpeechCard(
                title: selected.hasLocalTips
                    ? 'نکات فرم'
                    : 'یادداشت برنامه',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tips
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $tip',
                            style: context.gymTextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              )
            else
              CoachSpeechCard(
                title: 'نکته ذخیره‌شده پیدا نشد',
                child: Text(
                  'برای «${selected.name}» در کاتالوگ نکته فرم آماده نبود. '
                  'می‌تونی همین‌جا از مربی بخواهی نکات فرم را برایت بنویسد — '
                  'بدون ترک این صفحه.',
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_coachAnswer != null) ...<Widget>[
              GymSpacing.gapLg,
              CoachSpeechCard(
                title: 'راهنمای مربی برای همین حرکت',
                child: Text(
                  _coachAnswer!,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (_coachError != null) ...<Widget>[
              GymSpacing.gapMd,
              Text(
                _coachError!,
                style: context.gymTextStyle(
                  fontSize: 13,
                  color: context.gymTextSecondary,
                ),
              ),
            ],
            GymSpacing.gapXl,
            GymButton(
              label: tips.isEmpty
                  ? (_askingCoach
                      ? 'در حال گرفتن نکات فرم…'
                      : 'نکات فرم را از مربی بگیر')
                  : (_askingCoach
                      ? 'در حال دریافت…'
                      : 'توضیح بیشتر از مربی'),
              onPressed: _askingCoach
                  ? null
                  : () => unawaited(_askCoachInline(selected)),
              fullWidth: true,
              loading: _askingCoach,
              variant: tips.isEmpty
                  ? GymButtonVariant.primary
                  : GymButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  bool _isSame(FormExerciseGuidance a, FormExerciseGuidance? b) {
    if (b == null) return false;
    if (identical(a, b)) return true;
    if (a.catalogExerciseId != null &&
        b.catalogExerciseId != null &&
        a.catalogExerciseId == b.catalogExerciseId) {
      return true;
    }
    return a.name == b.name;
  }
}
