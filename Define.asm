;;Define.asm: Defines some functions or procedure
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

.code
CopyMemory proc NEAR32 STDCALL PUBLIC USES esi edi ecx, __lpDst:DWORD, __lpSrc:DWORD, __dwLength:DWORD
  cld    ;;set DF = 0; DF = 0 ==> inc or ++, DF = 1 ==> dec or --;
  mov esi, __lpSrc
  mov edi, __lpDst
  xor ecx, ecx
  mov ecx, __dwLength
  rep movsb
  xor eax, eax
  mov eax, __dwLength
  ret
CopyMemory endp

InitListView proc NEAR32 STDCALL PUBLIC __hList:HWND, __lstLvHdrs:PTR SListHead, __dwCount:DWORD
  local @dwSize:DWORD
  local __stColumn:LVCOLUMN
  pushad
  
  ;;;;set Style
  xor eax, eax
  invoke GetWindowLong, __hList, GWL_STYLE
  xor ebx, ebx
  mov ebx, eax
  AND ebx, NOT LVS_TYPEMASK
  OR  ebx, LVS_REPORT
  invoke SetWindowLong, __hList, GWL_STYLE, ebx
  
  ;;;;set Extended Style
  xor eax, eax
  invoke SendMessage, __hList, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0
  xor ebx, ebx
  mov ebx, eax
  OR ebx, LVS_EX_FULLROWSELECT
  OR ebx, LVS_EX_GRIDLINES
  invoke SendMessage, __hList, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, ebx
  
  ;;;;insert the table header
  invoke RtlZeroMemory, addr __stColumn, sizeof LVCOLUMN
  mov __stColumn.imask, LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM or LVCF_FMT;
  mov __stColumn.iSubItem, 0
  
  xor edi, edi
  mov edi, __lstLvHdrs
  mov @dwSize, sizeof SListHead
  xor ecx, ecx
  mov ecx, 0
  .while ecx < __dwCount
     ;;column i:
     xor eax, eax
     mov eax, [edi + SListHead.iAlign]
     mov __stColumn.fmt, eax
     xor eax, eax
     mov eax, [edi + SListHead.iWidth]
     mov __stColumn.lx, eax
     xor eax, eax
     mov eax, [edi + SListHead.strTitle]
     mov __stColumn.pszText, eax
     invoke SendMessage, __hList, LVM_INSERTCOLUMN, ecx, addr __stColumn
     
     ;Next
     inc ecx
     add edi, @dwSize
  .endw
  
  popad
  mov eax, TRUE
  ret
InitListView endp

END