// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagService)
const tagServiceProvider = TagServiceProvider._();

final class TagServiceProvider
    extends $AsyncNotifierProvider<TagService, List<Tag>> {
  const TagServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagServiceHash();

  @$internal
  @override
  TagService create() => TagService();
}

String _$tagServiceHash() => r'143696beb9b3aebd06c074dbf2527e11efbd4953';

abstract class _$TagService extends $AsyncNotifier<List<Tag>> {
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
