import 'package:flutter_riverpod/flutter_riverpod.dart';

class IsTemporaryDbNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}

final isTemporaryDbProvider = NotifierProvider<IsTemporaryDbNotifier, bool>(
  IsTemporaryDbNotifier.new,
);
