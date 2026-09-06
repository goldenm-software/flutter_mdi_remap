import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconMapping registry', () {
    test('contains more than 7000 generated icons', () {
      expect(iconMapping.length, greaterThan(7000));
    });

    test('every entry key matches its MdiRemapIcon.name', () {
      for (final entry in iconMapping.entries) {
        expect(entry.value.name, entry.key);
      }
    });

    test(
      'allMdiRemapIcons returns an unmodifiable snapshot of the same size',
      () {
        final all = allMdiRemapIcons();
        expect(all.length, iconMapping.length);
        expect(() => all.add(iconMapping.values.first), throwsUnsupportedError);
      },
    );
  });

  group('MdiRemapIcon round-trip', () {
    test('name -> MdiRemapIcon -> IconData round-trips for a known icon', () {
      const name = 'mdi-account';
      final icon = findMdiRemapIconByName(name);

      expect(icon, isNotNull);
      expect(icon!.name, name);
      expect(icon.iconData, same(icon.data));
      expect(icon.data, isA<IconData>());
      expect(icon.data, same(MdiIcons.account));
    });

    test('name -> MdiRemapIcon round-trips for another known icon', () {
      const name = 'mdi-home';
      final icon = findMdiRemapIconByName(name);

      expect(icon, isNotNull);
      expect(icon!.name, name);
      expect(icon.data, same(MdiIcons.home));
    });

    test('findMdiRemapIconByName returns null for an unregistered name', () {
      expect(findMdiRemapIconByName('mdi-this-icon-does-not-exist'), isNull);
    });

    test('equality and hashCode are based on name only', () {
      const a = MdiRemapIcon(
        name: 'mdi-account',
        tags: [],
        data: MdiIcons.account,
      );
      const b = MdiRemapIcon(
        name: 'mdi-account',
        tags: ['different'],
        data: MdiIcons.home,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString reports the icon name', () {
      const icon = MdiRemapIcon(
        name: 'mdi-account',
        tags: [],
        data: MdiIcons.account,
      );
      expect(icon.toString(), 'MdiRemapIcon(mdi-account)');
    });
  });

  group('searchMdiRemapIcons', () {
    test('matches by name substring, case-insensitively', () {
      final results = searchMdiRemapIcons('ACCOUNT-search');
      expect(results, isNotEmpty);
      expect(results.any((icon) => icon.name == 'mdi-account-search'), isTrue);
    });

    test('matches by tag substring, case-insensitively', () {
      final results = searchMdiRemapIcons('home automation');
      expect(results, isNotEmpty);
      expect(results.any((icon) => icon.name == 'mdi-account'), isTrue);
    });

    test('returns every icon for a blank query', () {
      final results = searchMdiRemapIcons('   ');
      expect(results.length, iconMapping.length);
    });

    test('returns an empty list when nothing matches', () {
      final results = searchMdiRemapIcons('this-will-not-match-anything-xyz');
      expect(results, isEmpty);
    });
  });
}
