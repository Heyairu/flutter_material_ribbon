import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ribbon/material_ribbon.dart";

void main() {
  testWidgets('header chips and controls share a vertical center', (
    tester,
  ) async {
    for (final width in [390.0, 1200.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: MaterialRibbon(
                  tabs: const [RibbonTab(id: 'home', label: '首頁', groups: [])],
                  context: const RibbonContext(),
                  collapsed: true,
                  leadingCommands: [
                    RibbonCommand(
                      id: 'save',
                      label: 'Save',
                      icon: Icons.save,
                      onInvoke: () {},
                    ),
                    RibbonCommand(
                      id: 'undo',
                      label: 'Undo',
                      icon: Icons.undo,
                      onInvoke: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chipY = tester.getCenter(find.byType(ChoiceChip)).dy;
      for (final button in find.byType(IconButton).evaluate()) {
        expect(
          tester.getCenter(find.byWidget(button.widget)).dy,
          closeTo(chipY, 0.1),
        );
      }
      expect(find.byType(Divider), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets("shows a contextual tab only for an image selection", (
    tester,
  ) async {
    final home = RibbonTab(id: "home", label: "首頁", groups: const []);
    final image = RibbonTab(
      id: "picture",
      label: "圖片格式",
      groups: const [],
      isVisible: (context) => context.selectionType == "image",
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            tabs: [home, image],
            context: const RibbonContext(),
          ),
        ),
      ),
    );
    expect(find.text("圖片格式"), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            tabs: [home, image],
            context: const RibbonContext(
              selectionType: "image",
              selectionCount: 1,
            ),
          ),
        ),
      ),
    );
    expect(find.text("圖片格式"), findsOneWidget);
  });
}
