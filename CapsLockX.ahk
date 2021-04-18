﻿; ========== CapsLockX ==========
; 名称：CapsLockX 程序入口
; 描述：用于生成模块加载组件、集成模块帮助文件、智能重载 CapsLockX 核心等功能。
; 作者：snomiao
; 联系：snomiao@gmail.com
; 支持：https://github.com/snomiao/CapsLockX
; 编码：UTF-8 with BOM
; 版权：Copyright © 2017-2021 Snowstar Laboratory. All Rights Reserved.
; 感谢：张工 QQ: 45289331 参与调试
; LICENCE: GNU GPLv3
; ========== CapsLockX ==========

#SingleInstance Force ; 跳过对话框并自动替换旧实例
; #NoTrayIcon ; 隐藏托盘图标
SetWorkingDir, %A_ScriptDir%

FileCreateDir ./User
global CapsLockX_配置路径 := "./User/CapsLockX-Config.ini"
global CapsLockX_模块路径 := "./Modules"
global CapsLockX_核心路径 := "./Core"
; 版本
global CapsLockX_Version
FileRead, CapsLockX_Version, ./Tools/version.txt
if(!CapsLockX_Version)
    CapsLockX_Version := "未知版本"
global CapsLockX_VersionName := "v" CapsLockX_Version
; 加载过程提示
global loadingTips := ""

; 对 核心模块 进行 编码清洗
清洗为_UTF8_WITH_BOM_型编码(CapsLockX_核心路径 "/CapsLockX-Config.ahk")
清洗为_UTF8_WITH_BOM_型编码(CapsLockX_核心路径 "/CapsLockX-Core.ahk")
清洗为_UTF8_WITH_BOM_型编码(CapsLockX_核心路径 "/CapsLockX-RunSilent.ahk")
清洗为_UTF8_WITH_BOM_型编码(CapsLockX_核心路径 "/CapsLockX-Update.ahk")

; 配置文件编码清洗
清洗为_UTF16_WITH_BOM_型编码(CapsLockX_配置路径)

; 复制用户模块
FileCopy ./User/*.user.ahk, %CapsLockX_模块路径%/, 1
FileCopy ./User/*.user.md, %CapsLockX_模块路径%/, 1
; 备份旧版本的用户模块（注意顺序，不要把新版用户模块覆盖了）
; FileCopy %CapsLockX_模块路径%/*.user.ahk, ./User/
; FileCopy %CapsLockX_模块路径%/*.user.md, ./User/

; 加载模块
ModulesRunner := CapsLockX_核心路径 "/CapsLockX-ModulesRunner.ahk"
ModulesLoader := CapsLockX_核心路径 "/CapsLockX-ModulesLoader.ahk"
LoadModules(ModulesRunner, ModulesLoader)

模块帮助向README编译()

; 隐藏 ToolTip
ToolTip

; 当 CI_TEST 启用时，仅测试编译效果，不启动核心
EnvGet ENVIROMENT, ENVIROMENT
if("CI_TEST" == ENVIROMENT){
    OutputDebug, % "[INFO] MODULE LOAD OK, SKIP CORE"
    ExitApp
}
CapslockX启动()

Return

模块帮助向README编译(){
    ; 编译README.md
    INPUT_README_FILE := "./docs/README.md"
    FileRead, source, %INPUT_README_FILE%
    ; 编译一次
    target := 模块帮助README更新(source)
    if (target == source)
        return "NOT_CHANGED"
    ; 如果不一样，就再编译一次
    加载提示追加("模块帮助有变更")
    ; 然后进行稳定性检查
    source := 模块帮助README更新(target)
    if (target != source)
        MsgBox % "如果你看到了这个，请联系雪星（QQ:997596439），这里肯定有 BUG……(20200228)"
    ; 输出到 docs/readme.md （用于 github-pages ）
    ; docs_target := 模块帮助README更新(source, 1)
    FileDelete ./docs/README.md
    FileAppend %target%, ./docs/README.md, UTF-8-Raw

    ; 输出根目录 README.md （用于 github 首页）
    FileDelete ./README.md
    PREFIX := "<!-- THIS FILE IS GENERATED PLEASE MODIFY DOCS/README -->`n`n"
    StringReplace, target, target, ./media/, ./docs/media/, All
    FileAppend %PREFIX%%target%, ./README.md, UTF-8-Raw
    ; Reload
    ; ExitApp
}
加载提示追加(msg, clear = 0){
    if (clear || loadingTips == ""){
        loadingTips := "CapsLockX " CapsLockX_Version "`n"
    }
    loadingTips .= msg "`n"
}
加载提示显示(){
    ToolTip % loadingTips
}
模块帮助尝试加载(模块文件名称, 模块名称){
    if (FileExist(CapsLockX_模块路径 "\" 模块名称 ".md")){
        FileRead, 模块帮助, %CapsLockX_模块路径%\%模块名称%.md
        Return 模块帮助
    }
    if (FileExist(CapsLockX_模块路径 "\" 模块文件名称 ".md")){
        FileRead, 模块帮助, %CapsLockX_模块路径%\%模块文件名称%.md
        Return 模块帮助
    }
    Return ""
}
清洗为_UTF8_WITH_BOM_型编码(path){
    FileRead ModuleCode, %path%
    FileDelete %path%
    FileAppend %ModuleCode%, %path%, UTF-8
}
清洗为_UTF16_WITH_BOM_型编码(path){
    FileRead ModuleCode, %path%
    FileDelete %path%
    FileAppend %ModuleCode%, %path%, UTF-16
}
模块帮助README更新(sourceREADME, docs=""){
    FileEncoding UTF-8
    ; 列出模块文件
    ModuleFiles := ""
    loop, Files, %CapsLockX_模块路径%\*.ahk ; Do not Recurse into subfolders. 子文件夹由模块自己去include去加载
        ModuleFiles .= A_LoopFileName "`n"
    ModuleFiles := Trim(ModuleFiles, "`n")
    Sort ModuleFiles
    ; 生成帮助
    全部帮助 := ""
    i := 0
    loop, Parse, ModuleFiles, `n
    {
        i++
        ; 匹配模块名
        模块文件 := A_LoopField
        匹配结果 := false
            || RegExMatch(A_LoopField, "O)((?:.*[-])*)(.*?)(?:\.user)?\.ahk", Match)
            || RegExMatch(A_LoopField, "O)((?:.*[-])*)(.*?)(?:\.用户)?\.ahk", Match)
        if (!匹配结果)
            Continue
        模块文件名称 := Match[1] Match[2]
        模块名称 := Match[2]
        模块帮助 := 模块帮助尝试加载(模块文件名称, 模块名称)
        if (!模块帮助)
            Continue
        模块帮助 := Trim(模块帮助, " `t`n")
        加载提示追加("加载模块帮助：" + i + "-" + 模块名称)

        全部帮助 .= "<!-- 模块文件名：" Match[1] Match[2] ".ahk" "-->" "`n`n"
        ; 替换标题层级
        模块帮助 := RegExReplace(模块帮助, "m)^#", "###")

        ; 替换资源链接的相对目录（图片gif等）
        FileCopy, %CapsLockX_模块路径%\*.gif, .\docs\media\, 1
        FileCopy, %CapsLockX_模块路径%\*.png, .\docs\media\, 1
        模块帮助 := RegExReplace(模块帮助, "m)\[(.*)\]\(\s*?\.\/(.*?)\)", "[$1]( ./media/$2 )")

        ; if (docs){
        ;     模块帮助 := RegExReplace(模块帮助, "m)\[(.*)\]\(\s*?\.\/(.*?)\)", "[$1]( ./$2 )")
        ; }else{
        ;     模块帮助 := RegExReplace(模块帮助, "m)\[(.*)\]\(\s*?\.\/(.*?)\)", "[$1]( ./" CapsLockX_模块路径 " /$2 ")
        ; }

        ; 没有标题的，给自动加标题
        if (!RegExMatch(模块帮助, "^#")){
            if (T%模块名称%_Disabled){
                全部帮助 .= "### " 模块名称 "模块（禁用）" "`n"
            } else {
                全部帮助 .= "### " 模块名称 "模块" "`n"
            }
        }
        全部帮助 .= 模块帮助 "`n`n"
    }
    加载提示显示()
    全部帮助 := Trim(全部帮助, " `t`n")

    ; 生成替换代码
    NeedleRegEx := "m)(\s*)(<!-- 开始：抽取模块帮助 -->)([\s\S]*)\r?\n(\s*)(<!-- 结束：抽取模块帮助 -->)"
    Replacement := "$1$2`n" 全部帮助 "`n$4$5"
    targetREADME := RegExReplace(sourceREADME, NeedleRegEx, Replacement, Replaces)

    ; 检查替换情况
    if (!Replaces){
        MsgBox % "加载模块帮助遇到错误。`n请更新 CapsLockX"
        MsgBox % targetREADME
        Return sourceREADME
    }

    Return targetREADME
}
LoadModules(ModulesRunner, ModulesLoader){
    FileEncoding UTF-8
    ; 列出模块文件 然后 排序
    ModuleFiles := ""
    loop, Files, %CapsLockX_模块路径%\*.ahk ; Do not Recurse into subfolders. 子文件夹由模块自己去include去加载
        ModuleFiles .= A_LoopFileName "`n"
    ModuleFiles := Trim(ModuleFiles, "`n")
    Sort ModuleFiles

    ; 生成模块加载代码
    code_setup := ""
    code_include := ""
    i := 0
    loop, Parse, ModuleFiles, `n
    {
        i++
        ; 匹配模块名
        模块文件 := A_LoopField
        匹配结果 := RegExMatch(A_LoopField, "O)(?:.*[.-])*(.*)\.ahk", Match)
        if (!匹配结果){

            Continue
        }
        模块名称 := Match[1]

        if (T%模块名称%_Disabled){
            加载提示追加("禁用模块：" i " " 模块名称)
        } else {
            ; 这里引入模块代码
            清洗为_UTF8_WITH_BOM_型编码(CapsLockX_模块路径 "\" 模块文件)

            ; 导入模块
            code_setup .= "GoSub CapsLockX_ModuleSetup_" i "`n"
            code_include .= "`n" "#If" "`n" "`n"
            code_include .= "CapsLockX_ModuleSetup_" i ":" "`n"
            code_include .= " " " " " " " " "#Include " CapsLockX_模块路径 "\" 模块文件 "`n"
            code_include .= "Return" "`n"
            加载提示追加("运行模块：" i " " 模块名称)
        }
    }
    加载提示显示()

    ; 拼接代码
    code_consts .= "; 请勿直接编辑本文件，以下内容由核心加载器自动生成。雪星/(20210318)" "`n"
    code_consts .= "global CapsLockX_模块路径 := " """" CapsLockX_模块路径 """" "`n"
    code_consts .= "global CapsLockX_核心路径 := " """" CapsLockX_核心路径 """" "`n"
    code_consts .= "global CapsLockX_Version := " """" CapsLockX_Version """" "`n"
    code_consts .= "global CapsLockX_VersionName := " """" CapsLockX_VersionName """" "`n"

    codeRunner .= code_consts "`n" code_setup
    codeLoader .= "Return" "`n" code_include

    FileDelete %ModulesRunner%
    FileAppend %codeRunner%, %ModulesRunner%
    FileDelete %ModulesLoader%
    FileAppend %codeLoader%, %ModulesLoader%
}

CapslockX启动(){
    CoreAHK := CapsLockX_核心路径 "\CapsLockX-Core.ahk"
    UpdatorAHK := CapsLockX_核心路径 "\CapsLockX-Update.ahk"
    ; 为了避免运行时对更新模块的影响，先把 EXE 文件扔到 Temp 目录，然后再运行核心。
    AHK_EXE_ROOT_PATH := "CapsLockX.exe"
    AHK_EXE_CORE_PATH := "./Core/CapsLockX.exe"
    AHK_EXE_TEMP_PATH := A_Temp "/CapsLockX.exe"
    FileCopy, %AHK_EXE_ROOT_PATH%, %AHK_EXE_TEMP_PATH%, 1
    if !FileExist(AHK_EXE_TEMP_PATH)
        FileCopy, %AHK_EXE_CORE_PATH%, %AHK_EXE_TEMP_PATH%, 1
    if !FileExist(AHK_EXE_TEMP_PATH)
        AHK_EXE_TEMP_PATH := AHK_EXE_ROOT_PATH
    ; 运行更新组件
    ; ToolTip % A_ScriptDir

    Run %AHK_EXE_TEMP_PATH% %UpdatorAHK%, %A_ScriptDir%

    ; 运行核心
    global T_AskRunAsAdmin := CapsLockX_ConfigGet("Core", "T_AskRunAsAdmin", 0)
    if(T_AskRunAsAdmin){
        RunWait *RunAs %AHK_EXE_TEMP_PATH% %CoreAHK%, %A_ScriptDir%
    }else{
        RunWait %AHK_EXE_TEMP_PATH% %CoreAHK%, %A_ScriptDir%
    }

    if (ErrorLevel){
        MsgBox, 4, CapsLockX 错误, CapsLockX 异常退出，是否重载？
        IfMsgBox No
        return
        Reload
    }else{
        TrayTip, CapsLockX 退出, CapsLockX 已退出。
        Sleep, 1000
    }
    ExitApp
}

CapsLockX_ConfigGet(field, varName, defaultValue){
    IniRead, %varName%, %CapsLockX_配置路径%, %field%, %varName%, %defaultValue%
    content := %varName% ; 千层套路XD
    return content 
}