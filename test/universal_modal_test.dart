import 'package:album_organizer/shared/widgets/universal_modal.dart';
import 'package:album_organizer/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showAction returns true on primary tap', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final future = UniversalModal.showAction(
      capturedContext,
      title: '确认删除照片？',
      content: '照片将移入系统最近删除。',
      primaryBtnText: '删除',
      destructive: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('确认删除照片？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });

  testWidgets('showAction returns false on secondary tap', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final future = UniversalModal.showAction(
      capturedContext,
      title: '开启生物识别保护',
      content: '将调用系统 Face ID。',
      primaryBtnText: '验证并开启',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(await future, isFalse);
  });
}
