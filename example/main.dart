// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_linkerd/otel_linkerd.dart';

/// Traces Linkerd calls with OpenTelemetry.
///
/// `otel_linkerd` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Linkerd call in
/// [tracedLinkerd]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'linkerd-example');

  // Traces a Linkerd call.
  final linkerdId = await tracedLinkerd<String>(
    operation: 'create',
    invoke: () async {
      // Make the Linkerd call here, then report what it returned.
      const id = 'linkerd_8f3a2c';
      return const LinkerdCallResult(
          value: id,
          result: LinkerdResult(
              proxyVersion: '1',
              sourceWorkload: 'example',
              sourceNamespace: 'example',
              destinationWorkload: 'example',
              destinationNamespace: 'example',
              authority: 'example',
              tls: true,
              latencyMs: 120,
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedLinkerd create returned $linkerdId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLinkerdInstrumentationAsync.
  await runWithoutLinkerdInstrumentationAsync(
    () => tracedLinkerd<String>(
      operation: 'create',
      invoke: () async {
        const id = 'linkerd_8f3a2c';
        return const LinkerdCallResult(
            value: id,
            result: LinkerdResult(
                proxyVersion: '1',
                sourceWorkload: 'example',
                sourceNamespace: 'example',
                destinationWorkload: 'example',
                destinationNamespace: 'example',
                authority: 'example',
                tls: true,
                latencyMs: 120,
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
