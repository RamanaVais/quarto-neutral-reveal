-- fit-options.lua —— 把 YAML 的 fit-* 参数交给 fit.html 与 fit.css
--
-- 为什么不直接用 include-in-header 文件：
--   Quarto 的 include-in-header 是 raw 插入，文件里的 $fit-min-font$ 之类
--   Pandoc 变量不会被展开；而 Lua filter 能读 doc.meta 并生成真正的标签。
-- 为什么追加而不是覆盖 header-includes：
--   覆盖会丢掉 Quarto 自带的 MathJax / reveal 资源（与 brand-header.lua 同理）。
--
-- 支持的顶层 YAML 键：
--   fit-mode          auto | off      关闭本页面的自适应（off 时 fit.html 直接返回）
--   fit-min-font      9               数据表字号下限（px）
--   fit-max-font      18              数据表字号上限（px）
--   fit-debug         true | false    控制台输出每页每个宿主的实测尺寸
--   fit-allow-scroll  true | false    全局允许出现滚动条（默认禁止）
--
-- 没有任何 fit-* 参数时返回 nil，产物与不装本过滤器时逐字节一致。

local function trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function val(meta, key)
  local v = meta[key]
  if v == nil then return nil end
  local s = trim(pandoc.utils.stringify(v))
  if s == '' then return nil end
  return s
end

local function html_attr(s)
  s = s:gsub('&', '&amp;'):gsub('"', '&quot;')
  s = s:gsub('<', '&lt;'):gsub('>', '&gt;')
  return s
end

local function log(msg)
  io.stderr:write(msg .. '\n')
end

-- 顺序固定，保证 <meta content> 稳定可断言
local KEYS = { 'fit-mode', 'fit-min-font', 'fit-max-font', 'fit-debug', 'fit-allow-scroll' }

function Meta(meta)
  local pairsOut = {}
  for _, k in ipairs(KEYS) do
    local v = val(meta, k)
    if v then pairsOut[#pairsOut + 1] = k .. '=' .. v end
  end

  if #pairsOut == 0 then return nil end

  local html = '<meta name="neutral-fit" content="' ..
               html_attr(table.concat(pairsOut, ';')) .. '">'

  local inc = pandoc.MetaInlines { pandoc.RawInline('html', html) }
  local cur = meta['header-includes']
  if cur == nil then
    meta['header-includes'] = inc
  elseif cur.t == 'MetaList' then
    table.insert(cur, inc)
    meta['header-includes'] = cur
  else
    meta['header-includes'] = pandoc.MetaList { cur, inc }
  end

  log('[fit-options] 已注入 <head>：' .. table.concat(pairsOut, ';'))
  return meta
end
