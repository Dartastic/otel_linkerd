# otel_linkerd

Dartastic OpenTelemetry bridge for Linkerd (service mesh).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_linkerd/otel_linkerd.dart';

await tracedLinkerd<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return LinkerdCallResult(value: r, result: LinkerdResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutLinkerdInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
