part of 'icons.dart';

/// A Layrz icon with metadata.
///
/// [MdiRemapIcon] represents a renderable Material Design Icon from the
/// flutter_material_design_icons package with additional metadata for
/// searchability and categorization. Each icon carries a unique name,
/// optional tags for categorization, and the underlying [IconData] for
/// rendering.
///
/// Instances are generated at build time into [MdiRemapIconsClasses] and
/// [iconMapping] by `tool/generate_icons.dart`; this class itself is
/// hand-written and shared by every generated instance.
final class MdiRemapIcon {
  /// Creates a [MdiRemapIcon].
  const MdiRemapIcon({
    required this.name,
    required this.tags,
    required this.data,
  });

  /// The icon's unique name, always prefixed with 'mdi-'.
  ///
  /// Used for persistence and lookup in the [iconMapping] registry.
  /// Example: `'mdi-account'`, `'mdi-wifi-strength-4'`.
  final String name;

  /// Searchable tags assigned to this icon by Material Design Icons.
  ///
  /// Categories such as 'Account / User', 'Alert / Error', or 'Weather'.
  /// Empty if the icon has no tags in the MDI metadata.
  final List<String> tags;

  /// The renderable [IconData] for this icon.
  ///
  /// Can be passed to Flutter's `Icon` widget or other icon-consuming
  /// widgets. Has a codepoint and font metadata set by the MDI package.
  final IconData data;

  /// Alias for [data], provided for call sites that prefer the
  /// `iconData` name when reading an [MdiRemapIcon] as an icon source.
  IconData get iconData => data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MdiRemapIcon && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'MdiRemapIcon($name)';
}
