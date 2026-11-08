# 版本历史

版本号遵循语义化：`MAJOR.MINOR.PATCH`。格式名 `neutral-revealjs` 与 `_extensions/neutral/` 内的类名 / 属性名是**跨版本稳定契约**（见 `CONTRACT.md`），改动会升 MINOR 并在下面写清楚。

> 说明：1.1.0 与 1.2.0 从未单独打 tag，能力是随 1.3.0 一起发布的。这里按开发顺序列出，方便回溯「某个特性是哪一版引入的」。

## v1.3.0

格内媒体 `data-media`，以及一份完整讲义示例。

**新增**

- `neutral.css` H3 段：`.panel > .cell[data-media]` 与 `.panel [data-split] > .sub[data-media]` 变 flex 列，高度从 grid 轨道一路传到叶子，末尾 `object-fit:contain`。支持 `img` / `video` / `frame` 三种值；`frame` 额外用 `--media-ar` 控比例（`object-fit` 对 iframe 无效，只承诺盒子与比例）。
- `examples/lecture.qmd`：40+ 屏真实讲义，作为回归样本；`examples/assets/` 与 `examples/figures/` 为其素材。
- 仓库根 `figures/`：`template.qmd` 用的两张图 + 一段 5 秒演示视频 + 一个本地网页。
- `template.qmd` 新增一屏「格内媒体：图 / 视频 / 网页」四宫格活样例。
- 仓库根 `_quarto.yml`：只声明 `project: type: default`，让 `examples/lecture.qmd` 能向上找到 `_extensions/`。
- `CHANGELOG.md`（本文件）。

**修复**

- `fit.html` 三处（`collect().push()` / `collectStatic().ok()` / `add()`）跳过 `el.closest('.panel')`：此前 `.fit` 页里放 panel，会给 cell 打上 `data-fit-host`，而 `.reveal .slides section .fit .cell[data-fit-host]`（0,5,0）会把 `.panel .cell[data-split]`（0,3,0）的 `display:grid` 顶成 `flex`，格内二级分栏无声消失。
- `template.qmd` 的 PART 页恢复 `<span class="part-meta" data-section data-nav>`：中间某个版本把它改成了围栏 div，导致 `chrome.html` 拿不到章节号（圆点导航与 PART 胶囊不生成、提纲点击静默失效），`part-contract.lua` 找不到 `data-section` 直接跳过校验。同一处还把 `part-watermark` / `part-label` / `part-title` 改回原始 HTML 块——契约过滤器按 HTML 正则取文本，包一层 `<p>` 就取不到。
- `template.qmd` 删掉 panel 页尾的 defbox：panel 固定 380pt（约 578px），加标题与页眉已经把 720px 占满，再塞提示框会溢出 58px 被页脚盖住。文字移入讲者备注。
- `.quartoignore` 由全层级 `*.html` 改为根锚定 `/*.html` + `/examples/*.html`：旧写法会把 `figures/media/embed-demo.html` 一并剔出 `quarto use template` 的复制结果，示例页 iframe 指向不存在的文件，而使用者侧没有任何报错。

**变更**

- `template.qmd` 冒号层级统一为 5 / 4 / 3（panel / cell / sub），与文档其余部分一致。

## v1.2.0（未单独发布）

`.fit` 从「交互组件」扩到「静态内容」。

- 图片 / figure、iframe / video、普通 markdown 表格、Mermaid·Graphviz·手写 SVG 全部纳入高度链；`htmlwidget` 除 plotly / DT 外走容器约束。
- 表格字号二分（9–18px）替代 `scrollY`；DT 去掉 `autoWidth` 改自动列宽。
- 打印护栏：`html.reveal-print` 下 `section` 去 padding，`.pdf-page` 兜 `overflow:hidden`。

## v1.1.0（未单独发布）

`.fit` 交互自适应。

- `fit.css` / `fit.html` / `fit-options.lua` / `FIT-CONTRACT.md`：plotly（`relayout({width,height})`）、DT、OJS·Observable Plot（补 `viewBox`）、其它 htmlwidget。
- YAML 开关 `fit-mode` / `fit-min-font` / `fit-max-font` / `fit-debug` / `fit-allow-scroll`；`data-fit-static="none"` 可单块 opt-out。
- 无 `.fit` 标记时零干预：不改 DOM、不注册监听。

## v1.0.1

首次公开发布（GitHub Release `v1.0.1`）。

- 中性可配置主题：封面、页眉三列、顶部圆点章节导航、PART 胶囊与进度、卡片、公式、图号、讲者备注、fragment、`?print-pdf`。
- CSS Grid panel：五种 `data-mode`（4 / 3t / 3b / 3l / 3r），`data-split="v|h|v3|h3"` 格内二级细分。
- `brand-header.lua` header 注入层：作者 / 单位 / 标语 / 页眉文字 / 配色 / logo 全部走顶层 YAML，logo 构建期内联、单文件版 0 外链。
- `part-contract.lua` 章节数值契约校验；`CONTRACT.md` 稳定契约清单。
