#Persistent

; CapsLock should not be triggered when pressed
SetCapslockState AlwaysOff

; Timer for checking whether the Script was modified
SetTimer,UPDATEDSCRIPT,1000

; Modi
ReverseMode := 0
ForwardMode := 1
ReviewMode  := 2

Active := 0
; Always start in Reverse Mode
SetMode(ReverseMode)
LoadTasks()

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
	Loop, read, %A_ScriptDir%\Tasks.txt
	{
		TaskCount := TaskCount + 1
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			Tasks%TaskCount%_%A_Index% := A_LoopField
		}
		If (InStr(Tasks%TaskCount%_2, "D"))
		{
			Tasks%TaskCount%_3 := 1
		}
		Else
		{
			Tasks%TaskCount%_3 := 0		
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
	MsgBox %Message%
}

;Show Current Task
ShowCurrentTask()
{
	global
	MsgBox % Tasks%CurrentTask%_1
}

;Add a New Task
AddTask()
{
	global
	InputBox, NewTask, Add Task - AutofocusAHK,,,375,90
	If (ErrorLevel != 1)
	{
		TaskCount := TaskCount + 1
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
	
	If (Active == 1)
	{
		MsgBox, 3, AutofocusAHK, % "You were working on`n`n" . Tasks%CurrentTask%_1 . "`n`nDo you want to re-add this task?"
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
		MsgBox, 3, AutofocusAHK, % Tasks%CurrentTask%_1 . "`n`nDoes this task feel ready to be done?"
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

ReAddTask()
{
	global
	TaskCount := TaskCount + 1
	Tasks%Taskcount%_1 := Tasks%CurrentTask%_1
	Tasks%Taskcount%_2 := "A" . A_Now
	Tasks%Taskcount%_3 := 0
	MarkAsDone()
}

MarkAsDone()
{
	global
	Tasks%CurrentTask%_2 := Tasks%CurrentTask%_2 . "D" . A_Now
	Tasks%CurrentTask%_3 := 1
	SaveTasks()
	CurrentTask := TaskCount + 1
	SelectNextTask()
}