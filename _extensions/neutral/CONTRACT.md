# 稳定 DOM / 命名契约（维护者视角）

本扩展的 CSS、封面 partial、注入脚本与使用者文档之间依赖一组**拼写固定**的字符串。
这些名字语义中性，但**改名会静默破坏功能**——不报错，只是页眉、圆点导航或章节跳转消失。

对外「中性化」只改可见品牌（封面文案、徽标、配色主令牌），**不改本文件列出的内部契约**。
两份既有 demo deck 的正文因此保持逐字不动。

## 1. 页面分类与状态（`chrome.html`）

| 契约 | 消费方 | 作用 |
|:--|:--|:--|
| `id="title-slide"` | `chrome.html` 分类逻辑；`neutral.css` E 段 `section#title-slide` | 封面页；partial 的 `<section>` 必须保留此 id |
| `data-state="cover"` / `"chromeless"` | `chrome.html` 分类；`neutral.css` D 段隐藏页码 | 控制页脚页码显隐 |
| `html.cover` / `html.chromeless` | `neutral.css` D 段 | reveal 由 `data-state` 自动加到 `<html>` 上，不要改 |
| `is-cover` / `is-outline` / `is-part` / `is-content` | `chrome.html` 分类；`neutral.css` B/D/F/G 段 | 由脚本按页打上，CSS 用它切换版式 |
| `.part-meta` + `data-section` + `data-nav` | `chrome.html` 建章节表、提纲跳转；`neutral.css` G 段 `display:none` | **唯一章节数据源**，不可删、不可改属性名 |
| `.nwpu-outline` / `.nwpu-part` | `chrome.html` 分类与胶囊挂载；`neutral.css` F/G 段 | 提纲页 / PART 页容器类名 |
| `a[href^="#sec-"]` | `chrome.html` 点击跳转：去掉 `#sec-` 后与 `data-section` 比对 | 提纲链接前缀必须是 `#sec-` |
| `.nwpu-chrome`, `.nc-title`, `.nc-nav`, `.nc-chap`, `.nc-dots`, `.nc-dot`, `.nc-logo` | `chrome.html` 生成；`neutral.css` C 段 | 页眉三列与圆点导航 |
| `.nc-right` / `.nc-brand` | `chrome.html` 仅在有 `brand-header` 时生成；`neutral.css` C 段 | 页眉右侧固定文字；无配置时**不输出**，页眉 DOM 与旧版逐字一致 |
| `<meta name="neutral-brand-header">` | `brand-header.lua` 注入 `<head>`；`chrome.html` 读取 | 页眉文字的唯一数据来源，改名会让文字消失 |
| `.part-pills`, `.pill`, `.is-on` | `chrome.html` 生成；`neutral.css` G 段 | PART 页进度胶囊 |
| `.cv-*` (`cv-rings/cv-logo/cv-body/cv-tag/cv-title/cv-sub/cv-rule/cv-meta/cv-band`) | `title-slide.html`；`neutral.css` E 段 | 封面结构 |

## 2. 版式与内容（`neutral.css`）

| 契约 | 段落 | 作用 / 不可动的原因 |
|:--|:--|:--|
| `.reveal .slides section { position: absolute }` | A | 改成 `relative` 会让所有页进入正常文档流堆叠，当前页被推出视口（曾导致空白页） |
| `--pt: 1.5202px` 及全部 `calc(N * var(--pt))` | A | 强绑 1280×720 画布；改几何令牌等于重做版式 |
| `.is-part > h1 { display:none }` | G | H1 被隐藏，但它承载 `{#sec-NN}` 锚点并触发 reveal 新建 horizontal stack，**不能删** |
| `.panel` / `.cell[data-area]` / `data-mode="4,3t,3b,3l,3r"` | H | CSS Grid 真实分格，`gap` 透出底色即分格线 |
| `.cell[data-split]` / `.sub` / `--sx/--sy/--sx2/--sy2` | H2 | 格内二级细分；`.sub` 数必须等于轨道数 |
| `data-media="img\|video\|frame"`（`.cell` / `.sub`） | H3 | 格内自适应媒体：容器变 flex 列，媒体吃满剩余高度 + `object-fit:contain`；与 `data-split` 互斥（split 胜出）、与 `.fit` 互斥；**必须带值**——Pandoc 把裸词 `{data-media}` 解析成 class 而非 attribute |
| `figure.nwpu-fig` / `figcaption` / `counter(fig)` | M | 图号计数器挂在 `.reveal .slides`；增减 `<figure>` 会整体位移编号 |
| `html.print-pdf` 与 `@media print` | N | Quarto `?print-pdf` 注入的类，用于展开 fragment、隐藏导航 |
| `--nwpu-*` 变量别名 | A | 中性主令牌是 `--brand-*`，别名保留以防旧内联样式断裂 |

## 2b. Header 注入层（`brand-header.lua`）

| 契约 | 说明 |
|:--|:--|
| 注入位置 | 追加到 Pandoc 的 `header-includes`，生成 `<style id="neutral-brand">` 与 `<meta name="neutral-brand-header">`；**必须追加**，覆盖会丢掉 Quarto 自带 MathJax / reveal 资源 |
| 无参数时 | 完全不注入，也不改 AST（除 meta 外），产物与不配置时一致 |
| YAML → CSS 映射 | `brand-primary` → `--brand-primary`（另 6 个色键）、`fig-label` → `--fig-label`（自动补尾空格）、`brand-logo` / `brand-logo-file` → `--brand-logo` |
| `brand-logo-file` | 构建期用 `io.open(...,'rb')` 读文件并 base64 内联；相对项目根目录，失败时回退到输入文件所在目录；两者都找不到只报警告、不中断渲染 |
| `brand-header` | 只生成 `<meta>`，不生成 CSS；`chrome.html` 读取后插入 `.nc-brand` |
| 优先级 | 注入的 `<style>` 在 `<head>` 末尾，晚于 `neutral.css`，因此能覆盖默认令牌；用户自己的 `include-in-header` 若写在更后位置也能再覆盖 |

`chrome.html` 与 `neutral.css` 都不直接读 YAML 参数 —— 它们只消费 meta 与 CSS 变量。这样 `quarto add` 安装版和本地开发版行为一致。

## 3. 数值契约（使用者每章要同步的三处）

```
提纲条目  N. [章名](#sec-NN)
H1 标题  # 章名 {#sec-NN}
PART 块  <span class="part-meta" data-section="NN" data-nav="短章名"></span>
```

`#sec-NN` 后缀 ↔ `data-section="NN"` 必须一致，否则提纲点击**静默失效**。
`part-watermark` / `part-label` 里的编号没有 CSS counter 兜底，删中间一章要手工重排后续连号。
章节数、圆点数、胶囊数、提纲序号、页脚总页数全部由 DOM 推导，**增删章节不需要改 JS/CSS**。

## 4. 已知漂移（保留，供校验档识别）

`typst-slides/slides-reveal.qmd` 的 PART 06 存在 `data-nav="实现解剖"` 与章名
「实现解剖：代码怎么组织」不一致。校验档 `part-contract.lua` 会报出这类问题，
但不修改 AST，因此输出 DOM 保持不变。
