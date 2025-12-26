// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporting_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportingController)
const reportingControllerProvider = ReportingControllerProvider._();

final class ReportingControllerProvider
    extends $AsyncNotifierProvider<ReportingController, List<ReportItem>> {
  const ReportingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportingControllerHash();

  @$internal
  @override
  ReportingController create() => ReportingController();
}

String _$reportingControllerHash() =>
    r'6226da86b34b9e41f3e273cac3c3d64bba1aace6';

abstract class _$ReportingController extends $AsyncNotifier<List<ReportItem>> {
  FutureOr<List<ReportItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ReportItem>>, List<ReportItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ReportItem>>, List<ReportItem>>,
              AsyncValue<List<ReportItem>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
