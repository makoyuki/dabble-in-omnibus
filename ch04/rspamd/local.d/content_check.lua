-- 本文に書かれたスクリプト(JavaScript・VBScript・ActiveX)を検出する
-- multimap の content ルールでは、base64 や quoted-printable でエンコードされたHTMLの本文を
-- デコードした状態で見られないので、デコード済みの本文(HTMLのタグ付き)をマップファイルの正規表現で調べる
local rspamd_logger = require "rspamd_logger"

local LOCAL_D = '/etc/rspamd/local.d'
local rules = {
  { symbol = 'REGEXP_JS_IN_BODY',      map = LOCAL_D .. '/scriptcheck/regexps_js.map',      description = 'Detect JavaScript in the email body' },
  { symbol = 'REGEXP_VBS_IN_BODY',     map = LOCAL_D .. '/scriptcheck/regexps_vbs.map',     description = 'Detect VBScript in the email body' },
  { symbol = 'REGEXP_ACTIVEX_IN_BODY', map = LOCAL_D .. '/scriptcheck/regexps_activex.map', description = 'Detect ActiveX in the email body' },
}

for _, r in ipairs(rules) do
  r.re_map = rspamd_config:add_map({
    type = 'regexp',
    url = 'file://' .. r.map,
    description = r.description,
  })
  if not r.re_map then
    rspamd_logger.errx(rspamd_config, 'content_check: cannot load map %s', r.map)
  else
    rspamd_config:register_symbol({
      name = r.symbol,
      type = 'normal',
      score = 0.0,
      description = r.description,
      callback = function(task)
        for _, part in ipairs(task:get_text_parts() or {}) do
          local content = part:get_content('raw_utf')
          if content and r.re_map:get_key(content) then
            return true, 1.0, r.symbol
          end
        end
        return false
      end,
    })
  end
end
