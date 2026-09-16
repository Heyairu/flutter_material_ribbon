import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

@immutable
class RibbonContext {
  const RibbonContext({this.selectionType, this.selectionCount = 0, this.values = const {}});
  final String? selectionType;
  final int selectionCount;
  final Map<String, Object?> values;
  bool get hasSelection => selectionCount > 0;
}

enum RibbonCommandSize { small, medium, large }
enum RibbonCommandType { action, toggle, menu, split, gallery }
enum RibbonCheckState { unchecked, checked, mixed }

class RibbonGalleryItem<T> {
  const RibbonGalleryItem({required this.value, required this.label, this.icon, this.onSelected});
  final T value; final String label; final IconData? icon; final ValueChanged<T>? onSelected;
}

/// One command can expose an action, toggle, menu, split-button, or gallery.
class RibbonCommand {
  const RibbonCommand({
    required this.id, required this.label, required this.icon, required this.onInvoke,
    this.description, this.shortcut, this.keyTip, this.type = RibbonCommandType.action,
    this.size = RibbonCommandSize.medium, this.isEnabled, this.disabledReason,
    this.isBusy, this.checkState, this.selectedValue, this.menuCommands = const [],
    this.galleryItems = const [],
  });
  final String id, label;
  final String? description, shortcut, keyTip;
  final IconData icon;
  final VoidCallback onInvoke;
  final RibbonCommandType type;
  final RibbonCommandSize size;
  final bool Function(RibbonContext)? isEnabled;
  final String? Function(RibbonContext)? disabledReason;
  final bool Function(RibbonContext)? isBusy;
  final RibbonCheckState Function(RibbonContext)? checkState;
  final Object? Function(RibbonContext)? selectedValue;
  final List<RibbonCommand> menuCommands;
  final List<RibbonGalleryItem<Object?>> galleryItems;
  bool enabledFor(RibbonContext context) => isEnabled?.call(context) ?? true;
  bool busyFor(RibbonContext context) => isBusy?.call(context) ?? false;
  RibbonCheckState stateFor(RibbonContext context) => checkState?.call(context) ?? RibbonCheckState.unchecked;
  String? disabledReasonFor(RibbonContext context) => disabledReason?.call(context);
}

class RibbonGroup {
  const RibbonGroup({
    required this.label, this.commands = const [], this.controls = const [],
    this.rows = 2, this.width, this.onMoreOptions, this.moreOptionsTooltip = "更多選項",
  }) : assert(rows >= 1 && rows <= 3);
  final String label;
  final List<RibbonCommand> commands;
  final List<Widget> controls;
  /// Fixed 1–3 command rows; controls remain available for custom composition.
  final int rows;
  final double? width;
  final VoidCallback? onMoreOptions;
  final String moreOptionsTooltip;
}

class RibbonTab {
  const RibbonTab({
    required this.id, required this.label, required this.groups, this.icon,
    this.isVisible, this.mobileCommands = const [], this.compactCommands = const [], this.keyTip,
  });
  final String id, label;
  final List<RibbonGroup> groups;
  final IconData? icon;
  final bool Function(RibbonContext)? isVisible;
  final List<RibbonCommand> mobileCommands;
  final List<RibbonCommand> compactCommands;
  final String? keyTip;
  bool visibleFor(RibbonContext context) => isVisible?.call(context) ?? true;
}

@immutable
class RibbonPersonalization {
  const RibbonPersonalization({
    this.quickAccessCommandIds = const [], this.tabOrder = const [], this.hiddenTabIds = const {},
  });
  final List<String> quickAccessCommandIds, tabOrder;
  final Set<String> hiddenTabIds;
  RibbonPersonalization copyWith({
    List<String>? quickAccessCommandIds, List<String>? tabOrder, Set<String>? hiddenTabIds,
  }) => RibbonPersonalization(
    quickAccessCommandIds: quickAccessCommandIds ?? this.quickAccessCommandIds,
    tabOrder: tabOrder ?? this.tabOrder, hiddenTabIds: hiddenTabIds ?? this.hiddenTabIds,
  );
}

/// Adapter for app-owned persistence (SharedPreferences, database, etc.).
abstract class RibbonPersonalizationStore {
  Future<RibbonPersonalization?> load();
  Future<void> save(RibbonPersonalization personalization);
}

class MaterialRibbon extends StatefulWidget {
  const MaterialRibbon({
    super.key, required this.tabs, required this.context, this.height = 190,
    this.collapsed = false, this.onCollapsedChanged, this.compact,
    this.leadingCommands = const [], this.quickAccessCommands = const [],
    this.personalization, this.personalizationStore, this.onPersonalizationChanged,
    this.commandPalette, this.quickAccessLimit = 4, this.quickAccessCollapsed = false, this.onQuickAccessCollapsedChanged,
  });
  final List<RibbonTab> tabs;
  final RibbonContext context;
  final double height;
  final bool collapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  final bool? compact;
  /// Backward-compatible alias for [quickAccessCommands].
  final List<RibbonCommand> leadingCommands;
  final List<RibbonCommand> quickAccessCommands;
  final RibbonPersonalization? personalization;
  final RibbonPersonalizationStore? personalizationStore;
  final ValueChanged<RibbonPersonalization>? onPersonalizationChanged;
  /// Optional search surface supplied by the host, commonly [RibbonCommandPalette].
  /// It is placed in the ribbon header and is omitted automatically on narrow layouts.
  final Widget? commandPalette;
  final int quickAccessLimit;
  final bool quickAccessCollapsed;
  final ValueChanged<bool>? onQuickAccessCollapsedChanged;
  @override State<MaterialRibbon> createState() => _MaterialRibbonState();
}

class _MaterialRibbonState extends State<MaterialRibbon> {
  List<RibbonTab> _visibleTabs = const [];
  String? _selectedTabId;
  RibbonPersonalization? _stored;
  bool _showKeyTips = false;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final value = await widget.personalizationStore?.load();
    if (mounted && value != null && widget.personalization == null) setState(() => _stored = value);
  }
  RibbonPersonalization get _prefs => widget.personalization ?? _stored ?? const RibbonPersonalization();
  @override void didChangeDependencies() { super.didChangeDependencies(); _updateTabs(); }
  @override void didUpdateWidget(covariant MaterialRibbon oldWidget) { super.didUpdateWidget(oldWidget); _updateTabs(); }
  void _updateTabs() {
    final order = {for (var i = 0; i < _prefs.tabOrder.length; i++) _prefs.tabOrder[i]: i};
    _visibleTabs = widget.tabs.where((tab) => tab.visibleFor(widget.context) && !_prefs.hiddenTabIds.contains(tab.id)).toList()
      ..sort((a, b) => (order[a.id] ?? 9999).compareTo(order[b.id] ?? 9999));
    if (!_visibleTabs.any((tab) => tab.id == _selectedTabId)) _selectedTabId = _visibleTabs.isEmpty ? null : _visibleTabs.first.id;
  }
  List<RibbonCommand> get _allCommands => [
    ...widget.quickAccessCommands, ...widget.leadingCommands,
    for (final tab in widget.tabs) for (final group in tab.groups) ...group.commands,
  ];
  List<RibbonCommand> get _qat {
    final defaults = widget.quickAccessCommands.isEmpty ? widget.leadingCommands : widget.quickAccessCommands;
    if (_prefs.quickAccessCommandIds.isEmpty) return defaults;
    final byId = {for (final command in _allCommands) command.id: command};
    return _prefs.quickAccessCommandIds.map((id) => byId[id]).whereType<RibbonCommand>().toList();
  }
  Future<void> _save(RibbonPersonalization next) async {
    setState(() { _stored = next; _updateTabs(); });
    widget.onPersonalizationChanged?.call(next);
    await widget.personalizationStore?.save(next);
  }
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.f1 && HardwareKeyboard.instance.isControlPressed) {
      widget.onCollapsedChanged?.call(!widget.collapsed); return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight || event.logicalKey == LogicalKeyboardKey.f10) {
      setState(() => _showKeyTips = !_showKeyTips); return KeyEventResult.handled;
    }
    if (!_showKeyTips) return KeyEventResult.ignored;
    final key = event.character?.toUpperCase();
    if (key == null) return KeyEventResult.ignored;
    for (final tab in _visibleTabs) {
      if (tab.keyTip?.toUpperCase() == key) { setState(() { _selectedTabId = tab.id; _showKeyTips = false; }); return KeyEventResult.handled; }
    }
    for (final command in _allCommands) {
      if (command.keyTip?.toUpperCase() == key && command.enabledFor(widget.context) && !command.busyFor(widget.context)) {
        command.onInvoke(); setState(() => _showKeyTips = false); return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
  @override Widget build(BuildContext context) {
    _updateTabs();
    if (_visibleTabs.isEmpty || _selectedTabId == null) return const SizedBox.shrink();
    final selected = _visibleTabs.firstWhere((tab) => tab.id == _selectedTabId);
    return Focus(onKeyEvent: _onKey, child: LayoutBuilder(builder: (context, constraints) {
      // Desktop command grids become unreadable before the common 600px phone
      // breakpoint; switch to the single-row command experience earlier.
      final compact = widget.compact ?? constraints.maxWidth < 720;
      return Material(color: Theme.of(context).colorScheme.surfaceContainerLow, child: SizedBox(
        height: compact ? (widget.collapsed ? 52 : 112) : (widget.collapsed ? 52 : widget.height),
        child: Column(children: [
          SizedBox(height: 48, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(width: 8),
            if (!widget.quickAccessCollapsed) ..._qat.take(widget.quickAccessLimit).map((command) => SizedBox(width: 40, height: 40, child: _KeyTip(label: command.keyTip, visible: _showKeyTips, child: _QatButton(command, widget.context)))),
            if (!widget.quickAccessCollapsed && _qat.length > widget.quickAccessLimit) _QatMoreButton(commands: _qat.skip(widget.quickAccessLimit).toList(), ribbonContext: widget.context),
            if (widget.onQuickAccessCollapsedChanged != null) IconButton(tooltip: widget.quickAccessCollapsed ? "展開快速存取工具列" : "收合快速存取工具列", onPressed: () => widget.onQuickAccessCollapsedChanged!(!widget.quickAccessCollapsed), icon: Icon(widget.quickAccessCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left)),
            if (widget.onPersonalizationChanged != null || widget.personalizationStore != null)
              _QatCustomizer(commands: _allCommands, selected: _prefs.quickAccessCommandIds, onChanged: (ids) => _save(_prefs.copyWith(quickAccessCommandIds: ids))),
            Expanded(child: RibbonHorizontalScrollView(scrollbarPadding: 0, padding: const EdgeInsets.symmetric(horizontal: 12), children: _visibleTabs.map((tab) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: SizedBox(height: 40, child: _KeyTip(label: tab.keyTip, visible: _showKeyTips, child: Center(child: ChoiceChip(
              avatar: tab.icon == null ? null : Icon(tab.icon, size: 18),
              label: Text(tab.label),
              selected: tab.id == _selectedTabId,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: tab.isVisible == null ? null : Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.55),
              selectedColor: tab.isVisible == null ? null : Theme.of(context).colorScheme.secondaryContainer,
              onSelected: (_) => setState(() => _selectedTabId = tab.id),
            )))))).toList())),
            if (!compact && widget.commandPalette != null) SizedBox(width: 260, child: widget.commandPalette!),
            IconButton(tooltip: widget.collapsed ? "展開 Ribbon (Ctrl+F1)" : "收合 Ribbon (Ctrl+F1)", onPressed: widget.onCollapsedChanged == null ? null : () => widget.onCollapsedChanged!(!widget.collapsed), icon: Icon(widget.collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up)),
          ])),
          if (!widget.collapsed) Expanded(child: compact ? _MobileActions(tab: selected, context: widget.context) : _TabBody(tab: selected, context: widget.context, showKeyTips: _showKeyTips)),
        ]),
      ));
    }));
  }
}

class _KeyTip extends StatelessWidget {
  const _KeyTip({required this.label, required this.visible, required this.child});
  final String? label; final bool visible; final Widget child;
  @override Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: [
      child,
      if (visible && label != null)
        Positioned(
          top: -2,
          right: -2,
          child: Material(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label!, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ),
    ],
  );
}
class _QatButton extends StatelessWidget {
  const _QatButton(this.command, this.context);
  final RibbonCommand command; final RibbonContext context;
  @override Widget build(BuildContext buildContext) => IconButton(
    tooltip: command.label,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    alignment: Alignment.center,
    visualDensity: VisualDensity.compact,
    onPressed: command.enabledFor(context) && !command.busyFor(context) ? command.onInvoke : null,
    icon: command.busyFor(context) ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(command.icon, size: 20),
  );
}
class _QatCustomizer extends StatelessWidget {
  const _QatCustomizer({required this.commands, required this.selected, required this.onChanged});
  final List<RibbonCommand> commands; final List<String> selected; final ValueChanged<List<String>> onChanged;
  @override Widget build(BuildContext context) => MenuAnchor(
    menuChildren: commands.map((command) => CheckboxMenuButton(value: selected.contains(command.id), onChanged: (checked) { final next = [...selected]; checked == true ? next.add(command.id) : next.remove(command.id); onChanged(next.toSet().toList()); }, child: Text(command.label))).toList(),
    builder: (context, controller, _) => IconButton(tooltip: "自訂快速存取工具列", onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: const Icon(Icons.more_horiz)),
  );
}
class _QatMoreButton extends StatelessWidget {
  const _QatMoreButton({required this.commands, required this.ribbonContext});
  final List<RibbonCommand> commands; final RibbonContext ribbonContext;
  @override Widget build(BuildContext context) => MenuAnchor(menuChildren: commands.map((command) => MenuItemButton(onPressed: command.enabledFor(ribbonContext) ? command.onInvoke : null, leadingIcon: Icon(command.icon), child: Text(command.label))).toList(), builder: (context, controller, _) => IconButton(tooltip: "更多快速存取命令", onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: const Icon(Icons.more_horiz)));
}

class RibbonHorizontalScrollView extends StatefulWidget {
  const RibbonHorizontalScrollView({super.key, required this.children, this.padding, this.scrollbarPadding = 12});
  final List<Widget> children; final EdgeInsetsGeometry? padding; final double scrollbarPadding;
  @override State<RibbonHorizontalScrollView> createState() => _RibbonHorizontalScrollViewState();
}
class _RibbonHorizontalScrollViewState extends State<RibbonHorizontalScrollView> {
  final _controller = ScrollController();
  void _handle(PointerSignalEvent event) { if (event is! PointerScrollEvent || !_controller.hasClients) return; final p = _controller.position; _controller.jumpTo((_controller.offset + event.scrollDelta.dy).clamp(p.minScrollExtent, p.maxScrollExtent).toDouble()); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Listener(onPointerSignal: _handle, child: Scrollbar(controller: _controller, thumbVisibility: true, child: ListView(controller: _controller, scrollDirection: Axis.horizontal, physics: const AlwaysScrollableScrollPhysics(), padding: (widget.padding ?? EdgeInsets.zero).add(EdgeInsets.only(bottom: widget.scrollbarPadding)), children: widget.children)));
}
class _TabBody extends StatelessWidget {
  const _TabBody({required this.tab, required this.context, required this.showKeyTips});
  final RibbonTab tab; final RibbonContext context; final bool showKeyTips;
  @override Widget build(BuildContext buildContext) => RibbonHorizontalScrollView(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: List.generate(tab.groups.length, (i) => [_Group(group: tab.groups[i], context: context, showKeyTips: showKeyTips), if (i < tab.groups.length - 1) const VerticalDivider(width: 24, indent: 6, endIndent: 6)]).expand((items) => items).toList());
}
class _MobileActions extends StatelessWidget {
  const _MobileActions({required this.tab, required this.context});
  final RibbonTab tab; final RibbonContext context;
  @override Widget build(BuildContext buildContext) { final commands = tab.compactCommands.isNotEmpty ? tab.compactCommands : tab.mobileCommands.isNotEmpty ? tab.mobileCommands : tab.groups.expand((group) => group.commands).where((command) => command.size != RibbonCommandSize.medium).toList(); return RibbonHorizontalScrollView(padding: const EdgeInsets.symmetric(horizontal: 8), children: commands.map((command) => Center(child: _CommandButton(command, context, compact: true))).toList()); }
}
class _Group extends StatelessWidget {
  const _Group({required this.group, required this.context, required this.showKeyTips});
  final RibbonGroup group; final RibbonContext context; final bool showKeyTips;
  @override Widget build(BuildContext buildContext) => SizedBox(width: group.width, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Expanded(child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (group.commands.isNotEmpty) SizedBox(height: group.rows * 48 + (group.rows - 1) * 6, child: Wrap(direction: Axis.vertical, spacing: 6, runSpacing: 6, children: group.commands.map((command) => _KeyTip(label: command.keyTip, visible: showKeyTips, child: _CommandButton(command, context))).toList())),
      ...group.controls,
    ])),
    SizedBox(height: 22, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(group.label, style: Theme.of(buildContext).textTheme.labelSmall), if (group.onMoreOptions != null) IconButton(tooltip: group.moreOptionsTooltip, iconSize: 14, visualDensity: VisualDensity.compact, onPressed: group.onMoreOptions, icon: const Icon(Icons.arrow_outward))])),
  ]));
}
class _CommandButton extends StatelessWidget {
  const _CommandButton(this.command, this.context, {this.compact = false});
  final RibbonCommand command; final RibbonContext context; final bool compact;
  @override Widget build(BuildContext buildContext) {
    final enabled = command.enabledFor(context); final busy = command.busyFor(context); final state = command.stateFor(context);
    final tooltip = [command.label, if (!enabled && command.disabledReasonFor(context) != null) command.disabledReasonFor(context)!, if (command.shortcut != null) command.shortcut!].join("\n");
    final icon = busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(command.icon, size: command.size == RibbonCommandSize.large && !compact ? 28 : 20);
    void action() { if (enabled && !busy) command.onInvoke(); }
    final main = _button(buildContext, icon, action, enabled && !busy, state);
    final child = switch (command.type) {
      RibbonCommandType.menu || RibbonCommandType.gallery => _MenuButton(command, context, icon, enabled && !busy, action, compact: compact),
      RibbonCommandType.split => compact
          ? _MenuButton(
              command,
              context,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon, const Icon(Icons.arrow_drop_down, size: 18)],
              ),
              enabled && !busy,
              action,
              invoke: false,
              compact: true,
            )
          : Row(mainAxisSize: MainAxisSize.min, children: [main, _MenuButton(command, context, const Icon(Icons.arrow_drop_down), enabled && !busy, action, invoke: false, compact: false)]),
      _ => main,
    };
    return Tooltip(message: tooltip, child: Semantics(button: true, enabled: enabled, checked: command.type == RibbonCommandType.toggle ? state == RibbonCheckState.checked : null, label: command.label, child: child));
  }
  Widget _button(BuildContext buildContext, Widget icon, VoidCallback action, bool enabled, RibbonCheckState state) {
    final selected = command.type == RibbonCommandType.toggle && state == RibbonCheckState.checked;
    if (command.size == RibbonCommandSize.large && !compact) {
      return SizedBox(
        width: 76,
        height: 102,
        child: TextButton(
          onPressed: enabled ? action : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            alignment: Alignment.center,
            backgroundColor: selected
                ? Theme.of(buildContext).colorScheme.secondaryContainer
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 5),
              Text(command.label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }
    if (command.size == RibbonCommandSize.medium || compact) {
      return SizedBox(
        height: 40,
        child: TextButton.icon(
        onPressed: enabled ? action : null,
        icon: icon,
        label: Text(
          command.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? Theme.of(buildContext).colorScheme.secondaryContainer
              : null,
        ),
        ),
      );
    }
    return IconButton(onPressed: enabled ? action : null, icon: icon, isSelected: selected, selectedIcon: icon);
  }
}
class _MenuButton extends StatelessWidget {
  const _MenuButton(this.command, this.context, this.icon, this.enabled, this.onInvoke, {this.invoke = true, this.compact = false});
  final RibbonCommand command; final RibbonContext context; final Widget icon; final bool enabled; final VoidCallback onInvoke; final bool invoke; final bool compact;
  @override Widget build(BuildContext buildContext) => MenuAnchor(
    menuChildren: command.type == RibbonCommandType.gallery
      ? command.galleryItems.map((item) => MenuItemButton(onPressed: enabled ? () => item.onSelected?.call(item.value) : null, leadingIcon: item.icon == null ? null : Icon(item.icon), child: Text(item.label))).toList()
      : command.menuCommands.map((item) => MenuItemButton(onPressed: item.enabledFor(context) ? item.onInvoke : null, leadingIcon: Icon(item.icon), child: Text(item.label))).toList(),
    builder: (context, controller, _) {
      void openMenu() {
        if (invoke && command.type == RibbonCommandType.menu) onInvoke();
        controller.isOpen ? controller.close() : controller.open();
      }
      if (command.size == RibbonCommandSize.medium || compact) {
        return TextButton.icon(
          onPressed: enabled ? openMenu : null,
          icon: icon,
          label: Text(command.label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }
      return IconButton(onPressed: enabled ? openMenu : null, icon: icon);
    },
  );
}

class RibbonCommandPalette extends StatelessWidget {
  const RibbonCommandPalette({super.key, required this.commands, required this.context});
  final List<RibbonCommand> commands; final RibbonContext context;
  @override Widget build(BuildContext buildContext) => SearchAnchor.bar(barHintText: "搜尋命令", barLeading: const Icon(Icons.search), suggestionsBuilder: (searchContext, controller) { final query = controller.text.trim().toLowerCase(); return commands.where((command) => command.enabledFor(context) && !command.busyFor(context) && (query.isEmpty || "${command.label} ${command.description ?? ""}".toLowerCase().contains(query))).map((command) => ListTile(leading: Icon(command.icon), title: Text(command.label), subtitle: command.description == null ? null : Text(command.description!), trailing: command.shortcut == null ? null : Text(command.shortcut!), onTap: () { controller.closeView(command.label); command.onInvoke(); })); });
}

class TextFormatControls extends StatelessWidget {
  const TextFormatControls({super.key, required this.fontSize, required this.color, required this.onFontSizeChanged, required this.onColorChanged});
  final double fontSize; final Color color; final ValueChanged<double> onFontSizeChanged; final ValueChanged<Color> onColorChanged;
  static const _colors = <Color>[Colors.black, Colors.red, Colors.orange, Colors.green, Colors.blue, Colors.purple];
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 132, child: Slider(value: fontSize.clamp(8, 72), min: 8, max: 72, divisions: 64, label: "${fontSize.round()} pt", onChanged: onFontSizeChanged)), MenuAnchor(menuChildren: _colors.map((choice) => MenuItemButton(onPressed: () => onColorChanged(choice), child: Icon(Icons.circle, color: choice))).toList(), builder: (context, controller, _) => IconButton.outlined(tooltip: "文字色彩", onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: Icon(Icons.format_color_text, color: color)))]);
}
