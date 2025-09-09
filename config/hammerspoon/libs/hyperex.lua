
--  hyperex.lua
-- https://github.com/hetima/hammerspoon-hyperex

local HYPEREX_VERSION = '0.3'

local log = hs.logger.new('hyperex', 'debug')

local KEY_DOWN = 1
local KEY_REPEAT = 2
local KEY_UP = 3

CHyper = {
    version = HYPEREX_VERSION,
    alertStyle = {
        strokeWidth  = 4,
        strokeColor = { white = 1, alpha = 0.95 },
        fillColor   = { white = 0, alpha = 0.75 },
        textColor = { white = 1, alpha = 0.95 },
        textFont  = ".AppleSystemUIFont",
        textSize  = 23,
        radius = 9,
    },

    showMessage = function(message, duration)
        if type(message) == 'string' then 
            return hs.alert.show(message, CHyper.alertStyle, hs.screen.mainScreen(), duration)
        end
    end,

}


-- 比較の手間を省くためにあらかじめ数値にしておく
local function realKeyCode(v)
    if type(v) == 'string' then
        v = hs.keycodes.map[v]
    end
    if type(v) == 'number' then
        return v
    end
    return nil
end

-- 2つの引数から modifiers と key を取得する。返り値は modifiers, key
-- ({'mod','mod'}, key) (key, {'mod','mod'}) -> 順不同で OK
-- ('key', nil)  -> modifiers は {}
-- ('mod+mod+key') -> オリジナル
local function parseKey(a1, a2)
    local parseSingle = function(a)
        if type(a) == 'number' then return {}, a end
        if type(a) == 'string' then
            local k = realKeyCode(a)
            if k ~= nil then return {}, k end
            -- parse mod+mod+k style
            k = a:lower()
            local words = hs.fnutils.split(k, '+')
            local key = nil
            local mods = hs.fnutils.imap(words, function(v)
                if v == 'cmd' or v == 'command' or v == '⌘' then
                    return 'cmd' 
                elseif v == 'ctrl' or v == 'control' or v == '⌃' or v == 'ctl' then
                    return 'ctrl' 
                elseif v == 'alt' or v == 'option' or v == '⌥' or v == 'opt' then
                    return 'alt' 
                elseif v == 'shift' or v == '⇧' or v == 'shft' then
                    return 'shift' 
                end
                if v == '' then
                    if key == 'pad' then key = 'pad+' end
                else
                    key = v
                end
                return nil
            end)
            return mods, realKeyCode(key)
        end
        return {}, nil
    end

    if a2 == nil then return parseSingle(a1) end

    local m = nil
    local k = nil

    if type(a1) == 'table' then
        m = a1
        k = a2
    elseif type(a2) == 'table' then
        m = a2
        k = a1
    end
    if k ~= nil then
        k = realKeyCode(k)
        return m, k
    end

    return {}, nil
end

local function modifiersToFlags(modifiers)
    local flags = {}
    for i, v in pairs(modifiers) do
        flags[v] = true
    end
    return flags
end

local function mergeFlags(t1, t2)
    local flags = {}
    for i, v in pairs(t1) do
        flags[i] = t1[i]
    end
    for i, v in pairs(t2) do
        flags[i] = t2[i]
    end
    return flags
end

local CModifier = {}
local CModifierImpl = {

    mod = function(self, modifiers)
        if type(modifiers) == 'string' then
            modifiers = {modifiers}
        end
        self._modFlags = modifiersToFlags(modifiers)
        return self
    end,

    withMessage = function(self, m, t)
        self.message = m
        if type(t) == 'number' then
            self.alertDuration = t
        end
        return self
    end,

    showMessage = function(self)
        if type(self.message) == 'string' then 
            CHyper.showMessage(self.message, self.alertDuration or 0)
        end
    end,

    to = function(self, ...)
        local keys = {...}
        local first = keys[1]
        if type(first) == 'string' then
            if first == 'any' or first == 'all' then
                self._anyTarget = true
                return self
            end
        elseif type(first) == 'table' then
            keys = first
        end
        local keyNumbers = {}
        for i, v in pairs(keys) do
            local specials = nil
            if v == 'atoz' then
                specials = {'a','b','c','d','e','f','g','h','i','j','k','l','m',
                    'n','o','p','q','r','s','t','u','v','w','x','y','z'}
            elseif v == 'fkeys' then
                specials = {'f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12','f13','f14','f15'}
            elseif v == 'num' then
                specials = {'1','2','3','4','5','6','7','8','9','0'}
            elseif v == 'pads' then
                specials = {'pad*', 'pad+', 'pad/', 'pad-', 'pad=', 'padclear', 'padenter',
                    'pad0', 'pad1', 'pad2', 'pad3', 'pad4', 'pad5', 'pad6', 'pad7', 'pad8', 'pad9'}
            else
                v = realKeyCode(v)
                if type(v) == 'number' then
                    table.insert(keyNumbers, v)
                end
            end
            if specials ~= nil then
                for i, v in pairs(specials) do
                    table.insert(keyNumbers, realKeyCode(v))
                end
            end
        end
        self._targetKeys = keyNumbers
        return self
    end,

    flagsForKey = function(self, key)
        if self._anyTarget then
            return self._modFlags
        end
        for i, v in pairs(self._targetKeys) do
            if key == v then
                return self._modFlags
            end
        end
        return nil
    end,

}

CModifier.new = function(hyperInstance)
    local _self = {
        _modFlags = {},
        _targetKeys = {},
        _anyTarget = false,
        message = nil,
        alertDuration = 0.4,
    }

    setmetatable(_self, {__index = CModifierImpl})
    return _self
end

local CBinder = {}
local CBinderImpl = {
    withMessage = function(self, m, t)
        self.message = m
        if type(t) == 'number' then
            self.alertDuration = t
        end
        return self
    end,

    showMessage = function(self)
        if type(self.message) == 'string' then 
            CHyper.showMessage(self.message, self.alertDuration or 0)
        end
    end,

    bind = function(self, fromKey, fromMod)
        self.fromMod, self.fromKey = parseKey(fromKey, fromMod)
        return self
    end,

    to = function(self, a1, a2)
        if type(a1) == 'function' then
            self.toFunc = a1
            self.toKey = nil
            return self
        end

        self.toFlags, self.toKey = parseKey(a1, a2)
        if self.toKey ~= nil then
            self.toFlags = modifiersToFlags(self.toFlags)
            self.toFunc = nil
        end
        return self
    end,

}

CBinder.new = function(hyperInstance)
    local _self = {
        fromKey = nil,
        fromMod = {},
        toKey = nil,
        toFlags = {},
        toFunc = nil,
        message = nil,
        alertDuration = 0.4,
        _parasited = false,
    }

    setmetatable(_self, {__index = CBinderImpl})

    return _self
end



local CHyperImpl = {
    withMessage = function(self, m, t, z)
        if type(m) == 'string' and #m > 0 then
            self.message = m
        end
        if type(t) == 'number' then
            self.alertDuration = t
        elseif type(t) == 'string' and #t > 0 then
            self.leaveMessage = t
            if type(z) == 'number' then
                self.alertDuration = z
            end
        end
        return self
    end,

    setInitialFunc = function(self, func)
        if (type(func) == 'function') then
            self._initialHitFunc = func
        end
        return self
    end,

    setInitialKey = function(self, key, modifiers)
        modifiers, key = parseKey(key, modifiers)
        if key == self._triggerKey then
            return self
        end
        self._initialHitFunc = function()
            hs.eventtap.event.newKeyEvent(modifiers, key, true):post()
            hs.timer.usleep(600)
            hs.eventtap.event.newKeyEvent(modifiers, key, false):post()
        end
        return self
    end,

    setEmptyHitFunc = function(self, func)
        if type(func) == 'function' then
            self._emptyHitFunc = func
        end
        return self
    end,

    setEmptyHitKey = function(self, key, modifiers)
        modifiers, key = parseKey(key, modifiers)
        if key == self._triggerKey then
            return self
        end
        self._emptyHitFunc = function()
            hs.eventtap.event.newKeyEvent(modifiers, key, true):post()
            hs.timer.usleep(600)
            hs.eventtap.event.newKeyEvent(modifiers, key, false):post()
        end
        return self
    end,

    bind = function(self, fromKey, fromMod)
        local b = CBinder.new(self):bind(fromKey, fromMod)
        table.insert(self._binders, b)
        return b
    end,

    mod = function(self, modifiers)
        local m = CModifier.new(self):mod(modifiers)
        table.insert(self._modifiers, m)
        return m
    end,

    enter = function(self)
        if self._tap:isEnabled() then
            log.d('try to re-enter')
            return
        end
        if type(self.message) == 'string' then 
            CHyper.showMessage(self.message, self.alertDuration or 0)
        end
        self._tap:start()
        if self._initialHitFunc then
            self._initialHitFunc()
        end
        self._triggered = false
    end,

    exit = function(self)
        if not self._tap:isEnabled() then
            log.d('try to re-exit')
            return
        end
        if type(self.leaveMessage) == 'string' then 
            CHyper.showMessage(self.leaveMessage, self.alertDuration or 0)
        end
        self._tap:stop()
        -- stop した後に呼ばないとキーイベントが発生しない
        if (not self._triggered) and self._emptyHitFunc then
            self._emptyHitFunc()
        end
    end,

    handleTap = function(self, e, keyCode, type)

        -- ややこしいことになるので triggerKey と同じものは無視
        -- hotkey 最初の keyDown は来ないが、押下中の keyRepeat は来る
        if keyCode == self._triggerKey then
            -- triggerKey の keyUp は確実に逃がさないとモードを抜け出せない
            if type == KEY_UP then
                return false
            else
                return true
            end
        end

        -- binder
        for i, v in ipairs(self._binders) do
            if keyCode == v.fromKey then
                -- remap 型
                if v.toKey ~= nil then
                    e:setKeyCode(v.toKey)
                    e:setFlags(v.toFlags)
                    if type == KEY_DOWN then
                        self._triggered = true
                        v:showMessage()
                    end
                    return false
                -- func 型
                elseif v.toFunc ~= nil then
                    if type == KEY_DOWN then
                        self._triggered = true
                        v:showMessage()
                        v.toFunc()
                    end
                    return true
                end
            end
        end

        -- modifier
        for i, v in ipairs(self._modifiers) do
            local flag = v:flagsForKey(keyCode)
            if flag ~= nil then
                e:setFlags(mergeFlags(flag, e:getFlags()))
                if type == KEY_DOWN then
                    self._triggered = true
                    v:showMessage()
                end
                return false
            end
        end

        -- parasite
        if self._parasited and type == KEY_DOWN then
            self._triggered = true
        end

        return false
    end,

}

CHyper.new = function(triggerKey)
    local _self = {
        message = nil,
        leaveMessage = nil,
        alertDuration = 0.4,

        _triggered = false,
        _binders = {},
        _modifiers = {},
        _emptyHitFunc = nil,
        _initialHitFunc = nil,

        _triggerKey = nil,
        _triggerMod = {}, -- unused now
        _trigger = nil,

        _tap = nil
    }

    setmetatable(_self, {__index = CHyperImpl})

    _self._triggerMod, _self._triggerKey = parseKey(triggerKey)
    if _self._triggerKey ~= nil then
        if CHyperParasites.realFlagMask[_self._triggerKey] ~= nil then
            _self:parasitize(_self._triggerKey)
        else
            local hotkeyDown = function() _self:enter() end
            local hotkeyUp = function() _self:exit() end
            _self._trigger = hs.hotkey.bind(_self._triggerMod, _self._triggerKey, 0, hotkeyDown, hotkeyUp, nil)
        end
    end

    local handleTap = function(e)
        -- キーボードからの直接入力だけを扱う
        local stateID = e:getProperty(hs.eventtap.event.properties['eventSourceStateID'])
        if stateID ~= 1 then
            return false
        end
        local keyCode = e:getKeyCode()
        local type = KEY_UP
        if e:getType() == hs.eventtap.event.types.keyDown then
            if e:getProperty(hs.eventtap.event.properties['keyboardEventAutorepeat']) == 0 then
                type = KEY_DOWN
            else
                type = KEY_REPEAT
            end
        end
        return _self:handleTap(e, keyCode, type)
    end
    _self._tap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, handleTap)

    return _self
end

-- Parasite modifier mode

CHyperParasites = {
    possibleKeys = {
        lcmd = 0x37, rcmd = 0x36,
        lalt = 0x3a, ralt = 0x3d,
        lctrl = 0x3b, rctrl = 0x3e,
        lshift = 0x38, rshift = 0x3c,
    },
    realFlagMask = {
        [0x37] = 8, -- lcmd  0000 1000
        [0x36] = 16, -- rcmd 0001 0000
        [0x3a] = 32, -- lalt 0010 0000
        [0x3d] = 64, -- ralt 0100 0000
        [0x3b] = 1, -- lctrl 0000 0001
        [0x3e] = 8192, -- rctrl 10 0000 0000 0000
        [0x38] = 2, -- lshift 0000 0010
        [0x3c] = 4, -- rshift 0000 0100
    },
    _parasites = {},
    _tap = nil,
}

CHyperParasites._handleTap = function(e)
    local stateID = e:getProperty(hs.eventtap.event.properties['eventSourceStateID'])
    if stateID ~= 1 then
        return false
    end
    local keyCode = e:getKeyCode()
    local hyper = CHyperParasites._parasites[keyCode]
    if hyper ~= nil then
        local realFlags = e:getRawEventData().CGEventData.flags
        local mask = CHyperParasites.realFlagMask[keyCode]
        if mask == nil then
            return false
        end
        if (realFlags & mask) == mask then
            -- log.d(keyCode, 'press', (realFlags))
            hyper:enter()
        else
            -- log.d(keyCode, 'release', (realFlags))
            hyper:exit()
        end
    end

    return false
end

CHyperParasites.startTap = function()
    if CHyperParasites._tap == nil then
         CHyperParasites._tap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, CHyperParasites._handleTap)
         CHyperParasites._tap:start()
    end
end

CHyperImpl.parasitize = function(self, modifier)
    if type(modifier) == 'string' then
        modifier = CHyperParasites.possibleKeys[modifier]
    end
    if CHyperParasites.realFlagMask[modifier] == nil then
        return self
    end
    local keyCode = modifier
    
    if CHyperParasites._parasites[keyCode] then
        return self
    end
    CHyperParasites.startTap()
    CHyperParasites._parasites[keyCode] = self
    
    self._parasited = true
    self.sticky = function(self)
        log.d('parasite can not become sticky')
        return self
    end
    return self
end


-- sticky mode

local STICKY_ONCE = 1
local STICKY_TOGGLE = 2
local STICKY_CHAIN = 3

local CHyperStickyImpl = {
    enter = function(self)
        if self._tap:isEnabled() then
            self:exitSticky()
        else
            -- log.d("Sticky enter")
            self._stickyModal:enter()
            CHyperImpl.enter(self)
        end
    end,

    exitSticky = function(self)
        -- log.d("Sticky exit")
        if  self.chainTimer then
            self.chainTimer:stop()
        end
        CHyperImpl.exit(self)
        self._stickyModal:exit()
    end,

    exit = function(self)
        -- intercept
    end,

    chain = function(self)
        if self.chainTimer == nil then
            self.chainTimer = hs.timer.delayed.new(self.chainDelay, function() self:exitSticky() end)
        end
        self.chainTimer:start()
    end,

    handleTap = function(self, e, keyCode, type)
        if keyCode == 0x35 or keyCode == self._triggerKey then
            return true
        end
        if self.stickyMode == STICKY_ONCE then
             self:exitSticky()
        elseif self.stickyMode == STICKY_CHAIN then
            self:chain()
        end
        return CHyperImpl.handleTap(self, e, keyCode, type)
    end,
}
setmetatable(CHyperStickyImpl, {__index = CHyperImpl})

CHyperImpl.sticky = function(self, mode, op)
    if type(mode) == 'string' then
        local case = {once = STICKY_ONCE, toggle = STICKY_TOGGLE, chain = STICKY_CHAIN}
        self.stickyMode = case[mode:lower()]
    end

    if type(self.stickyMode) == 'number' then
        if self._stickyModal == nil then
            self._stickyModal = hs.hotkey.modal.new()
            self._stickyModal:bind({}, 0x35, 0, function() self:exitSticky() end, nil, nil)
        end
        if self.stickyMode == STICKY_CHAIN and type(op) == 'number' then
            self.chainDelay = op
        else
            self.chainDelay = 0.5
        end
        setmetatable(self, {__index = CHyperStickyImpl})
    else
        setmetatable(self, {__index = CHyperImpl})
    end

    return self
end

return CHyper
