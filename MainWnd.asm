;;MainWnd.asm: Implement the main window of application;
;;

;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>

include Define.inc
include PeFile.inc
include WndRes.inc
include MainWnd.inc
include TabPeFile.inc
include TabDosHdr.inc
include TabFilHdr.inc
include TabOptHdr.inc
include TabDatDir.inc
include TabBlkTbl.inc
include TabExpTbl.inc
include TabImpTbl.inc
include TabRlcTbl.inc
include TabResTbl.inc
include TabUsrOpr.inc

LPNMHDR typedef DWORD

EXTERN strCapInf:BYTE, strCapErr:BYTE, strMainWndErr:BYTE, strMainIcoErr:BYTE
EXTERN g_hAppMain:HINSTANCE
PUBLIC g_hWndMain, g_aTabPages

.const
   strTabCtrlErr db '获取TAB控件句柄失败', 0
   strTabPageErr db '创建TAB页面窗口失败', 0

.data
   g_hWndMain HWND  NULL  ;应用程序主窗口的句柄,只有一个;
   g_hIcoMain HICON NULL  ;应用程序主窗口的图标句柄,只有一个;
   g_hTabCtrl HWND  NULL  ;Tab控件的句柄,只有一个;
   strPeFile  db '文  件',   0
   strDosHdr  db 'DOS 头',   0
   strFilHdr  db '文件头',   0
   strOptHdr  db '可选头',   0
   strDatDir  db '数据目录', 0
   strBlkTbl  db '节  表',   0
   strExpTbl  db '导出表',   0
   strImpTbl  db '导入表',   0
   strRlcTbl  db '重定位表', 0
   strResTbl  db '资源表',   0
   strUsrOpr  db '操  作',   0
   ;;;;;;;;;;;;;;;;;;;;;uiIDD,           hTabWnd, ProcWnd,    strTitle
   g_aTabPages SPePage <IDD_DLG_PE_FILE, NULL,    PeFileProc, offset strPeFile> ;;;00
               SPePage <IDD_DLG_DOS_HDR, NULL,    DosHdrProc, offset strDosHdr> ;;;01
               SPePage <IDD_DLG_FIL_HDR, NULL,    FilHdrProc, offset strFilHdr> ;;;02
               SPePage <IDD_DLG_OPT_HDR, NULL,    OptHdrProc, offset strOptHdr> ;;;03
               SPePage <IDD_DLG_DAT_DIR, NULL,    DatDirProc, offset strDatDir> ;;;04
               SPePage <IDD_DLG_BLK_TBL, NULL,    BlkTblProc, offset strBlkTbl> ;;;05
               SPePage <IDD_DLG_EXP_TBL, NULL,    ExpTblProc, offset strExpTbl> ;;;06
               SPePage <IDD_DLG_IMP_TBL, NULL,    ImpTblProc, offset strImpTbl> ;;;07
               SPePage <IDD_DLG_RLC_TBL, NULL,    RlcTblProc, offset strRlcTbl> ;;;08
               SPePage <IDD_DLG_RES_TBL, NULL,    ResTblProc, offset strResTbl> ;;;09
               SPePage <IDD_DLG_USR_OPR, NULL,    UsrOprProc, offset strUsrOpr> ;;;10

.code
InitMainWnd proc NEAR32 STDCALL PUBLIC uiCmdShow:UINT
  pushad
  
  ;;Load the icon of the application main window;
  mov g_hIcoMain, NULL
  invoke LoadIcon, g_hAppMain, IDI_MAIN_WND
  .if eax == NULL
     invoke MessageBox, NULL, offset strMainIcoErr, offset strCapErr, MSG_BTN_STYLE_ERR
     jmp ERR_InitMainWnd
  .endif
  mov g_hIcoMain, eax
  
  ;;Create the main window from resource template;
  mov g_hWndMain, NULL
  invoke GetDesktopWindow
  invoke CreateDialogParam, g_hAppMain, IDD_PE_MAIN_WND, eax, offset MainWndProc, NULL
  .if eax == NULL
     invoke MessageBox, NULL, offset strMainWndErr, offset strCapErr, MSG_BTN_STYLE_ERR
     jmp ERR_InitMainWnd
  .endif
  mov g_hWndMain, eax
  
  ;;显示主对话框窗口,如果在资源编辑器中为对话框设置了WS_VISIBLE属性,那么这里就不必再调用ShowWindow函数了;
  invoke ShowWindow, g_hWndMain, uiCmdShow ;;显示对话框;
  
  ;;此处不必刷新对话框窗口;
  invoke UpdateWindow, g_hWndMain          ;;更新对话框;
  
  popad
  mov eax, TRUE
  ret
  
  ERR_InitMainWnd:
  popad
  mov eax, FALSE
  ret
InitMainWnd endp

FreeMainWnd proc NEAR32 STDCALL PUBLIC
  .if g_hWndMain
     invoke DestroyWindow, g_hWndMain
     ;mov g_hWndMain, NULL  ;;<<<<------------ ???????
  .endif
FreeMainWnd endp

InitTabPage proc NEAR32 STDCALL PUBLIC __iDefSel:DWORD
  local @dwResult:DWORD, @X:DWORD, @Y:DWORD, @W:DWORD, @H:DWORD, @i:DWORD
  local @item:TCITEM
  local @dwSize:DWORD
  local @rt:RECT
  
  mov @dwResult, FALSE
  mov @W, 0
  mov @H, 0
  mov @X, 0
  mov @Y, 0
  
  pushad
  xor eax, eax
  invoke GetDlgItem, g_hWndMain, IDC_TAB_PETOOL
  .if eax == NULL
     invoke MessageBox, g_hWndMain, offset strTabCtrlErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwResult, FALSE
     jmp ERR_InitTabPage
  .endif
  mov g_hTabCtrl, eax
  
  invoke RtlZeroMemory, addr @rt, sizeof RECT
  invoke GetClientRect, g_hTabCtrl, addr @rt
  add @rt.top,    20
  sub @rt.bottom, 2
  add @rt.left,   2
  sub @rt.right,  2
  
  invoke RtlZeroMemory, addr @item, sizeof TCITEM
  mov @item.imask, TCIF_TEXT or TCIF_PARAM or TCIF_STATE
  
  mov @dwSize, sizeof SPePage
  mov esi, offset g_aTabPages  ;;此处不能用edx作为结构体的访问指针,因为edx的功能比较特殊;
  mov @i, 0
  .while @i < NUMBER_TABS
     ;create tab widnow
     xor eax, eax
     invoke CreateDialogParam, g_hAppMain, [esi + SPePage.uiIDD], g_hTabCtrl, [esi + SPePage.ProcWnd], NULL
     .if eax == NULL
        invoke MessageBox, NULL, offset strTabPageErr, offset strCapErr, MSG_BTN_STYLE_ERR
        mov @dwResult, FALSE
        jmp ERR_InitTabPage
     .endif
     
     ;save the handle for this tab window
     mov [esi + SPePage.hTabWnd], eax
     
     ;move and show the tab window
     mov ebx, @rt.left
     mov @X, ebx
     
     mov ebx, @rt.top
     mov @Y, ebx
     
     mov ebx, @rt.right
     sub ebx, @rt.left
     mov @W, ebx
     
     mov ebx, @rt.bottom
     sub ebx, @rt.top
     mov @H, ebx
     invoke MoveWindow, [esi + SPePage.hTabWnd], @X, @Y, @W, @H, TRUE
     
     mov edi, @i
     .if edi == __iDefSel
        mov ebx, TRUE
     .else
        mov ebx, FALSE
     .endif
     invoke ShowWindow, [esi + SPePage.hTabWnd], ebx
     
     ;insert one tab window
     ;item.cchTextMax = 5;
     mov ebx, [esi + SPePage.strTitle]
     mov @item.pszText, ebx
     invoke SendMessage, g_hTabCtrl, TCM_INSERTITEM, @i, addr @item
     
     ;next
     inc @i
     add esi, @dwSize ;next tab wnd
  .endw
  
  ;;;;OPTIONAL CODE;;;; BEGIN
  ;;invoke SendMessage, g_hTabCtrl, TCM_SETCURSEL, __iDefSel, 0
  ;;mov esi, offset g_aTabPages
  ;;mov eax, __iDefSel
  ;;mul @dwSize
  ;;add esi, eax
  ;;invoke ShowWindow, [esi + SPePage.hTabWnd], TRUE
  ;;;;OPTIONAL CODE;;;; END
  mov @dwResult, TRUE
  
  ERR_InitTabPage:
  popad
  mov eax, @dwResult
  ret
InitTabPage endp

FreeTabPage proc NEAR32 STDCALL PUBLIC
  local @i:DWORD, @dwSize:DWORD
  pushad
  
  mov @i, 0
  mov @dwSize, sizeof SPePage
  mov esi, offset g_aTabPages  ;此处不能用edx作为结构体的访问指针,因为edx的功能比较特殊;
  .while @i < NUMBER_TABS
     ;hWnd
     xor ebx, ebx
     mov ebx, [esi + SPePage.hTabWnd]
     .if ebx
        invoke DestroyWindow, ebx
        mov [esi + SPePage.hTabWnd], NULL
     .endif
     
     inc @i
     add esi, @dwSize
  .endw
  
  popad
  mov eax, TRUE
  ret
FreeTabPage endp

_OnTabSelChange proc NEAR32 STDCALL PRIVATE lpNMHDR:LPNMHDR
  local @i:LONG, @dwResult:DWORD, @dwSize:DWORD
  local @lCurSel:LRESULT
  
  mov @dwResult, TRUE
  mov @lCurSel, -1
  
  pushad
  xor eax, eax
  invoke SendMessage, g_hTabCtrl, TCM_GETCURSEL, 0, 0
  .if eax < 0 ;;no tab is selected
     mov @dwResult, FALSE
     jmp EXIT_OnTabSelChange
  .endif
  mov @lCurSel, eax
  
  xor esi, esi
  mov esi, offset g_aTabPages
  mov @dwSize, sizeof SPePage
  mov @i, 0
  .while @i < NUMBER_TABS
     ;hWnd
     xor ebx, ebx
     mov ebx, [esi + SPePage.hTabWnd]
     .if ebx
        mov eax, @i
        .if eax == @lCurSel
           mov eax, TRUE
        .else
           mov eax, FALSE
        .endif
        invoke ShowWindow, ebx, eax
     .endif
     
     inc @i
     add esi, @dwSize
  .endw
  
  EXIT_OnTabSelChange:
  popad
  mov eax, @dwResult
  ret
_OnTabSelChange endp

_OnNotify proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  .if __lParam == 0
     ret
  .endif
  
  pushad
  xor esi, esi
  mov esi, __lParam
  
  .if DWORD PTR [esi + NMHDR.code] == TCN_SELCHANGE
     invoke _OnTabSelChange, __lParam
  .endif
  
  popad
  mov eax, TRUE
  ret
_OnNotify endp

_OnSetTitleText proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  local @dwLen:DWORD
  local @strTitle[FILE_PATH_LEN]:TCHAR
  pushad
  
  invoke RtlZeroMemory, addr @strTitle, sizeof @strTitle
  xor eax, eax
  invoke GetModuleFileName, NULL, addr @strTitle, sizeof @strTitle
  .if eax == 0
     invoke RtlZeroMemory, addr @strTitle, sizeof @strTitle
     invoke SendMessage, g_hWndMain, WM_GETTEXT, sizeof @strTitle, addr @strTitle ;;;eax = lstrlen(@strTitle)
  .endif
  mov @dwLen, eax
  
  xor ecx, ecx
  mov ecx, eax
  dec ecx
  
  xor esi, esi
  lea esi, @strTitle
  add esi, @dwLen
  
  xor al, al
  mov al, BYTE PTR [esi]
  .while ecx >= 0
     .break .if al == 5Ch ;;5Ch: '\'
     dec ecx
     dec esi
     xor al, al
     mov al, BYTE PTR [esi]
  .endw
  
  .if al == 92 ;;92d: '\', 找到'\'
     inc esi   ;;skip '\'
     xor ecx, ecx
     
     ;;copy file name
     xor edi, edi
     lea edi, @strTitle
     
     xor al, al
     mov al, BYTE PTR [esi]
     .while al != 0
        mov BYTE PTR [edi], al
        inc esi
        inc edi
        inc ecx
        mov al, BYTE PTR [esi]
     .endw
  .else  ;;;没有找到'\'
     mov ecx, @dwLen
  .endif
  
  xor edi, edi
  lea edi, @strTitle
  add edi, ecx
  
  mov BYTE PTR [edi], 20H ;;append a space' '
  inc edi
  mov BYTE PTR [edi], 2DH ;;append a char '-'
  inc edi
  mov BYTE PTR [edi], 3EH ;;append a char '>'
  inc edi
  mov BYTE PTR [edi], 20H ;;append a space ' '
  inc edi
  add ecx, 4
  
  xor esi, esi
  mov esi, __lParam
  
  xor al, al
  mov al, BYTE PTR [esi]
  .while al != 0
     mov BYTE PTR [edi], al
     inc ecx
     inc edi
     inc esi
     xor al, al
     mov al, BYTE PTR [esi]
  .endw
  
  ;;clear the left space
  xor ebx, ebx
  lea ebx, @strTitle
  add ebx, ecx
  
  xor eax, eax
  mov eax, sizeof @strTitle
  sub eax, ecx
  
  ;invoke RtlZeroMemory, ebx, eax
  xor ecx, ecx
  mov ecx, eax
  CLR_LOOP:
  mov BYTE PTR [ebx], 0
  inc ebx
  LOOPZ CLR_LOOP
  
  invoke SendMessage, g_hWndMain, WM_SETTEXT, 0, addr @strTitle
  
  popad
  mov eax, TRUE
  ret
_OnSetTitleText endp

;收到通知消息之后,再通知其它子窗口,进行填充界面;
OnFillForm proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  local @i:DWORD, @dwSize:DWORD
  pushad
  
  xor esi, esi
  mov esi, offset g_aTabPages
  mov @dwSize, sizeof SPePage
  mov @i, 0
  
  .while @i < NUMBER_TABS
     ;hWnd
     xor ebx, ebx
     mov ebx, [esi + SPePage.hTabWnd]
     .if ebx
        invoke PostMessage, ebx, UDM_FILLFORM, 0, 0
     .endif
     
     ;NEXT
     inc @i
     add esi, @dwSize
  .endw
  
  popad
  mov eax, TRUE
  ret
OnFillForm endp

;;实现应用程序对话框过程;
MainWndProc proc NEAR32 STDCALL PUBLIC __hMainWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  
  mov @dwResult, NULL
  
  pushad
  xor eax, eax
  
  .if __uMsg == WM_INITDIALOG
     invoke SendMessage, __hMainWnd, WM_SETICON, ICON_SMALL, g_hIcoMain
     mov @dwResult, TRUE
  .elseif __uMsg == WM_NOTIFY
     .if (__wParam == IDC_TAB_PETOOL)
        invoke _OnNotify, __wParam, __lParam
     .endif
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_SETTITLETEXT
     invoke _OnSetTitleText, __wParam, __lParam
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .elseif __uMsg == WM_COMMAND
     .if ((__wParam == SC_CLOSE) || (__wParam == IDOK) || (__wParam == IDCANCEL))
        invoke PostQuitMessage, 0
     .endif
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  
  popad
  mov eax, @dwResult
  ret
MainWndProc endp

END