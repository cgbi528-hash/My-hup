local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

------------------------------------------------
-- ตั้งค่า (แก้ตรงนี้)
------------------------------------------------
local CONFIG = {
	Name = "MyHub",
	Title = "ฮับของฉัน",
	OwnerNames = { "Lilith_ilon" },       -- เจ้าของ (ข้ามหน้าคีย์)
	OwnerIds = {},                        -- ใส่ UserId เพิ่มได้ (ปลอดภัยกว่าชื่อ)
	Keys = { ["MY-KEY-1234"] = true },    -- คีย์ที่แจกได้
	KeyLink = "https://discord.gg/yourlink", -- ลิงก์รับคีย์ (ปุ่ม Get Key คัดลอกให้)
	Scripts = {                           -- GameId = ลิงก์สคริปต์ "ของคุณเอง"
		-- [123456789] = "https://raw.githubusercontent.com/YOU/REPO/main/Game.lua",
	},
}

local KEY_FILE = CONFIG.Name .. "_key.txt"
local isOwner = table.find(CONFIG.OwnerIds, player.UserId) ~= nil
	or table.find(CONFIG.OwnerNames, player.Name) ~= nil

------------------------------------------------
-- ตัวช่วย
------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function corner(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
end

local function drag(handle, frame)
	local dragging, start, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, startPos = true, i.Position, frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local gui = mk("ScreenGui", { Name = CONFIG.Name, ResetOnSpawn = false },
	(gethui and gethui()) or player:WaitForChild("PlayerGui"))

local function window(title, w, h)
	local f = mk("Frame", {
		Size = UDim2.new(0, w, 0, h),
		Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
		BackgroundColor3 = Color3.fromRGB(18, 14, 30),
		BorderSizePixel = 0,
	}, gui)
	corner(f, 12)
	mk("UIStroke", { Color = Color3.fromRGB(120, 60, 220), Thickness = 1.5 }, f)

	local head = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Color3.fromRGB(26, 20, 44),
		BorderSizePixel = 0,
	}, f)
	corner(head, 12)
	mk("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1, Text = title,
		TextColor3 = Color3.fromRGB(225, 205, 255),
		Font = Enum.Font.GothamBold, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	local x = mk("TextButton", {
		Size = UDim2.new(0, 26, 0, 24), Position = UDim2.new(1, -32, 0, 7),
		BackgroundColor3 = Color3.fromRGB(160, 50, 60), Text = "X",
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12,
	}, head)
	corner(x, 6)
	x.MouseButton1Click:Connect(function() f:Destroy() end)
	drag(head, f)
	return f
end

local function button(parent, text, y, color)
	local b = mk("TextButton", {
		Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0, 12, 0, y),
		BackgroundColor3 = color or Color3.fromRGB(60, 30, 120), Text = text,
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13,
		BorderSizePixel = 0,
	}, parent)
	corner(b, 8)
	return b
end

local function flash(btn, msg, default)
	btn.Text = msg
	task.delay(2, function()
		if btn.Parent and btn.Text == msg then btn.Text = default end
	end)
end

------------------------------------------------
-- Avatar Tools: เลือกผู้เล่น + Copy Avatar + View Player
------------------------------------------------
local function AvatarTools()
	if gui:FindFirstChild("AvatarToolsWin") then return end
	local w = window("เครื่องมืออวตาร", 230, 372)
	w.Name = "AvatarToolsWin"

	local selected, viewing, viewConn
	local rows = {}

	local selLabel = mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 12, 0, 46),
		BackgroundColor3 = Color3.fromRGB(10, 8, 18), BorderSizePixel = 0,
		Text = "เลือก: (ยังไม่ได้เลือก)", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham, TextSize = 12,
	}, w)
	corner(selLabel, 6)

	local list = mk("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, 190), Position = UDim2.new(0, 12, 0, 78),
		BackgroundColor3 = Color3.fromRGB(10, 8, 18), BorderSizePixel = 0,
		ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, w)
	corner(list, 6)
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.Name }, list)

	local copyBtn = button(w, "คัดลอกอวตาร", 276)
	local viewBtn = button(w, "ดูมุมมองผู้เล่น", 318, Color3.fromRGB(20, 55, 100))

	local function refresh()
		for p, row in pairs(rows) do
			row.BackgroundColor3 = (p == selected)
				and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(50, 50, 50)
		end
		selLabel.Text = selected and ("เลือก: " .. selected.DisplayName) or "เลือก: (ยังไม่ได้เลือก)"
	end

	local function addRow(p)
		if rows[p] then return end
		local row = mk("TextButton", {
			Name = p.Name, Size = UDim2.new(1, -6, 0, 28),
			Text = p.DisplayName .. " (@" .. p.Name .. ")",
			TextScaled = true, TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50), BorderSizePixel = 0,
		}, list)
		rows[p] = row
		row.MouseButton1Click:Connect(function()
			selected = p
			refresh()
		end)
	end

	local function stopView()
		if viewConn then viewConn:Disconnect() viewConn = nil end
		viewing = nil
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then workspace.CurrentCamera.CameraSubject = hum end
		if viewBtn.Parent then viewBtn.Text = "ดูมุมมองผู้เล่น" end
	end

	local function focusOn(target)
		local h = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if h then workspace.CurrentCamera.CameraSubject = h end
		return h ~= nil
	end

	for _, p in ipairs(Players:GetPlayers()) do addRow(p) end
	local c1 = Players.PlayerAdded:Connect(addRow)
	local c2 = Players.PlayerRemoving:Connect(function(p)
		if rows[p] then rows[p]:Destroy() rows[p] = nil end
		if p == selected then selected = nil end
		if p == viewing then stopView() end
		refresh()
	end)

	w.Destroying:Connect(function()
		c1:Disconnect()
		c2:Disconnect()
		stopView()
	end)

	-- View Player
	viewBtn.MouseButton1Click:Connect(function()
		if viewing then return stopView() end
		if not selected then return flash(viewBtn, "เลือกผู้เล่นก่อน", "ดูมุมมองผู้เล่น") end
		if selected == player then return flash(viewBtn, "นี่คือตัวคุณเอง", "ดูมุมมองผู้เล่น") end
		if not focusOn(selected) then return flash(viewBtn, "ยังไม่มีตัวละคร", "ดูมุมมองผู้เล่น") end

		local target = selected
		viewing = target
		viewBtn.Text = "หยุดดู: " .. target.DisplayName
		viewConn = target.CharacterAdded:Connect(function()
			task.wait(0.5)
			if viewing == target then focusOn(target) end
		end)
	end)

	-- Copy Avatar
	local busy = false
	copyBtn.MouseButton1Click:Connect(function()
		if busy then return end
		if not selected then return flash(copyBtn, "เลือกผู้เล่นก่อน", "คัดลอกอวตาร") end

		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return flash(copyBtn, "ไม่พบตัวละคร", "คัดลอกอวตาร") end

		busy = true
		copyBtn.Text = "กำลังโหลด..."
		local ok, err = pcall(function()
			local desc = Players:GetHumanoidDescriptionFromUserId(selected.UserId)
			hum:ApplyDescription(desc)
		end)
		busy = false

		if ok then
			flash(copyBtn, "สำเร็จ ✓", "คัดลอกอวตาร")
		else
			warn("Apply error:", err)
			flash(copyBtn, "ใช้ไม่ได้ในเกมนี้", "คัดลอกอวตาร")
		end
	end)
end

------------------------------------------------
-- โหลดสคริปต์เกม (ลิงก์ของคุณเอง)
------------------------------------------------
local function LoadGameScript()
	local url = CONFIG.Scripts[game.GameId]
	if not url then return "ยังไม่มีสคริปต์สำหรับเกมนี้" end
	local ok = pcall(function() loadstring(game:HttpGet(url))() end)
	return ok and "โหลดแล้ว ✓" or "โหลดไม่สำเร็จ"
end

------------------------------------------------
-- หน้า Hub
------------------------------------------------
local function ShowHub()
	local w = window(CONFIG.Title .. (isOwner and "  👑 เจ้าของ" or ""), 240, 190)
	local status = mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 46),
		BackgroundTransparency = 1, Text = "พร้อมใช้งาน",
		TextColor3 = Color3.fromRGB(170, 150, 210), Font = Enum.Font.Gotham, TextSize = 11,
	}, w)

	button(w, "เครื่องมืออวตาร", 72).MouseButton1Click:Connect(AvatarTools)
	button(w, "โหลดสคริปต์เกม", 114, Color3.fromRGB(30, 80, 60)).MouseButton1Click:Connect(function()
		status.Text = LoadGameScript()
	end)
end

------------------------------------------------
-- ระบบคีย์
------------------------------------------------
local function savedKey()
	if isfile and readfile and isfile(KEY_FILE) then
		local ok, v = pcall(readfile, KEY_FILE)
		if ok then return (v:gsub("%s", "")) end
	end
	return ""
end

local function checkKey(k)
	return isOwner or CONFIG.Keys[k] == true
end

local function ShowKeyUI()
	local w = window(CONFIG.Title .. " — ระบบคีย์", 280, 190)
	local box = mk("TextBox", {
		Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0, 12, 0, 50),
		BackgroundColor3 = Color3.fromRGB(10, 8, 18), Text = savedKey(),
		PlaceholderText = "ใส่คีย์...", TextColor3 = Color3.fromRGB(225, 205, 255),
		Font = Enum.Font.GothamBold, TextSize = 13, ClearTextOnFocus = false,
		BorderSizePixel = 0,
	}, w)
	corner(box, 8)

	local status = mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 92),
		BackgroundTransparency = 1, Text = "ใส่คีย์เพื่อเข้าใช้งาน",
		TextColor3 = Color3.fromRGB(170, 150, 210), Font = Enum.Font.Gotham, TextSize = 11,
	}, w)

	local enter = button(w, "ยืนยันคีย์", 116)
	enter.Size = UDim2.new(0.5, -18, 0, 36)
	local get = button(w, "รับคีย์", 116, Color3.fromRGB(20, 55, 100))
	get.Size = UDim2.new(0.5, -18, 0, 36)
	get.Position = UDim2.new(0.5, 6, 0, 116)

	enter.MouseButton1Click:Connect(function()
		local k = (box.Text:gsub("%s", ""))
		if checkKey(k) then
			if writefile then pcall(writefile, KEY_FILE, k) end
			w:Destroy()
			ShowHub()
		else
			status.Text = "คีย์ไม่ถูกต้อง"
			status.TextColor3 = Color3.fromRGB(255, 100, 110)
		end
	end)

	get.MouseButton1Click:Connect(function()
		pcall(function() (setclipboard or toclipboard)(CONFIG.KeyLink) end)
		status.Text = "คัดลอกลิงก์แล้ว"
	end)
end

------------------------------------------------
-- เริ่มต้น
------------------------------------------------
if isOwner or checkKey(savedKey()) then
	ShowHub()
else
	ShowKeyUI()
end
