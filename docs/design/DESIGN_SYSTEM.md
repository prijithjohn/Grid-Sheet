# Grid Sheet — Design System & Visual Tokens

## 1. Design Philosophy: Corporate Desktop Functionalism

The visual design system of Grid Sheet is engineered for high-density, calculation-intensive desktop spreadsheet workflows. Its visual ethos blends corporate productivity precision with modern enterprise UI rigor. The interface strictly eliminates decorative distractions to prioritize:
- **Maximum visible cell density**: Compact visual metrics maximize visible rows and columns per viewport height.
- **Pixel-aligned rendering**: Crisp, single-pixel borders rather than diffused shadows optimize GPU/CPU canvas rendering on Flutter Windows desktop.
- **Strict structural zones**: Title Command Bar (36px), Ribbon Toolbar (88px), Formula Bar (28px), Grid Canvas (flexible), Sheet Management Bar (28px), Status Bar (22px).
- **Tabular alignment**: Monospaced tabular numerals (`tnum`) ensure absolute horizontal alignment across financial calculations.

---

## 2. Color Palettes & Tokens

### 2.1. Light Theme — "Grid Professional"

The primary light theme establishes an authoritative, reliable financial environment using the iconic spectrum of corporate greens paired with low-fatigue slate-tinted neutrals.

| Token Name | Hex Code | Role & Usage |
| :--- | :--- | :--- |
| **Standard Primary** | `#217346` | Core app bar header, brand accentuation, active toggle icons. |
| **Primary Container (Accent Green)** | `#107C41` | Active primary button backgrounds, sheet active indicators, focus bounding box. |
| **Deep Green (Dark Green)** | `#185C37` | Pressed buttons, high-contrast text accents, formula syntax keywords. |
| **Primary (Brand Alternate)** | `#006130` | High-contrast brand elements. |
| **Selection Fill** | `#E2F0D9` | Cell range selection fill (rendered at 12% opacity), selected header backgrounds. |
| **Canvas White** | `#FFFFFF` | Pure data grid background, formula input field, active sheet tab backing. |
| **Application Base / Recessed** | `#F5F7F6` | Surrounding chrome, unfocused toolbars, ribbon background, dock backing. |
| **Pale Green Tint** | `#F0F7F2` | Hover state on grid cells, active worksheet tab backing. |
| **Gridline Gray** | `#E3E7E4` | Non-intrusive 1px cell gridlines across the core workspace. |
| **Neutral Border** | `#D9E1DC` | Toolbar dividers, formula bar outlines, panel boundaries, inactive tabs. |
| **Primary Text** | `#202124` | High-contrast body text, formula bar text, numeric figures. |
| **Secondary Text** | `#5F6B63` | Row/column headers, status indicators, inactive controls, unit labels. |
| **Critical Red (Error)** | `#C62828` | Formula parse errors, invalid references (`#REF!`, `#VALUE!`), destructive alerts. |
| **Alert Amber (Warning)** | `#B7791F` | Circular dependency warnings, unsaved external links, warning triangles. |

### 2.2. Dark Theme — "Graphite & Mint"

The dark theme is optimized for low-light environments, extended financial modeling sessions, and reduced eye strain.

| Token Name | Hex Code | Role & Usage |
| :--- | :--- | :--- |
| **Dark Surface (Background)** | `#101412` | Deep charcoal application background. |
| **Surface Container Low** | `#181c1a` | Unfocused toolbars, ribbon backing, left navigation bar. |
| **Surface Container** | `#1c201e` | Active toolbar backing, modal dialog surfaces. |
| **Surface Container High** | `#272b29` | Hover states on dark toolbars and dialog sections. |
| **Mint Primary** | `#4edea3` | Active selection rings, primary button text, brand highlights. |
| **Mint Container** | `#10b981` | Active primary buttons, active sheet tab indicators. |
| **Dark Gridlines** | `#3c4a42` | 1px low-contrast cell borders in dark mode. |
| **On-Surface (Primary Text)** | `#e0e3df` | High-contrast white/light gray text for cells and labels. |
| **On-Surface Variant (Secondary)** | `#bbcabf` | Column/row header text, inactive controls, coordinates. |
| **Dark Selection Fill** | `#10b981` | Rendered at 15% opacity across selected cell ranges. |

---

## 3. Typography Hierarchy

Typography enforces high-density readability and strict horizontal tabular alignment:
- **`Inter`** handles all command surfaces, ribbons, menus, modal dialogs, and headers.
- **`JetBrains Mono`** with tabular lining figures (`tnum`) is enforced for spreadsheet cell contents, the formula editor bar, row/column indicators, and coordinates (`A1`, `R1C1`).

| Style Role | Font Family | Size | Weight | Line Height | Usage |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Headline LG** | Inter | 20px | 600 (SemiBold) | 26px | Main dialog titles, dashboard headers. |
| **Headline MD** | Inter | 16px | 600 (SemiBold) | 22px | Section titles, modal headers. |
| **Headline SM** | Inter | 14px | 600 (SemiBold) | 18px | Title bar brand text ("GridX"), ribbon tab labels. |
| **Body LG** | Inter | 13px | 400 (Regular) | 18px | Standard descriptions, dialog form labels. |
| **Body MD** | Inter | 12px | 400 (Regular) | 16px | Standard button labels, tooltips, status text. |
| **Body SM** | Inter | 11px | 400 (Regular) | 14px | Micro-labels, subtext, shortcut hints. |
| **Cell Data** | JetBrains Mono | 12px | 400 (Regular) | 16px | Standard spreadsheet cell values and numbers. |
| **Cell Data Bold** | JetBrains Mono | 12px | 600 (SemiBold) | 16px | Bold spreadsheet headers and totals. |
| **Formula Bar** | JetBrains Mono | 13px | 400 (Regular) | 18px | Formula input field, equation syntax. |
| **Name Box / Coordinates** | JetBrains Mono | 12px | 400 (Regular) | 16px | Active coordinate indicator (e.g. `A1`). |
| **Micro Coordinate / Tag** | JetBrains Mono | 10px | 500 (Medium) | 12px | Cell error badges, status chips. |

---

## 4. Layout Dimensions & Grid Spacing Matrix

The layout is built for zero-margin edge-to-edge desktop presentation:

| Structural Zone | Fixed Dimension | Notes |
| :--- | :---: | :--- |
| **Title Command Bar** | 36px Height | Includes app icon, filename, quick utilities, search, and window controls. |
| **Ribbon Menu Tabs** | 32px Height | File, Home, Insert, Data, Formulas, View tabs. |
| **Ribbon Action Bar** | 56px Height | Total ribbon height: 88px (expanded) or 32px (collapsed). |
| **Formula Bar** | 28px Height | Name box (64px width), `fx` button (24px), formula field. |
| **Left Tool Dock** | 48px Width | Pinned vertical icon strip for navigation, pivots, and settings. |
| **Column Header Strip** | 24px Height | Contains column letters `A`, `B`, `C`... |
| **Row Header Strip** | 36px Width | Contains row numbers `1`, `2`, `3`... |
| **Default Cell Width** | 80px Width | User-resizable down to minimum 20px. |
| **Default Cell Height** | 20px Height | User-resizable down to minimum 16px. |
| **Sheet Tab Strip** | 28px Height | Docked beneath canvas; individual tab height 26px. |
| **Status Bar** | 22px Height | Docked at bottom edge with calculation state, stats, zoom. |

---

## 5. Elevation & Layering System

To maximize desktop performance and eliminate frame drops, depth is established via structural borders and crisp tonal layering rather than soft blur shadows:

- **Layer 0 (Canvas Surface)**: `#FFFFFF` sheet cells bordered by 1px solid `#E3E7E4`.
- **Layer 1 (Recessed Surrounding Chrome)**: `#F5F7F6` for headers, formula bar, ribbon container, and status bar.
- **Layer 2 (Selected Active Cell)**: Cell perimeter framed by a 2px solid `#107C41` ring with a 5x5px fill drag-handle anchor at the bottom-right corner.
- **Layer 3 (Context Menus & Ribbon Dropdowns)**: Elevated with `#FFFFFF` background, a 1px solid `#D9E1DC` border, and a tight desktop shadow: `0 2px 4px rgba(0, 0, 0, 0.08)`.
- **Layer 4 (Native Desktop Modals)**: `#FFFFFF` surface with 1px solid `#D9E1DC` border, accompanied by `0 8px 16px rgba(0, 0, 0, 0.14)`. No backdrop blur is applied to ensure low latency.

---

## 6. Shape & Border Radius Tokens

The geometric framework is strict and squared (`roundedness: 0`), reinforcing mechanical accuracy and zero gap bleeding:
- **Cells & Gridlines**: Absolute 0px sharp corners.
- **Ribbon & Action Buttons**: 2px border radius for interactive micro-buttons.
- **Worksheet Tabs**: Top corners rounded to 2px; bottom edge flush against canvas border.
- **Modal Dialogs & Popovers**: 4px radius on floating dialog containers to match modern desktop windowing conventions.
