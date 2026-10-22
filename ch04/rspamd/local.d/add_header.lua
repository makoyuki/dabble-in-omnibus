-- 宛先(To・Cc)か送信元(From)が、次のアドレスのどれかであれば、メールにヘッダーを付ける
local specific_emails = {
  'example1@example.com',
  'example2@example.com',
  'example3@example.com',
}

-- 追加するヘッダー
local header_name = 'X-Special-Header'
local header_value = 'Present'

-- 大文字・小文字を区別せずに引けるようにしておく
local targets = {}
for _, addr in ipairs(specific_emails) do
  targets[addr:lower()] = true
end

local function has_target(addrs)
  for _, a in ipairs(addrs or {}) do
    if a['addr'] and targets[a['addr']:lower()] then
      return true
    end
  end
  return false
end

local function check_email(task)
  -- エンベロープ(smtp)とヘッダー(mime)の両方を見る。mime の宛先には To と Cc の両方が入る
  if has_target(task:get_recipients('smtp')) or has_target(task:get_recipients('mime'))
      or has_target(task:get_from('smtp')) or has_target(task:get_from('mime')) then
    task:set_milter_reply({
      add_headers = {
        [header_name] = header_value
      }
    })
  end
end

rspamd_config:register_symbol({
  name = 'CHECK_SPECIFIC_EMAIL',
  callback = check_email,
  priority = 10,
  flags = 'empty',
  type = 'postfilter'
})
