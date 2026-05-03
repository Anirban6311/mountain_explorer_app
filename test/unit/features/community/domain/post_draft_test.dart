import 'package:basic_crud_flutter/features/community/domain/entities/post_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty title', () {
    expect(
      const PostDraft(description: 'd', imagePath: '/tmp/x').validate(),
      contains('title'),
    );
  });

  test('rejects title > 80 chars', () {
    final draft = PostDraft(
      title: 'x' * 81,
      description: 'd',
      imagePath: '/tmp/x',
    );
    expect(draft.validate(), contains('80'));
  });

  test('rejects empty description', () {
    expect(
      const PostDraft(title: 't', imagePath: '/tmp/x').validate(),
      contains('description'),
    );
  });

  test('rejects description > 2000 chars', () {
    final draft = PostDraft(
      title: 't',
      description: 'd' * 2001,
      imagePath: '/tmp/x',
    );
    expect(draft.validate(), contains('2000'));
  });

  test('requires image by default', () {
    expect(
      const PostDraft(title: 't', description: 'd').validate(),
      contains('image'),
    );
  });

  test('image is optional when requireImage=false (edit path)', () {
    expect(
      const PostDraft(title: 't', description: 'd')
          .validate(requireImage: false),
      isNull,
    );
  });

  test('valid draft returns null', () {
    expect(
      const PostDraft(title: 't', description: 'd', imagePath: '/tmp/x')
          .validate(),
      isNull,
    );
  });
}
