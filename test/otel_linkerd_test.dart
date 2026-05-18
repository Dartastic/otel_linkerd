// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_linkerd/otel_linkerd.dart';
import 'package:test/test.dart';

void main() {
  group('otel_linkerd', () {
    test('suppression toggles in zone', () async {
      expect(linkerdInstrumentationSuppressed(), isFalse);
      await runWithoutLinkerdInstrumentationAsync(() async {
        expect(linkerdInstrumentationSuppressed(), isTrue);
      });
      expect(linkerdInstrumentationSuppressed(), isFalse);
    });

    test('LinkerdResult fields default null', () {
      const r = LinkerdResult();
      expect(r.statusCode, isNull);
    });
  });
}
