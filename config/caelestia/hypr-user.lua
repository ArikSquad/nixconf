hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "DP-3",
    mode = "preferred",
    position = "2560x0",
    scale = 1,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "6000x0",
    scale = 1,
})

-- default picker is feature-rich but slow to appear. These bindings use
-- hyprshot directly while retaining both automatic saving and clipboard copy.
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -m active"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("screenshot-select"))
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + SHIFT + G", hl.dsp.global("caelestia:gameMode"))

hl.config({
    input = {
        kb_layout  = "fi,ru",
        kb_variant = ",phonetic",
        kb_options = "grp:alt_shift_toggle",
    },
})

-- Island geometry animates in QML. Keep compositor animation from fighting it.
-- Blur is confined to these small translucent surfaces, never the full screen.
hl.layer_rule({
    match = { namespace = "caelestia-(island(-launcher)?|active-pill)" },
    blur = true,
    ignore_alpha = 0.2,
    no_anim = true,
})

-- Detect a modifier-only Super tap in the compositor's raw key stream. A
-- normal press binding fires before Hyprland knows whether a second key will
-- follow, while a global release binding is unreliable for modifier keys.
local launcherShortcut = hl.dsp.global("caelestia:launcher")
-- XKB keycodes are stable here: Super_L=133 and Super_R=134 (the evdev
-- codes plus XKB's eight-key offset).
local superKeycodes = { [133] = true, [134] = true }
local superDown = {}
local launcherCandidate = false
local launcherInterrupted = false

hl.on("input.keyboard.key", function(keycode, _, state)
    if superKeycodes[keycode] then
        if state == 1 then
            -- Pressing both Super keys is a combination, not a tap.
            if superDown[133] or superDown[134] then
                launcherInterrupted = true
            end
            superDown[keycode] = true
            launcherCandidate = true
        elseif state == 0 then
            superDown[keycode] = nil

            -- Only the release of the final Super key completes the gesture.
            if not superDown[133] and not superDown[134] then
                if launcherCandidate and not launcherInterrupted then
                    hl.dispatch(launcherShortcut)
                end
                launcherCandidate = false
                launcherInterrupted = false
            end
        end
    elseif (state == 1 or state == 2)
        and (superDown[133] or superDown[134]) then
        -- Any other key turns the Super tap into a normal combination.
        launcherInterrupted = true
    end
end)
