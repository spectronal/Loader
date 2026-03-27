local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local VALID_KEYS = {
    ["HUB-KEYLESS"] = true,
}

local KeyWindow = Fluent:CreateWindow({
    Title = "DramaHub",
    SubTitle = "Key System",
    TabWidth = 0,
    Size = UDim2.fromOffset(380, 150),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tab = KeyWindow:AddTab({ Title = "Main", Icon = "" })

Tab:AddInput("KeyInput", {
    Title = "Access Key",
    Placeholder = "DRAMA-XXXX-XXXX-XXXX",
    Default = "",
    Numeric = false,
    Finished = false,
    Callback = function() end,
})

Tab:AddButton({
    Title = "Check Key",
    Description = "Click to validate your key",
    Callback = function()
        local key = Fluent.Options.KeyInput.Value

        if VALID_KEYS[key] then
            Fluent:Notify({
                Title = "DramaHub",
                Content = "Valid key! Loading...",
                Duration = 4,
            })
            task.wait(1.5)
            KeyWindow:Destroy()
            loadstring(game:HttpGet("https://dramahub.up.railway.app/init"))()
        else
            Fluent:Notify({
                Title = "DramaHub",
                Content = "Invalid key!",
                SubContent = "Please check your key and try again.",
                Duration = 4,
            })
        end
    end,
})
