Option Explicit

Function formatCurrentTime()
  Dim strCurTime
  Dim date_sep_char
  Dim time_sep_char
  Dim varYear, varMonth, varDay
  Dim varHour, varMinute, varSecond
  Dim curDT
  
  strCurTime = "" : date_sep_char = "" : time_sep_char = ""
  varYear = 0 : varMonth = 0 : varDay = 0
  varHour = 0 : varMinute = 0 : varSecond = 0
  curDT = Null
  
  curDT = Now()
  
  varYear = Year(curDT)
  varMonth = Month(curDT)
  If varMonth < 10 Then
    varMonth  = "0" & varMonth
  End If
  
  varDay = Day(curDT)
  If varDay < 10 Then
    varDay = "0" & varDay
  End If
  
  varHour = Hour(curDT)
  If varHour < 10 Then
    varHour = "0" & varHour
  End If
  
  varMinute = Minute(curDT)
  If varMinute < 10 Then
    varMinute = "0" & varMinute
  End If
  
  varSecond = Second(curDT)
  If varSecond < 10 Then
    varSecond = "0" & varSecond
  End If
  
  'date
  strCurTime = strCurTime & varYear & date_sep_char & varMonth & date_sep_char & varDay
  'time
  strCurTime = strCurTime & varHour & time_sep_char & varMinute
  formatCurrentTime = strCurTime
End Function

Dim argv
Set argv = WScript.Arguments
Dim args
args = WScript.Arguments.Length

If args < 2 Then
  WScript.Echo("Usage: CopyByTime.vbs <FilePath> <Version>")
  WScript.Quit(1)
End If

Dim strOldFile
strOldFile = argv(0)

Dim strVersion
strVersion = argv(1)

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")

Dim strBaseName
strBaseName = fso.GetBaseName(strOldFile)

Dim strExtnName
strExtnName = fso.GetExtensionName(strOldFile)

Dim strFullPath
strFullPath = fso.GetAbsolutePathName(strOldFile)

Dim strFolder
strFolder = "."

Dim idx
idx = InStrRev(strOldFile,"\")
If idx > 0 Then
  strFolder = Left(strOldFile, idx - 1)
End If

Dim strTimeStr
strTimeStr = formatCurrentTime()

Dim strNewFile
strNewFile = strFolder + "\" + strBaseName + strTimeStr + "_" + strVersion + "." + strExtnName

'backup/copy file
fso.CopyFile strOldFile, strNewFile

'rename file
'fso.MoveFile strOldFile, strNewFile

Set fso = Nothing
