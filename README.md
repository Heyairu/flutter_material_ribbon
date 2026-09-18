# Material Ribbon

Material 3 ribbon components for Flutter desktop, web, phone, and adaptive layouts. `material_ribbon` provides an Office-inspired command surface built from tabs, groups, commands, galleries, and compact form controls.

## Features

- Material 3 ribbon tabs with horizontal scrolling for constrained widths.
- Contextual tabs that appear only for a matching editor selection.
- Small, medium, and large commands, including action, toggle, menu, split, and gallery variants.
- A customizable Quick Access Toolbar, optional persistence, and optional command search.
- Keyboard key tips (`Alt`, `F10`, or a tab/command key tip) and `Ctrl+F1` to collapse or expand the ribbon.
- Host-controlled tabs, KeyTips, focus, shortcut registration, and unified async command dispatch.
- Ribbon-ready gallery, colour picker, combo box, font picker, text box, and spin box controls.
- An adaptive compact layout below 720 logical pixels, or whenever `compact` is set explicitly.

## Installation

```sh
flutter pub add material_ribbon
```

```dart
import 'package:material_ribbon/material_ribbon.dart';
```

## Quick start

`MaterialRibbon` is controlled by the host: provide current editor state in `RibbonContext` and update state from callbacks.

```dart
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _collapsed = false;
  String? _selectionType;

  @override
  Widget build(BuildContext context) {
    final ribbonContext = RibbonContext(
      selectionType: _selectionType,
      selectionCount: _selectionType == null ? 0 : 1,
    );

    return Scaffold(
      body: Column(
        children: [
          MaterialRibbon(
            context: ribbonContext,
            collapsed: _collapsed,
            onCollapsedChanged: (value) => setState(() => _collapsed = value),
            quickAccessCommands: [
              RibbonCommand(
                id: 'save',
                label: 'Save',
                icon: Icons.save_outlined,
                shortcut: 'Ctrl+S',
                keyTip: 'S',
                onInvoke: () {/* save the document */},
              ),
            ],
            tabs: [
              RibbonTab(
                id: 'home',
                label: 'Home',
                keyTip: 'H',
                groups: [
                  RibbonGroup(
                    label: 'Clipboard',
                    commands: [
                      RibbonCommand(
                        id: 'paste',
                        label: 'Paste',
                        icon: Icons.content_paste_outlined,
                        size: RibbonCommandSize.large,
                        onInvoke: () {/* paste */},
                      ),
                    ],
                  ),
                ],
              ),
              RibbonTab(
                id: 'picture-format',
                label: 'Picture Format',
                isVisible: (value) => value.selectionType == 'image',
                groups: const [],
              ),
            ],
          ),
          const Expanded(child: Placeholder()),
        ],
      ),
    );
  }
}
```

## External control

```dart
final ribbon = RibbonController();
final keyTips = RibbonKeyTipController();

MaterialRibbon(
  controller: ribbon,
  keyTipController: keyTips,
  selectedTabId: selectedTabId,
  onSelectedTabChanged: (id) => setState(() => selectedTabId = id),
  onCommandInvoked: (event) async {
    // Central logging, permissions, IPC, undo/redo, and async work.
    await dispatch(event.commandId, value: event.value);
  },
  onCommandError: (event, error, stackTrace) => report(error, stackTrace),
  context: ribbonContext,
  tabs: tabs,
)
```

Gallery choices arrive in `CommandInvocation.value`. While an async dispatch is running, the command displays a progress indicator and ignores reentry by default. Custom header or control actions can register through `RibbonKeyTipTarget`; dynamic menus and popup lifecycle use `menuBuilder`, `onMenuOpen`, and `onMenuClose`.

## Commands and groups

Use `RibbonCommand` for each operation and place commands in a `RibbonGroup`. Large commands span the group command height; small and medium commands tile vertically. `rows` controls the number of command rows (from 1 through 3).

```dart
RibbonGroup(
  label: 'Paragraph',
  rows: 2,
  commands: [
    RibbonCommand(
      id: 'bold',
      label: 'Bold',
      icon: Icons.format_bold,
      type: RibbonCommandType.toggle,
      checkState: (_) => isBold
          ? RibbonCheckState.checked
          : RibbonCheckState.unchecked,
      onInvoke: toggleBold,
    ),
    RibbonCommand(
      id: 'align',
      label: 'Align',
      icon: Icons.format_align_left,
      type: RibbonCommandType.menu,
      menuCommands: alignmentCommands,
      onInvoke: () {},
    ),
  ],
)
```

Set `isEnabled`, `isBusy`, and `disabledReason` to derive command state from the current `RibbonContext`. The ribbon disables unavailable or busy commands and displays the reason in their tooltip.

## Contextual tabs

`RibbonTab.isVisible` is evaluated whenever the supplied `RibbonContext` changes, making it suitable for selection-sensitive tooling:

```dart
RibbonTab(
  id: 'table-layout',
  label: 'Table Layout',
  isVisible: (context) => context.selectionType == 'table',
  groups: tableGroups,
)
```

## Backstage navigation chips

`RibbonChip` is a controlled, selectable button for a Backstage-style navigation rail or settings pane. Keep the selected destination in the host, then use `onSelected` to request a new destination. It can also run a normal action with `onPressed`, and exposes hover, focus, long-press, tooltip, and `ButtonStyle` customisation.

```dart
RibbonChip(
  label: '列印',
  icon: const Icon(Icons.print_outlined),
  selected: activeBackstagePage == 'print',
  onSelected: (_) => setState(() => activeBackstagePage = 'print'),
  tooltip: '列印文件',
)
```

## Ribbon controls and galleries

`RibbonGroup.controls` accepts any widget. The package includes compact, controlled widgets intended for this area: `RibbonGallery`, `RibbonFeaturedGallery`, `RibbonColorPicker`, `RibbonComboBox`, `RibbonFontPicker`, `RibbonTextBox`, and `RibbonSpinBox`. Use `RibbonPopup` when a custom ribbon control needs the same popup surface and dismissal behaviour as the built-in galleries and pickers.

For a gallery, `onPreview` is called while a pointer enters a cell and `onPreviewEnd` is called when it leaves the gallery. This lets an editor show a temporary preview and restore the committed value afterwards.

```dart
RibbonColorPicker(
  colors: const [Colors.black, Colors.red, Colors.blue],
  value: committedColor,
  onChanged: (color) => setState(() {
    committedColor = color;
    previewColor = color;
  }),
  onPreview: (color) => setState(() => previewColor = color),
  onPreviewEnd: () => setState(() => previewColor = committedColor),
)
```

Use `RibbonFeaturedGallery` when a few high-frequency values should remain
visible in the ribbon while the expansion button opens every available value:

```dart
RibbonFeaturedGallery<String>(
  items: styleItems,
  featuredValues: const ['Normal', 'Heading 1', 'Quote'],
  selectedValue: selectedStyle,
  onSelected: (value) => setState(() => selectedStyle = value),
)
```

## Quick Access Toolbar and personalization

Pass `quickAccessCommands` to set the default Quick Access Toolbar. The older `leadingCommands` property remains supported as an alias. To allow users to customize the toolbar, provide `onPersonalizationChanged`, a `RibbonPersonalizationStore`, or both. The store is application-owned, so it can use shared preferences, a database, or another persistence mechanism.

`RibbonPersonalization` stores Quick Access command IDs, tab ordering, and hidden tab IDs. Command IDs and tab IDs should therefore be stable and unique.

`quickAccessCommands` is always the program-defined default. To represent a user deliberately removing every QAT command, persist `RibbonPersonalization(quickAccessCustomized: true)`: an empty command-ID list then renders a genuinely empty QAT instead of falling back to the default.

Preferences can be serialized directly with `toJson()` and restored with `RibbonPersonalization.fromJson(...)`. Pass a `migration` callback when loading an older schema:

```dart
final preferences = RibbonPersonalization.fromJson(
  storedJson,
  migration: migrateRibbonPreferences,
);
```

Set `showCustomizationButton: true` to expose a built-in dialog where people can choose Quick Access commands, show or hide tabs, and reorder tabs. The result is sent through the same personalization callback or store.

## Layout, localization, and scrolling

Use `compactBreakpoint` to replace the default 720px breakpoint and `onLayoutModeChanged` to observe the resolved `RibbonLayoutMode`.

Built-in UI defaults to English. Add `RibbonLocalizations.delegate` to the app's `localizationsDelegates` to resolve English or Traditional Chinese from `Locale`; pass `localizations` to `MaterialRibbon` only when a single ribbon needs application-specific wording.

```dart
MaterialApp(
  localizationsDelegates: const [
    RibbonLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('zh', 'TW')],
)
```

External scroll controllers can be supplied through `headerScrollController` and `bodyScrollController`. The ribbon controller can also reveal named content:

```dart
ribbonController.scrollToTab('view');
ribbonController.scrollToGroup('paragraph', tabId: 'home');
```

Set a stable `RibbonGroup.id` when using `scrollToGroup`; the group label remains a compatibility fallback.

## Keyboard and accessibility

The ribbon is a focus traversal group with semantic labels for tabs, groups, and the active command surface. Use `Alt` or `F10` to open header KeyTips, choose a tab's key tip to reveal only that tab's command KeyTips, and press `Esc` to step back. `Left`/`Right`, `Ctrl+Tab`, `Home`, and `End` change tabs.

For app-specific bindings, provide `RibbonShortcut` values. This keeps accelerators typed and platform-aware:

```dart
MaterialRibbon(
  // ...
  shortcuts: [
    RibbonShortcut(
      id: 'save-document',
      activator: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
      onInvoke: saveDocument,
    ),
  ],
)
```

## Optional command palette

`RibbonCommandPalette` is independent of the ribbon. Place it in `MaterialRibbon.commandPalette` to show a search field in the desktop ribbon header. It is automatically omitted on narrow layouts.

```dart
MaterialRibbon(
  // ...tabs and context...
  commandPalette: RibbonCommandPalette(
    commands: commands,
    context: ribbonContext,
  ),
)
```

## Example

The runnable sample is in [`example/material_ribbon_example.dart`](example/material_ribbon_example.dart). After creating the example platforms, run it with:

```powershell
cd example
flutter create --platforms=windows,web .
flutter run -d windows -t material_ribbon_example.dart
```

## API reference

See [API.md](API.md) for the complete public API, constructor parameters, and behaviour notes.

## Development

```sh
flutter analyze
flutter test
```

## Command feedback and safe personalization

Use `onCommandFeedback` to present application-owned progress, success, and
failure UI. The package does not show snackbars or dialogs itself, so feedback
fits the host application's error reporting and undo model.

```dart
MaterialRibbon(
  // ...
  onCommandFeedback: (feedback) {
    if (feedback.type == RibbonCommandFeedbackType.failed) {
      showError(feedback.error!);
    }
  },
)
```

`RibbonPersonalization.toJson()` and `fromJson()` are the import/export format.
Before use, `validated(commandIds: ..., tabIds: ...)` removes stale or duplicate
IDs after an application update. The built-in customization dialog has a
**Reset to defaults** action; hosts can reset a controlled value with
`RibbonPersonalization.defaults`.

## Supported platforms

The package compiles for Android, iOS, Linux, macOS, web, and Windows. Its
full keyboard-first Ribbon interaction is designed for desktop and web; compact
layout is used below the configured breakpoint. Test the host application's
touch behaviour and text scale with its own command set before shipping mobile.
