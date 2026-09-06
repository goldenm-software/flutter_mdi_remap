/// Material Design Icons registry for Layrz.
///
/// This library provides access to the flutter_material_design_icons
/// package through Layrz-styled constants and a name-based registry.
/// Icons are organized by icon object form ([MdiRemapIconsClasses]) and a Map
/// for runtime lookup ([iconMapping]), plus a small typed search/accessor
/// API ([findMdiRemapIconByName], [searchMdiRemapIcons], [allMdiRemapIcons])
/// built on top of that map.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

part 'classes.g.dart';
part 'icon.dart';
part 'mapping.g.dart';

/// Returns all registered [MdiRemapIcon]s.
///
/// The returned list is a fresh, unmodifiable snapshot of [iconMapping]'s
/// values, safe to iterate or store without exposing the backing map.
List<MdiRemapIcon> allMdiRemapIcons() => List.unmodifiable(iconMapping.values);

/// Looks up a single [MdiRemapIcon] by its exact [name].
///
/// [name] must match the icon's `mdi-`-prefixed name exactly, e.g.
/// `'mdi-account'`. Returns `null` when no icon with that name is
/// registered in [iconMapping].
MdiRemapIcon? findMdiRemapIconByName(String name) => iconMapping[name];

/// Searches the registry for icons whose name or tags contain [query].
///
/// The match is case-insensitive and substring-based against each icon's
/// [MdiRemapIcon.name] and every entry in [MdiRemapIcon.tags]. An empty or
/// blank [query] returns every registered icon via [allMdiRemapIcons].
///
/// Results are returned in the same order as [iconMapping] (alphabetical
/// by icon name, as produced by the generator).
List<MdiRemapIcon> searchMdiRemapIcons(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return allMdiRemapIcons();
  }

  return iconMapping.values
      .where((icon) {
        if (icon.name.toLowerCase().contains(normalized)) {
          return true;
        }
        return icon.tags.any((tag) => tag.toLowerCase().contains(normalized));
      })
      .toList(growable: false);
}
