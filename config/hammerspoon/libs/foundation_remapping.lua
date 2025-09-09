
--  foundation_remapping.lua
-- https://github.com/hetima/hammerspoon-foundation_remapping

-- reference:
-- Technical Note TN2450 Remapping Keys in macOS 10.12 Sierra)
-- https://developer.apple.com/library/content/technotes/tn2450/

local FOUNDATION_REMAPPING_VERSION = '0.1.1'

local log = hs.logger.new('foundation_remapping', 'debug')


CFundationRemap = {
    version = FOUNDATION_REMAPPING_VERSION,
}

-- Never use these values as it is.
-- Bitwise OR with 0x700000000 required. (or simply add 0x700000000)
CFundationRemap.hidkeys = {
    [0x00] = 0x04, -- a
    [0x0b] = 0x05,
    [0x08] = 0x06,
    [0x02] = 0x07,
    [0x0e] = 0x08,
    [0x03] = 0x09,
    [0x05] = 0x0a,
    [0x04] = 0x0b,
    [0x22] = 0x0c,
    [0x26] = 0x0d,
    [0x28] = 0x0e,
    [0x25] = 0x0f,
    [0x2e] = 0x10,
    [0x2d] = 0x11,
    [0x1f] = 0x12,
    [0x23] = 0x13,
    [0x0c] = 0x14,
    [0x0f] = 0x15,
    [0x01] = 0x16,
    [0x11] = 0x17,
    [0x20] = 0x18,
    [0x09] = 0x19,
    [0x0d] = 0x1a,
    [0x07] = 0x1b,
    [0x10] = 0x1c,
    [0x06] = 0x1d, -- z
    [0x12] = 0x1e, -- 1
    [0x13] = 0x1f,
    [0x14] = 0x20,
    [0x15] = 0x21,
    [0x17] = 0x22,
    [0x16] = 0x23,
    [0x1a] = 0x24,
    [0x1c] = 0x25,
    [0x19] = 0x26,
    [0x1d] = 0x27, -- 0
    [0x24] = 0x28, -- Return
    [0x35] = 0x29, -- esc
    [0x33] = 0x2a, -- delete back space
    [0x30] = 0x2b, -- tab
    [0x31] = 0x2c, -- space
    [0x1b] = 0x2d, -- - and _
    [0x18] = 0x2e, -- = and +
    [0x21] = 0x2f, -- [ and {
    [0x1e] = 0x30, -- ] and }
    [0x2a] = 0x31, --  \ and |
    [0x2a] = 0x32, -- Non-US # and ~
    [0x29] = 0x33, -- ; and :
    [0x27] = 0x34, -- ' and "
    [0x32] = 0x35, -- Grave Accent and Tilde E/J
    [0x2b] = 0x36, -- , and "<"
    [0x2f] = 0x37, -- . and ">"
    [0x2c] = 0x38, -- / and ?
    [0x39] = 0x39, -- Caps Lock
    [0x7a] = 0x3a, -- F1
    [0x78] = 0x3b,
    [0x63] = 0x3c,
    [0x76] = 0x3d,
    [0x60] = 0x3e,
    [0x61] = 0x3f,
    [0x62] = 0x40,
    [0x64] = 0x41,
    [0x65] = 0x42,
    [0x6d] = 0x43,
    [0x67] = 0x44,
    [0x6f] = 0x45, -- F12
    [0x69] = 0x46, PrintScreen = 0x46, -- Print Screen
    [0x6b] = 0x47, ScrollLock = 0x47, -- Scroll Lock
    [0x71] = 0x48, Pause = 0x48, -- Pause
    [0x72] = 0x49, Insert = 0x49,-- Insert conflict with help
    [0x73] = 0x4a, -- Home
    [0x74] = 0x4b, -- Page Up
    [0x75] = 0x4c, -- Delete Forward
    [0x77] = 0x4d, -- End
    [0x79] = 0x4e, -- Page Down
    [0x7c] = 0x4f, --Right arrow key, raw is 0x3c, virtual ADB is 0x7c
    [0x7b] = 0x50, --Left arrow key, raw is 0x3b, virtual ADB is 0x7b
    [0x7d] = 0x51, --Down arrow, raw is 0x3d, virtual is 0x7d
    [0x7e] = 0x52, --Up arrow key, raw is 0x3e, virtual is 0x7e
    [0x47] = 0x53, --Num Lock and Clear
    [0x4b] = 0x54, -- Keypad /
    [0x43] = 0x55, -- pad *
    [0x4e] = 0x56, -- pad -
    [0x45] = 0x57, -- pad +
    [0x4c] = 0x58, -- pad Enter
    [0x53] = 0x59, -- pad 1
    [0x54] = 0x5a,
    [0x55] = 0x5b,
    [0x56] = 0x5c,
    [0x57] = 0x5d,
    [0x58] = 0x5e,
    [0x59] = 0x5f,
    [0x5b] = 0x60,
    [0x5c] = 0x61,
    [0x52] = 0x62, -- pad 0
    [0x41] = 0x63, -- pad .
    [0x0a] = 0x64, -- \ and | ISO only
    [0x6e] = 0x65, Application=0x65,-- Application
    [0x7f] = 0x66, --This is the power key, scan code in ADB is 7f 7f, not 7f ff
    [0x51] = 0x67, -- pad =
    -- [0x69] = 0x68, --  F13 on Andy keyboards conflict with PrintScreen
    -- [0x6b] = 0x69, --  F14 on Andy keyboards conflict with ScrollLock
    -- [0x71] = 0x6a, --  F15 on Andy keyboards conflict with Pause
    [0x6a] = 0x6b, --  F16
    [0x40] = 0x6c, -- F17
    [0x4f] = 0x6d, -- F18
    [0x50] = 0x6e, -- F19
    [0x5a] = 0x6f, -- F20
    f21=0x70,  f22=0x71,  f23=0x72,  f24=0x73,
    Execute=0x74,
    -- [0x72] = 0x75, --help conflict with insert
    Menu=0x76, Select=0x77, Stop=0x78, Again=0x79, Undo=0x7a, Cut=0x7b, Copy=0x7c, Paste=0x7d, Find=0x7e,
    [0x4a] = 0x7f, -- Norsi Mute, or maybe 0x4a
    [0x48] = 0x80, -- Norsi volume up, otherwise is 0x48 in ADB
    [0x49] = 0x81, -- Norsi volume down
    LockCapsLock=0x82, LockNumLocl=0x83, LockScrollLock=0x84,
    [0x5f] = 0x85, -- pad , JIS only
    -- padEqualSign=0x86
    International1=0x87, [0x5e] = 0x87, JISUnderScore = 0x87,-- Ro (JIS) International1 _ ろ
    International2=0x88, PCKana=0x88, -- PC Kana|Roma-ji
    International3=0x89, [0x5d] = 0x89, -- Yen (JIS)   ￥
    International4=0x8a,  XFER=0x8a, Henkan=0x8a, -- XFER 変換
    International5=0x8b,  NFER=0x8b, Muhenkan=0x8b,-- NFER 無変換
    International6=0x8c,  -- ,
    International7=0x8d,  -- DoubleByte/SingleByte
    International8=0x8e,  -- undef
    International9=0x8f,  -- undef

    [0x68] = 0x90, -- Kana lang1
    [0x66] = 0x91, -- Eisu lang2
    lang3=0x92, --Hiragana?
    lang4=0x93, --Katakana?
    lang5=0x94, --Zenkaku/Hankaku?
    lang6=0x95,
    lang7=0x96,
    lang8=0x97,
    lang9=0x98,

    [0x3b] = 0xe0, lctrl = 0xe0, lctl = 0xe0,--Left Control.  raw is 0x36, virtual is 0x3b
    [0x38] = 0xe1, lshift = 0xe1, --Left Shift
    [0x3a] = 0xe2, lalt = 0xe2, lopt = 0xe2, --Left option/alt key
    [0x37] = 0xe3, lcmd = 0xe3,--Left command key
    [0x3e] = 0xe4, rctrl = 0xe4, rctl = 0xe4, --Right Control, use 0x3e virtual
    [0x3c] = 0xe5, rshift = 0xe5, --Right Shift, use 0x3c virtual
    [0x3d] = 0xe6, ralt = 0xe6, ropt = 0xe6, --Right Option, use 0x3d virtual
    [0x36] = 0xe7, rcmd = 0xe7, --Right Command, use 0x36 virtual

    -- 全角/半角キーはいくつか該当しそうなのがあるけれど、うちでは [0x32] = 0x35, -- Grave Accent and Tilde と判定される
}
for i, v in pairs(CFundationRemap.hidkeys) do
    if type(v) == 'number' then
        CFundationRemap.hidkeys[i] = v + 0x700000000
    end
end

-- keyCode を数値に統一
local function realKeyCode(v)
    if type(v) == 'string' then
        v = hs.keycodes.map[v]
    end
    if type(v) == 'number' then
        return v
    end
    return nil
end

-- keyCode を hidutil で使える値に変換
local function hidKeyCode(keyCode)
    local hidCode = nil
    if (type(keyCode) == 'number') and (keyCode > 0x700000000) then
        return keyCode
    end
    --hidkeys[string] があるかどうか
    if type(keyCode) == 'string' then
        hidCode = CFundationRemap.hidkeys[keyCode]
        if hidCode ~= nil then
            return hidCode
        end
    end

    keyCode = realKeyCode(keyCode)
    if keyCode ~= nil then
        --数値keyCodeで探す
        return CFundationRemap.hidkeys[keyCode]
    end

    return nil
end


local CFundationRemapImpl = {

    remap = function(self, fromKey, toKey)
        fromKey = hidKeyCode(fromKey)
        toKey = hidKeyCode(toKey)
        if fromKey and toKey then
            table.insert(self._remaps, {from=fromKey, to=toKey})
        end
        return self
    end,

    nullfy = function(self, fromKey)
        fromKey = hidKeyCode(fromKey)
        if fromKey then
            table.insert(self._remaps, {from=fromKey, to=0})
        end
        return self
    end,

    -- --filter '{"ProductID":...,"VendorID":...}'
    _filterArgument = function(self)
        local filter = ''
        if self.productID then
            filter = '"ProductID":' .. self.productID .. ','
        end
        if self.vendorID then
            filter = filter .. '"VendorID":' .. self.vendorID .. ','
        end
        local optionName = '--filter'
        if os.execute("hidutil property --help | grep -e '--matching'") then
            optionName = '--matching'
        end
        if #filter > 0 then
            return ' ' .. optionName .. ' \'{' .. filter .. '}\''
        end
        return ''
    end,

    -- /usr/bin/hidutil property --filter '{"ProductID":...,"VendorID":...}' --set '{"UserKeyMapping":[{...},...]}'
    command = function(self)
        if #self._remaps == 0 then
            return nil
        end

        local filter = self:_filterArgument()
        local cmd = '/usr/bin/hidutil property' .. filter .. ' --set \'{"UserKeyMapping":['

        for i, v in ipairs(self._remaps) do
            if type(v) == 'table' then
                cmd = cmd .. '{"HIDKeyboardModifierMappingSrc":' .. v.from .. ',"HIDKeyboardModifierMappingDst":' .. v.to .. '},'
            end
        end
        cmd = cmd .. ']}\''
        return cmd
    end,

    -- /usr/bin/hidutil property --filter '{"ProductID":...,"VendorID":...}' --set '{"UserKeyMapping":[]}'
    resetCommand = function(self)
        local filter = self:_filterArgument()
        local cmd = '/usr/bin/hidutil property' .. filter .. ' --set \'{"UserKeyMapping":[]}\''
        return cmd
    end,

    register = function(self)
        local cmd = self:command()
        if cmd then
            if os.execute(cmd) ~= true then
                log.d('error occured while register()')
                log.d('command:' .. cmd)
            end
        end
        return self
    end,

    unregister = function(self)
        local cmd = self:resetCommand()
        if cmd then
            if os.execute(cmd) ~= true then
                log.d('error occured while unregister()')
                log.d('command:' .. cmd)
            end
        end
        return self
    end,

}

CFundationRemap.new = function(opt)
    local _self = {
        _remaps = {},
        vendorID = nil,
        productID = nil,
    }
    setmetatable(_self, {__index = CFundationRemapImpl})

    if type(opt) == 'table' then
        if type(opt.vendorID) == 'number' then
            _self.vendorID = opt.vendorID
        end
        if type(opt.productID) == 'number' then
            _self.productID = opt.productID
        end
    end

    return _self
end

return CFundationRemap
