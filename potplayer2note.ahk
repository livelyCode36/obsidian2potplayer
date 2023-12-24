#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%\lib\note2potplayer\RegisterUrlProtocol.ahk"
#Include "%A_ScriptDir%\lib\MyTool.ahk"
#Include "%A_ScriptDir%\lib\ReduceTime.ahk"
#Include "%A_ScriptDir%\lib\ImageTemplateParser.ahk"
#Include "%A_ScriptDir%\lib\PotplayerControl.ahk"

potplayer_path := IniRead("config.ini", "PotPlayer", "path")
is_stop := IniRead("config.ini", "PotPlayer", "is_stop")
reduce_time := IniRead("config.ini", "PotPlayer", "reduce_time")

potplayer_name := GetNameForPath(potplayer_path)

note_app_name := IniRead("config.ini", "Note", "app_name")

markdown_template := IniRead("config.ini", "MarkDown", "template")
markdown_image_template := IniRead("config.ini", "MarkDown", "image_template")
markdown_title := IniRead("config.ini", "MarkDown", "title")
markdown_path_is_encode := IniRead("config.ini", "MarkDown", "path_is_encode")
markdown_remove_suffix_of_video_file := IniRead("config.ini", "MarkDown", "remove_suffix_of_video_file")

RegisterUrlProtocol()

#HotIf WinActive("ahk_exe" potplayer_name) or WinActive("ahk_exe" note_app_name)
{
    ; 【定义热键，默认：Alt+G】
    ; 如何定义热键参考官方文档：https://wyagd001.github.io/v2/docs/Hotkeys.htm
    !g up::{
        ; 在笔记软件中按快捷键没有问题。但是在Potplayer中按快捷键，会出现问题：Potplayer的快捷键被触发了，解决办法是：等待快捷键释放，然后再执行
        KeyWait "Alt","T2"
        KeyWait "g","T2"

        Potplayer2Obsidian()
    }
    ^!g up::{
        KeyWait "Control","T2"
        KeyWait "Alt","T2"
        KeyWait "g","T2"
        
        Potplayer2ObsidianImage()
    }
}

; 【主逻辑】将Potplayer的播放链接粘贴到Obsidian中
Potplayer2Obsidian(){
    media_path := GetMediaPath()
    media_time := GetMediaTime()
    
    markdown_link := RenderMarkdownTemplate(markdown_template, media_path, media_time)
    PauseMedia()

    SendText2NoteApp(markdown_link)
}

RenderMarkdownTemplate(markdown_template, media_path, media_time){
    if (InStr(markdown_template, "{title}") != 0){
        markdown_template := RenderTitle(markdown_template, markdown_title, media_path, media_time)
    }
    markdown_template := RenderEnter(markdown_template)
    return markdown_template
}

; 【主逻辑】粘贴图像
Potplayer2ObsidianImage(){
    media_path := GetMediaPath()
    media_time := GetMediaTime()
    image := SaveImage()

    PauseMedia()

    RenderImage(markdown_image_template, media_path, media_time, image)
}

GetMediaPath(){
    return PressDownHotkey(GetMediaPathToClipboard)
}
GetMediaTime(){
    time := PressDownHotkey(GetMediaTimestampToClipboard)

    if (reduce_time != "0") {
        time := ReduceTime(time,reduce_time)
    }
    return time
}
PressDownHotkey(potplayer_control){
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    potplayer_control()
    ClipWait 1,0
    result := A_Clipboard
    ; MyLog "剪切板的值是：" . result

    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    if (result == "") {
        SafeRecursion()
        ; 无限重试！
        result := PressDownHotkey(potplayer_control)
    }
    return result
}

PauseMedia(){
    if (is_stop != "0") {
        Pause()
    }
}

RenderTitle(markdown_template, markdown_title, media_path, media_time){
    markdown_link := GenerateMarkdownLink(markdown_title, media_path, media_time)
    result := StrReplace(markdown_template, "{title}",markdown_link)
    return result
}

RenderEnter(template){
    result := StrReplace(template, "{enter}","`n")
    return result
}

; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
GenerateMarkdownLink(markdown_title, media_path, media_time){
    ; B站的视频
    if (InStr(media_path,"https://www.bilibili.com/video/")){
        ; 正常播放的情况
        name := StrReplace(GetPotplayerTitle(), " - PotPlayer", "")
        
        ; 视频没有播放，已经停止的情况
        if name == "PotPlayer"{
            name := GetFileNameInPath(media_path)
        }
    } else{
        ; 本地视频
        name := GetFileNameInPath(media_path)
    }
    markdown_title := StrReplace(markdown_title, "{name}",name)
    markdown_title := StrReplace(markdown_title, "{time}",media_time)

    markdown_link := url_protocol "?path=" ProcessUrl(media_path) "&time=" media_time
    result := "[" markdown_title "](" markdown_link ")"
    return result
}

GetFileNameInPath(path){
    name := GetNameForPath(path)
    if (markdown_remove_suffix_of_video_file != "0"){
        name := RemoveSuffix(name)
    }
    return name
}

RenderImage(markdown_image_template, media_path, media_time, image){
    image_templates := ImageTemplateConvertedToImagesTemplates(markdown_image_template)
    For index, image_template in image_templates{
        if (image_template == "{image}"){
            SendImage2NoteApp(image)
        } else {
            SendText2NoteApp(RenderMarkdownTemplate(image_template, media_path, media_time))
        }
    }
}

RemoveSuffix(name){
    index_of := InStr(name, ".")
    if (index_of = 0){
        return name
    }
    result := SubStr(name, 1,index_of-1)
    return result
}

; 路径地址处理
ProcessUrl(media_path){
    ; 进行Url编码
    if (markdown_path_is_encode != "0"){
        media_path := UrlEncode(media_path)
    }
    ; 但是 obidian中的potplayer回链路径有空格，在obsidian的预览模式【无法渲染】，所以将空格进行Url编码
    media_path := StrReplace(media_path, " ", "%20")

    return media_path
}

SendText2NoteApp(text){
    ActivateProgram(note_app_name)
    A_Clipboard := ""  ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := text
    ClipWait 2,0   ; 等待剪贴板中出现文本.
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 粘贴文字需要等待一下obsidian有延迟，不然会出现粘贴的文字【消失】
    Sleep 300
}

SaveImage(){
    A_Clipboard := ""
    SaveImageToClipboard()
    if !ClipWait(2,1){
        SafeRecursion()
    }
    return ClipboardAll()
}
SendImage2NoteApp(image){
    ActivateProgram(note_app_name)
    A_Clipboard := ""
    A_Clipboard := ClipboardAll(image)
    ClipWait 2,1
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 给Obsidian图片处理插件的时间
    Sleep 500
}