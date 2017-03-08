;;TabDatDir.asm: Implementation File
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
include WndRes.inc
include PeFile.inc

CNT_LIST_COLS = 4

EXTERN strCapInf:BYTE, strCapErr:BYTE
EXTERN strFmt2U:BYTE, strFmt8X:BYTE
EXTERNDEF g_lpDatDir:PIMAGE_DATA_DIRECTORY, g_lpOptHdr:PIMAGE_OPTIONAL_HEADER

.const
   ;;;Column Name Text for ListCtrl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strCol0 db 'Type', 0           ;;0
   strCol1 db 'Name', 0           ;;1
   strCol2 db 'VirtualAddress', 0 ;;2
   strCol3 db 'Size', 0           ;;3
   ;;;Type Name Text for Section Table;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strTypeName00 db 'Export Directory', 0              ;;00
   strTypeName01 db 'Import Directory', 0              ;;01
   strTypeName02 db 'Resource Directory', 0            ;;02
   strTypeName03 db 'Exception Directory', 0           ;;03
   strTypeName04 db 'Security Directory', 0            ;;04
   strTypeName05 db 'Base Relocation Table', 0         ;;05
   strTypeName06 db 'Debug Directory', 0               ;;06
   strTypeName07 db 'Architecture Specific Data', 0    ;;07
   strTypeName08 db 'RVA of GP', 0                     ;;08
   strTypeName09 db 'TLS Directory', 0                 ;;09
   strTypeName10 db 'Load Configuration Directory', 0  ;;10
   strTypeName11 db 'Bound Import Directory', 0        ;;11
   strTypeName12 db 'Import Address Table', 0          ;;12
   strTypeName13 db 'Delay Load Import Descriptors', 0 ;;13
   strTypeName14 db 'COM Runtime Descriptor', 0        ;;14
   strTypeName15 db 'UnUsed', 0                        ;;15
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidDatDir db '获取的DataDirectory无效', 0

.data
   _hWnd      HWND NULL ;;当前页面窗口的句柄;
   _hListCtrl HWND NULL ;;当前页面窗口上面的列表控件句柄;
   _stLvHdr SListHead <offset strCol0, 40,  LVCFMT_CENTER> ;;0 Type
            SListHead <offset strCol1, 190, LVCFMT_LEFT>   ;;1 Name
            SListHead <offset strCol2, 96,  LVCFMT_CENTER> ;;2 VirtualAddress
            SListHead <offset strCol3, 60,  LVCFMT_CENTER> ;;3 Size
   _strDatDirTypeName LPCTSTR offset strTypeName00 ;;;Export Directory
                      LPCTSTR offset strTypeName01 ;;;Import Directory
                      LPCTSTR offset strTypeName02 ;;;Resource Directory
                      LPCTSTR offset strTypeName03 ;;;Exception Directory
                      LPCTSTR offset strTypeName04 ;;;Security Directory
                      LPCTSTR offset strTypeName05 ;;;Base Relocation Table
                      LPCTSTR offset strTypeName06 ;;;Debug Directory
                      LPCTSTR offset strTypeName07 ;;;Architecture Specific Data
                      LPCTSTR offset strTypeName08 ;;;RVA of GP
                      LPCTSTR offset strTypeName09 ;;;TLS Directory
                      LPCTSTR offset strTypeName10 ;;;Load Configuration Directory
                      LPCTSTR offset strTypeName11 ;;;Bound Import Directory
                      LPCTSTR offset strTypeName12 ;;;Import Address Table
                      LPCTSTR offset strTypeName13 ;;;Delay Load Import Descriptors
                      LPCTSTR offset strTypeName14 ;;;COM Runtime Descriptor
                      LPCTSTR offset strTypeName15 ;;;UnUsed

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_DATA_DIRECTORY
  mov _hListCtrl, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @iRow:UINT, @dwSize:DWORD, @dwDatDirNum:DWORD
  local @stRow:LVITEM
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hListCtrl, LVM_DELETEALLITEMS, 0, 0
  
  .if ((g_lpDatDir == NULL) || (g_lpOptHdr == NULL))
     invoke MessageBox, _hWnd, offset strInvalidDatDir, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, g_lpOptHdr    ; esi ---> IMAGE_OPTIONAL_HEADER
  xor eax, eax
  mov eax, [esi + IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes]
  mov @dwDatDirNum, eax  ;Number of data directory entry in Data Directory;
  
  xor ebx, ebx
  mov ebx, offset _strDatDirTypeName
  
  xor esi, esi
  mov esi, g_lpDatDir    ;esi ---> IMAGE_DATA_DIRECTORY; Base Address of Data Directory
  mov @dwSize, sizeof IMAGE_DATA_DIRECTORY
  xor ecx, ecx           ;ecx = 0
  .while ecx < @dwDatDirNum  ;;;;;
     push ecx
     ;;STEP1: insert a row -> ecx;
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hListCtrl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;Type:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt2U, @iRow
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Name:
     mov @stRow.iSubItem, 1
     mov eax, [ebx]
     mov @stRow.pszText, eax  ;;Type Name
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;VirtualAddress:
     mov @stRow.iSubItem, 2
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_DATA_DIRECTORY.VirtualAddress]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Size:
     mov @stRow.iSubItem, 3
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     pop ecx
     
     ;Next
     inc ecx                 ;next index
     add ebx, sizeof LPCTSTR ;next Type Name
     add esi, @dwSize        ;next Data Directory Entry
  .endw
  
  mov @dwRet, TRUE
  
  ERR_Fill:
  popad
  mov eax, @dwRet
  ret
_Fill endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Message Handlers
_OnFillForm proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  invoke _Fill, NULL
  popad
  mov eax, TRUE
  ret
_OnFillForm endp

;;实现应用程序对话框过程;
DatDirProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke InitListView, _hListCtrl, offset _stLvHdr, CNT_LIST_COLS
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke _OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
DatDirProc endp

END