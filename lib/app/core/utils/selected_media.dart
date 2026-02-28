import 'dart:io';

class SelectedMedia {
  final File file;
  final bool isVideo;
  final File? thumbnail;

  SelectedMedia({required this.file, required this.isVideo, this.thumbnail});
}
