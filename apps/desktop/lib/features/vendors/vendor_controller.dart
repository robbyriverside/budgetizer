import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/tag_service.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

part 'vendor_controller.g.dart';

@riverpod
class VendorController extends _$VendorController {
  @override
  Future<List<Tag>> build() async {
    // Watch TagService so we rebuild when tags change (add/remove)
    final tags = await ref.watch(tagServiceProvider.future);
    // Filter for just Vendors
    return tags.where((t) => t.type == 'Vendor').toList();
  }

  void filterVendors(String query) async {
    // For local filtering, we can just filter the current state if needed,
    // or rely on built-in search in standard ListViews.
    // simpler to let UI handle simple text filtering on the data we provide.
  }

  void addTagToVendor(String vendorName, String tagName) {
    ref.read(tagServiceProvider.notifier).addTagToVendor(vendorName, tagName);
  }

  void saveChanges() {
    ref.read(tagServiceProvider.notifier).saveChanges();
  }

  void undoChanges() {
    ref.read(tagServiceProvider.notifier).revertToCheckpoint();
  }
}
