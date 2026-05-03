import 'package:basic_crud_flutter/features/offline_maps/domain/entities/download_progress.dart';
import 'package:basic_crud_flutter/features/offline_maps/presentation/view/widgets/download_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required DownloadProgress progress,
    required VoidCallback onCancel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DownloadProgressDialog(
            progress: progress,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }

  testWidgets('renders tile counts and progress bar', (tester) async {
    await pump(
      tester,
      progress: const DownloadProgress(
        regionId: 'r1',
        tilesDone: 30,
        tilesTotal: 100,
        bytesDone: 1024 * 1024,
        isComplete: false,
      ),
      onCancel: () {},
    );
    expect(find.textContaining('30'), findsWidgets);
    expect(find.textContaining('100'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('Cancel button invokes callback', (tester) async {
    var cancelled = false;
    await pump(
      tester,
      progress: const DownloadProgress(
        regionId: 'r1',
        tilesDone: 0,
        tilesTotal: 10,
        bytesDone: 0,
        isComplete: false,
      ),
      onCancel: () => cancelled = true,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(cancelled, isTrue);
  });
}
