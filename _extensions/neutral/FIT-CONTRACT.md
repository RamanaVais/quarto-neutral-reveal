# FIT-CONTRACT.md —— 交互组件自适应契约（v1.3.0）

本文件是 `fit.css` / `fit.html` / `fit-options.lua` 与使用者文档之间**拼写固定**的约定。
`CONTRACT.md` 保持不变（它管版式骨架）；本文件管「交互组件如何适配容器」。
改名会静默破坏功能——不报错，只是图表又溢出或又被裁。

## 1. 作者接口

| 写法 | 含义 |
|:--|:--|
| `:::: {.fit}` 包一层 | 该块吃满所在 section 的剩余高度，内部 widget 自动适配。**推荐写法**（Pandoc 必定生成 `<div class="fit">`） |
| `## 标题 {.fit}` | 整页进入自适应（依赖 Pandoc 把标题类名透传到 `<section>`，未在所有版本验证，优先用上一种） |
| `data-fit-allow-scroll` | 给单个宿主允许出现滚动条（默认禁止） |
| `data-fit-static="none"` | 给单个图片 / 媒体 / 表格 / SVG **豁免**自适应（小图标、装饰图用） |
| YAML `fit-mode: off` | 整份 deck 关闭自适应 |
| YAML `fit-min-font` / `fit-max-font` | 数据表字号二分区间，默认 9 / 18 |
| YAML `fit-debug: true` | 控制台打印每页每个宿主的实测尺寸，并给未适配宿主加红框 |
| `.panel` 内的图 / 视频 / 网页 | **不要**包 `.fit`。改用 `neutral.css` H3 的 `data-media="img\|video\|frame"`（见 §7） |

**无任何 `.fit` 标记时**：`fit.css` 全部规则以 `.fit` 为前缀，`fit.html` 启动即 `return`。
不注册监听、不改 DOM、不注入样式——另外两套非交互 deck 的计算样式与改造前逐项一致。

## 2. 运行时写入的 DOM 属性

| 属性 | 写在哪 | 谁消费 | 说明 |
|:--|:--|:--|:--|
| `data-fit-host="<kind>"` | `.cell` | `fit.css` §4 | 只有装 widget 的 cell 才生长；滑块声明 cell 不打标记，保持自然高度 |
| `data-fit-static="<kind>"` | 静态内容的块级宿主 | `fit.css` §9 | kind ∈ `img` / `media` / `table` / `svg`；由 `collectStatic()` 打 |
| `data-fit-tid="tN"` | 表格宿主 | `fit.html` 注入的 `<style>` | 普通表格没有 id，用它生成稳定选择器 |
| `data-fit-warn="<原因>"` | widget / 静态宿主 | 审计脚本、人 | 塞不下时写「需要 W×H > 可用 W×H」 |
| `data-fit-debug` | `<html>` | `fit.css` §8 | 由 `fit-debug: true` 打开，只用来画红框 |
| `<style data-qfit-for="<id>">` | `<head>` | 该表格实例 | 按实例注入的字号/内边距规则，`!important` 压过 `formatStyle()` 的内联字号 |

## 3. 高度链（`fit.css` 的事实契约）

```
section（absolute, height:100%, padding 71.45/52/91.21）
└─ div.fit            height:100% → 内容盒 1176×557.34，display:flex column
   ├─ 其它子元素        flex:0 0 auto（说明文字、滑块行，绝不被压扁）
   └─ .columns         flex:1 1 auto（row 不变，align-items:stretch 让两栏等高）
      └─ .column       display:flex column；overflow:visible!important 覆盖 Pandoc 的
                       @media screen{ div.column{overflow-x:auto} }
         └─ .cell[data-fit-host]        flex:1 1 auto，column 向
            └─ .cell-output-display     flex:1 1 auto，column 向
               └─ .html-widget          height:100%!important（压过内联 height:480px）
```

静态内容走同一条链，只是多两层 Quarto 的包裹：

```
div.fit
└─ .quarto-figure[data-fit-static="img"]     flex:1 1 0（宿主 = 最外层包装）
   └─ figure                                 flex:1 1 auto
      └─ p                                   flex:1 1 auto（Quarto 把 img 包在 p 里）
         └─ img                              flex:1 1 auto + object-fit:contain
      └─ figcaption                          flex:0 0 auto（图题绝不参与伸缩）
```

表格例外：`<table>` 只能是 `display:table`，被 flex 规则接管会毁掉布局；
它的高度由内容决定，靠字号二分（`fit.html`）而不是 flex 分配空间。

**不要**给链上任一层加 `overflow:hidden` 来「消除滚动条」——那会把内容裁掉，
正是 1.0.x 的错误做法。`overflow` 只出现在 widget 叶子节点上，并靠审计保证不真裁。

## 4. 打印模式

reveal 的打印样式会 `padding:0!important` + `.pdf-page{overflow:hidden}`，
内容盒从 557.34 变成 720，偏 162.66px 并被硬裁。
`fit.css` §7 让 `.fit` 自己补回 `padding: var(--y-body) var(--pad-x) calc(60*var(--pt))`，
所以 `?print-pdf` 与屏幕版几何完全一致。**改这条之前先跑一次打印断言。**

## 5. 组件适配策略

| 类型 | 识别条件 | 做法 | 禁止 |
|:--|:--|:--|:--|
| plotly | `.html-widget.js-plotly-plot` 或裸 `.js-plotly-plot`（Python plotly） | `Plotly.relayout({width,height})` 给容器实测像素，降级 `Plots.resize` | 不改 `autosize`（会与 htmlwidgets 自带 resizeHandler 分支冲突） |
| DT | `.html-widget.datatables` | 对字号二分（9–18px），直到 `table` 的高宽都塞进容器 | 不用 `scrollY`（那就是造滚动条）；不恢复 `table-layout:fixed` |
| 普通表格 | `table` 且不在 `.datatables` 内 | 与 DT 同一套二分；`display:table` 保住表格布局 | 不给它套 flex（会毁掉行列） |
| OJS / Plot | `[id^="ojs-cell-"]` 且含 `svg` | 补 `viewBox`，删 `width/height` 属性，`xMidYMid meet` 等比 contain | 不用 `none` / `slice`（必裁切或失真） |
| 图片 / figure | `img` 宽 ≥ 栏宽 30%；宿主取 `.quarto-figure` | 宿主 flex 生长，`img` 100% + `object-fit:contain` | 不用 `cover`（必裁切） |
| iframe / video | 同上 | 同图片，`object-fit:contain` | 不改 `src` / 不加 `sandbox` |
| 任意 SVG | 有 `viewBox`、渲染宽 ≥ 200px，且不在 ojs-cell 内 | 同 OJS；额外清掉 mermaid 写的 `max-width` | 不碰 `.math-svg` / `mjx-container`（公式） |
| 其它 widget | 其余 `.html-widget`（leaflet / echarts4r / reactable…） | 只做容器约束：内部 `img/canvas/svg/iframe` 限 `max-width/height` | 不猜内部结构，不做内部重排；塞不下就写 `data-fit-warn` |

`declaration` 类型的 ojs-cell（`viewof` 滑块）、MathJax 公式、图题里的图标、宽度不足 30% 的装饰图
**永远不参与适配**。要看某页实际接管了哪些宿主，用 `QFIT.report()` 或 `fit-debug: true`。

`.panel` 内的 `img / video / iframe / table / svg` ——**永不接管**：`fit.html` 的
`collect().push()`、`collectStatic().ok()` 与 `add()` 三处都先 `el.closest('.panel')` 判空，
命中即 `return`。理由见 §7。

## 6. 幂等与重入

- 每次适配在 widget 根节点上记 `__qk = "WxH"`，尺寸没变直接返回；
- 调度用 `pending` Set + `busy` 标志 + 双 `requestAnimationFrame`，避免 reveal 过渡帧抖动；
- DT / 普通表格 / SVG 例外：每次都复核——字号二分不幂等，SVG 的 `max-width` 可能被 mermaid 事后改写。

## 7. 与 panel 的边界（1.3.0）

`.panel` 的格子高度由 CSS Grid 轨道给死（380pt 画布 → 4 宫格每轨 187.75pt，
cell 内容盒 175.75pt，横切半格内容盒约 75pt），媒体归 `neutral.css` H3 的
`data-media` 管。两套高度源互斥，**不能混用**：

- `.fit` 里不要放 `.panel`——`.fit` 的 `height:100%` 解析到 section 内容盒
  （1176×557.34），panel 的轨道高度与它无关；
- panel 内的图 / 视频 / 网页不要包 `.fit`，写 `data-media="img|video|frame"`；
- plotly / DT / OJS 等交互 widget **不要放 panel**：它们按自身默认尺寸渲染
  （plotly 退化到 450×700），塞进 175pt 的格子必被裁。要交互就拆掉 panel，整页用 `.fit`。

为什么必须在 JS 里挡：`fit.html` 会给宿主的 `.closest('.cell')` 打 `data-fit-host`，
而 `.reveal .slides section .fit .cell[data-fit-host]`（0,5,0）会把
`.panel .cell[data-split]`（0,3,0）的 `display:grid` 顶成 `flex` ——
格内二级分栏无声消失，这是最难定位的一类排版事故。

审计：`fit_audit.py check --deck x.html --panel` 会单独扫 panel 页，
断言 `data-media` 生效（`display:flex` / `flex-direction:column`）、
媒体不出界、`object-fit:contain`、叶子高度 ≥ 91px、且无 `data-fit-*` 串味。
**没有 `data-media` 的 panel 页也会被量整页溢出**：panel 固定 380pt，
标题 + 页眉 + 一段 defbox 就能把 720px 撑破 58px（实测），
这类溢出不属于任何「媒体」断言，漏掉只能靠肉眼发现。
