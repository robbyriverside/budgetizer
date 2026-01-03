// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storageRepository)
const storageRepositoryProvider = StorageRepositoryProvider._();

final class StorageRepositoryProvider extends $FunctionalProvider<
    StorageRepository,
    StorageRepository,
    StorageRepository> with $Provider<StorageRepository> {
  const StorageRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'storageRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storageRepositoryHash();

  @$internal
  @override
  $ProviderElement<StorageRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageRepository create(Ref ref) {
    return storageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageRepository>(value),
    );
  }
}

String _$storageRepositoryHash() => r'0c574cff5aab6228fc251b7fc48d62ea99f778ba';
