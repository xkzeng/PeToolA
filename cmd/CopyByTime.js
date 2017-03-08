function formatCurrentTime()
{
  var str = "";
  var date_sep_char = '';
  var time_sep_char = '';
  var year = 0, month = 0, day = 0;
  var hour = 0, minute = 0, second = 0;
  var curDT = null;
  
  curDT = new Date();
  
  year = curDT.getYear();
  month = curDT.getMonth() + 1;
  if(month < 10)
  {
    month = '0' + month;
  }
  
  day = curDT.getDate();
  if(day < 10)
  {
    day = '0' + day;
  }
  
  hour = curDT.getHours();
  if(hour < 10)
  {
    hour = '0' + hour;
  }
  
  minute = curDT.getMinutes();
  if(minute < 10)
  {
    minute = '0' + minute;
  }
  
  second = curDT.getSeconds();
  if(second < 10)
  {
    second = '0' + second;
  }
  
  //date
  str = str + year + date_sep_char + month + date_sep_char + day;
  //time
  str = str + hour + time_sep_char + minute;
  return (str);
}

var argv = WScript.Arguments;
var args = WScript.Arguments.length;

if(args < 2)
{
  WScript.Echo("Usage: CopyByTime.js <FilePath> <Version>\n");
  WScript.Quit(1);
}

var strOldFile = argv(0);
var strVersion = argv(1);
var fso = new ActiveXObject("Scripting.FileSystemObject");
var strBaseName = fso.GetBaseName(strOldFile);
var strExtnName = fso.GetExtensionName(strOldFile);
var strFullPath = fso.GetAbsolutePathName(strOldFile);

var strFolder = ".";
var idx = strOldFile.lastIndexOf('\\');
if(idx > 0)
{
  strFolder = strOldFile.substring(0, idx);
}

var strTimeStr = formatCurrentTime();
var strNewFile = strFolder + '\\' + strBaseName + strTimeStr + '_' + strVersion + '.' + strExtnName;

//backup/copy file
fso.CopyFile(strOldFile, strNewFile);

//rename file
//fso.MoveFile(strOldFile, strNewFile);
