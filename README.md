# Material Ribbon

Material 3 Ribbon 元件，適用於 Flutter 桌面與 Web 應用程式。主分頁使用
`ChoiceChip`，支援依編輯器選取內容出現的淺色情境分頁。

## 完整範例

範例位於 `example/material_ribbon_example.dart`，包含：

- 首頁、圖片格式與表格設計等 Ribbon 分頁
- 選取文字／圖片／表格時動態顯示的情境分頁
- 字級與文字色彩控制項
- 命令的啟用條件、快捷鍵文字與執行回饋
- 預設關閉、可由右上角選單啟用的命令面板

在 `example` 目錄第一次建立預覽平台後執行：

```powershell
flutter create --platforms=windows,web .
flutter run -d windows -t material_ribbon_example.dart
```

## 命令面板為選用功能

`RibbonCommandPalette` 是獨立元件，只有將它放入你的 AppBar 或版面時才會出現：

```dart
if (showCommandPalette)
  SizedBox(
    width: 300,
    child: RibbonCommandPalette(
      commands: commands,
      context: ribbonContext,
    ),
  )
```

不加入此元件不會影響 Ribbon、情境分頁或命令執行。
