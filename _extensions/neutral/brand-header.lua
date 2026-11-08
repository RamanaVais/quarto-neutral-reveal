--[[
brand-header.lua —— 扩展自带的 header 注入层

把 YAML 顶层的品牌参数写进 HTML 的 <head>：
  · 颜色 / 图号前缀 / logo  →  <style id="neutral-brand">:root{...}</style>
  · 页眉固定文字            →  <meta name="neutral-brand-header" content="...">

为什么用 Lua 而不是 include-in-header 文件：
  Quarto 的 include-in-header 是 raw 插入，文件里的 $brand-primary$ 之类
  Pandoc 变量不会被展开；而 Lua filter 能读 doc.meta 并生成真正的 CSS。
  通过追加到 header-includes（不是覆盖），Quarto 自带的 MathJax / reveal
  资源不会丢失。Quarto 1.11.9 实测 html 与 revealjs 两种格式均生效。

brand-logo-file 在构建期读取图片并转成 data URI，因此单文件版与 live 版
都不依赖外部图片路径，彻底绕开「扩展 CSS 里相对 url() 无解」的问题。
]]
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local MIME = {
  png = 'image/png', jpg = 'image/jpeg', jpeg = 'image/jpeg',
  svg = 'image/svg+xml', gif = 'image/gif', webp = 'image/webp',
}

local COLOR_KEYS = {
  { 'brand-primary',        '--brand-primary' },
  { 'brand-accent',         '--brand-accent' },
  { 'brand-accent-soft',    '--brand-accent-soft' },
  { 'brand-primary-light',  '--brand-primary-light' },
  { 'brand-primary-pale',   '--brand-primary-pale' },
  { 'brand-accent-light',   '--brand-accent-light' },
  { 'brand-ink',            '--brand-ink' },
}

local function log(msg)
  if quarto and quarto.log and quarto.log.output then
    quarto.log.output(msg)
  else
    io.stderr:write(msg .. '\n')
  end
end

local function warn(msg)
  if quarto and quarto.log and quarto.log.warning then
    quarto.log.warning(msg)
  else
    io.stderr:write('WARNING: ' .. msg .. '\n')
  end
end

local function val(meta, key)
  local v = meta[key]
  if v == nil then return nil end
  local s = pandoc.utils.stringify(v)
  if s == '' then return nil end
  return s
end

local function b64(s)
  local out, i, n = {}, 1, #s
  while i <= n do
    local a = s:byte(i)
    local b = (i + 1 <= n) and s:byte(i + 1) or 0
    local c = (i + 2 <= n) and s:byte(i + 2) or 0
    local v = a * 65536 + b * 256 + c
    local o1 = math.floor(v / 262144) % 64
    local o2 = math.floor(v / 4096) % 64
    local o3 = math.floor(v / 64) % 64
    local o4 = v % 64
    out[#out + 1] = B64:sub(o1 + 1, o1 + 1) .. B64:sub(o2 + 1, o2 + 1) ..
                    ((i + 1 <= n) and B64:sub(o3 + 1, o3 + 1) or '=') ..
                    ((i + 2 <= n) and B64:sub(o4 + 1, o4 + 1) or '=')
    i = i + 3
  end
  return table.concat(out)
end

-- 相对路径按当前工作目录解析；Quarto 从别处调用时回退到输入文件所在目录
local function read_binary(path)
  local fh = io.open(path, 'rb')
  if fh then
    local data = fh:read('*a'); fh:close()
    return data, path
  end
  local st = PANDOC_STATE
  if st and st.input_files and st.input_files[1] then
    local dir = st.input_files[1]:match('^(.*)[/\\][^/\\]+$')
    if dir and dir ~= '' then
      local alt = dir .. '/' .. path
      local f2 = io.open(alt, 'rb')
      if f2 then
        local data = f2:read('*a'); f2:close()
        return data, alt
      end
    end
  end
  return nil, nil
end

local function css_value(s)
  -- 防止值里的分号 / 花括号提前结束声明
  return (s:gsub('[;{}]', ''))
end

local function css_string(s)
  return (s:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local function html_attr(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

local function logo_url(meta)
  local url = nil
  local direct = val(meta, 'brand-logo')
  if direct then
    if direct:lower():match('^%s*url%s*%(') then
      url = direct
    else
      url = 'url("' .. css_string(direct) .. '")'
    end
  end
  local file = val(meta, 'brand-logo-file')
  if file then
    local data, used = read_binary(file)
    if data then
      local ext = file:match('%.([%a%d]+)$') or 'png'
      local mime = MIME[ext:lower()] or 'application/octet-stream'
      url = 'url("data:' .. mime .. ';base64,' .. b64(data) .. '")'
      log('[brand-header] logo 内联：' .. used .. '（' .. #data .. ' 字节）')
    else
      warn('[brand-header] 找不到 brand-logo-file: ' .. file ..
           '（相对项目根目录，或写绝对路径）')
    end
  end
  return url
end

function Meta(meta)
  local decl, applied = {}, {}

  for _, pair in ipairs(COLOR_KEYS) do
    local v = val(meta, pair[1])
    if v then
      decl[#decl + 1] = pair[2] .. ':' .. css_value(v) .. ';'
      applied[#applied + 1] = pair[1]
    end
  end

  local label = val(meta, 'fig-label')
  if label then
    -- Pandoc 变量转换会吃掉 YAML 字符串末尾的空格；图号前缀几乎总需要
    -- 一个分隔符，因此缺尾空白时自动补一个（全角空格 U+3000 也算）。
    if not (label:match('[%s]$') or label:match('\227\128\128$')) then
      label = label .. ' '
    end
    decl[#decl + 1] = '--fig-label:"' .. css_string(label) .. '";'
    applied[#applied + 1] = 'fig-label'
  end

  local url = logo_url(meta)
  if url then
    decl[#decl + 1] = '--brand-logo:' .. url .. ';'
    applied[#applied + 1] = 'brand-logo'
  end

  local header = val(meta, 'brand-header')
  local html = {}
  if #decl > 0 then
    html[#html + 1] = '<style id="neutral-brand">:root{' .. table.concat(decl) .. '}</style>'
  end
  if header then
    html[#html + 1] = '<meta name="neutral-brand-header" content="' ..
                      html_attr(header) .. '">'
    applied[#applied + 1] = 'brand-header'
  end

  -- 没有任何品牌参数时完全不注入，产物与旧版逐字节一致
  if #html == 0 then return nil end

  local inc = pandoc.MetaInlines { pandoc.RawInline('html', table.concat(html, '\n')) }
  local cur = meta['header-includes']
  if cur == nil then
    meta['header-includes'] = inc
  elseif cur.t == 'MetaList' then
    table.insert(cur, inc)
    meta['header-includes'] = cur
  else
    meta['header-includes'] = pandoc.MetaList { cur, inc }
  end

  log('[brand-header] 已注入 <head>：' .. table.concat(applied, ', '))
  return meta
end
