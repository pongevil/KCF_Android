import 'package:bs_mobile/src/shared/ui/widgets/custom_modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FocusNode focusNode;
  late TextEditingController textController;

  setUp(() {
    focusNode = FocusNode();
    textController = TextEditingController();
  });

  tearDown(() {
    focusNode.dispose();
    textController.dispose();
  });

  Widget buildApp({VoidCallback? onSave}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCustomModalBottomSheet<void>(
              context: context,
              builder: (_) => Material(
                child: ListView(
                  children: [
                    const SizedBox(height: 180),
                    TextField(controller: textController, focusNode: focusNode),
                    const SizedBox(height: 540),
                    TextButton(
                      key: const ValueKey('saveButton'),
                      onPressed: onSave,
                      child: const Text('บันทึก'),
                    ),
                  ],
                ),
              ),
            ),
            child: const Text('เปิด'),
          ),
        ),
      ),
    );
  }

  testWidgets('moves above a 320 px keyboard on a 360 x 640 viewport', (
    tester,
  ) async {
    var saved = false;
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(onSave: () => saved = true));
    await tester.tap(find.text('เปิด'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final animatedPadding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding).last,
    );
    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea).last);
    expect(animatedPadding.padding, const EdgeInsets.only(bottom: 320));
    expect(safeArea.top, isFalse);
    expect(
      tester.getRect(find.byType(TextField)).bottom,
      lessThanOrEqualTo(320),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.byKey(const ValueKey('saveButton')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saveButton')));
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismisses the keyboard when modal content is dragged', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('เปิด'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
