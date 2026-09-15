local ProtectionConfig = {
    -- 🔴 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "AlexAndTuPapiOpex",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "OP STEAL AN EGG SCRIPT"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local POS2 = Vector3.new(514.74, 70.57, -365.25)

local DESTINATION_WAIT_TIME = 1.3
local PROMPT_COOLDOWN = 0.15

local Positions = {
    [1] = Vector3.new(586.69, 70.57, -323.43),
    [2] = Vector3.new(744.43, 70.57, -409.91),
    [3] = Vector3.new(953.64, 70.57, -320.68),
    [4] = Vector3.new(1189.46, 70.57, -408.11),
    [5] = Vector3.new(1497.20, 70.57, -311.09),
    [6] = Vector3.new(1879.72, 70.57, -396.42),
    [7] = Vector3.new(2284.08, 70.57, -329.22),
    [8] = Vector3.new(2813.06, 70.57, -397.42),
    [9] = Vector3.new(3392.44, 70.57, -323.93),
    [10] = Vector3.new(4032.04, 70.57, -400.21),
}

local selectedPosition = 2

local active = false
local autoLeft = false

local autoDestination = nil
local autoWaitingForPrompt = false
local autoMovingToPOS2 = false

local recoveringInterruption = false
local waitingForDestination = false

local movementToken = 0

local align = nil
local attachment = nil

local controls = nil
local controlsDisabled = false

local animationDisabled = false

local autoStealConnection = nil
local promptTriggeredConnection = nil

local promptDelays = {}
local promptCooldown = {}

local function getCharacterData()
    local character = player.Character
    if not character then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root then
        return character, humanoid, root
    end
    return nil
end

local function stopAllAnimations()
    if not animationDisabled then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function()
            track:Stop(0)
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if animationDisabled then
            stopAllAnimations()
        end
    end
end)

local function configurePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end
    if promptDelays[prompt] == nil then
        promptDelays[prompt] = prompt.HoldDuration
    end
    if prompt.HoldDuration ~= 0 then
        prompt.HoldDuration = 0
    end
end

local function restorePrompts()
    for prompt, delay in pairs(promptDelays) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = delay
            end)
        end
    end
    table.clear(promptDelays)
    table.clear(promptCooldown)
end

local function getControls()
    if controls then
        return controls
    end
    local success, result = pcall(function()
        local playerScripts = player:WaitForChild("PlayerScripts", 10)
        if not playerScripts then
            return nil
        end
        local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
        if not playerModule then
            return nil
        end
        local module = require(playerModule)
        return module:GetControls()
    end)
    if success and result then
        controls = result
        return result
    end
    return nil
end

local gui = Instance.new("ScreenGui")
gui.Name = "AutoStealGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(210, 178)
frame.Position = UDim2.new(0.5, -105, 0.5, -89)
frame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 15)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 55, 65)
stroke.Thickness = 1
stroke.Transparency = 0.1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 24)
title.Position = UDim2.fromOffset(12, 7)
title.BackgroundTransparency = 1
title.Text = "AUTO STEAL"
title.TextColor3 = Color3.fromRGB(248, 248, 250)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = frame

local creator = Instance.new("TextLabel")
creator.Name = "Creator"
creator.Size = UDim2.new(1, -24, 0, 14)
creator.Position = UDim2.fromOffset(12, 28)
creator.BackgroundTransparency = 1
creator.Text = "BY ALEX"
creator.TextColor3 = Color3.fromRGB(120, 120, 130)
creator.TextSize = 8
creator.Font = Enum.Font.GothamMedium
creator.TextXAlignment = Enum.TextXAlignment.Left
creator.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 16)
status.Position = UDim2.fromOffset(12, 42)
status.BackgroundTransparency = 1
status.Text = "● INACTIVE"
status.TextColor3 = Color3.fromRGB(145, 145, 150)
status.TextSize = 9
status.Font = Enum.Font.GothamMedium
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local button = Instance.new("TextButton")
button.Name = "ManualButton"
button.Size = UDim2.new(1, -24, 0, 34)
button.Position = UDim2.fromOffset(12, 61)
button.BackgroundColor3 = Color3.fromRGB(29, 29, 35)
button.BorderSizePixel = 0
button.Text = "ENABLE"
button.TextColor3 = Color3.fromRGB(235, 235, 238)
button.TextSize = 11
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 9)
buttonCorner.Parent = button

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(55, 55, 65)
buttonStroke.Thickness = 1
buttonStroke.Transparency = 0.15
buttonStroke.Parent = button

local autoButton = Instance.new("TextButton")
autoButton.Name = "AutoButton"
autoButton.Size = UDim2.new(1, -24, 0, 34)
autoButton.Position = UDim2.fromOffset(12, 101)
autoButton.BackgroundColor3 = Color3.fromRGB(29, 29, 35)
autoButton.BorderSizePixel = 0
autoButton.Text = "AUTO STEAL: OFF"
autoButton.TextColor3 = Color3.fromRGB(235, 235, 238)
autoButton.TextSize = 10
autoButton.Font = Enum.Font.GothamBold
autoButton.AutoButtonColor = false
autoButton.Parent = frame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 9)
autoCorner.Parent = autoButton

local autoStroke = Instance.new("UIStroke")
autoStroke.Color = Color3.fromRGB(55, 55, 65)
autoStroke.Thickness = 1
autoStroke.Transparency = 0.15
autoStroke.Parent = autoButton

local positionButton = Instance.new("TextButton")
positionButton.Name = "PositionSelector"
positionButton.Size = UDim2.new(1, -24, 0, 30)
positionButton.Position = UDim2.fromOffset(12, 141)
positionButton.BackgroundColor3 = Color3.fromRGB(23, 23, 29)
positionButton.BorderSizePixel = 0
positionButton.Text = ""
positionButton.AutoButtonColor = false
positionButton.Parent = frame

local positionCorner = Instance.new("UICorner")
positionCorner.CornerRadius = UDim.new(0, 9)
positionCorner.Parent = positionButton

local positionStroke = Instance.new("UIStroke")
positionStroke.Color = Color3.fromRGB(55, 55, 65)
positionStroke.Thickness = 1
positionStroke.Transparency = 0.1
positionStroke.Parent = positionButton

local positionText = Instance.new("TextLabel")
positionText.Size = UDim2.new(1, -42, 1, 0)
position.Position = UDim2.fromOffset(12, 0)
positionText.BackgroundTransparency = 1
positionText.Text = "POSITION 2"
positionText.TextColor3 = Color3.fromRGB(225, 225, 230)
positionText.TextSize = 10
positionText.Font = Enum.Font.GothamBold
positionText.TextXAlignment = Enum.TextXAlignment.Left
positionText.Parent = positionButton

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(25, 30)
arrow.Position = UDim2.new(1, -30, 0, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "⌄"
arrow.TextColor3 = Color3.fromRGB(150, 150, 160)
arrow.TextSize = 15
arrow.Font = Enum.Font.GothamBold
arrow.Parent = positionButton

local positionList = Instance.new("ScrollingFrame")
positionList.Name = "PositionList"
positionList.Size = UDim2.new(1, -24, 0, 0)
positionList.Position = UDim2.fromOffset(12, 174)
positionList.BackgroundColor3 = Color3.fromRGB(19, 19, 24)
positionList.BorderSizePixel = 0
positionList.Visible = false
positionList.ZIndex = 50
positionList.ClipsDescendants = true
positionList.CanvasSize = UDim2.fromOffset(0, 0)
positionList.ScrollBarThickness = 3
positionList.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
positionList.ScrollingDirection = Enum.ScrollingDirection.Y
positionList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
positionList.Parent = frame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 10)
listCorner.Parent = positionList

local listStroke = Instance.new("UIStroke")
listStroke.Color = Color3.fromRGB(55, 55, 65)
listStroke.Thickness = 1
listStroke.Parent = positionList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = positionList

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.Parent = positionList

local positionOptions = {}

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    positionList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 12)
end)

local function updatePositions()
    for i = 1, 10 do
        local option = positionOptions[i]
        if option then
            local label = option:FindFirstChild("Label")
            if i == selectedPosition then
                option.BackgroundColor3 = Color3.fromRGB(38, 65, 47)
                if label then
                    label.TextColor3 = Color3.fromRGB(105, 235, 135)
                end
            else
                option.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
                if label then
                    label.TextColor3 = Color3.fromRGB(205, 205, 212)
                end
            end
        end
    end
end

for i = 1, 10 do
    local option = Instance.new("TextButton")
    option.Name = "Position" .. i
    option.LayoutOrder = i
    option.Size = UDim2.new(1, -12, 0, 27)
    option.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
    option.BorderSizePixel = 0
    option. = ""
    option.AutoButtonColor = false
    option.ZIndex = 51
    option.Parent = positionList

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = option

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = "POSITION" .. i
    label.TextColor3 = Color3.fromRGB(205, 205, 212)
    label.TextSize = 9
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 52
    label.Parent = option

    positionOptions[i] = option

    option.Activated:Connect(function()
        selectedPosition = i
        positionText.Text = "POSITION" .. i
        positionList.Visible = false
        positionList.Size = UDim2.new(1, -24, 0, 0)
        positionList.CanvasPosition = Vector2.new(0, 0)
        arrow.Text = "⌄"
        updatePositions()
    end)
end

updatePositions()

local listOpen = false

positionButton.Activated:Connect(function()
    listOpen = not listOpen
    positionList.Visible = listOpen
    if listOpen then
        positionList.Size = UDim2.new(1, -24, 0, 120)
        positionList.CanvasPosition = Vector2.new(0, 0)
        arrow.Text = "⌃"
    else
        positionList.Size = UDim2.new(1, -24, 0, 0)
        arrow.Text = "⌄"
    end
end)

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

local function removeOrientation()
    if align then
        align:Destroy()
        align = nil
    end
    if attachment then
        attachment:Destroy()
        attachment = nil
    end
    local _, humanoid = getCharacterData()
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function disableControls()
    if controlsDisabled then
        return
    end
    local ctrl = getControls()
    if ctrl then
        local success = pcall(function()
            ctrl:Disable()
        end)
        if success then
            controlsDisabled = true
        end
    end
end

local function enableControls()
    if not controlsDisabled then
        return
    end
    local ctrl = getControls()
    if ctrl then
        pcall(function()
            ctrl:Enable()
        end)
    end
    controlsDisabled = false
end

local function blockWASD()
    local function blockMovement()
        return Enum.ContextActionResult.Sink
    end
    ContextActionService:BindAction(
        "AutoStealBlockMovement",
        blockMovement,
        false,
        Enum.KeyCode.W,
        Enum.KeyCode.A,
        Enum.KeyCode.S,
        Enum.KeyCode.D
    )
end

local function unblockWASD()
    ContextActionService:UnbindAction("AutoStealBlockMovement")
end

local function updateUI(inactive)
    if inactive then
        button.Text = "ENABLE"
        button.BackgroundColor3 = Color3.fromRGB(29, 29, 35)
        status.Text = "● INACTIVE"
        status.TextColor3 = Color3.fromRGB(145, 145, 150)
    else
        button.Text = "DISABLE"
        button.BackgroundColor3 = Color3.fromRGB(38, 90, 52)
        status.Text = "● ACTIVE"
        status.TextColor3 = Color3.fromRGB(90, 220, 115)
    end
end

local function isMovementInterrupted(humanoid)
    if not humanoid or not humanoid.Parent then
        return true
    end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.PlatformStanding
        or state == Enum.HumanoidStateType.Seated
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.Dead then
        return true
    end
    return false
end

local function getPromptPosition(prompt)
    if not prompt or not prompt.Parent then
        return nil
    end
    local parent = prompt.Parent
    if parent:IsA("BasePart") then
        return parent.Position
    end
    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    if parent:IsA("Model") then
        local part = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position
        end
    end
    local part = parent:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end
    return nil
end

local function findNearestPrompt(position)
    local nearest = nil
    local shortestDistance = math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local promptPosition = getPromptPosition(obj)
            if promptPosition then
                local distance = (promptPosition - position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = obj
                end
            end
        end
    end
    return nearest, shortestDistance
end

local recoverInterruption

local function startMovement(destination)
    local character, humanoid, root = getCharacterData()
    if not character or not humanoid or not root then
        return false
    end
    removeOrientation()
    disableControls()
    humanoid.AutoRotate = false
    humanoid.Jump = false

    attachment = Instance.new("Attachment")
    attachment.Name = "AutoStealDirectionAttachment"
    attachment.Parent = root

    align = Instance.new("AlignOrientation")
    align.Name = "ForceAutoStealDirection"
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.RigidityEnabled = true
    align.Responsiveness = 200
    align.MaxTorque = math.huge
    align.Parent = root

    local forward = root.CFrame.LookVector
    local left = Vector3.new(forward.Z, 0, -forward.X)
    if left.Magnitude > 0 then
        left = left.Unit
        align.CFrame = CFrame.lookAt(Vector3.zero, left)
    end

    movementToken += 1
    local myToken = movementToken

    task.spawn(function()
        while active and myToken == movementToken do
            if not humanoid.Parent or not root.Parent then
                break
            end
            stopAllAnimations()

            if isMovementInterrupted(humanoid) then
                local interruptionPoint = root.Position
                humanoid:Move(Vector3.zero, true)
                humanoid.Jump = false
                movementToken += 1
                removeOrientation()
                enableControls()
                if autoLeft and active then
                    recoverInterruption(interruptionPoint)
                end
                break
            end

            humanoid.Jump = false
            local distance = (root.Position - destination).Magnitude
            if distance <= 3 then
                humanoid:Move(Vector3.zero, true)
                stopAllAnimations()
                removeOrientation()
                enableControls()
                break
            end

            if not controlsDisabled then
                disableControls()
            end
            humanoid:MoveTo(destination)
            task.wait(0.05)
        end
    end)
    return true
end

recoverInterruption = function(position)
    if not active or not autoLeft then
        return
    end
    if recoveringInterruption then
        return
    end
    recoveringInterruption = true
    movementToken += 1
    removeOrientation()
    enableControls()

    local prompt = findNearestPrompt(position)
    if not prompt then
        recoveringInterruption = false
        return
    end

    local promptDestination = getPromptPosition(prompt)
    if not promptDestination then
        recoveringInterruption = false
        return
    end

    autoDestination = promptDestination
    autoWaitingForPrompt = true
    autoMovingToPOS2 = false
    recoveringInterruption = false

    startMovement(promptDestination)
end

local function goToSelectedPosition()
    if not autoLeft then
        return
    end
    local destination = Positions[selectedPosition]
    autoDestination = destination
    autoWaitingForPrompt = true
    autoMovingToPOS2 = false
    startMovement(destination)
end

local function goToPOS2Auto()
    if not autoLeft then
        return
    end
    autoDestination = POS2
    autoWaitingForPrompt = false
    autoMovingToPOS2 = true
    startMovement(POS2)
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if not autoLeft or not active then
            continue
        end
        local _, humanoid, root = getCharacterData()
        if not humanoid or not root then
            continue
        end
        stopAllAnimations()

        if isMovementInterrupted(humanoid) then
            if autoDestination and not recoveringInterruption then
                recoverInterruption(root.Position)
            end
            continue
        end

        if not autoDestination then
            continue
        end
        if waitingForDestination then
            continue
        end

        local distance = (root.Position - autoDestination).Magnitude
        if distance <= 3 then
            local wasPosition = autoWaitingForPrompt
            local wasPOS2 = autoMovingToPOS2
            autoDestination = nil
            movementToken += 1
            humanoid:Move(Vector3.zero, true)
            humanoid.Jump = false
            stopAllAnimations()
            removeOrientation()
            enableControls()

            waitingForDestination = true
            task.wait(DESTINATION_WAIT_TIME)
            waitingForDestination = false

            if not autoLeft or not active then
                continue
            end

            local _, newHumanoid, newRoot = getCharacterData()
            if not newHumanoid or not newRoot then
                continue
            end
            stopAllAnimations()

            if isMovementInterrupted(newHumanoid) then
                recoverInterruption(newRoot.Position)
                continue
            end

            if wasPosition then
                autoWaitingForPrompt = false
                autoMovingToPOS2 = true
                goToPOS2Auto()
            elseif wasPOS2 then
                autoMovingToPOS2 = false
                autoWaitingForPrompt = true
                goToSelectedPosition()
            end
        end
    end
end)

local function enableScript()
    if active then
        return
    end
    animationDisabled = true
    active = true
    autoDestination = nil
    autoWaitingForPrompt = false
    autoMovingToPOS2 = false
    blockWASD()
    updateUI(false)
    stopAllAnimations()
    startMovement(POS2)
end

local function stopAutoSteal()
    if autoStealConnection then
        autoStealConnection:Disconnect()
        autoStealConnection = nil
    end
    restorePrompts()
end

local function disableScript()
    active = false
    autoDestination = nil
    autoWaitingForPrompt = false
    autoMovingToPOS2 = false
    recoveringInterruption = false
    waitingForDestination = false
    movementToken += 1
    unblockWASD()
    enableControls()
    removeOrientation()
    stopAllAnimations()
    updateUI(true)
end

promptTriggeredConnection = ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer and triggeringPlayer ~= player then
        return
    end
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end
    if autoLeft then
        if active and autoWaitingForPrompt then
            goToPOS2Auto()
        end
        return
    end
    enableScript()
end)

button.Activated:Connect(function()
    if active then
        disableScript()
        return
    end
    enableScript()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.R then
        if active then
            autoLeft = false
            stopAutoSteal()
            disableScript()
            autoButton.Text = "AUTO STEAL: OFF"
            autoButton.BackgroundColor3 = Color3.fromRGB(29, 29, 35)
        end
    end
end)

autoButton.Activated:Connect(function()
    autoLeft = not autoLeft
    if autoLeft then
        animationDisabled = true
        autoButton.Text = "AUTO STEAL: ON"
        autoButton.BackgroundColor3 = Color3.fromRGB(38, 90, 52)
        autoStealConnection = ProximityPromptService.PromptShown:Connect(function(prompt)
            if not autoLeft then
                return
            end
            if not prompt or not prompt:IsA("ProximityPrompt") then
                return
            end
            if not prompt.Enabled then
                return
            end
            configurePrompt(prompt)
            local now = os.clock()
            local last = promptCooldown[prompt]
            if last and (now - last) < PROMPT_COOLDOWN then
                return
            end
            promptCooldown[prompt] = now
            task.defer(function()
                if not autoLeft then
                    return
                end
                if not prompt.Parent then
                    return
                end
                if not prompt.Enabled then
                    return
                end
                if typeof(fireproximityprompt) == "function" then
                    pcall(function()
                        fireproximityprompt(prompt, 1, true)
                    end)
                end
            end)
        end)
        if not active then
            active = true
            blockWASD()
            updateUI(false)
            stopAllAnimations()
            goToSelectedPosition()
        end
    else
        autoButton.Text = "AUTO STEAL: OFF"
        autoButton.BackgroundColor3 = Color3.fromRGB(29, 29, 35)
        stopAutoSteal()
        if active then
            disableScript()
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    movementToken += 1
    unblockWASD()
    enableControls()
    removeOrientation()
    active = false
    autoDestination = nil
    autoWaitingForPrompt = false
    autoMovingToPOS2 = false
    recoveringInterruption = false
    waitingForDestination = false
    updateUI(true)
    task.wait(1)
    if not character.Parent then
        return
    end
    if animationDisabled then
        stopAllAnimations()
    end
end)

player.CharacterRemoving:Connect(function()
    movementToken += 1
    unblockWASD()
    enableControls()
    removeOrientation()
end)
