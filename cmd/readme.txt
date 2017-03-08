
PostBuild_Cmds=cscript //Nologo cmd\CopyByTime.vbs Debug\PeToolC.exe D
PostBuild_Cmds=cscript //Nologo cmd\CopyByTime.js Release\PeToolC.exe R

PostBuild_Cmds=copy /Y debug\PeToolA.exe Debug\PeTool%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%_D.exe
PostBuild_Cmds=copy /Y release\PeToolA.exe Release\PeTool%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%_R.exe

PostBuild_Cmds=echo F|xcopy /Y debug\PeToolA.exe Debug\PeTool%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%_D.exe
PostBuild_Cmds=echo F|xcopy /Y release\PeToolA.exe Release\PeTool%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%_R.exe
