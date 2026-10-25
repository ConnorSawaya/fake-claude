-- grid.applescript: open one Ghostty window with a grid of terminals running fakeclaude (or the real Claude Code).
-- Needs Ghostty 1.3 or later, which added AppleScript support.
--
--   osascript grid.applescript [--count N] [--cols C] [--fake | --fake-cmd CMD] [dir ...]
--
--   --count     number of panes, 1-64 (default 6)
--   --cols      number of columns (default: picked from the count)
--   --fake      run `fakeclaude` from your PATH in each pane, a different made-up project per pane
--   --fake-cmd  like --fake, but start each pane with this shell command instead of `fakeclaude`
--   dir ...     where panes start; one dir = every pane, several = one per pane, cycling
-- Without --fake or --fake-cmd, every pane runs the real `claude`.
on run argv
	set dirs to {}
	set fakeCmd to ""
	set total to 6
	set nCols to 0
	set pending to ""
	try
		repeat with a in argv
			set a to a as text
			if pending is "count" then
				set total to a as integer
				set pending to ""
			else if pending is "cols" then
				set nCols to a as integer
				set pending to ""
			else if pending is "cmd" then
				set fakeCmd to a
				set pending to ""
			else if a is "--fake" then
				set fakeCmd to "fakeclaude"
			else if a is "--fake-cmd" then
				set pending to "cmd"
			else if a is "--count" then
				set pending to "count"
			else if a is "--cols" then
				set pending to "cols"
			else
				set end of dirs to a
			end if
		end repeat
	end try
	if (count of dirs) = 0 then set dirs to {POSIX path of (path to home folder)}
	if total < 1 then set total to 1
	if total > 64 then set total to 64

	-- a few wide rows: 6 = 3x2, 12 = 4x3, 32 = 8x4; past 32, stay 8 wide and add rows (64 = 8x8)
	-- spare slots make some columns one shorter
	if nCols < 1 then
		if total > 32 then
			set nCols to 8
		else
			set nRows to round ((total / 1.6) ^ 0.5) rounding as taught in school
			if nRows < 1 then set nRows to 1
			set nCols to (total + nRows - 1) div nRows
		end if
	end if
	if nCols > total then set nCols to total
	set nRows to (total + nCols - 1) div nCols
	-- smaller text as panes shrink
	set sizes to {13, 13, 12, 10, 9, 8, 7, 7}
	if nCols > 8 then
		set fontSize to 7
	else
		set fontSize to item nCols of sizes
	end if
	if nRows ≥ 6 then set fontSize to 6

	tell application "Ghostty"
		activate
		set made to 1
		set win to new window with configuration (my paneConfig(made, fakeCmd, dirs, fontSize))
		set tops to {focused terminal of selected tab of win}
		-- even out after every split: each split halves the last pane, so a long chain would get tiny
		repeat (nCols - 1) times
			set made to made + 1
			set end of tops to split (item -1 of tops) direction right with configuration (my paneConfig(made, fakeCmd, dirs, fontSize))
			perform action "equalize_splits" on (item 1 of tops)
		end repeat
		repeat with c from 1 to nCols
			set inCol to total div nCols
			if c ≤ (total mod nCols) then set inCol to inCol + 1
			set t to item c of tops
			repeat (inCol - 1) times
				set made to made + 1
				set t to split t direction down with configuration (my paneConfig(made, fakeCmd, dirs, fontSize))
				perform action "equalize_splits" on (item 1 of tops)
			end repeat
		end repeat
		perform action "equalize_splits" on (item 1 of tops)
		focus (item 1 of tops)
	end tell
end run

on paneConfig(i, fakeCmd, dirs, fontSize)
	set d to item (((i - 1) mod (count of dirs)) + 1) of dirs
	if fakeCmd is "" then
		set cmd to "claude"
	else
		-- exec: quitting the fake closes its pane instead of leaving a shell behind
		set cmd to "exec " & fakeCmd & " --project " & (i - 1)
	end if
	tell application "Ghostty" to return {initial working directory:d, initial input:cmd & linefeed, font size:fontSize}
end paneConfig
