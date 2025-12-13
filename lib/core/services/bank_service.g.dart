// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bankService)
const bankServiceProvider = BankServiceProvider._();

final class BankServiceProvider
    extends $FunctionalProvider<BankService, BankService, BankService>
    with $Provider<BankService> {
  const BankServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankServiceHash();

  @$internal
  @override
  $ProviderElement<BankService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BankService create(Ref ref) {
    return bankService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BankService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BankService>(value),
    );
  }
}

String _$bankServiceHash() => r'51dc2d36ac4ef015a76b190a8189dab0817e5d2d';
