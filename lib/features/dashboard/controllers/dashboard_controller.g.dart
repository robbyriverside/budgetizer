// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardController)
const dashboardControllerProvider = DashboardControllerProvider._();

final class DashboardControllerProvider
    extends $NotifierProvider<DashboardController, DashboardState> {
  const DashboardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardControllerHash();

  @$internal
  @override
  DashboardController create() => DashboardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardState>(value),
    );
  }
}

String _$dashboardControllerHash() =>
    r'f780c98c7ab64272ec2e65e331ac997e6364f40f';

abstract class _$DashboardController extends $Notifier<DashboardState> {
  DashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DashboardState, DashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DashboardState, DashboardState>,
              DashboardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(bankTransactionList)
const bankTransactionListProvider = BankTransactionListProvider._();

final class BankTransactionListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BankTransaction>>,
          List<BankTransaction>,
          FutureOr<List<BankTransaction>>
        >
    with
        $FutureModifier<List<BankTransaction>>,
        $FutureProvider<List<BankTransaction>> {
  const BankTransactionListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankTransactionListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankTransactionListHash();

  @$internal
  @override
  $FutureProviderElement<List<BankTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BankTransaction>> create(Ref ref) {
    return bankTransactionList(ref);
  }
}

String _$bankTransactionListHash() =>
    r'3af6ade8313112203ca23037229c57c148ee1859';

@ProviderFor(dashboardCalculations)
const dashboardCalculationsProvider = DashboardCalculationsProvider._();

final class DashboardCalculationsProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
  const DashboardCalculationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardCalculationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardCalculationsHash();

  @$internal
  @override
  $ProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, double> create(Ref ref) {
    return dashboardCalculations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$dashboardCalculationsHash() =>
    r'41be73f9db1e2571087de31e43292611edca878b';
