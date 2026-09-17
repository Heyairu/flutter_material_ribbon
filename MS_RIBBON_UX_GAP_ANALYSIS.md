# 與 Microsoft Ribbon 的 UX 差異盤點

本文件比較 `material_ribbon` 與 Microsoft Office／Windows Ribbon 的**互動、資訊架構、工作流程與可及性**差異。

## 比較範圍

- **不討論外觀**：不涵蓋色彩、字型、間距、圖示、圓角、Material 與 Fluent 視覺語言。
- **不重複外部接管 API 建議**：不重列 KeyTip 控制器、外部 Tab 控制、命令調度、快捷鍵 registry、popup lifecycle、focus controller、個人化 JSON、版面狀態通知及捲動控制等項目。請參閱 [EXTERNAL_API_RECOMMENDATIONS.md](EXTERNAL_API_RECOMMENDATIONS.md)。
- Microsoft 的 Windows Ribbon Framework 是較早期的桌面框架；本文件將它視為成熟 Ribbon 工作模式的參考，而非要求逐項複製 Office。

## 差異與建議

| 優先度 | UX 面向 | 現況 | MS Ribbon 的工作模式 | 建議 |
| --- | --- | --- | --- | --- |
| P0 | Contextual command UX | `RibbonTab.isVisible` 只能依 context 顯示／隱藏獨立 tab。 | 使用者選到特定物件時，會出現一組與該物件相關的 contextual tabs；離開選取範圍後整組消失，讓使用者能理解「目前選取物件帶來哪些操作」。 | 新增 contextual tab set 的概念：set ID、顯示條件、成員 tabs、啟用／失效時的選取 tab fallback，以及可供輔助技術理解的 set 名稱。 |
| P1 | Context menu 與 Mini Toolbar | 套件主要提供 Ribbon 上方命令面；沒有與選取物件直接相連的 contextual menu／mini toolbar 模式。 | Ribbon 工作模式可搭配 context menu 與 mini toolbar，讓高頻文字或物件操作能在游標／選取附近完成，不必回到上方。 | 提供可由同一份 command definition 派生的 `RibbonContextMenu` 與 `RibbonMiniToolbar`，並支援依 `RibbonContext` 篩選命令。 |
| P1 | 自訂工作流完整度 | 目前可選 QAT 命令、顯示／隱藏 tab、調整 tab 順序。 | Office 使用者可重設自訂、匯入／匯出自訂、建立自訂 tab 與 group，並在選項中集中管理。 | 加入「重設為預設值」、匯入／匯出與 validation；若不支援自訂 tab/group，應明確定義只支援哪些個人化範圍。 |
| P1 | 群組層級 overflow | 群組在空間不足時沒有自己的「更多命令」收納工作流；橫向捲動是主要取得被遮蔽命令的方式。 | 成熟 Ribbon 會把命令以群組為單位縮減或折疊，使用者仍能從目前群組取得完整功能集。 | 支援 group overflow menu，並讓 overflow 項目保留啟用、busy、toggle state、disabled reason 和快捷鍵資訊。 |
| P1 | 說明與可發現性 | Tooltip 僅組合 label、停用原因與 shortcut；沒有命令層級說明、教學或 Help 連結。 | Ribbon 的 ScreenTip 可提供命令用途與補充說明，並常提供與該命令相關的 Help 入口，降低首次使用門檻。 | 擴充命令說明模型：簡短摘要、較完整的說明、Help topic／URL；F1 應能在可支援的情境導向目前聚焦命令的說明。 |
| P1 | 鍵盤以外的完整輸入模式 | Gallery preview 主要以 pointer hover 驅動；沒有明確定義 touch、pen、trackpad 與鍵盤如何取得相同的 preview、commit、cancel 體驗。 | Windows 指引要求同一任務可透過不同輸入方式一致完成，尤其是選擇、捲動、文字編輯及快捷操作。 | 為 gallery、menu、spin box、combo box 定義 keyboard／touch／pen 的相等行為；特別補上焦點移動時 preview、Enter commit、Esc restore 的規則。 |
| P1 | 文字輸入與標準編輯命令 | `RibbonTextBox` 是受控欄位，但未明確定義剪下、複製、貼上、復原、選取全部及其與 Ribbon shortcut 的優先順序。 | Windows 使用者預期可編輯文字能以鍵盤、滑鼠／觸控板、觸控與筆完成標準文字操作。 | 撰寫輸入優先權規範：文字輸入控制項優先取得其標準 editing shortcuts；Ribbon 全域快捷鍵不得攔截正在輸入的文字。 |
| P2 | Tab 收合的直接操作 | 目前可透過 `Ctrl+F1` 或收合按鈕切換。 | Office 使用者也可直接對 tab 操作來收合／展開 Ribbon，減少移動到額外按鈕或記憶快捷鍵的需要。 | 加入 tab 的雙擊收合／展開，並在觸控情境選擇不易誤觸的替代操作。 |
| P2 | 輔助技術的結構化語意 | 已有 tab、group 與 command surface 的基本 semantics，但 contextual 關係、群組折疊／overflow、命令狀態變化與 popup 開關的宣告規範不完整。 | 成熟的 command surface 需讓螢幕閱讀器理解目前區域、群組、可用命令、選取／混合狀態與展開狀態，而不只讀出按鈕名稱。 | 為所有互動 surface 訂定 semantics contract：role、checked/mixed、expanded、has popup、disabled reason、contextual set 與狀態變化 announcement。 |
| P2 | 錯誤、忙碌與完成回饋 | 可顯示 command busy，但缺少對長工作、失敗與完成的使用者流程規範。 | Ribbon 命令的結果應清楚反映在文件、狀態列、通知或可復原流程中；不能只讓按鈕沉默失效。 | 定義 command feedback policy：短操作的即時狀態、長操作的進度／取消、失敗的可理解訊息，以及完成後可撤銷或查看結果的入口。 |

## 最小可行改善順序

若目標是先讓體驗接近成熟桌面 Ribbon，而非一次做齊 Office，建議依下列順序實作：

2. **Contextual tab set**：讓選取物件與可用命令有清楚的關聯。
4. **Context menu／mini toolbar**：讓高頻選取操作不必來回切換注意力。
5. **輸入等價與語意規範**：補齊 keyboard、touch、pen 與輔助技術的一致性。

## 不建議直接照搬的 Microsoft 行為

- 不必實作所有 Office 檔案頁面、帳戶、雲端或列印功能；Backstage 應只是可組合的容器。
- 不必為了仿真而讓每個 group 都折疊；僅在命令密度高且橫向捲動顯著降低可發現性時使用 overflow。
- 不必提供 mini toolbar 給所有情境；它最適合文字選取、圖片與圖形等具有明確 on-object command 的情境。
- 不應把 domain-specific 的 Undo/Redo、文件儲存規則或錯誤訊息硬寫入套件；套件應提供工作流支點與一致的呈現契約。

## 參考依據

- Microsoft 說明 Windows Ribbon 將命令邏輯與呈現控制項分離，並以 adaptive layout 在執行時調整控制項配置：[Understanding Commands and Controls](https://learn.microsoft.com/en-us/windows/win32/windowsribbon/windowsribbon-commandscontrols)。
- Windows Ribbon Framework 的開發指南列出 contextual UI、gallery 與 size definitions／scaling policies 等核心工作模式：[Windows Ribbon Framework Developer Guides](https://learn.microsoft.com/en-us/windows/win32/windowsribbon/windowsribbon-guides-entry)。
- Windows 對跨輸入方式、文字操作與小尺寸視窗捲動可達性的指引：[Windows app development best practices](https://learn.microsoft.com/en-us/windows/apps/get-started/best-practices)。

