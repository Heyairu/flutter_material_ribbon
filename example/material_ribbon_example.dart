import "package:flutter/material.dart";
import "package:material_ribbon/material_ribbon.dart";

void main() => runApp(const RibbonExample());

enum _PreviewDevice {
  desktop("桌面", 1200, Icons.desktop_windows_outlined),
  tablet("平板", 800, Icons.tablet_android_outlined),
  phone("手機", 390, Icons.phone_android_outlined);

  const _PreviewDevice(this.label, this.width, this.icon);
  final String label;
  final double width;
  final IconData icon;
}

class RibbonExample extends StatefulWidget {
  const RibbonExample({super.key});

  @override
  State<RibbonExample> createState() => _RibbonExampleState();
}

class _RibbonExampleState extends State<RibbonExample> {
  String? _selectionType;
  String _fontFamily = "Calibri";
  double _fontSize = 16;
  Color _color = Colors.black;
  bool _showCommandPalette = false;
  bool _ribbonCollapsed = false;
  bool _compactCommands = false;
  _PreviewDevice _previewDevice = _PreviewDevice.desktop;
  String _lastAction = "選取畫布中的項目，查看情境分頁。";

  void _run(String label) => setState(() => _lastAction = "已執行：$label");

  @override
  Widget build(BuildContext context) {
    final ribbonContext = RibbonContext(
      selectionType: _selectionType,
      selectionCount: _selectionType == null ? 0 : 1,
    );
    final commands = <RibbonCommand>[
      RibbonCommand(
        id: "undo",
        label: "復原",
        icon: Icons.undo,
        shortcut: "Ctrl+Z",
        onInvoke: () => _run("復原"),
      ),
      RibbonCommand(
        id: "redo",
        label: "重做",
        icon: Icons.redo,
        shortcut: "Ctrl+Y",
        onInvoke: () => _run("重做"),
      ),
      RibbonCommand(
        id: "save",
        label: "儲存",
        icon: Icons.save_outlined,
        shortcut: "Ctrl+S",
        onInvoke: () => _run("儲存"),
      ),
      RibbonCommand(
        id: "copy",
        label: "複製",
        icon: Icons.content_copy_outlined,
        shortcut: "Ctrl+C",
        onInvoke: () => _run("複製"),
        isEnabled: (value) => value.hasSelection,
      ),
      RibbonCommand(
        id: "crop",
        label: "裁切",
        icon: Icons.crop,
        onInvoke: () => _run("裁切圖片"),
        isEnabled: (value) => value.selectionType == "image",
      ),
      RibbonCommand(
        id: "table",
        label: "新增列",
        icon: Icons.table_rows_outlined,
        onInvoke: () => _run("新增表格列"),
        isEnabled: (value) => value.selectionType == "table",
      ),
    ];
    final tabs = <RibbonTab>[
      RibbonTab(
        id: "home",
        label: "首頁",
        icon: Icons.home_outlined,
        mobileCommands: [commands[0], commands[1], commands[2], commands[3]],
        groups: [
          RibbonGroup(
            label: "Font",
            controls: [
              _FontTools(
                family: _fontFamily,
                fontSize: _fontSize,
                color: _color,
                onFamilyChanged: (value) => setState(() => _fontFamily = value),
                onFontSizeChanged: (value) => setState(() => _fontSize = value),
                onColorChanged: (value) => setState(() => _color = value),
                onAction: _run,
              ),
            ],
          ),
          RibbonGroup(
            label: "Paragraph",
            controls: [_ParagraphTools(onAction: _run)],
          ),
          RibbonGroup(
            label: "Insert",
            controls: [_InsertTools(onAction: _run)],
          ),
        ],
      ),
      RibbonTab(
        id: "image",
        label: "圖片格式",
        icon: Icons.image_outlined,
        isVisible: (value) => value.selectionType == "image",
        groups: [
          RibbonGroup(label: "圖片", commands: [commands[4]]),
        ],
      ),
      RibbonTab(
        id: "table",
        label: "表格設計",
        icon: Icons.table_chart_outlined,
        isVisible: (value) => value.selectionType == "table",
        groups: [
          RibbonGroup(label: "列與欄", commands: [commands[5]]),
        ],
      ),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: Text("文件編輯器 · ${_previewDevice.label} 預覽"),
          actions: [
            IconButton(
              tooltip: "儲存",
              onPressed: commands[2].onInvoke,
              icon: Icon(commands[2].icon),
            ),
            if (_showCommandPalette && MediaQuery.sizeOf(context).width >= 700)
              SizedBox(
                width: 300,
                child: RibbonCommandPalette(
                  commands: commands,
                  context: ribbonContext,
                ),
              ),
            MenuAnchor(
              menuChildren: [
                CheckboxMenuButton(
                  value: _showCommandPalette,
                  onChanged: (value) =>
                      setState(() => _showCommandPalette = value ?? false),
                  child: const Text("顯示命令面板"),
                ),
                CheckboxMenuButton(
                  value: _ribbonCollapsed,
                  onChanged: (value) =>
                      setState(() => _ribbonCollapsed = value ?? false),
                  child: const Text("收起 Ribbon"),
                ),
                const Divider(),
                ..._PreviewDevice.values.map(
                  (device) => MenuItemButton(
                    onPressed: () => setState(() {
                      _previewDevice = device;
                      _ribbonCollapsed = device == _PreviewDevice.phone;
                      _compactCommands = device == _PreviewDevice.phone;
                    }),
                    leadingIcon: Icon(device.icon),
                    trailingIcon: _previewDevice == device
                        ? const Icon(Icons.check)
                        : null,
                    child: Text("${device.label} 預覽"),
                  ),
                ),
              ],
              builder: (context, controller, child) => IconButton(
                tooltip: "檢視選項",
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.more_vert),
              ),
            ),
          ],
        ),
        body: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _previewDevice.width),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    MaterialRibbon(
                      tabs: tabs,
                      context: ribbonContext,
                      height: 176,
                      collapsed: _ribbonCollapsed,
                      compact: _compactCommands,
                      leadingCommands: [
                        RibbonCommand(
                          id: 'toggle-collapse',
                          label: _ribbonCollapsed ? '展開命令' : '收合命令',
                          icon: _ribbonCollapsed
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          onInvoke: () => setState(
                            () => _ribbonCollapsed = !_ribbonCollapsed,
                          ),
                        ),
                        RibbonCommand(
                          id: 'toggle-mode',
                          label: _compactCommands ? '完整命令模式' : '精簡命令模式',
                          icon: _compactCommands
                              ? Icons.view_stream_outlined
                              : Icons.view_compact_outlined,
                          onInvoke: () => setState(
                            () => _compactCommands = !_compactCommands,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _EditorCanvas(
                        selectionType: _selectionType,
                        fontFamily: _fontFamily,
                        fontSize: _fontSize,
                        color: _color,
                        lastAction: _lastAction,
                      ),
                    ),
                    _SelectionCards(
                      selected: _selectionType,
                      onSelected: (value) =>
                          setState(() => _selectionType = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontTools extends StatelessWidget {
  const _FontTools({
    required this.family,
    required this.fontSize,
    required this.color,
    required this.onFamilyChanged,
    required this.onFontSizeChanged,
    required this.onColorChanged,
    required this.onAction,
  });
  final String family;
  final double fontSize;
  final Color color;
  final ValueChanged<String> onFamilyChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 400,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactSelect<String>(
                value: family,
                values: const ['Calibri', 'Arial', 'Georgia'],
                onChanged: onFamilyChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: _CompactSelect<double>(
                value: fontSize,
                values: List.generate(65, (index) => (index + 8).toDouble()),
                onChanged: onFontSizeChanged,
              ),
            ),
            _RibbonIcon(
              icon: Icons.format_size,
              tooltip: '放大字級',
              onPressed: () => onFontSizeChanged((fontSize + 1).clamp(8, 72)),
            ),
            _RibbonIcon(
              icon: Icons.format_size_outlined,
              tooltip: '縮小字級',
              onPressed: () => onFontSizeChanged((fontSize - 1).clamp(8, 72)),
            ),
          ],
        ),
        Row(
          children: [
            _RibbonIcon(
              icon: Icons.format_bold,
              tooltip: '粗體',
              onPressed: () => onAction('粗體'),
            ),
            _RibbonIcon(
              icon: Icons.format_italic,
              tooltip: '斜體',
              onPressed: () => onAction('斜體'),
            ),
            _RibbonIcon(
              icon: Icons.format_underline,
              tooltip: '底線',
              onPressed: () => onAction('底線'),
            ),
            _RibbonIcon(
              icon: Icons.strikethrough_s,
              tooltip: '刪除線',
              onPressed: () => onAction('刪除線'),
            ),
            _RibbonIcon(
              icon: Icons.subscript,
              tooltip: '下標',
              onPressed: () => onAction('下標'),
            ),
            _RibbonIcon(
              icon: Icons.superscript,
              tooltip: '上標',
              onPressed: () => onAction('上標'),
            ),
            MenuAnchor(
              menuChildren:
                  [Colors.black, Colors.red, Colors.blue, Colors.green]
                      .map(
                        (choice) => MenuItemButton(
                          onPressed: () => onColorChanged(choice),
                          child: Icon(Icons.circle, color: choice),
                        ),
                      )
                      .toList(),
              builder: (context, controller, child) => _RibbonIcon(
                icon: Icons.format_color_text,
                color: color,
                tooltip: '文字色彩',
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
            _RibbonIcon(
              icon: Icons.draw_outlined,
              tooltip: '醒目提示',
              onPressed: () => onAction('醒目提示'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ParagraphTools extends StatelessWidget {
  const _ParagraphTools({required this.onAction});
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Wrap(
      children: [
        _RibbonIcon(
          icon: Icons.format_list_bulleted,
          tooltip: '項目符號',
          onPressed: () => onAction('項目符號'),
        ),
        _RibbonIcon(
          icon: Icons.format_list_numbered,
          tooltip: '編號',
          onPressed: () => onAction('編號'),
        ),
        _RibbonIcon(
          icon: Icons.format_align_left,
          tooltip: '靠左',
          onPressed: () => onAction('靠左對齊'),
        ),
        _RibbonIcon(
          icon: Icons.format_align_center,
          tooltip: '置中',
          onPressed: () => onAction('置中對齊'),
        ),
        _RibbonIcon(
          icon: Icons.format_align_right,
          tooltip: '靠右',
          onPressed: () => onAction('靠右對齊'),
        ),
        _RibbonIcon(
          icon: Icons.format_align_justify,
          tooltip: '左右對齊',
          onPressed: () => onAction('左右對齊'),
        ),
        _RibbonIcon(
          icon: Icons.format_indent_increase,
          tooltip: '增加縮排',
          onPressed: () => onAction('增加縮排'),
        ),
        _RibbonIcon(
          icon: Icons.format_indent_decrease,
          tooltip: '減少縮排',
          onPressed: () => onAction('減少縮排'),
        ),
      ],
    ),
  );
}

class _InsertTools extends StatelessWidget {
  const _InsertTools({required this.onAction});
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Wrap(
      children: [
        _RibbonIcon(
          icon: Icons.image_outlined,
          tooltip: '插入圖片',
          onPressed: () => onAction('插入圖片'),
        ),
        _RibbonIcon(
          icon: Icons.palette_outlined,
          tooltip: '插入圖示',
          onPressed: () => onAction('插入圖示'),
        ),
        _RibbonIcon(
          icon: Icons.account_tree_outlined,
          tooltip: '插入圖形',
          onPressed: () => onAction('插入圖形'),
        ),
        _RibbonIcon(
          icon: Icons.video_library_outlined,
          tooltip: '插入影片',
          onPressed: () => onAction('插入影片'),
        ),
      ],
    ),
  );
}

class _CompactSelect<T> extends StatelessWidget {
  const _CompactSelect({
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value')),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    ),
  );
}

class _RibbonIcon extends StatelessWidget {
  const _RibbonIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    ),
  );
}

class _EditorCanvas extends StatelessWidget {
  const _EditorCanvas({
    required this.selectionType,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.lastAction,
  });
  final String? selectionType;
  final String fontFamily;
  final double fontSize;
  final Color color;
  final String lastAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Material 3 Ribbon 範例",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                "這段文字會反映字級與文字顏色控制項。",
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  color: color,
                ),
              ),
              if (selectionType == "image")
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Placeholder(fallbackHeight: 120),
                ),
              if (selectionType == "table")
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey),
                    ),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("名稱"),
                          ),
                          Padding(padding: EdgeInsets.all(8), child: Text("值")),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("項目 A"),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("42"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(lastAction, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectionCards extends StatelessWidget {
  const _SelectionCards({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) {
    final cards = [
      _ContextCard(
        label: "文字",
        icon: Icons.text_fields,
        selected: selected == null,
        onTap: () => onSelected(null),
      ),
      _ContextCard(
        label: "圖片",
        icon: Icons.image_outlined,
        selected: selected == "image",
        onTap: () => onSelected("image"),
      ),
      _ContextCard(
        label: "表格",
        icon: Icons.table_chart_outlined,
        selected: selected == "table",
        onTap: () => onSelected("table"),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SizedBox(
            height: 104,
            child: RibbonHorizontalScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: cards,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 12, children: cards),
        );
      },
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Card(
        color: selected
            ? colors.secondaryContainer
            : colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 112,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? colors.onSecondaryContainer : null,
                ),
                const SizedBox(height: 6),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
