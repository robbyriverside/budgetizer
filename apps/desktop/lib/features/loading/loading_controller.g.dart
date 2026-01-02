// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoadingController)
const loadingControllerProvider = LoadingControllerProvider._();

final class LoadingControllerProvider
    extends $NotifierProvider<LoadingController, LoadingState> {
  const LoadingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loadingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loadingControllerHash();

  @$internal
  @override
  LoadingController create() => LoadingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadingState>(value),
    );
  }
}

String _$loadingControllerHash() => r'e0d3e87221d760c1f20ba991066d94a70ef9564f';

abstract class _$LoadingController extends $Notifier<LoadingState> {
  LoadingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LoadingState, LoadingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoadingState, LoadingState>,
              LoadingState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
