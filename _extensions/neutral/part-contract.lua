--[[
part-contract.lua —— 章节数值契约只读校验

目的：章节名 / 章号在 qmd 里有多个手工副本（提纲条目、H1 锚点、
.part-meta[data-section][data-nav]、part-title、part-watermark、part-label），
增删中间一章时容易漏改，且 `#sec-NN` 与 data-section 不一致会让提纲点击
「静默失效」。本过滤器在渲染时把文档序列化成 HTML，正则比对这几处编号，
用 quarto.log 输出诊断。

关键：**不修改 AST**（Pandoc 函数返回 nil），因此输出 DOM 与不装过滤器时
完全一致，不会触发产物变化。旧 deck 也不需要任何新语法。
]]

local function nums_equal(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local function strip(s)
  return (s:gsub('<[^>]+>', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function join(t)
  return table.concat(t, ', ')
end

function Pandoc(doc)
  local ok, html = pcall(function() return pandoc.write(doc, 'html') end)
  if not ok or type(html) ~= 'string' then return nil end

  local sections, navs, titles, watermarks, labels = {}, {}, {}, {}, {}
  for n, nav in html:gmatch('data%-section="(%d+)"%s+data%-nav="([^"]*)"') do
    sections[#sections + 1] = n
    navs[#navs + 1] = nav
  end
  -- 没有 PART 结构的普通文档：直接跳过
  if #sections == 0 then return nil end

  local h1nums, linknums = {}, {}
  for id in html:gmatch('<h1[^>]*id="sec%-(%d+)"') do h1nums[#h1nums + 1] = id end
  for id in html:gmatch('href="#sec%-(%d+)"') do linknums[#linknums + 1] = id end
  for t in html:gmatch('class="part%-title">([^<]*)<') do titles[#titles + 1] = strip(t) end
  for w in html:gmatch('class="part%-watermark">([^<]*)<') do watermarks[#watermarks + 1] = strip(w) end
  -- Pandoc 的 HTML writer 会在块内容前后插入换行，先取整块文本再剥编号
  for block in html:gmatch('class="part%-label">([^<]*)<') do
    local n = strip(block):match('PART%s+(%d+)')
    if n then labels[#labels + 1] = n end
  end

  local errs = {}
  if not nums_equal(sections, h1nums) then
    errs[#errs + 1] = 'H1 锚点 [' .. join(h1nums) .. '] 与 data-section [' .. join(sections) .. '] 不一致'
  end
  if not nums_equal(sections, linknums) then
    errs[#errs + 1] = '提纲链接 [' .. join(linknums) .. '] 与 data-section [' .. join(sections) .. '] 不一致'
  end
  if not nums_equal(sections, watermarks) then
    errs[#errs + 1] = '水印编号 [' .. join(watermarks) .. '] 与 data-section [' .. join(sections) .. '] 不一致'
  end
  if not nums_equal(sections, labels) then
    errs[#errs + 1] = 'PART 标签编号 [' .. join(labels) .. '] 与 data-section [' .. join(sections) .. '] 不一致'
  end
  for i = 2, #sections do
    if tonumber(sections[i]) ~= tonumber(sections[i - 1]) + 1 then
      errs[#errs + 1] = '章号不连续：[' .. join(sections) .. ']'
      break
    end
  end

  if #errs > 0 then
    for _, e in ipairs(errs) do
      quarto.log.warning('[part-contract] ' .. e .. '（提纲点击可能静默失效）')
    end
  else
    quarto.log.output('[part-contract] OK：' .. #sections .. ' 章，' ..
                      sections[1] .. '–' .. sections[#sections] ..
                      ' 连号；提纲 / H1 / 水印 / PART 标签编号一致')
  end

  -- data-nav 是页眉圆点上方显示的短章名，允许是章名缩写，仅列出供核对
  for i = 1, #sections do
    local title, nav = titles[i] or '', navs[i] or ''
    if title ~= '' and nav ~= '' and title ~= nav then
      quarto.log.output('[part-contract] 提示：第 ' .. sections[i] .. ' 章 data-nav="' .. nav ..
                        '" 与章名「' .. title .. '」不完全一致（页眉缩写属正常，若属笔误请核对）')
    end
  end

  -- 返回 nil = 不修改文档
  return nil
end
