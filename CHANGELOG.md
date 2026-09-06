## 1.0.0

* First stable release of `flutter_mdi_remap`.
* `MdiRemapIcon` type carrying a stable `name` (`mdi-...`), searchable `tags`, and the renderable `IconData`.
* Full generated registry of all 7,447 Material Design Icons (`iconMapping`, `MdiRemapIconsClasses`).
* Search and lookup API: `allMdiRemapIcons()`, `findMdiRemapIconByName()`, `searchMdiRemapIcons()` (case-insensitive match over name and tags).
* Icon-registry generator (`tool/generate_icons.dart`, `make icons`) that regenerates the registry from `flutter_material_design_icons`.

## 0.0.1

* Initial release.
* `MdiRemapIcon`: an immutable icon record (`name`, `tags`, `data`) wrapping a Material Design Icon from `flutter_material_design_icons`.
* Generated registry of 7,447 icons: `MdiRemapIconsClasses` (one `static const MdiRemapIcon` per icon) and `iconMapping` (`Map<String, MdiRemapIcon>` keyed by `mdi-`-prefixed name).
* Typed accessor/search API: `findMdiRemapIconByName`, `searchMdiRemapIcons`, `allMdiRemapIcons`.
* `tool/generate_icons.dart` (and `make icons`) regenerates the registry from the installed `flutter_material_design_icons` package.
