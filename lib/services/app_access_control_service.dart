import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/utils/version_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class AppAccessConfig {
  const AppAccessConfig({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.forceUpdate,
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.maintenanceScope,
    required this.aiHubEnabled,
    required this.academyEnabled,
    required this.myClubEnabled,
    required this.socialEnabled,
    required this.privateChatEnabled,
    required this.publicChatEnabled,
    required this.aiChatEnabled,
    required this.aiChatUnavailableMessage,
  });

  factory AppAccessConfig.defaults() {
    return const AppAccessConfig(
      maintenanceMode: false,
      maintenanceMessage: 'اپلیکیشن موقتاً در حال بروزرسانی است.',
      forceUpdate: false,
      minSupportedVersion: '',
      latestVersion: '',
      updateUrl: '',
      maintenanceScope: 'all_non_admin',
      aiHubEnabled: true,
      academyEnabled: true,
      myClubEnabled: true,
      socialEnabled: true,
      privateChatEnabled: true,
      publicChatEnabled: true,
      aiChatEnabled: true,
      aiChatUnavailableMessage:
          'چت با هوش مصنوعی موقتاً غیرفعال شده است.',
    );
  }

  factory AppAccessConfig.fromMap(Map<String, dynamic> map) {
    return AppAccessConfig(
      maintenanceMode: map['maintenance_mode'] == true,
      maintenanceMessage:
          (map['maintenance_message'] as String?)?.trim().isNotEmpty ?? false
          ? (map['maintenance_message'] as String)
          : 'اپلیکیشن موقتاً در حال بروزرسانی است.',
      forceUpdate: map['force_update'] == true,
      minSupportedVersion: (map['min_supported_version'] as String?) ?? '',
      latestVersion: (map['latest_version'] as String?) ?? '',
      updateUrl: (map['update_url'] as String?) ?? '',
      maintenanceScope:
          (map['maintenance_scope'] as String?)?.trim().isNotEmpty ?? false
          ? (map['maintenance_scope'] as String)
          : 'all_non_admin',
      aiHubEnabled: map['ai_hub_enabled'] != false,
      academyEnabled: map['academy_enabled'] != false,
      myClubEnabled: map['my_club_enabled'] != false,
      socialEnabled: map['social_enabled'] != false,
      privateChatEnabled: map['private_chat_enabled'] != false,
      publicChatEnabled: map['public_chat_enabled'] != false,
      aiChatEnabled: map['ai_chat_enabled'] == true,
      aiChatUnavailableMessage:
          (map['ai_chat_unavailable_message'] as String?)?.trim().isNotEmpty ??
              false
          ? (map['ai_chat_unavailable_message'] as String)
          : AppConfig.aiChatUnavailableMessage,
    );
  }

  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool forceUpdate;
  final String minSupportedVersion;
  final String latestVersion;
  final String updateUrl;
  final String maintenanceScope;
  final bool aiHubEnabled;
  final bool academyEnabled;
  final bool myClubEnabled;
  final bool socialEnabled;
  final bool privateChatEnabled;
  final bool publicChatEnabled;
  final bool aiChatEnabled;
  final String aiChatUnavailableMessage;

  /// چت GPT فقط وقتی فعال است که ادمین روشن کرده و موتور OpenAI انتخاب شده باشد.
  bool get isAiChatAvailable =>
      aiChatEnabled; // موتور در UI چک می‌شود

  bool get shouldForceUpdate {
    if (!forceUpdate) return false;
    final requiredVersion = minSupportedVersion.trim();
    if (requiredVersion.isEmpty) return false;
    return VersionUtils.isLessThan(AppConfig.appVersion, requiredVersion);
  }

  AppAccessConfig copyWith({
    bool? maintenanceMode,
    String? maintenanceMessage,
    bool? forceUpdate,
    String? minSupportedVersion,
    String? latestVersion,
    String? updateUrl,
    String? maintenanceScope,
    bool? aiHubEnabled,
    bool? academyEnabled,
    bool? myClubEnabled,
    bool? socialEnabled,
    bool? privateChatEnabled,
    bool? publicChatEnabled,
    bool? aiChatEnabled,
    String? aiChatUnavailableMessage,
  }) {
    return AppAccessConfig(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      updateUrl: updateUrl ?? this.updateUrl,
      maintenanceScope: maintenanceScope ?? this.maintenanceScope,
      aiHubEnabled: aiHubEnabled ?? this.aiHubEnabled,
      academyEnabled: academyEnabled ?? this.academyEnabled,
      myClubEnabled: myClubEnabled ?? this.myClubEnabled,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      privateChatEnabled: privateChatEnabled ?? this.privateChatEnabled,
      publicChatEnabled: publicChatEnabled ?? this.publicChatEnabled,
      aiChatEnabled: aiChatEnabled ?? this.aiChatEnabled,
      aiChatUnavailableMessage:
          aiChatUnavailableMessage ?? this.aiChatUnavailableMessage,
    );
  }
}

@immutable
class AppAccessAuditLog {
  const AppAccessAuditLog({
    required this.id,
    required this.changedBy,
    required this.changedAt,
    required this.summary,
    required this.adminName,
  });

  final int id;
  final String? changedBy;
  final DateTime? changedAt;
  final String summary;
  final String adminName;
}

class AppAccessControlService {
  AppAccessControlService._();

  static final AppAccessControlService instance = AppAccessControlService._();
  final SupabaseClient _supabase = Supabase.instance.client;

  final ValueNotifier<AppAccessConfig> configNotifier = ValueNotifier(
    AppAccessConfig.defaults(),
  );

  DateTime? _lastFetchAt;
  bool _isLoading = false;
  static const Duration _cacheTtl = Duration(seconds: 25);

  Future<AppAccessConfig> getConfig({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastFetchAt != null &&
        now.difference(_lastFetchAt!) < _cacheTtl) {
      return configNotifier.value;
    }
    return refreshConfig();
  }

  Future<AppAccessConfig> refreshConfig() async {
    if (_isLoading) return configNotifier.value;
    _isLoading = true;
    try {
      final data = await _supabase
          .from('app_runtime_controls')
          .select()
          .eq('id', 'global')
          .maybeSingle();

      if (data != null) {
        configNotifier.value = AppAccessConfig.fromMap(data);
      }
      _lastFetchAt = DateTime.now();
    } catch (e) {
      debugPrint('AppAccessControlService.refreshConfig error: $e');
    } finally {
      _isLoading = false;
    }
    return configNotifier.value;
  }

  Future<bool> upsertConfig(AppAccessConfig config) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final previous = configNotifier.value;
      await _supabase.from('app_runtime_controls').upsert({
        'id': 'global',
        'maintenance_mode': config.maintenanceMode,
        'maintenance_message': config.maintenanceMessage,
        'maintenance_scope': config.maintenanceScope,
        'force_update': config.forceUpdate,
        'min_supported_version': config.minSupportedVersion.trim(),
        'latest_version': config.latestVersion.trim(),
        'update_url': config.updateUrl.trim(),
        'ai_hub_enabled': config.aiHubEnabled,
        'academy_enabled': config.academyEnabled,
        'my_club_enabled': config.myClubEnabled,
        'social_enabled': config.socialEnabled,
        'private_chat_enabled': config.privateChatEnabled,
        'public_chat_enabled': config.publicChatEnabled,
        'ai_chat_enabled': config.aiChatEnabled,
        'ai_chat_unavailable_message': config.aiChatUnavailableMessage.trim(),
        'updated_by': currentUserId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _insertAuditLog(
        changedBy: currentUserId,
        previous: previous,
        current: config,
      );
      configNotifier.value = config;
      _lastFetchAt = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('AppAccessControlService.upsertConfig error: $e');
      return false;
    }
  }

  Future<List<AppAccessAuditLog>> getAuditLogs({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('app_runtime_controls_audit')
          .select()
          .order('changed_at', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(response as List);
      final profilesById = await ProfileRepository.instance.fetchProfilesByIdsMap(
        rows
            .map((row) => row['changed_by'] as String?)
            .whereType<String>()
            .toList(),
        columns: 'id, username, first_name, last_name',
      );

      final logs = <AppAccessAuditLog>[];
      for (final row in rows) {
        final changedBy = row['changed_by'] as String?;
        final changedAt = _parseChangedAt(row['changed_at']);
        var adminName = 'ادمین';
        if (changedBy != null) {
          final profile = profilesById[changedBy];
          if (profile != null) {
            adminName = ProfileRepository.instance.displayNameFromMap(
              profile,
              fallback: 'ادمین',
            );
          }
        }

        logs.add(
          AppAccessAuditLog(
            id: (row['id'] as num?)?.toInt() ?? 0,
            changedBy: changedBy,
            changedAt: changedAt,
            summary: (row['change_summary'] as String?) ?? 'بدون جزئیات',
            adminName: adminName,
          ),
        );
      }
      return logs;
    } catch (e) {
      debugPrint('AppAccessControlService.getAuditLogs error: $e');
      return const [];
    }
  }

  Future<void> _insertAuditLog({
    required String? changedBy,
    required AppAccessConfig previous,
    required AppAccessConfig current,
  }) async {
    final summary = _buildChangeSummary(previous: previous, current: current);
    try {
      await _supabase.from('app_runtime_controls_audit').insert({
        'changed_by': changedBy,
        'changed_at': DateTime.now().toUtc().toIso8601String(),
        'change_summary': summary.isEmpty ? 'تنظیمات ذخیره شد' : summary,
        'new_config': {
          'maintenance_mode': current.maintenanceMode,
          'maintenance_message': current.maintenanceMessage,
          'maintenance_scope': current.maintenanceScope,
          'force_update': current.forceUpdate,
          'min_supported_version': current.minSupportedVersion,
          'latest_version': current.latestVersion,
          'update_url': current.updateUrl,
          'ai_hub_enabled': current.aiHubEnabled,
          'academy_enabled': current.academyEnabled,
          'my_club_enabled': current.myClubEnabled,
          'social_enabled': current.socialEnabled,
          'private_chat_enabled': current.privateChatEnabled,
          'public_chat_enabled': current.publicChatEnabled,
        },
      });
    } catch (e) {
      debugPrint('AppAccessControlService._insertAuditLog error: $e');
    }
  }

  String _buildChangeSummary({
    required AppAccessConfig previous,
    required AppAccessConfig current,
  }) {
    final changes = <String>[];
    void addBool(String label, bool a, bool b) {
      if (a != b) {
        changes.add('$label: ${b ? 'روشن' : 'خاموش'}');
      }
    }

    addBool('تعمیرات', previous.maintenanceMode, current.maintenanceMode);
    if (previous.maintenanceMessage.trim() != current.maintenanceMessage.trim()) {
      changes.add('پیام تعمیرات تغییر کرد');
    }
    if (previous.maintenanceScope != current.maintenanceScope) {
      changes.add('دامنه تعمیرات: ${_scopeLabel(current.maintenanceScope)}');
    }
    addBool('اجبار آپدیت', previous.forceUpdate, current.forceUpdate);
    if (previous.minSupportedVersion != current.minSupportedVersion) {
      changes.add('حداقل نسخه: ${current.minSupportedVersion}');
    }
    if (previous.latestVersion != current.latestVersion) {
      changes.add('آخرین نسخه: ${current.latestVersion}');
    }
    if (previous.updateUrl != current.updateUrl) {
      changes.add('لینک آپدیت تغییر کرد');
    }
    addBool('AI', previous.aiHubEnabled, current.aiHubEnabled);
    addBool('آکادمی', previous.academyEnabled, current.academyEnabled);
    addBool('باشگاه من', previous.myClubEnabled, current.myClubEnabled);
    addBool('اجتماعی', previous.socialEnabled, current.socialEnabled);
    addBool('چت خصوصی', previous.privateChatEnabled, current.privateChatEnabled);
    addBool('چت عمومی', previous.publicChatEnabled, current.publicChatEnabled);

    return changes.join(' | ');
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'athlete_only':
        return 'فقط ورزشکار';
      case 'trainer_only':
        return 'فقط مربی';
      case 'all_non_admin':
      default:
        return 'همه کاربران (به‌جز ادمین)';
    }
  }

  DateTime? _parseChangedAt(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return raw.isUtc ? raw : raw.toUtc();
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      return parsed.isUtc ? parsed : parsed.toUtc();
    }
    return null;
  }
}
