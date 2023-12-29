SLASH_PIAUCTION1 = '/PIAuction'
local frame = CreateFrame("Frame")
--setup GUI
local auctionFrame = CreateFrame("Frame", "AuctionFrame", UIParent, "BasicFrameTemplateWithInset")
auctionFrame:Hide()
auctionFrame:SetSize(300, 100)  -- width, height
auctionFrame:SetPoint("CENTER")  -- position on the screen

auctionFrame.title = auctionFrame:CreateFontString(nil, "OVERLAY")
auctionFrame.title:SetFontObject("GameFontHighlight")
auctionFrame.title:SetPoint("LEFT", auctionFrame.TitleBg, "LEFT", 5, 0)
auctionFrame.title:SetText("PI Auction")

auctionFrame.bidInfo = CreateFrame("ScrollingMessageFrame", nil, auctionFrame)
auctionFrame.bidInfo:SetFontObject("GameFontHighlight")
auctionFrame.bidInfo:SetSize(280, 80)  -- Adjust the size as needed
auctionFrame.bidInfo:SetPoint("TOPLEFT", 10, -10)
auctionFrame.bidInfo:SetJustifyH("LEFT")
auctionFrame.bidInfo:SetFading(false)
auctionFrame.bidInfo:SetMaxLines(100)
auctionFrame.bidInfo:SetInsertMode("BOTTOM")
auctionFrame.bidInfo:EnableMouseWheel(true)
auctionFrame.bidInfo:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then
        self:ScrollUp()
    else
        self:ScrollDown()
    end
end)

auctionFrame:EnableMouse(true)
auctionFrame:SetMovable(true)
auctionFrame:SetClampedToScreen(true)

auctionFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
auctionFrame:SetScript("OnMouseUp", auctionFrame.StopMovingOrSizing)

auctionFrame:Hide()


local function startAuction(msg, editbox)
    local startingBid = tonumber(msg)
    if startingBid then
        SendChatMessage("Selling PI for " .. startingBid .. " gold. Type 'bid [amount]' to participate.", "RAID")
        -- Initialize auction data
        auctionData = {
            highestBid = startingBid,
            highestBidder = nil,
            auctionOpen = true
        }
        -- Start the timer
        C_Timer.After(10, closeAuction)
		auctionFrame:Show() -- Show the GUI when the auction starts
    else
        print("Invalid starting bid. Usage: /PIAuction [amount]")
    end
end

SlashCmdList["PIAUCTION"] = startAuction
local bids = {} -- Table to store all bids

local function handleBid(sender, bidAmount, isTest)
    bidAmount = tonumber(bidAmount)
	-- Ignore negative bids
    if bidAmount < 0 then
        return
    end
    local playerName = UnitName("player") -- Get the player's name

    if auctionData.auctionOpen and bidAmount then
        -- Add the bid to the bids table
        table.insert(bids, {player = sender, amount = bidAmount})

        -- Sort the bids table by bid amount in descending order
        table.sort(bids, function(a, b) return a.amount > b.amount end)

        -- Update the highest bid and bidder if the new bid is higher
        if bidAmount > auctionData.highestBid then
            auctionData.highestBid = bidAmount
            auctionData.highestBidder = sender
            local message = sender.." is now leading with a bid of " .. bidAmount .. " gold."

            if not isTest then
                local chatType = "SAY"
                if IsInRaid() then
                    chatType = "RAID"
                elseif IsInGroup() then
                    chatType = "PARTY"
                end
                SendChatMessage(message, chatType)
            else
                -- Whisper to self for test
                SendChatMessage(message, "WHISPER", nil, playerName)
            end
        end

        updateAuctionFrame()
    end
end




local function onChatMsgReceived(_, _, msg, sender)
    if msg:lower():match("^bid %d+$") then
        local bidAmount = msg:match("%d+")
        handleBid(sender, bidAmount)
    end
end

frame:SetScript("OnEvent", onChatMsgReceived)
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")

function closeAuction()
    if auctionData.auctionOpen then
        auctionData.auctionOpen = false
        if auctionData.highestBidder then
            SendChatMessage("Auction closed! Winner: " .. auctionData.highestBidder .. " with " .. auctionData.highestBid .. " gold.", "RAID")
        else
            SendChatMessage("Auction closed! No bids received.", "RAID")
        end
		-- Clear the bids table
        bids = {}
    end
end
-- Simple UI to display the highest bid and bidder

-- Update UI function
function updateAuctionFrame()
    auctionFrame.bidInfo:Clear()
    for i, bid in ipairs(bids) do
        local bidText = bid.player .. ": " .. bid.amount .. " gold"
        auctionFrame.bidInfo:AddMessage(bidText)
    end
end



local function startTestAuction(msg, editbox)
    startAuction("10")  -- Start with a default bid of 10
    -- Simulate bids
    C_Timer.After(2, function() handleBid("RandomPlayer1", "11", true) end)
    C_Timer.After(4, function() handleBid("RandomPlayer2", "12", true) end)
    C_Timer.After(6, function() handleBid("RandomPlayer3", "5", true) end)  -- This should be ignored as it's lower
	C_Timer.After(7, function() handleBid("RandomPlayer4", "55", true) end)  -- This should be ignored as it's lower
	C_Timer.After(7, function() handleBid("RandomPlayer5", "-42", true) end)  -- This should be ignored as it's lower
	C_Timer.After(7, function() handleBid("RandomPlayer1", "-57", true) end)  -- This should be ignored as it's lower
end
SlashCmdList["PIAUCTIONTEST"] = startTestAuction
SLASH_PIAUCTIONTEST1 = '/PIAuctionTest'


