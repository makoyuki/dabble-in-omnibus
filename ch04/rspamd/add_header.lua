-- 特定のメールアドレスリスト
local specific_emails = {
  'example1@example.com',
  'example2@example.com',
  'example3@example.com',
  'example4@example.com',
  'example5@example.com',
  'example6@example.com',
  'example7@example.com',
  'example8@example.com',
  'example9@example.com',
  'example10@example.com'
}

-- 追加するヘッダー
local header_name = 'X-Special-Header'
local header_value = 'Present'

-- メールのTo, Cc, Fromヘッダーをチェック
local function check_email(task)
  -- ToおよびCcヘッダーのチェック
  local rcpts = task:get_recipients('all')
  for _, rcpt in ipairs(rcpts) do
    for _, specific_email in ipairs(specific_emails) do
      if rcpt['addr'] == specific_email then
        task:set_milter_reply({
          add_headers = {
            [header_name] = header_value
          }
        })
        return
      end
    end
  end

  -- Fromヘッダーのチェック
  local from = task:get_from('smtp')
  if from and #from > 0 then
    for _, sender in ipairs(from) do
      for _, specific_email in ipairs(specific_emails) do
        if sender['addr'] == specific_email then
          task:set_milter_reply({
            add_headers = {
              [header_name] = header_value
            }
          })
          return
        end
      end
    end
  end
end

-- Luaルールを登録
rspamd_config:register_symbol({
  name = 'CHECK_SPECIFIC_EMAIL',
  callback = check_email,
  priority = 10,
  flags = 'empty',
  type = 'postfilter'
})
