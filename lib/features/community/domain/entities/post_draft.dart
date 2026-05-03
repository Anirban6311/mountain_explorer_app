import 'package:equatable/equatable.dart';

class PostDraft extends Equatable {
  final String title;
  final String description;
  final String? imagePath;

  const PostDraft({
    this.title = '',
    this.description = '',
    this.imagePath,
  });

  static const int titleMaxLength = 80;
  static const int descriptionMaxLength = 2000;

  /// Returns a human-readable error or `null` when the draft is valid.
  /// UI layer surfaces the string; the data layer will never see an invalid
  /// draft if callers consult `validate()` first.
  String? validate({bool requireImage = true}) {
    final t = title.trim();
    if (t.isEmpty) return 'Please enter a title.';
    if (t.length > titleMaxLength) {
      return 'Title must be $titleMaxLength characters or fewer.';
    }
    final d = description.trim();
    if (d.isEmpty) return 'Please enter a description.';
    if (d.length > descriptionMaxLength) {
      return 'Description must be $descriptionMaxLength characters or fewer.';
    }
    if (requireImage && (imagePath == null || imagePath!.isEmpty)) {
      return 'Please attach an image.';
    }
    return null;
  }

  PostDraft copyWith({
    String? title,
    String? description,
    String? imagePath,
  }) {
    return PostDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  List<Object?> get props => [title, description, imagePath];
}
