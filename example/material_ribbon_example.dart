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
  Color _committedColor = Colors.black;
  String _fontFamily = "PMingLiU (本文)", _style = "標準", _findText = "";
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
          SizedBox(width: 300, child: Column(children: [
            Row(children: [
              Expanded(child: RibbonFontPicker(fonts: const ["PMingLiU (本文)", "Arial", "Calibri", "Times New Roman"], value: _fontFamily, onChanged: (value) => setState(() => _fontFamily = value ?? _fontFamily))),
              const SizedBox(width: 6), RibbonSpinBox(value: _fontSize, min: 8, max: 72, label: "pt", width: 82, onChanged: (value) => setState(() => _fontSize = value)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(constraints: const BoxConstraints.tightFor(width: 40, height: 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, isSelected: _bold, onPressed: () => setState(() => _bold = !_bold), icon: const Icon(Icons.format_bold)),
              IconButton(constraints: const BoxConstraints.tightFor(width: 40, height: 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, onPressed: () => _run("斜體"), icon: const Icon(Icons.format_italic)),
              IconButton(constraints: const BoxConstraints.tightFor(width: 40, height: 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, onPressed: () => _run("底線"), icon: const Icon(Icons.format_underline)),
              RibbonColorPicker(
                label: "文字色彩",
                colors: const [Colors.black, Colors.red, Colors.orange, Colors.green, Colors.blue, Colors.purple, Colors.brown, Colors.grey],
                value: _committedColor,
                onChanged: (color) => setState(() { _committedColor = color; _color = color; }),
                onPreview: (color) => setState(() => _color = color),
                onPreviewEnd: () => setState(() => _color = _committedColor),
              ),
            ]),
          ])),
        ], onMoreOptions: () => _run("字型設定")),
        RibbonGroup(label: "段落", rows: 2, commands: [
          command("bullet", "項目符號", Icons.format_list_bulleted, type: RibbonCommandType.menu),
          command("align-left", "靠左", Icons.format_align_left),
          command("align-center", "置中", Icons.format_align_center),
          command("indent", "縮排", Icons.format_indent_increase),
        ], onMoreOptions: () => _run("段落設定")),
        RibbonGroup(label: "樣式", rows: 2, controls: [MenuAnchor(
          menuChildren: [SizedBox(width: 312, child: RibbonGallery<String>(
          items: const [
            RibbonGalleryItem(value: "標準", label: "標準", preview: Text("AaBbCc", style: TextStyle(fontSize: 17))),
            RibbonGalleryItem(value: "標題 1", label: "標題 1", preview: Text("AaBb", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
            RibbonGalleryItem(value: "引用", label: "引用", preview: Text("“AaBb”", style: TextStyle(fontStyle: FontStyle.italic))),
            RibbonGalleryItem(value: "標題 2", label: "標題 2", preview: Text("AaBb", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            RibbonGalleryItem(value: "標題 3", label: "標題 3", preview: Text("AaBb", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            RibbonGalleryItem(value: "副標題", label: "副標題", preview: Text("AaBb", style: TextStyle(color: Colors.grey))),
            RibbonGalleryItem(value: "強調", label: "強調", preview: Text("AaBb", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
            RibbonGalleryItem(value: "書名", label: "書名", preview: Text("AaBb", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown))),
            RibbonGalleryItem(value: "程式碼", label: "程式碼", preview: Text("code", style: TextStyle(fontFamily: "monospace"))),
          ],
          selectedValue: _style,
          columns: 4,
          cellSize: const Size(72, 56),
          onSelected: (style) => setState(() => _style = style),
          onPreview: (style) => _run("預覽樣式：$style"),
        ))],
          builder: (context, controller, _) => Container(
            height: 84,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final name in ['標準', '標題 1', '引用'])
                SizedBox(width: 68, height: 82, child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    backgroundColor: _style == name ? Theme.of(context).colorScheme.secondaryContainer : null,
                  ),
                  onPressed: () => setState(() => _style = name),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('AaBb', style: TextStyle(fontSize: 19,
                      fontWeight: name == '標題 1' ? FontWeight.bold : FontWeight.normal,
                      fontStyle: name == '引用' ? FontStyle.italic : FontStyle.normal)),
                    const SizedBox(height: 8),
                    Text(name, style: const TextStyle(fontSize: 12)),
                  ]),
                )),
              const VerticalDivider(width: 1),
              SizedBox(width: 28, height: 82, child: IconButton(
                tooltip: '更多樣式',
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.unfold_more),
              )),
            ]),
          ),
        )]),
      ]),
      RibbonTab(id: "insert", label: "插入", keyTip: "N", groups: [RibbonGroup(label: "插圖", commands: [
        command("picture", "圖片", Icons.image_outlined, type: RibbonCommandType.split, size: RibbonCommandSize.large),
        command("table", "表格", Icons.table_chart_outlined, size: RibbonCommandSize.large),
      ])]),
      RibbonTab(id: "layout", label: "版面配置", groups: [RibbonGroup(label: "頁面設定", commands: [command("margin", "邊界", Icons.border_outer), command("orientation", "方向", Icons.screen_rotation_outlined)])]),
      RibbonTab(id: "picture-format", label: "圖片格式", isVisible: (c) => c.selectionType == "image", groups: [
        RibbonGroup(label: "調整", commands: [command("crop", "裁切", Icons.crop, size: RibbonCommandSize.large)]),
        RibbonGroup(label: "搜尋", rows: 1, controls: [RibbonTextBox(value: _findText, width: 180, label: "描述", hintText: "替代文字", onChanged: (value) => setState(() => _findText = value))]),
      ]),
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
          Expanded(child: Center(child: Card(child: SizedBox(width: 680, height: 420, child: Padding(padding: const EdgeInsets.all(56), child: Text("文件標題\n\n這是以現有 Ribbon 元件組成的 Word 風格範例。\n目前樣式：$_style", style: TextStyle(fontFamily: _fontFamily, fontSize: _fontSize, color: _color, fontWeight: _bold ? FontWeight.bold : FontWeight.normal))))))),
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
