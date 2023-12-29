#Requires AutoHotkey v2.0

log_toggle := false

GetNameForPath(program_path){
  ; 获取程序的路径
  SplitPath program_path, &name
  return name
}

SearchProgram(target_app_path) {
  ; 程序正在运行
  if (WinExist("ahk_exe" GetNameForPath(target_app_path))) {
      return true
  } else {
      return false
  }
}

ActivateNoteProgram(note_app_names){
  Loop Parse note_app_names, "`n"{
    note_program := A_LoopField
    if (WinExist("ahk_exe" note_program)) {
      ActivateProgram(note_program)
      return
    }
  }
}

ActivateProgram(process_name){
  if WinActive("ahk_exe" process_name){
      return
  }

  if (WinExist("ahk_exe" process_name)) {
      WinActivate ("ahk_exe" process_name)
      Sleep 300 ; 给程序切换窗口的时间
  } else {
      MsgBox process_name " is not running"
      Exit
  }
}

IsPotplayerRunning(media_player_path){
  if SearchProgram(media_player_path)
      return true
  else
      return false
}

; 获取Potplayer的标题
; 获取失败的原因：因为Potplayer的exe可能存在多个线程，而WinGetTitle其中一个线程的标题，结果可能为空字符串
; 参考：https://stackoverflow.com/questions/54570212/why-is-my-call-to-wingettitle-returning-an-empty-string
GetPotplayerTitle(){
  ids := WinGetList("ahk_exe" potplayer_name)
  for id in ids{
      title := WinGetTitle("ahk_id" id)
      if title == ""
        continue
      else
        return title
  }
}

MyLog(message){
  if log_toggle
      MsgBox message
}

; 安全的递归
global running_count := 0
SafeRecursion(){
  global running_count
  running_count++
  ToolTip("正在重试，第" running_count "次尝试...")
  SetTimer () => ToolTip(), -1000
  if (running_count > 5) {
    running_count := 0
    MsgBox "error: Replication failed!"
    Exit
  }
}

UrlEncode(str, sExcepts := "-_.", enc := "UTF-8") {
  hex := "00", func := "msvcrt\swprintf"
  buff := Buffer(StrPut(str, enc)), StrPut(str, buff, enc)   ;转码
  encoded := ""
  Loop {
    if (!b := NumGet(buff, A_Index - 1, "UChar"))
      break
    ch := Chr(b)
    ; "is alnum" is not used because it is locale dependent.
    if (b >= 0x41 && b <= 0x5A ; A-Z
      || b >= 0x61 && b <= 0x7A ; a-z
      || b >= 0x30 && b <= 0x39 ; 0-9
      || InStr(sExcepts, Chr(b), true))
      encoded .= Chr(b)
    else {
      DllCall(func, "Str", hex, "Str", "%%%02X", "UChar", b, "Cdecl")
      encoded .= hex
    }
  }
  return encoded
}

UrlDecode(Url, Enc := "UTF-8") {
  Pos := 1
  Loop {
    Pos := RegExMatch(Url, "i)(?:%[\da-f]{2})+", &code, Pos++)
    If (Pos = 0)
      Break
    code := code[0]
    var := Buffer(StrLen(code) // 3, 0)
    code := SubStr(code, 2)
    loop Parse code, "`%"
      NumPut("UChar", Integer("0x" . A_LoopField), var, A_Index - 1)
    Url := StrReplace(Url, "`%" code, StrGet(var, Enc))
  }
  Return Url
}