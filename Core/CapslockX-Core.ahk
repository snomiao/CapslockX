﻿; ========== CapsLockX ==========
; 名称：CapsLockX 核心
; 描述：用于处理配置文件、加载其它模块、提供基本 CapsLockX 键触发功能
; 作者：snomiao
; 联系：snomiao@gmail.com
; 支持：https://github.com/snomiao/CapsLockX
; 编码：UTF-8 with BOM
; 版权：Copyright © 2017-2021 Snowstar Laboratory. All Rights Reserved.
; LICENCE: GNU GPLv3
; ========== CapsLockX ==========
; 创建：Snowstar QQ: 997596439
; 参与完善：张工 QQ: 45289331

Process Priority, , High ; 脚本高优先级
SetTitleMatchMode RegEx
; #NoEnv ; 不检查空变量是否为环境变量

#SingleInstance Force ; 跳过对话框并自动替换旧实例（在启动成功后有效）
; if(A_IsAdmin){
;     #SingleInstance Force ; 跳过对话框并自动替换旧实例（在启动成功后有效）
; }else{
;     #SingleInstance, Off ; 允许多开，然后在下面用热键把其它实例关掉
; }
#Persistent
#MaxHotkeysPerInterval 1000 ; 时间内按键最大次数（通常是一直按着键触发的。。）
#InstallMouseHook ; 安装鼠标钩子

global CapsLockX_上次触发键 := ""
; 载入设定
global CapsLockX_配置路径_旧 := "./CapsLockX-Config.ini"
global CapsLockX_配置路径 := "./User/CapsLockX-Config.ini"
FileMove CapsLockX_配置路径_旧, CapsLockX_配置路径
#Include Core/CapsLockX-Config.ahk

; 模式处理
global CapsLockX := 1 ; 模块运行标识符
global CapsLockXMode := 0
global ModuleState := 0
global CapsLockX_FnActed := 0
global CM_NORMAL := 0 ; 普通模式
global CM_FN := 1 ; 临时 CapsLockX 模式（或称组合键模式
global CM_CapsLockX := 2 ; CapsLockX 模式
; global CM_FNX := 3 ; FnX 模式
global LastLightState := ((CapsLockXMode & CM_CapsLockX) || (CapsLockXMode & CM_FN))
global CapsLockPressTimestamp := 0

; 根据灯的状态来切换到上次程序退出时使用的模式（不）
UpdateCapsLockXMode(){
    if (T_UseCapsLockLight){
        CapsLockXMode := GetKeyState("CapsLock", "P")
    }
    if (T_UseScrollLockLight){
        CapsLockXMode |= GetKeyState("ScrollLock", "T") << 1
    }
    Return CapsLockXMode
}
UpdateCapsLockXMode()

; 根据当前模式，切换灯
Menu, tray, icon, %T_SwitchTrayIconOff%
UpdateLight()

global T_IgnoresByLines
defaultIgnoreFilePath := "./Data/CapsLockX.defaults.ignore.txt"
userIgnoreFilePath := "./User/CapsLockX.user.ignore.txt"
FileRead, T_IgnoresByLines, %userIgnoreFilePath%
if (!T_IgnoresByLinesUser){
    FileCopy, %defaultIgnoreFilePath%, %userIgnoreFilePath%
    FileRead, T_IgnoresByLines, %userIgnoreFilePath%
}

global CapsLockX_Paused := 0

#If CapsLockX_Avaliable()

#If !CapsLockX_Avaliable()

#If

Hotkey, If, CapsLockX_Avaliable()

if(T_XKeyAsCapsLock) 
    Hotkey CapsLock, CapsLockX_Dn
if(T_XKeyAsSpace) 
    Hotkey Space, CapsLockX_Dn
if(T_XKeyAsInsert)
    Hotkey Insert, CapsLockX_Dn
if(T_XKeyAsScrollLock)
    Hotkey ScrollLock, CapsLockX_Dn
if(T_XKeyAsRAlt)
    Hotkey RAlt, CapsLockX_Dn

Hotkey, If, !CapsLockX_Avaliable()

if(T_XKeyAsCapsLock) 
    Hotkey CapsLock, CapsLockX_NotAvaliable
if(T_XKeyAsSpace) 
    Hotkey Space, CapsLockX_NotAvaliable
if(T_XKeyAsInsert)
    Hotkey Insert, CapsLockX_NotAvaliable
if(T_XKeyAsScrollLock)
    Hotkey ScrollLock, CapsLockX_NotAvaliable
if(T_XKeyAsRAlt)
    Hotkey RAlt, CapsLockX_NotAvaliable

Hotkey, If

if(T_XKeyAsCapsLock)
    Hotkey CapsLock Up, CapsLockX_Up
if(T_XKeyAsSpace) 
    Hotkey Space Up, CapsLockX_Up
if(T_XKeyAsInsert)
    Hotkey Insert Up, CapsLockX_Up
if(T_XKeyAsScrollLock)
    Hotkey ScrollLock Up, CapsLockX_Up
if(T_XKeyAsRAlt)
    Hotkey RAlt Up, CapsLockX_Up

#Include Core\CapsLockX-ModulesRunner.ahk
CapsLockX_Loaded()
#Include Core\CapsLockX-ModulesLoader.ahk
#Include Core\CapsLockX-RunSilent.ahk

#If

UpdateLight(){
    NowLightState := ((CapsLockXMode & CM_CapsLockX) || (CapsLockXMode & CM_FN))
    if (NowLightState == LastLightState){
        Return
    }
    if (T_UseScrollLockLight && GetKeyState("ScrollLock", "T") != NowLightState){
        Send {ScrollLock}
    }
    if (T_UseCursor){
        UpdateCapsCursor(NowLightState)
    }
    if ( NowLightState && !LastLightState){
        Menu, tray, icon, %T_SwitchTrayIconOn%
        if (T_SwitchSound && T_SwitchSoundOn){
            SoundPlay %T_SwitchSoundOn%
        }
    }
    if ( !NowLightState && LastLightState ){
        Menu, tray, icon, %T_SwitchTrayIconOff%
        if (T_SwitchSound && T_SwitchSoundOff){
            SoundPlay %T_SwitchSoundOff%
        }
    }
    LastLightState := NowLightState
}
CapsLockXTurnOff(){
    CapsLockXMode &= ~CM_CapsLockX
    re := UpdateLight()3
    Return re
}
CapsLockXTurnOn(){
    CapsLockXMode |= CM_CapsLockX
    re := UpdateLight()
    Return re
}
CapsLockX_Avaliable(){
    return 1
    flag_IgnoreWindow := 0
    Loop, Parse, T_IgnoresByLines, `n, `r
    {
        content := Trim(RegExReplace(A_LoopField, "^#.*", ""))
        if(content){
            ; flag_IgnoreWindow := flag_IgnoreWindow || WinActive(content)
            If(WinActive(content)){
                ToolTip, ignored by %content%
                return false
            }
        }
    }
    return !CapsLockX_Paused
}
CapsLockX_Loaded(){
    ; 使用退出键退出其它实例
    SendInput ^!+\

    TrayTip CapsLockX %CapsLockX_VersionName%, 加载成功
    Menu, Tray, Tip, CapsLockX %CapsLockX_VersionName%
}
CapsLockX_Reload(){
    ToolTip, CapsLockX 重载中
    static times := 0
    times += 1
    if(times == 1){
        ; 使用 RunAsLimitiedUser 避免重载时出现 Could not close the previous instance of this script.  Keep waiting?
        RunAsLimitiedUser(A_WorkingDir "\CapsLockX.exe", A_WorkingDir)
        ; 这里启动新实例后不用急着退出当前实例
        ; 如果重载的新实例启动成功，则会自动使用热键结束掉本实例
        ; 而如果没有启动成功则保留本实例，以方便修改语法错误的模块
    }else{
        ; 但如果用户多次要求重载，那就直接退出掉好了（即，双击重载会强制退出当前实例）
        RunAsSameUser(A_WorkingDir "\CapsLockX.exe", A_WorkingDir)
        ExitApp
    }
}

CapsLockX_Dn(){
    ; 按住其它键的时候 不触发 CapsLockX 避免影响打字
    CapsLockX_上次触发键 := 触发键 := RegExReplace(A_ThisHotkey, "[\$\*\!\^\+\#\s]")
    WheelQ := A_PriorKey == "WheelDown" || A_PriorKey == "WheelUp"
    if(!WheelQ && GetKeyState(A_PriorKey, "P") && 触发键 != A_PriorKey && 触发键){
        CapsLockX_上次触发键 := ""
        ; ToolTip, % first5char "_" 触发键
        SendEvent {%触发键% Down}
        KeyWait %触发键%, T5 ; wait for 5 seconds
        SendEvent {%触发键% Up}
        Return
    }
    ; 记录 CapsLockX 按住的时间
    if ( CapsLockPressTimestamp == 0){
        CapsLockPressTimestamp := A_TickCount
    }
    ; 进入 Fn 模式
    CapsLockXMode |= CM_FN

    ; (20200809)长按显示帮助（空格除外）
    if (A_PriorKey == CapsLockX_上次触发键){
        if(A_PriorKey != "Space"){
            if ( A_TickCount - CapsLockPressTimestamp > 1000){
                CapsLockX_ShowHelp(CapsLockX_HelpInfo, 1, CapsLockX_上次触发键)
            }
        }else{
            if ( A_TickCount - CapsLockPressTimestamp > 200){
                SendEvent, {Space}
            }
        }
    }
    UpdateLight()
}
CapsLockX_Up(){
    CapsLockPressTimestamp := 0
    ; 退出 Fn 模式
    CapsLockXMode &= ~CM_FN
    ; ToolTip, %A_PriorKey% %CapsLockX_上次触发键%
    if(A_PriorKey == CapsLockX_上次触发键){
        if (CapsLockX_上次触发键 == "CapsLock"){
            if (GetKeyState("CapsLock", "T")){
                SetCapsLockState, Off
            } else {
                SetCapsLockState, On
            }
        }
        if(CapsLockX_上次触发键 == "Space"){
            SendEvent {Space}
        }
    }
    UpdateLight()
    CapsLockX_上次触发键 := ""
}
RunAsSameUser(CMD, WorkingDir){
    Run, %CMD%, %WorkingDir%
}

RunAsLimitiedUser(CMD, WorkingDir){
    ; ref: [Run as normal user (not as admin) when user is admin - Ask for Help - AutoHotkey Community]( https://autohotkey.com/board/topic/79136-run-as-normal-user-not-as-admin-when-user-is-admin/ )
    ; 
    ; TEST DEMO
    ; schtasks /Create /tn CapsLockX_RunAsLimitedUser /sc ONCE /tr "cmd /k cd \"C:\\users\\snomi\\\" && notepad \".\\tmp.txt\"" /F /ST 00:00
    ; schtasks /Run /tn CapsLockX_RunAsLimitedUser
    ; schtasks /Delete /tn CapsLockX_RunAsLimitedUser /F
    ; 
    ; Safe_WorkingDir := RegExReplace("C:\users\snomi\", "\\", "\\")
    ; Safe_CMD := RegExReplace(RegExReplace("notepad "".\temp.txt""", "\\", "\\"), "\""", "\""")
    Safe_WorkingDir := RegExReplace(WorkingDir, "\\", "\\")
    Safe_CMD := RegExReplace(RegExReplace(CMD, "\\", "\\"), "\""", "\""")
    RunWait cmd /c schtasks /Create /tn CapsLockX_RunAsLimitedUser /F /sc ONCE /ST 00:00 /tr "cmd /c cd \"%Safe_WorkingDir% && %Safe_CMD%\",, Hide
    RunWait cmd /c schtasks /Run /tn CapsLockX_RunAsLimitedUser,, Hide
    RunWait cmd /c schtasks /Delete /tn CapsLockX_RunAsLimitedUser /F,, Hide
}
; 接下来是流程控制
#if

; CapsLockX 模式切换处理
CapsLockX_NotAvaliable:
    TrayTip, CapsLockX, NotAvaliable
Return
