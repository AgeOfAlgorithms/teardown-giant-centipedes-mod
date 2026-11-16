-- Giant Centipedes options (Mod Manager): how big a nest can grow. A nest starts with one ring of silk and grows one
-- more each time its centipede comes home, up to this many (read by the host when a map starts; 0 = not set = 10).

function draw()
	local n = GetInt("savegame.mod.nestrings")
	if n < 3 or n > 10 then n = 10 end
	UiTranslate(UiCenter(), 300)
	UiAlign("center middle")
	UiFont("bold.ttf", 48)
	UiText("Giant Centipedes")
	UiTranslate(0, 90)
	UiFont("regular.ttf", 28)
	UiText("Nest size: rings of silk at most")
	UiTranslate(0, 60)
	UiFont("bold.ttf", 40)
	UiPush()
	for i = 3, 10 do
		UiPush()
		UiTranslate((i - 6.5) * 100, 0)
		if i == n then UiColor(1, 0.4, 0.3) else UiColor(0.8, 0.8, 0.8) end
		if UiTextButton(tostring(i), 80, 60) then SetInt("savegame.mod.nestrings", i) end
		UiPop()
	end
	UiPop()
	UiTranslate(0, 80)
	UiFont("regular.ttf", 22)
	UiColor(0.8, 0.8, 0.8)
	UiText("A nest starts with one ring and grows one more each time its centipede comes home.")
	UiTranslate(0, 30)
	UiText("Takes effect on the next map start.")
	UiTranslate(0, 100)
	UiColor(1, 1, 1)
	UiFont("bold.ttf", 32)
	if UiTextButton("Close", 200, 50) then Menu() end
end
