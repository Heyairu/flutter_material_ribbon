import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ribbon/material_ribbon.dart";

void main() {
  testWidgets('font and size fields have matching borders', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Row(children: [
      RibbonFontPicker(fonts: const ['Arial'], value: 'Arial', onChanged: (_) {}),
      RibbonSpinBox(value: 12, onChanged: (_) {}),
    ]))));
    final borders = find.byType(InputDecorator);
    expect(borders, findsNWidgets(2));
    final fontRect = tester.getRect(borders.at(0));
    final sizeRect = tester.getRect(borders.at(1));
    expect(fontRect.top, sizeRect.top);
    expect(fontRect.height, 40);
    expect(sizeRect.height, 40);
    // Compare the painted input containers, not just the outer form boxes.
    final fields = find.byType(EditableText);
    final fontContainer = InputDecorator.containerOf(tester.element(fields.at(0)))!;
    final sizeContainer = InputDecorator.containerOf(tester.element(fields.at(1)))!;
    expect(fontContainer.size.height, sizeContainer.size.height);
    expect(fontContainer.localToGlobal(Offset.zero).dy,
        sizeContainer.localToGlobal(Offset.zero).dy);
    final texts = find.byType(EditableText);
    expect(texts, findsNWidgets(2));
    expect(tester.getRect(texts.at(0)).top, tester.getRect(texts.at(1)).top);
    expect(tester.getRect(texts.at(0)).height, tester.getRect(texts.at(1)).height);
    expect(tester.takeException(), isNull);
  });
  testWidgets('gallery previews on hover, restores on exit, and selects a cell', (tester) async {
    String? preview;
    var previewEnded = false;
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 180, child: RibbonGallery<String>(
      items: const [
        RibbonGalleryItem(value: 'normal', label: '標準', preview: Text('Aa')),
        RibbonGalleryItem(value: 'heading', label: '標題 1', preview: Text('Aa', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      columns: 2,
      onPreview: (value) => preview = value,
      onPreviewEnd: () => previewEnded = true,
      onSelected: (value) => selected = value,
    )))));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.text('標題 1')));
    await tester.pump();
    expect(preview, 'heading');
    await tester.tap(find.text('標題 1').first);
    expect(selected, 'heading');
    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();
    expect(previewEnded, isTrue);
  });

  testWidgets('spin box increments within its bounds', (tester) async {
    var value = 12.0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(builder: (context, setState) => RibbonSpinBox(
      value: value, min: 8, max: 13, label: 'pt', onChanged: (next) => setState(() => value = next),
    )))));
    await tester.tap(find.byTooltip('Increase pt'));
    expect(value, 13);
    expect(find.byTooltip('Increase pt'), findsOneWidget);
  });

  testWidgets('colour palette opens as a fixed gallery, not a nested scroll view', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RibbonColorPicker(
      colors: const [Colors.black, Colors.red, Colors.blue],
      value: Colors.black,
      onChanged: (_) {},
    ))));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('embedded gallery keeps all cells on the same row', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 176, child: RibbonGallery<String>(
      items: const [
        RibbonGalleryItem(value: 'normal', label: '標準', preview: Text('Aa')),
        RibbonGalleryItem(value: 'heading', label: '標題 1', preview: Text('Bb')),
        RibbonGalleryItem(value: 'quote', label: '引用', preview: Text('Cc')),
      ],
      columns: 3,
      cellSize: const Size(54, 48),
      padding: EdgeInsets.zero,
      onSelected: (_) {},
    )))));
    final cellTops = ['標準', '標題 1', '引用']
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(cellTops.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick access and tabs share a vertical center', (
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
      final tabY = tester.getCenter(find.text('首頁')).dy;
      for (final button in find.byType(IconButton).evaluate()) {
        expect(
          tester.getCenter(find.byWidget(button.widget)).dy,
          closeTo(tabY, 0.1),
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
  testWidgets('renders a group launcher and command state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: '首頁',
                groups: [
                  RibbonGroup(
                    label: '字型',
                    onMoreOptions: () {},
                    commands: [
                      RibbonCommand(
                        id: 'bold',
                        label: '粗體',
                        icon: Icons.format_bold,
                        onInvoke: () {},
                        type: RibbonCommandType.toggle,
                        checkState: (_) => RibbonCheckState.checked,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byTooltip('更多選項'), findsOneWidget);
    expect(find.bySemanticsLabel('粗體'), findsOneWidget);
  });
}
