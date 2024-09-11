tell application "Arc"
	set spaceTabTitles to {}

	repeat with currentSpace in every space of front window
		set ok to true
		set tabTitles to {}
		set appId to title of currentSpace

		repeat with tabItem in every tab of currentSpace
			set tabURL to URL of tabItem
			set escapedTabTitle to my replaceString(title of tabItem, "\\", "\\\\")
			set escapedTabTitle to my replaceString(escapedTabTitle, "\"", "\\\"")
			set tabTitles to tabTitles & ("\"" & (escapedTabTitle) & " (" & tabURL & ")" & "\"" as string)
		end repeat

		set AppleScript's text item delimiters to ", "
		set delimitedTitles to tabTitles as string
		set AppleScript's text item delimiters to ""

		set titles to run script "{|" & appId & "|:{" & (delimitedTitles as string) & "}}"
		set spaceTabTitles to spaceTabTitles & titles
	end repeat

	return spaceTabTitles
end tell

on replaceString(targetText, searchString, replacementString)
	set AppleScript's text item delimiters to the searchString
	set the itemList to every text item of targetText
	set AppleScript's text item delimiters to the replacementString
	set targetText to the itemList as string
	set AppleScript's text item delimiters to ""
	return targetText
end replaceString
