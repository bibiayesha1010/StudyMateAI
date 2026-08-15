import '../models/progress_model.dart';

class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  final List<ProgressEntry> _entries = [];

  List<ProgressEntry> get entries => _entries;

  void addEntry(ProgressEntry entry) {
    _entries.add(entry);
  }
}