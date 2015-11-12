-- The main frame, used for listening to the events
local Frame = CreateFrame("Frame", "LearChineseFrame")
Frame:RegisterEvent("GOSSIP_SHOW")
Frame:RegisterEvent("QUEST_DETAIL") 
Frame:RegisterEvent("QUEST_GREETING")
Frame:RegisterEvent("QUEST_PROGRESS")
Frame:RegisterEvent("ADDON_LOADED") -- Needed for saving to the global saved variables
Frame:RegisterEvent("PLAYER_LOGOUT") -- Needed for saving to the global saved variables

-- The text frame
TextFrame = LibStub("LibTextDump-1.0"):New("Translated", 480, 320)

-- The flashcard frame
FlashCardFrame = LibStub("LibTextDump-1.0"):New("Flashcards", 480, 115)

-- Stores the translated
local TranslatedTable = {}

-- Set loaded
local loaded = false

-- For the flashcard time
local totalTime = 0 
local showing = false
local totalFlashcards = 0
local lastWord = ""

-- The main program
Frame:SetScript("OnEvent", function(self,event,...) 
	
	-- Clear the frame, then get the text
	TextFrame:Clear()
	text = nil
	
	-- Listen to the events		
	if (event == "GOSSIP_SHOW") then
		text = GetGossipText()		
	elseif (event == "QUEST_DETAIL") then		
		text = GetGossipText() -- TODO change?	
	elseif (event == "QUEST_GREETING") then		
		text = GetGossipText() -- TODO change?
	elseif (event == "QUEST_PROGRESS") then
		text = GetProgressText()			
	end
	
	if (text) then
		translate(text)
	end
	
	if (TextFrame:Lines() > 0) then
		TextFrame:Display()
	end
	
	-- Initiate our SavedVariables
	if (event == "ADDON_LOADED" and loaded == false) then				
		if (UsefulWords == nil) then
			UsefulWords = {}		
		end
		
		-- Our text display frame: Goes here because the addon needs to be loaded first				
		TextFrame:AddLine("Welcome to learning Chinese via WoW \nTranslated text will be displayed when you talk to an NPC. \n\nYou can use some commands to save characters into flashcards for learning. \n/flashcard <line number> - will insert the flashcard from the line number between the brackets. \n/flashcard clear - will clear all the flashcards'")
		TextFrame:Display()		
		
		-- Our flashcard frame
		FlashCardFrame:AddLine("Flashcards will be displayed when added")
		FlashCardFrame:Display()
		
		-- Count our flashcards 
		totalFlashcards = getn(UsefulWords)	
		
		loaded = true
	end
end)

-- The flashcard timer
Frame:SetScript("OnUpdate", function(self, elapsed)	
	-- Start when loaded and when there is some information in the UsefulWords	
	if (loaded and totalFlashcards > 0) then
		totalTime = totalTime + elapsed
		
		-- Show a flashcard every 120 seconds
		if (totalTime > 10) then		
			-- Don't show when the player is in combat
			if not (UnitAffectingCombat("player")) then
				showFlashcard(random(1, totalFlashcards))			
			end
			totalTime = 0
		end
	end
end)

-- Shows the flashcard
function showFlashcard(i)
	FlashCardFrame:Clear()		
	if not (showing) then
		-- Show only the characters
		lastWord = UsefulWords[i]
		j = string.find(lastWord, ",")				
		if not (j == nil) then
			FlashCardFrame:AddLine(string.sub(lastWord, 0, (j - 1)))
			showing = true
		end
	else
		FlashCardFrame:AddLine(lastWord)
		showing = false
	end	
	FlashCardFrame:Display()
end

-- Translate our text
function translate(text)
	full = ""
	counter = 0
	
	-- This matches unicode characters. String.Sub doesn't work well ~!
	for character in string.gmatch(text, "([%z\1-\127\194-\244][\128-\191]*)") do
		
		-- Check if the string is in the trad 'data array'			
		-- Always use full as a search parameter. If full is not find, the find the single character
		full = full .. character
					
		-- The problem is: it might stop on 龜兒 but there is a 龜兒子 
		-- Also, if it stops on 龜兒, it should still check 兒子
					
		result = findTrad(full)
		if (result == "") then
			-- Clear the full string and add the single character
			full = character				
			result = findTrad(character)
			if not (result == "") then
				-- Add the counter, to be able to use slash commands to add flash cards
				counter = counter + 1
				TextFrame:AddLine(result .. " [" .. counter .."]")
			end				
		else			
			-- Add the full string and add the counter, to be able to use slash commands to add flash cards
			counter = counter + 1
			TextFrame:AddLine(result .. " [" .. counter .."]")			
		end			
	end		
end

-- Find the characters in the data files and return it as a neat string
function findTrad(character)	
	for key, value in pairs(trad) do 
		if (value == character) then			
			
			-- Remove all the comma's fromt the text (so that its easy to import it to an csv later, when storing to SavedVariables)
			-- text = character:gsub(",", " ") .. " , " ..  pinyin[key]:gsub(",", " ") .. " , " .. entry[key]:gsub(",", " ")
			text = character:gsub(",", " ") .. " , " ..  pinyin[key]:gsub(",", " ") .. " , " .. entry[key]:gsub(",", " ")
			c = character:gsub(",", " ")
			p = pinyin[key]:gsub(",", " ")
			e = entry[key]:gsub(",", " ")
			-- Insert normal text, to be used for the flash cards
			table.insert(TranslatedTable, c .. " , " .. p .. " , " .. e)
			
			-- Return colored text			
			return "|cff32cd32" .. c .. "|r , |cff995500" .. p .. "|r , |cff7777aa" .. e .. "|r"
		end
	end
	
	return ""
end

-- Some commands for storing a flash card
SLASH_FLASHCARD1 = '/flashcard'
function SlashCmdList.FLASHCARD(msg, editbox)

	-- Clear everything
	if (msg == "clear") then
		UsefulWords = {}
		print("Cleared all the flashcards")
		
		-- Count the flashcards
		totalFlashcards = getn(UsefulWords)	
		return
	end
	
	-- Count
	if (msg == "count") then
		print("There are currently " .. getn(UsefulWords) .. " flashcards")
		
		-- Count the flashcards
		totalFlashcards = getn(UsefulWords)	
		
		return
	end
	
	-- Insert the flash cards
	local i = tonumber(msg)
	if not (i == nil) then	
		if (i >= 0) then
			if (TranslatedTable[i] == nil) then
				print("There is no flashcard at location: " .. i)
				
				return
			end
			
			-- Insert the flashcard
			table.insert(UsefulWords, TranslatedTable[i])
			print("Inserted a flashcard")		
			
			-- Count the flashcards
			totalFlashcards = getn(UsefulWords)	
			
			return
		end	
	end
	
	print("Use '/flashcard <line number>' to insert the line to the flashcards. For example: '/flashcard 2' to insert number 2. Type '/flashcard clear' to clear all flashcards.")
end
