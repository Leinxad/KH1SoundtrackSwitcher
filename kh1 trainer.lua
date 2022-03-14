PROCESS_NAME = "KINGDOM HEARTS FINAL MIX.exe"

scanned = false
musicString = "61 6D 75 73 69 63 2F 6D 75 73 69 63 00"
diveString = "61 6D 75 73 69 63 00"
titleString = "61 6D 75 73 69 63 2F 6D 75 73 69 63 31 31 30 2E 64 61 74 00"
amusicDefault = stringToByteTable("amusic")
amusicClassic = stringToByteTable("amusi2")
amusicRemastered = stringToByteTable("amusi3")

function writeDefaultMusic()
	writeBytes(musicAddress,amusicDefault)
	writeBytes(diveAddress,amusicDefault)
	writeBytes(titleAddress,amusicDefault)
end

function writeClassicMusic()
	writeBytes(musicAddress,amusicClassic)
	writeBytes(diveAddress,amusicClassic)
	writeBytes(titleAddress,amusicClassic)
end

function writeRemasteredMusic()
	writeBytes(musicAddress,musicRemastered)
	writeBytes(diveAddress,musicRemastered)
	writeBytes(titleAddress,musicRemastered)
end

function scanMusic()
	m = createMemScan()
	m.setOnlyOneResult(true)
	musicAddress = scanAOB(musicString, 0, 0xffffffffffffffff, m)
	diveAddress = scanAOB(diveString, musicAddress, 0xffffffffffffffff, m)
	titleAddress = scanAOB(titleString, diveAddress, 0xffffffffffffffff, m)
	m.destroy()
	scanned = true
end

function scanAOB(string, startAddress, endAddress, scanner)
	scanner.firstScan(soExactValue, vtByteArray, nil, string, nil, startAddress, endAddress, "*X*C*W", nil, nil , true, nil, nil, nil)
	scanner.waitTillDone()
	return scanner.getOnlyResult()
end

function lines_from(file)
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function loadHotkeys()
	lines = lines_from(TrainerOrigin .. "kh1config.txt")
	defaultHotkey = lines[2]:upper():gsub('%s+', '')
	classicHotkey = lines[4]:upper():gsub('%s+', '')
	remasteredHotkey = lines[6]:upper():gsub('%s+', '')
	UDF1.CELabel2.setCaption("Press " .. defaultHotkey .. " to change to the Default Soundtrack")
	UDF1.CELabel3.setCaption("Press " .. classicHotkey .. " to change to the Classic Soundtrack")
	UDF1.CELabel4.setCaption("Press " .. remasteredHotkey .. " to change to the Remastered Soundtrack")
end

function loadSettings()
	settings=getSettings('KH1TrackSwitcher')
	if #settings.Value['lastSelection'] == 0 then
		settings.Value['lastSelection'] = "Default"	
	end
	lastSelection = settings.Value['lastSelection']
	UDF1.CELabel7.setCaption(lastSelection)
end

function attach(timer)
	if getProcessIDFromProcessName(PROCESS_NAME) ~= nil then
		timer.destroy()
		openProcess(PROCESS_NAME)
		scanMusic()
		if lastSelection == "Default" then
			writeDefaultMusic()
		elseif lastSelection == "Classic" then
			writeClassicMusic()
		elseif lastSelection == "Remastered" then
			writeRemasteredMusic()
		end
		UDF1.CELabel1.setCaption("Attached")
		sound = createMemoryStream()
		sound.loadFromFile(getCheatEngineDir() .. "sound.wav")
		playSound(sound)
	end
end

function switch(timer)
	if scanned == true then
		if isKeyPressed(defaultHotkey) == true then
			writeDefaultMusic()
            UDF1.CELabel7.setCaption("Default")
		elseif isKeyPressed(classicHotkey) == true then
			writeClassicMusic()
            UDF1.CELabel7.setCaption("Classic")
		elseif isKeyPressed(remasteredHotkey) == true then
			writeRemasteredMusic()
            UDF1.CELabel7.setCaption("Remastered")
		end
	end
end

function close(sender)
	settings.Value['lastSelection'] = UDF1.CELabel7.getCaption()
	MainForm.Close()
end

loadSettings()
loadHotkeys()
UDF1.setOnClose(close)
UDF1.Show()
timer = createTimer(MainForm)
timer.Interval = 100
timer.OnTimer = attach
keyTimer = createTimer(MainForm)
keyTimer.Interval = 100
keyTimer.OnTimer = switch
closeTimer = createTimer(MainForm)
closeTimer.Interval = 100
closeTimer.OnTimer = function(closeTimer)
	if scanned == true and getProcessIDFromProcessName(PROCESS_NAME) == nil then
		UDF1.Close()
	end
end
