import "package:flutter/material.dart";
import "package:flutter/gestures.dart";

/// Current editor selection, used to reveal contextual UI.
@immutable
class RibbonContext {
  const RibbonContext({
    this.selectionType,
    this.selectionCount = 0,
    this.values = const {},
  });
  final String? selectionType;
  final int selectionCount;
  final Map<String, Object?> values;
  bool get hasSelection => selectionCount > 0;
}

/// A command shared by ribbon, menus, and the command palette.
class RibbonCommand {
  const RibbonCommand({
    required this.id,
    required this.label,
    required this.icon,
    required this.onInvoke,
    this.description,
    this.shortcut,
    this.isEnabled,
  });
  final String id;
  final String label;
  final String? description;
  final String? shortcut;
  final IconData icon;
  final VoidCallback onInvoke;
  final bool Function(RibbonContext context)? isEnabled;
  bool enabledFor(RibbonContext context) => isEnabled?.call(context) ?? true;
}

class RibbonGroup {
  const RibbonGroup({
    required this.label,
    this.commands = const [],
    this.controls = const [],
  });
  final String label;
  final List<RibbonCommand> commands;

  /// Custom controls, such as a font picker, placed after [commands].
  final List<Widget> controls;
}

/// Set [isVisible] to make a tab contextual.
class RibbonTab {
  const RibbonTab({
    required this.id,
    required this.label,
    required this.groups,
    this.icon,
    this.isVisible,
    this.mobileCommands = const [],
  });
  final String id;
  final String label;
  final List<RibbonGroup> groups;

  /// Optional symbol shown before this tab's label in the chip selector.
  final IconData? icon;
  final bool Function(RibbonContext context)? isVisible;

  /// Commands shown by the compact mobile toolbar. Falls back to group commands.
  final List<RibbonCommand> mobileCommands;
  bool visibleFor(RibbonContext context) => isVisible?.call(context) ?? true;
}

/// Material 3 ribbon which automatically shows contextual [RibbonTab]s.
class MaterialRibbon extends StatefulWidget {
  const MaterialRibbon({
    super.key,
    required this.tabs,
    required this.context,
    this.height = 132,
    this.collapsed = false,
    this.compact,
    this.leadingCommands = const [],
  }) : assert(
         leadingCommands.length <= 4,
         'At most four leading commands are allowed.',
       );
  final List<RibbonTab> tabs;
  final RibbonContext context;
  final double height;

  /// When true, only the scrollable chip selector is shown.
  final bool collapsed;

  /// Forces the compact command toolbar when non-null; otherwise adapts at 600px.
  final bool? compact;

  /// Optional fixed header commands; at most four. No commands are added implicitly.
  final List<RibbonCommand> leadingCommands;
  @override
  State<MaterialRibbon> createState() => _MaterialRibbonState();
}

class _MaterialRibbonState extends State<MaterialRibbon> {
  List<RibbonTab> _visibleTabs = const [];
  String? _selectedTabId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabs();
  }

  @override
  void didUpdateWidget(covariant MaterialRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTabs();
  }

  void _updateTabs() {
    final next = widget.tabs
        .where((tab) => tab.visibleFor(widget.context))
        .toList();
    _visibleTabs = next;
    if (!next.any((tab) => tab.id == _selectedTabId)) {
      _selectedTabId = next.isEmpty ? null : next.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleTabs.isEmpty || _selectedTabId == null) {
      return const SizedBox.shrink();
    }
    final selectedTab = _visibleTabs.firstWhere(
      (tab) => tab.id == _selectedTabId,
    );
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.compact ?? constraints.maxWidth < 600;
        final showContent = !widget.collapsed;
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SizedBox(
            height: compact
                ? (widget.collapsed ? 56 : 120)
                : (widget.collapsed ? 56 : widget.height),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      ...widget.leadingCommands
                          .take(4)
                          .map(
                            (command) => SizedBox(
                              width: 48,
                              child: IconButton(
                                tooltip: command.label,
                                onPressed: command.enabledFor(widget.context)
                                    ? command.onInvoke
                                    : null,
                                icon: Icon(command.icon),
                              ),
                            ),
                          ),
                      Expanded(
                        child: RibbonHorizontalScrollView(
                          scrollbarPadding: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          children: _visibleTabs
                              .map(
                                (tab) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: Center(
                                    child: ChoiceChip(
                                      avatar: tab.icon == null
                                          ? null
                                          : Icon(tab.icon),
                                      label: Text(tab.label),
                                      selected: tab.id == _selectedTabId,
                                      showCheckmark: false,
                                      backgroundColor: tab.isVisible == null
                                          ? null
                                          : colorScheme.secondaryContainer
                                                .withValues(alpha: 0.55),
                                      selectedColor: tab.isVisible == null
                                          ? null
                                          : colorScheme.secondaryContainer,
                                      onSelected: (_) => setState(
                                        () => _selectedTabId = tab.id,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showContent)
                  Expanded(
                    child: compact
                        ? _MobileRibbonActions(
                            tab: selectedTab,
                            ribbonContext: widget.context,
                          )
                        : _RibbonTabBody(
                            tab: selectedTab,
                            ribbonContext: widget.context,
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A horizontal Ribbon viewport with a visible scrollbar and mouse-wheel support.
class RibbonHorizontalScrollView extends StatefulWidget {
  const RibbonHorizontalScrollView({
    super.key,
    required this.children,
    this.padding,
    this.scrollbarPadding = 12,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  /// Extra space below content. Set to zero when the row already reserves space.
  final double scrollbarPadding;
  @override
  State<RibbonHorizontalScrollView> createState() =>
      _RibbonHorizontalScrollViewState();
}

class _RibbonHorizontalScrollViewState
    extends State<RibbonHorizontalScrollView> {
  final _controller = ScrollController();
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final position = _controller.position;
    final next = (_controller.offset + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _controller.jumpTo(next.toDouble());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _handlePointerSignal,
    child: Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: ListView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: (widget.padding ?? EdgeInsets.zero).add(
          EdgeInsets.only(bottom: widget.scrollbarPadding),
        ),
        children: widget.children,
      ),
    ),
  );
}

class _RibbonTabBody extends StatelessWidget {
  const _RibbonTabBody({required this.tab, required this.ribbonContext});
  final RibbonTab tab;
  final RibbonContext ribbonContext;
  @override
  Widget build(BuildContext context) => RibbonHorizontalScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    children: List.generate(
      tab.groups.length,
      (index) => [
        _RibbonGroup(group: tab.groups[index], ribbonContext: ribbonContext),
        if (index < tab.groups.length - 1) const SizedBox(width: 16),
      ],
    ).expand((widgets) => widgets).toList(),
  );
}

class _MobileRibbonActions extends StatelessWidget {
  const _MobileRibbonActions({required this.tab, required this.ribbonContext});
  final RibbonTab tab;
  final RibbonContext ribbonContext;
  @override
  Widget build(BuildContext context) {
    final commands = tab.mobileCommands.isNotEmpty
        ? tab.mobileCommands
        : tab.groups.expand((group) => group.commands).toList();
    return RibbonHorizontalScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: commands
          .map(
            (command) => SizedBox(
              width: 48,
              child: Center(
                child: _CommandButton(
                  command: command,
                  ribbonContext: ribbonContext,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RibbonGroup extends StatelessWidget {
  const _RibbonGroup({required this.group, required this.ribbonContext});
  final RibbonGroup group;
  final RibbonContext ribbonContext;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...group.commands.map(
              (command) => _CommandButton(
                command: command,
                ribbonContext: ribbonContext,
              ),
            ),
            ...group.controls,
          ],
        ),
      ),
      Text(group.label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({required this.command, required this.ribbonContext});
  final RibbonCommand command;
  final RibbonContext ribbonContext;
  @override
  Widget build(BuildContext context) {
    final enabled = command.enabledFor(ribbonContext);
    return Tooltip(
      message: [
        command.label,
        if (command.shortcut != null) command.shortcut!,
      ].join("  "),
      child: Semantics(
        button: true,
        label: command.label,
        child: IconButton.filledTonal(
          onPressed: enabled ? command.onInvoke : null,
          icon: Icon(command.icon),
        ),
      ),
    );
  }
}

/// Search and execute the supplied commands. Place in an [AppBar] or toolbar.
class RibbonCommandPalette extends StatelessWidget {
  const RibbonCommandPalette({
    super.key,
    required this.commands,
    required this.context,
  });
  final List<RibbonCommand> commands;
  final RibbonContext context;
  @override
  Widget build(BuildContext context) => SearchAnchor.bar(
    barHintText: "搜尋命令",
    barLeading: const Icon(Icons.search),
    suggestionsBuilder: (searchContext, controller) {
      final query = controller.text.trim().toLowerCase();
      final matches = commands.where(
        (command) =>
            command.enabledFor(this.context) &&
            (query.isEmpty ||
                "${command.label} ${command.description ?? ""}"
                    .toLowerCase()
                    .contains(query)),
      );
      return matches.map(
        (command) => ListTile(
          leading: Icon(command.icon),
          title: Text(command.label),
          subtitle: command.description == null
              ? null
              : Text(command.description!),
          trailing: command.shortcut == null ? null : Text(command.shortcut!),
          onTap: () {
            controller.closeView(command.label);
            command.onInvoke();
          },
        ),
      );
    },
  );
}

/// Compact Material 3 controls for font size and text color.
class TextFormatControls extends StatelessWidget {
  const TextFormatControls({
    super.key,
    required this.fontSize,
    required this.color,
    required this.onFontSizeChanged,
    required this.onColorChanged,
  });
  final double fontSize;
  final Color color;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onColorChanged;
  static const _colors = <Color>[
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 132,
        child: Slider(
          value: fontSize.clamp(8, 72),
          min: 8,
          max: 72,
          divisions: 64,
          label: "${fontSize.round()} pt",
          onChanged: onFontSizeChanged,
        ),
      ),
      MenuAnchor(
        menuChildren: _colors
            .map(
              (choice) => MenuItemButton(
                onPressed: () => onColorChanged(choice),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: choice),
                    const SizedBox(width: 8),
                    Text(
                      "#${choice.toARGB32().toRadixString(16).padLeft(8, "0")}",
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        builder: (context, controller, child) => IconButton.outlined(
          tooltip: "文字色彩",
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: Icon(Icons.format_color_text, color: color),
        ),
      ),
    ],
  );
}
