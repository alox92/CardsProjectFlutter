/// Types et classes utilitaires pour la synchronisation

enum SyncEventType {
  started,
  progress,
  completed,
  cancelled,
  error,
  uploadStarted,
  uploadProgress,
  downloadStarted,
  downloadProgress,
  completedWithErrors,
  failed,
}

class SyncEvent {
  final SyncEventType type;
  final String message;
  final Map<String, dynamic>? details;
  double? get progress => details != null && details!.containsKey('percent') ? (details!['percent'] as num?)?.toDouble() : null;
  SyncEvent(this.type, this.message, [this.details]);
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedItems;
  final int conflictsResolved;
  final int? syncDuration;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedItems,
    required this.conflictsResolved,
    this.syncDuration,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'syncedItems': syncedItems,
    'conflictsResolved': conflictsResolved,
    'syncDuration': syncDuration,
  };
}

class SyncServiceException implements Exception {
  final String message;
  final dynamic cause;

  SyncServiceException(this.message, [this.cause]);

  @override
  String toString() => 'SyncServiceException: $message${cause != null ? ', cause: $cause' : ''}';
}
