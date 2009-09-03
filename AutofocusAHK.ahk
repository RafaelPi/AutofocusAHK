#Persistent

; CapsLock should not be triggered when pressed
SetCapslockState AlwaysOff

SetTimer,MorningRoutine,300000

; Modi
ReverseMode := 0
ForwardMode := 1
ReviewMode  := 2

HasReviewModeTask := 0
HasForwardModeTask := 0
Ver := "0.8"

menu, tray, NoStandard
menu, tray, add, About/Help
menu, tray, add 
menu, tray, add, Exit
menu, tray, default, About/Help

Active := 0
; Always start in Reverse Mode
LoadConfig()
SetMode(ReverseMode)
PreviousMode := ReverseMode
LoadTasks()
DoMorningRoutine()

; End of auto-execute section
Return

; Add a task with CapsLock+a
TriggerAddTask:
	If (WinActive("Add Task - AutofocusAHK"))
	{
		WinClose
	}
	Else
	{
		AddTask()
	}
Return

; Show next tasks with CapsLock+s
TriggerShowNextTasks:
	ShowNextTasks()
Return

; Show current task with CapsLock+c
TriggerShowCurrentTask:
	ShowCurrentTask()
Return

; Start working with CapsLock+d
TriggerWork:
	If (WinActive("Reverse Mode - AutofocusAHK") or WinActive("Forward Mode - AutofocusAHK") or WinActive("Done - AutofocusAHK") or WinActive("Forward Mode - AutofocusAHK") or WinActive("Review Mode - AutofocusAHK"))
	{
		WinClose
	}
	Else
	{
		Work()
	}
Return

TriggerToggleAutostart:
	ToggleStartup()
Return

TriggerShowOnNotice:
	ShowOnNotice()
Return

TriggerExport:
	Export()
Return


; Load tasks from file Tasks.txt
LoadTasks()
{
	global
	TaskCount := 0
	UnactionedCount := 0
	Loop, read, %A_ScriptDir%\Tasks.txt
	{
		TaskCount := TaskCount + 1
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			Tasks%TaskCount%_%A_Index% := A_LoopField
		}
		If (InStr(Tasks%TaskCount%_2, "D") or InStr(Tasks%TaskCount%_2, "R"))
		{
			Tasks%TaskCount%_3 := 1
			If (!InStr(Tasks%TaskCount%_2, "D") and InStr(Tasks%TaskCount%_2, "R"))
			{
				HasTasksOnReview := 1
			}
		}
		Else
		{
			Tasks%TaskCount%_3 := 0
			UnactionedCount := UnactionedCount +1
			If (Tasks%TaskCount%_1 == "Change to review mode")
			{
				HasReviewModeTask := 1
			}
			If (Tasks%TaskCount%_1 == "Change to forward mode")
			{
				HasForwardModeTask := 1
			}
		}
	}
	If (TaskCount >= TasksPerPage * 3 and HasForwardModeTask == 0)
	{
			TaskCount := TaskCount + 1
			UnactionedCount := UnactionedCount + 1
			Tasks%Taskcount%_1 := "Change to forward mode"
			Tasks%Taskcount%_2 := "A" . A_Now
			Tasks%Taskcount%_3 := 0
			HasForwardModeTask := 1
			SaveTasks()
	}
	CurrentTask := TaskCount + 1
	SelectNextTask()
}

; Save tasks to file Tasks.txt
SaveTasks()
{
	global TaskCount
	Content := ""
	Loop %TaskCount%
	{
		Content := Content . Tasks%A_Index%_1 . A_Tab . Tasks%A_Index%_2 . "`n"
	}
	FileDelete, %A_ScriptDir%\Tasks.txt
	FileAppend, %Content%, %A_ScriptDir%\Tasks.txt
}

; Show Next Tasks
ShowNextTasks()
{
	global
	If (UnactionedCount <= 0)
	{
		MsgBox No unactioned tasks!
		Return
	}
	PreviousTask := CurrentTask

	Message := ""
	Count := 30
	If (UnactionedCount < 30)
	{
		Count := TaskCount
	}
	Loop %Count%
	{
		If (Tasks%A_Index%_3 == 0)
		{
			Message := Message . Tasks%A_Index%_1 . "`n"
		}
	}
	CurrentTask := PreviousTask
	MsgBox,,AutofocusAHK %Ver%, %Message%
}

;Show Current Task
ShowCurrentTask()
{
	global
	If (UnactionedCount <= 0)
	{
		MsgBox No unactioned tasks!
		Return
	}
	
	MsgBox % Tasks%CurrentTask%_1
}

;Add a New Task
AddTask()
{
	global
	Gui, 3:Destroy
	Gui, 3:Add, Edit, w400 vNewTask  ; The ym option starts a new column of controls.
	Gui, 3:Add, Button,ym default gButtonAdd, Add
	Gui, 3:+LabelGuiAdd
	Gui, 3:Show, , Add Task - AutofocusAHK %Ver%
}

;Set the current mode
SetMode(Mode)
{
	global CurrentMode, ReverseMode, ForwardMode, ReviewMode
	CurrentMode := Mode
}

;Work
Work()
{
	global
	
	If (CurrentMode == ReviewMode)
	{
		ShowReviewWindow()
	}
	Else If (Active == 1)
	{
		ShowDoneWindow()
	}
	Else
	{
		If (UnactionedCount <= 0)
		{
			MsgBox No unactioned tasks!
			Return
		}
		ShowWorkWindow()
	}
}


;Select Next Task
SelectNextTask()
{
	global
	If (UnactionedCount > 0)
	{
		If (CurrentMode == ReverseMode)
		{
			Loop
			{
				CurrentTask := CurrentTask - 1
				If (CurrentTask == 0)
				{
					CurrentTask := TaskCount
				}
				If (Tasks%CurrentTask%_3 == 0) 
				{
					Break
				}
			}
		}
		Else If (CurrentMode == ForwardMode)
		{
			Start := CurrentTask
			Loop
			{
				CurrentTask := CurrentTask + 1
				If (CurrentTask > LastTaskOnPage)
				{
					If (ActionOnCurrentPass)
					{
						CurrentTask := FirstTaskOnPage
						CurrentPass := CurrentPass + 1
						ActionOnCurrentPass := 0
					}
					Else
					{
						If (CurrentPass == 1)
						{
							CurrentMode := ReverseMode
							TaskCount := TaskCount + 1
							UnactionedCount := UnactionedCount + 1
							Tasks%Taskcount%_1 := "Change to forward mode"
							Tasks%Taskcount%_2 := "A" . A_Now
							Tasks%Taskcount%_3 := 0
							HasForwardModeTask := 1
							SaveTasks()
							CurrentTask := TaskCount + 1
							SelectNextTask()
							Break
						}
						Else
						{
							CurrentPass := 1
							ActionOnCurrentPass := 0
							SelectNextActivePage()
						}
					}
				}
				If (Tasks%CurrentTask%_3 == 0) 
				{
					Break
				}
			}
		}
	}
}

ReAddTask()
{
	global
	TaskCount := TaskCount + 1
	UnactionedCount := UnactionedCount + 1
	Tasks%Taskcount%_1 := Tasks%CurrentTask%_1
	Tasks%Taskcount%_2 := "A" . A_Now
	Tasks%Taskcount%_3 := 0
	MarkAsDone()
}

MarkAsDone()
{
	global
	Tasks%CurrentTask%_2 := Tasks%CurrentTask%_2 . " D" . A_Now . " T" . TimePassed
	Tasks%CurrentTask%_3 := 1
	UnactionedCount := UnactionedCount - 1
	SaveTasks()
	If (CurrentMode == ReverseMode)
	{
		CurrentTask := TaskCount + 1
	}
	SelectNextTask()
}

LoadConfig()
{
	global
	FormatTime, Now, , yyyyMMdd
	FormatTime, Hour, , H
	IniRead, StartWithWindows, %A_ScriptDir%\AutofocusAHK.ini, General, StartWithWindows
	If (StartWithWindows == "ERROR")
	{
		StartWithWindows := 0
		ToggleStartup()
	}
	IniRead, DoBackups, %A_ScriptDir%\AutofocusAHK.ini, General, DoBackups
	If (DoBackups == "ERROR")
	{
		DoBackups := 1
		IniWrite, %DoBackups%, %A_ScriptDir%\AutofocusAHK.ini, General, DoBackups
	}
	IniRead, BackupsToKeep, %A_ScriptDir%\AutofocusAHK.ini, General, BackupsToKeep
	If (BackupsToKeep == "ERROR")
	{
		BackupsToKeep := 10
		IniWrite, %BackupsToKeep%, %A_ScriptDir%\AutofocusAHK.ini, General, BackupsToKeep
	}
	IniRead, LastRoutine, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine
	If (LastRoutine == "ERROR")
	{
		LastRoutine := Now
		IniWrite, %LastRoutine%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine
	}
	IniRead, StartRoutineAt, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, StartRoutineAt
	If (StartRoutineAt == "ERROR")
	{
		StartRoutineAt := 6
		IniWrite, %StartRoutineAt%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, StartRoutineAt
	}
	IniRead, TasksPerPage, %A_ScriptDir%\AutofocusAHK.ini, ForwardMode, TasksPerPage
	If (TasksPerPage == "ERROR")
	{
		TasksPerPage := 20
		IniWrite, %TasksPerPage%, %A_ScriptDir%\AutofocusAHK.ini, ForwardMode, TasksPerPage
	}
	IniRead, HKAddTask, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKAddTask
	If (HKAddTask == "ERROR")
	{
		HKAddTask := "CapsLock & a"
		IniWrite, %HKAddTask%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKAddTask
	}
	Hotkey, %HKAddTask%, TriggerAddTask
	IniRead, HKWork, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKWork
	If (HKWork == "ERROR")
	{
		HKWork := "CapsLock & d"
		IniWrite, %HKWork%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKWork
	}
	Hotkey, %HKWork%, TriggerWork
	IniRead, HKShowNextTasks, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowNextTasks
	If (HKShowNextTasks == "ERROR")
	{
		HKShowNextTasks := "CapsLock & s"
		IniWrite, %HKShowNextTasks%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowNextTasks
	}
	Hotkey, %HKShowNextTasks%, TriggerShowNextTasks
	IniRead, HKShowCurrentTask, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowCurrentTask
	If (HKShowCurrentTask == "ERROR")
	{
		HKShowCurrentTask := "CapsLock & c"
		IniWrite, %HKShowCurrentTask%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowCurrentTask
	}
	Hotkey, %HKShowCurrentTask%, TriggerShowCurrentTask
	IniRead, HKShowOnNotice, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowOnNotice
	If (HKShowOnNotice == "ERROR")
	{
		HKShowOnNotice := "CapsLock & n"
		IniWrite, %HKShowOnNotice%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKShowOnNotice
	}
	Hotkey, %HKShowOnNotice%, TriggerShowOnNotice
	IniRead, HKToggleAutostart, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKToggleAutostart
	If (HKToggleAutostart == "ERROR")
	{
		HKToggleAutostart := "CapsLock & 1"
		IniWrite, %HKToggleAutostart%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKToggleAutostart
	}
	Hotkey, %HKToggleAutostart%, TriggerToggleAutostart
	IniRead, HKExport, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKExport
	If (HKExport == "ERROR")
	{
		HKExport := "CapsLock & e"
		IniWrite, %HKExport%, %A_ScriptDir%\AutofocusAHK.ini, HotKeys, HKExport
	}
	Hotkey, %HKExport%, TriggerExport

}

DoMorningRoutine()
{
	global
	if (((Now - LastRoutine) == 1 and (Hour - StartRoutineAt) >= 0) or (Now - LastRoutine) > 1)
	{
		DismissTasks()
		PutTasksOnNotice()
		SaveTasks()
		BackupTasks()
		LastRoutine := Now
		IniWrite, %Now%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine
		If (Tasks%CurrentTask%_3 == 1) 
		{
			SelectNextTask()
		}
	}
}

DismissTasks()
{
	global
	Message := ""
	Loop %TaskCount%
	{
		If (Tasks%A_Index%_3 == 0 and InStr(Tasks%A_Index%_2, "N"))
		{
			Tasks%A_Index%_2 := Tasks%A_Index%_2 . " R" . A_Now
			Tasks%A_Index%_3 := 1
			UnactionedCount := UnactionedCount - 1
			Message := Message . "- " . Tasks%A_Index%_1 . "`n"
		}
	}
	If (Message != "")
	{
		MsgBox The following tasks are now on review:`n`n%Message%
		HasTasksOnReview := 1
		If (HasReviewModeTask == 0)
		{
			TaskCount := TaskCount + 1
			UnactionedCount := UnactionedCount + 1
			Tasks%Taskcount%_1 := "Change to review mode"
			Tasks%Taskcount%_2 := "A" . A_Now
			Tasks%Taskcount%_3 := 0
			HasReviewModeTask := 1
		}
	}
}

PutTasksOnNotice()
{
	global
	BlockStarted := 0
	Message := ""
	Loop %TaskCount%
	{
		If (BlockStarted)
		{
			If (Tasks%A_Index%_3 == 1)
			{
				Break
			}
			if (Tasks%A_Index%_1 != "Change to review mode" and Tasks%A_Index%_1 != "Change to forward mode")
			{
				Tasks%A_Index%_2 := Tasks%A_Index%_2 . " N"
				Message := Message . "- " . Tasks%A_Index%_1 . "`n"
			}
		}
		Else
		{
			If (Tasks%A_Index%_3 == 0 && Tasks%A_Index%_1 != "Change to review mode" and Tasks%A_Index%_1 != "Change to forward mode")
			{
				BlockStarted := 1
				Tasks%A_Index%_2 := Tasks%A_Index%_2 . " N"
				Message := Message . "- " . Tasks%A_Index%_1 . "`n"
			}
		}
	}
	If (Message != "")
	{
		MsgBox The following tasks are now on notice for review:`n`n%Message%
	}
}

DoReview()
{
	global
	ReviewComplete := 1
	ReviewTask := 0
	SelectNextReviewTask()
}

BackupTasks()
{
	global DoBackups, BackupsToKeep
	If (DoBackups)
	{
		If (!FileExist(A_ScriptDir . "\Backups"))
		{
			FileCreateDir, %A_ScriptDir%\Backups
		}
		FormatTime, BackupTime, , yyyy-MM-dd
		FileCopy, %A_ScriptDir%\Tasks.txt, %A_ScriptDir%\Backups\Tasks-%BackupTime%.txt
		
		Count := 0
		Loop, %A_ScriptDir%\Backups\*.*
		{
			Count := Count + 1
			FileList = %FileList%%A_LoopFileName%`n
			Sort, FileList
		}
		If (Count > BackupsToKeep)
		{
			FilesToDelete := Count - BackupsToKeep
			Count := 0
			Loop, parse, FileList, `n
			{
				if (A_LoopField == "")
				{
					Continue
				}
				Count := Count + 1
				If (Count > FilesToDelete)
				{
					Break
				}
				FileDelete, %A_ScriptDir%\Backups\%A_LoopField%
			}
		}
	}
}

ToggleStartup()
{
	If (StartWithWindows)
	{
		Message := "Autostart is currently enabled."
	}
	Else 
	{
		Message := "Autostart is currently disabled."
	}
	Message := Message . "`n`nDo you want AutofocusAHK to start with Windows in the future?"

	MsgBox, 4, AutofocusAHK %Ver%, %Message%
	IfMsgBox Yes
	{
		FileCreateShortcut, "%A_ScriptFullPath%", %A_Startup%\AutofocusAHK.lnk, %A_ScriptDir% 
		StartWithWindows := 1
		IniWrite, 1, %A_ScriptDir%\AutofocusAHK.ini, General, StartWithWindows
	}
	IfMsgBox No
	{
		FileDelete, %A_Startup%\AutofocusAHK.lnk
		StartWithWindows := 0
		IniWrite, 0, %A_ScriptDir%\AutofocusAHK.ini, General, StartWithWindows
	}
}

ShowOnNotice()
{
	global
	Message := ""
	Loop %TaskCount%
	{
		If (Tasks%A_Index%_3 == 0 and InStr(Tasks%A_Index%_2, "N"))
		{
			Message := Message . "- " . Tasks%A_Index%_1 . "`n"
		}
	}
	If (Message != "")
	{
		MsgBox The following tasks are on notice:`n`n%Message%
	}
	Else
	{
		MsgBox There are currently no tasks on notice.
	}
}

SetForwardModeStats()
{
	global
	CurrentPage := Ceil(CurrentTask/TasksPerPage)
	If (TaskCount < TasksPerPage)
	{
		LastTaskOnPage := TaskCount
		FirstTaskOnPage := 1
	}
	Else
	{
		LastTaskOnPage := CurrentPage * TasksPerPage
		FirstTaskOnPage := LastTaskOnPage - TasksPerPage + 1
		If (LastTaskOnPage > TaskCount)
		{
			LastTaskOnPage := TaskCount
		}
	}
}

SelectNextActivePage()
{
	global
	If (UnactionedCount > 0)
	{
		Loop
		{
			If (Tasks%CurrentTask%_3 == 0)
			{
				Break
			}
			CurrentTask := CurrentTask +1
		}
		SetForwardModeStats()
		CurrentTask := FirstTaskOnPage - 1
	}
}

Export()
{
	global
	If (!FileExist(A_ScriptDir . "\Export"))
	{
		FileCreateDir, %A_ScriptDir%\Export
	}
	FormatTime, ExportTime, , yyyy-MM-dd
	Export := ""
	Export := "<!doctype html>" 
		. "<html><head><title>Export " . ExportTime . " - AutofocusAHK</title>"
		. "<style type=""text/css"">"
		. "body {background-color: #FFF;font-family: Corbel, ""Lucida Grande"", ""Lucida Sans Unicode"", ""Lucida Sans"", ""DejaVu Sans"", ""Bitstream Vera Sans"", ""Liberation Sans"", Verdana, ""Verdana Ref"", sans-serif;} "
		. "table {width:90%; margin:0 auto;border-collapse: collapse;border-spacing: 0;} "
		. "th,td {border:1px solid #666;} "
		. ".done {background:#CDFF7F;} "
		. ".review {background:#F5FF7F;} "
		. ".datefield {whitespace:nowrap;} "
		. "th {text-align:center;background:#DDD; font-weight:bold;} "
		. "th,td {padding:0.3em;} "
		. "h1 {font-size:16px; color:#666; padding:0; margin:0.5em auto; width:90%;}"
		. "h2 {font-size:24px; color:#666; padding:0; margin:0.5em auto; width:90%;}"
		. "</style>"
		. "</head><body>"
		. "<h1>AutofocusAHK</h1>"
		. "<h2>Export " . ExportTime . "</h2><table cellspacing=""0"">"
		. "<tr><th colspan=""4"">Page 1</th></tr>"
		. "<tr><th>Task</th><th>Added</th><th>On&nbsp;Review</th><th><nobr>Done/Re-Added</nobr></th></tr>"
		ExportPage := 1
	Loop, %TaskCount%
	{
		If (ExportPage < ceil(A_Index/TasksPerPage))
		{
			ExportPage := ExportPage + 1
			Export .= "<tr><th colspan=""4"">Page " . ExportPage . "</th></tr>"
			. "<tr><th>Task</th><th>Added</th><th>On Review</th><th><nobr>Done/Re-Added</nobr></th></tr>"
		}
		Export .= "<tr"
		If (Tasks%A_Index%_3 == 1)
		{
			Export .= " class="""
			If (InStr(Tasks%A_Index%_2, "R"))
			{
				Export .= "review"
			}
			Else If (InStr(Tasks%A_Index%_2, "D"))
			{
				Export .= " done"
			}
			Export .= """"
		}
		Export .= ">"
				. "<td>" 
					. Tasks%A_Index%_1
				. "</td>"
		ExportAdded := ""
		ExportReview := ""
		ExportDone := ""
		Loop, Parse, Tasks%A_Index%_2, %A_Space%
		{
			If (InStr(A_LoopField, "D"))
			{
				ExportDone := SubStr(A_LoopField, 2)
				FormatTime, ExportDone, %ExportDone%, yyyy-MM-dd'&nbsp;'H:mm
			}
			If (InStr(A_LoopField, "R"))
			{
				ExportReview := SubStr(A_LoopField, 2)
				FormatTime, ExportReview, %ExportReview%, yyyy-MM-dd'&nbsp;'H:mm
			}
			If (InStr(A_LoopField, "A"))
			{
				ExportAdded := SubStr(A_LoopField, 2)
				FormatTime, ExportAdded, %ExportAdded%, yyyy-MM-dd'&nbsp;'H:mm
			}

		}
		Export .= "<td><nobr>" 
					. ExportAdded
				. "<nobr></td>"
				. "<td><nobr>" 
					. ExportReview
				. "<nobr></td>"
				. "<td><nobr>" 
					. ExportDone
				. "</nobr></td>"
		
		Export .= "</tr>"
	}
	
	Export .= "</table></body></html>"
	
	FileDelete, %A_ScriptDir%\Export\Tasks-%ExportTime%.html
	FileAppend, %Export%, %A_ScriptDir%\Export\Tasks-%ExportTime%.html 
	Run, %A_ScriptDir%\Export\Tasks-%ExportTime%.html 
}

ShowWorkWindow()
{
	global
	Gui, Destroy
	Gui, Font, Bold
	Gui, Add, Text, Y20 w400 Center vTaskControl, % Tasks%CurrentTask%_1
	Gui, Font, Norm
	GuiControlGet, TaskPos, Pos, TaskControl
	NewY := TaskPosY + TaskPosH + 20
	NewYT := NewY + 5
	GuiControl, Text, ModeControl, ForwardMode
	;GuiControl, Move, TaskControl, w200 h100
	Gui, Add, Text, vQuestionLabel Y%NewYT%,Does this task feel ready to be done? 
	Gui, Add, Button, gButtonReady vYesButton Y%NewY%, &Yes
	Gui, Add, Button, gButtonNotReady vNoButton Y%NewY% Default, &No
	;Gui, Add, Button, vCancelButton Y%NewY%, &Cancel
	;GuiControlGet, CancelPos, Pos, CancelButton
	;DiffX := CancelPosX + CancelPosW - TaskPosX - TaskPosW
	;CancelPosX := CancelPosX - DiffX
	;GuiControl, Move, CancelButton, x%CancelPosX% y%CancelPosY% w%CancelPosW% h%CancelPosH%
	GuiControlGet, NoPos, Pos, NoButton
	DiffX := NoPosX + NoPosW - TaskPosX - TaskPosW
	NoPosX := NoPosX - DiffX
	GuiControl, Move, NoButton, x%NoPosX% y%NoPosY% w%NoPosW% h%NoPosH%
	GuiControlGet, YesPos, Pos, YesButton
	YesPosX := YesPosX - DiffX
	GuiControl, Move, YesButton, x%YesPosX% y%YesPosY% w%YesPosW% h%YesPosH%
	GuiControlGet, QuestionPos, Pos, QuestionLabel
	QuestionPosX := QuestionPosX - DiffX
	GuiControl, Move, QuestionLabel, x%QuestionPosX% y%QuestionPosY% w%QuestionPosW% h%QuestionPosH%
	If (CurrentMode == ForwardMode)
	{
		Title := "Forward Mode"
	}
	Else
	{
		Title := "Reverse Mode"
	}
	Gui, Show, Center Autosize, %Title% - AutofocusAHK %Ver%
	GuiControl, Focus, NoButton
	Return
}

ShowDoneWindow()
{
	global
	SetTimer,UpdateTime,Off
	Gui, 2:Destroy
	Gui, Destroy
	Gui, Add, Text, vWorkingOn, You were working on
	GuiControlGet, WorkingPos, Pos, WorkingOn
	NewY := WorkingPosY + WorkingPosH + 20
	Gui, Font, Bold
	Gui, Add, Text, x%WorkingPosX% Y%NewY% w400 Center vTaskControl, % Tasks%CurrentTask%_1
	Gui, Font, Norm
	GuiControlGet, TaskPos, Pos, TaskControl
	NewY := TaskPosY + TaskPosH + 20
	NewYT := NewY + 5
	GuiControl, Text, ModeControl, ForwardMode
	;GuiControl, Move, TaskControl, w200 h100
	Gui, Add, Text, vQuestionLabel Y%NewYT%,Do you want to re-add this task?
	Gui, Add, Button, gButtonReAdd vYesButton Y%NewY%, &Yes
	Gui, Add, Button, gButtonNoReAdd vNoButton Y%NewY% Default, &No
	;Gui, Add, Button, vCancelButton Y%NewY%, &Cancel
	;GuiControlGet, CancelPos, Pos, CancelButton
	;DiffX := CancelPosX + CancelPosW - TaskPosX - TaskPosW
	;CancelPosX := CancelPosX - DiffX
	;GuiControl, Move, CancelButton, x%CancelPosX% y%CancelPosY% w%CancelPosW% h%CancelPosH%
	GuiControlGet, NoPos, Pos, NoButton
	DiffX := NoPosX + NoPosW - TaskPosX - TaskPosW
	NoPosX := NoPosX - DiffX
	GuiControl, Move, NoButton, x%NoPosX% y%NoPosY% w%NoPosW% h%NoPosH%
	GuiControlGet, YesPos, Pos, YesButton
	YesPosX := YesPosX - DiffX
	GuiControl, Move, YesButton, x%YesPosX% y%YesPosY% w%YesPosW% h%YesPosH%
	GuiControlGet, QuestionPos, Pos, QuestionLabel
	QuestionPosX := QuestionPosX - DiffX
	GuiControl, Move, QuestionLabel, x%QuestionPosX% y%QuestionPosY% w%QuestionPosW% h%QuestionPosH%
	Gui, +LabelGuiDone
	Gui, Show, Center Autosize, Done - AutofocusAHK %Ver% 
	GuiControl, Focus, YesButton
	Return
}

CapsLock & y::
ShowReviewWindow()
Return
ShowReviewWindow()
{
	global
	Gui, Destroy
	Gui, Font, Bold
	Gui, Add, Text, Y20 w400 Center vTaskControl, % Tasks%ReviewTask%_1
	Gui, Font, Norm
	GuiControlGet, TaskPos, Pos, TaskControl
	NewY := TaskPosY + TaskPosH + 20
	NewYT := NewY + 5
	GuiControl, Text, ModeControl, ForwardMode
	;GuiControl, Move, TaskControl, w200 h100
	Gui, Add, Text, vQuestionLabel Y%NewYT%,Do you want to re-add this task?
	Gui, Add, Button, gButtonReviewYes vRvYesButton Y%NewY%, &Yes
	Gui, Add, Button, gButtonReviewNo vRvNoButton Y%NewY% Default, &Not now
	Gui, Add, Button, gButtonReviewNever vRvNeverButton Y%NewY%, Ne&ver
	;Gui, Add, Button, vCancelButton Y%NewY%, &Cancel
	;GuiControlGet, CancelPos, Pos, CancelButton
	;DiffX := CancelPosX + CancelPosW - TaskPosX - TaskPosW
	;CancelPosX := CancelPosX - DiffX
	;GuiControl, Move, CancelButton, x%CancelPosX% y%CancelPosY% w%CancelPosW% h%CancelPosH%
	GuiControlGet, NeverPos, Pos, RvNeverButton
	DiffX := NeverPosX + NeverPosW - TaskPosX - TaskPosW
	NeverPosX := NeverPosX - DiffX
	GuiControl, Move, RvNeverButton, x%NeverPosX% y%NeverPosY% w%NeverPosW% h%NeverPosH%
	GuiControlGet, YesPos, Pos, RvYesButton
	YesPosX := YesPosX - DiffX
	GuiControl, Move, RvYesButton, x%YesPosX% y%YesPosY% w%YesPosW% h%YesPosH%
	GuiControlGet, NoPos, Pos, RvNoButton
	NoPosX := NoPosX - DiffX
	GuiControl, Move, RvNoButton, x%NoPosX% y%NoPosY% w%NoPosW% h%NoPosH%
	GuiControlGet, QuestionPos, Pos, QuestionLabel
	QuestionPosX := QuestionPosX - DiffX
	GuiControl, Move, QuestionLabel, x%QuestionPosX% y%QuestionPosY% w%QuestionPosW% h%QuestionPosH%
	;Gui, +LabelGuiReview
	Gui, Show, Center Autosize, Review Mode - AutofocusAHK %Ver%
	GuiControl, Focus, RvNoButton
	Return
}


ShowStatusWindow()
{
	global
	Gui, 2:Destroy
	Gui, 2:+AlwaysOnTop -SysMenu +Owner -Caption Resize MinSize MaxSize
	Gui, 2:Add, Text, y10, % Tasks%CurrentTask%_1
	Gui, 2:Add, Text, y10 Right vTimeControl, 00:00:00
	Gui, 2:Add, Button,ym default gButtonStop vStopButton, Stop
	Gui, 2:Add, Button,ym gButtonHide, Hide for 30s
	Gui, 2:Show, y0 xCenter NoActivate AutoSize, Status - AutohotkeyAHK
	GuiControl, Focus, StopButton
}

SelectNextReviewTask()
{
	global
	Loop
	{
		ReviewTask := ReviewTask + 1
		If (ReviewTask > TaskCount)
		{
			CurrentMode := PreviousMode
			If (!ReviewComplete)
			{
				ReAddTask()
			}
			Else
			{
				MarkAsDone()
			}
			Gui, Destroy
			MsgBox, Review done!
			Break
		}
		
		If (Tasks%ReviewTask%_3 == 1)
		{
			If (!InStr(Tasks%ReviewTask%_2, "D") and InStr(Tasks%ReviewTask%_2, "R"))
			{
				ShowReviewWindow()
				Break
			}
		}
	}
}

GuiClose:
GuiEscape:
Gui, Hide
Return

GuiDoneClose:
GuiDoneEscape:
	Gui, Destroy
	ShowStatusWindow()
	SetTimer,UpdateTime,1000
Return

GuiAddClose:
GuiAddEscape:
	Gui, 3:Destroy
Return


ButtonNotReady:
SelectNextTask()
ShowWorkWindow()
Return

ButtonReady:
Gui, Hide
If (Tasks%CurrentTask%_1 == "Change to review mode")
{
	Active := 0
	PreviousMode := CurrentMode
	CurrentMode := ReviewMode
	DoReview()
}
Else If (Tasks%CurrentTask%_1 == "Change to forward mode")
{
	Active := 0
	CurrentMode := ForwardMode
	CurrentPass := 1
	ActionOnCurrentPass := 0
	Tasks%CurrentTask%_2 := Tasks%CurrentTask%_2 . " D" . A_Now
	Tasks%CurrentTask%_3 := 1
	UnactionedCount := UnactionedCount - 1
	SaveTasks()
	CurrentTask := 1
	SelectNextActivePage()
	SelectNextTask()
	Work()
}
Else
{
	Active := 1
	TimePassed := 0
	ShowStatusWindow()
	SetTimer,UpdateTime,1000
}
Return

ButtonReAdd:
	Active := 0
	If (CurrentMode == ForwardMode)
	{
		ActionOnCurrentPass := 1
	}
	ReAddTask()
	ShowWorkWindow()
Return

ButtonNoReAdd:
	Active := 0
	If (CurrentMode == ForwardMode)
	{
		ActionOnCurrentPass := 1
	}
	MarkAsDone()
	ShowWorkWindow()
Return

ButtonAdd:
	Gui, Submit
	If (NewTask != "")
	{
		TaskCount := TaskCount + 1
		UnactionedCount := UnactionedCount + 1
		Tasks%Taskcount%_1 := NewTask
		Tasks%Taskcount%_2 := "A" . A_Now
		Tasks%Taskcount%_3 := 0
		SaveTasks()
	}
	Gui, Hide
Return

ButtonHide:
	SetTimer,ReShowStatusWindow,30000
	Gui, 2:Hide
Return

ButtonStop:
	Work()
Return

ButtonReviewYes:
Tasks%ReviewTask%_2 := Tasks%ReviewTask%_2 . " D" . A_Now
Tasks%ReviewTask%_3 := 1

TaskCount := TaskCount + 1
UnactionedCount := UnactionedCount + 1
Tasks%Taskcount%_1 := Tasks%ReviewTask%_1
Tasks%Taskcount%_2 := "A" . A_Now
Tasks%Taskcount%_3 := 0
SelectNextReviewTask()
Return

ButtonReviewNo:
ReviewComplete := 0
SelectNextReviewTask()
Return

ButtonReviewNever:
Tasks%ReviewTask%_2 := Tasks%ReviewTask%_2 . " D" . A_Now
Tasks%ReviewTask%_3 := 1
SelectNextReviewTask()
Return

About/Help:
MsgBox, ,About/Help - AutofocusAHK %Ver%, CapsLock + a%A_Tab%Add task`nCapsLock + c%A_Tab%Show current task`nCapsLock + s%A_Tab%Show next tasks`nCapsLock + d%A_Tab%Start/Stop work`nCapsLock + 1%A_Tab%Toggle autostart`n`nAutofocus Time Management System`nCopyright (C) 2009 Mark Forster`nhttp://markforster.net`n`nAutofocusAHK`nCopyright (C) 2009 Andreas Hofmann`nhttp://andreashofmann.net
Return

Exit:
ExitApp, 0
Return

MorningRoutine:
	FormatTime, Now, , yyyyMMdd
	FormatTime, Hour, , H
	DoMorningRoutine()
Return

ReShowStatusWindow:
	SetTimer,ReShowStatusWindow,Off
	Gui, 2:Show, y0 xCenter NoActivate AutoSize, Status - AutohotkeyAHK
Return

UpdateTime:
	TimePassed := TimePassed + 1
	TimeTemp := TimePassed
	If (TimePassed < 60)
	{
		Hours := 0
		Minutes := 0
		Seconds := TimePassed
	}
	Else If (TimePassed < 3600)
	{
		Hours := 0
		Minutes := 0
		Loop
		{
			TimeTemp := TimeTemp - 60
			Minutes := Minutes + 1
			If (TimeTemp <60)
			{
				break
			}
		}
		Seconds := TimeTemp
	}
	Else
	{
		Hours := 0
		Loop
		{
			TimeTemp := TimeTemp - 3600
			Hours := Hours + 1
			If (TimeTemp < 3600)
			{
				break
			}
		}
		Minutes := 0
		Loop
		{
			If (TimeTemp <60)
			{
				break
			}
			TimeTemp := TimeTemp - 60
			Minutes := Minutes + 1
		}
		Seconds := TimeTemp
	}
	TimeString := ""
	
	If (Hours > 0)
	{
		;If (Hours < 10)
		;{
		;	TimeString := TimeString . "0"
		;}
		TimeString := TimeString . Hours . ":"
		If (Minutes < 10)
		{
			TimeString := TimeString . "0"		
		}
	}
	TimeString := TimeString . Minutes . ":"
	If (Seconds< 10)
	{
		TimeString := TimeString . "0"
	}
	TimeString := TimeString . Seconds

	GuiControl, 2: , TimeControl, %TimeString%
Return