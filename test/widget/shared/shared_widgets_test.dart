import 'package:basic_crud_flutter/core/theme/app_theme.dart';
import 'package:basic_crud_flutter/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Continue', onPressed: () => tapped = true),
      ));
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows progress indicator when loading', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppButton(label: 'Save', isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(const AppButton(label: 'Off')));
      final ElevatedButton btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('AppTextField', () {
    testWidgets('shows label and forwards changes', (tester) async {
      String latest = '';
      await tester.pumpWidget(_wrap(
        AppTextField(label: 'Name', onChanged: (v) => latest = v),
      ));
      expect(find.text('Name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ada');
      expect(latest, 'ada');
    });
  });

  group('AppPasswordField', () {
    testWidgets('obscures by default and toggles on tap', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppPasswordField(label: 'Password'),
      ));
      TextField field = tester.widget(find.byType(TextField));
      expect(field.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      field = tester.widget(find.byType(TextField));
      expect(field.obscureText, isFalse);
    });
  });

  group('AppCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppCard(child: Text('inner')),
      ));
      expect(find.text('inner'), findsOneWidget);
    });
  });

  group('FeatureCard', () {
    testWidgets('invokes onTap and shows title', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        FeatureCard(
          title: 'Mountains',
          subtitle: 'Browse peaks',
          icon: Icons.landscape,
          onTap: () => tapped = true,
        ),
      ));
      expect(find.text('Mountains'), findsOneWidget);
      expect(find.text('Browse peaks'), findsOneWidget);
      await tester.tap(find.byType(FeatureCard));
      expect(tapped, isTrue);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows spinner when isLoading=true', (tester) async {
      await tester.pumpWidget(_wrap(
        const LoadingOverlay(
          isLoading: true,
          child: Text('content'),
        ),
      ));
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides spinner when isLoading=false', (tester) async {
      await tester.pumpWidget(_wrap(
        const LoadingOverlay(
          isLoading: false,
          child: Text('content'),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('EmptyState', () {
    testWidgets('renders message and optional action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        EmptyState(
          message: 'No trips yet',
          actionLabel: 'Add',
          onAction: () => tapped = true,
        ),
      ));
      expect(find.text('No trips yet'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(tapped, isTrue);
    });

    testWidgets('omits button when no action provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'Empty'),
      ));
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('ErrorView', () {
    testWidgets('shows message and retry button', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(
        ErrorView(
          message: 'Boom',
          onRetry: () => retried = true,
        ),
      ));
      expect(find.text('Boom'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('ThemedAppBar', () {
    testWidgets('is a PreferredSize widget with title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: const ThemedAppBar(title: 'Home'),
          body: const SizedBox.shrink(),
        ),
      ));
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
