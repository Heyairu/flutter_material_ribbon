import "package:flutter/material.dart";
import "package:material_ribbon/material_ribbon.dart";

void main() => runApp(const WordRibbonExample());

class WordRibbonExample extends StatefulWidget {
  const WordRibbonExample({super.key});
  @override State<WordRibbonExample> createState() => _WordRibbonExampleState();
}

class _WordRibbonExampleState extends State<WordRibbonExample> {
  bool _collapsed = false, _bold = false, _compact = false, _showPalette = true;
  double _previewWidth = 1200;
  double _fontSize = 12;
  Color _color = Colors.black;
  String? _selection;
  String _status = "準備就緒";
  void _run(String name) => setState(() => _status = "已執行：$name");

  @override Widget build(BuildContext context) {
    final value = RibbonContext(selectionType: _selection, selectionCount: _selection == null ? 0 : 1);
    RibbonCommand command(String id, String label, IconData icon, {RibbonCommandType type = RibbonCommandType.action, RibbonCommandSize size = RibbonCommandSize.medium, String? keyTip, VoidCallback? action}) =>
      RibbonCommand(id: id, label: label, icon: icon, type: type, size: size, keyTip: keyTip, onInvoke: action ?? () => _run(label));
    final save = command("save", "儲存", Icons.save_outlined, keyTip: "S");
    final undo = command("undo", "復原", Icons.undo);
    final redo = command("redo", "重做", Icons.redo);
    final tabs = [
      RibbonTab(id: "file", label: "檔案", keyTip: "F", groups: [RibbonGroup(label: "文件", commands: [command("new", "新增", Icons.note_add_outlined, size: RibbonCommandSize.large), command("print", "列印", Icons.print_outlined)])]),
      RibbonTab(id: "home", label: "常用", keyTip: "H", groups: [
        RibbonGroup(label: "剪貼簿", rows: 2, commands: [
          command("paste", "貼上", Icons.content_paste_outlined, size: RibbonCommandSize.large),
          command("cut", "剪下", Icons.content_cut, size: RibbonCommandSize.medium),
          command("copy", "複製", Icons.content_copy_outlined, size: RibbonCommandSize.medium),
        ]),
        RibbonGroup(label: "字型", rows: 2, controls: [
          SizedBox(width: 210, child: Column(children: [
            Row(children: [
              const Expanded(child: _Select(label: "PMingLiU (本文)")),
              const SizedBox(width: 6), const SizedBox(width: 54, child: _Select(label: "12")),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(isSelected: _bold, onPressed: () => setState(() => _bold = !_bold), icon: const Icon(Icons.format_bold)),
              IconButton(onPressed: () => _run("斜體"), icon: const Icon(Icons.format_italic)),
              IconButton(onPressed: () => _run("底線"), icon: const Icon(Icons.format_underline)),
              MenuAnchor(menuChildren: [Colors.black, Colors.red, Colors.blue].map((c) => MenuItemButton(onPressed: () => setState(() => _color = c), child: Icon(Icons.circle, color: c))).toList(), builder: (context, controller, _) => IconButton(onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: Icon(Icons.format_color_text, color: _color))),
            ]),
          ])),
        ], onMoreOptions: () => _run("字型設定")),
        RibbonGroup(label: "段落", rows: 2, commands: [
          command("bullet", "項目符號", Icons.format_list_bulleted, type: RibbonCommandType.menu),
          command("align-left", "靠左", Icons.format_align_left),
          command("align-center", "置中", Icons.format_align_center),
          command("indent", "縮排", Icons.format_indent_increase),
        ], onMoreOptions: () => _run("段落設定")),
        RibbonGroup(label: "樣式", rows: 2, commands: [
          command("normal", "標準", Icons.text_fields, size: RibbonCommandSize.large),
          command("heading", "標題 1", Icons.title, size: RibbonCommandSize.large),
        ]),
      ]),
      RibbonTab(id: "insert", label: "插入", keyTip: "N", groups: [RibbonGroup(label: "插圖", commands: [
        command("picture", "圖片", Icons.image_outlined, type: RibbonCommandType.split, size: RibbonCommandSize.large),
        command("table", "表格", Icons.table_chart_outlined, size: RibbonCommandSize.large),
      ])]),
      RibbonTab(id: "layout", label: "版面配置", groups: [RibbonGroup(label: "頁面設定", commands: [command("margin", "邊界", Icons.border_outer), command("orientation", "方向", Icons.screen_rotation_outlined)])]),
      RibbonTab(id: "picture-format", label: "圖片格式", isVisible: (c) => c.selectionType == "image", groups: [RibbonGroup(label: "調整", commands: [command("crop", "裁切", Icons.crop, size: RibbonCommandSize.large)])]),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xff171717), foregroundColor: Colors.white, title: Text("文件 1 · ${_previewWidth.round()}px"), actions: [
          IconButton(tooltip: _showPalette ? "隱藏命令搜尋" : "顯示命令搜尋", onPressed: () => setState(() => _showPalette = !_showPalette), icon: Icon(_showPalette ? Icons.search_off_outlined : Icons.search)),
          IconButton(tooltip: _compact ? "完整模式" : "精簡模式", onPressed: () => setState(() => _compact = !_compact), icon: Icon(_compact ? Icons.view_stream_outlined : Icons.view_compact_outlined)),
          MenuAnchor(menuChildren: [1200, 820, 390].map((width) => MenuItemButton(onPressed: () => setState(() => _previewWidth = width.toDouble()), child: Text(width == 1200 ? "桌面" : width == 820 ? "平板" : "手機"))).toList(), builder: (context, controller, _) => IconButton(tooltip: "裝置檢視", onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: const Icon(Icons.devices_outlined))),
        ]),
        body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: _previewWidth), child: Column(children: [
          MaterialRibbon(tabs: tabs, context: value, compact: _compact, collapsed: _collapsed, onCollapsedChanged: (v) => setState(() => _collapsed = v), quickAccessCommands: [save, undo, redo], commandPalette: _showPalette ? RibbonCommandPalette(commands: [save, undo, redo], context: value) : null),
          Expanded(child: Center(child: Card(child: SizedBox(width: 680, height: 420, child: Padding(padding: const EdgeInsets.all(56), child: Text("文件標題\n\n這是以現有 Ribbon 元件組成的 Word 風格範例。", style: TextStyle(fontSize: _fontSize, color: _color, fontWeight: _bold ? FontWeight.bold : FontWeight.normal))))))),
          Padding(padding: const EdgeInsets.all(10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_status), const SizedBox(width: 24), SegmentedButton<String?>(segments: const [ButtonSegment(value: null, label: Text("文字")), ButtonSegment(value: "image", label: Text("圖片"))], selected: {_selection}, emptySelectionAllowed: false, onSelectionChanged: (v) => setState(() => _selection = v.first))])),
        ]))),
      ),
    );
  }
}

class _Select extends StatelessWidget {
  const _Select({required this.label});
  final String label;
  @override Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(4)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Row(children: [Expanded(child: Text(label, overflow: TextOverflow.ellipsis)), const Icon(Icons.arrow_drop_down, size: 16)])));
}
