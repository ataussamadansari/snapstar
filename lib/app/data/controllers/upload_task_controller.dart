import 'package:get/get.dart';

enum UploadTaskType { post, story }

class UploadTaskState {
  UploadTaskState({
    required this.id,
    required this.type,
    required this.label,
    required this.progress,
    required this.isRunning,
    this.errorMessage,
  });

  final String id;
  final UploadTaskType type;
  final String label;
  final double progress;
  final bool isRunning;
  final String? errorMessage;

  UploadTaskState copyWith({
    String? label,
    double? progress,
    bool? isRunning,
    String? errorMessage,
  }) {
    return UploadTaskState(
      id: id,
      type: type,
      label: label ?? this.label,
      progress: progress ?? this.progress,
      isRunning: isRunning ?? this.isRunning,
      errorMessage: errorMessage,
    );
  }
}

class UploadTaskController extends GetxController {
  final RxMap<String, UploadTaskState> _tasks = <String, UploadTaskState>{}.obs;

  List<UploadTaskState> get activeTasks =>
      _tasks.values.where((t) => t.isRunning).toList();

  UploadTaskState? latestActiveOf(UploadTaskType type) {
    final matches = _tasks.values.where((t) => t.type == type && t.isRunning);
    if (matches.isEmpty) return null;
    return matches.last;
  }

  String start({
    required UploadTaskType type,
    required String label,
  }) {
    final id = '${type.name}_${DateTime.now().microsecondsSinceEpoch}';
    _tasks[id] = UploadTaskState(
      id: id,
      type: type,
      label: label,
      progress: 0,
      isRunning: true,
    );
    return id;
  }

  void updateTask(
    String id, {
    String? label,
    double? progress,
  }) {
    final current = _tasks[id];
    if (current == null) return;

    _tasks[id] = current.copyWith(
      label: label,
      progress: (progress ?? current.progress).clamp(0.0, 1.0),
      isRunning: true,
      errorMessage: null,
    );
  }

  void complete(String id) {
    final current = _tasks[id];
    if (current == null) return;
    _tasks[id] = current.copyWith(
      progress: 1,
      isRunning: false,
      errorMessage: null,
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      _tasks.remove(id);
    });
  }

  void fail(String id, String message) {
    final current = _tasks[id];
    if (current == null) return;
    _tasks[id] = current.copyWith(
      isRunning: false,
      errorMessage: message,
    );
    Future<void>.delayed(const Duration(seconds: 4), () {
      _tasks.remove(id);
    });
  }
}
