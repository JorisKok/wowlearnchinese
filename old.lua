
-- Find the characters in the data files and return it as a neat string
function findTrad(character)
	for key, value in pairs(trad) do 
		if (value == character) then
		
			-- Remove all the comma's fromt the text (so that its easy to import it to an csv later, when storing to SavedVariables)			
			return "|cff71d5ff|HPeraPera:PeraPera|h" .. character:gsub(",", " ") .. " , " ..  pinyin[key]:gsub(",", " ") .. " , " .. entry[key]:gsub(",", " ") .. "|h|r"			
		end
	end
	
	return ""
end

-- Read the custom hyperlinks
local OldSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
	local func = strmatch(link, "^PeraPera:(%a+)")	
	-- Our custom item reference, aka hyperlink, will save our data so we can easily create a csv to import for flashcard programs like anki etc
	if func == "PeraPera" then
		local neatText = string.match(text, "|h(.*)|h")
		if not (neatText == nil) then
			-- If not already in the UsefulWords table, then insert
			local alreadyInserted = false
			for key, value in pairs(UsefulWords) do				
				if (value == neatText) then
					alreadyInserted = true
				end
			end
			
			if (alreadyInserted == false) then
				-- For making flashcards
				table.insert(UsefulWords, neatText)								
			end
		end
	else
		OldSetItemRef(link, text, button, chatFrame)
	end
end 
