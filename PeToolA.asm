;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include <comctl32.inc>
include <comdlg32.inc>
include Define.inc
include MainWnd.inc

;;;库文件;;;
includelib <user32.lib>
includelib <kernel32.lib>
includelib <comctl32.lib>
includelib <msvcrt.lib>
includelib <shlwapi.lib>

EXTERN strCapInf:BYTE, strCapErr:BYTE, strAppInstErr:BYTE
EXTERN g_aTabPages:SPePage
PUBLIC g_hAppMain

;;;常量数据段;;;
.const
  strCap db 'Message', 0
  strMsg db 'Hello,Win32 ASM World!!!', 0

;;;已初始化数据段;;;
.data
  hInstCur dd 0
  hMainWnd dd 0

;;;未初始化数据段;;;
.data?
  g_hAppMain HINSTANCE ?
  szCmdLine  LPSTR     ?

;;;代码段;;;
.code
;;;;Initialize the Instance
InitInstance proc NEAR32 STDCALL PUBLIC
  pushad
  
  ;Initialize common controlers:tab page,list ctrl,tree ctrl,and so on;
  call InitCommonControls
  
  xor eax, eax
  invoke InitMainWnd, SW_SHOWNORMAL  ;;;SEQ:222222
  .if eax == FALSE
     jmp ERR_InitInstance
  .endif
  
  xor eax, eax
  invoke InitTabPage, TAB_PE_FILE    ;;;SEQ:333333
  .if eax == FALSE
     jmp ERR_InitInstance
  .endif
  
  popad
  mov eax, TRUE
  ret
  
  ERR_InitInstance:
  popad
  mov eax, FALSE
  ret
InitInstance endp

;;;;Destroy the Instance
ExitInstance proc NEAR32 STDCALL PUBLIC dwExitCode:DWORD
  pushad
  invoke FreeTabPage                 ;;;SEQ:333333
  invoke FreeMainWnd                 ;;;SEQ:222222
  popad
  invoke ExitProcess, dwExitCode
  xor eax, eax
  mov eax, TRUE
  ret
ExitInstance endp

;;;;实现WinMain()函数;;;;
WinMain proc NEAR32 STDCALL PUBLIC hInstance:HINSTANCE, hPrevInstance:HINSTANCE, lpCmdLine:LPSTR, iCmdShow:UINT
  local _stMsg: MSG
  local _ExitCode: DWORD
  
  mov _ExitCode, 0
  
  pushad ;backup all registers
  
  ;;;Add your code
  xor eax, eax
  mov eax, hInstance
  mov g_hAppMain, eax
  
  ;Initialize the instance
  xor eax, eax
  call InitInstance
  .if eax == FALSE
     mov _ExitCode, 1
     invoke MessageBox, NULL, offset strAppInstErr, offset strCapErr, MSG_BTN_STYLE_ERR
     jmp ERR_WinMain
  .endif
  
  ;UDM_PARSECOMMANDLINE: parse the commmand line parameter
  .if lpCmdLine
     xor eax, eax
     invoke lstrlen, lpCmdLine
     .if eax
        xor esi, esi
        mov esi, offset g_aTabPages
        xor eax, eax
        mov eax, HWND PTR [esi + SPePage.hTabWnd]
        .if eax
           invoke SendMessage, eax, UDM_PARSECOMMANDLINE, 0, lpCmdLine
        .endif
     .endif
  .endif
  
  ;Main message loop
  .while TRUE
     ;;;GetMessage()是同步消息读取,无消息时原地等待;PeekMessage是异步消息读取,无消息时直接返回0;
     ;;;有消息时,这两个函数都是读取消息并返回;如果要充分利用CPU资源,可考虑使用PeekMessage()函数;
     xor eax, eax
     invoke GetMessage, addr _stMsg, NULL, 0, 0
     .break .if eax < 0  ;;;GetMessage failed;
     .break .if eax == 0 ;;;return the WM_QUIT message;
     invoke TranslateMessage, addr _stMsg
     invoke DispatchMessage, addr _stMsg
  .endw
  
  mov eax, _stMsg.wParam
  mov _ExitCode, eax
  
  ERR_WinMain:
  popad ;restore all registers
  call ExitInstance
  xor eax, eax
  mov eax, _ExitCode
  ret
WinMain endp

;;;;定义程序的入口地址;;;;
start:
  ;STEP1: get the hInstance of current process
  xor eax, eax
  invoke GetModuleHandle, NULL
  .if eax == NULL
    invoke ExitProcess, 0
  .endif
  mov hInstCur, eax
  
  ;STEP2: get the command ling prametere for current process
  xor eax, eax
  invoke GetCommandLine
  mov szCmdLine, eax
  
  xor esi, esi
  mov esi, eax
  xor al, al
  mov al, BYTE PTR [esi]
  .while (al != 0)
     .break .if al == 20H ;;20H:空格
     inc esi
     mov al, BYTE PTR [esi]
  .endw
  
  .if al == 32            ;;32D:空格
     inc esi
     mov szCmdLine, esi
  .endif
  
  .if al == 0
     mov szCmdLine, 0
  .endif
  
  ;STEP3: call the main program:WinMain()
  xor eax, eax
  invoke WinMain, hInstCur, NULL, szCmdLine, SW_SHOWNORMAL
  invoke ExitProcess, eax
end start

END