// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VendorController)
const vendorControllerProvider = VendorControllerProvider._();

final class VendorControllerProvider
    extends $AsyncNotifierProvider<VendorController, List<Tag>> {
  const VendorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vendorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vendorControllerHash();

  @$internal
  @override
  VendorController create() => VendorController();
}

String _$vendorControllerHash() => r'7197a013e1f86c323259e79443fb90c528e4d3ff';

abstract class _$VendorController extends $AsyncNotifier<List<Tag>> {
  FutureOr<List<Tag>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Tag>>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Tag>>, List<Tag>>,
              AsyncValue<List<Tag>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
