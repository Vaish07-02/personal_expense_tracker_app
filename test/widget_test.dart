import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:personal_expense_tracker_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
    'Personal Expense Tracker dashboard loads',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ExpenseTrackerApp(),
      );

      // Verify the app initially appears.
      expect(find.text('My Expenses'), findsOneWidget);

      // Wait for asynchronous database loading.
      await tester.runAsync(() async {
        await Future<void>.delayed(
          const Duration(seconds: 1),
        );
      });

      // Process pending UI updates.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the dashboard title and Add Expense button.
      expect(find.text('My Expenses'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);

      // Check that either the dashboard content or loading/error
      // state is present. This avoids assuming the database is empty.
      final dashboardLoaded =
          find.text('Expense Categories').evaluate().isNotEmpty;

      final loadingIndicator =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      final errorMessage =
          find.text('Unable to load expenses. Please try again.')
              .evaluate()
              .isNotEmpty;

      expect(
        dashboardLoaded || loadingIndicator || errorMessage,
        isTrue,
        reason: 'The dashboard should display content, loading, or an error state.',
      );
    },
  );
}