# Stitch Screen Inventory & UX Mapping

This document provides a comprehensive inventory of all **23 reference screens** and design prototypes extracted from the local Stitch design archive (`stitch_desktop_spreadsheet_app_design.zip`). Each entry maps visual specifications, UI components, states, and planned Flutter implementations.

---

## Screen Inventory Table

| # | Screen Name | Reference Directory | Theme | Category | Target Flutter Implementation | Status |
| :-: | :--- | :--- | :-: | :--- | :--- | :-: |
| 1 | Main Spreadsheet Editor (Expenses) | `main_spreadsheet_editor_expenses` | Light | Core Editor | `lib/features/grid/` & `lib/features/workbook/` | Planned |
| 2 | Main Spreadsheet Editor (Dark) | `main_spreadsheet_editor_expenses_dark_theme` | Dark | Core Editor | `lib/features/grid/` & `lib/features/settings/` | Planned |
| 3 | Home / Recent Workbooks | `home_recent_workbooks` | Light | Dashboard | `lib/features/home/` | Planned |
| 4 | Home / Recent Workbooks (Dark) | `home_recent_workbooks_dark_theme` | Dark | Dashboard | `lib/features/home/` | Planned |
| 5 | Login & Local Account | `login_local_account` | Light | Account / Shell | `lib/features/settings/` | Planned |
| 6 | New Workbook Creation | `new_workbook_creation` | Light | Templates | `lib/features/workbook/` | Planned |
| 7 | New Workbook Creation (Dark) | `new_workbook_creation_dark_theme` | Dark | Templates | `lib/features/workbook/` | Planned |
| 8 | Formula Editing Helper | `editor_formula_editing_helper` | Light | Formula Subsystem | `lib/features/formula_bar/` | Planned |
| 9 | Formula Error Diagnostics | `editor_formula_error_diagnostics` | Light | Diagnostics | `lib/features/formula_bar/` | Planned |
| 10 | Range Selection Aggregates | `editor_range_selection_aggregates` | Light | Status Bar | `lib/features/grid/` | Planned |
| 11 | Cell Context Menu | `editor_cell_context_menu` | Light | Grid Interaction | `lib/features/grid/` | Planned |
| 12 | Find and Replace Dialog | `editor_find_and_replace_dialog` | Light | Data Tools | `lib/features/grid/` | Planned |
| 13 | Format Cells Dialog | `editor_format_cells_dialog` | Light | Formatting | `lib/features/formatting/` | Planned |
| 14 | Custom Sort Dialog | `editor_custom_sort_dialog` | Light | Data Tools | `lib/features/grid/` | Planned |
| 15 | Column Filter Dropdown | `editor_column_filter_dropdown` | Light | Data Tools | `lib/features/grid/` | Planned |
| 16 | CSV Import Configuration Preview | `file_workflow_csv_import_configuration_preview` | Light | File Workflow | `lib/features/import_export/` | Planned |
| 17 | XLSX Compatibility Warning | `file_workflow_xlsx_compatibility_warning` | Light | File Workflow | `lib/features/import_export/` | Planned |
| 18 | Save As / Export Dialog | `file_workflow_save_as_export_dialog` | Light | File Workflow | `lib/features/file_management/` | Planned |
| 19 | Open Existing Workbook | `file_workflow_open_existing_workbook` | Light | File Workflow | `lib/features/file_management/` | Planned |
| 20 | Settings: Appearance (Dark Theme) | `settings_appearance_dark_theme` | Dark | Settings | `lib/features/settings/` | Planned |
| 21 | Settings: Account & Preferences | `settings_account_preferences` | Light | Settings | `lib/features/settings/` | Planned |
| 22 | Settings: Keyboard Shortcuts | `settings_keyboard_shortcuts` | Light | Settings | `lib/features/settings/` | Planned |
| 23 | Design System Component Library | `design_system_component_library` | Light | Design System | `lib/core/` & Component Gallery | Planned |

---

## Detailed Screen Specifications

### 1. Main Spreadsheet Editor (Expenses)
- **Reference**: `main_spreadsheet_editor_expenses/code.html` & `screen.png`
- **Primary Purpose**: Primary interactive spreadsheet workspace displaying active workbook, ribbons, formula bar, canvas, sheet tabs, and status bar in high-density corporate green light theme.
- **Main UI Components**:
  - Title Command Bar (36px): App icon, "GridX", Save (`Ctrl+S`), Undo/Redo, Filename (`Monthly Business Expenses.xlsx`), Saved badge, Command Search (`Alt+Q`), Profile badge, Windows window controls.
  - Ribbon Toolbar (88px): Home tab active with Clipboard, Font, Alignment, Number, Cells, and Editing button clusters.
  - Formula Bar (28px): Name box (`A1`), `fx` wizard button, monospaced formula input field with `=SUMIFS(...)`, expander arrow.
  - Left Tool Dock (48px): Sheet navigator, Pivot analysis, Calculated fields, Filter inspector, Workbook settings.
  - Grid Viewport: Column headers (`A`–`M`), Row headers (`1`–`45`), active selection border (`#107C41`) with 5x5px autofill handle, soft selection fill.
  - Sheet Tab Bar (28px): Tabs ("Expenses 2024", "Q3 Summary", "Raw Invoices"), Add Sheet (`+`), tab scroll buttons.
  - Status Bar (22px): Calculation mode ("Ready"), Quick stats (Average, Count, Sum), Zoom slider (100%).
- **User Interactions**: Cell click/drag selection, formula input, header resizing, tab switching, ribbon tool execution.
- **States**:
  - *Loading*: Skeleton gridline rendering.
  - *Empty*: Blank cells with default dimensions (80px x 20px).
  - *Error*: Invalid formula displaying `#VALUE!`, `#REF!`, etc.
  - *Success*: Clean rendered cell text with formatted numbers/currency.
- **Target Flutter Implementation**: `lib/features/workbook/screens/workbook_screen.dart`, `lib/features/grid/widgets/grid_viewport.dart`.
- **Open Questions**: Should the left tool dock (48px) be collapsible to maximize grid width on smaller displays?

### 2. Main Spreadsheet Editor (Dark Theme)
- **Reference**: `main_spreadsheet_editor_expenses_dark_theme/code.html` & `screen.png`
- **Primary Purpose**: Complete dark theme rendition of the main spreadsheet editor ("Graphite & Mint" palette).
- **Main UI Components**: Same as Screen 1, styled with dark surface (`#101412`), container low (`#181c1a`), high-contrast mint accents (`#4edea3`), and dark gridlines (`#3c4a42`).
- **User Interactions**: Identical to Screen 1.
- **Target Flutter Implementation**: Shared widget implementation with dynamic `ThemeData` switching.

### 3 & 4. Home / Recent Workbooks (Light & Dark)
- **Reference**: `home_recent_workbooks/code.html` & `home_recent_workbooks_dark_theme/code.html`
- **Primary Purpose**: Landing dashboard shown on app startup without an active file; displays recent files, pinned workbooks, and template launchers.
- **Main UI Components**:
  - Top search bar for filtering recent workbooks.
  - New Workbook template cards (Blank Workbook, Expense Report, Balance Sheet, Monthly Invoice).
  - Recent Files table: Workbook name, Last Modified date, File Size, Storage location, pin icon.
  - Left navigation panel: Home, New, Open, Settings, Account.
- **Target Flutter Implementation**: `lib/features/home/screens/home_screen.dart`.

### 5. Login & Local Account
- **Reference**: `login_local_account/code.html` & `screen.png`
- **Primary Purpose**: Desktop profile selection and offline local identity setup.
- **Main UI Components**: User avatar card, Organization label, local credentials/identity switch, offline mode indicator.
- **Target Flutter Implementation**: `lib/features/settings/widgets/account_profile_card.dart`.

### 6 & 7. New Workbook Creation (Light & Dark)
- **Reference**: `new_workbook_creation/code.html` & `new_workbook_creation_dark_theme/code.html`
- **Primary Purpose**: Template selection gallery providing pre-formatted workbook architectures.
- **Main UI Components**: Grid of template previews with categories (Finance, Operations, Personal, Blank).
- **Target Flutter Implementation**: `lib/features/workbook/widgets/template_gallery_dialog.dart`.

### 8. Formula Editing Helper
- **Reference**: `editor_formula_editing_helper/code.html` & `screen.png`
- **Primary Purpose**: Contextual assistance overlay displayed during formula authoring.
- **Main UI Components**:
  - Parameter syntax tooltip floating below active formula cursor: `SUMIFS(sum_range, criteria_range1, criteria1, ...)`.
  - Active argument bolding to guide user through parameter entry.
  - Quick link to documentation / function help.
- **Target Flutter Implementation**: `lib/features/formula_bar/widgets/formula_syntax_helper.dart`.

### 9. Formula Error Diagnostics
- **Reference**: `editor_formula_error_diagnostics/code.html` & `screen.png`
- **Primary Purpose**: Detailed diagnostic flyout when selecting or hovering a cell with an evaluation error (`#VALUE!`, `#REF!`, `#DIV/0!`).
- **Main UI Components**: Error alert banner, error code, plain English explanation, "Show Calculation Steps" button, and "Trace Precedents".
- **Target Flutter Implementation**: `lib/features/formula_bar/widgets/error_diagnostics_tooltip.dart`.

### 10. Range Selection Aggregates
- **Reference**: `editor_range_selection_aggregates/code.html` & `screen.png`
- **Primary Purpose**: Dynamic computation and display of statistical metrics across currently selected cells.
- **Main UI Components**: Status bar chips showing `AVERAGE: $1,420.50`, `COUNT: 45`, `NUMERICAL COUNT: 42`, `MIN: $120.00`, `MAX: $5,400.00`, `SUM: $63,922.50`.
- **Target Flutter Implementation**: `lib/features/grid/widgets/status_bar_aggregates.dart`.

### 11. Cell Context Menu
- **Reference**: `editor_cell_context_menu/code.html` & `screen.png`
- **Primary Purpose**: Right-click context menu on grid cells.
- **Main UI Components**: Cut, Copy, Paste, Paste Special (Values, Formulas, Formats), Insert Row Above/Below, Delete Row/Col, Clear Contents, Format Cells, Filter, Sort.
- **Target Flutter Implementation**: `lib/features/grid/widgets/cell_context_menu.dart`.

### 12. Find and Replace Dialog
- **Reference**: `editor_find_and_replace_dialog/code.html` & `screen.png`
- **Primary Purpose**: Modal utility for searching and replacing cell contents.
- **Main UI Components**: Find input, Replace input, Match Case, Match Entire Cell, Scope (Sheet/Workbook), Look In (Formulas/Values), Find Next, Replace, Replace All.
- **Target Flutter Implementation**: `lib/features/grid/dialogs/find_replace_dialog.dart`.

### 13. Format Cells Dialog
- **Reference**: `editor_format_cells_dialog/code.html` & `screen.png`
- **Primary Purpose**: Deep styling dialog for selected cells.
- **Main UI Components**: Tabbed modal:
  - *Number*: Category list (General, Number, Currency, Date, Percentage) with decimal places and symbol selectors.
  - *Alignment*: Horizontal, Vertical, Text wrap, Merge cells.
  - *Font*: Family, Style, Size, Color, Underline.
  - *Border*: Preset box, inner lines, line styles, border color.
  - *Fill*: Background fill color palette and sample preview.
- **Target Flutter Implementation**: `lib/features/formatting/dialogs/format_cells_dialog.dart`.

### 14. Custom Sort Dialog
- **Reference**: `editor_custom_sort_dialog/code.html` & `screen.png`
- **Primary Purpose**: Multi-column sorting builder.
- **Main UI Components**: "My data has headers" checkbox, dynamic level rows (`Sort by [Column] on [Cell Values] order [A to Z]`), Add Level, Delete Level, Copy Level, Move Up/Down.
- **Target Flutter Implementation**: `lib/features/grid/dialogs/custom_sort_dialog.dart`.

### 15. Column Filter Dropdown
- **Reference**: `editor_column_filter_dropdown/code.html` & `screen.png`
- **Primary Purpose**: Excel-style header filter popover.
- **Main UI Components**: Sort A to Z, Sort Z to A, Filter by Color, Text Filters submenu (Equals, Contains, Starts With), Search input, Select All checkbox with list of unique distinct column values.
- **Target Flutter Implementation**: `lib/features/grid/widgets/column_filter_dropdown.dart`.

### 16. CSV Import Configuration & Preview Dialog
- **Reference**: `file_workflow_csv_import_configuration_preview/code.html` & `screen.png`
- **Primary Purpose**: Interactive wizard for parsing CSV/TSV files with preview.
- **Main UI Components**: Delimiter radio/dropdown (Comma, Semicolon, Tab, Pipe, Custom), Text Encoding (UTF-8, ASCII), "First row contains headers" checkbox, 20-row live preview table, Cancel / Import buttons.
- **Target Flutter Implementation**: `lib/features/import_export/dialogs/csv_import_dialog.dart`.

### 17. XLSX Compatibility Warning Dialog
- **Reference**: `file_workflow_xlsx_compatibility_warning/code.html` & `screen.png`
- **Primary Purpose**: Modal warning when saving features or formatting to XLSX that may differ in external readers.
- **Main UI Components**: Warning icon (`warning_amber`), summary of adjusted items, "Don't show this again" checkbox, "Save Anyway" and "Cancel" buttons.
- **Target Flutter Implementation**: `lib/features/import_export/dialogs/xlsx_compatibility_dialog.dart`.

### 18. Save As / Export Dialog
- **Reference**: `file_workflow_save_as_export_dialog/code.html` & `screen.png`
- **Primary Purpose**: Export destination and format selector.
- **Main UI Components**: File format selector (`.gsheet`, `.xlsx`, `.csv`, `.tsv`, `.pdf`), file path preview, sheet selection scope (Active Sheet vs Entire Workbook).
- **Target Flutter Implementation**: `lib/features/file_management/dialogs/save_as_dialog.dart`.

### 19. Open Existing Workbook
- **Reference**: `file_workflow_open_existing_workbook/code.html` & `screen.png`
- **Primary Purpose**: File browsing modal with quick access to recent directories and local drive partitions.
- **Main UI Components**: Folder navigation tree, file list with `.gsheet` and `.xlsx` filters, Open / Cancel buttons.
- **Target Flutter Implementation**: Integrated with native OS file picker and custom recent workbook list.

### 20. Settings: Appearance (Dark Theme)
- **Reference**: `settings_appearance_dark_theme/code.html` & `screen.png`
- **Primary Purpose**: Personalization settings for themes and display contrast.
- **Main UI Components**: Theme mode selector (Light "Grid Professional", Dark "Graphite & Mint", System Match), Gridline contrast slider, Accent green tone picker.
- **Target Flutter Implementation**: `lib/features/settings/screens/appearance_settings_screen.dart`.

### 21. Settings: Account & Preferences
- **Reference**: `settings_account_preferences/code.html` & `screen.png`
- **Primary Purpose**: Desktop defaults and application preferences.
- **Main UI Components**: Default workbook settings (Default font, Default font size, Default new sheet count), Auto-save interval slider (1 min – 15 min), Measurement units.
- **Target Flutter Implementation**: `lib/features/settings/screens/preferences_screen.dart`.

### 22. Settings: Keyboard Shortcuts Reference
- **Reference**: `settings_keyboard_shortcuts/code.html` & `screen.png`
- **Primary Purpose**: Searchable catalog of all desktop spreadsheet keyboard shortcuts.
- **Main UI Components**: Search shortcut input, category tabs (Navigation, Selection, Editing, Formatting, Formulas), shortcut badge list (e.g. `Ctrl` + `Z`, `F4`, `Ctrl` + `Shift` + `L`).
- **Target Flutter Implementation**: `lib/features/settings/dialogs/keyboard_shortcuts_dialog.dart`.

### 23. Design System Component Library
- **Reference**: `design_system_component_library/code.html` & `screen.png`
- **Primary Purpose**: Living showcase of all atomic design tokens, buttons, inputs, icons, tabs, badges, and modals.
- **Main UI Components**: Color swatches, typography scale, micro-button states (Normal, Hover, Pressed, Active), dialog templates.
- **Target Flutter Implementation**: Storybook / Gallery module in test/debug builds.
