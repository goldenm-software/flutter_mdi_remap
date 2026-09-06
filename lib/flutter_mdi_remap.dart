/// Shared Material Design Icons remap for Layrz Flutter projects.
///
/// Exports the [MdiRemapIcon] type, the generated `iconMapping` and
/// `MdiRemapIconsClasses` registries, and a small typed search/accessor API
/// (`findMdiRemapIconByName`, `searchMdiRemapIcons`, `allMdiRemapIcons`)
/// built on top of the flutter_material_design_icons package. This is the
/// single import consumers need — both `layrz_ui` and `layrz-sdk` depend on
/// this package so they share one `MdiRemapIcon` type and one generated icon
/// registry.
library;

export 'package:flutter/widgets.dart' show IconData;

export 'src/icons.dart';
