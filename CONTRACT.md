# 写一份 deck：必须遵守的结构契约

本格式用少数几个**固定类名**驱动页眉、圆点导航、PART 进度胶囊和提纲跳转。
它们是内部契约（名字带 `nwpu-` 只是历史拼写，语义中性），**不要改名**。
维护者视角的完整清单见 `_extensions/neutral/CONTRACT.md`。

## 一章的最小结构（三处，全部写在同一个 qmd 里）

```markdown
## 汇报提纲 {#outline}

::: {.nwpu-outline}

1. [第一章：起步](#sec-01)

:::

# 第一章：起步 {#sec-01}

<div class="nwpu-part">
<span class="part-meta" data-section="01" data-nav="起步"></span>
<div class="part-watermark">01</div>
<div class="part-label">PART 01</div>
<div class="part-title">第一章：起步</div>
<div class="part-rule"></div>
</div>

## 本章第一页

正文……
```

要点：

1. **章标题必须是 `#`（H1）**，且带 `{#sec-NN}`。它被 CSS 隐藏，但负责新建 reveal 的 horizontal stack 并承载锚点——删掉会让章节分组失效。
2. `data-section="NN"` 必须与提纲链接 `#sec-NN` 的数字一致，否则点击提纲**不跳转也不报错**。
3. `data-nav` 是页眉圆点上方显示的短章名，建议 ≤ 6 个字。
4. `part-watermark` / `part-label` 的编号没有自动连号，删中间一章要手工重排后面的 `01…NN`。
5. 章节数、每章圆点数、PART 胶囊数、提纲序号、页脚总页数**全部自动推导**，增删章节无需改 CSS 或 JS。

## 其它固定拼写

| 用途 | 写法 |
|:--|:--|
| 提纲页 | `::: {.nwpu-outline}` + 有序列表 |
| PART 页 | `class="nwpu-part"` + `.part-meta` / `.part-watermark` / `.part-label` / `.part-title` / `.part-rule` |
| 图与自动图号 | `<figure class="nwpu-fig">` + `<figcaption>` |
| panel 分格 | `::::: {.panel data-mode="4" style="--px:50%;--py:50%"}` → `:::: {.cell data-area="a"}` |
| 格内细分 | `data-split="v|h|v3|h3"` + `::: {.sub}`，子格数必须等于轨道数（`v/h` → 2，`v3/h3` → 3） |
| 讲者备注 | `::: {.notes}` |
| fragment | `. . .` 或 `::: {.fragment}` |

## 页眉固定文字（可选，不影响结构）

在 qmd 顶层加一行即可；扩展会自动注入 `<head>`，不需要写任何 HTML 或 CSS：

```yaml
brand-header: "某某单位 · 课程名"
```

不写就不显示，页眉保持「本页标题｜章节圆点导航｜徽标」三列；写了则在徽标左侧多一列小字。封面、提纲、PART 页是 `chromeless`，本来就没有页眉，这一设置只影响普通内容页。文字建议 ≤ 20 字，章数多时会压缩中间导航。

配色、logo、图号前缀等其它品牌参数见 README「Header 注入与品牌参数化」。

## 容易踩的坑

- **不要在 panel 内套 `::: {.columns}`**，三层 `overflow:hidden` 会静默裁掉内容。
- **不要改 `.reveal .slides section` 的 `position:absolute`**，会推出空白页。
- 图号是 CSS 计数器，reveal 只渲染当前页时同章可能显示重复编号；正文里不要写「见图 N」。
- 中文破折号 `——` 会被 Pandoc 转成 `---` 而意外分页，正文请用「：」或「，」代替。
- 封面标签「汇报人：」「依托单位：」是通用中文，若要改请覆盖 `template-partials: [title-slide.html]`。
