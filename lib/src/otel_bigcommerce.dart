// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_bigcommerce_suppression.dart';

const _tracerName = 'dartastic_otel_libs_bigcommerce';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any BigCommerce v3 API call in a CLIENT span.
Future<T> tracedBigcommerce<T>({
  required String resource,
  required String action,
  required String storeHash,
  required Future<T> Function() invoke,
  String? apiVersion,
}) async {
  if (bigcommerceInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'bigcommerce.resource': resource,
    'bigcommerce.action': action,
    'bigcommerce.operation': '$resource.$action',
    'bigcommerce.store_hash': storeHash,
  };
  if (apiVersion != null) m['bigcommerce.api.version'] = apiVersion;

  final span = _tracer().startSpan(
    'bigcommerce $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
