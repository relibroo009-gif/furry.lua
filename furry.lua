--=====================================================================
--  PASSWORD LOCK + FURRY TAB + BLESSED.LUA
--=====================================================================
local is_authenticated = false
local attempts = 3
local real_password = ""

local tab_password = menu.new_tab("Password", "rbxassetid://10734975692")
local sec_left = tab_password:new_section("Input", "Left")
local pass_box = sec_left:new_textbox("Password", "Click and type...", "")
local sec_right = tab_password:new_section("Action", "Right")
local unlock_btn

local function hide_password_tab()
    pcall(function() pass_box:remove() end)
    pcall(function() unlock_btn:remove() end)
    pcall(function() sec_left:remove() end)
    pcall(function() sec_right:remove() end)
    if tab_password.set_name then
        pcall(function() tab_password:set_name(" ") end)
    end
end

local function on_password_submit()
    if is_authenticated or attempts <= 0 then return end

    local entered = ""
    pcall(function() entered = tostring(pass_box:get() or "") end)
    if entered == "" then entered = real_password end
    entered = entered:gsub("%D", "")

    if entered == "9999" then
        is_authenticated = true
        hide_password_tab()
        
        -- =====================================================================
        -- 1. ТВОЯ ВКЛАДКА FURRY (CLAN TAG)
        -- =====================================================================
        local function utf8_chars(s)
            local t, i = {}, 1
            s = tostring(s or "")
            while i <= #s do
                local b = s:byte(i)
                local len = 1
                if     b >= 0xF0 then len = 4
                elseif b >= 0xE0 then len = 3
                elseif b >= 0xC0 then len = 2 end
                t[#t + 1] = s:sub(i, i + len - 1)
                i = i + len
            end
            return t
        end

        local up_map, low_map = {}, {}
        do
            local lc = utf8_chars("абвгдеёжзийклмнопрстуфхцчшщъыьэюя")
            local uc = utf8_chars("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
            for i = 1, #lc do
                up_map[lc[i]]  = uc[i]
                low_map[uc[i]] = lc[i]
            end
        end

        local function upper(ch) return up_map[ch]  or string.upper(ch) end
        local function lower(ch) return low_map[ch] or string.lower(ch) end
        local function clamp(v, a, b) v = tonumber(v) or a; if v < a then return a elseif v > b then return b end; return v end

        local ANIMS = { "Static", "Wave", "Marquee", "Typewriter" }
        local FIXED_TAG_TEXT = "Furry.lua"

        local function build_frames(text, mode)
            local c = utf8_chars(text)
            local n = #c
            if n == 0 then return { "" } end
            if mode == "Static" then return { text, text }
            elseif mode == "Wave" then
                local function mk(idx)
                    local out = {}
                    for i = 1, n do out[i] = (i == idx) and upper(c[i]) or lower(c[i]) end
                    return table.concat(out)
                end
                local f = {}
                for i = 1, n do f[#f + 1] = mk(i) end
                for i = n - 1, 2, -1 do f[#f + 1] = mk(i) end
                if #f == 1 then f[2] = f[1] end
                return f
            elseif mode == "Marquee" then
                local src = utf8_chars(text .. "   ")
                local total = #src
                local f = {}
                for off = 0, total - 1 do
                    local out = {}
                    for i = 1, n do out[i] = src[((off + i - 1) % total) + 1] end
                    f[#f + 1] = table.concat(out)
                end
                return f
            elseif mode == "Typewriter" then
                local f = { "" }
                for i = 1, n do f[#f + 1] = table.concat(c, "", 1, i) end
                f[#f + 1] = text; f[#f + 1] = ""
                return f
            end
            return { text, text }
        end

        local ct_enable, ct_anim, ct_speed
        local last_ct_sig = nil

        pcall(function()
            local tab_furry = menu.new_tab("Furry", "rbxassetid://10734975692")
            local sec_info = tab_furry:new_section("Author & Info", "Left")
            sec_info:new_label("Author: xRevives (Try Okeanarium)")
            sec_info:new_label("Configs: Dream, Okeanarium")

            local ct_sec = tab_furry:new_section("Clan Tag Settings", "Left")
            ct_enable = ct_sec:new_toggle("Enable Clan Tag", true)
            ct_anim   = ct_sec:new_combobox("Animation", ANIMS, "Wave")
            ct_speed  = ct_sec:new_slider("Speed (ms)", 50, 500, 150, 0, "ms")

            local function apply_clan_tag()
                if not (ct_enable and ct_anim and ct_speed) then return end
                local enabled = ct_enable:get(); local anim = ct_anim:get(); local ms = clamp(ct_speed:get(), 50, 500); local text = FIXED_TAG_TEXT
                local sig = tostring(enabled) .. "|" .. text .. "|" .. anim .. "|" .. ms
                if sig == last_ct_sig then return end
                last_ct_sig = sig

                if not enabled or text == "" then
                    pcall(function() clantag.reset() end); return
                end

                local speed = ms / 1000; local frames = build_frames(text, anim)
                local ok = pcall(function() clantag.set_frames(frames, speed) end)
                if not ok then pcall(function() clantag.set(text, "static", speed) end) end
            end

            for _, obj in ipairs({ct_enable, ct_anim, ct_speed}) do
                pcall(function() obj:set_callback(function() pcall(apply_clan_tag) end) end)
            end

            task.spawn(function()
                task.wait(0.5); pcall(apply_clan_tag)
                while true do pcall(apply_clan_tag); task.wait(0.4) end
            end)
        end) 

        -- =====================================================================
        -- 2. ВНЕДРЕНИЕ BLESSED.LUA
        -- =====================================================================
        local DB_KEY = "blessed_lua_config_v1"
        local CONFIG_VERSION = 1

        local function call_or(fallback, callback, ...)
            local ok, result = pcall(callback, ...)
            if ok then return result end
            return fallback
        end

        local function find_reference(paths)
            for _, path in ipairs(paths) do
                local ok, reference = pcall(ui.reference, path[1], path[2], path[3])
                if ok and reference ~= nil then return reference end
            end
            return nil
        end

        local auto_scope_reference = find_reference({
            { "RAGE", "Aimbot", "Automatic scope" }, { "RAGE", "Aimbot", "Auto scope" }, { "RAGE", "Aimbot", "Auto-scope" },
            { "RAGE", "Other", "Automatic scope" }, { "RAGE", "Other", "Auto scope" },
            { "RAGE", "Weapon settings", "Automatic scope" }, { "RAGE", "Weapon", "Automatic scope" }
        })

        local auto_duck_reference = find_reference({
            { "MISC", "Movement", "Auto duck" }, { "MISC", "Movement", "Automatic duck" }, { "MISC", "Miscellaneous", "Auto duck" }
        })

        local original_auto_scope = false
        if auto_scope_reference ~= nil then original_auto_scope = call_or(false, ui.get, auto_scope_reference) == true end
        local original_auto_duck = false
        if auto_duck_reference ~= nil then original_auto_duck = call_or(false, ui.get, auto_duck_reference) == true end

        local original_resolver = {
            enabled = call_or(false, rage.is_resolver_enabled),
            mode = call_or("Adaptive", rage.get_resolver_mode),
            miss_limit = call_or(2, rage.get_resolver_miss_limit),
            baim_after = call_or(2, rage.get_resolver_baim_after_misses)
        }

        local main_tab = menu.new_tab("blessed.lua", "rbxassetid://10734975692")
        local general_section = main_tab:new_section("Runtime", "Left")
        local aa_section = main_tab:new_section("Anti-Aim", "Left")
        local pattern_section = main_tab:new_section("Yaw Patterns", "Left")
        local state_section = main_tab:new_section("State Override", "Left")
        local flick_section = main_tab:new_section("Flick AA", "Left")
        local manual_section = main_tab:new_section("Manual Dirs", "Left")
        local movement_section = main_tab:new_section("Movement Choke", "Right")
        local rage_section = main_tab:new_section("Ragebot", "Right")
        local resolver_section = main_tab:new_section("Resolver", "Right")
        local resolver_advanced_section = main_tab:new_section("Per-Target", "Right")
        local desync_section = main_tab:new_section("Desync & Lag", "Right")
        local body_pattern_section = main_tab:new_section("Body & Lag", "Right")

        local master = general_section:new_toggle("Enable blessed.lua", false)
        local aa_enabled = aa_section:new_toggle("Anti-aim", false)
        local pitch_mode = aa_section:new_combobox("Pitch", { "Down", "Up", "Zero", "Custom", "Jitter", "Mega" }, "Down")
        local custom_pitch = aa_section:new_slider("Custom pitch", -89, 89, -89, 0, "°")
        local pitch_jitter_pattern = aa_section:new_combobox("Jitter pattern", { "2-Way", "3-Way", "Random", "Sway" }, "2-Way")
        local pitch_jitter_a = aa_section:new_slider("Jitter A", -89, 89, -89, 0, "°")
        local pitch_jitter_b = aa_section:new_slider("Jitter B", -89, 89, 89, 0, "°")
        local pitch_jitter_center = aa_section:new_slider("Jitter center", -89, 89, 0, 0, "°")
        local pitch_jitter_speed = aa_section:new_slider("Jitter speed", 1, 16, 1, 0, "t")
        local pitch_mega_sequence = aa_section:new_textbox("Mega sequence", "A,B,0,-A,R,-B", "A,B,0,-A,A,-B,B,R")
        local pitch_mega_help = aa_section:new_label("A, B, -A, -B, R, deg")
        local yaw_base = aa_section:new_combobox("Yaw base", { "Backward", "Forward", "Left", "Right" }, "Backward")
        local yaw_offset = aa_section:new_slider("Yaw offset", -180, 180, 0, 0, "°")
        local adaptive_aa = aa_section:new_toggle("Adaptive yaw", false)
        local yaw_modifier = aa_section:new_combobox("Yaw modifier", { "Disabled", "Center", "3-Way", "5-Way", "Spin", "Random", "Sway", "Asymmetric", "Sequence", "Sine", "Triangle" }, "Random")
        local modifier_amount = aa_section:new_slider("Modifier amount", 0, 180, 26, 0, "°")

        local yaw_pattern_period = pattern_section:new_slider("Pattern hold", 1, 128, 4, 0, "t")
        local yaw_asymmetric_left = pattern_section:new_slider("Left angle", -180, 180, -32, 0, "°")
        local yaw_asymmetric_right = pattern_section:new_slider("Right angle", -180, 180, 26, 0, "°")
        local yaw_asymmetric_left_hold = pattern_section:new_slider("Left hold", 1, 32, 1, 0, "t")
        local yaw_asymmetric_right_hold = pattern_section:new_slider("Right hold", 1, 32, 1, 0, "t")
        local yaw_sequence = pattern_section:new_textbox("Yaw sequence", "angle:hold, angle:hold", "-40:2,40:2,0:1")
        local yaw_wave_period = pattern_section:new_slider("Wave period", 2, 512, 64, 0, "t")
        local yaw_spin_speed = pattern_section:new_slider("Spin speed", -720, 720, 120, 0, "°/s")
        local yaw_sequence_help = pattern_section:new_label("Example: -40:2, 40:2")

        local manual_direction_enabled = manual_section:new_toggle("Manual dirs", false)
        local manual_left = manual_section:new_keybind("Left", "Hold", "Left")
        local manual_right = manual_section:new_keybind("Right", "Hold", "Right")
        local manual_back = manual_section:new_keybind("Back", "Hold", "Down")
        local manual_forward = manual_section:new_keybind("Forward", "Hold", "Up")

        local desync_enabled = desync_section:new_toggle("Body yaw", false)
        local desync_limit = desync_section:new_slider("Desync limit", 0, 86, 85, 0, "°")
        local inverter_key = desync_section:new_keybind("Invert side", "Toggle", "F")
        local auto_invert = desync_section:new_toggle("Auto invert", false)
        local invert_interval = desync_section:new_slider("Invert delay", 1, 32, 1, 0, "t")
        local show_fake = desync_section:new_toggle("Show fake", false)
        local fake_lag_enabled = desync_section:new_toggle("Fake lag", false)
        local fake_lag_limit = desync_section:new_slider("Lag limit", 0, 14, 0, 0, "t")
        local fake_lag_variability = desync_section:new_slider("Variability", 0, 100, 100, 0, "%")
        local unchoke_on_shot = desync_section:new_toggle("Unchoke on shot", false)

        local desync_pattern = body_pattern_section:new_combobox("Desync pattern", { "Static", "Alternating", "Random", "Sine", "Sequence", "Explicit" }, "Static")
        local desync_left_min = body_pattern_section:new_slider("Left min", 0, 86, 20, 0, "°")
        local desync_left_max = body_pattern_section:new_slider("Left max", 0, 86, 85, 0, "°")
        local desync_right_min = body_pattern_section:new_slider("Right min", 0, 86, 20, 0, "°")
        local desync_right_max = body_pattern_section:new_slider("Right max", 0, 86, 85, 0, "°")
        local desync_pattern_period = body_pattern_section:new_slider("Desync period", 1, 256, 8, 0, "t")
        local desync_sequence = body_pattern_section:new_textbox("Desync sequence", "limit:hold, limit:hold", "30:2,58:1,40:1")
        local desync_real = body_pattern_section:new_slider("Explicit real", -86, 86, 25, 0, "°")
        local desync_fake = body_pattern_section:new_slider("Explicit fake", -86, 86, -25, 0, "°")
        local desync_mirror_explicit = body_pattern_section:new_toggle("Mirror on invert", false)
        local desync_sequence_help = body_pattern_section:new_label("Range: 0..86")

        local fake_lag_pattern = body_pattern_section:new_combobox("Fake lag pattern", { "Static", "Alternating", "Random", "Sine", "Sequence" }, "Static")
        local fake_lag_min = body_pattern_section:new_slider("Choke min", 0, 14, 2, 0, "t")
        local fake_lag_pattern_period = body_pattern_section:new_slider("Lag period", 1, 256, 8, 0, "t")
        local fake_lag_sequence = body_pattern_section:new_textbox("Lag sequence", "choke:hold, choke:hold", "2:1,6:2,4:1")
        local fake_lag_sequence_help = body_pattern_section:new_label("Range: 0..14")

        local state_override_enabled = state_section:new_toggle("State override", false)
        local state_override_mode = state_section:new_combobox("Override mode", { "Spin", "Madness" }, "Spin")
        local state_on_stand = state_section:new_toggle("Standing", false)
        local state_on_run = state_section:new_toggle("Running", false)
        local state_on_duck = state_section:new_toggle("Crouching", false)
        local state_on_air = state_section:new_toggle("Air / jumping", false)
        local state_pitch = state_section:new_slider("Pitch", -89, 89, 0, 0, "°")
        local state_yaw_base = state_section:new_combobox("Yaw base", { "Backward", "Forward", "Left", "Right" }, "Backward")
        local state_yaw_offset = state_section:new_slider("Yaw offset", -180, 180, 0, 0, "°")
        local state_spin_direction = state_section:new_combobox("Spin direction", { "Right", "Left" }, "Right")
        local state_spin_speed = state_section:new_slider("Spin speed", 30, 1440, 720, 0, "°/s")
        local state_madness_period = state_section:new_slider("Madness rate", 1, 32, 2, 0, "t")
        local state_madness_pitch_min = state_section:new_slider("Madness min", -89, 89, -89, 0, "°")
        local state_madness_pitch_max = state_section:new_slider("Madness max", -89, 89, 89, 0, "°")
        local state_madness_yaw_range = state_section:new_slider("Madness range", 0, 180, 180, 0, "°")
        local state_madness_desync = state_section:new_toggle("Random desync", false)
        local state_upper_body_chaos = state_section:new_toggle("Body chaos", false)
        local state_body_chaos_strength = state_section:new_slider("Chaos strength", 0, 89, 65, 0, "°")
        local state_disable_fake_lag = state_section:new_toggle("No fake lag", false)

        local flick_enabled = flick_section:new_toggle("Flick AA", false)
        local flick_yaw = flick_section:new_slider("Flick yaw", -180, 180, 180, 0, "°")
        local flick_pitch = flick_section:new_slider("Flick pitch", -89, 89, -89, 0, "°")
        local flick_ticks = flick_section:new_slider("Flick time", 1, 64, 8, 0, "t")
        local flick_rest_ticks = flick_section:new_slider("Rest time", 1, 64, 8, 0, "t")
        local flick_bind_mode = flick_section:new_combobox("Bind mode", { "Hold", "Toggle" }, "Hold")
        local flick_bind = flick_section:new_keybind("Flick key", "Hold", "X")

        local rage_enabled = rage_section:new_toggle("Ragebot", false)
        local weapon_profiles = rage_section:new_toggle("Sniper profile", false)
        local min_damage = rage_section:new_slider("Min damage", 1, 130, 30, 0, "")
        local hitchance = rage_section:new_slider("Hitchance", 0, 100, 55, 0, "%")
        local sniper_damage = rage_section:new_slider("Sniper damage", 1, 130, 60, 0, "")
        local sniper_hitchance = rage_section:new_slider("Sniper HC", 0, 100, 65, 0, "%")
        local target_selection = rage_section:new_combobox("Target mode", { "Highest damage", "Near crosshair", "Best hitchance", "Cycle" }, "Near crosshair")
        local hitbox_preset = rage_section:new_combobox("Hitboxes", { "Head", "Head + chest", "Body", "All" }, "All")
        local force_baim = rage_section:new_keybind("Body aim", "Hold", "B")
        local force_safe = rage_section:new_keybind("Safe point", "Hold", "V")
        local auto_scope = rage_section:new_toggle("Auto scope", false)
        local auto_scope_unavailable = rage_section:new_label("Auto scope N/A")
        auto_scope:set_visible(auto_scope_reference ~= nil)
        auto_scope_unavailable:set_visible(auto_scope_reference == nil)

        local resolver_enabled = resolver_section:new_toggle("Resolver", false)
        local resolver_mode = resolver_section:new_combobox("Mode", { "Brute-force", "Adaptive", "Freestanding" }, "Adaptive")
        local resolver_miss_limit = resolver_section:new_slider("Miss limit", 1, 5, 2, 0, " misses")
        local resolver_baim_after = resolver_section:new_slider("BAim after", 0, 5, 2, 0, " misses")

        local resolver_player_overrides = resolver_advanced_section:new_toggle("Per-target", false)
        local resolver_brute_sequence = resolver_advanced_section:new_textbox("Brute sequence", "angle:hold, angle:hold", "58,-58,0,86,-86,29,-29")
        local resolver_reset_on_hit = resolver_advanced_section:new_toggle("Reset on hit", false)
        local resolver_lock_on_hit = resolver_advanced_section:new_toggle("Lock yaw", false)
        local resolver_freestand_seed = resolver_advanced_section:new_toggle("Freestand seed", false)
        local resolver_safe_on_baim = resolver_advanced_section:new_toggle("Safe with BAim", false)
        local resolver_sequence_help = resolver_advanced_section:new_label(":N holds N cycles")

        local autostop_enabled = movement_section:new_toggle("Movement choke", false)
        local autostop_choke_ticks = movement_section:new_slider("Choke ticks", 1, 14, 3, 0, "t")
        local autostop_min_speed = movement_section:new_slider("Min speed", 1, 200, 10, 0, "")
        local autostop_duck = movement_section:new_toggle("Duck assist", false)
        local autostop_description = movement_section:new_label("Flushes while moving")
        local autostop_duck_unavailable = movement_section:new_label("Auto duck N/A")
        autostop_duck:set_visible(auto_duck_reference ~= nil)
        autostop_duck_unavailable:set_visible(auto_duck_reference == nil)

        -- Simplified sequence parsers for brevity (logic works the same)
        local function parse_timed_sequence(value, minimum, maximum, allowed_tokens)
            local parsed = { steps = {}, total = 0 }
            local source = tostring(value or ""):gsub(";", ",")
            for raw_token in string.gmatch(source .. ",", "([^,]+),") do
                local compact = raw_token:gsub("%s+", "")
                local value_text, duration_text = compact:match("^(.-):(%d+)$")
                if value_text == nil then value_text = compact; duration_text = "1" end
                local duration = tonumber(duration_text)
                local numeric = tonumber(value_text)
                local step_value = nil
                if numeric ~= nil and numeric == numeric then step_value = clamp(numeric, minimum, maximum)
                elseif allowed_tokens ~= nil then
                    local token = string.upper(value_text)
                    if allowed_tokens[token] then step_value = token end
                end
                if step_value == nil or duration == nil or duration < 1 or duration > 256 or duration ~= math.floor(duration) then return nil end
                table.insert(parsed.steps, { value = step_value, duration = duration })
                parsed.total = parsed.total + duration
                if #parsed.steps >= 32 then break end
            end
            if #parsed.steps == 0 or parsed.total <= 0 then return nil end
            return parsed
        end

        local function parse_sequence_or_default(value, minimum, maximum, allowed_tokens, fallback)
            return parse_timed_sequence(value, minimum, maximum, allowed_tokens) or parse_timed_sequence(fallback, minimum, maximum, allowed_tokens)
        end

        local function sample_timed_sequence(sequence, step)
            if sequence == nil or sequence.total == nil or sequence.total <= 0 then return 0 end
            local cursor = math.floor(tonumber(step) or 0) % sequence.total
            for _, item in ipairs(sequence.steps) do
                if cursor < item.duration then return item.value end
                cursor = cursor - item.duration
            end
            return sequence.steps[1].value
        end

        local MEGA_TOKENS = { A = true, B = true, ["-A"] = true, ["-B"] = true, R = true, RANDOM = true }
        local mega_sequence_data, yaw_sequence_data, desync_sequence_data, fake_lag_sequence_data, resolver_sequence_data

        local function parse_mega_sequence(value) mega_sequence_data = parse_sequence_or_default(value, -89, 89, MEGA_TOKENS, "A,B,0,-A,R,-B") end
        local function parse_yaw_sequence(value) yaw_sequence_data = parse_sequence_or_default(value, -180, 180, nil, "-40:2,40:2,0:1") end
        local function parse_desync_sequence(value) desync_sequence_data = parse_sequence_or_default(value, 0, 86, nil, "30:2,58:1,40:1") end
        local function parse_fake_lag_sequence(value) fake_lag_sequence_data = parse_sequence_or_default(value, 0, 14, nil, "2:1,6:2,4:1") end
        local function parse_resolver_sequence(value) resolver_sequence_data = parse_sequence_or_default(value, -180, 180, nil, "58,-58,0,86,-86") end

        pitch_mega_sequence:set_callback(function(value) parse_mega_sequence(value or pitch_mega_sequence:get()) end)
        yaw_sequence:set_callback(function(value) parse_yaw_sequence(value or yaw_sequence:get()) end)
        desync_sequence:set_callback(function(value) parse_desync_sequence(value or desync_sequence:get()) end)
        fake_lag_sequence:set_callback(function(value) parse_fake_lag_sequence(value or fake_lag_sequence:get()) end)
        resolver_brute_sequence:set_callback(function(value) parse_resolver_sequence(value or resolver_brute_sequence:get()) end)

        parse_mega_sequence(pitch_mega_sequence:get())
        parse_yaw_sequence(yaw_sequence:get())
        parse_desync_sequence(desync_sequence:get())
        parse_fake_lag_sequence(fake_lag_sequence:get())
        parse_resolver_sequence(resolver_brute_sequence:get())

        local function update_menu_visibility()
            local selected_pitch = pitch_mode:get()
            local jitter_selected = selected_pitch == "Jitter"
            local mega_selected = selected_pitch == "Mega"
            local pitch_jitter_enabled = jitter_selected or mega_selected

            custom_pitch:set_visible(selected_pitch == "Custom")
            pitch_jitter_pattern:set_visible(jitter_selected)
            pitch_jitter_a:set_visible(pitch_jitter_enabled)
            pitch_jitter_b:set_visible(pitch_jitter_enabled)
            pitch_jitter_center:set_visible(jitter_selected and pitch_jitter_pattern:get() == "3-Way")
            pitch_jitter_speed:set_visible(pitch_jitter_enabled)
            pitch_mega_sequence:set_visible(mega_selected)
            pitch_mega_help:set_visible(mega_selected)
            yaw_modifier:set_visible(not adaptive_aa:get())
            local selected_yaw_pattern = yaw_modifier:get()
            local custom_yaw_pattern = not adaptive_aa:get()
            modifier_amount:set_visible(adaptive_aa:get() or selected_yaw_pattern == "Center" or selected_yaw_pattern == "3-Way" or selected_yaw_pattern == "5-Way" or selected_yaw_pattern == "Random" or selected_yaw_pattern == "Sway" or selected_yaw_pattern == "Sine" or selected_yaw_pattern == "Triangle")

            local asymmetric_selected = custom_yaw_pattern and selected_yaw_pattern == "Asymmetric"
            local sequence_selected = custom_yaw_pattern and selected_yaw_pattern == "Sequence"
            local wave_selected = custom_yaw_pattern and (selected_yaw_pattern == "Sine" or selected_yaw_pattern == "Triangle")
            local spin_selected = custom_yaw_pattern and selected_yaw_pattern == "Spin"

            yaw_pattern_period:set_visible(custom_yaw_pattern and (selected_yaw_pattern == "Center" or selected_yaw_pattern == "3-Way" or selected_yaw_pattern == "5-Way" or selected_yaw_pattern == "Random" or asymmetric_selected))
            yaw_asymmetric_left:set_visible(asymmetric_selected)
            yaw_asymmetric_right:set_visible(asymmetric_selected)
            yaw_asymmetric_left_hold:set_visible(asymmetric_selected)
            yaw_asymmetric_right_hold:set_visible(asymmetric_selected)
            yaw_sequence:set_visible(sequence_selected)
            yaw_sequence_help:set_visible(sequence_selected)
            yaw_wave_period:set_visible(wave_selected)
            yaw_spin_speed:set_visible(spin_selected)

            local manual_enabled = manual_direction_enabled:get()
            manual_left:set_visible(manual_enabled)
            manual_right:set_visible(manual_enabled)
            manual_back:set_visible(manual_enabled)
            manual_forward:set_visible(manual_enabled)

            invert_interval:set_visible(auto_invert:get())
            local body_enabled = desync_enabled:get()
            local selected_desync_pattern = desync_pattern:get()
            desync_pattern:set_visible(body_enabled)
            desync_limit:set_visible(body_enabled and selected_desync_pattern == "Static")
            show_fake:set_visible(desync_enabled:get())

            local patterned_desync = body_enabled and selected_desync_pattern ~= "Static"
            local explicit_desync = body_enabled and selected_desync_pattern == "Explicit"
            desync_left_min:set_visible(patterned_desync and not explicit_desync)
            desync_left_max:set_visible(patterned_desync and not explicit_desync)
            desync_right_min:set_visible(patterned_desync and not explicit_desync)
            desync_right_max:set_visible(patterned_desync and not explicit_desync)
            desync_pattern_period:set_visible(patterned_desync and selected_desync_pattern ~= "Explicit" and selected_desync_pattern ~= "Sequence")
            desync_sequence:set_visible(body_enabled and selected_desync_pattern == "Sequence")
            desync_sequence_help:set_visible(body_enabled and selected_desync_pattern == "Sequence")
            desync_real:set_visible(explicit_desync)
            desync_fake:set_visible(explicit_desync)
            desync_mirror_explicit:set_visible(explicit_desync)

            fake_lag_limit:set_visible(fake_lag_enabled:get())
            fake_lag_variability:set_visible(fake_lag_enabled:get())
            local lag_enabled = fake_lag_enabled:get()
            local selected_lag_pattern = fake_lag_pattern:get()
            fake_lag_pattern:set_visible(lag_enabled)
            fake_lag_min:set_visible(lag_enabled and selected_lag_pattern ~= "Static")
            fake_lag_pattern_period:set_visible(lag_enabled and selected_lag_pattern ~= "Static" and selected_lag_pattern ~= "Sequence")
            fake_lag_sequence:set_visible(lag_enabled and selected_lag_pattern == "Sequence")
            fake_lag_sequence_help:set_visible(lag_enabled and selected_lag_pattern == "Sequence")

            local flick_active = flick_enabled:get()
            flick_yaw:set_visible(flick_active)
            flick_pitch:set_visible(flick_active)
            flick_ticks:set_visible(flick_active)
            flick_rest_ticks:set_visible(flick_active)
            flick_bind_mode:set_visible(flick_active)
            flick_bind:set_visible(flick_active)

            local resolver_active = resolver_enabled:get() and resolver_player_overrides:get()
            resolver_player_overrides:set_visible(resolver_enabled:get())
            resolver_brute_sequence:set_visible(resolver_active)
            resolver_reset_on_hit:set_visible(resolver_active)
            resolver_lock_on_hit:set_visible(resolver_active)
            resolver_freestand_seed:set_visible(resolver_active)
            resolver_safe_on_baim:set_visible(resolver_active)
            resolver_sequence_help:set_visible(resolver_active)

            local movement_choke_enabled = autostop_enabled:get()
            autostop_choke_ticks:set_visible(movement_choke_enabled)
            autostop_min_speed:set_visible(movement_choke_enabled)
            autostop_description:set_visible(movement_choke_enabled)
            autostop_duck:set_visible(movement_choke_enabled and auto_duck_reference ~= nil)
            autostop_duck_unavailable:set_visible(movement_choke_enabled and auto_duck_reference == nil)

            sniper_damage:set_visible(weapon_profiles:get())
            sniper_hitchance:set_visible(weapon_profiles:get())

            local state_enabled = state_override_enabled:get()
            local madness_selected = state_enabled and state_override_mode:get() == "Madness"
            state_override_mode:set_visible(state_enabled)
            state_on_stand:set_visible(state_enabled)
            state_on_run:set_visible(state_enabled)
            state_on_duck:set_visible(state_enabled)
            state_on_air:set_visible(state_enabled)
            state_pitch:set_visible(state_enabled and not madness_selected)
            state_yaw_base:set_visible(state_enabled and not madness_selected)
            state_yaw_offset:set_visible(state_enabled and not madness_selected)
            state_spin_direction:set_visible(state_enabled and not madness_selected)
            state_spin_speed:set_visible(state_enabled and not madness_selected)
            state_madness_period:set_visible(madness_selected)
            state_madness_pitch_min:set_visible(madness_selected)
            state_madness_pitch_max:set_visible(madness_selected)
            state_madness_yaw_range:set_visible(madness_selected)
            state_madness_desync:set_visible(madness_selected)
            state_upper_body_chaos:set_visible(madness_selected)
            state_body_chaos_strength:set_visible(madness_selected and state_upper_body_chaos:get())
            state_disable_fake_lag:set_visible(state_enabled)
        end

        pitch_mode:set_callback(update_menu_visibility)
        pitch_jitter_pattern:set_callback(update_menu_visibility)
        adaptive_aa:set_callback(update_menu_visibility)
        yaw_modifier:set_callback(update_menu_visibility)
        manual_direction_enabled:set_callback(update_menu_visibility)
        auto_invert:set_callback(update_menu_visibility)
        desync_enabled:set_callback(update_menu_visibility)
        desync_pattern:set_callback(update_menu_visibility)
        fake_lag_enabled:set_callback(update_menu_visibility)
        fake_lag_pattern:set_callback(update_menu_visibility)
        flick_enabled:set_callback(update_menu_visibility)
        weapon_profiles:set_callback(update_menu_visibility)
        state_override_enabled:set_callback(update_menu_visibility)
        state_override_mode:set_callback(update_menu_visibility)
        state_upper_body_chaos:set_callback(update_menu_visibility)
        resolver_enabled:set_callback(update_menu_visibility)
        resolver_player_overrides:set_callback(update_menu_visibility)
        autostop_enabled:set_callback(update_menu_visibility)
        update_menu_visibility()

        local config_controls = {
            master = master, aa_enabled = aa_enabled, pitch_mode = pitch_mode, custom_pitch = custom_pitch,
            pitch_jitter_pattern = pitch_jitter_pattern, pitch_jitter_a = pitch_jitter_a, pitch_jitter_b = pitch_jitter_b,
            pitch_jitter_center = pitch_jitter_center, pitch_jitter_speed = pitch_jitter_speed, pitch_mega_sequence = pitch_mega_sequence,
            yaw_base = yaw_base, yaw_offset = yaw_offset, adaptive_aa = adaptive_aa, yaw_modifier = yaw_modifier, modifier_amount = modifier_amount,
            yaw_pattern_period = yaw_pattern_period, yaw_asymmetric_left = yaw_asymmetric_left, yaw_asymmetric_right = yaw_asymmetric_right,
            yaw_asymmetric_left_hold = yaw_asymmetric_left_hold, yaw_asymmetric_right_hold = yaw_asymmetric_right_hold, yaw_sequence = yaw_sequence,
            yaw_wave_period = yaw_wave_period, yaw_spin_speed = yaw_spin_speed, manual_direction_enabled = manual_direction_enabled,
            desync_enabled = desync_enabled, desync_limit = desync_limit, auto_invert = auto_invert, invert_interval = invert_interval,
            show_fake = show_fake, fake_lag_enabled = fake_lag_enabled, fake_lag_limit = fake_lag_limit, fake_lag_variability = fake_lag_variability,
            unchoke_on_shot = unchoke_on_shot, desync_pattern = desync_pattern, desync_left_min = desync_left_min, desync_left_max = desync_left_max,
            desync_right_min = desync_right_min, desync_right_max = desync_right_max, desync_pattern_period = desync_pattern_period,
            desync_sequence = desync_sequence, desync_real = desync_real, desync_fake = desync_fake, desync_mirror_explicit = desync_mirror_explicit,
            fake_lag_pattern = fake_lag_pattern, fake_lag_min = fake_lag_min, fake_lag_pattern_period = fake_lag_pattern_period, fake_lag_sequence = fake_lag_sequence,
            state_override_enabled = state_override_enabled, state_override_mode = state_override_mode, state_on_stand = state_on_stand,
            state_on_run = state_on_run, state_on_duck = state_on_duck, state_on_air = state_on_air, state_pitch = state_pitch,
            state_yaw_base = state_yaw_base, state_yaw_offset = state_yaw_offset, state_spin_direction = state_spin_direction,
            state_spin_speed = state_spin_speed, state_madness_period = state_madness_period, state_madness_pitch_min = state_madness_pitch_min,
            state_madness_pitch_max = state_madness_pitch_max, state_madness_yaw_range = state_madness_yaw_range, state_madness_desync = state_madness_desync,
            state_upper_body_chaos = state_upper_body_chaos, state_body_chaos_strength = state_body_chaos_strength, state_disable_fake_lag = state_disable_fake_lag,
            flick_enabled = flick_enabled, flick_yaw = flick_yaw, flick_pitch = flick_pitch, flick_ticks = flick_ticks, flick_rest_ticks = flick_rest_ticks,
            flick_bind_mode = flick_bind_mode, rage_enabled = rage_enabled, weapon_profiles = weapon_profiles, min_damage = min_damage, hitchance = hitchance,
            sniper_damage = sniper_damage, sniper_hitchance = sniper_hitchance, target_selection = target_selection, hitbox_preset = hitbox_preset,
            auto_scope = auto_scope, resolver_enabled = resolver_enabled, resolver_mode = resolver_mode, resolver_miss_limit = resolver_miss_limit,
            resolver_baim_after = resolver_baim_after, resolver_player_overrides = resolver_player_overrides, resolver_brute_sequence = resolver_brute_sequence,
            resolver_reset_on_hit = resolver_reset_on_hit, resolver_lock_on_hit = resolver_lock_on_hit, resolver_freestand_seed = resolver_freestand_seed,
            resolver_safe_on_baim = resolver_safe_on_baim, autostop_enabled = autostop_enabled, autostop_choke_ticks = autostop_choke_ticks,
            autostop_min_speed = autostop_min_speed, autostop_duck = autostop_duck,
        }

        local function apply_config_values(values)
            if type(values) ~= "table" then return false end
            for name, handle in pairs(config_controls) do
                if values[name] ~= nil then pcall(function() handle:set(values[name]) end) end
            end
            update_menu_visibility()
            return true
        end

        local function collect_config_values()
            local values = {}
            for name, handle in pairs(config_controls) do values[name] = handle:get() end
            values.config_version = CONFIG_VERSION
            return values
        end

        local function save_config() pcall(function() database.write(DB_KEY, collect_config_values()); database.flush() end) end
        local function load_config()
            local values = call_or(nil, database.read, DB_KEY)
            if type(values) ~= "table" or values.config_version ~= CONFIG_VERSION then
                -- Use defaults
            else
                apply_config_values(values)
            end
        end

        local target_misses, resolver_targets, pending_shots, resolver_overrides_applied = {}, {}, {}, false

        resolver_section:new_button("Reset resolver state", function()
            pcall(rage.reset_resolver_state)
            pcall(plist.reset_all)
            target_misses, resolver_targets, pending_shots = {}, {}, {}
            resolver_overrides_applied = false
        end)

        local function target_key(target) return tostring(target or "unknown") end
        local function get_target_slot(target)
            if target == nil then return nil end
            if type(entity.get_player_slot) == "function" then
                local slot = call_or(nil, entity.get_player_slot, target)
                if slot ~= nil then return slot end
            end
            local info = call_or(nil, entity.get_info, target)
            if info ~= nil and info.slot ~= nil then return info.slot end
            return target
        end

        local function get_resolver_target_state(target)
            local slot = get_target_slot(target)
            local key = target_key(slot)
            local state = resolver_targets[key]
            if state == nil then
                state = { slot = slot, misses = 0, hits = 0, stage = 0, locked_yaw = nil, freestand = nil, lock_applied = false }
                resolver_targets[key] = state
            end
            return state
        end

        local function normalized_angle(value) return ((tonumber(value) or 0) + 180) % 360 - 180 end
        local function detect_enemy_freestand(target)
            local anim = call_or(nil, entity.get_anim_state, target)
            if anim == nil then return "center" end
            local eye, feet = tonumber(anim.eye_angles_y), tonumber(anim.goal_feet_yaw)
            if eye == nil or feet == nil then return "center" end
            local delta = normalized_angle(feet - eye)
            if delta > 10 then return "left" elseif delta < -10 then return "right" end
            return "center"
        end

        local toolkit_active, aa_runtime_active, rage_runtime_active, resolver_runtime_active = false, false, false, false
        local auto_scope_applied = false
        local current_state, current_weapon, current_scoped, current_speed = "Unknown", "None", false, 0
        local current_in_air, current_crouching = false, false
        local current_state_override, current_state_override_mode, state_override_was_active = false, "None", false
        local state_spin_started_at, state_spin_speed_runtime, state_spin_direction_runtime, madness_step_runtime = 0, 720, 1, 0
        local madness_visual = { neck_pitch = 0, neck_yaw = 0, neck_roll = 0, waist_pitch = 0, waist_yaw = 0, waist_roll = 0, left_shoulder_pitch = 0, left_shoulder_yaw = 0, left_shoulder_roll = 0, right_shoulder_pitch = 0, right_shoulder_yaw = 0, right_shoulder_roll = 0 }
        local madness_character, madness_neck, madness_waist, madness_left_shoulder, madness_right_shoulder, madness_body_applied = nil, nil, nil, nil, nil, false
        local sway_amount, explicit_desync_active, movement_choke_active, movement_choke_started, auto_duck_applied, manual_yaw = 0, false, false, 0, false, nil
        local flick_runtime = { state = "REST", timer = 0, toggle_active = false, previous_key = false, active = false }

        local YAW_BASES = { Backward = 180, Forward = 0, Left = -90, Right = 90 }
        local HITBOX_PRESETS = { Head = { "head" }, ["Head + chest"] = { "head", "chest" }, Body = { "chest", "pelvis" }, All = { "head", "chest", "pelvis", "arms", "legs" } }
        local HITBOX_PRIORITIES = { Head = { "head" }, ["Head + chest"] = { "head", "chest" }, Body = { "pelvis", "chest" }, All = { "head", "chest", "pelvis" } }

        local function sway_modifier(tick) return math.sin(tick * 0.18) * sway_amount end
        local function state_spin_modifier()
            local elapsed = globals.realtime() - state_spin_started_at
            local angle = elapsed * state_spin_speed_runtime * state_spin_direction_runtime
            return (angle + 180) % 360 - 180
        end

        local function get_state_group()
            local state = string.lower(tostring(current_state or ""))
            if current_in_air or string.find(state, "jump", 1, true) ~= nil or string.find(state, "air", 1, true) ~= nil then return "air" end
            if current_crouching or string.find(state, "duck", 1, true) ~= nil or string.find(state, "crouch", 1, true) ~= nil then return "duck" end
            if string.find(state, "run", 1, true) ~= nil or string.find(state, "move", 1, true) ~= nil or string.find(state, "walk", 1, true) ~= nil or current_speed > 5 then return "run" end
            if state == "unknown" or state == "" then return nil end
            return "stand"
        end

        local function should_use_state_override()
            if not state_override_enabled:get() then return false end
            local group = get_state_group()
            if group == "air" then return state_on_air:get() elseif group == "duck" then return state_on_duck:get() elseif group == "run" then return state_on_run:get() elseif group == "stand" then return state_on_stand:get() end
            return false
        end

        local function deterministic_unit(step) local value = (step * 1103515245 + 12345) % 2147483648; return (value % 100001) / 100000 end
        local function deterministic_between(step, value_a, value_b)
            local minimum, maximum = math.min(value_a, value_b), math.max(value_a, value_b)
            return minimum + (maximum - minimum) * deterministic_unit(step)
        end

        local function find_character_motor(character, name)
            if character == nil then return nil end
            local motor = character:FindFirstChild(name, true)
            if motor ~= nil and motor:IsA("Motor6D") then return motor end
            return nil
        end

        local function restore_madness_body()
            if madness_body_applied then
                if madness_neck ~= nil and madness_neck.Parent ~= nil then madness_neck.Transform = CFrame.new() end
                if madness_waist ~= nil and madness_waist.Parent ~= nil then madness_waist.Transform = CFrame.new() end
                if madness_left_shoulder ~= nil and madness_left_shoulder.Parent ~= nil then madness_left_shoulder.Transform = CFrame.new() end
                if madness_right_shoulder ~= nil and madness_right_shoulder.Parent ~= nil then madness_right_shoulder.Transform = CFrame.new() end
            end
            madness_body_applied = false
        end

        local function refresh_madness_character()
            local player = call_or(nil, entity.get_local_player)
            local character = player and player.Character or nil
            if character ~= madness_character then
                restore_madness_body()
                madness_character = character
                madness_neck = find_character_motor(character, "Neck")
                madness_waist = find_character_motor(character, "Waist")
                madness_left_shoulder = find_character_motor(character, "LeftShoulder") or find_character_motor(character, "Left Shoulder")
                madness_right_shoulder = find_character_motor(character, "RightShoulder") or find_character_motor(character, "Right Shoulder")
            end
        end

        local function update_madness_visual(step)
            local strength = clamp(state_body_chaos_strength:get(), 0, 89)
            madness_visual.neck_pitch = deterministic_between(step + 101, -strength, strength)
            madness_visual.neck_yaw = deterministic_between(step + 211, -strength, strength)
            madness_visual.neck_roll = deterministic_between(step + 307, -strength * 0.75, strength * 0.75)
            madness_visual.waist_pitch = deterministic_between(step + 401, -strength * 0.45, strength * 0.45)
            madness_visual.waist_yaw = deterministic_between(step + 503, -strength * 0.55, strength * 0.55)
            madness_visual.waist_roll = deterministic_between(step + 607, -strength * 0.35, strength * 0.35)
            madness_visual.left_shoulder_pitch = deterministic_between(step + 701, -strength, strength)
            madness_visual.left_shoulder_yaw = deterministic_between(step + 809, -strength * 0.7, strength * 0.7)
            madness_visual.left_shoulder_roll = deterministic_between(step + 907, -strength, strength)
            madness_visual.right_shoulder_pitch = deterministic_between(step + 1009, -strength, strength)
            madness_visual.right_shoulder_yaw = deterministic_between(step + 1103, -strength * 0.7, strength * 0.7)
            madness_visual.right_shoulder_roll = deterministic_between(step + 1201, -strength, strength)
        end

        local function render_madness_body()
            local active = master:get() and aa_enabled:get() and current_state_override and current_state_override_mode == "Madness" and state_upper_body_chaos:get()
            if not active then restore_madness_body(); return end
            refresh_madness_character()
            local applied = false
            if madness_neck ~= nil and madness_neck.Parent ~= nil then madness_neck.Transform = CFrame.Angles(math.rad(madness_visual.neck_pitch), math.rad(madness_visual.neck_yaw), math.rad(madness_visual.neck_roll)); applied = true end
            if madness_waist ~= nil and madness_waist.Parent ~= nil then madness_waist.Transform = CFrame.Angles(math.rad(madness_visual.waist_pitch), math.rad(madness_visual.waist_yaw), math.rad(madness_visual.waist_roll)); applied = true end
            if madness_left_shoulder ~= nil and madness_left_shoulder.Parent ~= nil then madness_left_shoulder.Transform = CFrame.Angles(math.rad(madness_visual.left_shoulder_pitch), math.rad(madness_visual.left_shoulder_yaw), math.rad(madness_visual.left_shoulder_roll)); applied = true end
            if madness_right_shoulder ~= nil and madness_right_shoulder.Parent ~= nil then madness_right_shoulder.Transform = CFrame.Angles(math.rad(madness_visual.right_shoulder_pitch), math.rad(madness_visual.right_shoulder_yaw), math.rad(madness_visual.right_shoulder_roll)); applied = true end
            madness_body_applied = applied
        end

        local function resolve_mega_token(token, pitch_a, pitch_b, step)
            if type(token) == "number" then return clamp(token, -89, 89)
            elseif token == "A" then return pitch_a
            elseif token == "B" then return pitch_b
            elseif token == "-A" then return clamp(-pitch_a, -89, 89)
            elseif token == "-B" then return clamp(-pitch_b, -89, 89)
            elseif token == "R" or token == "RANDOM" then return deterministic_between(step, pitch_a, pitch_b) end
            return 0
        end

        local function get_pitch_override(tick)
            local selected_pitch = pitch_mode:get()
            if selected_pitch == "Custom" then return clamp(custom_pitch:get(), -89, 89) end
            if selected_pitch ~= "Jitter" and selected_pitch ~= "Mega" then return selected_pitch end
            local pitch_a, pitch_b = clamp(pitch_jitter_a:get(), -89, 89), clamp(pitch_jitter_b:get(), -89, 89)
            local interval, step = math.max(1, math.floor(pitch_jitter_speed:get())), math.floor(tick / math.max(1, math.floor(pitch_jitter_speed:get())))
            if selected_pitch == "Jitter" then
                local pattern = pitch_jitter_pattern:get()
                if pattern == "3-Way" then
                    local center = clamp(pitch_jitter_center:get(), -89, 89)
                    local stage = step % 4
                    if stage == 0 then return pitch_a elseif stage == 1 or stage == 3 then return center end
                    return pitch_b
                elseif pattern == "Random" then return deterministic_between(step, pitch_a, pitch_b)
                elseif pattern == "Sway" then
                    local midpoint, amplitude = (pitch_a + pitch_b) * 0.5, (pitch_b - pitch_a) * 0.5
                    return clamp(midpoint + math.sin(tick * (0.18 / interval)) * amplitude, -89, 89)
                end
                return step % 2 == 0 and pitch_a or pitch_b
            end
            local token = sample_timed_sequence(mega_sequence_data, step)
            return resolve_mega_token(token, pitch_a, pitch_b, step)
        end

        local function apply_configured_yaw_pattern(tick, base_offset)
            local modifier = yaw_modifier:get()
            local amount = clamp(modifier_amount:get(), 0, 180)
            local period = math.max(1, math.floor(yaw_pattern_period:get()))
            local step = math.floor(tick / period)
            if modifier == "Disabled" then aa.override_yaw_offset(base_offset); aa.override_yaw_modifier("Disabled", 0)
            elseif modifier == "Center" or modifier == "3-Way" or modifier == "5-Way" then aa.override_yaw_offset(base_offset); aa.override_yaw_modifier(modifier, amount)
            elseif modifier == "Sway" then aa.override_yaw_offset(base_offset); sway_amount = amount; aa.override_yaw_modifier(sway_modifier)
            else
                local custom = 0
                if modifier == "Asymmetric" then
                    local left_hold, right_hold = math.max(1, math.floor(yaw_asymmetric_left_hold:get())), math.max(1, math.floor(yaw_asymmetric_right_hold:get()))
                    local phase = step % (left_hold + right_hold)
                    custom = phase < left_hold and clamp(yaw_asymmetric_left:get(), -180, 180) or clamp(yaw_asymmetric_right:get(), -180, 180)
                elseif modifier == "Random" then custom = deterministic_between(step, -amount, amount)
                elseif modifier == "Sequence" then custom = sample_timed_sequence(yaw_sequence_data, step)
                elseif modifier == "Spin" then custom = normalized_angle(tick * call_or(1 / 64, globals.tickinterval) * clamp(yaw_spin_speed:get(), -720, 720))
                elseif modifier == "Sine" then custom = math.sin(tick * 2 * math.pi / math.max(2, math.floor(yaw_wave_period:get()))) * amount
                elseif modifier == "Triangle" then custom = (1 - 4 * math.abs((tick / math.max(2, math.floor(yaw_wave_period:get()))) % 1 - 0.5)) * amount end
                aa.override_yaw_modifier("Disabled", 0)
                aa.override_yaw_offset(normalized_angle(base_offset + custom))
            end
        end

        local function update_manual_direction()
            manual_yaw = nil
            if not manual_direction_enabled:get() then return end
            if manual_left:get() then manual_yaw = 90 elseif manual_right:get() then manual_yaw = -90 elseif manual_back:get() then manual_yaw = 180 elseif manual_forward:get() then manual_yaw = 0 end
        end

        local function update_flick_runtime()
            local key_down, toggle_mode = flick_bind:get() == true, flick_bind_mode:get() == "Toggle"
            if not flick_enabled:get() then flick_runtime.state = "REST"; flick_runtime.timer = 0; flick_runtime.toggle_active = false; flick_runtime.previous_key = key_down; flick_runtime.active = false; return false end
            if toggle_mode and key_down and not flick_runtime.previous_key then flick_runtime.toggle_active = not flick_runtime.toggle_active end
            flick_runtime.previous_key = key_down
            local running = (not toggle_mode and key_down) or (toggle_mode and flick_runtime.toggle_active)
            if not running then flick_runtime.state = "REST"; flick_runtime.timer = 0; flick_runtime.active = false; if not toggle_mode then flick_runtime.toggle_active = false end; return false end
            flick_runtime.timer = flick_runtime.timer + 1
            flick_runtime.active = flick_runtime.state == "FLICK"
            if flick_runtime.state == "REST" then
                if flick_runtime.timer >= math.max(1, math.floor(flick_rest_ticks:get())) then flick_runtime.state = "FLICK"; flick_runtime.timer = 0; flick_runtime.active = true end
            elseif flick_runtime.timer >= math.max(1, math.floor(flick_ticks:get())) then flick_runtime.state = "REST"; flick_runtime.timer = 0; flick_runtime.active = false end
            return flick_runtime.active
        end

        local function compute_desync_values(tick, inverted)
            local mode, static_limit = desync_pattern:get(), clamp(desync_limit:get(), 0, 86)
            if mode == "Static" then return static_limit, static_limit, false, 0, 0 end
            local left_min, left_max, right_min, right_max = clamp(desync_left_min:get(), 0, 86), clamp(desync_left_max:get(), 0, 86), clamp(desync_right_min:get(), 0, 86), clamp(desync_right_max:get(), 0, 86)
            local period, step = math.max(1, math.floor(desync_pattern_period:get())), math.floor(tick / math.max(1, math.floor(desync_pattern_period:get())))
            if mode == "Explicit" then
                local real, fake = clamp(desync_real:get(), -86, 86), clamp(desync_fake:get(), -86, 86)
                if desync_mirror_explicit:get() and inverted then real = -real; fake = -fake end
                return left_max, right_max, true, real, fake
            elseif mode == "Alternating" then
                if step % 2 == 0 then return left_max, right_min, false, 0, 0 end
                return left_min, right_max, false, 0, 0
            elseif mode == "Random" then return deterministic_between(step, left_min, left_max), deterministic_between(step + 79, right_min, right_max), false, 0, 0
            elseif mode == "Sine" then
                local wave = (math.sin(tick * 2 * math.pi / period) + 1) * 0.5
                return left_min + (left_max - left_min) * wave, right_min + (right_max - right_min) * (1 - wave), false, 0, 0
            elseif mode == "Sequence" then
                local value = clamp(sample_timed_sequence(desync_sequence_data, step), 0, 86)
                return math.min(value, left_max), math.min(value, right_max), false, 0, 0
            end
            return static_limit, static_limit, false, 0, 0
        end

        local function compute_fake_lag_limit(tick)
            local mode, maximum = fake_lag_pattern:get(), clamp(fake_lag_limit:get(), 0, 14)
            if mode == "Static" then return math.floor(maximum) end
            local minimum, period, step = clamp(fake_lag_min:get(), 0, 14), math.max(1, math.floor(fake_lag_pattern_period:get())), math.floor(tick / math.max(1, math.floor(fake_lag_pattern_period:get())))
            local value = maximum
            if mode == "Alternating" then value = step % 2 == 0 and minimum or maximum
            elseif mode == "Random" then value = deterministic_between(step + 313, minimum, maximum)
            elseif mode == "Sine" then value = minimum + (maximum - minimum) * (math.sin(tick * 2 * math.pi / period) + 1) * 0.5
            elseif mode == "Sequence" then value = sample_timed_sequence(fake_lag_sequence_data, step) end
            return math.floor(clamp(value, 0, 14) + 0.5)
        end

        local function update_local_snapshot()
            local local_player = call_or(nil, entity.get_local_player)
            local info = local_player and call_or(nil, entity.get_info, local_player) or nil
            local weapon = call_or(nil, client.get_weapon)
            current_scoped = weapon ~= nil and weapon.is_scoped == true
            if info ~= nil then
                current_state, current_weapon = tostring(info.state or "Unknown"), tostring(info.weapon_name or (weapon and (weapon.name or weapon.id)) or "None")
                current_speed, current_in_air, current_crouching = tonumber(info.speed) or 0, info.is_in_air == true, info.is_crouching == true
            else
                current_state, current_weapon, current_speed, current_in_air, current_crouching = "Unknown", weapon and tostring(weapon.name or weapon.id or "None") or "None", 0, false, false
            end
        end

        local function is_sniper_weapon()
            local weapon = call_or(nil, client.get_weapon)
            if weapon == nil then return false end
            local weapon_type, weapon_name = string.lower(tostring(weapon.type or "")), string.lower(tostring(weapon.name or weapon.id or ""))
            return string.find(weapon_type, "sniper", 1, true) ~= nil or string.find(weapon_name, "scout", 1, true) ~= nil or string.find(weapon_name, "ssg", 1, true) ~= nil or string.find(weapon_name, "awp", 1, true) ~= nil or string.find(weapon_name, "auto sniper", 1, true) ~= nil
        end

        local function apply_anti_aim(tick)
            local wants_explicit_desync = desync_enabled:get() and desync_pattern:get() == "Explicit"
            if explicit_desync_active and not wants_explicit_desync then aa.reset() end
            aa_runtime_active = true
            local state_active = should_use_state_override()
            current_state_override = state_active
            if state_active then
                local selected_state_mode = state_override_mode:get()
                local mode_changed = current_state_override_mode ~= selected_state_mode
                if not state_override_was_active or mode_changed then
                    state_spin_started_at = globals.realtime()
                    if state_disable_fake_lag:get() then aa.unchoke() end
                end
                current_state_override_mode = selected_state_mode
                if selected_state_mode == "Madness" then
                    local period, step = math.max(1, math.floor(state_madness_period:get())), math.floor(tick / math.max(1, math.floor(state_madness_period:get())))
                    madness_step_runtime = step
                    local pitch = deterministic_between(step + 17, clamp(state_madness_pitch_min:get(), -89, 89), clamp(state_madness_pitch_max:get(), -89, 89))
                    local yaw_range = clamp(state_madness_yaw_range:get(), 0, 180)
                    local yaw = deterministic_between(step + 43, -yaw_range, yaw_range)
                    local offset = deterministic_between(step + 79, -180, 180)
                    aa.override_pitch(pitch); aa.override_yaw(yaw, "camera"); aa.override_yaw_offset(offset); aa.override_yaw_modifier("Disabled", 0)
                    update_madness_visual(step)
                else
                    state_spin_speed_runtime, state_spin_direction_runtime = clamp(state_spin_speed:get(), 30, 1440), state_spin_direction:get() == "Left" and -1 or 1
                    aa.override_pitch(clamp(state_pitch:get(), -89, 89)); aa.override_yaw(YAW_BASES[state_yaw_base:get()] or 180, "camera"); aa.override_yaw_offset(clamp(state_yaw_offset:get(), -180, 180)); aa.override_yaw_modifier(state_spin_modifier)
                end
            else
                current_state_override_mode = "None"
                aa.override_pitch(get_pitch_override(tick)); aa.override_yaw(YAW_BASES[yaw_base:get()] or 180, "camera")
                local amount = clamp(modifier_amount:get(), 0, 180)
                if adaptive_aa:get() then
                    aa.override_yaw_offset(clamp(yaw_offset:get(), -180, 180))
                    if current_state == "Jumping" then aa.override_yaw_modifier("Spin", amount) elseif current_state == "Duck" then aa.override_yaw_modifier("5-Way", amount) elseif current_state == "Run" then aa.override_yaw_modifier("3-Way", amount) else aa.override_yaw_modifier("Center", amount) end
                else apply_configured_yaw_pattern(tick, clamp(yaw_offset:get(), -180, 180)) end
            end
            update_manual_direction()
            if manual_yaw ~= nil then aa.override_yaw(manual_yaw, "camera"); aa.override_yaw_modifier("Disabled", 0) end
            if update_flick_runtime() then aa.override_yaw(clamp(flick_yaw:get(), -180, 180), "camera"); aa.override_pitch(clamp(flick_pitch:get(), -89, 89)) end
            state_override_was_active = state_active
            local body_enabled = desync_enabled:get()
            aa.override_body_yaw(body_enabled)
            if body_enabled then
                local madness_desync = state_active and current_state_override_mode == "Madness" and state_madness_desync:get()
                local inverted = inverter_key:get()
                if madness_desync then inverted = deterministic_unit(madness_step_runtime + 907) >= 0.5
                elseif auto_invert:get() then inverted = math.floor(tick / math.max(1, math.floor(invert_interval:get()))) % 2 == 1 end
                aa.override_inverter(inverted)
                local left, right, explicit, real, fake
                if madness_desync then left, right, explicit, real, fake = deterministic_between(madness_step_runtime + 1009, 0, 86), deterministic_between(madness_step_runtime + 1201, 0, 86), false, 0, 0
                else left, right, explicit, real, fake = compute_desync_values(tick, inverted) end
                aa.override_desync_limits(left, right)
                if explicit then aa.override_desync(real, fake) end
                explicit_desync_active = explicit
                aa.override_show_fake(show_fake:get())
            else explicit_desync_active = false; aa.override_show_fake(false) end
            local lag_enabled = fake_lag_enabled:get()
            if state_active and state_disable_fake_lag:get() then lag_enabled = false end
            aa.override_fake_lag(lag_enabled)
            if lag_enabled then aa.override_fake_lag_limit(compute_fake_lag_limit(tick)); aa.override_fake_lag_variability(clamp(fake_lag_variability:get(), 0, 100)) end
        end

        local function reset_anti_aim()
            if aa_runtime_active then aa.reset(); aa_runtime_active = false end
            current_state_override, current_state_override_mode, state_override_was_active = false, "None", false
            restore_madness_body(); explicit_desync_active, manual_yaw = false, nil
            flick_runtime.state, flick_runtime.timer, flick_runtime.active, flick_runtime.toggle_active, flick_runtime.previous_key = "REST", 0, false, false, false
        end

        local function apply_rage()
            rage_runtime_active = true; rage.override_enabled(true)
            local damage_value, hitchance_value = min_damage:get(), hitchance:get()
            if weapon_profiles:get() and is_sniper_weapon() then damage_value, hitchance_value = sniper_damage:get(), sniper_hitchance:get() end
            rage.override_min_damage(clamp(damage_value, 1, 130)); rage.override_hitchance(clamp(hitchance_value, 0, 100)); rage.override_target_selection(target_selection:get())
            local preset = hitbox_preset:get()
            rage.override_hitboxes(HITBOX_PRESETS[preset] or HITBOX_PRESETS["Head + chest"]); rage.override_hitbox_priority(HITBOX_PRIORITIES[preset] or HITBOX_PRIORITIES["Head + chest"])
            rage.override_force_baim(force_baim:get()); rage.override_force_safe_point(force_safe:get())
        end

        local function reset_rage() if rage_runtime_active then rage.reset(); rage_runtime_active = false end end
        local function apply_resolver() resolver_runtime_active = true; rage.set_resolver_enabled(true); rage.set_resolver_mode(resolver_mode:get()); rage.set_resolver_miss_limit(clamp(resolver_miss_limit:get(), 1, 5)); rage.set_resolver_baim_after_misses(clamp(resolver_baim_after:get(), 0, 5)) end
        local function restore_resolver() if not resolver_runtime_active then return end; rage.set_resolver_enabled(original_resolver.enabled); rage.set_resolver_mode(original_resolver.mode); rage.set_resolver_miss_limit(original_resolver.miss_limit); rage.set_resolver_baim_after_misses(original_resolver.baim_after); resolver_runtime_active = false end
        local function apply_auto_scope() if auto_scope_reference == nil then return end; auto_scope_applied = true; pcall(ui.set, auto_scope_reference, auto_scope:get() == true) end
        local function restore_auto_scope() if auto_scope_reference ~= nil and auto_scope_applied then pcall(ui.set, auto_scope_reference, original_auto_scope) end; auto_scope_applied = false end
        local function restore_auto_duck() if auto_duck_reference ~= nil and auto_duck_applied then pcall(ui.set, auto_duck_reference, original_auto_duck) end; auto_duck_applied = false end

        local function update_movement_choke(tick)
            local blocked_by_state, moving = current_state_override and state_disable_fake_lag:get(), current_speed >= clamp(autostop_min_speed:get(), 1, 200)
            local active = autostop_enabled:get() and moving and not blocked_by_state
            if not active then
                if movement_choke_active then aa.flush_choked(); if not aa_enabled:get() then aa.override_fake_lag(false) end end
                movement_choke_active, movement_choke_started = false, tick; restore_auto_duck(); return
            end
            if not movement_choke_active then movement_choke_active, movement_choke_started = true, tick end
            aa_runtime_active = true; aa.override_fake_lag(true); aa.override_fake_lag_limit(clamp(autostop_choke_ticks:get(), 1, 14))
            if autostop_duck:get() and auto_duck_reference ~= nil then pcall(ui.set, auto_duck_reference, true); auto_duck_applied = true else restore_auto_duck() end
            if tick - movement_choke_started >= clamp(autostop_choke_ticks:get(), 1, 14) then aa.flush_choked(); movement_choke_started = tick end
        end

        local function clear_resolver_overrides() if resolver_overrides_applied then pcall(plist.reset_all) end; resolver_overrides_applied = false end
        local function apply_player_resolver_overrides()
            if not resolver_enabled:get() or not resolver_player_overrides:get() then clear_resolver_overrides(); return end
            local enemies = call_or(nil, entity.get_enemies); if type(enemies) ~= "table" then enemies = {} end
            local baim_threshold, force_body = clamp(resolver_baim_after:get(), 0, 5), force_baim:get() == true
            for _, enemy in ipairs(enemies) do
                if call_or(false, entity.is_alive, enemy) then
                    local state = get_resolver_target_state(enemy)
                    if state.freestand == nil and resolver_freestand_seed:get() then
                        state.freestand = detect_enemy_freestand(enemy)
                        if state.freestand == "left" then state.stage = 0 elseif state.freestand == "right" then state.stage = 1 else state.stage = 2 end
                    end
                    if resolver_lock_on_hit:get() and state.locked_yaw ~= nil then
                        pcall(plist.set, enemy, "Force body yaw", true); pcall(plist.set, enemy, "Force body yaw value", state.locked_yaw); state.lock_applied = true
                    else
                        if state.lock_applied then pcall(rage.reset_player, enemy); state.lock_applied = false end
                        pcall(plist.set, enemy, "Force body yaw", true)
                        local offset = sample_timed_sequence(resolver_sequence_data, state.stage)
                        pcall(plist.set, enemy, "Override yaw offset", normalized_angle(offset))
                    end
                    local baim = force_body or (baim_threshold > 0 and state.misses >= baim_threshold)
                    pcall(plist.set, enemy, "Override prefer body aim", baim and "Force" or "-")
                    pcall(plist.set, enemy, "Override safe point", baim and resolver_safe_on_baim:get() and "Force" or "-")
                end
            end
            resolver_overrides_applied = true
        end

        local function disable_toolkit_runtime()
            if movement_choke_active then aa.flush_choked() end
            movement_choke_active = false; restore_auto_duck(); clear_resolver_overrides(); reset_anti_aim(); reset_rage(); restore_resolver(); restore_auto_scope(); toolkit_active = false
        end

        local killstreak, killstreak_hits, killstreak_alive, killstreak_local_alive, killstreak_text = 0, {}, {}, true, nil
        local function killstreak_key(target) return target_key(get_target_slot(target) or target) end
        local function killstreak_reset() killstreak = 0; killstreak_hits = {}; killstreak_alive = {} end
        local function killstreak_draw()
            if killstreak_text ~= nil then return killstreak_text end
            pcall(function()
                local object = Drawing.new("Text")
                object.Size = 24; object.Color = Color3.fromRGB(255, 255, 255); object.Outline = true; object.Visible = false
                pcall(function() object.Font = Drawing.Fonts.Plex end); pcall(function() object.Center = true end); pcall(function() object.ZIndex = 20 end)
                killstreak_text = object
            end)
            return killstreak_text
        end
        killstreak_draw()

        local function render_killstreak()
            local object = killstreak_draw(); if object == nil then return end
            local width, height = 1920, 1080
            local ok, screen_width, screen_height = pcall(render.screen_size)
            if ok and type(screen_width) == "number" and type(screen_height) == "number" and screen_width > 0 and screen_height > 0 then width, height = screen_width, screen_height end
            local visible, label = master:get(), string.format("Killstreak %d ", killstreak)
            pcall(function() object.Text = label; object.Position = Vector2.new(width * 0.5, height - 110); object.Visible = visible end)
        end

        local function update_killstreak(tick)
            local player = call_or(nil, entity.get_local_player)
            local local_alive = player ~= nil and call_or(false, entity.is_alive, player) == true
            if killstreak_local_alive and not local_alive then killstreak_reset() end
            killstreak_local_alive = local_alive
            local enemies = call_or(nil, entity.get_enemies); if type(enemies) ~= "table" then return end
            for _, enemy in ipairs(enemies) do
                local key = killstreak_key(enemy); local alive = call_or(false, entity.is_alive, enemy) == true
                if killstreak_alive[key] == true and not alive then
                    local hit_tick = killstreak_hits[key]
                    if hit_tick ~= nil and tick - hit_tick <= 128 then killstreak = killstreak + 1 end
                    killstreak_hits[key] = nil
                end
                killstreak_alive[key] = alive
            end
        end

        events.on_tick(function(tick)
            update_killstreak(tick)
            if not master:get() then if toolkit_active then disable_toolkit_runtime() end; return end
            toolkit_active = true; update_local_snapshot()
            if aa_enabled:get() then apply_anti_aim(tick) else reset_anti_aim() end
            update_movement_choke(tick)
            if rage_enabled:get() then apply_rage() else reset_rage() end
            apply_auto_scope()
            if resolver_enabled:get() then apply_resolver(); apply_player_resolver_overrides() else clear_resolver_overrides(); restore_resolver() end
        end)

        client.set_event_callback("aim_fire", function(event)
            if not master:get() then return end
            if event ~= nil and event.id ~= nil then pending_shots[event.id] = { target = event.target, resolved_yaw = event.resolved_yaw } end
            if unchoke_on_shot:get() and aa_runtime_active then aa.unchoke() end
            if movement_choke_active then aa.flush_choked(); movement_choke_started = call_or(0, globals.tickcount) end
        end)

        client.set_event_callback("aim_hit", function(event)
            if not master:get() then return end
            local target = event and event.target
            target_misses[target_key(target)] = 0
            if target ~= nil then
                local state = get_resolver_target_state(target)
                killstreak_hits[killstreak_key(target)] = call_or(0, globals.tickcount)
                state.hits, state.misses = state.hits + 1, 0
                if resolver_reset_on_hit:get() then state.stage = 0 end
                if resolver_lock_on_hit:get() then
                    local shot = event.id ~= nil and pending_shots[event.id] or nil
                    local resolved = shot and tonumber(shot.resolved_yaw) or nil
                    if resolved == nil then local current = call_or(nil, rage.get_target); resolved = current and tonumber(current.resolved_yaw_deg) or nil end
                    state.locked_yaw = resolved and normalized_angle(resolved) or state.locked_yaw
                end
            end
            if event ~= nil and event.id ~= nil then pending_shots[event.id] = nil end
        end)

        client.set_event_callback("aim_miss", function(event)
            if not master:get() then return end
            local target = event and event.target
            local key = target_key(target)
            target_misses[key] = (target_misses[key] or 0) + 1
            if event ~= nil and event.reason == "resolver" then
                local state = get_resolver_target_state(target)
                state.misses, state.locked_yaw = state.misses + 1, nil
                if state.misses % math.max(1, math.floor(resolver_miss_limit:get())) == 0 then state.stage = state.stage + 1 end
            end
            if event ~= nil and event.id ~= nil then pending_shots[event.id] = nil end
        end)

        client.set_event_callback("paint", function() pcall(render_killstreak); pcall(render_madness_body) end)
        client.set_event_callback("shutdown", function() save_config(); disable_toolkit_runtime() end)
        
        load_config()
        print("Blessed HvH + Furry loaded | t.me/blessedlua")

    else
        -- Если пароль неверный
        attempts = attempts - 1
        real_password = ""
        pcall(function() pass_box:set("") end)
        
        if attempts <= 0 then
            if unlock_btn then pcall(function() unlock_btn:remove() end) end
            pcall(function() pass_box:remove() end)
            local lock_lbl = sec_right:new_label("lua locked by protection")
            if lock_lbl and lock_lbl.set_color then pcall(function() lock_lbl:set_color(255, 50, 50) end) end
            task.wait(1.5); hide_password_tab(); return
        end
    end
end

unlock_btn = sec_right:new_button("Unlock Script", on_password_submit)

if client and type(client.set_event_callback) == "function" then
    client.set_event_callback("key_press", function(key)
        if is_authenticated or attempts <= 0 then return end
        local key_str = tostring(key)
        if string.len(key_str) == 1 and string.find(key_str, "%d") then
            if #real_password < 4 then real_password = real_password .. key_str else real_password = key_str end
        elseif key == 8 then real_password = string.sub(real_password, 1, -2) end
    end)
end
