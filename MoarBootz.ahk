/*
Read info from file:
	Startkey
	Pet default
	Unload Pet
	Load Pet
	Deposit All Key
	Alarm Default

Read info from path file:
	Direction to start
	Path to stash
	Path/Click location of chest
	Info for popup
	Default sell/price
	Color of item (Might change to using picture instead)
*/

#SingleInstance Force
OnExit, Quit
SetWorkingDir, %A_ScriptDir%

CoordMode, Mouse, Client
CoordMode, Pixel, Client
CoordMode, ToolTip, Client
Menu, Tray, Icon, fav.ico
SetKeyDelay, 10, 5

ItemLoc:=0
StashItemLoc:=0

IfExist,RPGMO.ini
{
    FileReadLine,Read_Acc,RPGMO.ini,1
    FileReadLine,Read_StartKey,RPGMO.ini,2
    FileReadLine,Alarm,RPGMO.ini,3
    FileReadLine,Read_Steam,RPGMO.ini,4
    FileReadLine,Key_LoadPet,RPGMO.ini,5
    FileReadLine,Key_UnloadPet,RPGMO.ini,6
    FileReadLine,Key_DepositAll,RPGMO.ini,7
    FileReadLine,EmptyFromStash,RPGMO.ini,8
    FileReadLine,DestroyOres,RPGMO.ini,9
    FileReadLine,PetSet,RPGMO.ini,10

    Hotkey,%Read_StartKey%,Start_bot
   
    Account = %Read_Acc%
    
    IF (Read_Steam = 1)
    {
    Game_Title = RPG MO - Early Access
    Game_Process = nw.exe
    }
      
    IF (Read_Steam = 0)
    {
    Game_Title = RPG MO - Web Browser Game
    Game_Process = RPG MO.exe
    }

}

IfNOTExist,RPGMO.ini
{
    Gui, Start: Add, Text, w110 h20,Account
    Gui, Start: Add, Edit, w100 h20 vAcc, Account name
 
    Gui, Start: Add, Text, w110 h20 ,Bot Start Hotkey:
    Gui, Start: Add, Hotkey, w70 h20 vStartKey,.
        
    Gui, Start: Add, Text, w110 h20 ,Load Pet Key:
    Gui, Start: Add, Hotkey, w70 h20 vLoadPet,c

    Gui, Start: Add, Text, w110 h20 ,Unload Pet Key:
    Gui, Start: Add, Hotkey, w70 h20 vUnloadPet,x

    Gui, Start: Add, Text, w110 h20 ,Deposit All Key:
    Gui, Start: Add, Hotkey, w70 h20 vDepositAll,e

    Gui, Start: Add, Text, w110 h20 ,Withdraw 1 or All Key:
    Gui, Start: Add, Hotkey, w70 h20 vWithdrawKey,z

    Gui, Start: Add, Text, w110 h20 ,Destroy all ores in bag Key:
    Gui, Start: Add, Hotkey, w70 h20 vDestroyOres,g

	  Gui, Start: Add, Checkbox,vAlarm,Alarm:
	  Gui, Start: Add, Checkbox,vSteam,Steam version
	  Gui, Start: Add, Checkbox,vPet,Pet? (16 Slot Only)
    Gui, Start: Add, Button,gsave, Save

    Gui, Start: Show,w160, Settings
    return
 
    save:
    Gui, Start: Submit
    FileAppend,%Acc%`n%StartKey%`n%Alarm%`n%Steam%`n%LoadPet%`n%UnloadPet%`n%DepositAll%`n%WithdrawKey%`n%DestroyOres%`n%Pet%,RPGMO.ini
    Sleep,200
    Reload
    return
}


Process, Exist, %Game_Process%
IF !errorlevel=1
{
MsgBox, Start the RPG MO Client and login then start the bot
ExitApp
}

Select_Again:
FileSelectFile, Script, 3,%A_ScriptDir%/Scripts,Load a script, Script (*.path)
IF Script =
{
	MsgBox, You didn't select a script
	Sleep, 200
	gosub, Select_Again
	return
}

FileReadLine,Read_Type,%Script%,1 ;Name of Item to use
FileReadLine,Read_BotType,%Script%,2 ; Type of bot Gather or Process
FileReadLine,Gather_Dir,%Script%,3 ; Button to press to Gather
FileReadLine,Gather_Path,%Script%,4 ; Path to Gather from Stash
FileReadLine,Stash_Dir,%Script%,5 ; Key to press to open Stash
FileReadLine,Stash_Path,%Script%,6 ; Path to Stash from Gathering Spot
FileReadLine,PetForce,%Script%,7 ; Forces Pet Status 1=Pet,0=NoPet, anything else = doesn't force
FileReadLine,ItemToDelete,%Script%,8 ; Name of item to delete LEAVE EMPTY IF YOU DONT NEED ANYTHING DELETED

DebugMessage("Started | This screen is for debug purposes")
WinActivate, %Game_Title%
WinWaitActive, %Game_Title%
WorldSwap:=0

Start_bot:
Loop
{
Gosub,LoginCheck
Gosub,Alarm
if(Read_BotType="Gather") ;==================== Gather Type
{
  Inv_Res:=2
  Pet_Inv_Res:=2
  Inv_Res:=Search_Inv(Read_Type)
  ;DebugMessage("Inv_Res: " Inv_Res)
  if(Inv_Res=0) ;If image not found
  {
      ;DebugMessage("Inventory Not Full: Dig")
      Gosub,Digg
      Sleep,4500
  }     
  if (Inv_Res=1) ;If found
  {
    If(ItemToDelete!="") ;Do we delete item
    {
      Sleep,100
      WinActivate, %Game_Title%
      WinWaitActive, %Game_Title%
      FoundY2:=0
      ImageSearch, FoundX, FoundY, 900, 75, 1220, 270,*80 *TransWhite %A_ScriptDir%\Images\%ItemToDelete%.png
      if ErrorLevel=0
      {
        DebugMessage("Deleting all " ItemToDelete "s!")
        Sleep,200
        Click right %FoundX%,%FoundY%
        FoundY2:=FoundY+110
        Sleep,200
        Click %FoundX%,%FoundY2%
        Sleep,200
        Click,590,380
        Sleep,200
        continue Start_bot
      }
    }
  	If((PetSet=1 && PetForce!=0) || PetForce=1) ;Does player have a pet
  	{
  		Pet_Inv_Res:=Search_Pet_Inv(Read_Type)
      DebugMessage("Pet_Inv_Res: " Pet_Inv_Res)
      if(Pet_Inv_Res=1) ;If not found
  		{
  			DebugMessage("Inventory Full, Pet Inventory Full")
        	Gosub,Stash
        	Gosub,WalkBack
  		}
          if(Pet_Inv_Res=0) ;If found
  		{
        	DebugMessage("Inventory Full, Pet Inventory Empty: Load Pet")
  			Gosub,LoadPet
  		}
  	}
  	Else ; If NO pet (Already checked if full inventory)
  	{
		Gosub,Stash
		Gosub,WalkBack
  	}
  }
}
else if(Read_BotType="Process") ;============== Process Type
{
  FindInvResult:=Find_Inv(Read_Type)
  ;DebugMessage("Find_Inv Results: " FindInvResult )
  if(FindInvResult!=0)
  {
    StringSplit,ItemLoc,FindInvResult,`,
    ItemLoc1:=ItemLoc1+10
    ItemLoc2:=ItemLoc2+10
    Sleep,200
    Gosub,Alarm
    Send,{Shift Down}
    Sleep,100
    Click %ItemLoc1%,%ItemLoc2%
    Send,{Shift Up}
    Sleep,100
    Gosub,Alarm
    Click 500,500,0
    Gosub,Digg
    Sleep,5000
  }
  if(FindInvResult=0)
  {
    Gosub,Stash
    Gosub,GatherMats
    Gosub,WalkBack
  }
}
else if(Read_BotType="Buy") ;================== Buy type
{
Purchase:
Loop
{
	Inv_Res:=2
	Pet_Inv_Res:=2
	Gosub,Alarm
	Gosub,Digg
	Buy_Inv_Res:=Search_Buy_Inv(Read_Type)
	;DebugMessage("Buy_Inv_Res : " Buy_Inv_Res)
	if(Buy_Inv_Res=0) ;If image not found, if inventory NOT full
	{
		;DebugMessage("Searching if buyable")
		ImageSearch,,, 435, 410, 520, 435,*90 *TransWhite %A_ScriptDir%\Images\zzzBuyfor.png
		if(ErrorLevel=0) ;If [Purchasable] buy one
		{
			;DebugMessage("Time to buy")
			Loop, 30
			{
				Gosub,Alarm
				Click 490,435
				Sleep,20 ; Don't mess with this one
			}
			Gosub,Alarm
			Click 520,465,0
			Goto,Purchase
		} 
		else if(ErrorLevel=1) ; If [Not purchasable] OR not chosen
		{
			FindStoreResult:=Find_Store(Read_Type) ;Find out if item is available NPC
			if(FindStoreResult="") ;Item not in shop, wrong NPC/something else
			{
				DebugMessage("Wrong NPC he dont even sell this shit")
				Pause
			} 
			else if(FindStoreResult!="") ;Item purchasable, so go click it
			{
				;DebugMessage("Item purchasable, clicking to buy")
				StringSplit,StoreItemLoc,FindStoreResult,`,
				StoreItemLoc1:=StoreItemLoc1+10
				StoreItemLoc2:=StoreItemLoc2+10
				Gosub,Alarm
				Click %StoreItemLoc1%,%StoreItemLoc2%
				Gosub,Alarm
				ImageSearch,,, 435, 410, 520, 435,*90 *TransWhite %A_ScriptDir%\Images\zzzBuyfor.png
				if(ErrorLevel=1)
				{
					DebugMessage("Bought them all, world hopping")
					Gosub,Alarm
					Sleep,5500
					Send,{Enter}
					Sleep,100
					SendRaw,/world 5
					Send,{Enter}
					Send,{Enter}
					SendRaw,/world 4
					Send,{Enter}
					Sleep,5000
					WorldSwap:=1
					Gosub,LoginCheck
					Sleep,500
					Goto,Purchase
				}
			}
		}
	}
	else if(Buy_Inv_Res=1)
	{
		If((PetSet=1 && PetForce!=0) || PetForce=1) ;Does player have a pet/Does script force
		{
			Pet_Inv_Res:=Search_Pet_Inv(Read_Type)
			DebugMessage("Pet_Inv_Res: " Pet_Inv_Res)
			if(Pet_Inv_Res=1) ;If not found
			{
				DebugMessage("Inventory Full, Pet Inventory Full")
			    Gosub,Stash
			    Gosub,WalkBack
			}
			if(Pet_Inv_Res=0) ;If found
			{
			    DebugMessage("Inventory Full, Pet Inventory Empty: Load Pet")
				Gosub,LoadPet
			}
		}
		Else ; If NO pet (Already checked if full inventory)
  		{
			Gosub,Stash
			Gosub,WalkBack
  		}
	}
}
}
}
Return

Alarm:
if(Alarm=1)
{
  PixelGetcolor, Captcha, 613,221
  IfEqual, Captcha, 0x333333
  {
    SoundBeep,2000,2000
    WinActivate,%Game_Title%
    Pause
    Sleep,100
    Click 750,300
    Sleep,100
  }
  ;RunWait,Capture2Text.exe 465 310 765 365, %A_ScriptDir%\OCR
  ;DebugMessage(Clipboard)
}
Return

LoginCheck:
PixelGetColor,LoginTest,544,297
IfEqual,LoginTest,0xEAEAE9
	{
		if(WorldSwap=0)
		{
			Click,446,403
			WorldSwap:=1
		}
		Sleep,500
		Goto,LoginCheck
	}
Return

Digg:
	Gosub,Alarm
	Sleep,200
	Send,{%Gather_Dir% Down}
	Sleep,100
	Send,{%Gather_Dir% Up}
	Sleep,100
Return

LoadPet:
	Gosub,Alarm
	Sleep,500
	Send,{%Key_LoadPet% Down}
	Sleep,100
	Send,{%Key_LoadPet% Up}
	Sleep,750
Return

Stash:
	Sleep,1000
	K(Stash_Path)
	Sleep,500
	Gosub,Alarm
	Send,{%Stash_Dir% Down} ;Open Stash
	Sleep,100
	Send,{%Stash_Dir% Up}
	Sleep,1000
	Gosub,Alarm
	Send,{%Key_DepositAll% Down} ;Clear Inventory
	Sleep,100
	Send,{%Key_DepositAll% Up}
	if((PetSet=1 && PetForce!=0) || PetForce=1)
	{
	 Gosub,Alarm
	 Sleep,750
	 Send,{%Key_UnloadPet% Down} ;Unload Pet
	 Sleep,100
	 Send,{%Key_UnloadPet% Up}
	 Sleep,750
	 Gosub,Alarm
	 Send,{%Key_DepositAll% Down} ;Clear Inventory
	 Sleep,100
	 Send,{%Key_DepositAll% Up}
	}
	Sleep,1500
Return

GatherMats:
	FindStashResult:=Find_Stash(Read_Type)
	if(FindStashResult=0)
	{
		DebugMessage("Out of mats to proceess")
		Pause
	}
	StringSplit,StashItemLoc,FindStashResult,`,
	StashItemLoc1:=StashItemLoc1+10
	StashItemLoc2:=StashItemLoc2+10
	Sleep,100
	Gosub,Alarm
	Click %StashItemLoc1%, %StashItemLoc2%
	Sleep,250
	Gosub,Alarm
	Send,{%EmptyFromStash% Down}
	Sleep,100
	Send,{%EmptyFromStash% Up}
	Sleep,500
Return

WalkBack:
	Sleep,100
	K(Gather_Path) ; Walk back to gather location
	Sleep,200
Return



K(multipleKeyTimes){
    Loop, Parse, multipleKeyTimes,`,
    {
        keyOrTimes:=StrSplit(A_LoopField,A_Space)
        if(keyOrTimes[1]="Wait")
        {
        	Sleep,1500
        	continue 
        }
        Loop % keyOrTimes[2] {
            Random, Sleepy, 80, 90
            Gosub,Alarm
            Send, % "{" keyOrTimes[1]" Down}"
            Sleep, % Sleepy
            Send, % "{" keyOrTimes[1]" Up}"
            Sleep, 60
        }
        Sleep,120
    }
}
return

; -------------- Gather Mode ------------------
Search_Inv(image)
{
 sleep,800
 var=0
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 Sleep,100
 imagepic:=ImageNum%var%
 ImageSearch,,,1180,220,1220,260,*80 *TransWhite %A_ScriptDir%\Images\%imagepic%.png
 if ErrorLevel = 0
 {
   Return 1 
 }
 if ErrorLevel = 2
   DebugMessage("Image [ " imagepic " ] missing")
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
 }
}

Search_Pet_Inv(image)
{
 sleep, 1000
 var = 0
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 image:=ImageNum%var%
 ImageSearch,,,1180,340,1220,400,*80 *TransWhite %A_ScriptDir%\Images\%image%.png
 if ErrorLevel = 0
   Return 1 
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
 }
}

; -------------- Process Mode ------------------
Find_Inv(image)
{
 sleep,800
 var=0
 ItemFound:=""
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 Sleep,100
 imagepic:=ImageNum%var%
 ImageSearch,ItemX,ItemY,910,75,1220,260,*50 *TransWhite %A_ScriptDir%\Images\%imagepic%.png
 if ErrorLevel = 0
 {
   ItemFound:=ItemX . "," . ItemY
   Return ItemFound
 }
 if ErrorLevel = 2
   DebugMessage("Image [ " imagepic " ] missing")
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
;DebugMessage("Image checked : [ " imagepic " ]")
 }
}

Find_Stash(image)
{
 sleep,800
 var=0
 ItemFound:=""
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 Sleep,100
 imagepic:=ImageNum%var%
 ImageSearch,StItemX,StItemY,340,180,860,500,*80 *TransWhite %A_ScriptDir%\Images\%imagepic%.png
 if ErrorLevel = 0
 {
  ItemFound:=StItemX . "," . StItemY
  Return ItemFound
 }
 if ErrorLevel = 2
   DebugMessage("Image [ " imagepic " ] missing")
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
;DebugMessage("Image checked : [ " imagepic " ]")
 }
}

; -------------- Purchase (NPC) Mode ------------------
Search_Buy_Inv(image)
{
 sleep,800
 var=0
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 Sleep,100
 imagepic:=ImageNum%var%
 ImageSearch,,,1180,220,1220,260,*80 *TransWhite %A_ScriptDir%\Images\%imagepic%.png
 if ErrorLevel = 0
 {
   Return 1 
 }
 if ErrorLevel = 2
   DebugMessage("Image [ " imagepic " ] missing")
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
 }
}

Find_Store(image)
{
 sleep,200
 var=0
 ItemFound:=""
 StringSplit,ImageNum,image,`,
 Loop,%ImageNum0%
 {
 var+=1
 Sleep,100
 Gosub,Alarm
 imagepic:=ImageNum%var%
 ImageSearch,StItemX,StItemY,420,180,820,410,*80 *TransWhite %A_ScriptDir%\Images\%imagepic%.png
 if ErrorLevel = 0
 {
  ItemFound:=StItemX . "," . StItemY
  Return ItemFound
 }
 if ErrorLevel = 2
   DebugMessage("Image [ " imagepic " ] missing")
 if A_Index = %ImageNum0%
   Return 0
 if var = 100
   var = 0
 }
}

F2::Pause,Toggle
F3::Reload

F1::
Quit:
WinSet, AlwaysOnTop, off, %Game_Title%
Send,{Up Up}
Send,{Left Up}
Send,{Right Up}
Send,{Down Up}
Send,{W Up}
Send,{A Up}
Send,{S Up}
Send,{D Up}
ExitApp
return

;Debug Shit
DebugMessage(str)
{
 global h_stdout
 DebugConsoleInitialize()  ; start console window if not yet started
 str .= "`n" ; add line feed
 ;DllCall("WriteFile", "uint", h_Stdout, "uint", &str, "uint", StrLen(str), "uint*", BytesWritten, "uint", NULL) ; write into the console
 FileAppend %str%, CONOUT$
 WinSet, Bottom,, ahk_id %h_stout%  ; keep console on bottom
}

DebugConsoleInitialize()
{
   global h_Stdout     ; Handle for console
   static is_open = 0  ; toogle whether opened before
   if (is_open = 1)     ; yes, so don't open again
     return
	 
   is_open := 1	
   ; two calls to open, no error check (it's debug, so you know what you are doing)
   DllCall("AttachConsole", int, -1, int)
   DllCall("AllocConsole", int)

   dllcall("SetConsoleTitle", "str","Paddy Debug Console")    ; Set the name. Example. Probably could use a_scriptname here 
   h_Stdout := DllCall("GetStdHandle", "int", -11) ; get the handle
   WinSet, Bottom,, ahk_id %h_stout%      ; make sure it's on the bottom
   WinActivate,%Game_Title%   ; Application specific; I need to make sure this application is running in the foreground. YMMV
   return
}