local addonName = ...
local Codex = CreateFrame("Frame")

local DB_DEFAULTS = {
  currentPage = 1,
}

local STATE = {
  isOpen = false,
  isFlipping = false,
  currentPage = 1,
  maxPages = 4,
}

-- Replace these paths with your real .blp/.tga files in your addon.
local MEDIA = {
  coverAlliance = "Interface\\AddOns\\CodexOfTales\\Media\\cover-alliance",
  coverHorde = "Interface\\AddOns\\CodexOfTales\\Media\\cover-horde",
  openBook = "Interface\\AddOns\\CodexOfTales\\Media\\book-open",
  pageShadow = "Interface\\AddOns\\CodexOfTales\\Media\\page-shadow",
  bookmark = "Interface\\AddOns\\CodexOfTales\\Media\\bookmark-ribbon",
  -- Sequence: flip-01 .. flip-12 (right-page curl texture frames)
  flipPrefix = "Interface\\AddOns\\CodexOfTales\\Media\\Flip\\flip-",
}

local PAGES = {
  [1] = {
    leftTitle = "Heldbrecher-Chronik",
    leftBody = "Platzhalter links: Lore und Weltwissen.",
    rightTitle = "Die verlorene Festung",
    rightBody = "Platzhalter rechts: Questziel, Fortschritt, Belohnungen.",
    marker = "I",
  },
  [2] = {
    leftTitle = "Schatten-Chronik",
    leftBody = "Platzhalter links: Notizen zu Gegnern und Orten.",
    rightTitle = "Ruinen von Andorhal",
    rightBody = "Platzhalter rechts: Aufgaben und Checkliste.",
    marker = "II",
  },
  [3] = {
    leftTitle = "Bestiarium",
    leftBody = "Platzhalter links: Kreaturen und Schwachstellen.",
    rightTitle = "Belohnungen",
    rightBody = "Platzhalter rechts: Loot und Ruf.",
    marker = "III",
  },
  [4] = {
    leftTitle = "Dungeon Log",
    leftBody = "Platzhalter links: Gruppenstrategie und Pull-Pfade.",
    rightTitle = "Feldnotizen",
    rightBody = "Platzhalter rechts: Eigene Markierungen.",
    marker = "IV",
  },
}

local function Pad2(n)
  if n < 10 then
    return "0" .. n
  end
  return tostring(n)
end

local function SafePage(page)
  if page < 1 then
    return 1
  end
  if page > STATE.maxPages then
    return STATE.maxPages
  end
  return page
end

local function SetFactionCover(frame)
  local faction = UnitFactionGroup("player")
  if faction == "Horde" then
    frame.Cover:SetTexture(MEDIA.coverHorde)
  else
    frame.Cover:SetTexture(MEDIA.coverAlliance)
  end
end

local function HighlightBookmarks(frame)
  for i, btn in ipairs(frame.Bookmarks) do
    if i == STATE.currentPage then
      btn:SetAlpha(1.0)
      btn.Icon:SetVertexColor(1, 1, 1)
    else
      btn:SetAlpha(0.5)
      btn.Icon:SetVertexColor(0.8, 0.8, 0.8)
    end
  end
end

local function RenderPage(frame)
  local data = PAGES[STATE.currentPage]
  frame.LeftTitle:SetText(data.leftTitle)
  frame.LeftBody:SetText(data.leftBody)
  frame.RightTitle:SetText(data.rightTitle)
  frame.RightBody:SetText(data.rightBody)
  HighlightBookmarks(frame)
end

local function CreateNudgeAnim(target)
  local group = target:CreateAnimationGroup()

  local out = group:CreateAnimation("Translation")
  out:SetDuration(0.10)
  out:SetOrder(1)

  local back = group:CreateAnimation("Translation")
  back:SetDuration(0.16)
  back:SetOrder(2)

  group.Out = out
  group.Back = back
  return group
end

local function PlayFlip(frame, direction, onMidpoint)
  if STATE.isFlipping then
    return
  end
  STATE.isFlipping = true

  local duration = 0.38
  local elapsed = 0
  local totalFrames = 12
  local appliedMidpoint = false

  frame.FlipOverlay:SetAlpha(1)
  frame.FlipOverlay:SetTexCoord(0, 1, 0, 1)
  if direction < 0 then
    -- Mirror horizontally for previous-page motion.
    frame.FlipOverlay:SetTexCoord(1, 0, 0, 1)
  end

  if direction > 0 then
    frame.PageNudge.Out:SetOffset(-12, 0)
    frame.PageNudge.Back:SetOffset(12, 0)
  else
    frame.PageNudge.Out:SetOffset(12, 0)
    frame.PageNudge.Back:SetOffset(-12, 0)
  end
  frame.PageNudge:Play()

  frame.ShadowPulse:Play()

  frame.FlipDriver:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    local progress = elapsed / duration

    if progress >= 0.5 and not appliedMidpoint then
      appliedMidpoint = true
      if onMidpoint then
        onMidpoint()
      end
    end

    local idx = math.floor(progress * totalFrames) + 1
    idx = math.max(1, math.min(totalFrames, idx))
    frame.FlipOverlay:SetTexture(MEDIA.flipPrefix .. Pad2(idx))

    if progress >= 1 then
      frame.FlipDriver:SetScript("OnUpdate", nil)
      frame.FlipOverlay:SetAlpha(0)
      STATE.isFlipping = false
    end
  end)
end

local function GotoPage(frame, targetPage)
  targetPage = SafePage(targetPage)
  if targetPage == STATE.currentPage then
    return
  end
  local direction = targetPage > STATE.currentPage and 1 or -1

  PlayFlip(frame, direction, function()
    STATE.currentPage = targetPage
    if CodexOfTalesDB then
      CodexOfTalesDB.currentPage = targetPage
    end
    RenderPage(frame)
  end)
end

local function OpenCodex(frame)
  if STATE.isOpen then
    return
  end
  STATE.isOpen = true
  frame:Show()
  SetFactionCover(frame)
  RenderPage(frame)

  frame.Cover:SetAlpha(1)
  frame.PageLayer:SetAlpha(0)

  frame.OpenAnim:Stop()
  frame.OpenAnim:Play()
end

local function CloseCodex(frame)
  if not STATE.isOpen then
    return
  end
  STATE.isOpen = false
  frame:Hide()
end

local function CreateBookmark(frame, index, xOffset)
  local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
  btn:SetSize(34, 54)
  btn:SetPoint("BOTTOM", xOffset, 18)

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()
  icon:SetTexture(MEDIA.bookmark)
  btn.Icon = icon

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("CENTER", 0, 2)
  text:SetText(PAGES[index].marker)

  btn:SetScript("OnEnter", function(self)
    self:SetScale(1.08)
  end)
  btn:SetScript("OnLeave", function(self)
    self:SetScale(1.0)
  end)
  btn:SetScript("OnClick", function()
    GotoPage(frame, index)
  end)

  return btn
end

local function BuildUI()
  local f = CreateFrame("Frame", "CodexOfTalesFrame", UIParent, "BackdropTemplate")
  f:SetSize(980, 620)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()
  Codex.Frame = f

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetTexture(MEDIA.openBook)
  f.Bg = bg

  local pageLayer = CreateFrame("Frame", nil, f)
  pageLayer:SetAllPoints()
  f.PageLayer = pageLayer

  local cover = f:CreateTexture(nil, "ARTWORK", nil, 5)
  cover:SetPoint("CENTER")
  cover:SetSize(420, 560)
  cover:SetTexture(MEDIA.coverAlliance)
  f.Cover = cover

  local leftTitle = pageLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  leftTitle:SetPoint("TOPLEFT", 200, -100)
  leftTitle:SetWidth(260)
  leftTitle:SetJustifyH("LEFT")
  f.LeftTitle = leftTitle

  local leftBody = pageLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  leftBody:SetPoint("TOPLEFT", leftTitle, "BOTTOMLEFT", 0, -10)
  leftBody:SetWidth(270)
  leftBody:SetJustifyH("LEFT")
  leftBody:SetJustifyV("TOP")
  f.LeftBody = leftBody

  local rightTitle = pageLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  rightTitle:SetPoint("TOPLEFT", 525, -100)
  rightTitle:SetWidth(250)
  rightTitle:SetJustifyH("LEFT")
  f.RightTitle = rightTitle

  local rightBody = pageLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  rightBody:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", 0, -10)
  rightBody:SetWidth(260)
  rightBody:SetJustifyH("LEFT")
  rightBody:SetJustifyV("TOP")
  f.RightBody = rightBody

  local shadow = pageLayer:CreateTexture(nil, "ARTWORK", nil, 2)
  shadow:SetPoint("CENTER", 6, 0)
  shadow:SetSize(340, 520)
  shadow:SetTexture(MEDIA.pageShadow)
  shadow:SetBlendMode("BLEND")
  shadow:SetAlpha(0.25)
  f.PageShadow = shadow

  local flipOverlay = pageLayer:CreateTexture(nil, "OVERLAY", nil, 8)
  flipOverlay:SetPoint("TOPRIGHT", -165, -74)
  flipOverlay:SetSize(330, 505)
  flipOverlay:SetAlpha(0)
  f.FlipOverlay = flipOverlay

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", 4, 6)
  f.Close = closeBtn

  local prevBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  prevBtn:SetSize(70, 24)
  prevBtn:SetPoint("BOTTOMLEFT", 24, 20)
  prevBtn:SetText("<")
  prevBtn:SetScript("OnClick", function()
    GotoPage(f, STATE.currentPage - 1)
  end)

  local nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  nextBtn:SetSize(70, 24)
  nextBtn:SetPoint("BOTTOMRIGHT", -24, 20)
  nextBtn:SetText(">")
  nextBtn:SetScript("OnClick", function()
    GotoPage(f, STATE.currentPage + 1)
  end)

  f.Bookmarks = {}
  local startX = -90
  for i = 1, STATE.maxPages do
    local btn = CreateBookmark(f, i, startX + ((i - 1) * 60))
    table.insert(f.Bookmarks, btn)
  end

  -- Open animation: cover fades out while pages fade in.
  local openAnim = f:CreateAnimationGroup()
  local coverOut = openAnim:CreateAnimation("Alpha")
  coverOut:SetTarget(cover)
  coverOut:SetFromAlpha(1)
  coverOut:SetToAlpha(0)
  coverOut:SetDuration(0.28)
  coverOut:SetOrder(1)

  local pageIn = openAnim:CreateAnimation("Alpha")
  pageIn:SetTarget(pageLayer)
  pageIn:SetFromAlpha(0)
  pageIn:SetToAlpha(1)
  pageIn:SetDuration(0.30)
  pageIn:SetOrder(1)
  f.OpenAnim = openAnim

  local shadowPulse = shadow:CreateAnimationGroup()
  local pulseIn = shadowPulse:CreateAnimation("Alpha")
  pulseIn:SetFromAlpha(0.22)
  pulseIn:SetToAlpha(0.45)
  pulseIn:SetDuration(0.12)
  pulseIn:SetOrder(1)

  local pulseOut = shadowPulse:CreateAnimation("Alpha")
  pulseOut:SetFromAlpha(0.45)
  pulseOut:SetToAlpha(0.22)
  pulseOut:SetDuration(0.20)
  pulseOut:SetOrder(2)
  f.ShadowPulse = shadowPulse

  f.PageNudge = CreateNudgeAnim(pageLayer)

  f.FlipDriver = CreateFrame("Frame", nil, f)
end

SLASH_CODEXOFTALES1 = "/codex"
SLASH_CODEXOFTALES2 = "/codextales"
SlashCmdList.CODEXOFTALES = function(msg)
  local frame = Codex.Frame
  if not frame then
    return
  end
  msg = (msg or ""):lower()
  if msg == "close" then
    CloseCodex(frame)
    return
  end
  if msg:match("^page%s+%d+$") then
    local p = tonumber(msg:match("%d+"))
    if p then
      OpenCodex(frame)
      GotoPage(frame, p)
      return
    end
  end
  if frame:IsShown() then
    CloseCodex(frame)
  else
    OpenCodex(frame)
  end
end

Codex:SetScript("OnEvent", function(_, event)
  if event == "ADDON_LOADED" then
    if addonName ~= "CodexOfTales" then
      return
    end
    if not CodexOfTalesDB then
      CodexOfTalesDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
      if CodexOfTalesDB[k] == nil then
        CodexOfTalesDB[k] = v
      end
    end
    STATE.currentPage = SafePage(CodexOfTalesDB.currentPage or 1)
    BuildUI()
  elseif event == "PLAYER_LOGIN" then
    if Codex.Frame then
      RenderPage(Codex.Frame)
    end
  end
end)

Codex:RegisterEvent("ADDON_LOADED")
Codex:RegisterEvent("PLAYER_LOGIN")
