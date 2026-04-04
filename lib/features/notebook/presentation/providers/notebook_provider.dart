import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notebook_repository.dart';
import '../../domain/models/notebook_entry.dart';

final _repo = NotebookRepository();

class NotebookNotifier extends AsyncNotifier<List<NotebookEntry>> {
  @override
  Future<List<NotebookEntry>> build() => _repo.loadAll();

  Future<bool> addEntry(NotebookEntry entry) async {
    final isNew = !(await _repo.contains(entry.articleUrl));
    await _repo.save(entry);
    state = AsyncValue.data(await _repo.loadAll());
    return isNew;
  }

  Future<bool> isKnown(String url) => _repo.contains(url);
}

final notebookProvider =
    AsyncNotifierProvider<NotebookNotifier, List<NotebookEntry>>(
        NotebookNotifier.new);
