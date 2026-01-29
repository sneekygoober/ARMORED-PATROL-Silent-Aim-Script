local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "Your executor";

if not (hookfunction and (filtergc or getgc) and restorefunction and require) then
    return error(executor .. " is missing " .. (not hookfunction and "hookfunction " or "") .. (not (filtergc and getgc) and "filtergc getgc " or "") .. (not restorefunction and "restorefunction " or "") .. (not require and "require" or ""));
end;

local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"));
local Players = game:GetService("Players");

local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;

local h = plr.Character and plr.Character:WaitForChild("Humanoid", 5);

plr.CharacterAdded:Connect(function(char: Model)
    h = char:WaitForChild("Humanoid", 5);
end);

local mouse = plr:GetMouse();

local filter = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-filtergc/refs/heads/main/main.luau"))();

local getScripts = function(char: Model): (LocalScript?, LocalScript?)
    local rifle = "LocalScript[Name = \"LsTlRifle\"]";
    local rpg = "LocalScript[Name = \"LsTlRpg\"]";
    local _ = function(_: string): LocalScript?
        return ({unpack(plr.Backpack:QueryDescendants(_)), unpack(char:QueryDescendants(_))})[1];
    end;

    return _(rifle), _(rpg);
end;

local getTarget = function(): BasePart
    local cPart, cDistance = nil, 100;

    for _, player: Player in next, Players:GetChildren() do
        if player == plr or player.Team == plr.Team then continue; end;

        local char = player.Character;
        if not char or char:FindFirstChildOfClass("ForceField") then continue; end;

        local tPart: BasePart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart");
        if not tPart then continue; end;

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position);
        if not onScreen then continue; end;

        local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude;
        if distance < cDistance then
            cPart = tPart;
            cDistance = distance;
        end;
    end;

    return cPart;
end;

local hook = function(f: (any, any?, Vector3?) -> () | boolean)
    if not f then return; end;
    local old; old = clonefunction(hookfunction(f, newcclosure(function(_, __, pos)
        local c = getTarget();
        if c and pos then
            return old(_, __, c.Position);
        end;

        return old(_, __, pos);
    end)));
end;

local setup = function(char: Model)
    task.wait(3);

    local rifle, rpg = getScripts(char);

    if rifle then hook(filter(rifle, "pcall", "FireServer", "print", "script", "Name", ":ToolSvcsSend; failed to send ")); end;
    if rpg then hook(filter(rpg, "pcall", "FireServer", "print", "script", "Name", ":ToolSvcsSend; failed to send ")); end;

    print("Set up!");
end;

plr.CharacterAdded:Connect(setup);

setup(plr.Character or plr.CharacterAdded:Wait());
