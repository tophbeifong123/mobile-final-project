import '../entities/saved_job.dart';

abstract class SavedJobRepository {
  Future<List<SavedJob>> fetchSaved();
}
