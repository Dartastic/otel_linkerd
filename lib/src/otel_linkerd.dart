// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_linkerd_suppression.dart';

class LinkerdResult {
  const LinkerdResult({
    this.proxyVersion,
    this.sourceWorkload,
    this.sourceNamespace,
    this.destinationWorkload,
    this.destinationNamespace,
    this.authority,
    this.tls,
    this.latencyMs,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? proxyVersion;
  final String? sourceWorkload;
  final String? sourceNamespace;
  final String? destinationWorkload;
  final String? destinationNamespace;
  final String? authority;
  final bool? tls;
  final int? latencyMs;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

class LinkerdCallResult<T> {
  const LinkerdCallResult({required this.value, this.result});
  final T value;
  final LinkerdResult? result;
}

Future<T> tracedLinkerd<T>({
  required String operation,
  required Future<LinkerdCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (linkerdInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_linkerd');
  final span = t.startSpan('linkerd $operation', kind: SpanKind.internal);
  try {
    span.setStringAttribute('service.mesh', 'linkerd');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.proxyVersion != null) {
        span.setStringAttribute('linkerd.proxy.version', res.proxyVersion!);
      }
      if (res.sourceWorkload != null) {
        span.setStringAttribute('source.workload', res.sourceWorkload!);
      }
      if (res.sourceNamespace != null) {
        span.setStringAttribute('source.namespace', res.sourceNamespace!);
      }
      if (res.destinationWorkload != null) {
        span.setStringAttribute(
          'destination.workload',
          res.destinationWorkload!,
        );
      }
      if (res.destinationNamespace != null) {
        span.setStringAttribute(
          'destination.namespace',
          res.destinationNamespace!,
        );
      }
      if (res.authority != null) {
        span.setStringAttribute('http.host', res.authority!);
      }
      if (res.tls != null) {
        span.setBoolAttribute('linkerd.tls', res.tls!);
      }
      if (res.latencyMs != null) {
        span.setIntAttribute('http.client.duration', res.latencyMs!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('linkerd.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'linkerd.error',
        );
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
