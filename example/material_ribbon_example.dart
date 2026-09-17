import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_ribbon/material_ribbon.dart";

/// Copy-ready application template for every public Material Ribbon widget.
/// Keep command definitions and editor state in the host application.
void main() => runApp(const RibbonTemplateApp());

class RibbonTemplateApp extends StatelessWidget {
  const RibbonTemplateApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const RibbonTemplatePage(),
      );
}

class RibbonTemplatePage extends StatefulWidget {
  const RibbonTemplatePage({super.key});

  @override
  State<RibbonTemplatePage> createState() => _RibbonTemplatePageState();
}

class _RibbonTemplatePageState extends State<RibbonTemplatePage> {
  bool _collapsed = false, _compact = false, _showPalette = true, _showBackstage = false;
  bool _bold = false, _italic = false, _underline = false, _busy = false;
  double _previewWidth = 1200, _fontSize = 12;
  Color _committedColor = Colors.black, _previewColor = Colors.black;
  String _fontFamily = "PMingLiU (本文)", _paragraphAlignment = "靠左";
  String _lineSpacing = "1.0", _style = "標準", _findText = "";
  String _backstagePage = "資訊", _status = "準備就緒";
  String? _selectionType;
  RibbonPersonalization _personalization = const RibbonPersonalization();

  RibbonContext get _context => RibbonContext(
        selectionType: _selectionType,
        selectionCount: _selectionType == null ? 0 : 1,
        values: {"isBusy": _busy},
      );

  void _run(String name) => setState(() => _status = "已執行：$name");
  void _toggleBold() => setState(() {
        _bold = !_bold;
        _status = _bold ? "已套用粗體" : "已移除粗體";
      });
  Future<void> _simulateSave() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() {
        _busy = false;
        _status = "已儲存文件";
      });
    }
  }

  RibbonCommand _command(
    String id,
    String label,
    IconData icon, {
    RibbonCommandType type = RibbonCommandType.action,
    RibbonCommandSize size = RibbonCommandSize.medium,
    String? keyTip,
    String? description,
    String? shortcut,
    VoidCallback? onInvoke,
    bool Function(RibbonContext)? isEnabled,
    String? Function(RibbonContext)? disabledReason,
    bool Function(RibbonContext)? isBusy,
    RibbonCheckState Function(RibbonContext)? checkState,
    List<RibbonCommand> menuCommands = const [],
    List<RibbonGalleryItem<Object?>> galleryItems = const [],
    Object? Function(RibbonContext)? selectedValue,
    ValueChanged<Object?>? onGalleryPreview,
    VoidCallback? onGalleryPreviewEnd,
  }) => RibbonCommand(
        id: id, label: label, icon: icon, type: type, size: size,
        keyTip: keyTip, description: description, shortcut: shortcut,
        onInvoke: onInvoke ?? () => _run(label), isEnabled: isEnabled,
        disabledReason: disabledReason, isBusy: isBusy, checkState: checkState,
        menuCommands: menuCommands, galleryItems: galleryItems,
        selectedValue: selectedValue, onGalleryPreview: onGalleryPreview,
        onGalleryPreviewEnd: onGalleryPreviewEnd,
      );

  @override
  Widget build(BuildContext context) {
    final save = _command("save", "儲存", Icons.save_outlined,
        keyTip: "S", shortcut: "Ctrl+S", description: "將目前的文件變更寫入磁碟",
        onInvoke: _simulateSave, isBusy: (value) => value.values["isBusy"] == true);
    final undo = _command("undo", "復原", Icons.undo, keyTip: "U");
    final redo = _command("redo", "重做", Icons.redo, keyTip: "R");
    final allCommands = <RibbonCommand>[save, undo, redo];
    final tabs = _buildTabs(allCommands);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff171717), foregroundColor: Colors.white,
        title: Text("Ribbon 完整元件模板 · ${_previewWidth.round()}px"),
        actions: [_paletteButton(), _compactButton(), _qatModeMenu(), _devicePreviewMenu()],
      ),
      body: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _previewWidth),
        child: _showBackstage
            ? _backstagePreview()
            : Column(children: [
                MaterialRibbon(
                  tabs: tabs, context: _context, compact: _compact, collapsed: _collapsed,
                  onCollapsedChanged: (value) => setState(() => _collapsed = value),
                  quickAccessCommands: [save, undo, redo], personalization: _personalization,
                  onPersonalizationChanged: (value) => setState(() => _personalization = value),
                  headerActions: [
                    RibbonActionChip(
                      label: "開啟 Backstage",
                      icon: const Icon(Icons.description_outlined, size: 18),
                      onPressed: () => setState(() {
                        _showBackstage = true;
                        _status = "已開啟 Backstage";
                      }),
                    ),
                  ],
                  showCustomizationButton: true,
                  shortcuts: [RibbonShortcut(id: "save-document", activator: const SingleActivator(LogicalKeyboardKey.keyS, control: true), onInvoke: _simulateSave, description: "儲存文件")],
                  commandPalette: _showPalette ? RibbonCommandPalette(commands: allCommands, context: _context) : null,
                ),
                Expanded(child: _editorPreview()),
                _statusBar(),
              ]),
      )),
    );
  }

  List<RibbonTab> _buildTabs(List<RibbonCommand> allCommands) {
    final paste = _command("paste", "貼上", Icons.content_paste_outlined, size: RibbonCommandSize.large, keyTip: "P");
    final cut = _command("cut", "剪下", Icons.content_cut);
    final copy = _command("copy", "複製", Icons.content_copy_outlined);
    final bold = _command("bold", "粗體", Icons.format_bold,
        type: RibbonCommandType.toggle,
        checkState: (_) => _bold ? RibbonCheckState.checked : RibbonCheckState.unchecked,
        onInvoke: _toggleBold);
    final bullets = _command("bullets", "項目符號", Icons.format_list_bulleted,
        type: RibbonCommandType.menu, menuCommands: [
          _command("bullets-dot", "圓點", Icons.circle_outlined),
          _command("bullets-number", "編號", Icons.format_list_numbered),
        ]);
    final picture = _command("picture", "圖片", Icons.image_outlined,
        type: RibbonCommandType.split, size: RibbonCommandSize.large, menuCommands: [
          _command("picture-file", "從檔案插入", Icons.folder_open_outlined),
          _command("picture-camera", "從相機插入", Icons.camera_alt_outlined),
        ]);
    final styleGallery = _command("styles", "樣式", Icons.style_outlined,
        type: RibbonCommandType.gallery, galleryItems: _styleItems,
        selectedValue: (_) => _style, onInvoke: () => _run("選取樣式"),
        onGalleryPreview: (value) => _run("預覽樣式：$value"),
        onGalleryPreviewEnd: () => _run("已結束樣式預覽"));
    allCommands.addAll([paste, cut, copy, bold, bullets, picture, styleGallery]);

    return [
      RibbonTab(id: "file", label: "檔案", keyTip: "F", groups: [
        RibbonGroup(label: "文件", commands: [
          _command("new", "新增", Icons.note_add_outlined, size: RibbonCommandSize.large),
          _command("print", "列印", Icons.print_outlined, size: RibbonCommandSize.large),
        ]),
      ]),
      RibbonTab(id: "home", label: "常用", keyTip: "H", groups: [
        RibbonGroup(label: "剪貼簿", rows: 2, commands: [paste, cut, copy]),
        RibbonGroup(label: "字型", rows: 2, controls: [_fontControls()], onMoreOptions: () => _run("字型設定")),
        RibbonGroup(label: "段落", rows: 2, commands: [
          bullets,
          _command("align-left", "靠左", Icons.format_align_left, onInvoke: () => setState(() => _paragraphAlignment = "靠左")),
          _command("align-center", "置中", Icons.format_align_center, onInvoke: () => setState(() => _paragraphAlignment = "置中")),
          _command("indent", "縮排", Icons.format_indent_increase),
        ], onMoreOptions: () => _run("段落設定")),
        // The `gallery` command opens a menu; this embedded gallery shows
        // the controlled-selection variant that updates the document preview.
        RibbonGroup(label: "樣式選單", rows: 2, commands: [styleGallery]),
        RibbonGroup(label: "樣式", rows: 2, controls: [_originalStyleControls()]),
      ], compactCommands: [paste, bold, bullets]),
      RibbonTab(id: "insert", label: "插入", keyTip: "N", groups: [
        RibbonGroup(label: "插圖", commands: [picture, _command("table", "表格", Icons.table_chart_outlined, size: RibbonCommandSize.large)]),
        RibbonGroup(label: "連結", commands: [_command("link", "連結", Icons.link_outlined), _command("comment", "註解", Icons.comment_outlined)]),
      ]),
      RibbonTab(id: "view", label: "檢視", keyTip: "W", groups: [
        RibbonGroup(label: "顯示", commands: [
          _command("ruler", "尺規", Icons.straighten, type: RibbonCommandType.toggle, checkState: (_) => RibbonCheckState.mixed),
          _command("zoom", "縮放", Icons.zoom_in),
        ]),
      ]),
      RibbonTab(id: "picture-format", label: "圖片格式", keyTip: "J",
          isVisible: (value) => value.selectionType == "image", groups: [
        RibbonGroup(label: "調整", commands: [
          _command("crop", "裁切", Icons.crop, size: RibbonCommandSize.large),
          _command("remove-background", "移除背景", Icons.auto_fix_high,
              isEnabled: (value) => value.hasSelection,
              disabledReason: (_) => "請先選取圖片"),
        ]),
        RibbonGroup(label: "替代文字", rows: 1, controls: [
          RibbonTextBox(value: _findText, width: 190, label: "描述", hintText: "輸入替代文字", onChanged: (value) => setState(() => _findText = value)),
        ]),
      ]),
    ];
  }

  Widget _fontControls() => SizedBox(
        width: 312,
        child: RibbonCol(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RibbonRowGrid(
              spacing: 6,
              children: [
                RibbonFontPicker(
                  fonts: const [
                    "PMingLiU (本文)",
                    "Arial",
                    "Calibri",
                    "Times New Roman",
                  ],
                  value: _fontFamily,
                  onChanged: (value) =>
                      setState(() => _fontFamily = value ?? _fontFamily),
                ),
                RibbonSpinBox(
                  value: _fontSize,
                  min: 8,
                  max: 72,
                  label: "pt",
                  width: 82,
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
              ],
            ),
            RibbonRowGrid(
              children: [
                RibbonRowGrid(
                  spacing: 0,
                  children: [
                    IconButton(
                      isSelected: _bold,
                      tooltip: "粗體",
                      onPressed: _toggleBold,
                      icon: const Icon(Icons.format_bold),
                    ),
                    IconButton(
                      isSelected: _italic,
                      tooltip: "斜體",
                      onPressed: () => setState(() => _italic = !_italic),
                      icon: const Icon(Icons.format_italic),
                    ),
                    IconButton(
                      isSelected: _underline,
                      tooltip: "底線",
                      onPressed: () => setState(() => _underline = !_underline),
                      icon: const Icon(Icons.format_underline),
                    ),
                  ],
                ),
                RibbonColorPicker(
                  label: "文字色彩",
                  colors: const [
                    Colors.black,
                    Colors.red,
                    Colors.orange,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                  ],
                  value: _committedColor,
                  onChanged: (color) => setState(() {
                    _committedColor = color;
                    _previewColor = color;
                  }),
                  onPreview: (color) =>
                      setState(() => _previewColor = color),
                  onPreviewEnd: () =>
                      setState(() => _previewColor = _committedColor),
                ),
                SizedBox(
                  width: 104,
                  child: RibbonComboBox<String>(
                    label: "行距",
                    value: _lineSpacing,
                    items: const [
                      RibbonComboBoxItem(value: "1.0", label: "1.0"),
                      RibbonComboBoxItem(value: "1.5", label: "1.5"),
                      RibbonComboBoxItem(value: "2.0", label: "2.0"),
                    ],
                    onChanged: (value) =>
                        setState(() => _lineSpacing = value ?? _lineSpacing),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Generic base component: the first three styles stay in the ribbon and
  /// the expander reveals the complete gallery.
  Widget _originalStyleControls() => RibbonFeaturedGallery<String>(
        items: _styleChoices,
        featuredValues: const ["標準", "標題 1", "引用", "程式碼"],
        selectedValue: _style,
        moreTooltip: "更多樣式",
        onSelected: (value) => setState(() => _style = value),
        onPreview: (value) => _run("預覽樣式：$value"),
        onPreviewEnd: () => _run("已結束樣式預覽"),
      );

  List<RibbonGalleryItem<String>> get _styleChoices => [
        const RibbonGalleryItem(value: "標準", label: "標準", preview: Text("AaBbCc", style: TextStyle(fontSize: 17))),
        const RibbonGalleryItem(value: "標題 1", label: "標題 1", preview: Text("AaBb", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
        const RibbonGalleryItem(value: "引用", label: "引用", preview: Text("“AaBb”", style: TextStyle(fontStyle: FontStyle.italic))),
        const RibbonGalleryItem(value: "程式碼", label: "程式碼", preview: Text("code", style: TextStyle(fontFamily: "monospace"))),
      ];

  List<RibbonGalleryItem<Object?>> get _styleItems => _styleChoices
      .map((item) => RibbonGalleryItem<Object?>(
            value: item.value,
            label: item.label,
            preview: item.preview,
          ))
      .toList();

  Widget _editorPreview() => Center(child: Card(child: SizedBox(width: 700, height: 430, child: Padding(
        padding: const EdgeInsets.all(48),
        child: Text("文件編輯器模板\n\n此範例可直接複製作為專案的 Ribbon 起點。\n\n• Action、Toggle、Menu、Split、Gallery 命令\n• Font、SpinBox、Color、ComboBox、TextBox 控制項\n• QAT、個人化、命令搜尋、KeyTips\n• 以「檔案」Chip 進入 Backstage\n\n樣式：$_style  ·  對齊：$_paragraphAlignment  ·  行距：$_lineSpacing", style: TextStyle(fontFamily: _fontFamily, fontSize: _fontSize, color: _previewColor, fontWeight: _bold ? FontWeight.bold : FontWeight.normal, fontStyle: _italic ? FontStyle.italic : FontStyle.normal, decoration: _underline ? TextDecoration.underline : null)),
      ))));

  Widget _backstagePreview() => Row(children: [
        SizedBox(width: 190, child: ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text("Backstage", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final page in const ["資訊", "開啟", "列印"])
              RibbonChip(label: page, icon: Icon(page == "資訊" ? Icons.info_outline : page == "開啟" ? Icons.folder_open_outlined : Icons.print_outlined), selected: _backstagePage == page, onSelected: (_) => setState(() { _backstagePage = page; _status = "Backstage：$page"; })),
            const Spacer(),
            RibbonChip(label: "返回文件", icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { _showBackstage = false; _status = "已返回文件"; })),
          ]),
        ))),
        const VerticalDivider(width: 1),
        Expanded(child: Center(child: Card(child: SizedBox(width: 560, child: Padding(
          padding: const EdgeInsets.all(36),
          child: Text("$_backstagePage\n\n這裡是由「檔案」RibbonChip 觸發的 Backstage 工作區。\n\n可在此放置文件資訊、開啟／另存與列印等全文件層級操作。", style: Theme.of(context).textTheme.titleLarge),
        ))))),
      ]);

  Widget _statusBar() => Padding(padding: const EdgeInsets.all(10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_status), const SizedBox(width: 24),
        SegmentedButton<String?>(segments: const [ButtonSegment(value: null, label: Text("文字")), ButtonSegment(value: "image", label: Text("圖片"))], selected: {_selectionType}, emptySelectionAllowed: false, onSelectionChanged: (value) => setState(() => _selectionType = value.first)),
      ]));

  Widget _paletteButton() => IconButton(tooltip: _showPalette ? "隱藏命令搜尋" : "顯示命令搜尋", onPressed: () => setState(() => _showPalette = !_showPalette), icon: Icon(_showPalette ? Icons.search_off_outlined : Icons.search));
  Widget _compactButton() => IconButton(tooltip: _compact ? "完整模式" : "精簡模式", onPressed: () => setState(() => _compact = !_compact), icon: Icon(_compact ? Icons.view_stream_outlined : Icons.view_compact_outlined));
  Widget _qatModeMenu() => RibbonPopup(
        menuChildren: [
          MenuItemButton(
            onPressed: () => setState(
              () => _personalization = const RibbonPersonalization(),
            ),
            child: const Text("使用程式預設 QAT"),
          ),
          MenuItemButton(
            onPressed: () => setState(
              () => _personalization = _personalization.copyWith(
                quickAccessCustomized: true,
                quickAccessCommandIds: const [],
              ),
            ),
            child: const Text("清空 QAT"),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          tooltip: "QAT 模式",
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.more_horiz),
        ),
      );

  Widget _devicePreviewMenu() => RibbonPopup(
        menuChildren: [1200, 820, 390]
            .map(
              (width) => MenuItemButton(
                onPressed: () =>
                    setState(() => _previewWidth = width.toDouble()),
                child: Text(
                  width == 1200 ? "桌面" : width == 820 ? "平板" : "手機",
                ),
              ),
            )
            .toList(),
        builder: (context, controller, _) => IconButton(
          tooltip: "裝置檢視",
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.devices_outlined),
        ),
      );
}
