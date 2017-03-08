;New DataType
LPNMHDR typedef DWORD

;Message for User defined
UDM_FILLFORM         equ WM_USER+1000
UDM_SETTITLETEXT     equ WM_USER+1001
UDM_PARSECOMMANDLINE equ WM_USER+1002
UDM_CR_UPDATE        equ WM_USER+1003

;;;Index for tab page
TAB_PE_FILE equ 0  ;Home Page
TAB_DOS_HDR equ 1  ;Dos Header
TAB_FIL_HDR equ 2  ;File Header
TAB_OPT_HDR equ 3  ;Optional Header
TAB_DAT_DIR equ 4  ;Data Directory
TAB_BLK_TBL equ 5  ;Section Table
TAB_EXP_TBL equ 6  ;Export Table
TAB_IMP_TBL equ 7  ;Import Table
TAB_RLC_TBL equ 8  ;Base Relocation Table
TAB_RES_TBL equ 9  ;Resource Table
TAB_USR_OPR equ 10 ;User Operation
NUMBER_TABS equ 11 ;Number of Tab Pages

;some constants about 
PAGE_TITLE_LEN equ 32
TEMP_BUFF_SIZE equ 32

MSG_BTN_STYLE_INF = MB_OKCANCEL or MB_ICONINFORMATION
MSG_BTN_STYLE_ERR = MB_OKCANCEL or MB_ICONERROR
MSG_BTN_STYLE_WRN = MB_OKCANCEL or MB_ICONWARNING

;Define struct for the Tab Page
SPePage STRUCT
  uiIDD    UINT    ?
  hTabWnd  HWND    ?
  ProcWnd  DLGPROC ?
  strTitle LPSTR   ?
SPePage ENDS

;Define the column of the List Ctrl Header
SListHead STRUCT
  strTitle LPTSTR 0
  iWidth   UINT   0
  iAlign   UINT   0
SListHead ENDS

CopyMemory PROTO NEAR32 STDCALL __lpDst:DWORD, __lpSrc:DWORD, __dwLength:DWORD
InitListView PROTO NEAR32 STDCALL __hList:HWND, __lstLvHdrs:PTR SListHead, __dwCount:DWORD
