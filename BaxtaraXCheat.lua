--[[
================================================================================
  BAXTARA X CHEAT  -  BLOOD EVIL EDITION  (v1.0.0)
  Roblox LocalScript - visual interface demonstration

  INSTALL : StarterPlayer > StarterPlayerScripts > LocalScript (paste this file)
  OPEN    : floating skull button (drag to move) or RightShift on a keyboard.

  NOTE    : This is a UI showcase only. Every toggle / slider / button changes
            the interface itself (effects, colors, size, notifications ...).
            It does not touch gameplay, other players, remotes or the server.
================================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "BaxtaraXCheat"
local APP_NAME = "BAXTARA X CHEAT"
local EDITION = "BLOOD EVIL EDITION"
local VERSION = "1.0.0"

local previous = PlayerGui:FindFirstChild(GUI_NAME)
if previous then
	previous:Destroy()
end

--------------------------------------------------------------------------------
-- THEME / SETTINGS
--------------------------------------------------------------------------------
local Theme = {
	Background = Color3.fromRGB(8, 6, 9), -- #080609
	Panel = Color3.fromRGB(18, 11, 16), -- #120B10
	Card = Color3.fromRGB(27, 16, 23), -- #1B1017
	Primary = Color3.fromRGB(215, 25, 63), -- #D7193F
	DarkRed = Color3.fromRGB(101, 10, 32), -- #650A20
	White = Color3.fromRGB(245, 245, 245), -- #F5F5F5
	Secondary = Color3.fromRGB(153, 144, 154), -- #99909A
	Online = Color3.fromRGB(70, 220, 120),
}

local Accent = { Primary = Theme.Primary, Dark = Theme.DarkRed }

local AccentPresets = {
	{ name = "BLOOD", primary = Color3.fromRGB(215, 25, 63), dark = Color3.fromRGB(101, 10, 32) },
	{ name = "CRIMSON", primary = Color3.fromRGB(255, 51, 85), dark = Color3.fromRGB(122, 18, 40) },
	{ name = "EMBER", primary = Color3.fromRGB(255, 90, 31), dark = Color3.fromRGB(107, 32, 8) },
	{ name = "RUBY", primary = Color3.fromRGB(194, 24, 91), dark = Color3.fromRGB(90, 11, 46) },
	{ name = "GHOST", primary = Color3.fromRGB(226, 226, 230), dark = Color3.fromRGB(74, 68, 76) },
}

local Defaults = {
	Particles = true,
	MovingLines = true,
	AnimatedBorder = true,
	MovingLight = true,
	LogoRing = true,
	Pulse = true,
	GlitchFx = true,
	NeonGlow = true,
	GlowIntensity = 60,
	ParticleDensity = 100,
	Notifications = true,
	FloatingButton = true,
	LockPanel = false,
	MiniHud = false,
	Transparency = 0,
	AnimSpeed = 1,
	PanelSize = 100,
	Accent = 1,
}

local Settings = {}
for k, v in pairs(Defaults) do
	Settings[k] = v
end

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local FONT_CODE = Enum.Font.Code

--------------------------------------------------------------------------------
-- SHARED TABLES
--------------------------------------------------------------------------------
local State = { PanelOpen = false, Minimized = false, Page = "", Ready = false, Intro = false, OpenToken = 0 }
local Refs, Controls, UI, Pages = {}, {}, {}, {}
local Float, Hud, Panel = {}, {}, {}
local Notify = { List = {}, Counter = 0 }
local Metrics = { FPS = 60, Ping = nil, Frames = 0, Acc = 0, History = {}, StartTime = os.time() }
local Connections = {}

--------------------------------------------------------------------------------
-- UTILITIES
--------------------------------------------------------------------------------
local FULL = UDim.new(1, 0)

local function clamp(v, lo, hi)
	if hi < lo then
		return hi
	end
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function track(conn)
	Connections[#Connections + 1] = conn
	return conn
end

local function create(className, props, children)
	local inst = Instance.new(className)
	local isGui = inst:IsA("GuiObject")
	if isGui then
		inst.BorderSizePixel = 0
		inst.BackgroundTransparency = 1
		if inst:IsA("GuiButton") then
			inst.AutoButtonColor = false
		end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then
			inst.Font = FONT
			inst.TextColor3 = Theme.White
			inst.TextSize = 13
			inst.Text = ""
		end
	end
	if props then
		if isGui and props.BackgroundColor3 ~= nil and props.BackgroundTransparency == nil then
			inst.BackgroundTransparency = 0
		end
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(parent, radius)
	local r = radius
	if typeof(r) == "number" then
		r = UDim.new(0, r)
	end
	return create("UICorner", { CornerRadius = r, Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function gradient(parent, colorSeq, transSeq, rotation)
	return create("UIGradient", {
		Color = colorSeq or ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = transSeq or NumberSequence.new(0),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

local function padding(parent, l, t, r, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		Parent = parent,
	})
end

local function listLayout(parent, gap, dir, hAlign, vAlign)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap or 0),
		FillDirection = dir or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function counter()
	local n = 0
	return function()
		n = n + 1
		return n
	end
end

local function dur(t)
	return t / math.max(Settings.AnimSpeed, 0.1)
end

local function tween(inst, duration, props, style, direction)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(dur(duration), style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

local function ck(t, c)
	return ColorSequenceKeypoint.new(t, c)
end

-- single Heartbeat loop for every continuous animation
local Updaters = {}
local updaterId = 0
local function addUpdater(fn)
	updaterId = updaterId + 1
	local id = updaterId
	Updaters[id] = fn
	return function()
		Updaters[id] = nil
	end
end

track(RunService.Heartbeat:Connect(function(dt)
	for id, fn in pairs(Updaters) do
		local ok = pcall(fn, dt)
		if not ok then
			Updaters[id] = nil
		end
	end
end))

--------------------------------------------------------------------------------
-- ROOT GUI
--------------------------------------------------------------------------------
local ScreenGui = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
})
ScreenGui.Parent = PlayerGui

ScreenGui.Destroying:Connect(function()
	for _, c in ipairs(Connections) do
		c:Disconnect()
	end
end)

local function screenSize()
	local s = ScreenGui.AbsoluteSize
	if s.X < 50 or s.Y < 50 then
		local cam = workspace.CurrentCamera
		if cam then
			return cam.ViewportSize
		end
		return Vector2.new(800, 450)
	end
	return s
end

--------------------------------------------------------------------------------
-- ACCENT BINDING / SURFACES / GLOW REGISTRIES
--------------------------------------------------------------------------------
local AccentBinds = {}
local function bind(fn)
	AccentBinds[#AccentBinds + 1] = fn
	fn()
end

local function bindColor(inst, prop, which)
	bind(function()
		if which == "Dark" then
			inst[prop] = Accent.Dark
		else
			inst[prop] = Accent.Primary
		end
	end)
end

local function refreshAccent()
	for i = 1, #AccentBinds do
		pcall(AccentBinds[i])
	end
end

local Surfaces = {}
local function surface(inst, base, factor)
	local entry = { Inst = inst, Base = base or 0, Factor = factor or 1 }
	Surfaces[#Surfaces + 1] = entry
	inst.BackgroundTransparency = clamp(entry.Base + (Settings.Transparency / 100) * entry.Factor, 0, 0.95)
end

local function applySurfaces()
	local t = Settings.Transparency / 100
	for i = 1, #Surfaces do
		local e = Surfaces[i]
		e.Inst.BackgroundTransparency = clamp(e.Base + t * e.Factor, 0, 0.95)
	end
end

local Glows = {}
local function glowK()
	if Settings.NeonGlow then
		return Settings.GlowIntensity / 100
	end
	return 0
end

local function registerGlow(strokeInst, maxFn)
	local entry = { Stroke = strokeInst, Max = maxFn }
	function entry.Refresh(animated)
		local tr = 1 - clamp(entry.Max() * glowK(), 0, 1)
		if animated then
			tween(strokeInst, 0.25, { Transparency = tr })
		else
			strokeInst.Transparency = tr
		end
	end
	Glows[#Glows + 1] = entry
	entry.Refresh(false)
	return entry
end

local function refreshGlows()
	for i = 1, #Glows do
		Glows[i].Refresh(false)
	end
end

-- soft neon halo made of two stacked rings
local function makeGlow(parent, radius, spread, maxA)
	for i = 1, 2 do
		local pad = spread * i
		local f = create("Frame", {
			Name = "Glow" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, pad * 2, 1, pad * 2),
			Parent = parent,
		})
		corner(f, radius + pad)
		local s = stroke(f, Accent.Primary, 2 + i * 2, 1)
		bindColor(s, "Color", "Primary")
		local strength = maxA / i
		registerGlow(s, function()
			return strength
		end)
	end
end

--------------------------------------------------------------------------------
-- LOGO: SKULL (drawn from frames), ROTATING RINGS, PARTICLES, GLITCH
--------------------------------------------------------------------------------
local function makeSkull(parent, size, bodyColor, temp)
	local root = create("Frame", { Name = "Skull", Size = UDim2.fromOffset(size, size), Parent = parent })
	local bodyParts = {}
	local pupils = {}
	local useAccent = (bodyColor == nil)
	local c0 = useAccent and Accent.Primary or bodyColor

	local function piece(cx, cy, w, h, color, rad, rot)
		local f = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx, cy),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = color,
			Rotation = rot or 0,
			Parent = root,
		})
		if rad then
			corner(f, UDim.new(rad, 0))
		end
		return f
	end

	bodyParts[1] = piece(0.5, 0.38, 0.74, 0.66, c0, 0.48, 0) -- cranium
	bodyParts[2] = piece(0.5, 0.76, 0.42, 0.26, c0, 0.28, 0) -- jaw
	piece(0.33, 0.43, 0.2, 0.22, Theme.Background, 0.5) -- eye socket L
	piece(0.67, 0.43, 0.2, 0.22, Theme.Background, 0.5) -- eye socket R
	pupils[1] = piece(0.33, 0.43, 0.085, 0.085, Accent.Primary, 0.5)
	pupils[2] = piece(0.67, 0.43, 0.085, 0.085, Accent.Primary, 0.5)
	piece(0.5, 0.6, 0.07, 0.07, Theme.Background, nil, 45) -- nose
	piece(0.41, 0.8, 0.02, 0.16, Theme.Background) -- teeth gaps
	piece(0.5, 0.8, 0.02, 0.16, Theme.Background)
	piece(0.59, 0.8, 0.02, 0.16, Theme.Background)
	piece(0.66, 0.15, 0.016, 0.2, Theme.Background, nil, 28) -- crack

	if not temp then
		bind(function()
			if useAccent then
				for _, p in ipairs(bodyParts) do
					p.BackgroundColor3 = Accent.Primary
				end
			end
			for _, p in ipairs(pupils) do
				p.BackgroundColor3 = Accent.Primary
			end
		end)
	end

	local api = { Root = root }
	function api.Center()
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.fromScale(0.5, 0.5)
	end
	return api
end

local Rings = {}
local function makeRing(parent, extra, thickness, speed, temp)
	local f = create("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, extra, 1, extra),
		Parent = parent,
	})
	corner(f, FULL)
	local s = stroke(f, Color3.new(1, 1, 1), thickness or 2, 0)
	local g = create("UIGradient", {
		Color = ColorSequence.new(Accent.Primary),
		Transparency = NumberSequence.new({ kp(0, 0), kp(0.45, 0.7), kp(0.55, 1), kp(1, 1) }),
		Parent = s,
	})
	local ring = { Frame = f, Gradient = g, Speed = speed or 140, Temp = temp and true or false }
	Rings[#Rings + 1] = ring
	if not temp then
		f.Visible = Settings.LogoRing
		bind(function()
			g.Color = ColorSequence.new(Accent.Primary)
		end)
	end
	return ring
end

local function removeRing(ring)
	for i, r in ipairs(Rings) do
		if r == ring then
			table.remove(Rings, i)
			break
		end
	end
end

addUpdater(function(dt)
	for i = 1, #Rings do
		local r = Rings[i]
		if r.Frame.Visible then
			r.Gradient.Rotation = (r.Gradient.Rotation + dt * r.Speed) % 360
		end
	end
end)

local function makeParticles(parent, count, opts)
	opts = opts or {}
	local field = { Enabled = true, Density = 1, Items = {}, Gate = opts.gate }
	local holder = create("Frame", {
		Name = "Particles",
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		Parent = parent,
	})
	for i = 1, count do
		local sz = math.random(2, 4)
		local f = create("Frame", {
			Size = UDim2.fromOffset(sz, sz),
			BackgroundColor3 = Accent.Primary,
			Parent = holder,
		})
		corner(f, 1)
		field.Items[i] = {
			Frame = f,
			X = math.random(),
			Y = math.random(),
			VY = 0.03 + math.random() * 0.08,
			VX = (math.random() - 0.5) * 0.03,
			Phase = math.random() * 6.28,
			Alpha = 0.35 + math.random() * 0.5,
		}
	end
	function field.SetEnabled(v)
		field.Enabled = v
		holder.Visible = v
	end
	function field.SetDensity(d)
		field.Density = d
		local n = math.floor(count * d + 0.5)
		for i, it in ipairs(field.Items) do
			it.Frame.Visible = i <= n
		end
	end
	local t = 0
	field.Stop = addUpdater(function(dt)
		if not field.Enabled then
			return
		end
		if field.Gate and not field.Gate() then
			return
		end
		t = t + dt
		for _, it in ipairs(field.Items) do
			if it.Frame.Visible then
				it.Y = it.Y - it.VY * dt
				it.X = it.X + it.VX * dt
				if it.Y < -0.05 then
					it.Y = 1.05
					it.X = math.random()
				end
				it.Frame.Position = UDim2.fromScale(it.X, it.Y)
				it.Frame.BackgroundTransparency = 1 - it.Alpha * (0.55 + 0.45 * math.sin(t * 2.2 + it.Phase))
			end
		end
	end)
	if not opts.temp then
		bind(function()
			for _, it in ipairs(field.Items) do
				it.Frame.BackgroundColor3 = Accent.Primary
			end
		end)
	end
	return field
end

-- short digital glitch: jitter + slice bars (target must live in a non-layout parent)
local function glitch(target, duration, strength)
	if not target or not target.Parent then
		return
	end
	if target:GetAttribute("Glitching") then
		return
	end
	target:SetAttribute("Glitching", true)
	strength = strength or 5
	local origin = target.Position
	local isText = target:IsA("TextLabel")
	local origColor = nil
	if isText then
		origColor = target.TextColor3
	end
	local parent = target.Parent
	task.spawn(function()
		local steps = math.max(2, math.floor(duration / 0.045))
		local bars = {}
		for step = 1, steps do
			if not target.Parent then
				break
			end
			target.Position = origin + UDim2.fromOffset(math.random(-strength, strength), math.random(-1, 1))
			if isText then
				if step % 2 == 0 then
					target.TextColor3 = Accent.Primary
				else
					target.TextColor3 = Theme.White
				end
			end
			for _, b in ipairs(bars) do
				b:Destroy()
			end
			bars = {}
			local abs = target.AbsoluteSize
			local halfY = math.max(1, math.floor(abs.Y / 2))
			for _ = 1, math.random(1, 3) do
				local col = Theme.White
				if math.random() > 0.5 then
					col = Accent.Primary
				end
				local bar = create("Frame", {
					AnchorPoint = target.AnchorPoint,
					Position = origin + UDim2.fromOffset(math.random(-strength * 2, strength * 2), math.random(-halfY, halfY)),
					Size = UDim2.fromOffset(math.max(8, math.floor(abs.X * (0.3 + math.random() * 0.7))), math.random(2, 5)),
					BackgroundColor3 = col,
					BackgroundTransparency = 0.35,
					ZIndex = target.ZIndex + 2,
					Parent = parent,
				})
				bars[#bars + 1] = bar
			end
			task.wait(0.045)
		end
		for _, b in ipairs(bars) do
			b:Destroy()
		end
		if target.Parent then
			target.Position = origin
			if isText then
				target.TextColor3 = origColor
			end
		end
		target:SetAttribute("Glitching", nil)
	end)
end

--------------------------------------------------------------------------------
-- NOTIFICATION SYSTEM
--------------------------------------------------------------------------------
UI.NotifyHolder = create("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 62),
	Size = UDim2.new(0, 260, 1, -110),
	ZIndex = 20,
	Parent = ScreenGui,
})
listLayout(UI.NotifyHolder, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)

local function dismissNotification(entry)
	if entry.Dead then
		return
	end
	entry.Dead = true
	for i, e in ipairs(Notify.List) do
		if e == entry then
			table.remove(Notify.List, i)
			break
		end
	end
	if entry.Progress then
		entry.Progress:Cancel()
	end
	tween(entry.Card, 0.3, { Position = UDim2.new(1, 60, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	task.delay(dur(0.3), function()
		if entry.Holder and entry.Holder.Parent then
			tween(entry.Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quad)
			task.delay(dur(0.22), function()
				entry.Holder:Destroy()
			end)
		end
	end)
end

local function notify(title, message, opts)
	opts = opts or {}
	if not Settings.Notifications and not opts.force then
		return
	end
	while #Notify.List >= 5 do
		dismissNotification(Notify.List[1])
	end
	local life = opts.duration or 3.4
	Notify.Counter = Notify.Counter + 1

	local holder = create("Frame", {
		Name = "Notif",
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = Notify.Counter,
		Parent = UI.NotifyHolder,
	})
	local card = create("Frame", {
		Name = "Card",
		Position = UDim2.new(1, 60, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 6, 9),
		BackgroundTransparency = 0.12,
		Parent = holder,
	})
	corner(card, 8)
	stroke(card, Accent.Primary, 1.5, 0.1)
	local icon = makeSkull(card, 26, nil, true)
	icon.Root.Position = UDim2.fromOffset(10, 12)
	create("TextLabel", {
		Position = UDim2.fromOffset(46, 8),
		Size = UDim2.new(1, -56, 0, 14),
		Text = string.upper(title),
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = Accent.Primary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(46, 23),
		Size = UDim2.new(1, -56, 0, 28),
		Text = message,
		TextSize = 11,
		TextTransparency = 0.12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	local bar = create("Frame", {
		Position = UDim2.new(0, 8, 1, -7),
		Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = Accent.Dark,
		BackgroundTransparency = 0.3,
		Parent = card,
	})
	corner(bar, FULL)
	local fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Accent.Primary,
		Parent = bar,
	})
	corner(fill, FULL)

	local entry = { Holder = holder, Card = card, Dead = false }
	Notify.List[#Notify.List + 1] = entry

	tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, 60) }, Enum.EasingStyle.Quad)
	tween(card, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	entry.Progress = TweenService:Create(
		fill,
		TweenInfo.new(life, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 1, 0) }
	)
	entry.Progress:Play()
	task.delay(life, function()
		dismissNotification(entry)
	end)
end

--------------------------------------------------------------------------------
-- INPUT HELPERS: DRAG, PRESS, HOVER, FLASH
--------------------------------------------------------------------------------
local function makeDraggable(handle, target, opts)
	opts = opts or {}
	local dragging = false
	local startInput, startPointer, startPos = nil, nil, nil
	local moved = 0

	handle.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		startInput = input
		startPointer = input.Position
		startPos = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
		moved = 0
		if opts.onBegin then
			opts.onBegin()
		end
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End and dragging and startInput == input then
				dragging = false
				if opts.onEnd then
					opts.onEnd(moved)
				end
			end
		end)
	end)

	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch then
			if input ~= startInput then
				return
			end
		elseif t ~= Enum.UserInputType.MouseMovement then
			return
		end
		local d = input.Position - startPointer
		moved = math.max(moved, math.sqrt(d.X * d.X + d.Y * d.Y))
		if opts.canDrag and not opts.canDrag() then
			return
		end
		if moved < (opts.threshold or 3) then
			return
		end
		local screen = screenSize()
		local size = target.AbsoluteSize
		local nx = clamp(startPos.X + d.X, 4, screen.X - size.X - 4)
		local ny = clamp(startPos.Y + d.Y, 4, screen.Y - size.Y - 4)
		target.Position = UDim2.fromOffset(nx, ny)
		if opts.onMove then
			opts.onMove()
		end
	end))
end

local function isPointerInput(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

local function pressEffect(button, target, scaleDown)
	target = target or button
	local sc = create("UIScale", { Scale = 1, Parent = target })
	local down = false
	button.InputBegan:Connect(function(input)
		if isPointerInput(input) then
			down = true
			tween(sc, 0.08, { Scale = scaleDown or 0.95 }, Enum.EasingStyle.Quad)
		end
	end)
	local function release()
		if down then
			down = false
			tween(sc, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	button.InputEnded:Connect(function(input)
		if isPointerInput(input) then
			release()
		end
	end)
	button.MouseLeave:Connect(release)
	return sc
end

local function flash(button, rad)
	local f = create("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Accent.Primary,
		BackgroundTransparency = 0.55,
		ZIndex = button.ZIndex + 3,
		Parent = button,
	})
	corner(f, rad or 8)
	tween(f, 0.38, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(dur(0.42), function()
		f:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- UI COMPONENTS
--------------------------------------------------------------------------------
local function sectionLabel(parent, text, order)
	local f = create("Frame", { Name = "Section", Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order, Parent = parent })
	local mark = create("Frame", {
		Position = UDim2.fromOffset(2, 6),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Accent.Primary,
		Rotation = 45,
		Parent = f,
	})
	bindColor(mark, "BackgroundColor3", "Primary")
	create("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = text,
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = f,
	})
	local line = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 1),
		BackgroundColor3 = Accent.Dark,
		Parent = f,
	})
	bindColor(line, "BackgroundColor3", "Dark")
	gradient(line, nil, NumberSequence.new({ kp(0, 1), kp(1, 0.1) }), 0)
	return f
end

local function newInfoRow(parent, label, value, order)
	local row = create("Frame", {
		Name = "Info_" .. label,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Card,
		LayoutOrder = order,
		Parent = parent,
	})
	corner(row, 6)
	surface(row, 0, 0.6)
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.42, 0, 1, 0),
		Text = label,
		Font = FONT_BOLD,
		TextSize = 10,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local val = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.58, -12, 1, 0),
		Text = value,
		Font = FONT_CODE,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	return val
end

local function newButton(parent, o)
	local b = create("TextButton", {
		Name = "Btn_" .. o.text,
		Size = o.size or UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = o.primary and Accent.Primary or Theme.Card,
		Text = o.text,
		Font = FONT_BOLD,
		TextSize = 12,
		LayoutOrder = o.order or 0,
		Parent = parent,
	})
	corner(b, 8)
	local s = stroke(b, Accent.Primary, 1, o.primary and 0.2 or 0.55)
	bindColor(s, "Color", "Primary")
	if o.primary then
		bindColor(b, "BackgroundColor3", "Primary")
	end
	b.MouseEnter:Connect(function()
		if o.primary then
			tween(b, 0.15, { BackgroundTransparency = 0.15 })
		else
			tween(b, 0.15, { BackgroundColor3 = Color3.fromRGB(46, 21, 31) })
		end
	end)
	b.MouseLeave:Connect(function()
		if o.primary then
			tween(b, 0.2, { BackgroundTransparency = 0 })
		else
			tween(b, 0.2, { BackgroundColor3 = Theme.Card })
		end
	end)
	pressEffect(b, b, 0.95)
	b.Activated:Connect(function()
		flash(b, 8)
		if o.onClick then
			o.onClick(b)
		end
	end)
	return b
end

local function newToggle(parent, o)
	local value = o.default and true or false
	local row = create("TextButton", {
		Name = "Toggle_" .. o.key,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Theme.Card,
		LayoutOrder = o.order or 0,
		Parent = parent,
	})
	corner(row, 8)
	surface(row, 0, 0.6)
	local rowStroke = stroke(row, Accent.Dark, 1, 0.45)
	bindColor(rowStroke, "Color", "Dark")
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 9),
		Size = UDim2.new(1, -86, 0, 16),
		Text = o.title,
		Font = FONT_BOLD,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -86, 0, 24),
		Text = o.desc or "",
		TextSize = 11,
		TextColor3 = Theme.Secondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local cap = create("Frame", {
		Name = "Capsule",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Accent.Dark,
		Parent = row,
	})
	corner(cap, FULL)
	local capStroke = stroke(cap, Accent.Primary, 1, 0.6)
	local halo = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 8, 1, 8),
		Parent = cap,
	})
	corner(halo, FULL)
	local haloStroke = stroke(halo, Accent.Primary, 4, 1)
	bindColor(haloStroke, "Color", "Primary")
	local glowEntry = registerGlow(haloStroke, function()
		if value then
			return 0.55
		end
		return 0
	end)
	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Theme.Secondary,
		ZIndex = 2,
		Parent = cap,
	})
	corner(knob, FULL)

	local function render(animated)
		local bg = value and Accent.Primary or Accent.Dark
		local pos = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local kc = value and Theme.White or Theme.Secondary
		local st = value and 0.1 or 0.6
		if animated then
			tween(cap, 0.22, { BackgroundColor3 = bg })
			tween(knob, 0.3, { Position = pos, BackgroundColor3 = kc }, Enum.EasingStyle.Back)
			tween(capStroke, 0.22, { Transparency = st, Color = Accent.Primary })
		else
			cap.BackgroundColor3 = bg
			knob.Position = pos
			knob.BackgroundColor3 = kc
			capStroke.Transparency = st
			capStroke.Color = Accent.Primary
		end
		glowEntry.Refresh(animated)
	end
	bind(function()
		render(false)
	end)

	local function burst()
		local b = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = value and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Accent.Primary,
			BackgroundTransparency = 0.3,
			Parent = cap,
		})
		corner(b, FULL)
		tween(b, 0.5, { Size = UDim2.fromOffset(58, 58), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
		task.delay(dur(0.55), function()
			b:Destroy()
		end)
	end

	local api = {}
	function api.Set(v, silent, instant)
		v = v and true or false
		if v == value then
			return
		end
		value = v
		Settings[o.key] = v
		render(not instant)
		if v and not instant then
			burst()
		end
		if o.apply then
			o.apply(v)
		end
		if not silent then
			notify(o.group or "SETTINGS", o.title .. (v and " enabled successfully." or " disabled."), { force = o.forceNotify })
		end
	end
	function api.Get()
		return value
	end
	Controls[o.key] = api

	pressEffect(row, row, 0.985)
	row.Activated:Connect(function()
		api.Set(not value)
	end)
	if o.apply then
		o.apply(value)
	end
	return api
end

local function newSlider(parent, o)
	local value = o.default
	local scroll = o.scroll
	local row = create("Frame", {
		Name = "Slider_" .. o.key,
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = Theme.Card,
		LayoutOrder = o.order or 0,
		Parent = parent,
	})
	corner(row, 8)
	surface(row, 0, 0.6)
	local rowStroke = stroke(row, Accent.Dark, 1, 0.45)
	bindColor(rowStroke, "Color", "Dark")
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 9),
		Size = UDim2.new(1, -90, 0, 16),
		Text = o.title,
		Font = FONT_BOLD,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 9),
		Size = UDim2.fromOffset(70, 16),
		Font = FONT_CODE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	bindColor(valueLabel, "TextColor3", "Primary")
	local bar = create("Frame", {
		Position = UDim2.new(0, 14, 0, 44),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Accent.Dark,
		Parent = row,
	})
	corner(bar, FULL)
	bindColor(bar, "BackgroundColor3", "Dark")
	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Accent.Primary,
		Parent = bar,
	})
	corner(fill, FULL)
	bindColor(fill, "BackgroundColor3", "Primary")
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Theme.White,
		ZIndex = 2,
		Parent = bar,
	})
	corner(knob, FULL)
	local knobStroke = stroke(knob, Accent.Primary, 2, 0)
	bindColor(knobStroke, "Color", "Primary")
	local hit = create("TextButton", {
		Name = "Hit",
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 0, 32),
		Parent = row,
	})

	local function snap(v)
		v = clamp(v, o.min, o.max)
		if o.step then
			v = math.floor((v - o.min) / o.step + 0.5) * o.step + o.min
		end
		return clamp(v, o.min, o.max)
	end
	local function fmt(v)
		if o.format then
			return o.format(v)
		end
		return tostring(v)
	end
	local function render(animated)
		local a = (value - o.min) / (o.max - o.min)
		valueLabel.Text = fmt(value)
		if animated then
			tween(fill, 0.15, { Size = UDim2.new(a, 0, 1, 0) }, Enum.EasingStyle.Quad)
			tween(knob, 0.15, { Position = UDim2.new(a, 0, 0.5, 0) }, Enum.EasingStyle.Quad)
		else
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
		end
	end

	local dragging = false
	local activeInput = nil
	local function updateFromX(x)
		local w = bar.AbsoluteSize.X
		if w <= 0 then
			return
		end
		local a = clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
		local v = snap(o.min + a * (o.max - o.min))
		if v ~= value then
			value = v
			Settings[o.key] = v
			render(false)
			if o.apply then
				o.apply(v)
			end
		end
	end
	local function finish()
		if not dragging then
			return
		end
		dragging = false
		activeInput = nil
		if scroll then
			scroll.ScrollingEnabled = true
		end
		tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) }, Enum.EasingStyle.Quad)
		notify(o.group or "SETTINGS", o.title .. " set to " .. fmt(value) .. ".")
	end
	hit.InputBegan:Connect(function(input)
		if not isPointerInput(input) then
			return
		end
		dragging = true
		activeInput = input
		if scroll then
			scroll.ScrollingEnabled = false
		end
		tween(knob, 0.12, { Size = UDim2.fromOffset(21, 21) }, Enum.EasingStyle.Quad)
		updateFromX(input.Position.X)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				finish()
			end
		end)
	end)
	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch then
			if input ~= activeInput then
				return
			end
		elseif t ~= Enum.UserInputType.MouseMovement then
			return
		end
		updateFromX(input.Position.X)
	end))

	local api = {}
	function api.Set(v, silent)
		v = snap(v)
		value = v
		Settings[o.key] = v
		render(true)
		if o.apply then
			o.apply(v)
		end
		if not silent then
			notify(o.group or "SETTINGS", o.title .. " set to " .. fmt(v) .. ".")
		end
	end
	function api.Get()
		return value
	end
	Controls[o.key] = api
	render(false)
	if o.apply then
		o.apply(value)
	end
	return api
end

local function buttonGrid(parent, order)
	local f = create("Frame", {
		Name = "ButtonGrid",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 40),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = f,
	})
	return f
end

--------------------------------------------------------------------------------
-- ICONS (drawn with frames, recolorable) AND ORNAMENTS
--------------------------------------------------------------------------------
local function buildIcon(kind, parent)
	local root = create("Frame", { Name = "Icon_" .. kind, Size = UDim2.fromOffset(24, 24), Parent = parent })
	local parts = {}
	local function fillP(cx, cy, w, h, rot, rad)
		local f = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0,
			BackgroundColor3 = Theme.Secondary,
			Parent = root,
		})
		if rad then
			corner(f, rad)
		end
		parts[#parts + 1] = { Frame = f }
	end
	local function lineP(cx, cy, w, h, rot, rad, th)
		local f = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0,
			Parent = root,
		})
		if rad then
			corner(f, rad)
		end
		local s = stroke(f, Theme.Secondary, th or 1.6, 0)
		parts[#parts + 1] = { Frame = f, Stroke = s }
	end

	if kind == "home" then
		lineP(12, 16.5, 12, 9, 0, 1.5, 1.6)
		fillP(7.6, 8.6, 10, 2, -38, 1)
		fillP(16.4, 8.6, 10, 2, 38, 1)
		fillP(12, 18.5, 3, 5, 0, 1)
	elseif kind == "visual" then
		lineP(12, 12, 21, 12, 0, UDim.new(0.5, 0), 1.6)
		fillP(12, 12, 7, 7, 0, FULL)
	elseif kind == "tools" then
		fillP(12, 12, 3, 19, 45, 1.5)
		fillP(12, 12, 2, 19, -45, 1)
		lineP(17.6, 6.4, 8, 8, 0, FULL, 2)
		fillP(6.4, 6.4, 5, 5, 45, 1)
	elseif kind == "settings" then
		lineP(12, 12, 14, 14, 0, FULL, 2)
		fillP(12, 12, 4, 4, 0, FULL)
		for i = 0, 7 do
			local a = math.rad(i * 45)
			fillP(12 + math.sin(a) * 8.6, 12 - math.cos(a) * 8.6, 3, 4.2, i * 45, 1)
		end
	elseif kind == "profile" then
		fillP(12, 8, 8, 8, 0, FULL)
		fillP(12, 19, 16, 8, 0, UDim.new(0.5, 0))
	else -- about
		lineP(12, 12, 21, 21, 0, FULL, 2)
		fillP(12, 7.4, 3, 3, 0, FULL)
		fillP(12, 14.2, 3, 8, 0, 1.5)
	end

	local api = { Root = root }
	function api.SetColor(c)
		for _, p in ipairs(parts) do
			if p.Stroke then
				p.Stroke.Color = c
			else
				p.Frame.BackgroundColor3 = c
			end
		end
	end
	return api
end

local function accentFrame(parent, props)
	props.BackgroundColor3 = Accent.Primary
	props.Parent = parent
	local f = create("Frame", props)
	bindColor(f, "BackgroundColor3", "Primary")
	return f
end

local function buildOrnament(kind, p)
	if kind == "home" then
		local heights = { 6, 10, 14, 19, 24, 30 }
		for i = 1, 6 do
			accentFrame(p, {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromOffset(50 + (i - 1) * 7, 34),
				Size = UDim2.fromOffset(4, heights[i]),
				BackgroundTransparency = 0.75 - i * 0.1,
			})
		end
	elseif kind == "visual" then
		for i = 1, 18 do
			local h = 6 + math.floor(22 * math.abs(math.sin(i * 0.7)))
			accentFrame(p, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, (i - 1) * 5, 0.5, 0),
				Size = UDim2.fromOffset(2, h),
				BackgroundTransparency = 0.2 + (i % 3) * 0.2,
			})
		end
	elseif kind == "tools" then
		for r = 0, 2 do
			for c = 0, 5 do
				local bright = ((r + c) % 3 == 0)
				accentFrame(p, {
					Position = UDim2.fromOffset(44 + c * 8, 4 + r * 11),
					Size = UDim2.fromOffset(4, 4),
					BackgroundTransparency = bright and 0 or 0.72,
				})
			end
		end
	elseif kind == "settings" then
		local knobs = { 0.7, 0.3, 0.55 }
		for i = 1, 3 do
			local y = 4 + (i - 1) * 12
			accentFrame(p, {
				Position = UDim2.fromOffset(18, y + 3),
				Size = UDim2.fromOffset(72, 2),
				BackgroundTransparency = 0.65,
			})
			accentFrame(p, {
				Position = UDim2.fromOffset(18 + math.floor(64 * knobs[i]), y),
				Size = UDim2.fromOffset(8, 8),
				BackgroundTransparency = 0,
			})
		end
	elseif kind == "profile" then
		local widths = { 2, 1, 3, 1, 2, 2, 1, 3, 1, 1, 2, 3, 1, 2, 1, 1, 3, 2, 1, 2 }
		local x = 0
		for i = 1, #widths do
			x = x + widths[i] + 2
			if x > 88 then
				break
			end
			accentFrame(p, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, x, 0.5, 0),
				Size = UDim2.fromOffset(widths[i], 26),
				BackgroundTransparency = 0.25,
			})
		end
	else -- about
		local t = create("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = "0101 0011\n1010 1100\n0110 1001",
			Font = FONT_CODE,
			TextSize = 10,
			TextTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = p,
		})
		bindColor(t, "TextColor3", "Primary")
	end
end

local function pageHeader(scroll, title, subtitle, ornamentKind, order)
	local h = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = order, Parent = scroll })
	local bar = create("Frame", {
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.fromOffset(3, 32),
		BackgroundColor3 = Accent.Primary,
		Parent = h,
	})
	bindColor(bar, "BackgroundColor3", "Primary")
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -110, 0, 22),
		Text = title,
		Font = FONT_BLACK,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = h,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 21),
		Size = UDim2.new(1, -110, 0, 14),
		Text = subtitle,
		TextSize = 11,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = h,
	})
	local line = create("Frame", {
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Accent.Primary,
		Parent = h,
	})
	bindColor(line, "BackgroundColor3", "Primary")
	gradient(line, nil, NumberSequence.new({ kp(0, 0.05), kp(1, 1) }), 0)
	local orn = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(92, 36),
		Parent = h,
	})
	buildOrnament(ornamentKind, orn)
	return h
end

local function makePage(parent, id)
	local holder = create("Frame", { Name = id, Size = UDim2.fromScale(1, 1), Visible = false, Parent = parent })
	local scroll = create("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Accent.Primary,
		Parent = holder,
	})
	bindColor(scroll, "ScrollBarImageColor3", "Primary")
	padding(scroll, 8, 8, 10, 10)
	listLayout(scroll, 8)
	Pages[id] = { Holder = holder, Scroll = scroll }
	return scroll
end

--------------------------------------------------------------------------------
-- METRICS HELPERS
--------------------------------------------------------------------------------
local function readPing()
	local ok, v = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and type(v) == "number" and v > 0 then
		return math.floor(v + 0.5)
	end
	return nil
end

local function pingText()
	if Metrics.Ping then
		return Metrics.Ping .. " ms"
	end
	return "N/A"
end

local function detectPlatform()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "MOBILE"
	end
	if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "CONSOLE"
	end
	return "DESKTOP"
end

local function formatDuration(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	if h > 0 then
		return string.format("%02d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

local function loadAvatar(imageLabel, thumbType, thumbSize)
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)
		end)
		if ok and content and imageLabel.Parent then
			imageLabel.Image = content
		end
	end)
end

--------------------------------------------------------------------------------
-- MAIN PANEL
--------------------------------------------------------------------------------
UI.PanelRoot = create("Frame", {
	Name = "PanelRoot",
	Size = UDim2.fromOffset(560, 340),
	Position = UDim2.fromOffset(40, 40),
	Visible = false,
	ZIndex = 5,
	Parent = ScreenGui,
})

UI.Panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Theme.Panel,
	Active = true,
	Parent = UI.PanelRoot,
})
corner(UI.Panel, 12)
surface(UI.Panel, 0, 1)
UI.PanelScale = create("UIScale", { Scale = 0.85, Parent = UI.Panel })
makeGlow(UI.Panel, 12, 3, 0.55)

UI.PanelStroke = stroke(UI.Panel, Color3.new(1, 1, 1), 2, 0.05)
UI.PanelStrokeGrad = create("UIGradient", {
	Rotation = 0,
	Transparency = NumberSequence.new({ kp(0, 0), kp(0.5, 0.55), kp(1, 0) }),
	Parent = UI.PanelStroke,
})
bind(function()
	UI.PanelStrokeGrad.Color = ColorSequence.new({ ck(0, Accent.Primary), ck(0.5, Accent.Dark), ck(1, Accent.Primary) })
end)

-- title bar --------------------------------------------------------------------
UI.TitleBar = create("Frame", {
	Name = "TitleBar",
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 0, 40),
	BackgroundColor3 = Theme.Card,
	Active = true,
	Parent = UI.Panel,
})
corner(UI.TitleBar, 8)
surface(UI.TitleBar, 0, 0.8)
do
	local s = stroke(UI.TitleBar, Accent.Dark, 1, 0.4)
	bindColor(s, "Color", "Dark")

	local logoBox = create("Frame", { Position = UDim2.fromOffset(7, 5), Size = UDim2.fromOffset(30, 30), Parent = UI.TitleBar })
	local sk = makeSkull(logoBox, 20, nil)
	sk.Center()
	makeRing(logoBox, 4, 1.5, 160)

	UI.TitleLabel = create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(46, 5),
		Size = UDim2.new(1, -46 - 118, 0, 18),
		Text = APP_NAME,
		Font = FONT_BLACK,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = UI.TitleBar,
	})
	create("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 8, Parent = UI.TitleLabel })
	local sub = create("TextLabel", {
		Position = UDim2.fromOffset(46, 23),
		Size = UDim2.new(1, -46 - 118, 0, 12),
		Text = EDITION .. "  |  v" .. VERSION,
		Font = FONT_BOLD,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = UI.TitleBar,
	})
	bindColor(sub, "TextColor3", "Primary")

	local ctrl = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(106, 26),
		Parent = UI.TitleBar,
	})
	listLayout(ctrl, 5, Enum.FillDirection.Horizontal)

	local function windowButton(kind, order, onClick)
		local b = create("TextButton", {
			Name = "Win_" .. kind,
			Size = UDim2.fromOffset(31, 26),
			BackgroundColor3 = Theme.Panel,
			LayoutOrder = order,
			Parent = ctrl,
		})
		corner(b, 6)
		local st = stroke(b, Accent.Dark, 1, 0.3)
		bindColor(st, "Color", "Dark")
		local function bar(w, h, rot)
			local f = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(w, h),
				Rotation = rot or 0,
				BackgroundColor3 = Theme.White,
				Parent = b,
			})
			corner(f, 1)
		end
		if kind == "min" then
			bar(11, 2)
		elseif kind == "restore" then
			local sq = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(10, 10),
				Parent = b,
			})
			corner(sq, 2)
			stroke(sq, Theme.White, 1.5, 0)
		else
			bar(14, 2, 45)
			bar(14, 2, -45)
		end
		b.MouseEnter:Connect(function()
			tween(b, 0.15, { BackgroundColor3 = (kind == "close") and Accent.Primary or Accent.Dark })
		end)
		b.MouseLeave:Connect(function()
			tween(b, 0.2, { BackgroundColor3 = Theme.Panel })
		end)
		pressEffect(b, b, 0.9)
		b.Activated:Connect(onClick)
		return b
	end

	UI.BtnMin = windowButton("min", 1, function()
		Panel.SetMinimized(true)
	end)
	UI.BtnRestore = windowButton("restore", 2, function()
		if State.Minimized then
			Panel.SetMinimized(false)
		else
			Panel.ResetLayout()
			notify("PANEL", "Panel position and size reset.")
		end
	end)
	UI.BtnClose = windowButton("close", 3, function()
		Panel.Close()
	end)

	makeDraggable(UI.TitleBar, UI.PanelRoot, {
		canDrag = function()
			return not Settings.LockPanel
		end,
	})
end

-- body -------------------------------------------------------------------------
UI.Body = create("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(8, 54),
	Size = UDim2.new(1, -16, 1, -62),
	ClipsDescendants = true,
	Parent = UI.Panel,
})

local NAV = {
	{ id = "HOME", icon = "home" },
	{ id = "VISUAL", icon = "visual" },
	{ id = "TOOLS", icon = "tools" },
	{ id = "SETTINGS", icon = "settings" },
	{ id = "PROFILE", icon = "profile" },
	{ id = "ABOUT", icon = "about" },
}
local NAV_H = 44
local NavButtons = {}

local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 66, 1, 0),
	BackgroundColor3 = Theme.Card,
	Active = true,
	Parent = UI.Body,
})
corner(sidebar, 8)
surface(sidebar, 0, 0.8)
do
	local s = stroke(sidebar, Accent.Dark, 1, 0.4)
	bindColor(s, "Color", "Dark")
end

local navScroll = create("ScrollingFrame", {
	Name = "Nav",
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.new(1, -6, 1, -6),
	CanvasSize = UDim2.new(0, 0, 0, #NAV * NAV_H),
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = sidebar,
})

UI.NavIndicator = create("Frame", {
	Name = "Indicator",
	Position = UDim2.fromOffset(0, 8),
	Size = UDim2.fromOffset(3, 28),
	BackgroundColor3 = Accent.Primary,
	ZIndex = 3,
	Parent = navScroll,
})
corner(UI.NavIndicator, FULL)
bindColor(UI.NavIndicator, "BackgroundColor3", "Primary")

local content = create("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(74, 0),
	Size = UDim2.new(1, -74, 1, 0),
	BackgroundColor3 = Theme.Background,
	ClipsDescendants = true,
	Active = true,
	Parent = UI.Body,
})
corner(content, 8)
surface(content, 0, 0.9)
do
	local s = stroke(content, Accent.Dark, 1, 0.5)
	bindColor(s, "Color", "Dark")
end

local function refreshNav(animated)
	for i, nb in ipairs(NavButtons) do
		local active = (State.Page == nb.Id)
		nb.Icon.SetColor(active and Accent.Primary or Theme.Secondary)
		nb.Label.TextColor3 = active and Theme.White or Theme.Secondary
		local goal = active and 0.4 or 1
		if animated then
			tween(nb.Button, 0.25, { BackgroundTransparency = goal, BackgroundColor3 = Accent.Dark })
		else
			nb.Button.BackgroundTransparency = goal
			nb.Button.BackgroundColor3 = Accent.Dark
		end
		if active then
			local pos = UDim2.fromOffset(0, (i - 1) * NAV_H + 8)
			if animated then
				tween(UI.NavIndicator, 0.32, { Position = pos }, Enum.EasingStyle.Back)
			else
				UI.NavIndicator.Position = pos
			end
		end
	end
end
bind(function()
	refreshNav(false)
end)

local function showPage(id, instant)
	local page = Pages[id]
	if not page then
		return
	end
	if State.Page == id and not instant then
		return
	end
	State.Page = id
	for pid, p in pairs(Pages) do
		if pid ~= id then
			p.Holder.Visible = false
		end
	end
	page.Scroll.CanvasPosition = Vector2.new(0, 0)
	if instant then
		page.Holder.Position = UDim2.fromOffset(0, 0)
		page.Holder.Visible = true
		UI.PageCurtain.BackgroundTransparency = 1
	else
		page.Holder.Position = UDim2.fromOffset(28, 0)
		page.Holder.Visible = true
		UI.PageCurtain.BackgroundTransparency = 0
		tween(UI.PageCurtain, 0.34, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		tween(page.Holder, 0.38, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
	end
	refreshNav(not instant)
	if id == "HOME" then
		if Refs.UpdateStats then
			Refs.UpdateStats()
		end
		if Refs.UpdateClock then
			Refs.UpdateClock()
		end
	end
end

for i, item in ipairs(NAV) do
	local btn = create("TextButton", {
		Name = item.id,
		Position = UDim2.fromOffset(4, (i - 1) * NAV_H),
		Size = UDim2.new(1, -4, 0, NAV_H - 2),
		BackgroundColor3 = Accent.Dark,
		BackgroundTransparency = 1,
		Parent = navScroll,
	})
	corner(btn, 6)
	local icon = buildIcon(item.icon, btn)
	icon.Root.AnchorPoint = Vector2.new(0.5, 0)
	icon.Root.Position = UDim2.new(0.5, 0, 0, 3)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 12),
		Text = item.id,
		Font = FONT_BOLD,
		TextSize = 9,
		TextColor3 = Theme.Secondary,
		Parent = btn,
	})
	NavButtons[i] = { Id = item.id, Button = btn, Icon = icon, Label = label }
	pressEffect(btn, btn, 0.92)
	btn.MouseEnter:Connect(function()
		if State.Page ~= item.id then
			tween(btn, 0.15, { BackgroundTransparency = 0.78 })
		end
	end)
	btn.MouseLeave:Connect(function()
		if State.Page ~= item.id then
			tween(btn, 0.2, { BackgroundTransparency = 1 })
		end
	end)
	btn.Activated:Connect(function()
		if State.Page ~= item.id then
			flash(btn, 6)
		end
		showPage(item.id, false)
	end)
end

--------------------------------------------------------------------------------
-- PAGE: HOME
--------------------------------------------------------------------------------
local function buildHome(scroll)
	local O = counter()
	pageHeader(scroll, "HOME", "Dashboard overview", "home", O())

	-- hero card ------------------------------------------------------------------
	local hero = create("Frame", {
		Name = "Hero",
		Size = UDim2.new(1, 0, 0, 148),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(hero, 10)
	surface(hero, 0, 0.5)
	gradient(hero, ColorSequence.new(Color3.fromRGB(40, 13, 23), Color3.fromRGB(16, 9, 14)), nil, 35)
	do
		local s = stroke(hero, Accent.Primary, 1, 0.6)
		bindColor(s, "Color", "Primary")
	end

	Refs.HomeParticles = makeParticles(hero, 18, {
		gate = function()
			return State.PanelOpen and State.Page == "HOME"
		end,
	})

	Refs.HeroLines = {}
	local lineData = {
		{ y = 0.2, w = 0.45, sp = 0.22, th = 1 },
		{ y = 0.52, w = 0.3, sp = 0.34, th = 2 },
		{ y = 0.86, w = 0.55, sp = 0.16, th = 1 },
	}
	for _, d in ipairs(lineData) do
		local lf = create("Frame", {
			Position = UDim2.new(math.random(), 0, d.y, 0),
			Size = UDim2.new(d.w, 0, 0, d.th),
			BackgroundColor3 = Accent.Primary,
			Parent = hero,
		})
		bindColor(lf, "BackgroundColor3", "Primary")
		gradient(lf, nil, NumberSequence.new({ kp(0, 1), kp(0.5, 0.05), kp(1, 1) }), 0)
		Refs.HeroLines[#Refs.HeroLines + 1] = { Frame = lf, X = math.random() * 1.6 - 0.5, Speed = d.sp, Y = d.y }
	end
	addUpdater(function(dt)
		if not Settings.MovingLines or not State.PanelOpen or State.Page ~= "HOME" then
			return
		end
		for _, l in ipairs(Refs.HeroLines) do
			l.X = l.X + dt * l.Speed
			if l.X > 1.1 then
				l.X = -0.6
			end
			l.Frame.Position = UDim2.new(l.X, 0, l.Y, 0)
		end
	end)

	local logoBox = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(84, 84),
		Parent = hero,
	})
	local sk = makeSkull(logoBox, 64, nil)
	sk.Center()
	makeRing(logoBox, 12, 2, 120)
	makeRing(logoBox, 26, 1, -80)

	Refs.HeroTitle = create("TextLabel", {
		Name = "HeroTitle",
		Position = UDim2.fromOffset(122, 30),
		Size = UDim2.new(1, -134, 0, 30),
		Text = APP_NAME,
		Font = FONT_BLACK,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hero,
	})
	create("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 11, Parent = Refs.HeroTitle })

	local chip = create("Frame", {
		Position = UDim2.fromOffset(122, 66),
		Size = UDim2.fromOffset(124, 18),
		BackgroundColor3 = Accent.Dark,
		Parent = hero,
	})
	corner(chip, 4)
	bindColor(chip, "BackgroundColor3", "Dark")
	do
		local s = stroke(chip, Accent.Primary, 1, 0.3)
		bindColor(s, "Color", "Primary")
	end
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = EDITION,
		Font = FONT_BOLD,
		TextSize = 9,
		Parent = chip,
	})

	local dot = create("Frame", {
		Position = UDim2.fromOffset(124, 98),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Online,
		Parent = hero,
	})
	corner(dot, FULL)
	TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.75,
	}):Play()
	create("TextLabel", {
		Position = UDim2.fromOffset(138, 92),
		Size = UDim2.new(1, -150, 0, 20),
		Text = "INTERFACE ONLINE",
		Font = FONT_BOLD,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hero,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(122, 118),
		Size = UDim2.new(1, -134, 0, 16),
		Text = "v" .. VERSION .. "  |  Visual interface demo",
		TextSize = 10,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = hero,
	})

	-- user card ------------------------------------------------------------------
	local uc = create("Frame", {
		Name = "UserCard",
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = Theme.Card,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(uc, 10)
	surface(uc, 0, 0.5)
	do
		local s = stroke(uc, Accent.Dark, 1, 0.35)
		bindColor(s, "Color", "Dark")
	end
	local avBox = create("Frame", { Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(56, 56), Parent = uc })
	local av = create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Image = "",
		Parent = avBox,
	})
	corner(av, FULL)
	do
		local s = stroke(av, Accent.Primary, 2, 0)
		bindColor(s, "Color", "Primary")
	end
	makeRing(avBox, 9, 1.5, 100)
	loadAvatar(av, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	create("TextLabel", {
		Position = UDim2.fromOffset(86, 11),
		Size = UDim2.new(1, -96, 0, 20),
		Text = LocalPlayer.DisplayName,
		Font = FONT_BOLD,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = uc,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(86, 32),
		Size = UDim2.new(1, -96, 0, 16),
		Text = "@" .. LocalPlayer.Name,
		TextSize = 12,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = uc,
	})
	local idLabel = create("TextLabel", {
		Position = UDim2.fromOffset(86, 50),
		Size = UDim2.new(1, -96, 0, 16),
		Text = "USER ID  " .. tostring(LocalPlayer.UserId),
		Font = FONT_CODE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = uc,
	})
	bindColor(idLabel, "TextColor3", "Primary")

	-- stat cards -----------------------------------------------------------------
	sectionLabel(scroll, "LIVE STATISTICS", O())
	local grid = create("Frame", {
		Name = "Stats",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = O(),
		Parent = scroll,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 80),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	local function statCard(order, label, sub, valueFont, valueSize)
		local c = create("Frame", { Name = "Stat_" .. label, LayoutOrder = order, BackgroundColor3 = Theme.Card, Parent = grid })
		corner(c, 10)
		surface(c, 0, 0.5)
		local st = stroke(c, Accent.Dark, 1, 0.35)
		bindColor(st, "Color", "Dark")
		local strip = create("Frame", {
			Position = UDim2.fromOffset(0, 10),
			Size = UDim2.fromOffset(3, 18),
			BackgroundColor3 = Accent.Primary,
			Parent = c,
		})
		bindColor(strip, "BackgroundColor3", "Primary")
		-- corner bracket decoration
		local b1 = create("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(10, 1),
			BackgroundColor3 = Accent.Primary,
			BackgroundTransparency = 0.3,
			Parent = c,
		})
		bindColor(b1, "BackgroundColor3", "Primary")
		local b2 = create("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(1, 10),
			BackgroundColor3 = Accent.Primary,
			BackgroundTransparency = 0.3,
			Parent = c,
		})
		bindColor(b2, "BackgroundColor3", "Primary")
		create("TextLabel", {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -30, 0, 12),
			Text = label,
			Font = FONT_BOLD,
			TextSize = 10,
			TextColor3 = Theme.Secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = c,
		})
		local val = create("TextLabel", {
			Position = UDim2.fromOffset(12, 24),
			Size = UDim2.new(1, -20, 0, 28),
			Text = "--",
			Font = valueFont or FONT_BLACK,
			TextSize = valueSize or 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = c,
		})
		local subL = create("TextLabel", {
			Position = UDim2.fromOffset(12, 56),
			Size = UDim2.new(1, -20, 0, 14),
			Text = sub,
			TextSize = 10,
			TextColor3 = Theme.Secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = c,
		})
		return c, val, subL
	end

	local fpsCard, fpsVal, fpsSub = statCard(1, "FPS", "frames per second")
	local _, pingVal, pingSub = statCard(2, "PING", "server latency")
	local _, timeVal, timeSub = statCard(3, "LOCAL TIME", "--", FONT_CODE, 20)
	local _, sessVal, sessSub = statCard(4, "SESSION", "interface uptime", FONT_CODE, 20)

	-- sparkline inside the FPS card
	local spark = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -26),
		Size = UDim2.fromOffset(64, 26),
		Parent = fpsCard,
	})
	local sparkBars = {}
	for i = 1, 16 do
		local b = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, (i - 1) * 4, 1, 0),
			Size = UDim2.fromOffset(3, 2),
			BackgroundColor3 = Accent.Primary,
			Parent = spark,
		})
		bindColor(b, "BackgroundColor3", "Primary")
		sparkBars[i] = b
	end

	-- system info ----------------------------------------------------------------
	sectionLabel(scroll, "SYSTEM INFO", O())
	local infoPlatform = newInfoRow(scroll, "PLATFORM", detectPlatform(), O())
	local infoView = newInfoRow(scroll, "VIEWPORT", "--", O())
	local infoPlayers = newInfoRow(scroll, "PLAYERS", "--", O())
	newInfoRow(scroll, "PLACE ID", tostring(game.PlaceId), O())
	newInfoRow(scroll, "INTERFACE", "ONLINE  v" .. VERSION, O())

	function Refs.UpdateStats()
		fpsVal.Text = tostring(Metrics.FPS)
		fpsVal.TextColor3 = (Metrics.FPS < 30) and Accent.Primary or Theme.White
		if Metrics.FPS >= 55 then
			fpsSub.Text = "smooth"
		elseif Metrics.FPS >= 30 then
			fpsSub.Text = "playable"
		else
			fpsSub.Text = "low frame rate"
		end
		pingVal.Text = pingText()
		pingSub.Text = Metrics.Ping and "data ping" or "not available here"
		sessVal.Text = formatDuration(os.time() - Metrics.StartTime)
		sessSub.Text = "interface uptime"
		local hist = Metrics.History
		for i = 1, 16 do
			local v = hist[#hist - 16 + i] or 0
			local h = math.max(2, math.floor(clamp(v / 75, 0, 1) * 26))
			sparkBars[i].Size = UDim2.fromOffset(3, h)
		end
		local s = screenSize()
		infoView.Text = string.format("%dx%d", math.floor(s.X), math.floor(s.Y))
		infoPlatform.Text = detectPlatform()
		infoPlayers.Text = string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers)
	end
	function Refs.UpdateClock()
		timeVal.Text = os.date("%H:%M:%S")
		timeSub.Text = os.date("%a, %d %b %Y")
	end
end

--------------------------------------------------------------------------------
-- PAGE: VISUAL
--------------------------------------------------------------------------------
local function buildVisual(scroll)
	local O = counter()
	local G = "VISUAL SETTINGS"
	pageHeader(scroll, "VISUAL", "Interface effects and ornaments", "visual", O())

	sectionLabel(scroll, "EFFECTS", O())
	newToggle(scroll, {
		key = "Particles", title = "Particle Field", group = G, order = O(), default = Defaults.Particles,
		desc = "Floating red particles on the Home banner.",
		apply = function(v)
			if Refs.HomeParticles then
				Refs.HomeParticles.SetEnabled(v)
			end
		end,
	})
	newToggle(scroll, {
		key = "MovingLines", title = "Moving Red Lines", group = G, order = O(), default = Defaults.MovingLines,
		desc = "Animated digital lines across the Home banner.",
		apply = function(v)
			if Refs.HeroLines then
				for _, l in ipairs(Refs.HeroLines) do
					l.Frame.Visible = v
				end
			end
		end,
	})
	newToggle(scroll, {
		key = "AnimatedBorder", title = "Animated Border", group = G, order = O(), default = Defaults.AnimatedBorder,
		desc = "Rotating gradient light along the panel border.",
	})
	newToggle(scroll, {
		key = "MovingLight", title = "Moving Light", group = G, order = O(), default = Defaults.MovingLight,
		desc = "A faint light band sweeping down the panel.",
		apply = function(v)
			if UI.LightHolder then
				UI.LightHolder.Visible = v
			end
		end,
	})
	newToggle(scroll, {
		key = "LogoRing", title = "Logo Rings", group = G, order = O(), default = Defaults.LogoRing,
		desc = "Rotating rings around every skull logo and avatar.",
		apply = function(v)
			for _, r in ipairs(Rings) do
				if not r.Temp then
					r.Frame.Visible = v
				end
			end
		end,
	})
	newToggle(scroll, {
		key = "Pulse", title = "Button Pulse", group = G, order = O(), default = Defaults.Pulse,
		desc = "Subtle pulse on the floating skull button.",
		apply = function(v)
			if Float.SetPulse then
				Float.SetPulse(v)
			end
		end,
	})
	newToggle(scroll, {
		key = "GlitchFx", title = "Glitch Effect", group = G, order = O(), default = Defaults.GlitchFx,
		desc = "Occasional glitch on titles while the panel is open.",
	})
	newToggle(scroll, {
		key = "NeonGlow", title = "Neon Glow", group = G, order = O(), default = Defaults.NeonGlow,
		desc = "Soft red halo around the panel, button and toggles.",
		apply = function()
			refreshGlows()
		end,
	})

	sectionLabel(scroll, "INTENSITY", O())
	newSlider(scroll, {
		key = "GlowIntensity", title = "Glow Intensity", group = G, order = O(), scroll = scroll,
		min = 0, max = 100, step = 5, default = Defaults.GlowIntensity,
		format = function(v)
			return string.format("%d%%", v)
		end,
		apply = function()
			refreshGlows()
		end,
	})
	newSlider(scroll, {
		key = "ParticleDensity", title = "Particle Density", group = G, order = O(), scroll = scroll,
		min = 10, max = 100, step = 10, default = Defaults.ParticleDensity,
		format = function(v)
			return string.format("%d%%", v)
		end,
		apply = function(v)
			if Refs.HomeParticles then
				Refs.HomeParticles.SetDensity(v / 100)
			end
		end,
	})
end

--------------------------------------------------------------------------------
-- PAGE: TOOLS
--------------------------------------------------------------------------------
local SampleNotes = {
	{ "BAXTARA SYSTEM", "Interface successfully initialized." },
	{ "VISUAL SETTINGS", "Effect enabled successfully." },
	{ "TOOLS", "Utility module responded normally." },
	{ "SYSTEM CHECK", "All interface modules are stable." },
	{ "THEME ENGINE", "Accent color profile loaded." },
}

local function buildTools(scroll)
	local O = counter()
	pageHeader(scroll, "TOOLS", "Interface utilities and demos", "tools", O())

	sectionLabel(scroll, "NOTIFICATIONS", O())
	local g1 = buttonGrid(scroll, O())
	local sampleIndex = 0
	newButton(g1, {
		text = "TEST NOTIFY", order = 1,
		onClick = function()
			sampleIndex = sampleIndex % #SampleNotes + 1
			local s = SampleNotes[sampleIndex]
			notify(s[1], s[2], { force = true })
		end,
	})
	newButton(g1, {
		text = "STACK x3", order = 2,
		onClick = function()
			for i = 1, 3 do
				local s = SampleNotes[(i + sampleIndex) % #SampleNotes + 1]
				notify(s[1], s[2], { force = true, duration = 3 + i * 0.5 })
				task.wait(0.15)
			end
		end,
	})
	newButton(g1, {
		text = "CLEAR ALL", order = 3,
		onClick = function()
			for i = #Notify.List, 1, -1 do
				dismissNotification(Notify.List[i])
			end
		end,
	})
	newButton(g1, {
		text = "LONG TEXT", order = 4,
		onClick = function()
			notify("BAXTARA SYSTEM", "This is a longer description to preview how wrapped text looks inside a notification card.", { force = true })
		end,
	})

	sectionLabel(scroll, "INTERFACE", O())
	newToggle(scroll, {
		key = "MiniHud", title = "Mini HUD", group = "TOOLS", order = O(), default = Defaults.MiniHud,
		desc = "Small draggable FPS and ping readout.",
		apply = function(v)
			if Hud.Frame then
				Hud.Frame.Visible = v
				if v then
					Hud.Update()
				end
			end
		end,
	})
	local g2 = buttonGrid(scroll, O())
	newButton(g2, {
		text = "TRIGGER GLITCH", order = 1,
		onClick = function()
			glitch(UI.TitleLabel, 0.5, 3)
			if Refs.HeroTitle then
				glitch(Refs.HeroTitle, 0.5, 5)
			end
		end,
	})
	newButton(g2, {
		text = "REPLAY INTRO", order = 2,
		onClick = function()
			Refs.PlayIntro(function()
				notify("BAXTARA SYSTEM", "Intro replay finished.")
			end)
		end,
	})
	newButton(g2, {
		text = "CENTER PANEL", order = 3,
		onClick = function()
			Panel.Center(true)
			notify("PANEL", "Panel centered on screen.")
		end,
	})
	newButton(g2, {
		text = "COUNT UI", order = 4,
		onClick = function()
			notify("UI INFO", #ScreenGui:GetDescendants() .. " interface elements are loaded.")
		end,
	})

	sectionLabel(scroll, "SESSION TIMER", O())
	local sw = create("Frame", {
		Name = "Stopwatch",
		Size = UDim2.new(1, 0, 0, 104),
		BackgroundColor3 = Theme.Card,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(sw, 10)
	surface(sw, 0, 0.5)
	do
		local s = stroke(sw, Accent.Dark, 1, 0.35)
		bindColor(s, "Color", "Dark")
	end
	local swLabel = create("TextLabel", {
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 34),
		Text = "00:00.00",
		Font = FONT_CODE,
		TextSize = 28,
		Parent = sw,
	})
	local running, elapsed = false, 0
	local startBtn
	startBtn = newButton(sw, {
		text = "START", primary = true, size = UDim2.new(0.5, -16, 0, 34),
		onClick = function()
			running = not running
			startBtn.Text = running and "STOP" or "START"
		end,
	})
	startBtn.Position = UDim2.new(0, 10, 1, -44)
	local resetBtn = newButton(sw, {
		text = "RESET", size = UDim2.new(0.5, -16, 0, 34),
		onClick = function()
			running = false
			elapsed = 0
			startBtn.Text = "START"
			swLabel.Text = "00:00.00"
		end,
	})
	resetBtn.Position = UDim2.new(0.5, 6, 1, -44)
	addUpdater(function(dt)
		if running then
			elapsed = elapsed + dt
			if State.PanelOpen and State.Page == "TOOLS" then
				local m = math.floor(elapsed / 60)
				local s = math.floor(elapsed % 60)
				local cs = math.floor((elapsed * 100) % 100)
				swLabel.Text = string.format("%02d:%02d.%02d", m, s, cs)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- PAGE: SETTINGS
--------------------------------------------------------------------------------
local function setAccent(index, silent)
	local p = AccentPresets[index]
	if not p then
		return
	end
	Settings.Accent = index
	Accent.Primary = p.primary
	Accent.Dark = p.dark
	refreshAccent()
	if Refs.UpdateSwatches then
		Refs.UpdateSwatches()
	end
	if not silent then
		notify("THEME ENGINE", "Accent color set to " .. p.name .. ".")
	end
end

local function buildSettings(scroll)
	local O = counter()
	local G = "SETTINGS"
	pageHeader(scroll, "SETTINGS", "Colors, transparency and behavior", "settings", O())

	sectionLabel(scroll, "THEME", O())
	local swCard = create("Frame", {
		Name = "Swatches",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Card,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(swCard, 10)
	surface(swCard, 0, 0.6)
	padding(swCard, 10, 10, 10, 10)
	create("UIGridLayout", {
		CellSize = UDim2.new(0.2, -7, 0, 56),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = swCard,
	})
	local swatchRefs = {}
	for i, preset in ipairs(AccentPresets) do
		local b = create("TextButton", { Name = preset.name, LayoutOrder = i, Parent = swCard })
		local circle = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 2),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = preset.primary,
			Parent = b,
		})
		corner(circle, FULL)
		local ring = stroke(circle, Theme.White, 2, 1)
		create("TextLabel", {
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 0, 14),
			Text = preset.name,
			Font = FONT_BOLD,
			TextSize = 8,
			TextColor3 = Theme.Secondary,
			Parent = b,
		})
		pressEffect(b, circle, 0.88)
		b.Activated:Connect(function()
			setAccent(i, false)
		end)
		swatchRefs[i] = { Ring = ring, Circle = circle }
	end
	function Refs.UpdateSwatches()
		for i, r in ipairs(swatchRefs) do
			tween(r.Ring, 0.2, { Transparency = (i == Settings.Accent) and 0 or 1 })
		end
	end
	for i, r in ipairs(swatchRefs) do
		r.Ring.Transparency = (i == Settings.Accent) and 0 or 1
	end

	sectionLabel(scroll, "PANEL", O())
	newSlider(scroll, {
		key = "Transparency", title = "Panel Transparency", group = G, order = O(), scroll = scroll,
		min = 0, max = 60, step = 5, default = Defaults.Transparency,
		format = function(v)
			return string.format("%d%%", v)
		end,
		apply = function()
			applySurfaces()
		end,
	})
	newSlider(scroll, {
		key = "PanelSize", title = "Panel Size", group = G, order = O(), scroll = scroll,
		min = 80, max = 110, step = 5, default = Defaults.PanelSize,
		format = function(v)
			return string.format("%d%%", v)
		end,
		apply = function()
			Panel.Layout()
		end,
	})
	newSlider(scroll, {
		key = "AnimSpeed", title = "Animation Speed", group = G, order = O(), scroll = scroll,
		min = 0.5, max = 2, step = 0.1, default = Defaults.AnimSpeed,
		format = function(v)
			return string.format("%.1fx", v)
		end,
	})

	sectionLabel(scroll, "BEHAVIOR", O())
	newToggle(scroll, {
		key = "Notifications", title = "Notifications", group = G, order = O(), default = Defaults.Notifications,
		desc = "Show slide-in notification cards.", forceNotify = true,
	})
	newToggle(scroll, {
		key = "FloatingButton", title = "Floating Button", group = G, order = O(), default = Defaults.FloatingButton,
		desc = "Show the skull button while the panel is closed.",
		apply = function()
			Float.Refresh()
		end,
	})
	newToggle(scroll, {
		key = "LockPanel", title = "Lock Panel Position", group = G, order = O(), default = Defaults.LockPanel,
		desc = "Disable dragging the panel by its title bar.",
	})

	sectionLabel(scroll, "DATA", O())
	newButton(scroll, {
		text = "RESET ALL SETTINGS", primary = true, order = O(),
		onClick = function()
			for key, ctrl in pairs(Controls) do
				if Defaults[key] ~= nil then
					ctrl.Set(Defaults[key], true)
				end
			end
			setAccent(Defaults.Accent, true)
			notify("SETTINGS", "All settings restored to defaults.", { force = true })
		end,
	})
end

--------------------------------------------------------------------------------
-- PAGE: PROFILE
--------------------------------------------------------------------------------
local function buildProfile(scroll)
	local O = counter()
	pageHeader(scroll, "PROFILE", "Your Roblox account", "profile", O())

	local card = create("Frame", {
		Name = "ProfileCard",
		Size = UDim2.new(1, 0, 0, 118),
		BackgroundColor3 = Theme.Card,
		ClipsDescendants = true,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(card, 10)
	surface(card, 0, 0.5)
	do
		local s = stroke(card, Accent.Dark, 1, 0.35)
		bindColor(s, "Color", "Dark")
	end
	local box = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(84, 84),
		Parent = card,
	})
	local av = create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Parent = box,
	})
	corner(av, FULL)
	do
		local s = stroke(av, Accent.Primary, 2, 0)
		bindColor(s, "Color", "Primary")
	end
	makeRing(box, 14, 2, 110)
	loadAvatar(av, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	create("TextLabel", {
		Position = UDim2.fromOffset(122, 26),
		Size = UDim2.new(1, -132, 0, 24),
		Text = LocalPlayer.DisplayName,
		Font = FONT_BLACK,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(122, 52),
		Size = UDim2.new(1, -132, 0, 16),
		Text = "@" .. LocalPlayer.Name,
		TextSize = 12,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	local tag = create("TextLabel", {
		Position = UDim2.fromOffset(122, 72),
		Size = UDim2.new(1, -132, 0, 16),
		Text = "VERIFIED INTERFACE USER",
		Font = FONT_BOLD,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	bindColor(tag, "TextColor3", "Primary")

	sectionLabel(scroll, "ACCOUNT DETAILS", O())
	newInfoRow(scroll, "DISPLAY NAME", LocalPlayer.DisplayName, O())
	newInfoRow(scroll, "USERNAME", LocalPlayer.Name, O())
	newInfoRow(scroll, "USER ID", tostring(LocalPlayer.UserId), O())
	newInfoRow(scroll, "ACCOUNT AGE", LocalPlayer.AccountAge .. " days", O())
	newInfoRow(scroll, "MEMBERSHIP", LocalPlayer.MembershipType.Name, O())
	newInfoRow(scroll, "LOCALE", LocalPlayer.LocaleId, O())
	newInfoRow(scroll, "DEVICE", detectPlatform(), O())
	newInfoRow(scroll, "SESSION START", os.date("%H:%M:%S", Metrics.StartTime), O())
end

--------------------------------------------------------------------------------
-- PAGE: ABOUT
--------------------------------------------------------------------------------
local function buildAbout(scroll)
	local O = counter()
	pageHeader(scroll, "ABOUT", "BAXTARA X CHEAT information", "about", O())

	local card = create("Frame", {
		Name = "LogoCard",
		Size = UDim2.new(1, 0, 0, 156),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(card, 10)
	surface(card, 0, 0.5)
	gradient(card, ColorSequence.new(Color3.fromRGB(40, 13, 23), Color3.fromRGB(16, 9, 14)), nil, 70)
	do
		local s = stroke(card, Accent.Primary, 1, 0.6)
		bindColor(s, "Color", "Primary")
	end
	local box = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(84, 84),
		Parent = card,
	})
	makeSkull(box, 60, nil).Center()
	makeRing(box, 12, 2, 120)
	makeRing(box, 26, 1, -90)
	create("TextLabel", {
		Position = UDim2.fromOffset(0, 108),
		Size = UDim2.new(1, 0, 0, 22),
		Text = APP_NAME,
		Font = FONT_BLACK,
		TextSize = 18,
		Parent = card,
	})
	local ed = create("TextLabel", {
		Position = UDim2.fromOffset(0, 130),
		Size = UDim2.new(1, 0, 0, 16),
		Text = EDITION .. "  |  v" .. VERSION,
		Font = FONT_BOLD,
		TextSize = 10,
		Parent = card,
	})
	bindColor(ed, "TextColor3", "Primary")

	sectionLabel(scroll, "DETAILS", O())
	newInfoRow(scroll, "VERSION", VERSION, O())
	newInfoRow(scroll, "EDITION", "BLOOD EVIL", O())
	newInfoRow(scroll, "DEVELOPER", "BAXTARA", O())
	newInfoRow(scroll, "TYPE", "Visual interface demo", O())
	newInfoRow(scroll, "ENGINE", "Roblox Luau UI", O())
	newInfoRow(scroll, "HOTKEY", "RightShift (keyboard)", O())

	sectionLabel(scroll, "DESCRIPTION", O())
	local desc = create("Frame", {
		Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Card,
		LayoutOrder = O(),
		Parent = scroll,
	})
	corner(desc, 10)
	surface(desc, 0, 0.6)
	padding(desc, 12, 10, 12, 10)
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "BAXTARA X CHEAT is a dark, cyber-themed interface showcase: custom skull logo, animated borders, "
			.. "glitch intro, premium toggles, sliders and a notification system. Every control in this panel only "
			.. "changes the interface itself. It contains no gameplay features and does not affect other players.",
		TextSize = 12,
		TextColor3 = Theme.Secondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = desc,
	})
end

--------------------------------------------------------------------------------
-- BUILD PAGES + PAGE CURTAIN
--------------------------------------------------------------------------------
buildHome(makePage(content, "HOME"))
buildVisual(makePage(content, "VISUAL"))
buildTools(makePage(content, "TOOLS"))
buildSettings(makePage(content, "SETTINGS"))
buildProfile(makePage(content, "PROFILE"))
buildAbout(makePage(content, "ABOUT"))

UI.PageCurtain = create("Frame", {
	Name = "PageCurtain",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Theme.Background,
	BackgroundTransparency = 1,
	ZIndex = 20,
	Parent = content,
})

-- moving light band over the whole panel
UI.LightHolder = create("Frame", {
	Name = "LightHolder",
	Size = UDim2.fromScale(1, 1),
	ClipsDescendants = true,
	ZIndex = 30,
	Parent = UI.Panel,
})
UI.Light = create("Frame", {
	Name = "Light",
	Position = UDim2.fromOffset(0, -90),
	Size = UDim2.new(1, 0, 0, 90),
	BackgroundColor3 = Theme.White,
	Parent = UI.LightHolder,
})
gradient(UI.Light, nil, NumberSequence.new({ kp(0, 1), kp(0.5, 0.94), kp(1, 1) }), 90)
UI.LightHolder.Visible = Settings.MovingLight

-- open/close curtain (fade effect)
UI.PanelCurtain = create("Frame", {
	Name = "PanelCurtain",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Theme.Panel,
	BackgroundTransparency = 0,
	ZIndex = 60,
	Parent = UI.Panel,
})
corner(UI.PanelCurtain, 12)

--------------------------------------------------------------------------------
-- FLOATING BUTTON
--------------------------------------------------------------------------------
do
	local root = create("TextButton", {
		Name = "FloatingButton",
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.fromOffset(16, 130),
		Visible = false,
		ZIndex = 10,
		Parent = ScreenGui,
	})
	Float.Root = root
	local face = create("Frame", {
		Name = "Face",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = root,
	})
	Float.Scale = create("UIScale", { Scale = 0, Parent = face })

	local pulse = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.86),
		Parent = face,
	})
	corner(pulse, FULL)
	local pulseStroke = stroke(pulse, Accent.Primary, 2, 0.45)
	bindColor(pulseStroke, "Color", "Primary")

	local core = create("Frame", {
		Name = "Core",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.86),
		BackgroundColor3 = Theme.Background,
		Parent = face,
	})
	corner(core, FULL)
	makeGlow(core, 999, 3, 0.6)
	local coreStroke = stroke(core, Accent.Primary, 2, 0.1)
	bindColor(coreStroke, "Color", "Primary")
	local pressScale = create("UIScale", { Scale = 1, Parent = core })
	makeSkull(core, 30, nil).Center()
	makeRing(face, 0, 2, 150)

	local pulseTweens = {}
	function Float.SetPulse(v)
		for _, t in ipairs(pulseTweens) do
			t:Cancel()
		end
		pulseTweens = {}
		pulse.Visible = v
		if v then
			pulse.Size = UDim2.fromScale(0.86, 0.86)
			pulseStroke.Transparency = 0.45
			local info = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, false, 0)
			pulseTweens[1] = TweenService:Create(pulse, info, { Size = UDim2.fromScale(1.35, 1.35) })
			pulseTweens[2] = TweenService:Create(pulseStroke, info, { Transparency = 1 })
			pulseTweens[1]:Play()
			pulseTweens[2]:Play()
		end
	end

	root.InputBegan:Connect(function(input)
		if isPointerInput(input) then
			tween(pressScale, 0.08, { Scale = 0.88 }, Enum.EasingStyle.Quad)
			tween(core, 0.1, { BackgroundColor3 = Accent.Dark }, Enum.EasingStyle.Quad)
		end
	end)
	local function release()
		tween(pressScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(core, 0.28, { BackgroundColor3 = Theme.Background }, Enum.EasingStyle.Quad)
	end
	root.InputEnded:Connect(function(input)
		if isPointerInput(input) then
			release()
		end
	end)

	makeDraggable(root, root, {
		threshold = 4,
		onEnd = function(moved)
			if moved < 8 then
				Panel.Open()
			end
		end,
	})

	function Float.Refresh()
		Float.Token = (Float.Token or 0) + 1
		local token = Float.Token
		local show = (not State.PanelOpen) and Settings.FloatingButton and State.Ready
		if show then
			root.Visible = true
			tween(Float.Scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		else
			tween(Float.Scale, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(dur(0.22), function()
				if Float.Token == token then
					root.Visible = false
				end
			end)
		end
	end

	Float.SetPulse(Settings.Pulse)
end

--------------------------------------------------------------------------------
-- MINI HUD
--------------------------------------------------------------------------------
do
	local f = create("Frame", {
		Name = "MiniHud",
		Position = UDim2.fromOffset(12, 96),
		Size = UDim2.fromOffset(176, 30),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.15,
		Active = true,
		Visible = Settings.MiniHud,
		ZIndex = 9,
		Parent = ScreenGui,
	})
	corner(f, 8)
	local s = stroke(f, Accent.Primary, 1.2, 0.2)
	bindColor(s, "Color", "Primary")
	local bar = create("Frame", {
		Position = UDim2.fromOffset(7, 7),
		Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = Accent.Primary,
		Parent = f,
	})
	corner(bar, FULL)
	bindColor(bar, "BackgroundColor3", "Primary")
	Hud.Label = create("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Font = FONT_CODE,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = f,
	})
	Hud.Frame = f
	function Hud.Update()
		Hud.Label.Text = string.format("FPS %d  |  PING %s", Metrics.FPS, pingText())
	end
	Hud.Update()
	makeDraggable(f, f, {})
end

--------------------------------------------------------------------------------
-- PANEL MANAGEMENT: layout, open / close / minimize
--------------------------------------------------------------------------------
Panel.W, Panel.H, Panel.CurH = 560, 340, 340
local MIN_H = 56

function Panel.Layout()
	local screen = screenSize()
	local w = clamp(screen.X - 24, 300, 600)
	local h = clamp(screen.Y - 24, 250, 390)
	local k = Settings.PanelSize / 100
	w = clamp(math.floor(w * k), 280, screen.X - 8)
	h = clamp(math.floor(h * k), 230, screen.Y - 8)
	Panel.W, Panel.H = w, h
	Panel.CurH = State.Minimized and MIN_H or h
	UI.PanelRoot.Size = UDim2.fromOffset(w, Panel.CurH)
	Panel.Clamp(false)
	UI.NotifyHolder.Size = UDim2.new(0, clamp(math.floor(screen.X * 0.44), 200, 270), 1, -110)
end

function Panel.Clamp(animated)
	local screen = screenSize()
	local p = UI.PanelRoot.Position
	local x = clamp(p.X.Offset, 4, screen.X - Panel.W - 4)
	local y = clamp(p.Y.Offset, 4, screen.Y - Panel.CurH - 4)
	local goal = UDim2.fromOffset(x, y)
	if animated then
		tween(UI.PanelRoot, 0.3, { Position = goal })
	else
		UI.PanelRoot.Position = goal
	end
end

function Panel.Center(animated)
	local screen = screenSize()
	local goal = UDim2.fromOffset(
		math.floor((screen.X - Panel.W) / 2),
		math.floor((screen.Y - Panel.CurH) / 2)
	)
	if animated then
		tween(UI.PanelRoot, 0.4, { Position = goal })
	else
		UI.PanelRoot.Position = goal
	end
end

function Panel.ResetLayout()
	if Controls.PanelSize then
		Controls.PanelSize.Set(Defaults.PanelSize, true)
	end
	Panel.Layout()
	Panel.Center(true)
end

function Panel.SetMinimized(v)
	if State.Minimized == v then
		return
	end
	State.Minimized = v
	if v then
		Panel.CurH = MIN_H
		tween(UI.PanelRoot, 0.32, { Size = UDim2.fromOffset(Panel.W, MIN_H) }, Enum.EasingStyle.Quint)
		task.delay(dur(0.32), function()
			if State.Minimized then
				UI.Body.Visible = false
			end
		end)
	else
		Panel.CurH = Panel.H
		UI.Body.Visible = true
		tween(UI.PanelRoot, 0.38, { Size = UDim2.fromOffset(Panel.W, Panel.H) }, Enum.EasingStyle.Quint)
		task.delay(dur(0.4), function()
			if not State.Minimized then
				Panel.Clamp(true)
			end
		end)
	end
end

function Panel.Open()
	if State.PanelOpen or not State.Ready then
		return
	end
	State.PanelOpen = true
	State.OpenToken = State.OpenToken + 1
	Panel.Clamp(false)
	UI.PanelRoot.Visible = true
	UI.PanelScale.Scale = 0.82
	UI.PanelCurtain.BackgroundTransparency = 0
	tween(UI.PanelScale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(UI.PanelCurtain, 0.34, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	Float.Refresh()
	if State.Page == "HOME" then
		Refs.UpdateStats()
		Refs.UpdateClock()
	end
end

function Panel.Close()
	if not State.PanelOpen then
		return
	end
	-- never strand a touch user without a way back in
	if not Settings.FloatingButton and not UserInputService.KeyboardEnabled then
		Panel.SetMinimized(true)
		notify("PANEL", "Floating button is hidden, so the panel was minimized instead.", { force = true })
		return
	end
	State.PanelOpen = false
	State.OpenToken = State.OpenToken + 1
	local token = State.OpenToken
	tween(UI.PanelScale, 0.26, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(UI.PanelCurtain, 0.26, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad)
	Float.Refresh()
	task.delay(dur(0.28), function()
		if State.OpenToken == token and not State.PanelOpen then
			UI.PanelRoot.Visible = false
		end
	end)
end

track(UserInputService.InputBegan:Connect(function(input, processed)
	if processed or State.Intro then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift and State.Ready then
		if State.PanelOpen then
			Panel.Close()
		else
			Panel.Open()
		end
	end
end))

track(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	Panel.Layout()
	local screen = screenSize()
	for _, g in ipairs({ Float.Root, Hud.Frame }) do
		local size = g.AbsoluteSize
		local p = g.Position
		g.Position = UDim2.fromOffset(
			clamp(p.X.Offset, 4, screen.X - size.X - 4),
			clamp(p.Y.Offset, 4, screen.Y - size.Y - 4)
		)
	end
end))

--------------------------------------------------------------------------------
-- CONTINUOUS ANIMATION + METRICS
--------------------------------------------------------------------------------
do
	local lightT = 0
	local glitchTimer = 5
	local clockAcc = 0
	addUpdater(function(dt)
		-- animated border
		if State.PanelOpen and Settings.AnimatedBorder then
			UI.PanelStrokeGrad.Rotation = (UI.PanelStrokeGrad.Rotation + dt * 70) % 360
		end
		-- moving light band
		if State.PanelOpen and Settings.MovingLight and not State.Minimized then
			lightT = lightT + dt
			local travel = Panel.CurH + 180
			local y = ((lightT * 85) % travel) - 90
			UI.Light.Position = UDim2.fromOffset(0, y)
		end
		-- periodic glitch on titles
		if State.PanelOpen and Settings.GlitchFx then
			glitchTimer = glitchTimer - dt
			if glitchTimer <= 0 then
				glitchTimer = 6 + math.random() * 5
				glitch(UI.TitleLabel, 0.25, 2)
				if State.Page == "HOME" and Refs.HeroTitle and not State.Minimized then
					glitch(Refs.HeroTitle, 0.3, 4)
				end
			end
		end
		-- fps / ping
		Metrics.Frames = Metrics.Frames + 1
		Metrics.Acc = Metrics.Acc + dt
		if Metrics.Acc >= 0.5 then
			Metrics.FPS = math.floor(Metrics.Frames / Metrics.Acc + 0.5)
			Metrics.Frames = 0
			Metrics.Acc = 0
			Metrics.Ping = readPing()
			local h = Metrics.History
			h[#h + 1] = Metrics.FPS
			if #h > 40 then
				table.remove(h, 1)
			end
			if Hud.Frame.Visible then
				Hud.Update()
			end
			if State.PanelOpen and State.Page == "HOME" and not State.Minimized then
				Refs.UpdateStats()
			end
		end
		clockAcc = clockAcc + dt
		if clockAcc >= 0.25 then
			clockAcc = 0
			if State.PanelOpen and State.Page == "HOME" and not State.Minimized then
				Refs.UpdateClock()
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- LOADING INTRO
--------------------------------------------------------------------------------
local STAGES = { "INITIALIZING SYSTEM", "LOADING INTERFACE", "PREPARING MODULES", "SYSTEM READY" }

local function stageFor(p)
	if p < 0.28 then
		return 1
	elseif p < 0.58 then
		return 2
	elseif p < 0.97 then
		return 3
	end
	return 4
end

function Refs.PlayIntro(onDone)
	if State.Intro then
		return
	end
	State.Intro = true

	local overlay = create("CanvasGroup", {
		Name = "Intro",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Active = true,
		ZIndex = 100,
		Parent = ScreenGui,
	})
	local band = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = overlay,
	})
	gradient(band, ColorSequence.new({
		ck(0, Theme.Background),
		ck(0.5, Color3.fromRGB(36, 6, 16)),
		ck(1, Theme.Background),
	}), nil, 90)

	local particles = makeParticles(overlay, 34, { temp = true })

	-- red lines sweeping across the screen
	local sweeps = {}
	for i = 1, 6 do
		local f = create("Frame", {
			Position = UDim2.new(-0.5, 0, 0.5, 0),
			Size = UDim2.new(0.4, 0, 0, (i % 2 == 0) and 2 or 1),
			BackgroundColor3 = Accent.Primary,
			Parent = overlay,
		})
		gradient(f, nil, NumberSequence.new({ kp(0, 1), kp(0.5, 0.05), kp(1, 1) }), 0)
		sweeps[i] = { F = f, X = -math.random() * 1.2, Speed = 0.7 + math.random() * 0.9, Y = math.random(8, 92) / 100 }
	end
	local stopSweep = addUpdater(function(dt)
		for _, s in ipairs(sweeps) do
			s.X = s.X + dt * s.Speed
			if s.X > 1.1 then
				s.X = -0.5
				s.Y = math.random(8, 92) / 100
			end
			s.F.Position = UDim2.new(s.X, 0, s.Y, 0)
		end
	end)

	-- centre: skull, title, edition
	local center = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.9, 0, 0, 220),
		Parent = overlay,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(320, 400), Parent = center })
	local logoGroup = create("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(130, 130),
		GroupTransparency = 1,
		Parent = center,
	})
	local logoScale = create("UIScale", { Scale = 0.7, Parent = logoGroup })
	makeSkull(logoGroup, 90, nil, true).Center()
	local introRing = makeRing(logoGroup, -8, 2, 140, true)

	local title = create("TextLabel", {
		Name = "IntroTitle",
		Position = UDim2.fromOffset(0, 140),
		Size = UDim2.new(1, 0, 0, 34),
		Text = APP_NAME,
		Font = FONT_BLACK,
		TextScaled = true,
		MaxVisibleGraphemes = 0,
		Parent = center,
	})
	create("UITextSizeConstraint", { MaxTextSize = 28, MinTextSize = 14, Parent = title })
	local sub = create("TextLabel", {
		Position = UDim2.fromOffset(0, 180),
		Size = UDim2.new(1, 0, 0, 16),
		Text = EDITION,
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = Accent.Primary,
		TextTransparency = 1,
		Parent = center,
	})

	-- loading block
	local load = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -34),
		Size = UDim2.new(0.8, 0, 0, 52),
		Parent = overlay,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(340, 60), Parent = load })
	local status = create("TextLabel", {
		Size = UDim2.new(0.72, 0, 0, 16),
		Text = STAGES[1],
		Font = FONT_CODE,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = load,
	})
	local pct = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.28, 0, 0, 16),
		Text = "0%",
		Font = FONT_CODE,
		TextSize = 12,
		TextColor3 = Accent.Primary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = load,
	})
	local track_ = create("Frame", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Accent.Dark,
		Parent = load,
	})
	corner(track_, FULL)
	local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Accent.Primary, Parent = track_ })
	corner(fill, FULL)
	create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "BAXTARA // BLOOD EVIL // v" .. VERSION,
		Font = FONT_CODE,
		TextSize = 9,
		TextColor3 = Theme.Secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = load,
	})

	local done = false
	local function runProgress()
		local total = 1.7
		local t = 0
		local stage = 0
		while t < total and overlay.Parent do
			t = t + RunService.Heartbeat:Wait()
			local a = math.min(t / total, 1)
			local p = a * a * (3 - 2 * a)
			fill.Size = UDim2.new(p, 0, 1, 0)
			pct.Text = math.floor(p * 100 + 0.5) .. "%"
			local s = stageFor(p)
			if s ~= stage then
				stage = s
				status.Text = STAGES[s]
				glitch(status, 0.15, 3)
			end
		end
		fill.Size = UDim2.new(1, 0, 1, 0)
		pct.Text = "100%"
		status.Text = STAGES[4]
		done = true
	end

	task.spawn(function()
		task.wait(0.2)
		tween(logoGroup, 0.9, { GroupTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		tween(logoScale, 1, { Scale = 1 }, Enum.EasingStyle.Back)
		task.wait(0.65)
		glitch(logoGroup, 0.45, 8)
		task.wait(0.15)
		task.spawn(runProgress)
		for i = 1, #APP_NAME do
			title.MaxVisibleGraphemes = i
			task.wait(0.04)
		end
		glitch(title, 0.25, 4)
		tween(sub, 0.5, { TextTransparency = 0 })
		while not done do
			task.wait(0.05)
		end
		task.wait(0.3)
		tween(overlay, 0.55, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		task.wait(dur(0.6))
		stopSweep()
		particles.Stop()
		removeRing(introRing)
		overlay:Destroy()
		State.Intro = false
		if onDone then
			onDone()
		end
	end)
end

--------------------------------------------------------------------------------
-- START
--------------------------------------------------------------------------------
do
	local waited = 0
	while ScreenGui.AbsoluteSize.X < 50 and waited < 2 do
		waited = waited + task.wait()
	end
end

Panel.Layout()
Panel.Center(false)
applySurfaces()
refreshGlows()
refreshAccent()
showPage("HOME", true)
Refs.UpdateStats()
Refs.UpdateClock()

Refs.PlayIntro(function()
	State.Ready = true
	Panel.Open()
	notify("BAXTARA SYSTEM", "Interface successfully initialized.")
end)
