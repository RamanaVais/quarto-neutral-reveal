# Neutral Reveal

一个**中性可配置**的 Quarto reveal.js 格式扩展：封面、页眉三列（含可配置固定文字）、顶部圆点章节导航、PART 进度胶囊、CSS Grid 分格 panel（含格内二级细分）、卡片、公式、图号、讲者备注、fragment 与 `?print-pdf` 全部开箱可用。

默认外观不含任何真实机构名称或校徽，只有可替换的占位文字与中性几何徽标。作者 / 单位 / 标语 / **页眉文字** / 配色 / logo 全部由顶层 YAML 参数驱动，扩展自带的 `brand-header.lua` 会自动把它们注入 HTML 的 `<head>`；版式几何来自一套 Typst 蓝金主题，但**不分发任何第三方 VI 资源**。当前版本 1.0.1。

## 快速开始

**环境**：Quarto ≥ 1.8（本机 1.11.9 实测）。reveal.js 由 Quarto 内置，无需另装；看 HTML 不需要 Python / Chrome / TeX；中文依赖本机系统字体。

```bash
# 方式一：从零起一个 deck（推荐）
mkdir mydeck && cd mydeck
quarto use template --no-prompt RamanaVais/quarto-neutral-reveal
quarto render mydeck.qmd            # template.qmd 会被自动重命名为目录名

# 方式二：装进已有项目
quarto add RamanaVais/quarto-neutral-reveal
```

仓库地址：<https://github.com/RamanaVais/quarto-neutral-reveal>；固定到已发布版本可写 `RamanaVais/quarto-neutral-reveal@v1.0.1`。本地演练可用本地目录路径或 zip。  
`quarto add` **只安装 `_extensions/` 里的内容**，仓库根目录的 README / LICENSE / 渲染产物不会被带过去；LICENSE 请到仓库查看。

从 GitHub 安装时扩展落在 `_extensions/RamanaVais/neutral/`，用本地目录路径 / zip 安装时落在 `_extensions/neutral/`。两者格式名都是 `neutral-revealjs`，Quarto 会自动重写 CSS 与过滤器路径，**不需要改 qmd**。

`quarto use template` 必须在**目标目录内**执行（它只接受一个 `<target>` 参数）。

## 最小 qmd

```markdown
---
title: "我的汇报"
subtitle: "副标题"
author: "张三"
institute: "某某单位"
date: today
# brand-header: "某某单位 · 课程名"   # 可选：每页页眉右侧固定文字
embed-resources: true       # 顶层，-M 才能覆盖
html-math-method: mathml    # 顶层，-M 才能覆盖
format: neutral-revealjs
---

## 汇报提纲 {#outline}

::: {.nwpu-outline}

1. [第一章](#sec-01)

:::

# 第一章 {#sec-01}

<div class="nwpu-part">
<span class="part-meta" data-section="01" data-nav="第一章"></span>
<div class="part-watermark">01</div>
<div class="part-label">PART 01</div>
<div class="part-title">第一章</div>
<div class="part-rule"></div>
</div>

## 第一页

正文…… $E = mc^2$
```

完整可运行骨架见 `template.qmd`（含公式、fragment、讲者备注、panel 细分格、图号）。  
章节结构的固定写法与坑见 **[CONTRACT.md](CONTRACT.md)** —— 增删章节不需要改 JS/CSS，但 `#sec-NN` 与 `data-section` 必须一致。

## Header 注入与品牌参数化

所有品牌参数都是 **qmd 顶层的自定义 YAML 键**。扩展的 `brand-header.lua` 在渲染时读取它们，往 `<head>` 追加一段 `<style id="neutral-brand">`（颜色 / 图号 / logo）和一条 `<meta name="neutral-brand-header">`（页眉固定文字）；`chrome.html` 再读这条 meta，把文字放到每页页眉右侧、徽标左边。**没有任何品牌参数时不注入任何东西**，页眉也不会多出 DOM 节点，产物与旧版完全一致。

| 想改什么          | 顶层 YAML 键                                                                                                                      | 说明                                                                          |
| :------------ | :----------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| 标题 / 副标题 / 日期 | `title` / `subtitle` / `date`                                                                                                  | 封面 Pandoc 变量                                                                |
| 汇报人 / 依托单位    | `author` / `institute`                                                                                                         | 封面，改了立即生效                                                                   |
| 封面顶部 tag      | `brand-tagline`                                                                                                                | 不写回退到 `institute`，再回退到中性占位                                                  |
| 封面底部色带        | `brand-unit`                                                                                                                   | 同上                                                                          |
| **页眉右侧固定文字**  | **`brand-header`**                                                                                                             | 单位 / 课程名等；删掉该行即不显示，建议 ≤ 20 字                                                |
| 主色 / 辅色 / 浅色系 | `brand-primary`、`brand-accent`、`brand-accent-soft`、`brand-primary-light`、`brand-primary-pale`、`brand-accent-light`、`brand-ink` | 对应 `:root` 的 `--brand-*` 令牌                                                 |
| 页眉与封面徽标       | `brand-logo-file`                                                                                                              | **推荐**：图片路径（相对项目根目录或绝对路径），构建期自动读文件转 data URI                                |
| 同上            | `brand-logo`                                                                                                                   | 直接给 CSS 值，如 `'url("data:image/png;base64,…")'`；与 `brand-logo-file` 同时写时后者优先 |
| 图号前缀          | `fig-label`                                                                                                                    | 默认「图 」；尾部空格会自动补齐                                                            |
| 页码 / 菜单       | `slide-number` / `menu` 等                                                                                                      | 在 `format:` 下覆盖扩展默认值                                                        |

一段可复制的配置：

```yaml
title: "我的汇报"
author: "张三"
institute: "某某大学"
brand-header: "某某大学 · 知识库工程"
brand-primary: "#0B4F4A"
brand-accent: "#B98A3E"
brand-logo-file: "assets/logo.png"
fig-label: "Figure "
embed-resources: true
html-math-method: mathml
format: neutral-revealjs
```

`template.qmd` 默认只启用 `brand-header: "YOUR ORGANIZATION · COURSE"` 作为活样例，其余参数以注释形式列出，取消注释即可生效。

**为什么 logo 要构建期内联**：`embed-resources` 按*工作目录*解析 CSS 里的相对 `url()`，CSS 一旦内联成 `data:` URI 就丢失路径基准；扩展在 `quarto add` 与 `quarto use template` 两种安装方式下目录也不同。所以 `neutral.css` 的默认徽标是内联 SVG data URI，而 `brand-logo-file` 由过滤器在构建期读文件并转成 data URI —— 单文件版与 live 版都保持 0 外链，**不需要随包分发图片目录**。支持 png / jpg / jpeg / svg / gif / webp；找不到文件时渲染日志会给出 `[brand-header] 找不到 …` 警告。可选 VI 皮肤接入模板见 `_extensions/neutral/skin-nwpu.css`（不含任何第三方标识）。

**高级：批量覆盖 CSS 变量** 仍可用 `include-in-header`。不要用 `format: ...: css: my.css`，那会替换掉扩展默认的 `neutral.css`：

```yaml
include-in-header:
  - text: |
      <style>
      :root { --card-stroke: #C9D3E2; --fig-label: "Fig. "; }
      </style>
```

注入层写在 `<head>` 末尾，优先级高于 `neutral.css`；两种写法可以叠加。

## 双产物

```bash
# 单文件自包含版：CSS / 图片 / MathML 全内联，拷 1 个文件、断网可看
quarto render mydeck.qmd -o mydeck.html

# live 现场版：S 键讲者视图、MathJax 公式、打印全功能
quarto render mydeck.qmd -M embed-resources:false -M html-math-method:mathjax -o mydeck-live.html
```

`-M` 覆盖的是**文档顶层** metadata；`embed-resources` 与 `html-math-method` 请始终写在 qmd 顶层，不要写进 `format:` 块。

|         | 单文件版            | live 版                                                                                      |
| :------ | :-------------- | :------------------------------------------------------------------------------------------ |
| 分发携带    | 仅 `mydeck.html` | `mydeck-live.html` + `mydeck_files/` + `figures/`（若有内容图）+ 扩展安装目录下的 `neutral.css` |
| 公式      | 构建期 MathML（离线）  | MathJax（需联网，jsdelivr CDN）                                                                   |
| 讲者视图    | 可能失效            | 正常                                                                                          |
| 改 CSS 后 | 必须重渲            | 改 `neutral.css` 刷新即可                                                                        |

live 版的外链主题样式指向**扩展安装目录**下的 `neutral.css`（Quarto 保留扩展目录的相对路径，不会复制进 `*_files/`）。路径随安装方式变化：从 GitHub 安装是 `_extensions/RamanaVais/neutral/neutral.css`，从本地目录 / zip 安装是 `_extensions/neutral/neutral.css`。以生成 HTML 里的 `<link href="...">` 为准，把对应目录一起带上；路径由 Quarto 自动重写，格式名与渲染行为不受影响。因为该 CSS 内已无相对路径图片，携带这一个文件即可，不需要额外 logo 资产。

其它：`?print-pdf` 导 PDF、`M` 键目录、`S` 键讲者视图、`.fragment` 动画、`::: {.notes}` 备注、圆点点击跳转都可用。

## 章节契约校验

扩展自带只读过滤器 `part-contract.lua`，每次渲染自动检查五处章号副本：

- 提纲 `href="#sec-NN"`、H1 锚点 `{#sec-NN}`、`.part-meta[data-section="NN"]`、`part-watermark`、`PART NN` 是否一致且连号；
- `data-nav` 与 `part-title` 的文案差异（页眉短名缩写属正常，仅作提示）。

不一致时输出 `(W)` 警告，例如把 `data-section` 改错会一次报出 H1、提纲、水印、PART 标签四项。这项检查是必要的：`#sec-NN` 与 `data-section` 不匹配时，点击提纲**不跳转也不报错**。过滤器返回 `nil`、不修改 AST，因此输出 DOM 与不装过滤器时完全一致，不需要重渲已有产物。

正常 deck 的输出形如：`[part-contract] OK：7 章，01–07 连号；提纲 / H1 / 水印 / PART 标签编号一致`。

## 排障索引

| 现象                             | 检查                                                                                                             |
| :----------------------------- | :------------------------------------------------------------------------------------------------------------- |
| 封面还是别人的名字                      | 改 `author` / `institute`；或设 `brand-tagline` / `brand-unit` 覆盖                                                  |
| 页眉固定文字不显示                      | `brand-header` 是否写在**文档顶层**（不能缩进到 `format:` 下）、是否被注释掉；`template.qmd` 默认带一行占位文字                                 |
| 页眉右侧文字挤到章节导航                   | 文字过长，建议 ≤ 20 字，或删掉 `brand-header`                                                                              |
| 页眉 / 封面徽标空白                    | 用 `brand-logo-file` 指到真实存在的文件；看渲染日志是否有 `[brand-header] 找不到 …`                                                  |
| 主色 / 图号前缀改了没生效                 | 参数是否写在顶层；`head` 里应出现 `<style id="neutral-brand">`                                                              |
| `Could not fetch resource ...` | 自定义 CSS 里出现了相对 `url()`；改用 `brand-logo-file` 或 data URI                                                         |
| 圆点 / 胶囊不出现                     | PART 页是否含 `.part-meta[data-section][data-nav]`；章标题是否为 H1                                                       |
| 提纲点击不跳转                        | `#sec-NN` 与 `data-section="NN"` 是否一致                                                                           |
| 出现空白页 / 当前页被推走                 | 是否把 `.reveal .slides section` 的 `position:absolute` 改掉了                                                        |
| `-M` 覆盖没生效                     | 两个键是否误写进了 `format:` 块                                                                                          |
| 不带文件名 `quarto render` 走了别的格式   | 显式指定 qmd 文件名；文档级 `format: neutral-revealjs` 才会生效                                                               |
| 公式不渲染 / 显示成原始 TeX              | live 版需联网（MathJax CDN）；单文件版需浏览器原生 MathML 支持，且个别复杂 TeX（如带 `\,` 的积分式）Pandoc 构建期无法转换，会回退成 TeX 文本，请改用简单公式或切 live 版 |
| 中文破折号导致分页                      | `——` 会被 Pandoc 转成 `---`，改用「：」或「，」                                                                              |

## Quarto 1.11.9 实测行为（维护依据）

| 项                                                              | 结论                                                                                                                                             |
| :------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| `contributes.format` / `formats`                               | 单数与复数**都生效**；本仓库采用单数，与 `quarto-touying-typst` 一致                                                                                               |
| `css` / `template-partials` / `include-after-body` / `filters` | 相对 `_extensions/neutral/` 解析成功；Quarto 把 `css` 重写为 `_extensions/neutral/neutral.css`；`filters: [part-contract.lua, brand-header.lua]` 两个过滤器互不干扰 |
| `pandoc.write(doc, 'html')`                                    | 在 Lua 过滤器中可用（demo deck 序列化约 68 KB），用于只读契约校验                                                                                                    |
| `Meta()` 追加 `header-includes`                                  | **`html` 与 `revealjs` 都生效**，`<style>` 确实落在 `<head>`；必须追加（`MetaList` 或转成 list），直接覆盖会丢掉 Quarto 自带资源                                              |
| Lua 读二进制 + base64                                              | 构建期可读 32 KB PNG 并生成 43 KB data URI，单文件版与 live 版都 0 外链                                                                                          |
| `pandoc.utils.stringify` 尾空格                                   | YAML `"Figure "` 的尾空格会被吃掉；`fig-label` 由注入层自动补一个分隔符                                                                                             |
| CSS 变量 → 浏览器                                                   | `--brand-*` 颜色、`--fig-label` 字符串、`--brand-logo` 的 `url()` 在 `background` / `content` 中均正确展开                                                    |
| 自定义 YAML 键                                                     | 透传为 Pandoc 变量，连字符（`brand-unit`）与下划线（`brand_unit`）写法均可                                                                                          |
| `$for(author)$` / `$for(institute)$`                           | 生效，标量字符串也能迭代一次                                                                                                                                 |
| `-M` 对扩展内默认值                                                   | **可以覆盖**（`embed-resources` / `html-math-method` 实测可切到 live 版）；但为兼容旧版本，仍建议把两键写在文档顶层                                                             |
| `var()` 在 `background` / `content`                             | 均正确展开，`--fig-label` 参数化成立                                                                                                                      |
| `quarto add <本地目录>`                                            | 只安装 `_extensions/`，根目录文件不带                                                                                                                     |
| `quarto use template --no-prompt <本地目录>`                       | 在目标目录内执行；`template.qmd` 自动重命名为目录名；生成项目可直接渲染                                                                                                    |
| `.quartoignore`                                                | 必需：根目录的 `*.html` / `*_files/` 等产物默认会被一起复制给使用者                                                                                                  |
| `quarto add RamanaVais/quarto-neutral-reveal`                    | 公开 GitHub 仓库安装成功，识别为 `Neutral Reveal 1.0.1 (format)`，扩展落在 `_extensions/RamanaVais/neutral/`                                                  |
| `quarto use template --no-prompt RamanaVais/quarto-neutral-reveal` | 自动装好扩展，复制 `CONTRACT.md` / `examples/` / 重命名后的 qmd；单文件版与 live 版均渲染通过，live 版 CSS 链到 `_extensions/RamanaVais/neutral/neutral.css`        |

## 已知限制

- 单文件版讲者视图可能失效；`chalkboard` 与 `embed-resources` 冲突，默认关闭。
- 字体使用系统字体栈，未随仓库分发字体文件；换机器字形与行高可能变化，进而影响 `--pt` 几何观感。
- 图号由 CSS 计数器生成，reveal 只渲染当前页时同章可能显示重复编号；正文不要写「见图 N」。
- `--pt` 与全部几何令牌绑定 1280×720，改画布尺寸等于重做版式。
- `data-split` 子格容量有限（横切半格约 89pt、三格每轨约 62pt），过长代码块 / 表格会被三层 `overflow:hidden` 静默裁切。
- `brand-header` 文字与章节圆点导航共用页眉一行；章数多时右侧文字会压缩中间导航，建议缩短到 20 字以内或关闭。
- `html-math-method: mathml` 是构建期转换，少数复杂 TeX 会转换失败并回退成 TeX 文本（渲染时会有 `[WARNING] Could not convert TeX math`）；`template.qmd` 已改用可转换的简单公式，需要复杂公式请用 live 版的 MathJax。

## 目录结构

```
_extensions/neutral/          ← quarto add 实际安装的全部内容
                              （从 GitHub 安装会多一层 owner：_extensions/RamanaVais/neutral/）
  _extension.yml              格式默认值
  neutral.css                 主题样式（A–P 段）
  title-slide.html            封面 Pandoc partial
  chrome.html                 页眉 / 圆点导航 / 胶囊注入脚本
  brand-header.lua            header 注入层：YAML 品牌参数 → <head> 的 style/meta
  part-contract.lua           章节数值契约只读校验
  skin-nwpu.css               可选 VI 皮肤接入模板（不含第三方标识）
  CONTRACT.md                 维护者视角的稳定契约清单
template.qmd                  最小可运行骨架（quarto use template 的入口）
CONTRACT.md                   使用者视角的章节结构写法
examples/brand-overrides.css  配色覆盖示例
.quartoignore                 排除渲染产物
README.md  LICENSE
```

## 授权

代码采用 MIT，见 [LICENSE](LICENSE)。**校徽 / VI 标识、视觉规范与字体文件不在授权范围内，本仓库不分发这些资产**；使用方须自行取得授权。版式结构参考 `quarto-touying-typst`（Kazuharu Yanagimoto）及 Quarto / Pandoc / Reveal.js 上游项目，本扩展不附带也不修改其代码。

