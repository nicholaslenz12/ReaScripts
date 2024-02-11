-- When assigning this action as a shortcut, it's best to set the "Scope" to
-- global. This way toggle visibility will work irrespective of focus.

-- TODO:
--  Simplify table storing GUID -> FXs
--  Verify GUID invalidations (don't reload effects from tracks that don't exist)
--  Handle case when FX chain is open
--  Handle case when FX chain and track effects are both open (save FX chain first)

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

-- This needs to be refactored
-- Also redesigned as `FXs` is not very efficient
function get_fx_open()
    local FXs = {}
    for iTrack = 0, reaper.GetNumTracks(current_project) - 1 do
        local track = reaper.GetTrack(current_project, iTrack)
        local fxCount = reaper.TrackFX_GetCount(track)
        local first = true
        for iFx = 0, fxCount - 1 do
            if reaper.TrackFX_GetOpen(track, iFx) then
                if first then
                    FXs[reaper.GetTrackGUID(track)] = {}
                    first = false
                end
                FXs[reaper.GetTrackGUID(track)][iFx] = iTrack
                -- display("    " .. iTrack .. " -> " .. iFx .. "\n")
            end
        end
    end
    return FXs
end

function save_track_fx(fxs, path)
    local file = io.open(path, "w")
    for guid, data in pairs(fxs) do
        for iFx, iTrack in pairs(data) do
            file:write(guid .. "," .. iTrack .. "," .. iFx .. "\n")
        end
    end
    file:close()
end

function load_track_fx(path)
    local file = io.open(path, "r")
    guids = get_track_guids()
    for line in file:lines() do
        guid, iTrack, iFx = line:match("([^,]*),([^,]*),([^,]*)")
        if guids[guid] ~= nil then
            local track = reaper.GetTrack(current_project, iTrack)
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
    for _, data in pairs(fxs) do
        for iFx, iTrack in pairs(data) do
            local track = reaper.GetTrack(current_project, iTrack)
            reaper.TrackFX_SetOpen(track, iFx, false)
        end
    end
end

function main()
    path = reaper.GetResourcePath() .. "/Scripts/Numu Scripts/plug_state.txt"

    if check_fx_open() then
        local fxs = get_fx_open()
        save_track_fx(fxs, path)
        close_fx(fxs)
    else
        if file_exists(path) then load_track_fx(path) end
        clear(path)
    end
end

main()
