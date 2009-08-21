#Persistent

; CapsLock should not be triggered when pressed
SetCapslockState AlwaysOff

; Timer for checking whether the Script was modified
SetTimer,UPDATEDSCRIPT,1000
SetTimer,MorningRoutine,300000

; Modi
ReverseMode := 0
ForwardMode := 1
ReviewMode  := 2

Ver := "0.1"

menu, tray, NoStandard
menu, tray, add, About/Help
menu, tray, add 
menu, tray, add, Exit
menu, tray, default, About/Help

Active := 0
; Always start in Reverse Mode
LoadConfig()
SetMode(ReverseMode)
LoadTasks()
DoMorningRoutine()

; End of auto-execute section
Return

; Add a task with CapsLock+a
CapsLock & a::
	AddTask()
Return

; Show next tasks with CapsLock+s
CapsLock & s::
	ShowNextTasks()
Return

; Show current task with CapsLock+c
CapsLock & c::
	ShowCurrentTask()
Return

; Start working with CapsLock+d
CapsLock & d::
	Work()
Return

; If the Script was modified, reload it
UPDATEDSCRIPT:
	FileGetAttrib,attribs,%A_ScriptFullPath%
	IfInString,attribs,A
	{
		FileSetAttrib,-A,%A_ScriptFullPath%
		SplashTextOn,,,Updated AutofocusAHK,
		Sleep,500
		SplashTextOff
		Reload
	}
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
		}
		Else
		{
			Tasks%TaskCount%_3 := 0
			UnactionedCount := UnactionedCount +1
		}
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

	Message := ""
	Count := 30
	If (TaskCount < 30)
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
	InputBox, NewTask, Add Task - AutofocusAHK %Ver%,,,375,90
	If (ErrorLevel != 1)
	{
		TaskCount := TaskCount + 1
		UnactionedCount := UnactionedCount + 1
		Tasks%Taskcount%_1 := NewTask
		Tasks%Taskcount%_2 := "A" . A_Now
		Tasks%Taskcount%_3 := 0
		SaveTasks()
	}
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
	If (UnactionedCount <= 0)
	{
		MsgBox No unactioned tasks!
		Return
	}
	
	If (Active == 1)
	{
		MsgBox, 3, AutofocusAHK %Ver%, % "You were working on`n`n" . Tasks%CurrentTask%_1 . "`n`nDo you want to re-add this task?"
		IfMsgBox Yes
		{
			Active := 0
			ReAddTask()
		}
		IfMsgBox No
		{
			Active := 0
			MarkAsDone()
		}
	}
	
	Loop
	{
		MsgBox, 3, AutofocusAHK %Ver%, % Tasks%CurrentTask%_1 . "`n`nDoes this task feel ready to be done?"
		IfMsgBox Yes
		{
			Active := 1
			Break
		}
		IfMsgBox No
		{
			SelectNextTask()
		}
		IfMsgBox Cancel
		{
			Break
		}
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
	Tasks%CurrentTask%_2 := Tasks%CurrentTask%_2 . " D" . A_Now
	Tasks%CurrentTask%_3 := 1
	UnactionedCount := UnactionedCount - 1
	SaveTasks()
	CurrentTask := TaskCount + 1
	SelectNextTask()
}

LoadConfig()
{
	global
	FormatTime, Now, , yyyyMMdd
	FormatTime, Hour, , H
	IfNotExist, %A_ScriptDir%\AutofocusAHK.ini
	{
		LastRoutine := Now
		StartRoutineAt := 6
		IniWrite, %LastRoutine%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine
		IniWrite, %StartRoutineAt%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, StartRoutineAt
	}
	Else
	{
		IniRead, LastRoutine, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine, Now
		IniRead, StartRoutineAt, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, StartRoutineAt, 6
	}
}

DoMorningRoutine()
{
	global
	if (((Now - LastRoutine) == 1 and (Hour - StartRoutineAt) >= 0) or (Now - LastRoutine) > 1)
	{
	MsgBox 1
		DismissTasks()
		PutTasksOnNotice()
		SaveTasks()
		IniWrite, %Now%, %A_ScriptDir%\AutofocusAHK.ini, ReviewMode, LastRoutine
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
	}
}

PutTasksOnNotice()
{
	global
	BlockStarted := 0
	Loop %TaskCount%
	{
		If (BlockStarted)
		{
		MsgBox A_Index
			If (Tasks%A_Index%_3 == 1)
			{
				Break
			}
			Tasks%A_Index%_2 := Tasks%A_Index%_2 . " N"
			Message := Message . "- " . Tasks%A_Index%_1 . "`n"
		}
		Else
		{
			If (A_Index== 0)
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

About/Help:
MsgBox, ,About/Help - AutofocusAHK %Ver%, CapsLock + a%A_Tab%Add task`nCapsLock + c%A_Tab%Show current task`nCapsLock + s%A_Tab%Show next tasks`nCapsLock + d%A_Tab%Start/Stop work`n`nAutofocus Time Management System`nCopyright (C) 2009 Mark Forster`nhttp://markforster.net`n`nAutofocusAHK`nCopyright (C) 2009 Andreas Hofmann`nhttp://andreashofmann.net
Return

Exit:
ExitApp, 0
Return

MorningRoutine:
	FormatTime, Now, , yyyyMMdd
	FormatTime, Hour, , H
	DoMorningRoutine()
Return