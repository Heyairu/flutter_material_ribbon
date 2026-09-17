# 外部接管 API 建議

本文件以「讓宿主 App 能完整接管行為與狀態」為判準，整理 `material_ribbon` 建議公開的 API。

> 這裡的 API 指 Flutter package 的公開介面，不是 HTTP／REST API。

## 建議總覽

| 優先度 | 建議開放 | 現況限制 | 建議形式 |
| --- | --- | --- | --- |
| P0 | KeyTip 控制器 | KeyTip 狀態完全私有；外部無法開啟、關閉、指定層級或得知觸發結果。 | `RibbonKeyTipController`：`showHeader()`、`showCommands(tabId)`、`hide()`；加上 `onKeyTipStateChanged`、`onKeyTipUnhandled`。 |
| P0 | 目前選取 Tab | `_selectedTabId` 私有，外部無法程式化切換或同步路由／文件狀態。 | `selectedTabId` + `onSelectedTabChanged`，或 `RibbonController.selectTab(id)`。 |
| P0 | 命令調度 | `RibbonCommand.onInvoke` 只有無參數同步 callback；外部難以統一記錄、權限檢查、IPC、Undo/Redo 或非同步處理。 | `onCommandInvoked(CommandInvocation event)` 或 `RibbonCommandDispatcher`。事件應包含 command ID、來源、tab ID 與 payload。 |
| P0 | Gallery 選值 payload | `gallery` 類命令選中項目後只呼叫 `onInvoke()`，會遺失實際選取值。 | `onGallerySelected: ValueChanged<Object?>`，或統一由 `CommandInvocation.value` 傳遞。 |
| P1 | KeyTip 註冊與擴充 | 自訂 `controls`、`headerActions`、Backstage 與 QAT overflow 無法接上 KeyTip。 | 公開 `RibbonKeyTipTarget`／`keyTip` wrapper，或接受 `headerKeyTipTargets`、`controlKeyTipTargets`。 |
| P1 | 快捷鍵集中管理 | `shortcuts` 僅在 Ribbon focus 範圍內生效，也無法觀察衝突或覆寫內建鍵。 | `RibbonShortcutRegistry` 或 controller；支援註冊、解除註冊、衝突查詢與 app scope。 |
| P1 | 非同步命令生命週期 | `isBusy(context)` 要宿主自行維護；無法以 `Future` 自動管理 loading、失敗與重入。 | 支援 `FutureOr<void> Function(...)` handler，並提供 `onCommandError` 與重入策略。 |
| P1 | Menu／Split／Popup 生命週期 | 外部不能可靠接管開啟、關閉、動態載入或定位。 | `onMenuOpen`、`onMenuClose`、`menuBuilder` 或 `galleryBuilder`。 |
| P1 | Ribbon focus／導覽 | 外部無法要求 Ribbon 聚焦、切換 KeyTip 模式或攔截左右鍵／Home／End。 | `focusNode`、`autofocus`、`onNavigationIntent`，或在 controller 提供 focus/navigation API。 |
| P2 | 個人化資料序列化 | Store 已可外接，但 `RibbonPersonalization` 沒有 `toJson/fromJson`、版本與 migration 機制。 | JSON codec、schema version 與 migration hook。 |
| P2 | 版面狀態 | `compact` 可強制，但外部無法得知自動斷點切換的結果。 | `onLayoutModeChanged(RibbonLayoutMode)`；公開 breakpoint 設定。 |
| P2 | 文案／本地化 | 多處中文與英文 tooltip 寫死，外部難以接管 i18n。 | `RibbonLocalizations` 或文案 delegate。 |
| P3 | 捲動控制 | `RibbonHorizontalScrollView` 自建 controller，外部無法捲到指定 tab 或 group。 | 接受可選 `ScrollController`，並提供 `scrollToTab`／`scrollToGroup`。 |

## KeyTip：應優先處理

目前 KeyTip 的狀態與按鍵處理都在私有的 `_MaterialRibbonState._onKey` 中；外部只能透過 `RibbonTab.keyTip` 與 `RibbonCommand.keyTip` 提供顯示字串。

這會讓下列情境無法實作或難以維護：

- 自訂 header action、外掛控制項及 Backstage 的 KeyTip。
- 教學導引或自動化操作時，由外部開啟、關閉或指定 KeyTip 層級。
- 宿主 App 統一協調 Ribbon、編輯器與其他面板的鍵盤輸入。
- 未匹配 KeyTip 的紀錄、提示與 fallback 行為。

建議將 KeyTip 設計為「控制器 + 可註冊目標」，而非只增加幾個 callback。

```dart
final keyTips = RibbonKeyTipController();

MaterialRibbon(
  keyTipController: keyTips,
  // ...
)

keyTips.showHeader();
keyTips.showCommands('home');
keyTips.hide();
```

`RibbonKeyTipController` 至少應能公開目前狀態，例如：

```dart
enum RibbonKeyTipLevel { hidden, header, commands }

class RibbonKeyTipState {
  const RibbonKeyTipState({required this.level, this.tabId});

  final RibbonKeyTipLevel level;
  final String? tabId;
}
```

## 命令調度：以事件取代分散 callback

建議保留既有 `onInvoke` 作為相容層，但新增統一的調度事件，讓宿主可以處理記錄、權限、非同步執行、Undo/Redo 及遠端接管。

```dart
MaterialRibbon(
  controller: ribbon,
  selectedTabId: selectedTabId,
  onSelectedTabChanged: setSelectedTab,
  onCommandInvoked: dispatchCommand,
  // ...
)

Future<void> dispatchCommand(CommandInvocation event) async {
  // 例如：記錄、權限檢查、呼叫編輯器、同步 busy 狀態。
}
```

事件建議帶有足夠的上下文：

```dart
enum RibbonInvocationSource { button, keyTip, shortcut, commandPalette, menu, gallery }

class CommandInvocation {
  const CommandInvocation({
    required this.commandId,
    required this.source,
    this.tabId,
    this.value,
  });

  final String commandId;
  final RibbonInvocationSource source;
  final String? tabId;
  final Object? value;
}
```

其中 `value` 對 gallery、下拉選單、色彩與字型等「選值型」命令尤其重要。

## 建議維持為內部實作的項目

下列項目不需要為了外部接管而公開：

- 命令按鈕的固定尺寸、群組排版與 responsive 演算法。
- KeyTip overlay 的 widget 實作細節。
- 內部 tab list 的可變狀態。

外部真正需要接管的是意圖、狀態、資料與生命週期；視覺排版的細節則應保留給元件內部演進。
