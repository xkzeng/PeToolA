;;;ģʽ����;;;
.386
.model flat,stdcall
option casemap:none

;;;ͷ�ļ�;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include <comctl32.inc>
include <comdlg32.inc>
include Define.inc
include MainWnd.inc

;;;���ļ�;;;
includelib <user32.lib>
includelib <kernel32.lib>
includelib <comctl32.lib>
includelib <msvcrt.lib>
includelib <shlwapi.lib>

EXTERN strCapInf:BYTE, strCapErr:BYTE, strAppInstErr:BYTE
EXTERN g_aTabPages:SPePage
PUBLIC g_hAppMain

;;;�������ݶ�;;;
.const
  strCap db 'Message', 0
  strMsg db 'Hello,Win32 ASM World!!!', 0

;;;�ѳ�ʼ�����ݶ�;;;
.data
  hInstCur dd 0
  hMainWnd dd 0

;;;δ��ʼ�����ݶ�;;;
.data?
  g_hAppMain HINSTANCE ?
  szCmdLine  LPSTR     ?

;;;�����;;;
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

;;;;ʵ��WinMain()����;;;;
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
     ;;;GetMessage()��ͬ����Ϣ��ȡ,����Ϣʱԭ�صȴ�;PeekMessage���첽��Ϣ��ȡ,����Ϣʱֱ�ӷ���0;
     ;;;����Ϣʱ,�������������Ƕ�ȡ��Ϣ������;���Ҫ�������CPU��Դ,�ɿ���ʹ��PeekMessage()����;
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

;;;;����������ڵ�ַ;;;;
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
     .break .if al == 20H ;;20H:�ո�
     inc esi
     mov al, BYTE PTR [esi]
  .endw
  
  .if al == 32            ;;32D:�ո�
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