--[[
    BAXTARA X CHEAT — ORBITAL GALAXY
    DELTA VISUAL EDITION | Client-side UI only

    This script creates a cosmetic Roblox interface. It does not contain
    gameplay cheats, ESP, aimbot, RemoteEvent manipulation, anti-cheat bypasses,
    or server-side changes.

    Run in Delta while inside a Roblox experience.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[BAXTARA] LocalPlayer tidak tersedia.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GUI_NAME = "BaxtaraOrbitalGalaxy"

local previous = PlayerGui:FindFirstChild(GUI_NAME)
if previous then
    previous:Destroy()
end

local Palette = {
    deep = Color3.fromRGB(5, 7, 19),
    second = Color3.fromRGB(11, 16, 38),
    card = Color3.fromRGB(15, 23, 43),
    violet = Color3.fromRGB(116, 59, 255),
    blue = Color3.fromRGB(40, 123, 255),
    cyan = Color3.fromRGB(57, 231, 255),
    pink = Color3.fromRGB(212, 91, 255),
    white = Color3.fromRGB(234, 243, 255),
    muted = Color3.fromRGB(137, 151, 181),
    disabled = Color3.fromRGB(72, 81, 109),
    green = Color3.fromRGB(69, 226, 190),
}

local ThemeOptions = {
    NEBULA = { accent = Color3.fromRGB(116, 59, 255), secondary = Color3.fromRGB(57, 231, 255) },
    MIDNIGHT = { accent = Color3.fromRGB(40, 123, 255), secondary = Color3.fromRGB(111, 183, 255) },
    AURORA = { accent = Color3.fromRGB(35, 202, 184), secondary = Color3.fromRGB(145, 245, 223) },
}

local state = {
    GalaxyBackground = true,
    StarParticles = true,
    PlanetRotation = true,
    NebulaGlow = true,
    OrbitTrail = true,
    HologramEffect = true,
    AmbientAnimation = true,
    UISound = false,
    ReduceMotion = false,
    GlowIntensity = 0.78,
    AnimationSpeed = 1.0,
    BackgroundOpacity = 0.92,
    ParticleDensity = 0.70,
    OrbitSpeed = 1.0,
    UIScale = 1.0,
    PanelTransparency = 0.08,
    Theme = "NEBULA",
}

local alive = true
local connections = {}
local activeTweens = {}
local orbitTweens = {}
local animatedRings = {}
local starObjects = {}
local nebulaObjects = {}
local effectObjects = {}
local activeSlider = nil
local toggleRefreshers = {}
local themeButtons = {}
local themeButtonStrokes = {}
local selectedPage = "HOME"
local selectPage
local hidePanel
local openedOnce = false
local introFinished = false
local sessionStarted = os.clock()
local cachedFPS = 0
local fpsFrames = 0
local fpsClock = os.clock()
local accent = ThemeOptions[state.Theme].accent
local secondaryAccent = ThemeOptions[state.Theme].secondary

local function keepConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or accent,
        Thickness = thickness or 1,
        Transparency = transparency == nil and 0.35 or transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, colorA, colorB, rotation)
    return make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        }),
        Rotation = rotation or 0,
    }, parent)
end

local function label(parent, text, size, color, font, position, dimensions)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Palette.white,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        ZIndex = (parent.ZIndex or 1) + 1,
        Position = position or UDim2.new(),
        Size = dimensions or UDim2.new(1, 0, 0, 22),
    }, parent)
end

local function playTween(object, duration, properties, style, direction, repeatCount, reverses)
    if not object or not object.Parent then
        return nil
    end
    local info = TweenInfo.new(
        math.max(0.05, duration),
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out,
        repeatCount or 0,
        reverses or false
    )
    local tween = TweenService:Create(object, info, properties)
    table.insert(activeTweens, tween)
    tween.Completed:Connect(function()
        for index, savedTween in ipairs(activeTweens) do
            if savedTween == tween then
                table.remove(activeTweens, index)
                break
            end
        end
    end)
    tween:Play()
    return tween
end

local function cancelTweenList(list)
    for _, tween in ipairs(list) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(list)
end

local function addRing(parent, size, color, transparency, thickness, rotation, skipAnimation)
    local ring = make("Frame", {
        Name = "OrbitRing",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        Rotation = rotation or 0,
        ZIndex = (parent.ZIndex or 1) + 1,
    }, parent)
    corner(ring, 999)
    stroke(ring, color, thickness or 1.2, transparency or 0.25)
    if not skipAnimation then table.insert(animatedRings, ring) end
    return ring
end

local function makePlanet(parent, color, diameter, position, zindex)
    local planet = make("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.fromOffset(diameter, diameter),
        ZIndex = zindex or 4,
    }, parent)
    corner(planet, 999)
    gradient(planet, color:Lerp(Color3.new(1, 1, 1), 0.27), color:Lerp(Color3.new(0, 0, 0), 0.43), 35)
    stroke(planet, color:Lerp(Palette.white, 0.25), 1, 0.35)

    local surface = make("Frame", {
        BackgroundColor3 = color:Lerp(Palette.white, 0.18),
        BackgroundTransparency = 0.60,
        BorderSizePixel = 0,
        Position = UDim2.new(0.12, 0, 0.20, 0),
        Size = UDim2.new(0.48, 0, 0.20, 0),
        Rotation = -28,
        ZIndex = (zindex or 4) + 1,
    }, planet)
    corner(surface, 999)
    return planet
end

local notice, noticeStroke, noticeTextLabel, noticeToken
noticeToken = 0

local function showNotice(message, tint)
    if not alive or not notice then return end
    noticeTextLabel.Text = message
    noticeStroke.Color = tint or accent
    notice.Position = UDim2.new(1, 24, 0, 78)
    notice.Visible = true
    playTween(notice, 0.32, { Position = UDim2.new(1, -14, 0, 78) }, Enum.EasingStyle.Back)
    local token = os.clock()
    noticeToken = token
    task.delay(2.35, function()
        if alive and notice and notice.Parent and noticeToken == token then
            local out = playTween(notice, 0.24, { Position = UDim2.new(1, 24, 0, 78) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if out then
                out.Completed:Wait()
            end
            if alive and notice and notice.Parent and noticeToken == token then
                notice.Visible = false
            end
        end
    end)
end

local function particleBurst(parent, center, tint, amount)
    if not alive or state.ReduceMotion or not state.StarParticles then return end
    amount = math.min(amount or 5, 7)
    for index = 1, amount do
        local dot = make("Frame", {
            BackgroundColor3 = tint or secondaryAccent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = center,
            Size = UDim2.fromOffset(math.random(3, 5), math.random(3, 5)),
            ZIndex = 80,
        }, parent)
        corner(dot, 999)
        local angle = (math.pi * 2 / amount) * index
        local distance = math.random(13, 25)
        local target = UDim2.new(center.X.Scale, center.X.Offset + math.cos(angle) * distance,
            center.Y.Scale, center.Y.Offset + math.sin(angle) * distance)
        local tween = playTween(dot, 0.42, {
            Position = target,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 1),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if tween then
            tween.Completed:Connect(function()
                if dot and dot.Parent then dot:Destroy() end
            end)
        end
    end
end

local function getViewport()
    local camera = workspace.CurrentCamera
    if camera then return camera.ViewportSize end
    return Vector2.new(800, 600)
end

local function calculatePanelSize()
    local viewport = getViewport()
    local scale = math.clamp(state.UIScale or 1, 0.82, 1.12)
    local width = math.min(860, math.max(250, (viewport.X - 24) / scale))
    local height = math.min(585, math.max(260, (viewport.Y - 42) / scale))
    return width, height
end

local screen = make("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = false,
}, PlayerGui)

local rootScale = make("UIScale", { Scale = 1 }, screen)

local panelWidth, panelHeight = calculatePanelSize()
local isCompact = getViewport().X < 560
local navWidth = isCompact and 82 or 142

local main = make("Frame", {
    Name = "OrbitalPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(180, 120),
    BackgroundColor3 = Palette.deep,
    BackgroundTransparency = 0.02,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 10,
}, screen)
rootScale.Parent = main
corner(main, 19)
local mainStroke = stroke(main, accent, 1.4, 0.12)
gradient(main, Color3.fromRGB(12, 16, 43), Color3.fromRGB(4, 7, 18), 28)

local backgroundLayer = make("Frame", {
    Name = "CosmicBackground",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 10,
}, main)

local nebulaColors = {
    { Color3.fromRGB(106, 46, 211), UDim2.new(-0.12, 0, 0.04, 0), UDim2.fromOffset(260, 190) },
    { Color3.fromRGB(25, 103, 188), UDim2.new(0.53, 0, 0.40, 0), UDim2.fromOffset(290, 210) },
    { Color3.fromRGB(155, 53, 181), UDim2.new(0.20, 0, 0.72, 0), UDim2.fromOffset(220, 150) },
}

for index, item in ipairs(nebulaColors) do
    local blob = make("Frame", {
        Name = "NebulaCloud" .. index,
        BackgroundColor3 = item[1],
        BackgroundTransparency = 0.79,
        BorderSizePixel = 0,
        Position = item[2],
        Size = item[3],
        ZIndex = 10,
    }, backgroundLayer)
    corner(blob, 999)
    gradient(blob, item[1], Palette.deep, index * 43)
    table.insert(nebulaObjects, blob)
end

local starLayer = make("Frame", {
    Name = "StarField",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 11,
}, backgroundLayer)

for index = 1, 34 do
    local diameter = math.random(2, 4)
    local star = make("Frame", {
        Name = "Star" .. index,
        BackgroundColor3 = index % 5 == 0 and Palette.cyan or Palette.white,
        BackgroundTransparency = math.random(30, 72) / 100,
        BorderSizePixel = 0,
        Position = UDim2.new(math.random(3, 97) / 100, 0, math.random(4, 96) / 100, 0),
        Size = UDim2.fromOffset(diameter, diameter),
        ZIndex = 11,
    }, starLayer)
    corner(star, 999)
    table.insert(starObjects, star)
end

local scanLine = make("Frame", {
    Name = "HologramLine",
    BackgroundColor3 = secondaryAccent,
    BackgroundTransparency = 0.90,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0.45, 0),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 12,
}, backgroundLayer)

local header = make("Frame", {
    Name = "Header",
    BackgroundColor3 = Color3.fromRGB(9, 14, 34),
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 66),
    ZIndex = 20,
}, main)
local headerLine = make("Frame", {
    BackgroundColor3 = secondaryAccent,
    BackgroundTransparency = 0.60,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 16, 1, -1),
    Size = UDim2.new(1, -32, 0, 1),
    ZIndex = 21,
}, header)

local logoSmall = make("Frame", {
    Name = "BXMiniLogo",
    BackgroundColor3 = Color3.fromRGB(13, 19, 45),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(15, 11),
    Size = UDim2.fromOffset(43, 43),
    ZIndex = 22,
}, header)
corner(logoSmall, 13)
stroke(logoSmall, secondaryAccent, 1.2, 0.18)
label(logoSmall, "BX", 18, Palette.white, Enum.Font.GothamBlack, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)).ZIndex = 25
addRing(logoSmall, 54, accent, 0.20, 1, 15)
addRing(logoSmall, 64, secondaryAccent, 0.62, 1, -20)

label(header, "BAXTARA X CHEAT", 15, Palette.white, Enum.Font.GothamBold,
    UDim2.fromOffset(68, 11), UDim2.new(0.52, -68, 0, 22)).ZIndex = 22
label(header, "ORBITAL GALAXY  /  BEYOND THE UNIVERSE", 8, Palette.muted, Enum.Font.GothamMedium,
    UDim2.fromOffset(69, 34), UDim2.new(0.56, -69, 0, 15)).ZIndex = 22

local clockLabel = label(header, "00:00:00  UTC-LOCAL", 9, secondaryAccent, Enum.Font.Code,
    UDim2.new(1, -166, 0, 16), UDim2.fromOffset(104, 18))
clockLabel.TextXAlignment = Enum.TextXAlignment.Right
clockLabel.ZIndex = 22

local function makeHeaderButton(text, xOffset, tint)
    local button = make("TextButton", {
        Text = text,
        TextColor3 = tint or Palette.white,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(20, 29, 57),
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, xOffset, 0.5, 0),
        Size = UDim2.fromOffset(29, 29),
        ZIndex = 24,
    }, header)
    corner(button, 9)
    stroke(button, tint or accent, 1, 0.52)
    return button
end

local minimizeButton = makeHeaderButton("−", -49, secondaryAccent)
local closeButton = makeHeaderButton("×", -14, Color3.fromRGB(255, 113, 150))

local dragBar = make("Frame", {
    Name = "DragHandle",
    BackgroundTransparency = 1,
    Active = true,
    Position = UDim2.fromOffset(64, 4),
    Size = UDim2.new(1, -165, 1, -8),
    ZIndex = 30,
}, header)

local body = make("Frame", {
    Name = "Body",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 67),
    Size = UDim2.new(1, 0, 1, -94),
    ZIndex = 20,
}, main)

local nav = make("Frame", {
    Name = "PlanetNavigation",
    BackgroundColor3 = Color3.fromRGB(8, 13, 32),
    BackgroundTransparency = 0.33,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(9, 10),
    Size = UDim2.new(0, navWidth, 1, -18),
    ZIndex = 20,
}, body)
corner(nav, 14)
stroke(nav, accent, 1, 0.72)

local navTitle = label(nav, "ORBIT MAP", 8, secondaryAccent, Enum.Font.GothamBold,
    UDim2.new(0, 10, 0, 8), UDim2.new(1, -18, 0, 18))
navTitle.TextXAlignment = Enum.TextXAlignment.Center

local orbitSpine = make("Frame", {
    BackgroundColor3 = secondaryAccent,
    BackgroundTransparency = 0.70,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0, 25, 0, 42),
    Size = UDim2.new(0, 1, 1, -55),
    ZIndex = 21,
}, nav)
gradient(orbitSpine, accent, secondaryAccent, 90)

local navList = make("Frame", {
    Name = "PlanetList",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(4, 34),
    Size = UDim2.new(1, -8, 1, -42),
    ZIndex = 22,
}, nav)
local navLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
}, navList)

local pageHost = make("Frame", {
    Name = "PageHost",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, navWidth + 18, 0, 10),
    Size = UDim2.new(1, -navWidth - 27, 1, -18),
    ZIndex = 22,
}, body)

local footer = make("Frame", {
    Name = "Footer",
    BackgroundColor3 = Color3.fromRGB(7, 11, 27),
    BackgroundTransparency = 0.26,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -27),
    Size = UDim2.new(1, 0, 0, 27),
    ZIndex = 20,
}, main)
local footerText = label(footer, "BX  •  CLIENT VISUAL INTERFACE  •  v1.0.0", 8, Palette.muted,
    Enum.Font.GothamMedium, UDim2.fromOffset(15, 0), UDim2.new(1, -30, 1, 0))
footerText.TextXAlignment = Enum.TextXAlignment.Center

notice = make("Frame", {
    Name = "HologramNotification",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 24, 0, 78),
    Size = UDim2.fromOffset(220, 48),
    BackgroundColor3 = Color3.fromRGB(10, 17, 39),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 90,
}, main)
corner(notice, 12)
noticeStroke = stroke(notice, secondaryAccent, 1, 0.18)
noticeTextLabel = label(notice, "", 10, Palette.white, Enum.Font.GothamBold,
    UDim2.fromOffset(14, 0), UDim2.new(1, -25, 1, 0))
noticeTextLabel.ZIndex = 91

local floatingButton = make("TextButton", {
    Name = "FloatingBXButton",
    Text = "BX",
    TextColor3 = Palette.white,
    TextSize = 17,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(13, 19, 45),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -22, 1, -24),
    Size = UDim2.fromOffset(54, 54),
    Visible = false,
    ZIndex = 100,
}, screen)
corner(floatingButton, 18)
stroke(floatingButton, secondaryAccent, 1.5, 0.12)

local intro = make("Frame", {
    Name = "OrbitalIntro",
    BackgroundColor3 = Palette.deep,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    Visible = true,
    ZIndex = 150,
}, screen)
local introGlow = make("Frame", {
    BackgroundColor3 = Color3.fromRGB(55, 34, 135),
    BackgroundTransparency = 0.80,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.48),
    Size = UDim2.fromOffset(250, 250),
    ZIndex = 151,
}, intro)
corner(introGlow, 999)
gradient(introGlow, Palette.violet, Palette.blue, 60)

local introLogo = make("Frame", {
    Name = "IntroBX",
    BackgroundColor3 = Color3.fromRGB(13, 20, 48),
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.46),
    Size = UDim2.fromOffset(20, 20),
    ZIndex = 155,
}, intro)
corner(introLogo, 999)
stroke(introLogo, secondaryAccent, 1.5, 0.05)
label(introLogo, "BX", 27, Palette.white, Enum.Font.GothamBlack, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)).ZIndex = 158
local introRingA = addRing(introLogo, 92, accent, 0.12, 1.5, 12, true)
local introRingB = addRing(introLogo, 125, secondaryAccent, 0.35, 1.1, -24, true)
local introRingC = addRing(introLogo, 155, Palette.pink, 0.68, 1, 45, true)
local introOrbitTweens = {}

local introPlanet = makePlanet(intro, Palette.blue, 12,
    UDim2.new(0.5, 72, 0.46, -34), 156)
local introTitle = label(intro, "BAXTARA X CHEAT", 20, Palette.white, Enum.Font.GothamBlack,
    UDim2.new(0, 0, 0.64, 0), UDim2.new(1, 0, 0, 30))
introTitle.TextXAlignment = Enum.TextXAlignment.Center
introTitle.TextTransparency = 1
local introSubtitle = label(intro, "ORBITAL GALAXY  •  BEYOND THE UNIVERSE", 9, secondaryAccent,
    Enum.Font.GothamMedium, UDim2.new(0, 0, 0.70, 0), UDim2.new(1, 0, 0, 22))
introSubtitle.TextXAlignment = Enum.TextXAlignment.Center
introSubtitle.TextTransparency = 1
local introStatus = label(intro, "INITIALIZING COSMIC INTERFACE...", 8, Palette.muted,
    Enum.Font.Code, UDim2.new(0, 0, 0.76, 0), UDim2.new(1, 0, 0, 20))
introStatus.TextXAlignment = Enum.TextXAlignment.Center
introStatus.TextTransparency = 1

local skipIntro = make("TextButton", {
    Text = "SKIP  ›",
    TextColor3 = Palette.muted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    BackgroundColor3 = Palette.card,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(72, 28),
    ZIndex = 160,
}, intro)
corner(skipIntro, 9)
stroke(skipIntro, secondaryAccent, 1, 0.65)

local function updatePanelTransparency()
    main.BackgroundTransparency = math.clamp(state.PanelTransparency, 0, 0.45)
    header.BackgroundTransparency = math.clamp(state.PanelTransparency + 0.16, 0.12, 0.70)
    nav.BackgroundTransparency = math.clamp(state.PanelTransparency + 0.25, 0.18, 0.78)
    footer.BackgroundTransparency = math.clamp(state.PanelTransparency + 0.18, 0.12, 0.72)
end

local function refreshOrbitAnimations()
    cancelTweenList(orbitTweens)
    if not alive or state.ReduceMotion or not state.PlanetRotation or not state.AmbientAnimation or not state.OrbitTrail then
        return
    end
    local speed = math.max(0.25, state.OrbitSpeed * state.AnimationSpeed)
    for index, ring in ipairs(animatedRings) do
        if ring and ring.Parent then
            local duration = (22 + index * 6) / speed
            local tween = TweenService:Create(ring,
                TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
                { Rotation = ring.Rotation + 360 })
            table.insert(orbitTweens, tween)
            tween:Play()
        end
    end
end

local function applyVisualSettings()
    if not alive then return end
    backgroundLayer.Visible = state.GalaxyBackground
    starLayer.Visible = state.StarParticles
    scanLine.Visible = state.HologramEffect

    for index, blob in ipairs(nebulaObjects) do
        blob.Visible = state.NebulaGlow
        blob.BackgroundTransparency = math.clamp(0.99 - (state.BackgroundOpacity * 0.10) - (state.GlowIntensity * 0.12), 0.72, 0.99)
    end

    local visibleStars = math.floor(#starObjects * state.ParticleDensity)
    for index, star in ipairs(starObjects) do
        star.Visible = index <= visibleStars
    end

    local strokeTransparency = 0.78 - (state.GlowIntensity * 0.58)
    mainStroke.Transparency = math.clamp(strokeTransparency, 0.12, 0.80)
    noticeStroke.Transparency = math.clamp(strokeTransparency, 0.12, 0.80)
    updatePanelTransparency()
    rootScale.Scale = state.UIScale
end

local pages = {}

local function createPage(name)
    local page = make("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = secondaryAccent,
        Visible = false,
        ZIndex = 23,
    }, pageHost)
    local padding = make("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
    }, page)
    local layout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }, page)
    pages[name] = page
    return page
end

local function createCard(parent, height, name)
    local card = make("Frame", {
        Name = name or "HologramCard",
        BackgroundColor3 = Palette.card,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, height),
        ZIndex = 24,
    }, parent)
    corner(card, 14)
    local cardStroke = stroke(card, accent, 1, 0.66)
    gradient(card, Color3.fromRGB(21, 29, 62), Color3.fromRGB(10, 16, 35), 18)
    table.insert(effectObjects, { object = cardStroke, base = 0.66 })
    return card
end

local function sectionTitle(parent, titleText, subtitleText)
    local wrapper = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 0, subtitleText and 49 or 29),
        ZIndex = 24,
    }, parent)
    label(wrapper, titleText, 17, Palette.white, Enum.Font.GothamBold,
        UDim2.fromOffset(2, 0), UDim2.new(1, -4, 0, 25))
    if subtitleText then
        label(wrapper, subtitleText, 9, Palette.muted, Enum.Font.Gotham,
            UDim2.fromOffset(3, 25), UDim2.new(1, -6, 0, 18))
    end
    return wrapper
end

local function createActionButton(parent, text, callback, tint)
    local button = make("TextButton", {
        Text = text,
        TextColor3 = Palette.white,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(24, 32, 69),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 39),
        ZIndex = 26,
    }, parent)
    corner(button, 11)
    local buttonStroke = stroke(button, tint or accent, 1, 0.38)
    gradient(button, (tint or accent):Lerp(Palette.deep, 0.40), Color3.fromRGB(12, 19, 43), 0)
    button.MouseEnter:Connect(function()
        if alive then
            playTween(button, 0.16, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad)
            buttonStroke.Transparency = 0.12
        end
    end)
    button.MouseLeave:Connect(function()
        if alive then
            playTween(button, 0.16, { BackgroundTransparency = 0.05 }, Enum.EasingStyle.Quad)
            buttonStroke.Transparency = 0.38
        end
    end)
    button.Activated:Connect(function()
        if not alive then return end
        playTween(button, 0.08, { Size = UDim2.new(1, -9, 0, 37) }, Enum.EasingStyle.Quad)
        task.delay(0.09, function()
            if alive and button.Parent then
                playTween(button, 0.12, { Size = UDim2.new(1, -4, 0, 39) }, Enum.EasingStyle.Back)
            end
        end)
        if callback then callback() end
    end)
    return button
end

local function addToggle(parent, titleText, description, key, tint)
    local row = make("Frame", {
        Name = key .. "ToggleRow",
        BackgroundColor3 = Color3.fromRGB(14, 21, 45),
        BackgroundTransparency = 0.30,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 64),
        ZIndex = 25,
    }, parent)
    corner(row, 12)
    stroke(row, tint or secondaryAccent, 1, 0.82)
    label(row, titleText, 10, Palette.white, Enum.Font.GothamBold,
        UDim2.fromOffset(12, 9), UDim2.new(1, -116, 0, 19))
    label(row, description or "Visual interface setting", 8, Palette.muted, Enum.Font.Gotham,
        UDim2.fromOffset(12, 30), UDim2.new(1, -116, 0, 20))

    local track = make("TextButton", {
        Name = "GalaxyEnergySwitch",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(26, 34, 61),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, -1),
        Size = UDim2.fromOffset(76, 30),
        ZIndex = 28,
    }, row)
    corner(track, 999)
    local trackStroke = stroke(track, Palette.disabled, 1, 0.40)
    local trackGradient = gradient(track, accent, secondaryAccent, 0)
    trackGradient.Transparency = NumberSequence.new(1)

    local orb = make("Frame", {
        Name = "EnergyOrb",
        BackgroundColor3 = Palette.disabled,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(22, 22),
        ZIndex = 30,
    }, track)
    corner(orb, 999)
    local orbStroke = stroke(orb, Palette.white, 1, 0.66)

    local status = label(row, "OFF", 7, Palette.muted, Enum.Font.GothamBold,
        UDim2.new(1, -83, 0.5, 14), UDim2.fromOffset(70, 12))
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.ZIndex = 29

    local function refresh()
        local enabled = state[key] == true
        trackGradient.Transparency = enabled and NumberSequence.new(0) or NumberSequence.new(1)
        trackStroke.Color = enabled and (tint or accent) or Palette.disabled
        trackStroke.Transparency = enabled and 0.12 or 0.48
        status.Text = enabled and "ON" or "OFF"
        status.TextColor3 = enabled and secondaryAccent or Palette.muted
        playTween(orb, state.ReduceMotion and 0.05 or 0.18, {
            Position = enabled and UDim2.new(1, -26, 0, 4) or UDim2.fromOffset(4, 4),
            BackgroundColor3 = enabled and Palette.white or Palette.disabled,
        }, Enum.EasingStyle.Quint)
        playTween(orbStroke, 0.18, { Transparency = enabled and 0.12 or 0.66 }, Enum.EasingStyle.Quad)
    end

    track.Activated:Connect(function()
        if not alive then return end
        state[key] = not state[key]
        refresh()
        particleBurst(track, UDim2.new(0.5, 0, 0.5, 0), tint or secondaryAccent, 5)
        applyVisualSettings()
        if key == "PlanetRotation" or key == "OrbitTrail" or key == "AmbientAnimation" or key == "ReduceMotion" then
            refreshOrbitAnimations()
        end
        showNotice(string.upper(titleText) .. (state[key] and " ENABLED" or " DISABLED"), tint or accent)
    end)
    toggleRefreshers[key .. tostring(row)] = refresh
    refresh()
    return row
end

local function addSlider(parent, titleText, key, minimum, maximum, initial, suffix, tint)
    local row = make("Frame", {
        Name = key .. "SliderRow",
        BackgroundColor3 = Color3.fromRGB(14, 21, 45),
        BackgroundTransparency = 0.30,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 72),
        ZIndex = 25,
    }, parent)
    corner(row, 12)
    stroke(row, tint or secondaryAccent, 1, 0.84)
    label(row, titleText, 10, Palette.white, Enum.Font.GothamBold,
        UDim2.fromOffset(12, 8), UDim2.new(1, -80, 0, 18))
    local valueLabel = label(row, "", 9, secondaryAccent, Enum.Font.Code,
        UDim2.new(1, -72, 0, 8), UDim2.fromOffset(58, 18))
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = make("Frame", {
        Name = "SliderTrack",
        Active = true,
        BackgroundColor3 = Color3.fromRGB(31, 40, 68),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 13, 0, 43),
        Size = UDim2.new(1, -26, 0, 7),
        ZIndex = 26,
    }, row)
    corner(track, 999)
    local fill = make("Frame", {
        BackgroundColor3 = tint or accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 27,
    }, track)
    corner(fill, 999)
    gradient(fill, tint or accent, secondaryAccent, 0)
    local knob = make("Frame", {
        BackgroundColor3 = Palette.white,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(15, 15),
        ZIndex = 29,
    }, track)
    corner(knob, 999)
    stroke(knob, tint or secondaryAccent, 1.2, 0.10)

    local current = initial or state[key] or minimum
    local function setValue(value, notify)
        current = math.clamp(value, minimum, maximum)
        state[key] = current
        local alpha = (current - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        local display = (math.floor(current * 100 + 0.5) / 100)
        valueLabel.Text = tostring(display) .. (suffix or "")
        if notify then
            applyVisualSettings()
            if key == "AnimationSpeed" or key == "OrbitSpeed" then refreshOrbitAnimations() end
        end
    end
    local function fromX(x)
        local width = math.max(1, track.AbsoluteSize.X)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        setValue(minimum + (maximum - minimum) * alpha, true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = { inputType = input.UserInputType, track = track, update = fromX }
            fromX(input.Position.X)
        end
    end)
    track.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = { inputType = Enum.UserInputType.Touch, track = track, update = fromX }
        end
    end)
    setValue(current, false)
    return row
end

local homePage = createPage("HOME")
sectionTitle(homePage, "COMMAND CENTER", "Your personal orbital interface is online.")

local hero = createCard(homePage, 176, "HomeHero")
local heroGlow = make("Frame", {
    BackgroundColor3 = accent,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, 18, 0.5, 0),
    Size = UDim2.fromOffset(190, 190),
    ZIndex = 24,
}, hero)
corner(heroGlow, 999)

local heroLogo = make("Frame", {
    Name = "OrbitalBXEmblem",
    BackgroundColor3 = Color3.fromRGB(13, 20, 47),
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(1, -86, 0.5, 0),
    Size = UDim2.fromOffset(82, 82),
    ZIndex = 28,
}, hero)
corner(heroLogo, 999)
stroke(heroLogo, secondaryAccent, 1.4, 0.10)
label(heroLogo, "BX", 29, Palette.white, Enum.Font.GothamBlack,
    UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)).ZIndex = 31
addRing(heroLogo, 105, accent, 0.12, 1.5, 18)
addRing(heroLogo, 132, secondaryAccent, 0.42, 1.1, -33)
addRing(heroLogo, 151, Palette.pink, 0.70, 1, 55)
makePlanet(heroLogo, Palette.blue, 9, UDim2.new(0.5, 58, 0.5, -26), 32)

-- Small asteroid fragments add depth without relying on external image assets.
for index, asteroidData in ipairs({
    { 5, UDim2.new(0.5, -63, 0.5, -33), -18 },
    { 4, UDim2.new(0.5, 56, 0.5, 39), 24 },
    { 3, UDim2.new(0.5, -27, 0.5, 67), 42 },
}) do
    local asteroid = make("Frame", {
        Name = "BXAsteroid" .. index,
        BackgroundColor3 = index == 2 and Palette.cyan or Palette.muted,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        Position = asteroidData[2],
        Size = UDim2.fromOffset(asteroidData[1], asteroidData[1] + 2),
        Rotation = asteroidData[3],
        ZIndex = 34,
    }, heroLogo)
    corner(asteroid, 2)
end

label(hero, "WELCOME BACK,", 8, secondaryAccent, Enum.Font.GothamBold,
    UDim2.fromOffset(16, 17), UDim2.new(0.58, -18, 0, 16))
label(hero, LocalPlayer.DisplayName, 18, Palette.white, Enum.Font.GothamBlack,
    UDim2.fromOffset(16, 37), UDim2.new(0.62, -18, 0, 27))
label(hero, "BAXTARA X CHEAT  /  ORBITAL GALAXY", 8, Palette.muted, Enum.Font.GothamMedium,
    UDim2.fromOffset(17, 67), UDim2.new(0.65, -18, 0, 17))
local usernameLine = label(hero, "@" .. LocalPlayer.Name .. "  •  ID " .. tostring(LocalPlayer.UserId), 8,
    Palette.muted, Enum.Font.Code, UDim2.fromOffset(17, 89), UDim2.new(0.68, -18, 0, 17))

local heroButton = make("TextButton", {
    Text = "OPEN VISUAL LAB   ›",
    TextColor3 = Palette.white,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(35, 43, 91),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(16, 121),
    Size = UDim2.fromOffset(142, 34),
    ZIndex = 30,
}, hero)
corner(heroButton, 9)
stroke(heroButton, secondaryAccent, 1, 0.35)
heroButton.Activated:Connect(function()
    if selectPage then
        selectPage("VISUAL")
        showNotice("VISUAL LAB OPENED", secondaryAccent)
    end
end)

local avatar = make("ImageLabel", {
    Name = "HomeAvatar",
    BackgroundColor3 = Color3.fromRGB(22, 32, 65),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -17, 1, -13),
    Size = UDim2.fromOffset(39, 39),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
    ZIndex = 31,
}, hero)
corner(avatar, 999)
stroke(avatar, secondaryAccent, 1.2, 0.20)

local statsRow = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -4, 0, 78),
    ZIndex = 24,
}, homePage)
local statsLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
}, statsRow)

local function statCard(parent, titleText, initialText, tint)
    local card = make("Frame", {
        BackgroundColor3 = Palette.card,
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Size = UDim2.new(0.333, -6, 1, 0),
        ZIndex = 25,
    }, parent)
    corner(card, 12)
    stroke(card, tint or accent, 1, 0.68)
    label(card, titleText, 8, Palette.muted, Enum.Font.GothamBold,
        UDim2.fromOffset(10, 9), UDim2.new(1, -16, 0, 15))
    local value = label(card, initialText, 17, tint or secondaryAccent, Enum.Font.GothamBlack,
        UDim2.fromOffset(10, 29), UDim2.new(1, -16, 0, 27))
    return value
end

local fpsValue = statCard(statsRow, "FPS", "--", Palette.cyan)
local pingValue = statCard(statsRow, "PING", "--", Palette.violet)
local sessionValue = statCard(statsRow, "SESSION", "00:00", Palette.green)

local homeInfo = createCard(homePage, 80, "SystemStatus")
label(homeInfo, "SYSTEM STATUS", 9, secondaryAccent, Enum.Font.GothamBold,
    UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 17))
label(homeInfo, "Visual modules are client-side only. No gameplay modifications are active.", 9,
    Palette.muted, Enum.Font.Gotham, UDim2.fromOffset(13, 31), UDim2.new(1, -26, 0, 35))

local visualPage = createPage("VISUAL")
sectionTitle(visualPage, "VISUAL LAB", "Tune the nebula, orbit paths, ambient stars and hologram layers.")
local visualGroup = createCard(visualPage, 8, "VisualToggleGroup")
visualGroup.AutomaticSize = Enum.AutomaticSize.Y
visualGroup.Size = UDim2.new(1, -4, 0, 0)
make("UIPadding", {
    PaddingTop = UDim.new(0, 9),
    PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9),
}, visualGroup)
local visualLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, visualGroup)

addToggle(visualGroup, "Galaxy Background", "Show the layered deep-space background.", "GalaxyBackground", Palette.violet)
addToggle(visualGroup, "Star Particles", "Show decorative star particles.", "StarParticles", Palette.cyan)
addToggle(visualGroup, "Planet Rotation", "Animate the orbital emblem rings.", "PlanetRotation", Palette.blue)
addToggle(visualGroup, "Nebula Glow", "Control the colored nebula clouds.", "NebulaGlow", Palette.pink)
addToggle(visualGroup, "Orbit Trail", "Enable orbital ring rotation.", "OrbitTrail", Palette.violet)
addToggle(visualGroup, "Hologram Effect", "Show the subtle scanning line.", "HologramEffect", Palette.cyan)
addToggle(visualGroup, "Ambient Animation", "Enable ambient interface motion.", "AmbientAnimation", Palette.green)

local visualSliderGroup = createCard(visualPage, 8, "VisualSliderGroup")
visualSliderGroup.AutomaticSize = Enum.AutomaticSize.Y
visualSliderGroup.Size = UDim2.new(1, -4, 0, 0)
make("UIPadding", {
    PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, visualSliderGroup)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, visualSliderGroup)
addSlider(visualSliderGroup, "Glow Intensity", "GlowIntensity", 0, 1, state.GlowIntensity, "", Palette.violet)
addSlider(visualSliderGroup, "Animation Speed", "AnimationSpeed", 0.25, 2, state.AnimationSpeed, "x", Palette.cyan)
addSlider(visualSliderGroup, "Background Opacity", "BackgroundOpacity", 0.40, 1, state.BackgroundOpacity, "", Palette.blue)
addSlider(visualSliderGroup, "Particle Density", "ParticleDensity", 0, 1, state.ParticleDensity, "", Palette.pink)
addSlider(visualSliderGroup, "Orbit Speed", "OrbitSpeed", 0.25, 2, state.OrbitSpeed, "x", Palette.green)

local toolsPage = createPage("TOOLS")
sectionTitle(toolsPage, "ORBITAL TOOLS", "Preview and test interface components. These tools affect UI only.")
local previewCard = createCard(toolsPage, 108, "PreviewCard")
label(previewCard, "LIVE PREVIEW", 9, secondaryAccent, Enum.Font.GothamBold,
    UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 17))
local previewOrb = make("Frame", {
    BackgroundColor3 = accent,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 15, 0.5, 9),
    Size = UDim2.fromOffset(30, 30),
    ZIndex = 27,
}, previewCard)
corner(previewOrb, 999)
stroke(previewOrb, secondaryAccent, 1.2, 0.10)
addRing(previewOrb, 48, secondaryAccent, 0.18, 1, 12)
label(previewCard, "GALAXY ENERGY CORE", 9, Palette.white, Enum.Font.GothamBold,
    UDim2.fromOffset(60, 35), UDim2.new(1, -75, 0, 18))
label(previewCard, "A small sample of the live visual system.", 8, Palette.muted, Enum.Font.Gotham,
    UDim2.fromOffset(60, 54), UDim2.new(1, -75, 0, 28))

local testGroup = createCard(toolsPage, 8, "ToolsActionGroup")
testGroup.AutomaticSize = Enum.AutomaticSize.Y
testGroup.Size = UDim2.new(1, -4, 0, 0)
make("UIPadding", {
    PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, testGroup)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, testGroup)

createActionButton(testGroup, "UI ANIMATION PREVIEW", function()
    if state.ReduceMotion then
        showNotice("REDUCE MOTION IS ACTIVE", Palette.muted)
        return
    end
    previewOrb.Rotation = 0
    playTween(previewOrb, 0.7, { Rotation = 360, Size = UDim2.fromOffset(38, 38) }, Enum.EasingStyle.Back)
    task.delay(0.72, function()
        if alive and previewOrb.Parent then
            playTween(previewOrb, 0.22, { Size = UDim2.fromOffset(30, 30) }, Enum.EasingStyle.Quad)
        end
    end)
    showNotice("ANIMATION PREVIEW PLAYED", secondaryAccent)
end, Palette.cyan)

createActionButton(testGroup, "GALAXY EFFECT PREVIEW", function()
    particleBurst(previewCard, UDim2.new(0, 31, 0.5, 9), secondaryAccent, 7)
    showNotice("GALAXY EFFECT PREVIEW", accent)
end, Palette.violet)

addToggle(testGroup, "Toggle Test Area", "A separate test switch for the interface.", "TestToggle", Palette.pink)
addSlider(testGroup, "Slider Test Area", "TestSlider", 0, 100, 55, "%", Palette.cyan)

createActionButton(testGroup, "BUTTON ANIMATION TEST", function()
    showNotice("BUTTON ANIMATION COMPLETE", Palette.green)
end, Palette.green)

local function resetVisualSettings()
    state.GalaxyBackground = true
    state.StarParticles = true
    state.PlanetRotation = true
    state.NebulaGlow = true
    state.OrbitTrail = true
    state.HologramEffect = true
    state.AmbientAnimation = true
    state.ReduceMotion = false
    state.GlowIntensity = 0.78
    state.AnimationSpeed = 1
    state.BackgroundOpacity = 0.92
    state.ParticleDensity = 0.70
    state.OrbitSpeed = 1
    state.UIScale = 1
    state.PanelTransparency = 0.08
    state.Theme = "NEBULA"
    accent = ThemeOptions[state.Theme].accent
    secondaryAccent = ThemeOptions[state.Theme].secondary
    applyVisualSettings()
    refreshOrbitAnimations()
    for _, refreshToggle in pairs(toggleRefreshers) do
        pcall(refreshToggle)
    end
    for name, button in pairs(themeButtons) do
        local selected = name == state.Theme
        button.BackgroundTransparency = selected and 0.02 or 0.30
        button.TextColor3 = selected and Palette.white or Palette.muted
        if themeButtonStrokes[name] then
            themeButtonStrokes[name].Transparency = selected and 0.12 or 0.65
        end
    end
    showNotice("VISUAL SETTINGS RESET", secondaryAccent)
end

createActionButton(testGroup, "RESET VISUAL SETTINGS", resetVisualSettings, Palette.pink)

local profilePage = createPage("PROFILE")
sectionTitle(profilePage, "ORBITAL PROFILE", "Player identity supplied by the current Roblox client.")
local profileCard = createCard(profilePage, 190, "PlayerProfileCard")
local profileAvatar = make("ImageLabel", {
    BackgroundColor3 = Color3.fromRGB(21, 31, 67),
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 17),
    Size = UDim2.fromOffset(76, 76),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
    ZIndex = 28,
}, profileCard)
corner(profileAvatar, 999)
stroke(profileAvatar, secondaryAccent, 1.5, 0.12)
addRing(profileAvatar, 94, accent, 0.18, 1.2, 25)
label(profileCard, LocalPlayer.DisplayName, 14, Palette.white, Enum.Font.GothamBlack,
    UDim2.new(0, 10, 0, 103), UDim2.new(1, -20, 0, 23)).TextXAlignment = Enum.TextXAlignment.Center
local profileUser = label(profileCard, "@" .. LocalPlayer.Name, 9, secondaryAccent, Enum.Font.GothamMedium,
    UDim2.new(0, 10, 0, 127), UDim2.new(1, -20, 0, 17))
profileUser.TextXAlignment = Enum.TextXAlignment.Center
local memberBadge = label(profileCard, "✦  ORBITAL MEMBER  ✦", 8, Palette.green, Enum.Font.GothamBold,
    UDim2.new(0, 10, 0, 151), UDim2.new(1, -20, 0, 18))
memberBadge.TextXAlignment = Enum.TextXAlignment.Center

local identityCard = createCard(profilePage, 102, "IdentityDetails")
label(identityCard, "ACCOUNT DETAILS", 9, secondaryAccent, Enum.Font.GothamBold,
    UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 16))
label(identityCard, "USERNAME     " .. LocalPlayer.Name, 9, Palette.white, Enum.Font.Code,
    UDim2.fromOffset(13, 33), UDim2.new(1, -26, 0, 17))
label(identityCard, "USER ID          " .. tostring(LocalPlayer.UserId), 9, Palette.muted, Enum.Font.Code,
    UDim2.fromOffset(13, 57), UDim2.new(1, -26, 0, 17))

local settingsPage = createPage("SETTINGS")
sectionTitle(settingsPage, "SYSTEM SETTINGS", "Personalize scale, motion, theme and panel appearance.")
local themeCard = createCard(settingsPage, 86, "ThemeSelection")
label(themeCard, "THEME SELECTION", 9, secondaryAccent, Enum.Font.GothamBold,
    UDim2.fromOffset(13, 9), UDim2.new(1, -26, 0, 17))

local function setTheme(themeName)
    if not ThemeOptions[themeName] then return end
    state.Theme = themeName
    accent = ThemeOptions[themeName].accent
    secondaryAccent = ThemeOptions[themeName].secondary
    mainStroke.Color = accent
    headerLine.BackgroundColor3 = secondaryAccent
    orbitSpine.BackgroundColor3 = secondaryAccent
    footerText.TextColor3 = Palette.muted
    for name, button in pairs(themeButtons) do
        local selected = name == themeName
        button.BackgroundTransparency = selected and 0.02 or 0.30
        button.TextColor3 = selected and Palette.white or Palette.muted
        themeButtonStrokes[name].Transparency = selected and 0.12 or 0.65
    end
    applyVisualSettings()
    showNotice("THEME: " .. themeName, secondaryAccent)
end

for index, themeName in ipairs({ "NEBULA", "MIDNIGHT", "AURORA" }) do
    local button = make("TextButton", {
        Text = themeName,
        TextColor3 = Palette.white,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BackgroundColor3 = ThemeOptions[themeName].accent,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Position = UDim2.new((index - 1) / 3, 7, 0, 39),
        Size = UDim2.new(1 / 3, -14, 0, 30),
        ZIndex = 27,
    }, themeCard)
    corner(button, 8)
    local buttonStroke = stroke(button, ThemeOptions[themeName].secondary, 1, 0.65)
    themeButtonStrokes[themeName] = buttonStroke
    themeButtons[themeName] = button
    button.Activated:Connect(function() setTheme(themeName) end)
end

local settingsGroup = createCard(settingsPage, 8, "SettingsSliderGroup")
settingsGroup.AutomaticSize = Enum.AutomaticSize.Y
settingsGroup.Size = UDim2.new(1, -4, 0, 0)
make("UIPadding", {
    PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, settingsGroup)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, settingsGroup)
addToggle(settingsGroup, "Reduce Motion", "Reduce continuous movement and transition time.", "ReduceMotion", Palette.green)
addSlider(settingsGroup, "UI Scale", "UIScale", 0.82, 1.00, state.UIScale, "x", Palette.cyan)
addSlider(settingsGroup, "Panel Transparency", "PanelTransparency", 0, 0.35, state.PanelTransparency, "", Palette.violet)

local settingsActions = createCard(settingsPage, 8, "SettingsActions")
settingsActions.AutomaticSize = Enum.AutomaticSize.Y
settingsActions.Size = UDim2.new(1, -4, 0, 0)
make("UIPadding", {
    PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, settingsActions)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, settingsActions)
createActionButton(settingsActions, "RESET ALL SETTINGS", resetVisualSettings, Palette.pink)
createActionButton(settingsActions, "CLOSE PANEL", function()
    if hidePanel then hidePanel("ORBITAL PORTAL CLOSED") end
end, Palette.pink)

local aboutPage = createPage("ABOUT")
sectionTitle(aboutPage, "ABOUT ORBITAL GALAXY", "A compact client-side visual interface.")
local aboutCard = createCard(aboutPage, 168, "AboutCard")
local aboutLogo = make("Frame", {
    BackgroundColor3 = Color3.fromRGB(15, 23, 54),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(15, 18),
    Size = UDim2.fromOffset(58, 58),
    ZIndex = 27,
}, aboutCard)
corner(aboutLogo, 999)
stroke(aboutLogo, secondaryAccent, 1.2, 0.18)
label(aboutLogo, "BX", 21, Palette.white, Enum.Font.GothamBlack,
    UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)).ZIndex = 30
addRing(aboutLogo, 76, accent, 0.18, 1, 15)
label(aboutCard, "BAXTARA X CHEAT", 13, Palette.white, Enum.Font.GothamBlack,
    UDim2.fromOffset(86, 18), UDim2.new(1, -98, 0, 21))
label(aboutCard, "ORBITAL GALAXY  /  VERSION 1.0.0", 8, secondaryAccent,
    Enum.Font.GothamBold, UDim2.fromOffset(87, 40), UDim2.new(1, -98, 0, 17))
label(aboutCard, "Designed as a space-themed control center for local interface visuals, animation previews and personal UI settings.",
    9, Palette.muted, Enum.Font.Gotham, UDim2.fromOffset(15, 91), UDim2.new(1, -30, 0, 58))

local safetyCard = createCard(aboutPage, 94, "ClientOnlyNotice")
label(safetyCard, "CLIENT VISUAL MODE", 9, Palette.green, Enum.Font.GothamBold,
    UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 17))
label(safetyCard, "This panel only changes its own interface. It does not modify game mechanics, other players, remote events or server state.",
    8, Palette.muted, Enum.Font.Gotham, UDim2.fromOffset(13, 32), UDim2.new(1, -26, 0, 49))

local pageNames = {
    { "HOME", Palette.blue },
    { "VISUAL", Palette.violet },
    { "TOOLS", Palette.cyan },
    { "PROFILE", Palette.green },
    { "SETTINGS", Palette.pink },
    { "ABOUT", Palette.white },
}

local navButtons = {}
selectPage = function(name)
    if not pages[name] then return end
    selectedPage = name
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
        if page.Visible then
            page.CanvasPosition = Vector2.new(0, 0)
        end
    end
    for pageName, item in pairs(navButtons) do
        local selected = pageName == name
        item.label.TextColor3 = selected and Palette.white or Palette.muted
        item.planet.Size = UDim2.fromOffset(selected and 35 or 29, selected and 35 or 29)
        item.glow.BackgroundTransparency = selected and 0.77 or 0.94
        item.outline.Transparency = selected and 0.10 or 0.55
        item.label.TextSize = isCompact and (selected and 8 or 7) or (selected and 10 or 9)
        if selected and not state.ReduceMotion then
            playTween(item.planet, 0.20, { Rotation = 12 }, Enum.EasingStyle.Back)
            task.delay(0.20, function()
                if alive and item.planet.Parent then
                    playTween(item.planet, 0.25, { Rotation = 0 }, Enum.EasingStyle.Quad)
                end
            end)
        else
            item.planet.Rotation = 0
        end
    end
end

for index, data in ipairs(pageNames) do
    local name, tint = data[1], data[2]
    local navItem = make("TextButton", {
        Name = name .. "PlanetNav",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -3, 0, isCompact and 39 or 48),
        LayoutOrder = index,
        ZIndex = 24,
    }, navList)

    local planetX = isCompact and 4 or 7
    local planet = makePlanet(navItem, tint, 29,
        UDim2.new(0, planetX, 0.5, -14), 26)
    local glow = make("Frame", {
        BackgroundColor3 = tint,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, planetX + 14, 0.5, 0),
        Size = UDim2.fromOffset(43, 43),
        ZIndex = 25,
    }, navItem)
    corner(glow, 999)
    local outline = stroke(planet, tint, 1, 0.55)
    local navLabel = label(navItem, name, isCompact and 7 or 9, Palette.muted, Enum.Font.GothamBold,
        UDim2.new(0, isCompact and 43 or 53, 0, 0), UDim2.new(1, isCompact and -46 or -58, 1, 0))
    navLabel.TextWrapped = false
    navLabel.TextTruncate = Enum.TextTruncate.AtEnd
    navButtons[name] = { button = navItem, planet = planet, glow = glow, outline = outline, label = navLabel }
    navItem.Activated:Connect(function()
        selectPage(name)
        showNotice(name .. " SECTOR SELECTED", tint)
    end)
end

selectPage("HOME")

local function updateLayout()
    if not alive then return end
    local viewport = getViewport()
    local width, height = calculatePanelSize()
    isCompact = viewport.X < 560
    navWidth = isCompact and 82 or 142
    main.Size = UDim2.fromOffset(width, height)
    nav.Size = UDim2.new(0, navWidth, 1, -18)
    pageHost.Position = UDim2.new(0, navWidth + 18, 0, 10)
    pageHost.Size = UDim2.new(1, -navWidth - 27, 1, -18)
    navList.Position = UDim2.fromOffset(4, 34)
    navList.Size = UDim2.new(1, -8, 1, -42)
    navLayout.Padding = UDim.new(0, isCompact and 3 or 5)
    for _, item in pairs(navButtons) do
        item.button.Size = UDim2.new(1, -3, 0, isCompact and 39 or 48)
        item.label.Position = UDim2.new(0, isCompact and 43 or 53, 0, 0)
        item.label.Size = UDim2.new(1, isCompact and -46 or -58, 1, 0)
        item.label.TextSize = isCompact and 7 or 9
    end
    if introFinished then
        main.Position = UDim2.fromScale(0.5, 0.5)
    end
end

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        dragInput = input
    end
end)

keepConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local viewport = getViewport()
        local halfW = main.AbsoluteSize.X * 0.5
        local halfH = main.AbsoluteSize.Y * 0.5
        local x = math.clamp(startPosition.X.Offset + delta.X, -viewport.X * 0.5 + halfW + 8, viewport.X * 0.5 - halfW - 8)
        local y = math.clamp(startPosition.Y.Offset + delta.Y, -viewport.Y * 0.5 + halfH + 8, viewport.Y * 0.5 - halfH - 8)
        main.Position = UDim2.new(0.5, x, 0.5, y)
    end
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        activeSlider.update(input.Position.X)
    end
end))

keepConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragInput = nil
        activeSlider = nil
    end
end))

local function finishIntro()
    if introFinished or not alive then return end
    introFinished = true
    openedOnce = true
    cancelTweenList(introOrbitTweens)
    playTween(intro, 0.35, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
    playTween(introLogo, 0.28, { Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.34, function()
        if not alive then return end
        intro.Visible = false
        main.Visible = true
        local width, height = calculatePanelSize()
        main.Size = UDim2.fromOffset(190, 130)
        main.BackgroundTransparency = 1
        updatePanelTransparency()
        local openTween = playTween(main, state.ReduceMotion and 0.12 or 0.52, {
            Size = UDim2.fromOffset(width, height),
            BackgroundTransparency = state.PanelTransparency,
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        refreshOrbitAnimations()
        if openTween then openTween.Completed:Wait() end
        if alive then
            showNotice("ORBITAL SYSTEM ONLINE", secondaryAccent)
        end
    end)
end

local function playOpening(shortMode)
    if not alive then return end
    floatingButton.Visible = false
    intro.Visible = false
    main.Visible = true
    local width, height = calculatePanelSize()
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(shortMode and 190 or 215, shortMode and 130 or 145)
    main.BackgroundTransparency = 1
    updatePanelTransparency()
    local tween = playTween(main, state.ReduceMotion and 0.12 or (shortMode and 0.30 or 0.48), {
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = state.PanelTransparency,
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    if tween then
        tween.Completed:Connect(function()
            if alive then
                showNotice("WELCOME BACK TO ORBITAL", secondaryAccent)
            end
        end)
    end
    refreshOrbitAnimations()
end

hidePanel = function(message)
    if not alive or not main.Visible then return end
    activeSlider = nil
    dragging = false
    if state.ReduceMotion then
        main.Visible = false
        floatingButton.Visible = true
        showNotice(message or "PANEL MINIMIZED", secondaryAccent)
        return
    end
    local width = math.min(230, main.AbsoluteSize.X)
    local tween = playTween(main, 0.30, {
        Size = UDim2.fromOffset(width * 0.72, 105),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    for _, item in pairs(navButtons) do
        playTween(item.planet, 0.22, { Size = UDim2.fromOffset(10, 10) }, Enum.EasingStyle.Quad)
    end
    if tween then tween.Completed:Wait() end
    if alive then
        main.Visible = false
        floatingButton.Visible = true
        for _, item in pairs(navButtons) do
            item.planet.Size = UDim2.fromOffset(29, 29)
        end
        showNotice(message or "PANEL MINIMIZED", secondaryAccent)
    end
end

minimizeButton.Activated:Connect(function()
    hidePanel("PANEL MINIMIZED")
end)
closeButton.Activated:Connect(function()
    hidePanel("ORBITAL PORTAL CLOSED")
end)
floatingButton.Activated:Connect(function()
    playOpening(true)
end)
skipIntro.Activated:Connect(finishIntro)

local function safeGetPing()
    local success, result = pcall(function()
        local network = Stats:FindFirstChild("Network")
        if not network then return nil end
        local serverStats = network:FindFirstChild("ServerStatsItem")
        if not serverStats then return nil end
        local dataPing = serverStats:FindFirstChild("Data Ping")
        if not dataPing then return nil end
        return dataPing:GetValueString()
    end)
    if success and result then
        return tostring(result)
    end
    return "N/A"
end

keepConnection(RunService.Heartbeat:Connect(function()
    if not alive then return end
    fpsFrames = fpsFrames + 1
    local now = os.clock()
    if now - fpsClock >= 1 then
        cachedFPS = math.floor(fpsFrames / math.max(0.001, now - fpsClock) + 0.5)
        fpsFrames = 0
        fpsClock = now
        fpsValue.Text = tostring(cachedFPS)
        local elapsed = math.floor(now - sessionStarted)
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        sessionValue.Text = string.format("%02d:%02d", minutes, seconds)
        pingValue.Text = safeGetPing()
    end
end))

keepConnection(RunService.RenderStepped:Connect(function()
    if not alive or not state.HologramEffect or state.ReduceMotion or not state.AmbientAnimation then return end
    if scanLine and scanLine.Parent then
        local t = os.clock() * 0.18 * state.AnimationSpeed
        scanLine.Position = UDim2.new(0, 0, 0.10 + ((math.sin(t) + 1) * 0.34), 0)
    end
end))

keepConnection(task.spawn(function()
    while alive and screen.Parent do
        if state.StarParticles and state.AmbientAnimation and not state.ReduceMotion then
            for index, star in ipairs(starObjects) do
                if index <= math.floor(#starObjects * state.ParticleDensity) and star.Parent then
                    local base = math.random(35, 82) / 100
                    playTween(star, math.random(7, 15) / 10 / math.max(0.5, state.AnimationSpeed), {
                        BackgroundTransparency = base,
                    }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                end
            end
        end
        task.wait(2.4)
    end
end))

keepConnection(task.spawn(function()
    while alive and screen.Parent do
        clockLabel.Text = os.date("%H:%M:%S") .. "  LOCAL"
        task.wait(1)
    end
end))

local function updateAvatarImages()
    local image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
    avatar.Image = image
    profileAvatar.Image = image
end

local function onCharacterChanged()
    task.delay(0.5, function()
        if alive then updateAvatarImages() end
    end)
end
keepConnection(LocalPlayer.CharacterAdded:Connect(onCharacterChanged))

local camera = workspace.CurrentCamera
if camera then
    keepConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout))
end
keepConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        keepConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout))
        updateLayout()
    end
end))

applyVisualSettings()
refreshOrbitAnimations()
updateLayout()

-- Cinematic first launch: layered fade, orbital emblem reveal, title and panel expansion.
intro.BackgroundTransparency = 1
playTween(intro, 0.45, { BackgroundTransparency = 0.08 }, Enum.EasingStyle.Quad)
playTween(introGlow, 0.75, { Size = UDim2.fromOffset(310, 310), BackgroundTransparency = 0.75 }, Enum.EasingStyle.Quint)
playTween(introLogo, 0.65, { Size = UDim2.fromOffset(78, 78) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
table.insert(introOrbitTweens, playTween(introRingA, 4.0, { Rotation = 372 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
table.insert(introOrbitTweens, playTween(introRingB, 6.0, { Rotation = -384 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
table.insert(introOrbitTweens, playTween(introRingC, 8.0, { Rotation = 405 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
playTween(introPlanet, 1.0, { Position = UDim2.new(0.5, 82, 0.46, -42) }, Enum.EasingStyle.Sine)
task.delay(0.55, function()
    if alive then
        playTween(introTitle, 0.42, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
    end
end)
task.delay(0.82, function()
    if alive then
        playTween(introSubtitle, 0.42, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
    end
end)
task.delay(1.18, function()
    if alive then
        introStatus.Text = "SYNCHRONIZING ORBITAL NAVIGATION..."
        playTween(introStatus, 0.35, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
    end
end)
task.delay(1.95, function()
    if alive then finishIntro() end
end)

-- Cleanup if the ScreenGui is removed manually.
screen.AncestryChanged:Connect(function(_, parent)
    if parent == nil and alive then
        alive = false
        cancelTweenList(orbitTweens)
        cancelTweenList(activeTweens)
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end
end)

print("[BAXTARA X CHEAT] ORBITAL GALAXY UI loaded. Client visual mode only.")
