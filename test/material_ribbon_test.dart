import 'dart:async';

import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ribbon/material_ribbon.dart";

void main() {
  testWidgets('RibbonPopup provides a reusable standard popup surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonPopup(
            menuChildren: const [
              SizedBox(width: 120, child: Text('Popup content')),
            ],
            builder: (context, controller, child) => TextButton(
              onPressed: controller.open,
              child: const Text('Open popup'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open popup'));
    await tester.pumpAndSettle();

    expect(find.text('Popup content'), findsOneWidget);
    final anchor = tester.widget<MenuAnchor>(find.byType(MenuAnchor));
    expect(anchor.clipBehavior, Clip.antiAlias);
    expect(anchor.style?.elevation?.resolve(<WidgetState>{}), 4);
  });

  testWidgets(
    'RibbonCol stacks up to three children and RibbonRowGrid wraps after three columns',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RibbonCol(
                  children: [
                    SizedBox(key: ValueKey('col-1'), width: 10, height: 10),
                    SizedBox(key: ValueKey('col-2'), width: 10, height: 10),
                    SizedBox(key: ValueKey('col-3'), width: 10, height: 10),
                  ],
                ),
                RibbonRowGrid(
                  children: [
                    SizedBox(key: ValueKey('row-1'), width: 10, height: 10),
                    SizedBox(key: ValueKey('row-2'), width: 10, height: 10),
                    SizedBox(key: ValueKey('row-3'), width: 10, height: 10),
                    SizedBox(key: ValueKey('row-4'), width: 10, height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('col-2'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('col-1'))).dy),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('col-3'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('col-2'))).dy),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('row-2'))).dx,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dx),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('row-3'))).dx,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('row-2'))).dx),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('row-4'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dy),
      );
    },
  );

  testWidgets('RibbonCol rejects more than three children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RibbonCol(
          children: [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('gallery and large controls use proportional heights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'Large',
                    commands: [
                      for (final type in [
                        RibbonCommandType.action,
                        RibbonCommandType.menu,
                        RibbonCommandType.split,
                      ])
                        RibbonCommand(
                          id: type.name,
                          label: type.name,
                          icon: Icons.add,
                          size: RibbonCommandSize.large,
                          type: type,
                          onInvoke: () {},
                        ),
                    ],
                  ),
                  RibbonGroup(
                    label: 'Gallery command',
                    commands: [
                      RibbonCommand(
                        id: 'gallery-command',
                        label: 'gallery-command',
                        icon: Icons.style,
                        type: RibbonCommandType.gallery,
                        onInvoke: () {},
                      ),
                    ],
                  ),
                  RibbonGroup(
                    label: 'Gallery',
                    controls: [
                      RibbonFeaturedGallery<int>(
                        items: const [
                          RibbonGalleryItem(value: 1, label: 'Featured 1'),
                          RibbonGalleryItem(value: 2, label: 'Featured 2'),
                          RibbonGalleryItem(value: 3, label: 'Featured 3'),
                          RibbonGalleryItem(value: 4, label: 'Featured 4'),
                          RibbonGalleryItem(value: 5, label: 'Featured 5'),
                          RibbonGalleryItem(value: 6, label: 'Featured 6'),
                          RibbonGalleryItem(value: 7, label: 'Featured 7'),
                        ],
                        featuredValues: const [1, 2, 3, 4, 5, 6, 7],
                        onSelected: (_) {},
                      ),
                      RibbonGallery<int>(
                        items: const [
                          RibbonGalleryItem(value: 1, label: 'Cell'),
                        ],
                        columns: 1,
                        onSelected: (_) {},
                      ),
                      const Column(
                        key: ValueKey('custom-control-column'),
                        children: [SizedBox(height: 40), SizedBox(height: 40)],
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
    for (final label in ['action', 'menu', 'split']) {
      final button = find
          .ancestor(of: find.text(label), matching: find.byType(TextButton))
          .first;
      expect(tester.getSize(button).height, 120);
    }
    final largeIcon = tester.widget<Icon>(find.byIcon(Icons.add).first);
    expect(largeIcon.size, 40);
    final galleryButton = find
        .ancestor(
          of: find.text('gallery-command'),
          matching: find.byType(TextButton),
        )
        .first;
    expect(tester.getSize(galleryButton).height, 40);
    final largeButton = find
        .ancestor(of: find.text('action'), matching: find.byType(TextButton))
        .first;
    expect(
      tester.getTopLeft(galleryButton).dy,
      tester.getTopLeft(largeButton).dy,
    );
    expect(tester.getSize(find.byType(RibbonFeaturedGallery<int>)).height, 120);
    final featuredCell = find
        .ancestor(
          of: find.text('Featured 1'),
          matching: find.byType(TextButton),
        )
        .first;
    expect(tester.getSize(featuredCell).height, 60);
    final featured1 = tester.getTopLeft(find.text('Featured 1'));
    final featured2 = tester.getTopLeft(find.text('Featured 2'));
    final featured3 = tester.getTopLeft(find.text('Featured 3'));
    final featured4 = tester.getTopLeft(find.text('Featured 4'));
    expect(featured2.dy, featured1.dy);
    expect(featured2.dx, greaterThan(featured1.dx));
    expect(featured3.dy, featured1.dy);
    expect(featured3.dx, greaterThan(featured2.dx));
    expect(featured4.dx, featured1.dx);
    expect(featured4.dy, greaterThan(featured1.dy));
    expect(find.text('Featured 7'), findsNothing);
    final cell = find
        .ancestor(of: find.text('Cell'), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(cell).height, 60);
    expect(
      tester.getTopLeft(find.byType(RibbonGallery<int>)).dy,
      tester.getTopLeft(find.byType(RibbonFeaturedGallery<int>)).dy,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('custom-control-column')))
          .height,
      80,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('custom-control-column'))).dy,
      tester.getTopLeft(find.byType(RibbonFeaturedGallery<int>)).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('group selection controls retain full row hit targets', (
    tester,
  ) async {
    bool? checked;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'Selection',
                    rows: 1,
                    controls: [
                      Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (value) => checked = value,
                          ),
                          RadioGroup<int>(
                            groupValue: 1,
                            onChanged: (_) {},
                            child: const Radio<int>(value: 1),
                          ),
                        ],
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
    expect(tester.getSize(find.byType(Checkbox)).height, 40);
    expect(tester.getSize(find.byType(Radio<int>)).height, 40);
    await tester.tapAt(
      tester.getTopLeft(find.byType(Checkbox)) + const Offset(2, 2),
    );
    expect(checked, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-row controls share a 40px height across densities', (
    tester,
  ) async {
    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(visualDensity: density),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RibbonChip(label: 'Chip', onPressed: () {}),
                  RibbonTextBox(value: 'Text', onChanged: (_) {}),
                  RibbonComboBox<String>(
                    items: const [RibbonComboBoxItem(value: 'a', label: 'A')],
                    value: 'a',
                    onChanged: (_) {},
                  ),
                  RibbonSpinBox(value: 12, onChanged: (_) {}),
                  RibbonColorPicker(
                    colors: const [Colors.black],
                    value: Colors.black,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(TextButton)).height, 40);
      for (final field in find.byType(InputDecorator).evaluate()) {
        expect(tester.getSize(find.byWidget(field.widget)).height, 40);
        final editable = find.descendant(
          of: find.byWidget(field.widget),
          matching: find.byType(EditableText),
        );
        final container = InputDecorator.containerOf(tester.element(editable))!;
        expect(container.size.height, 40);
        expect(
          container.localToGlobal(Offset.zero).dy,
          tester.getTopLeft(find.byWidget(field.widget)).dy,
        );
      }
      expect(tester.getSize(find.byType(IconButton).last).height, 40);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'a customized empty quick access toolbar does not use program defaults',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialRibbon(
              context: const RibbonContext(),
              personalization: const RibbonPersonalization(
                quickAccessCustomized: true,
              ),
              quickAccessCommands: [
                RibbonCommand(
                  id: 'save',
                  label: '儲存',
                  icon: Icons.save,
                  onInvoke: () {},
                ),
              ],
              tabs: const [RibbonTab(id: 'home', label: '首頁', groups: [])],
            ),
          ),
        ),
      );
      expect(find.byTooltip('儲存'), findsNothing);
    },
  );

  testWidgets('renders a Backstage chip inside the ribbon tab scroll area', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            onBackstagePressed: () => opened = true,
            backstageLabel: '開啟 Backstage',
            tabs: const [RibbonTab(id: 'home', label: '首頁', groups: [])],
          ),
        ),
      ),
    );

    final chip = find.bySemanticsLabel('開啟 Backstage');
    expect(chip, findsOneWidget);
    expect(tester.getCenter(chip).dy, lessThan(48));
    expect(
      find.ancestor(
        of: chip,
        matching: find.byType(RibbonHorizontalScrollView),
      ),
      findsOneWidget,
    );
    await tester.tap(chip);
    expect(opened, isTrue);
  });

  testWidgets(
    'customization panel changes visible tabs and quick access commands',
    (tester) async {
      RibbonPersonalization value = const RibbonPersonalization();
      final tabs = const [
        RibbonTab(id: 'home', label: '首頁', groups: []),
        RibbonTab(id: 'view', label: '檢視', groups: []),
      ];
      final command = RibbonCommand(
        id: 'save',
        label: '儲存',
        icon: Icons.save,
        onInvoke: () {},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RibbonCustomizationPanel(
                tabs: tabs,
                commands: [command],
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('儲存'));
      expect(value.quickAccessCommandIds, ['save']);
      await tester.tap(find.byType(Checkbox).at(1));
      expect(value.hiddenTabIds, {'view'});
      await tester.tap(find.byTooltip('下移 首頁'));
      expect(value.tabOrder, ['view', 'home']);
    },
  );

  testWidgets('key tips scope commands to the selected tab', (tester) async {
    var homeInvoked = false;
    var insertInvoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: '首頁',
                keyTip: 'H',
                groups: [
                  RibbonGroup(
                    label: 'Home',
                    commands: [
                      RibbonCommand(
                        id: 'paste',
                        label: '貼上',
                        icon: Icons.paste,
                        keyTip: 'P',
                        onInvoke: () => homeInvoked = true,
                      ),
                    ],
                  ),
                ],
              ),
              RibbonTab(
                id: 'insert',
                label: '插入',
                keyTip: 'N',
                groups: [
                  RibbonGroup(
                    label: 'Insert',
                    commands: [
                      RibbonCommand(
                        id: 'picture',
                        label: '圖片',
                        icon: Icons.image,
                        keyTip: 'P',
                        onInvoke: () => insertInvoked = true,
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

    await tester.tap(find.text('首頁'));
    await tester.sendKeyEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    expect(find.text('插入'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    expect(insertInvoked, isTrue);
    expect(homeInvoked, isFalse);
  });

  testWidgets('application shortcuts invoke their configured action', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            shortcuts: [
              RibbonShortcut(
                id: 'save',
                activator: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                ),
                onInvoke: () => saved = true,
              ),
            ],
            tabs: const [RibbonTab(id: 'home', label: '首頁', groups: [])],
          ),
        ),
      ),
    );
    await tester.tap(find.text('首頁'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(saved, isTrue);
  });

  testWidgets('chip reports selection changes and exposes custom behaviour', (
    tester,
  ) async {
    bool? selected;
    var pressed = false;
    var longPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonChip(
            label: '列印',
            icon: const Icon(Icons.print_outlined),
            selected: false,
            tooltip: '列印文件',
            onPressed: () => pressed = true,
            onSelected: (value) => selected = value,
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('列印'), findsOneWidget);
    expect(find.byTooltip('列印文件'), findsOneWidget);
    await tester.tap(find.text('列印'));
    expect(pressed, isTrue);
    expect(selected, isTrue);
    await tester.longPress(find.text('列印'));
    expect(longPressed, isTrue);
  });

  testWidgets('chip disables its action while retaining its selected state', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonChip(
            label: '資訊',
            selected: true,
            enabled: false,
            onPressed: () => called = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('資訊'));
    expect(called, isFalse);
  });

  testWidgets('chip selection behaviour is controlled by the host', (
    tester,
  ) async {
    bool? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonChip(
            label: 'Open Backstage',
            selected: false,
            selectionBehavior: RibbonChipSelectionBehavior.preserve,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Backstage'));
    expect(selected, isFalse);
  });

  testWidgets('font and size fields have matching borders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              RibbonFontPicker(
                fonts: const ['Arial'],
                value: 'Arial',
                onChanged: (_) {},
              ),
              RibbonSpinBox(value: 12, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    final borders = find.byType(InputDecorator);
    expect(borders, findsNWidgets(2));
    final fontRect = tester.getRect(borders.at(0));
    final sizeRect = tester.getRect(borders.at(1));
    expect(fontRect.top, sizeRect.top);
    expect(fontRect.height, 40);
    expect(sizeRect.height, 40);
    // Compare the painted input containers, not just the outer form boxes.
    final fields = find.byType(EditableText);
    final fontContainer = InputDecorator.containerOf(
      tester.element(fields.at(0)),
    )!;
    final sizeContainer = InputDecorator.containerOf(
      tester.element(fields.at(1)),
    )!;
    expect(fontContainer.size.height, sizeContainer.size.height);
    expect(
      fontContainer.localToGlobal(Offset.zero).dy,
      sizeContainer.localToGlobal(Offset.zero).dy,
    );
    final texts = find.byType(EditableText);
    expect(texts, findsNWidgets(2));
    expect(tester.getRect(texts.at(0)).top, tester.getRect(texts.at(1)).top);
    expect(
      tester.getRect(texts.at(0)).height,
      tester.getRect(texts.at(1)).height,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'gallery previews on hover, restores on exit, and selects a cell',
    (tester) async {
      String? preview;
      var previewEnded = false;
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: RibbonGallery<String>(
                items: const [
                  RibbonGalleryItem(
                    value: 'normal',
                    label: '標準',
                    preview: Text('Aa'),
                  ),
                  RibbonGalleryItem(
                    value: 'heading',
                    label: '標題 1',
                    preview: Text(
                      'Aa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                columns: 2,
                onPreview: (value) => preview = value,
                onPreviewEnd: () => previewEnded = true,
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      );

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
    },
  );

  testWidgets('spin box increments within its bounds', (tester) async {
    var value = 12.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RibbonSpinBox(
              value: value,
              min: 8,
              max: 13,
              label: 'pt',
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Increase pt'));
    expect(value, 13);
    expect(find.byTooltip('Increase pt'), findsOneWidget);
  });

  testWidgets(
    'colour palette opens as a fixed gallery, not a nested scroll view',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RibbonColorPicker(
              colors: const [Colors.black, Colors.red, Colors.blue],
              value: Colors.black,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
    },
  );

  testWidgets('embedded gallery keeps all cells on the same row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 176,
            child: RibbonGallery<String>(
              items: const [
                RibbonGalleryItem(
                  value: 'normal',
                  label: '標準',
                  preview: Text('Aa'),
                ),
                RibbonGalleryItem(
                  value: 'heading',
                  label: '標題 1',
                  preview: Text('Bb'),
                ),
                RibbonGalleryItem(
                  value: 'quote',
                  label: '引用',
                  preview: Text('Cc'),
                ),
              ],
              columns: 3,
              cellSize: const Size(54, 48),
              padding: EdgeInsets.zero,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    final cellTops = [
      '標準',
      '標題 1',
      '引用',
    ].map((label) => tester.getTopLeft(find.text(label)).dy).toList();
    expect(cellTops.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('featured gallery selects visible items and expands all items', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonFeaturedGallery<String>(
            items: const [
              RibbonGalleryItem(
                value: 'normal',
                label: '標準',
                preview: Text('Aa'),
              ),
              RibbonGalleryItem(
                value: 'heading',
                label: '標題 1',
                preview: Text('Bb'),
              ),
              RibbonGalleryItem(
                value: 'code',
                label: '程式碼',
                preview: Text('code'),
              ),
            ],
            featuredValues: const ['normal', 'heading'],
            moreTooltip: '更多樣式',
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('標準'));
    expect(selected, 'normal');
    await tester.tap(find.byTooltip('更多樣式'));
    await tester.pumpAndSettle();
    expect(find.text('程式碼'), findsOneWidget);
    await tester.tap(find.text('程式碼'));
    expect(selected, 'code');
  });

  testWidgets('quick access and tabs share a vertical center', (tester) async {
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
    expect(find.byTooltip('More options'), findsOneWidget);
    expect(find.bySemanticsLabel('粗體'), findsOneWidget);
  });

  testWidgets('compact mode uses explicitly configured compact commands', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            compact: true,
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                compactCommands: [
                  RibbonCommand(
                    id: 'compact',
                    label: 'Compact',
                    icon: Icons.compress,
                    onInvoke: () {},
                  ),
                ],
                groups: [
                  RibbonGroup(
                    label: 'Source',
                    commands: [
                      RibbonCommand(
                        id: 'large',
                        label: 'Large',
                        icon: Icons.add,
                        size: RibbonCommandSize.large,
                        onInvoke: () {},
                      ),
                      RibbonCommand(
                        id: 'small',
                        label: 'Small',
                        icon: Icons.remove,
                        size: RibbonCommandSize.small,
                        onInvoke: () {},
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

    expect(find.bySemanticsLabel('Compact'), findsOneWidget);
    expect(find.text('Large'), findsNothing);
    expect(find.text('Small'), findsNothing);
  });

  testWidgets(
    'compact mode derives commands and shrinks medium buttons when unconfigured',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialRibbon(
              compact: true,
              context: const RibbonContext(),
              tabs: [
                RibbonTab(
                  id: 'home',
                  label: 'Home',
                  groups: [
                    RibbonGroup(
                      label: 'Source',
                      commands: [
                        RibbonCommand(
                          id: 'large',
                          label: 'Large',
                          icon: Icons.add,
                          size: RibbonCommandSize.large,
                          onInvoke: () {},
                        ),
                        RibbonCommand(
                          id: 'medium',
                          label: 'Medium',
                          icon: Icons.drag_handle,
                          onInvoke: () {},
                        ),
                        RibbonCommand(
                          id: 'small',
                          label: 'Small',
                          icon: Icons.remove,
                          size: RibbonCommandSize.small,
                          onInvoke: () {},
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

      expect(find.text('Large'), findsOneWidget);
      expect(find.bySemanticsLabel('Small'), findsOneWidget);
      expect(find.bySemanticsLabel('Medium'), findsOneWidget);
      expect(find.text('Medium'), findsNothing);
      expect(
        find.ancestor(
          of: find.byIcon(Icons.drag_handle),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('external controllers select tabs and drive KeyTip state', (
    tester,
  ) async {
    final ribbon = RibbonController();
    final keyTips = RibbonKeyTipController();
    final selected = <String>[];
    final states = <RibbonKeyTipState>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            controller: ribbon,
            keyTipController: keyTips,
            onSelectedTabChanged: selected.add,
            onKeyTipStateChanged: states.add,
            context: const RibbonContext(),
            tabs: const [
              RibbonTab(id: 'home', label: 'Home', keyTip: 'H', groups: []),
              RibbonTab(id: 'view', label: 'View', keyTip: 'V', groups: []),
            ],
          ),
        ),
      ),
    );

    ribbon.selectTab('view');
    await tester.pump();
    expect(selected, ['view']);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'View'))
          .selected,
      isTrue,
    );

    keyTips.showHeader();
    await tester.pump();
    expect(keyTips.value.level, RibbonKeyTipLevel.header);
    expect(states.last.level, RibbonKeyTipLevel.header);
    expect(find.text('H'), findsOneWidget);
  });

  testWidgets('gallery selection is dispatched with source, tab, and value', (
    tester,
  ) async {
    CommandInvocation? invocation;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            onCommandInvoked: (event) => invocation = event,
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'Styles',
                    commands: [
                      RibbonCommand(
                        id: 'style',
                        label: 'Style',
                        icon: Icons.style,
                        type: RibbonCommandType.gallery,
                        onInvoke: () {},
                        galleryItems: const [
                          RibbonGalleryItem(value: 'heading', label: 'Heading'),
                        ],
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

    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heading'));
    await tester.pumpAndSettle();
    expect(invocation?.commandId, 'style');
    expect(invocation?.source, RibbonInvocationSource.gallery);
    expect(invocation?.tabId, 'home');
    expect(invocation?.value, 'heading');
  });

  testWidgets('async commands expose busy state and ignore reentry', (
    tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'File',
                    commands: [
                      RibbonCommand(
                        id: 'save',
                        label: 'Save',
                        icon: Icons.save,
                        onInvoked: (_) {
                          calls++;
                          return completer.future;
                        },
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

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Save'));
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('shortcut registry reports conflicts and supports removal', () {
    final first = RibbonShortcut(
      id: 'save',
      activator: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
      onInvoke: () {},
    );
    final second = RibbonShortcut(
      id: 'save-as',
      activator: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
      onInvoke: () {},
    );
    final registry = RibbonShortcutRegistry([first]);
    expect(registry.register(second), same(first));
    expect(registry.unregister('save'), isTrue);
    expect(registry.conflictFor(second.activator), same(second));
  });

  testWidgets('matching shortcuts use unified command dispatch', (
    tester,
  ) async {
    CommandInvocation? invocation;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            autofocus: true,
            context: const RibbonContext(),
            onCommandInvoked: (event) => invocation = event,
            shortcuts: [
              RibbonShortcut(
                id: 'save',
                activator: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                ),
                onInvoke: () {},
              ),
            ],
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'File',
                    commands: [
                      RibbonCommand(
                        id: 'save',
                        label: 'Save',
                        icon: Icons.save,
                        onInvoke: () {},
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(invocation?.commandId, 'save');
    expect(invocation?.source, RibbonInvocationSource.shortcut);
  });

  test('personalization JSON round-trips and migrates legacy data', () {
    const value = RibbonPersonalization(
      quickAccessCommandIds: ['save'],
      quickAccessCustomized: true,
      tabOrder: ['view', 'home'],
      hiddenTabIds: {'debug'},
    );
    final decoded = RibbonPersonalization.fromJson(value.toJson());
    expect(decoded.schemaVersion, RibbonPersonalization.currentSchemaVersion);
    expect(decoded.quickAccessCommandIds, ['save']);
    expect(decoded.quickAccessCustomized, isTrue);
    expect(decoded.tabOrder, ['view', 'home']);
    expect(decoded.hiddenTabIds, {'debug'});

    final migrated = RibbonPersonalization.fromJson(
      {
        'schemaVersion': 0,
        'qat': <Object?>['print'],
      },
      migration: (version, json) {
        expect(version, 0);
        return {'quickAccessCommandIds': json['qat']};
      },
    );
    expect(migrated.schemaVersion, RibbonPersonalization.currentSchemaVersion);
    expect(migrated.quickAccessCommandIds, ['print']);
  });

  testWidgets('layout mode reports the configurable breakpoint', (
    tester,
  ) async {
    final modes = <RibbonLayoutMode>[];
    Widget ribbon(double width) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: MaterialRibbon(
            compactBreakpoint: 500,
            onLayoutModeChanged: modes.add,
            context: const RibbonContext(),
            tabs: const [RibbonTab(id: 'home', label: 'Home', groups: [])],
          ),
        ),
      ),
    );

    await tester.pumpWidget(ribbon(400));
    await tester.pump();
    expect(modes, [RibbonLayoutMode.compact]);
    await tester.pumpWidget(ribbon(600));
    await tester.pump();
    expect(modes.last, RibbonLayoutMode.expanded);
  });

  testWidgets('host localizations replace built-in ribbon strings', (
    tester,
  ) async {
    const strings = RibbonLocalizations(
      expandRibbon: 'Open commands',
      collapseRibbon: 'Close commands',
      ribbonTabs: 'Document sections',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            localizations: strings,
            context: const RibbonContext(),
            tabs: const [RibbonTab(id: 'home', label: 'Home', groups: [])],
          ),
        ),
      ),
    );
    expect(find.byTooltip('Close commands'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Document sections')), findsOneWidget);
  });

  testWidgets(
    'external scroll controllers and controller targets move ribbon content',
    (tester) async {
      final ribbon = RibbonController();
      final header = ScrollController();
      final body = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MaterialRibbon(
                compact: false,
                controller: ribbon,
                headerScrollController: header,
                bodyScrollController: body,
                context: const RibbonContext(),
                tabs: [
                  for (var i = 0; i < 8; i++)
                    RibbonTab(
                      id: 'tab-$i',
                      label: 'Long tab $i',
                      groups: i == 0
                          ? [
                              for (var g = 0; g < 4; g++)
                                RibbonGroup(
                                  id: 'group-$g',
                                  label: 'Group $g',
                                  width: 220,
                                ),
                            ]
                          : const [],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(header.hasClients, isTrue);
      expect(body.hasClients, isTrue);

      final tabScroll = ribbon.scrollToTab('tab-7');
      await tester.pumpAndSettle();
      await tabScroll;
      expect(header.offset, greaterThan(0));
      final groupScroll = ribbon.scrollToGroup('group-3', tabId: 'tab-0');
      await tester.pumpAndSettle();
      await groupScroll;
      expect(body.offset, greaterThan(0));
    },
  );

  test('personalization validation removes stale and duplicate IDs', () {
    const preferences = RibbonPersonalization(
      quickAccessCommandIds: ['save', 'missing', 'save'],
      quickAccessCustomized: true,
      tabOrder: ['view', 'missing', 'view'],
      hiddenTabIds: {'home', 'missing'},
    );
    final valid = preferences.validated(
      commandIds: ['save'],
      tabIds: ['home', 'view'],
    );
    expect(valid.quickAccessCommandIds, ['save']);
    expect(valid.tabOrder, ['view']);
    expect(valid.hiddenTabIds, {'home'});
    expect(RibbonPersonalization.defaults.quickAccessCustomized, isFalse);
  });

  test('localization delegate resolves Traditional Chinese', () async {
    final strings = await RibbonLocalizations.delegate.load(const Locale('zh'));
    expect(strings.moreOptions, '更多選項');
  });

  testWidgets('command feedback reports its full successful lifecycle', (
    tester,
  ) async {
    final feedback = <RibbonCommandFeedbackType>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialRibbon(
            context: const RibbonContext(),
            onCommandFeedback: (event) => feedback.add(event.type),
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                groups: [
                  RibbonGroup(
                    label: 'File',
                    commands: [
                      RibbonCommand(
                        id: 'save',
                        label: 'Save',
                        icon: Icons.save,
                        onInvoke: () {},
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
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      feedback,
      [RibbonCommandFeedbackType.started, RibbonCommandFeedbackType.succeeded],
    );
  });
}
