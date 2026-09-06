# flutter_mdi_remap

A searchable, serializable Material Design Icons registry for Layrz Flutter projects.

`flutter_mdi_remap` wraps [`flutter_material_design_icons`](https://pub.dev/packages/flutter_material_design_icons)
in a single shared `MdiRemapIcon` type, so that projects which both need to store an icon choice by
name (e.g. in a database, GraphQL field, or JSON payload) and render it back as an `IconData` can do
so through one common type, rather than each maintaining its own name↔icon mapping. Both
[`layrz_ui`](https://github.com/goldenm-software/layrz_ui) and `layrz-sdk` depend on this package.

## Features

* `MdiRemapIcon` — an immutable record of `name` (the `mdi-`-prefixed persistence key), `tags`
  (searchable categories from the MDI metadata), and `data` (the renderable `IconData`).
* A generated registry of all 7,447 Material Design Icons, indexed two ways:
  * `MdiRemapIconsClasses` — one `static const MdiRemapIcon` per icon, for compile-time references.
  * `iconMapping` — a `Map<String, MdiRemapIcon>` keyed by icon name, for runtime lookup.
* A small typed API on top of the registry: `findMdiRemapIconByName`, `searchMdiRemapIcons`, and
  `allMdiRemapIcons`.

## Getting started

Add the dependency:

```yaml
dependencies:
  flutter_mdi_remap: ^0.0.1
```

Import the package entry point:

```dart
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
```

## Usage

### Look up an icon by name

```dart
final icon = findMdiRemapIconByName('mdi-account');
if (icon != null) {
  return Icon(icon.data);
}
```

### Search by name or tag

`searchMdiRemapIcons` matches case-insensitively against both the icon's name and its tags — useful
for building an icon picker's search field.

```dart
final results = searchMdiRemapIcons('home automation');
// -> every MdiRemapIcon whose name or tags contain "home automation",
//    e.g. mdi-account (tagged 'Home Automation').
```

An empty or blank query returns every registered icon:

```dart
final all = searchMdiRemapIcons(''); // same as allMdiRemapIcons()
```

### Reference an icon directly

When the icon is known at compile time, reference it through `MdiRemapIconsClasses` instead of a
string lookup:

```dart
final icon = MdiRemapIconsClasses.accountSearch;
```

### Persist and restore an icon choice

Because `MdiRemapIcon.name` is a plain string, it round-trips cleanly through storage:

```dart
// Persist:
final storedName = icon.name; // e.g. 'mdi-account'

// Restore:
final restored = findMdiRemapIconByName(storedName);
```

## Regenerating the icon registry

The registry (`lib/src/classes.g.dart` and `lib/src/mapping.g.dart`) is generated from the installed
`flutter_material_design_icons` package version — it is not hand-maintained. To regenerate after
bumping that dependency:

```bash
make icons
```

This runs `dart run tool/generate_icons.dart`, which parses the MDI package's icon metadata and
aborts if it matches fewer than 7,000 icons (a signal that the MDI package's internal structure
changed in a way the generator doesn't understand yet).
