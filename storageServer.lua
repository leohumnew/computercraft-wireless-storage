require "utils"

local verifiedUsers = settings.get("verifiedUsers", {})
local db = {}
local dbIndeces = ""
local inChest = settings.get("inChest", "right")
local outChest = settings.get("outChest", "top")
local pw = settings.get("pw", "")
math.randomseed(os.time())
local secCode = settings.get("secCode", math.random(1000,9999))
local modem = peripheral.find("modem", function(name, modem)
    return modem.isWireless()
end)
local dbChannel = 1511 + os.computerID()
local dbSigninChannel = 1509 - os.computerID()

function setup()
    term.clear()
    term.setCursorPos(1,1)
    print("Enter storage name:")
    os.setComputerLabel(read())
    setPw()
    print("\nEnter In Chest side:")
    inChest = read()
    settings.set("inChest", inChest)
    print("\nEnter Out Chest side:")
    outChest = read()
    settings.set("outChest", outChest)
    settings.set("setupDone", 1)
    term.clear()
end
function setPw()
    print("\nEnter Password:")
    pw = read("*")
    settings.set("pw", pw)
end

function goOnline()
    -- Signup channel
    modem.open(1510)
    modem.open(dbSigninChannel)
    modem.open(dbChannel)
end
function listenModem()
    local event, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
    if channel == dbChannel then
        if unencrypt(message, secCode) == "getdb" then
            modem.transmit(dbChannel, dbChannel, dbIndeces)
        end
    elseif channel == 1510 then
        modem.transmit(1510, dbSigninChannel, os.computerLabel())
    elseif channel == dbSigninChannel then
        if message == "getCode" then
            term.clear()
            term.setCursorPos(1,1)
            print("Signup code: " .. secCode)
            settings.set("secCode", secCode)
            modem.transmit(dbSigninChannel, dbSigninChannel, "ready")
        else
            term.clear()
            if unencrypt(message, secCode) == pw then
                modem.transmit(dbSigninChannel, dbChannel, "success")
            end
        end
    end
end

function scanStorage()
    term.setCursorPos(1,1)
    print("Scanning...")
    storageChests = {peripheral.find("inventory", function(name, modem)
        return name ~= inChest and name ~= outChest
    end)}

    for i=1, #storageChests do
        for slot, item in pairs(storageChests[i].list()) do
            if db[item.name] == nil then
                db[item.name] = {[i]={slot}, ["c"]=item.count}
                dbIndeces = dbIndeces .. " " .. item.name
            else
                db[item.name][i].insert(slot)
                db[item.name]["c"] = db[item.name]["c"] + db[item.count]
            end
        end
    end
    print("Complete!")
end

function search(input)
    --name, amount
end

-- START --
if settings.get("setupDone", 0) == 0 then
    setup()
end
scanStorage()

goOnline()
while true do listenModem() end