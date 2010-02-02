; AutofocusAHK
;
; This file holds all functions specific to the Autofocus 5 system. 
;
; @author    Andreas Hofmann
; @license   See LICENSE.txt
; @version   0.9.3
; @since     0.9.3

AF5_IsReviewOptional()
{
    Return 0
}

AF5_IsValidTask(TaskName, TaskStats)
{
  global
	If (TaskName == "Change to review mode")
	{
		Return 0
	}
	If (TaskName == "Change to forward mode")
	{
	Return 0
	}
	If (TaskName == "---")
	{
	  HasClosedList := 1
    LastTaskInClosedList := TaskCount
		Return 0
	}	
	Return 1
}

AF5_PostTaskLoad()
{
  global
	If (TaskCount >= TasksPerPage and HasClosedList == 0)
	{
	  HasClosedList := 1
    LastTaskInClosedList := TaskCount
		SaveTasks()
	}
  If (CurrentTask == 0 or Tasks%CurrentTask%_3 == 4)
  {
  	SelectNextTask()
  }
}

AF5_PostTaskAdd()
{
  global
	If (TaskCount >= TasksPerPage and HasClosedList == 0)
	{
	  HasClosedList := 1
    LastTaskInClosedList := TaskCount
		SaveTasks()
	}
}

AF5_SelectNextTask()
{
	global
	If (UnactionedCount > 0 or HasTasksOnReview)
	{
			Start := CurrentTask
			Loop
			{
      			CurrentTask := CurrentTask + 1
          		If (!InStr(Tasks%CurrentTask%_2, "D") and InStr(Tasks%CurrentTask%_2, "R"))
	 			{
  	 			    If (CurrentMode != ReviewMode)
	 			    {
                      ReviewComplete := 1
  	                  ReviewTask := CurrentTask
  	                  PreviousMode := CurrentMode
                      CurrentMode := ReviewMode
                    } 
                }

				If (HasClosedList and CurrentTask == LastTaskInClosedList+1)
				{
					If (ActionOnCurrentPass or (ActionOnCurrentPass and CreatingList))
					{
					  If (!CreatingList)
					  {
      				CurrentPass := CurrentPass + 1
  						ActionOnCurrentPass := 0
						}
            CurrentTask := 0
					}
					Else If (!CreatingList)
					{
 						If (CurrentPass == 1)
						{
                            AF5_DismissTasks()
							CurrentPass := 1
							ActionOnCurrentPass := 0
						}
						Else
						{                              
							CurrentPass := 1
							ActionOnCurrentPass := 0
							
						}
					}
				}
				If (CurrentTask > TaskCount)
				{
						CurrentTask := 0
        }
				If (Tasks%CurrentTask%_4 == 0 or (UnactionedCount == 0 and HasTasksOnReview == 0) (UnactionedCount == 0 and CurrentMode == ReviewMode and HasTasksOnReview == 1)) 
				{
					Break
				}
			}
	}
}


AF5_Work()
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
		If (HasClosedList == 0)
    	{
    	  HasClosedList := 1
        LastTaskInClosedList := TaskCount
    		SaveTasks()
    	}

		ShowWorkWindow()
	}
}

SetBacklogStats()
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

AF5_DoMorningRoutine()
{
		SaveTasks()
		BackupTasks()
}

AF5_DismissTasks()
{
	global
	Message := ""
	Loop
	{
	  If (A_Index > LastTaskInClosedList)
	  {
      Break
    }
		If (Tasks%A_Index%_4 == 0)
		{
			Tasks%A_Index%_2 := Tasks%A_Index%_2 . " R" . A_Now
			Tasks%A_Index%_4 := 1
			UnactionedCount := UnactionedCount - 1
			Message := Message . "- " . Tasks%A_Index%_1 . "`n"
		}
	}
	If (Message != "")
	{
		MsgBox The following tasks are now on review:`n`n%Message%
		HasTasksOnReview := 1
	}
	LastTaskInClosedList := TaskCount
	SaveTasks()
}

AF5_GetWorkWindowTitle()
{
	global CurrentTask,LastTaskInClosedList,CurrentPass,ActionOnCurrentPass
	If (CurrentTask > LastTaskInClosedList)
	{
		Title := "Open List"
	}
	Else                                     
	{
		Title := "Pass " . CurrentPass
      If (ActionOnCurrentPass == 0)
      {
        Title .= "(!)"                                   
      }
      Title .= " - Closed List"
    }
	Title .= GetStandardWindowTitle()
	Return Title
}

AF5_GetReviewWindowTitle()
{
	Title := "Review"
	Title .= GetStandardWindowTitle()
	Return Title
}