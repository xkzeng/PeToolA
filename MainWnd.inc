;;MainWnd.inc: Define the main window of application;
;;

InitMainWnd PROTO NEAR32 STDCALL iCmdShow:DWORD
FreeMainWnd PROTO NEAR32 STDCALL
InitTabPage PROTO NEAR32 STDCALL _iDefSel:DWORD
FreeTabPage PROTO NEAR32 STDCALL
MainWndProc PROTO NEAR32 STDCALL hMainWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
