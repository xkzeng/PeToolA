;;TabPeFile.asm: Implementation file
;;

;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include <comdlg32.inc>
include <shell32.inc>
include Define.inc
include WndRes.inc
include PeFile.inc
include PeToolA.inc

;;;库文件;;;
includelib <comdlg32.lib>
includelib <shell32.lib>

EXTERN strCapInf:BYTE, strCapErr:BYTE
EXTERN strDefSoftName:BYTE, strDefAuthor:BYTE, strDefEmail:BYTE
EXTERN strFmt1D:BYTE, strFmt2D:BYTE, strFmt4D:BYTE
EXTERNDEF g_strBase:LPBYTE, g_hWndMain:HWND

PFILETIME   typedef DWORD
PSYSTEMTIME typedef DWORD

GetFileExInfoStandard equ 0

.const
   strFileFilter  db 'EXE文件(*.exe)', 0, '*.exe', 0, 'DLL文件(*.dll)', 0, '*.dll', 0, 'OCX文件(*.ocx)', 0, '*.ocx', 0, 'COM文件(*.com)', 0, '*.com', 0, 'SYS文件(*.sys)', 0, '*.sys', 0, 'DRV文件(*.drv)', 0, '*.drv', 0, 0
   strFiltTimeFmt db '%04d-%02d-%02d %02d:%02d:%02d', 0
   strFmtVersion  db '%04d.%02d.%02d', 0
   strFmtAttr1 db '%s,',  0
   strFmtAttr2 db '%s',   0
   strAttrCMN  db '普通', 0
   strAttrDir  db '目录', 0
   strAttrOFL  db '离线', 0
   strAttrSYS  db '系统', 0
   strAttrTMP  db '临时', 0
   strAttrRDO  db '只读', 0
   strAttrHDN  db '隐藏', 0
   strAttrCPR  db '压缩', 0
   strAttrENC  db '加密', 0
   strAttrARC  db '归档', 0
   strAttrUNK  db '未知', 0
   strMsgSelFile  db '请选择文件', 0
   strFileAttrErr db '提取文件属性失败', 0
   strFileSize    db '%I64u bytes', 0
   strInvalidPE   db 'PE文件对象无效', 0
   strOpenPeFail  db '打开文件失败,错误码是%u', 0
   strParsePeFail db '解析文件失败,错误码是%u', 0

.data
   _hWnd HWND NULL ;;当前页面窗口的句柄;

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

FileTime2SystemTime proc NEAR32 STDCALL PUBLIC __lpFileTime:PFILETIME, __lpSysTime:PSYSTEMTIME
  local @ft:FILETIME
  pushad
  invoke FileTimeToLocalFileTime, __lpFileTime, addr @ft
  invoke FileTimeToSystemTime, addr @ft, __lpSysTime
  popad
  mov eax, TRUE
  ret
FileTime2SystemTime endp

FormatFileTime proc NEAR32 STDCALL PUBLIC __strBuf:LPSTR, __dwBufSize:DWORD, __lpFileTime:PFILETIME
  local @ft:FILETIME
  local @st:SYSTEMTIME
  local @dwYear:DWORD, @dwMonth:DWORD, @dwDay:DWORD, @dwHour:DWORD, @dwMinute:DWORD, @dwSecond:DWORD
  
  pushad
  invoke FileTimeToLocalFileTime, __lpFileTime, addr @ft
  invoke FileTimeToSystemTime, addr @ft, addr @st
  
  ;Year
  xor eax, eax
  mov ax, @st.wYear
  mov @dwYear, eax
  
  ;Month
  xor eax, eax
  mov ax, @st.wMonth
  mov @dwMonth, eax
  
  ;Day
  xor eax, eax
  mov ax, @st.wDay
  mov @dwDay, eax
  
  ;Hour
  xor eax, eax
  mov ax, @st.wHour
  mov @dwHour, eax
  
  ;Minute
  xor eax, eax
  mov ax, @st.wMinute
  mov @dwMinute, eax
  
  ;Second
  xor eax, eax
  mov ax, @st.wSecond
  mov @dwSecond, eax
  
  invoke RtlZeroMemory, __strBuf, __dwBufSize
  invoke wsprintf, __strBuf, offset strFiltTimeFmt, @dwYear, @dwMonth, @dwDay, @dwHour, @dwMinute, @dwSecond
  popad
  mov eax, TRUE
  ret
FormatFileTime endp

FormatFileAttr proc NEAR32 STDCALL PUBLIC __strBuf:LPSTR, __dwBufSize:DWORD, __dwFileAttributes:DWORD
  local @dwTotalLen:DWORD
  
  pushad
  mov @dwTotalLen, 0
  invoke RtlZeroMemory, __strBuf, __dwBufSize
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_NORMAL
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke __snprintf, esi, ecx, offset strFmtAttr1, offset strAttrCMN
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrCMN
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrDir
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrDir
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_OFFLINE
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrOFL
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrOFL
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_SYSTEM
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrSYS
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrSYS
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_TEMPORARY
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrTMP
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrTMP
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_READONLY
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrRDO
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrRDO
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_HIDDEN
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrHDN
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrHDN
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_COMPRESSED
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrCPR
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrCPR
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_ENCRYPTED
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrENC
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrENC
     add @dwTotalLen, eax
  .endif
  
  .if __dwFileAttributes & FILE_ATTRIBUTE_ARCHIVE
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrARC
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrARC
     add @dwTotalLen, eax
  .endif
  
  .if @dwTotalLen == 0
     mov esi, __strBuf
     add esi, @dwTotalLen ;;start: pos + @dwTotalLen
     mov ecx, __dwBufSize
     sub ecx, @dwTotalLen ;;bytes: __dwBufSize - @dwTotalLen
     invoke RtlZeroMemory, esi, ecx
     xor eax, eax
     ;invoke _snprintf, esi, ecx, offset strFmtAttr1, offset strAttrUNK
     invoke wsprintf, esi, offset strFmtAttr1, offset strAttrUNK
     add @dwTotalLen, eax
  .endif
  
  mov eax, @dwTotalLen
  mov esi, __strBuf
  .if BYTE PTR [esi + eax - 1] == 44 ;;如果最后一个字符是逗号: ',' = 44 (0x2C)
     dec eax
     mov BYTE PTR [esi + eax], 0    ;;则删除逗号;
  .endif
  
  popad
  ret
FormatFileAttr endp

_ParseFeFile proc NEAR32 STDCALL PRIVATE __strFileName:LPTSTR
  local @dwResult:DWORD
  local @ullFileSize:ULONGLONG
  local @wfad:WIN32_FILE_ATTRIBUTE_DATA
  local @strMsg[TEMP_BUFF_SIZE]:CHAR
  
  mov @dwResult, TRUE;
  pushad
  xor eax, eax
  
  .if ((__strFileName == NULL) || (BYTE PTR [__strFileName] == 0))
     mov @dwResult, FALSE;
     invoke MessageBox, _hWnd, offset strMsgSelFile, offset strCapInf, MSG_BTN_STYLE_INF
     jmp EXIT_ParseFeFile
  .endif
  
  ;.if g_strBase == NULL
  ;   mov @dwResult, FALSE
  ;   invoke MessageBox, _hWnd, offset strInvalidPE, offset strCapErr, MSG_BTN_STYLE_ERR
  ;   jmp EXIT_ParseFeFile
  ;.endif
  
  invoke GetDlgItem, _hWnd, IDC_EDT_PE_FILE
  invoke SendMessage, eax, WM_SETTEXT, 0, __strFileName
  
  ;Get the attribute of the file
  invoke RtlZeroMemory, addr @wfad, sizeof WIN32_FILE_ATTRIBUTE_DATA
  invoke GetFileAttributesEx, __strFileName, GetFileExInfoStandard, addr @wfad
  .if eax == FALSE
     mov @dwResult, FALSE
     invoke MessageBox, _hWnd, offset strFileAttrErr, offset strCapErr, MSG_BTN_STYLE_ERR
     jmp EXIT_ParseFeFile
  .endif
  
  ;;File Size
  invoke RtlZeroMemory, addr @strMsg, TEMP_BUFF_SIZE
  mov edx, @wfad.nFileSizeHigh
  mov eax, @wfad.nFileSizeLow
  lea ebx, @ullFileSize
  mov [ebx],     eax  ;;;低32位:低地址中存放低32位;
  mov [ebx + 4], edx  ;;;高32位:高地址中存放高32位;
  invoke wsprintf, addr @strMsg, offset strFileSize, @ullFileSize
  
  invoke GetDlgItem, _hWnd, IDC_STATIC_FILE_SIZE
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Create Time
  invoke FormatFileTime, addr @strMsg, TEMP_BUFF_SIZE, addr @wfad.ftCreationTime
  invoke GetDlgItem, _hWnd, IDC_STATIC_CTIME
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Modified Time
  invoke FormatFileTime, addr @strMsg, TEMP_BUFF_SIZE, addr @wfad.ftLastWriteTime
  invoke GetDlgItem, _hWnd, IDC_STATIC_MTIME
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Access Time
  invoke FormatFileTime, addr @strMsg, TEMP_BUFF_SIZE, addr @wfad.ftLastAccessTime
  invoke GetDlgItem, _hWnd, IDC_STATIC_ATIME
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;All Attributes
  invoke FormatFileAttr, addr @strMsg, TEMP_BUFF_SIZE, @wfad.dwFileAttributes
  invoke GetDlgItem, _hWnd, IDC_STATIC_ATTRS
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  invoke PE_Close
  xor eax, eax
  invoke PE_OpenEx, __strFileName, addr @dwResult, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, PAGE_READWRITE, FILE_MAP_READ or FILE_MAP_WRITE
  .if eax == FALSE
     invoke RtlZeroMemory, addr @strMsg, TEMP_BUFF_SIZE
     invoke wsprintf, addr @strMsg, offset strOpenPeFail, @dwResult
     mov @dwResult, FALSE
     invoke MessageBox, _hWnd, addr @strMsg, offset strCapErr, MSG_BTN_STYLE_ERR
     jmp EXIT_ParseFeFile
  .endif
  
  xor eax, eax
  invoke PE_Parse, addr @dwResult
  .if eax == FALSE
     invoke RtlZeroMemory, addr @strMsg, TEMP_BUFF_SIZE
     invoke wsprintf, addr @strMsg, offset strParsePeFail, @dwResult
     mov @dwResult, FALSE
     invoke MessageBox, _hWnd, addr @strMsg, offset strCapErr, MSG_BTN_STYLE_ERR
     invoke PE_Close
     jmp EXIT_ParseFeFile
  .endif
  
  ;;UDM_FILLFORM:通知父窗口,让父窗口通知其它子窗口,进行填充界面;
  invoke PostMessage, g_hWndMain, UDM_FILLFORM, 0, 0
  
  ;;UDM_CR_UPDATE:UDM_CR_UPDATE:notify the current window to read the copy right information of the PE file;
  invoke PostMessage, _hWnd, UDM_CR_UPDATE, 0, 0
  
  ;;通知父窗口,让其设置其标题栏的文本为当前程序文件名和正在解析的PE文件的路径名;
  invoke SendMessage, g_hWndMain, UDM_SETTITLETEXT, 0, __strFileName
  
  EXIT_ParseFeFile:
  popad
  mov eax, @dwResult
  ret
_ParseFeFile endp

_ShowDefaultCopyRight proc NEAR32 STDCALL PRIVATE
  local @stSysTime:SYSTEMTIME
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  
  pushad
  ;;SoftName:
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_NAME
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefSoftName
  
  ;;Get System Time
  invoke RtlZeroMemory, addr @stSysTime, sizeof SYSTEMTIME
  invoke GetSystemTime, addr @stSysTime
  
  ;;Version:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, @stSysTime.wYear
  xor ebx, ebx
  mov bx, @stSysTime.wMonth
  xor edx, edx
  mov dx, @stSysTime.wDay
  invoke wsprintf, addr @strMsg, offset strFmtVersion, eax, ebx, edx
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_VERSION
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Author:
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_AUTHOR
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefAuthor
  
  ;;Email:
  invoke GetDlgItem, _hWnd, IDC_STATIC_EMAIL
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefEmail
  popad
  mov eax, TRUE
  ret
_ShowDefaultCopyRight endp

_ShowCopyRight proc NEAR32 STDCALL PRIVATE
  local @dwRet:DWORD, @dwSignLength:DWORD, @dwSignBase:DWORD
  local @dwStrLen:DWORD ;;, @dwPointerToRawData:DWORD, @dwVirtualSize:DWORD
  local	@stSign:SSoftSign
  local	@stSoftName:SString
  local	@stAuthor:SString
  local	@stEmail:SString
  local @strBackUp:LPBYTE, @hHeap:HANDLE
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  mov @dwSignBase, 0
  ;mov @dwPointerToRawData, 0
  ;mov @dwVirtualSize, 0
  
  ;;查找可执行的代码段,并返回代码段的起始地址(FOA:PointerToRawData);
  xor eax, eax
  ;invoke GetSignSegment, CODE_SEG_RO, addr @dwSignBase, addr @dwPointerToRawData, addr @dwVirtualSize
  invoke GetSignSegment, CODE_SEG_RO, addr @dwSignBase, NULL, NULL
  .if (eax != 0)
     mov @dwRet, FALSE
     jmp EXIT_ShowCopyRight
  .endif
  
  xor esi, esi
  mov esi, @dwSignBase ;;;esi ---> SSoftSign: base of Soft Sign
  
  ;;Total length of SoftSign
  xor eax, eax
  mov al, BYTE PTR [esi + SSoftSign.bLength]
  .if eax == 0
     mov @dwRet, FALSE
     jmp EXIT_ShowCopyRight
  .endif
  mov @dwSignLength, eax
  
  ;;Get Process Heap
  mov @hHeap, NULL
  xor eax, eax
  invoke GetProcessHeap
  .if eax == NULL
     mov @dwRet, FALSE
     jmp EXIT_ShowCopyRight
  .endif
  mov @hHeap, eax
  
  ;;Alloc Memory
  mov @strBackUp, 0
  xor eax, eax
  invoke HeapAlloc, @hHeap, HEAP_ZERO_MEMORY, @dwSignLength
  .if eax == NULL
     mov @dwRet, FALSE
     jmp EXIT_ShowCopyRight
  .endif
  mov @strBackUp, eax
  
  ;;Backup all bytes of SoftSign
  invoke CopyMemory, @strBackUp, @dwSignBase, @dwSignLength ;;@dwSignLength return by eax;
  
  ;;Decrpty SoftSign
  xor ecx, ecx
  mov ecx, eax
  sub ecx, sizeof SSoftSign.bLength ;;length to decrpty
  
  xor esi, esi
  mov esi, @strBackUp
  add esi, sizeof SSoftSign.bLength ;;base address to decrpty
  invoke PE_Decrpty, esi, ecx, KEY_ENCRPTY
  
  invoke RtlZeroMemory, addr @stSign, sizeof SSoftSign
  invoke RtlZeroMemory, addr @stSoftName, sizeof SString
  invoke RtlZeroMemory, addr @stAuthor, sizeof SString
  invoke RtlZeroMemory, addr @stEmail, sizeof SString
  
  xor esi, esi
  mov esi, @strBackUp
  
  ;;;;Version:
  invoke CopyMemory, addr @stSign, esi, sizeof SSoftSign
  
  xor eax, eax
  mov ax, @stSign.wVersion1
  xor ebx, ebx
  mov bl, @stSign.bVersion2
  xor edx, edx
  mov dl, @stSign.bVersion3
  invoke wsprintf, addr @strMsg, offset strFmtVersion, eax, ebx, edx
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_VERSION
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;SoftName:
  add esi, sizeof SSoftSign ;;;esi ---> SoftName:SString
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stSoftName, esi, eax
  xor ebx, ebx
  lea ebx, @stSoftName
  add ebx, SString.strBuffer ;;pointer to SoftName-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_NAME
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;Author:
  add esi, sizeof SString.bLength
  add esi, @dwStrLen   ;;;esi -->Author:SString
  
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stAuthor, esi, eax
  xor ebx, ebx
  lea ebx, @stAuthor
  add ebx, SString.strBuffer ;;pointer to Author-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_STATIC_SOFT_AUTHOR
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;Email:
  add esi, sizeof SString.bLength
  add esi, @dwStrLen   ;;;esi -->Email:SString
  
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stEmail, esi, eax
  xor ebx, ebx
  lea ebx, @stEmail
  add ebx, SString.strBuffer ;;pointer to Author-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_STATIC_EMAIL
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;free the buffer
  invoke HeapAlloc, @hHeap, 0, @strBackUp
  
  mov @dwRet, TRUE
  
  EXIT_ShowCopyRight:
  .if @dwRet == FALSE
     invoke _ShowDefaultCopyRight
  .endif
  popad
  mov eax, @dwRet
  ret
_ShowCopyRight endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Message Handlers
_OnBtnOpenFile proc NEAR32 STDCALL PRIVATE
  local @dwResult:DWORD
  local @ofn:OPENFILENAME;
  local @strFileName[FILE_PATH_LEN]:TCHAR
  
  pushad
  invoke RtlZeroMemory, addr @strFileName, FILE_PATH_LEN
  invoke RtlZeroMemory, addr @ofn, sizeof OPENFILENAME
  
  mov @ofn.lStructSize, sizeof OPENFILENAME 
  mov @ofn.lpstrFilter, offset strFileFilter
  mov @ofn.nFilterIndex, 1
  lea eax, @strFileName
  mov @ofn.lpstrFile, eax
  mov @ofn.nMaxFile, FILE_PATH_LEN
  mov @ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_READONLY or OFN_HIDEREADONLY
  
  mov @dwResult, TRUE
  invoke GetOpenFileName, addr @ofn
  .if eax == FALSE
     mov @dwResult, FALSE
     jmp EXIT_OnBtnOpenFile
  .endif
  
  invoke _ParseFeFile, addr @strFileName
  ;;.if eax
  ;;   invoke _ShowCopyRight
  ;;.else
  ;;   invoke _ShowDefaultCopyRight
  ;;.endif
  
  EXIT_OnBtnOpenFile:
  popad
  mov eax, @dwResult
  ret
_OnBtnOpenFile endp

_OnParseCommandLine proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  invoke _ParseFeFile, __lParam
  popad
  mov eax, TRUE
  ret
_OnParseCommandLine endp

_OnUpdateCopyRight proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  invoke _ShowCopyRight
  popad
  mov eax, TRUE
  ret
_OnUpdateCopyRight endp

_OnDropFiles proc NEAR32 STDCALL PRIVATE __hDropFile:HDROP
  local @dwRet:DWORD
  local @strFileName[FILE_PATH_LEN]:TCHAR
  mov @dwRet, 0
  
  .if __hDropFile == NULL
     mov @dwRet, 1
     jmp EXIT_OnDropFiles1
  .endif
  
  pushad
  invoke DragQueryFile, __hDropFile, 0FFFFFFFFH, NULL, 0
  .if eax < 1
     mov @dwRet, 2
     jmp EXIT_OnDropFiles2
  .endif
  
  invoke RtlZeroMemory, addr @strFileName, sizeof @strFileName
  invoke DragQueryFile, __hDropFile, 0, addr @strFileName, sizeof @strFileName
  .if eax <= 0
     mov @dwRet, 3
     jmp EXIT_OnDropFiles2
  .endif
  
  invoke _ParseFeFile, addr @strFileName
  mov @dwRet, 0
  
  EXIT_OnDropFiles2:
  invoke DragFinish, __hDropFile
  popad
  
  EXIT_OnDropFiles1:
  mov eax, @dwRet
  ret
_OnDropFiles endp

;;Window Procedure
PeFileProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke DragAcceptFiles, __hWnd, TRUE
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_PARSECOMMANDLINE
     invoke _OnParseCommandLine, __wParam, __lParam
     mov @dwResult, TRUE
     ;设置消息处理结果的返回值为result,这个返回值会覆盖并作为SendMessage()的返回值被返回给消息的发送者;
     invoke SetWindowLong, __hWnd, DWL_MSGRESULT, @dwResult
  .elseif __uMsg == UDM_CR_UPDATE
     invoke _OnUpdateCopyRight, __wParam, __lParam
     mov @dwResult, TRUE
     invoke SetWindowLong, __hWnd, DWL_MSGRESULT, @dwResult
  .elseif __uMsg == WM_DROPFILES
     invoke _OnDropFiles, __wParam
     mov @dwResult, TRUE
  .elseif __uMsg == WM_COMMAND
     mov eax, __wParam
     and eax, 0000FFFFH
     ;;uiID = LOWORD(wParam);
     .if eax == IDC_BTN_OPEN_FILE
        invoke _OnBtnOpenFile
     .endif
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
PeFileProc endp

END