-- Služby
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Cesta k RemoteEvent
local remoteEventPath = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("Event")

-- Funkce pro spuštění minihry
function StartRobotClawInsane()
    if not remoteEventPath or not remoteEventPath:IsA("RemoteEvent") then
        warn("RemoteEvent pro spuštění minihry nebyl nalezen nebo není RemoteEvent!")
        return
    end
    local args = {
        [1] = "StartMinigame",
        [2] = "Robot Claw",
        [3] = "Insane"
    }
    print("Spouštím minihru Robot Claw (Insane)...")
    remoteEventPath:FireServer(unpack(args))
end

-- Funkce pro sebrání předmětu
function GrabItem(itemId)
    if not remoteEventPath or not remoteEventPath:IsA("RemoteEvent") then
        warn("RemoteEvent pro sebrání itemu nebyl nalezen nebo není RemoteEvent!")
        return
    end
    local args = {
        "GrabMinigameItem",
        itemId
    }
    -- print("Pokouším se sebrat předmět s ID:", itemId) -- Odkomentuj pro detailní logování
    remoteEventPath:FireServer(unpack(args))
end

-- Funkce pro nalezení všech IDček předmětů v minihře
function FindAllItemIDs()
    local itemIDs = {}
    print("Hledám IDčka předmětů...")

    local chunkerFolder = Workspace:FindFirstChild("Rendered")
    if chunkerFolder then
        chunkerFolder = chunkerFolder:FindFirstChild("Chunker")
    end

    if chunkerFolder then
        print("Prohledávám složku: " .. chunkerFolder:GetFullName())
        for _, itemInstance in ipairs(chunkerFolder:GetChildren()) do
            -- Předpokládáme, že jméno instance je ID ve formátu GUID
            -- GUID má typicky 36 znaků včetně pomlček: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
            if string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-") then
                -- Můžeme přidat přesnější kontrolu regexem, pokud by tam byly i jiné 36 znakové názvy
                -- Prozatím toto stačí
                print("Nalezen potenciální item s ID (Name):", itemInstance.Name)
                table.insert(itemIDs, itemInstance.Name)
            else
                -- print("Instance '" .. itemInstance.Name .. "' neodpovídá formátu ID, ignoruji.")
            end
        end
    else
        warn("Složka 'Workspace.Rendered.Chunker' nenalezena! Předměty nelze najít.")
    end

    if #itemIDs == 0 then
        warn("Nenalezena žádná IDčka předmětů! Ověř, zda jsou itemy v 'Workspace.Rendered.Chunker' a zda jejich jména odpovídají GUID formátu.")
    end
    
    print("Nalezeno celkem ".. #itemIDs .." IDček.")
    return itemIDs
end


-- Hlavní logika skriptu
function Main()
    print("Ověřuji RemoteEvent...")
    if not remoteEventPath or not remoteEventPath:IsA("RemoteEvent") then
         warn("Kritická chyba: RemoteEvent na cestě k '...Shared.Framework.Network.Remote.Event' nebyl nalezen nebo není RemoteEvent! Skript nemůže pokračovat.")
         return
    end
    print("RemoteEvent nalezen.")

    StartRobotClawInsane()

    print("Čekám 7 sekund, aby se minihra a předměty načetly...") -- Uprav podle potřeby, může být potřeba déle
    wait(7) 
    -- Je možné, že itemy se generují postupně, nebo až po nějaké akci v minihře.
    -- Pokud wait(7) nestačí, zkus delší čas, nebo sleduj, kdy se objeví první item ve složce Chunker.

    local itemIDsToCollect = FindAllItemIDs()

    if #itemIDsToCollect > 0 then
        print("Začínám sbírat předměty...")
        for i, itemID in ipairs(itemIDsToCollect) do
            print("Sbírám předmět " .. i .. "/" .. #itemIDsToCollect .. ": " .. itemID)
            GrabItem(itemID)
            wait(0.1) -- Požadovaná prodleva
        end
        print("Všechny nalezené předměty byly sebrány (nebo byl odeslán pokus o sebrání).")
    else
        print("Nebyly nalezeny žádné předměty k sebrání. Zkontroluj konzoli pro případné varování.")
    end
end

-- === Spuštění skriptu ===
-- Pro spuštění v exploitu bys měl mít tlačítko nebo příkaz, který zavolá Main()
-- nebo pokud je skript již v executoru, můžeš zavolat:
-- Main()
-- nebo bezpečněji přes spawn, aby neblokoval hlavní thread exploitu:
-- task.spawn(Main)

print("Skript pro sběr itemů v Robot Claw načten. Zavolej Main() nebo task.spawn(Main) pro spuštění.")

-- Příklad, jak to můžeš chtít spustit automaticky po injectu (pokud to tvůj exploit umožňuje a je to žádoucí)
-- _G.RunRobotClawCollector = Main -- Uložíš si funkci globálně
-- A pak v konzoli exploitu napíšeš: RunRobotClawCollector()
-- Nebo rovnou:
-- task.spawn(Main)