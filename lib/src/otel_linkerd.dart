// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_linkerd_suppression.dart';

class LinkerdResult {
  /// Creates a result.
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

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class LinkerdCallResult<T> {
  /// Creates a call result.
  const LinkerdCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final LinkerdResult? result;
}

Future<T> tracedLinkerd<T>({
  required String operation,
  required Future<LinkerdCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (linkerdInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_linkerd');
  final span = t.startSpan('linkerd $operation', kind: SpanKind.internal);
  try {
    span.addAttributes(OTelAPI.attributes(
        [OTelAPI.attributeString('service.mesh', 'linkerd')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.proxyVersion != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString('linkerd.proxy.version', res.proxyVersion!)
        ]));
      }
      if (res.sourceWorkload != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('source.workload', res.sourceWorkload!)]));
      }
      if (res.sourceNamespace != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString('source.namespace', res.sourceNamespace!)
        ]));
      }
      if (res.destinationWorkload != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            'destination.workload',
            res.destinationWorkload!,
          )
        ]));
      }
      if (res.destinationNamespace != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            'destination.namespace',
            res.destinationNamespace!,
          )
        ]));
      }
      if (res.authority != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('http.host', res.authority!)]));
      }
      if (res.tls != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeBool('linkerd.tls', res.tls!)]));
      }
      if (res.latencyMs != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('http.client.duration', res.latencyMs!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('linkerd.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            ErrorAttributes.errorType.key,
            res.errorCode ?? 'linkerd.error',
          )
        ]));
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
