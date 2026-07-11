/// Version for prompt package architecture and future templates.
class PromptVersion {
  const PromptVersion({
    required this.id,
    required this.major,
    required this.minor,
    required this.patch,
  });

  /// Initial architecture version.
  static const v1 = PromptVersion(
    id: 'prompt_builder_v1',
    major: 1,
    minor: 0,
    patch: 0,
  );

  /// Stable version id.
  final String id;

  /// Major version.
  final int major;

  /// Minor version.
  final int minor;

  /// Patch version.
  final int patch;

  /// Semantic version string.
  String get semver => '$major.$minor.$patch';
}
