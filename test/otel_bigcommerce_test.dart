// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_bigcommerce/otel_bigcommerce.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_bigcommerce-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('catalog.products.create records CLIENT span', () async {
    await tracedBigcommerce<String>(
      resource: 'catalog/products',
      action: 'create',
      storeHash: 'h-abc',
      apiVersion: 'v3',
      invoke: () async => 'p-1',
    );
    final a = attrsOf(
      spans.findSpanByName('bigcommerce catalog/products.create')!,
    );
    expect(a['bigcommerce.resource'], 'catalog/products');
    expect(a['bigcommerce.action'], 'create');
    expect(a['bigcommerce.operation'], 'catalog/products.create');
    expect(a['bigcommerce.store_hash'], 'h-abc');
    expect(a['bigcommerce.api.version'], 'v3');
  });

  test('suppression skips spans', () async {
    await runWithoutBigcommerceInstrumentationAsync(() async {
      await tracedBigcommerce<String>(
        resource: 'r',
        action: 'a',
        storeHash: 'h',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('bigcommerce '), isEmpty);
  });
}
