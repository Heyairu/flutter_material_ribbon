# API Reference

This reference describes the public API exported by `package:material_ribbon/material_ribbon.dart` in version 1.1.0.

## Data models and enums

### `RibbonContext`

Immutable application state passed to the ribbon when it evaluates command and tab state.

| Property | Type | Description |
| --- | --- | --- |
| `selectionType` | `String?` | Application-defined selection category, such as `image` or `table`. |
| `selectionCount` | `int` | Number of selected items; defaults to `0`. |
| `values` | `Map<String, Object?>` | Additional application-defined state; defaults to an empty map. |
| `hasSelection` | `bool` | `true` when `selectionCount > 0`. |

### Command enums

| Enum | Values | Purpose |
| --- | --- | --- |
| `RibbonCommandSize` | `small`, `medium`, `large` | Chooses the command button layout. Large commands span the group command height. |
| `RibbonCommandType` | `action`, `toggle`, `menu`, `split`, `gallery` | Chooses the command interaction pattern. |
| `RibbonCheckState` | `unchecked`, `checked`, `mixed` | State returned by a toggle command. The checked state receives selected styling. |

### `RibbonCommand`

Describes one executable ribbon operation. `id`, `label`, `icon`, and `onInvoke` are required.

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `id` / `label` | `String` | required | Stable command identifier and visible label. |
| `icon` | `IconData` | required | Command icon. |
| `onInvoke` | `VoidCallback` | required | Invoked for the main command action. |
| `description` | `String?` | `null` | Searchable command-palette description. |
| `shortcut` / `keyTip` | `String?` | `null` | Tooltip shortcut text and Alt/F10 key-tip label. |
| `type` | `RibbonCommandType` | `action` | Command interaction pattern. |
| `size` | `RibbonCommandSize` | `medium` | Command visual size. |
| `isEnabled` | `bool Function(RibbonContext)?` | `null` | Enables a command when `true`; defaults to enabled. |
| `disabledReason` | `String? Function(RibbonContext)?` | `null` | Added to the tooltip while disabled. |
| `isBusy` | `bool Function(RibbonContext)?` | `null` | Shows a progress indicator and prevents invocation when `true`. |
| `checkState` | `RibbonCheckState Function(RibbonContext)?` | `null` | Toggle state; defaults to `unchecked`. |
| `menuCommands` | `List<RibbonCommand>` | `[]` | Items shown by `menu` and `split` commands. |
| `galleryItems` | `List<RibbonGalleryItem<Object?>>` | `[]` | Items shown by a `gallery` command. |
| `selectedValue` | `Object? Function(RibbonContext)?` | `null` | Selected gallery value. |
| `onGalleryPreview` | `ValueChanged<Object?>?` | `null` | Receives the gallery value on pointer entry. |
| `onGalleryPreviewEnd` | `VoidCallback?` | `null` | Called when the gallery pointer exits. |

`enabledFor`, `busyFor`, `stateFor`, and `disabledReasonFor` expose the resolved values for a supplied context.

### `RibbonChip`

A compact, controlled selectable button for Backstage navigation, settings panes, and other command lists. It requires either `label` or `child`. Use `selected` with `onSelected` for navigation state, `onPressed` for a normal action, or both when an item should select and act. `icon`, `tooltip`, `semanticLabel`, `style`, `padding`, `minimumSize`, and `alignment` control presentation. It also forwards `onLongPress`, `onHover`, `onFocusChange`, `focusNode`, and `autofocus` for application-specific behaviour.

### `RibbonGroup`

Groups commands and arbitrary controls under a label.

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | Group caption. |
| `commands` | `List<RibbonCommand>` | `[]` | Commands arranged in the group grid. |
| `controls` | `List<Widget>` | `[]` | Custom widgets placed beside the command grid. |
| `rows` | `int` | `2` | Command rows; must be from 1 through 3. |
| `width` | `double?` | `null` | Optional explicit group width. |
| `onMoreOptions` | `VoidCallback?` | `null` | Shows a group launcher when supplied. |
| `moreOptionsTooltip` | `String` | localized default | Launcher tooltip. |

### `RibbonTab`

Defines one ribbon tab.

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `id` / `label` | `String` | required | Stable tab identifier and visible label. |
| `groups` | `List<RibbonGroup>` | required | Groups displayed for the tab. |
| `icon` | `IconData?` | `null` | Optional tab icon. |
| `isVisible` | `bool Function(RibbonContext)?` | `null` | Contextual visibility predicate; defaults to visible. |
| `mobileCommands` | `List<RibbonCommand>` | `[]` | Compact-layout source when `compactCommands` is empty. |
| `compactCommands` | `List<RibbonCommand>` | `[]` | Preferred compact-layout command source. |
| `keyTip` | `String?` | `null` | Alt/F10 key-tip label. |

## Main widgets

### `MaterialRibbon`

The top-level ribbon widget. `tabs` and `context` are required.

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `tabs` | `List<RibbonTab>` | required | Ribbon tabs. |
| `context` | `RibbonContext` | required | Current application/editor state. |
| `height` | `double` | `210` | Expanded desktop ribbon height. |
| `collapsed` | `bool` | `false` | Whether only the 48px header is shown. |
| `onCollapsedChanged` | `ValueChanged<bool>?` | `null` | Receives collapse toggle requests. |
| `compact` | `bool?` | `null` | Forces compact or desktop layout; `null` switches below 720px. |
| `quickAccessCommands` | `List<RibbonCommand>` | `[]` | Default Quick Access Toolbar commands. |
| `leadingCommands` | `List<RibbonCommand>` | `[]` | Backwards-compatible Quick Access Toolbar alias. |
| `personalization` | `RibbonPersonalization?` | `null` | Host-controlled preferences. |
| `personalizationStore` | `RibbonPersonalizationStore?` | `null` | Optional asynchronous preference store. |
| `onPersonalizationChanged` | `ValueChanged<RibbonPersonalization>?` | `null` | Receives toolbar customization changes. |
| `commandPalette` | `Widget?` | `null` | Optional desktop-header search widget. |
| `quickAccessLimit` | `int` | `4` | Commands shown before toolbar overflow. |
| `quickAccessCollapsed` | `bool` | `false` | Hides Quick Access commands when `true`. |
| `onQuickAccessCollapsedChanged` | `ValueChanged<bool>?` | `null` | Receives Quick Access visibility toggle requests. |
| `shortcuts` | `List<RibbonShortcut>` | `[]` | Application-defined keyboard bindings active while focus is in the ribbon. |
| `showCustomizationButton` | `bool` | `false` | Shows the full Ribbon customization dialog in the header. |
| `customizationDialogTitle` | `String` | `自訂功能區` | Dialog title and customization button tooltip. |

Keyboard handling:

- `Ctrl+F1` requests a collapsed-state toggle.
- `Alt` or `F10` opens header key tips. Choosing a tab key tip then opens command key tips for that tab; `Esc` returns to header tips, then closes them.
- `Left`/`Right`, `Ctrl+Tab`/`Ctrl+Shift+Tab`, and `Home`/`End` switch tabs.
- A matching enabled, idle command key tip invokes that command. Command key tips never invoke commands from an inactive tab.

In compact mode, the ribbon uses `compactCommands`, then `mobileCommands`, then non-medium commands from all tab groups. The command palette is not shown.

### `RibbonHorizontalScrollView`

A horizontally scrolling `ListView` with a visible scrollbar. It accepts required `children`, optional `padding`, and `scrollbarPadding`. Pointer wheel movement is translated into horizontal scrolling.

### `RibbonCommandPalette`

A Material `SearchAnchor` that filters required `commands` against a command's label and optional description. It requires the current `RibbonContext`, excludes disabled or busy commands, and invokes the selected command.

### `TextFormatControls`

A ready-made row containing a font-size slider and text-colour menu. Required values are `fontSize`, `color`, `onFontSizeChanged`, and `onColorChanged`. The slider operates from 8 to 72.

## Compact controls

All controls below are controlled widgets: the host owns the value and updates it in the supplied callback.

### `RibbonGallery<T>` and `RibbonGalleryItem<T>`

`RibbonGallery<T>` renders a fixed grid of `RibbonGalleryItem<T>` values. It requires `items` and `onSelected`; optional properties are `selectedValue`, `onPreview`, `onPreviewEnd`, `columns` (default `4`), `cellSize` (default `72 × 60`), `showLabels` (default `true`), `enabled` (default `true`), and `padding` (default `EdgeInsets.all(6)`). `columns` must be greater than zero.

Each item requires `value` and `label`, and can supply `icon`, `preview`, `tooltip`, and an item-specific `onSelected` callback. `preview` takes precedence over `icon`.

### `RibbonFeaturedGallery<T>`

The default command button height is 40px, including buttons that open a gallery. Gallery cells are 60px tall. Large command buttons are 120px tall with 40px icons; the featured gallery is also 120px tall including its border. Group content is aligned to the top of the 120px command area. Compact command buttons remain 40px tall.

`RibbonFeaturedGallery<T>` composes a 120px-high container with a top-aligned 3-column grid of common 60px-high gallery items and an expansion button that opens the full `RibbonGallery<T>`. The default grid displays up to six featured items in two rows. It requires `items`, `featuredValues`, and `onSelected`. `featuredValues` controls the visible items and order; values absent from `items` are ignored. Optional properties are `selectedValue`, `onPreview`, `onPreviewEnd`, `columns` (default `4`), `featuredCols` (default `3`), `featuredCellSize` (default `68 × 60`), `galleryCellSize` (default `72 × 60`), `galleryWidth` (default `312`), `moreTooltip` (default `More items`), and `enabled` (default `true`).

### `RibbonComboBox<T>` and `RibbonComboBoxItem<T>`

`RibbonComboBox<T>` shows a read-only field that opens a Material menu. It requires `items`, `value`, and `onChanged`; `label` is optional, `width` defaults to `150`, and `enabled` defaults to `true`. A combo-box item requires `value` and `label` and may include a `leading` widget.

### `RibbonTextBox`

Controlled ribbon-sized text field. `value` and `onChanged` are required. `label`, `hintText`, `width` (default `150`), and `enabled` (default `true`) are optional.

### `RibbonSpinBox`

Numeric text field with increment and decrement buttons. Required parameters are `value` and `onChanged`; `min`, `max`, `step`, `label`, `width`, and `decimalPlaces` are optional. Defaults are `0`, `100`, `1`, `null`, `108`, and `0`, respectively. Input and step results are clamped to the inclusive range.

### `RibbonColorPicker`

Menu-backed palette built on `RibbonGallery<Color>`. It requires `colors`, `value`, and `onChanged`. `onPreview`, `onPreviewEnd`, `label` (default `Color`), and `columns` (default `6`) are optional. The selected colour is shown on the trigger icon.

### `RibbonFontPicker`

Convenience `RibbonComboBox<String>` that renders each available font with its own typeface. It requires `fonts`, `value`, and `onChanged`; `width` defaults to `170`.

## Personalization

### `RibbonPersonalization`

Immutable preferences used by `MaterialRibbon`.

| Property | Type | Default |
| --- | --- | --- |
| `quickAccessCommandIds` | `List<String>` | `[]` |
| `quickAccessCustomized` | `bool` | `false` | When `false`, uses program defaults; when `true`, an empty ID list is a deliberately empty QAT. |
| `tabOrder` | `List<String>` | `[]` |
| `hiddenTabIds` | `Set<String>` | `{}` |

Use `copyWith` to produce an updated preference object.

### `RibbonPersonalizationStore`

Implement this abstract adapter to persist user preferences:

```dart
abstract class RibbonPersonalizationStore {
  Future<RibbonPersonalization?> load();
  Future<void> save(RibbonPersonalization personalization);
}
```

When no controlled `personalization` is supplied, `MaterialRibbon` loads from the store once and saves changes after Quick Access customization.

### `RibbonShortcut`

Defines a keyboard binding owned by the application. Supply an `id`, a Flutter `ShortcutActivator` (normally `SingleActivator`), and `onInvoke`. `isEnabled` can disable the binding for the current `RibbonContext`. Pass bindings through `MaterialRibbon.shortcuts`.

### `RibbonCustomizationPanel`

A controlled UI for choosing Quick Access commands, hiding or showing tabs, and moving tabs up or down. It requires `tabs`, `commands`, `value`, and `onChanged`. Set `MaterialRibbon.showCustomizationButton` to `true` to expose the same panel in a dialog that automatically calls the ribbon's personalization callback/store.
