-- When assigning this action as a shortcut, it's best to set the "Scope" to
-- global. This way toggle visibility will work irrespective of focus.

-- TODO:
--  Handle case when FX chain is open
--  Handle case when FX chain and track effects are both open (save FX chain first)
--  Make it so z-order of FX windows reloads right

local using_reaper = reaper ~= nil
local current_project = reaper.EnumProjects(-1, "")

local display = nil
if using_reaper then
    display = function(x)
        reaper.ShowConsoleMsg(x .. "\n")
    end
else
    display = function(x)
        print(x .. "\n")
    end
end

function file_exists(path)
    f = io.open(path, "r")
    if f == nil then
        return false
    else
        f:close()
        return true
    end
end

function clear(path)
    file = io.open(path, "w")
    file:close()
end

function check_fx_open()
    return table_length(get_fx_open()) > 0
end

function table_length(table)
    local c = 0
    for _ in pairs(table) do
        c = c + 1
    end
    return c
end

function print_fxs(fxs)
    for guid, fx_set in pairs(fxs) do
        for fx_idx, _ in pairs(fx_set) do
            display(guid .. " " .. fx_idx)
        end
    end
end

function print_fx_chains(fx_chains)
    for guid, _ in pairs(fx_chains) do
        display(guid)
    end
end

-- This needs to be refactored
-- Also redesigned as `FXs` is not very efficient
function get_fx_open()
    local fxs = {}
    for iTrack = 0, reaper.GetNumTracks(current_project) - 1 do
        local track = reaper.GetTrack(current_project, iTrack)
        local fxCount = reaper.TrackFX_GetCount(track)
        local first = true
        for iFx = 0, fxCount - 1 do
            if reaper.TrackFX_GetOpen(track, iFx) then
                if first then
                    fxs[reaper.GetTrackGUID(track)] = {}
                    first = false
                end
                fxs[reaper.GetTrackGUID(track)][iFx] = 0
            end
        end
    end
    return fxs
end

function save_track_fx(fxs, path)
    local file = io.open(path, "w")
    for guid, data in pairs(fxs) do
        for iFx, _ in pairs(data) do
            file:write(guid .. "," .. iFx .. "\n")
        end
    end
    file:close()
end

function load_track_fx(path)
    local file = io.open(path, "r")
    guids = get_track_guids()
    for line in file:lines() do
        guid, iFx = line:match("([^,]*),([^,]*)")
        if guids[guid] ~= nil then
            local track = reaper.BR_GetMediaTrackByGUID(current_project, guid)
            reaper.TrackFX_SetOpen(track, iFx, true)
        end
    end
    file:close()
end

function get_track_guids()
    local guids = {}
    for iTrack = 0, reaper.GetNumTracks(current_project) - 1 do
        local track = reaper.GetTrack(current_project, iTrack)
        guids[reaper.GetTrackGUID(track)] = 0
    end
    return guids
end

function close_fx(fxs)
    for guid, data in pairs(fxs) do
        for iFx, _ in pairs(data) do
            local track = reaper.BR_GetMediaTrackByGUID(current_project, guid)
            reaper.TrackFX_SetOpen(track, iFx, false)
        end
    end
end

function check_fx_chain_open()
    return false
end

-- Assume single effect chain for now
function get_fx_chain_open()
    local chains = {}
    for iTrack = 0, reaper.GetNumTracks(current_project) - 1 do
        local track = reaper.GetTrack(current_project, iTrack)
        local visible = reaper.TrackFX_GetChainVisible(track) >= 0 or
                        reaper.TrackFX_GetChainVisible(track) == -2
        if visible then
            chains[reaper.GetTrackGUID(track)] = 0
        end
    end
    return chains
end

function save_track_fx_chain(fx_chain, path)
end

function close_fx_chain(fxs)
end

function load_track_fx_chain(fx_chain_path)
end

function main()
    local fx_path = reaper.GetResourcePath() .. "/Scripts/Numu Scripts/fx_state.txt"
    local fx_chain_path = reaper.GetResourcePath() .. "/Scripts/Numu Scripts/fx_chain_state.txt"

    if check_fx_open() or check_fx_chain_open() then
        local fx_chain = get_fx_chain_open()
        local fxs = get_fx_open()

        save_track_fx_chain(fx_chain, fx_chain_path)
        save_track_fx(fxs, fx_path)

        close_fx_chain(fx_chain)
        close_fx(fxs)
    else
        if file_exists(fx_chain_path) then load_track_fx_chain(fx_chain_path) end
        if file_exists(fx_path)       then load_track_fx(fx_path) end

        clear(fx_chain_path)
        clear(fx_path)
    end
end

main()
