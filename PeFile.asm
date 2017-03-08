;;PeFile.asm: Access the PE file;
;;

;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include PeFile.inc

PUBLIC g_strFileName, g_hFile, g_hMapFile, g_lpvBase, g_strBase
PUBLIC g_lpDosHdr, g_lpNtHdr , g_lpFilHdr, g_lpOptHdr, g_lpDatDir, g_lpBlkTbl
PUBLIC g_lpExpBlk, g_lpImpBlk, g_lpResBlk, g_lpRlcBlk, g_lpDbgBlk, g_lpTlsBlk, g_lpIatBlk
PUBLIC g_lpExpTbl, g_lpImpTbl, g_lpResTbl, g_lpRlcTbl, g_lpDbgTbl, g_lpTlsTbl, g_lpIatTbl

.const
   strFmtFile        db '%s', 0
   ;;;MachineString
   strMachineI386    db 'I386', 0
   strMachineIA64    db 'IA64', 0
   strMachineARM     db 'ARM', 0
   strMachineTHUMB   db 'ARM Thumb', 0
   strMachineALPHA   db 'ALPHA', 0
   strMachineALPHA64 db 'ALPHA64', 0
   strMachinePOWERPC db 'POWERPC', 0
   strMachineOTHER   db 'Other', 0
   ;;;Subsystem
   strSubSysUNK      db 'Unknown', 0
   strSubSysNATIVE   db 'No Need Subsystem', 0
   strSubSysW32GUI   db 'Win32 GUI', 0
   strSubSysW64GUI   db 'Win64 GUI', 0
   strSubSysROMGUI   db 'ROM GUI', 0
   strSubSysWINGUI   db 'Windows GUI', 0
   strSubSysW32CUI   db 'Win32 CUI', 0
   strSubSysW64CUI   db 'Win64 CUI', 0
   strSubSysROMCUI   db 'ROM CUI', 0
   strSubSysWINCUI   db 'Windows CUI', 0
   strSubSysOS2CUI   db 'OS2 CUI', 0
   strSubSysPSXCUI   db 'Posix CUI', 0
   strSubSysW9XDRV   db 'Win9X Driver', 0
   strSubSysWCEGUI   db 'Windows CE GUI', 0
   strSubSysOTHER    db 'Other', 0
   ;;;File Type
   strFileDLL        db 'DLL', 0
   strFileEXE        db 'EXE', 0
   strFileSYS        db 'SYS', 0
   strFileUNK        db 'UNK', 0

.data?
   g_strFileName TCHAR FILE_PATH_LEN dup(?)
   g_hFile    HANDLE ?
   g_hMapFile HANDLE ?
   g_lpvBase  LPVOID ?
   g_strBase  LPBYTE ?
   g_lpDosHdr PIMAGE_DOS_HEADER         ? ;;;DOS Header
   g_lpNtHdr  PIMAGE_NT_HEADERS         ? ;;;NT Header
   g_lpFilHdr PIMAGE_FILE_HEADER        ? ;;;File Header
   g_lpOptHdr PIMAGE_OPTIONAL_HEADER    ? ;;;Optional Header
   g_lpDatDir PIMAGE_DATA_DIRECTORY     ? ;;;Data Directory
   g_lpBlkTbl PIMAGE_SECTION_HEADER     ? ;;;Section Table
   g_lpExpBlk PIMAGE_DATA_DIRECTORY     ? ;;;Export Block(VirtualAddress && Size)
   g_lpExpTbl PIMAGE_EXPORT_DIRECTORY   ? ;;;Export Directory(FOA)
   g_lpImpBlk PIMAGE_DATA_DIRECTORY     ? ;;;Import Block(VirtualAddress && Size)
   g_lpImpTbl PIMAGE_IMPORT_DESCRIPTOR  ? ;;;Import Directory(FOA)
   g_lpResBlk PIMAGE_DATA_DIRECTORY     ? ;;;Resource Directory(VirtualAddress && Size)
   g_lpResTbl PIMAGE_RESOURCE_DIRECTORY ? ;;;Resource Directory(FOA)
   g_lpRlcBlk PIMAGE_DATA_DIRECTORY     ? ;;;Base Relocation Block(VirtualAddress && Size)
   g_lpRlcTbl PIMAGE_BASE_RELOCATION    ? ;;;Base Relocation Table(FOA)
   g_lpDbgBlk PIMAGE_DATA_DIRECTORY     ? ;;;Debug Block(VirtualAddress && Size)
   g_lpDbgTbl PIMAGE_DEBUG_DIRECTORY    ? ;;;Debug Directory(FOA)
   g_lpTlsBlk PIMAGE_DATA_DIRECTORY     ? ;;;TLS Block(VirtualAddress && Size)
   g_lpTlsTbl PIMAGE_TLS_DIRECTORY      ? ;;;TLS Directory(FOA)
   g_lpIatBlk PIMAGE_DATA_DIRECTORY     ? ;;;Import Address Table Block(VirtualAddress && Size)
   g_lpIatTbl PIMAGE_THUNK_DATA         ? ;;;Import Address Table(FOA)
   DATA_SEG_END db ?

.code
PE_SetFileName proc NEAR32 STDCALL PRIVATE __strFileName:LPCTSTR
  local @dwLen:DWORD
  
  .if __strFileName == 0
      mov @dwLen, 0
      jmp ERR_SetFileName1
  .endif
  
  pushad
  
  xor eax, eax
  invoke lstrlen, __strFileName
  .if eax == 0
      mov @dwLen, 0
      jmp ERR_SetFileName2
  .endif
  
  mov @dwLen, eax
  invoke RtlZeroMemory, offset g_strFileName, FILE_PATH_LEN
  ;;invoke _strncpy, offset g_strFileName, __strFileName, @dwLen
  invoke wsprintf, offset g_strFileName, offset strFmtFile, __strFileName
  mov @dwLen, eax
  
  ERR_SetFileName2:
  popad
  
  ERR_SetFileName1:
  mov eax, @dwLen
  ret
PE_SetFileName endp

PE_Open proc NEAR32 STDCALL PUBLIC __strFileName:LPCTSTR, __dwDesiredAccess:DWORD, __dwShareMode:DWORD
  local @dwRet:DWORD
  mov @dwRet, TRUE
  
  pushad
  xor eax, eax
  invoke PE_SetFileName, __strFileName
  .if eax == 0
      mov @dwRet, FALSE
      jmp ERR_Open
  .endif
  
  ;;Open File
  invoke CreateFile, offset g_strFileName, __dwDesiredAccess, __dwShareMode, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL
  .if ((eax == INVALID_HANDLE_VALUE) || (eax == NULL))
      mov @dwRet, FALSE
      jmp ERR_Open   ;;Open file failed
  .endif
  
  mov g_hFile, eax
  mov @dwRet, TRUE   ;;Open file ok
  
  ERR_Open:
  popad
  mov eax, @dwRet
  ret
PE_Open endp

PE_MapFile proc NEAR32 STDCALL PUBLIC __dwMapProtect:DWORD
  local @dwRet:DWORD
  mov @dwRet, TRUE
  
  .if ((g_hFile == INVALID_HANDLE_VALUE) || (g_hFile == NULL))
      mov @dwRet, FALSE
      jmp ERR_MapFile1
  .endif
  
  pushad
  xor eax, eax
  
  ;;Mapping the file into memory
  invoke CreateFileMapping, g_hFile, NULL, __dwMapProtect, 0, 0, NULL
  .if eax == NULL
      mov @dwRet, FALSE
      jmp ERR_MapFile2
  .endif
  
  mov g_hMapFile, eax
  mov @dwRet, TRUE
  
  ERR_MapFile2:
  popad
  
  ERR_MapFile1:
  mov eax, @dwRet
  ret
PE_MapFile endp

PE_MapFileView proc NEAR32 STDCALL PUBLIC __dwDesiredViewAccess:DWORD, __dwNumberOfBytesToMap:DWORD
  local @dwRet:DWORD
  mov @dwRet, TRUE
  
  .if g_hMapFile == NULL
      mov @dwRet, FALSE
      jmp ERR_MapFileView1
  .endif
  
  pushad
  xor eax, eax
  
  ;;Mapping the view of the file into the address space of the calling process;
  invoke MapViewOfFile, g_hMapFile, __dwDesiredViewAccess, 0, 0, __dwNumberOfBytesToMap
  .if eax == NULL
      mov @dwRet, FALSE
      jmp ERR_MapFileView2
  .endif
  
  mov g_lpvBase, eax
  mov g_strBase, eax
  mov @dwRet, TRUE
  
  ERR_MapFileView2:
  popad
  
  ERR_MapFileView1:
  mov eax, @dwRet
  ret
PE_MapFileView endp

PE_UnMapFileView proc NEAR32 STDCALL PUBLIC
  local @dwRet:DWORD
  mov @dwRet, TRUE
  
  .if g_lpvBase == NULL
      mov @dwRet, FALSE
      jmp ERR_UnMapFileView1
  .endif
  
  pushad
  xor eax, eax
  
  invoke UnmapViewOfFile, g_lpvBase
  .if eax == FALSE
      mov @dwRet, FALSE
      jmp ERR_UnMapFileView2
  .endif
  
  mov g_lpvBase, NULL
  mov g_strBase, NULL
  mov @dwRet, TRUE
  
  ERR_UnMapFileView2:
  popad
  
  ERR_UnMapFileView1:
  mov eax, @dwRet
  ret
PE_UnMapFileView endp

PE_OpenEx proc NEAR32 STDCALL PUBLIC __strFileName:LPCTSTR, __lpResult:LPDWORD, __dwDesiredAccess:DWORD, __dwShareMode:DWORD, __dwMapProtect:DWORD, __dwDesiredViewAccess:DWORD
  local @dwRet:DWORD
  mov @dwRet, TRUE
  
  pushad
  xor eax, eax
  
  invoke PE_SetFileName, __strFileName
  .if eax == 0
      mov [__lpResult], 1
      mov @dwRet, FALSE
      jmp ERR_OpenEx
  .endif
  
  ;Open File
  invoke CreateFile, offset g_strFileName, __dwDesiredAccess, __dwShareMode, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL
  .if (eax == INVALID_HANDLE_VALUE) || (eax == NULL)
      mov [__lpResult], 2
      mov @dwRet, FALSE
      jmp ERR_OpenEx
  .endif
  mov g_hFile, eax
  
  ;Mapping the file into memory
  xor eax, eax
  invoke CreateFileMapping, g_hFile, NULL, __dwMapProtect, 0, 0, NULL
  .if eax == NULL
      invoke CloseHandle, g_hFile
      mov g_hFile, NULL
      mov [__lpResult], 3
      mov @dwRet, FALSE
      jmp ERR_OpenEx
  .endif
  mov g_hMapFile, eax
  
  ;Mapping the view of the file into the address space of the calling process;
  xor eax, eax
  invoke MapViewOfFile, g_hMapFile, __dwDesiredViewAccess, 0, 0, 0
  .if eax == NULL
      invoke CloseHandle, g_hMapFile
      mov g_hMapFile, NULL
      invoke CloseHandle, g_hFile
      mov g_hFile, NULL
      mov [__lpResult], 4
      mov @dwRet, FALSE
      jmp ERR_OpenEx
  .endif
  mov g_lpvBase, eax
  mov g_strBase, eax
  
  mov [__lpResult], 0
  mov @dwRet, TRUE
  
  ERR_OpenEx:
  popad
  mov eax, @dwRet
  ret
PE_OpenEx endp

PE_Close proc NEAR32 STDCALL PUBLIC
   pushad
  ;Unmap all mapped views of the file-mapping object
  .if g_lpvBase != NULL
      invoke UnmapViewOfFile, g_lpvBase
      mov g_lpvBase, NULL
      mov g_strBase, NULL
  .endif
  
  ;Close the file-mapping object handle
  .if g_hMapFile != NULL
      invoke CloseHandle, g_hMapFile
      mov g_hMapFile, NULL;
  .endif
  
  ;Close the object handle of the file
  .if ((g_hFile != INVALID_HANDLE_VALUE) && (g_hFile != NULL))
      invoke CloseHandle, g_hFile
      mov g_hFile, NULL
  .endif
  popad
  mov eax, TRUE
  ret
PE_Close endp

PE_GetMachineString proc NEAR32 STDCALL PUBLIC __machine:DWORD
  local @strName:DWORD
  mov @strName, 0
  pushad
  .if __machine == IMAGE_FILE_MACHINE_I386
      mov @strName, offset strMachineI386
  .elseif __machine == IMAGE_FILE_MACHINE_IA64
      mov @strName, offset strMachineIA64
  .elseif __machine == IMAGE_FILE_MACHINE_ARM
      mov @strName, offset strMachineARM
  .elseif __machine == IMAGE_FILE_MACHINE_THUMB
      mov @strName, offset strMachineTHUMB
  .elseif __machine == IMAGE_FILE_MACHINE_ALPHA
      mov @strName, offset strMachineALPHA
  .elseif __machine == IMAGE_FILE_MACHINE_ALPHA64
      mov @strName, offset strMachineALPHA64
  .elseif __machine == IMAGE_FILE_MACHINE_POWERPC
      mov @strName, offset strMachinePOWERPC
  .else
      mov @strName, offset strMachineOTHER
  .endif
  popad
  mov eax, @strName
  ret
PE_GetMachineString endp

PE_GetSubsystemString proc NEAR32 STDCALL PUBLIC __subsystem:DWORD, __magic:DWORD
  local @strSubSys:DWORD
  mov @strSubSys, 0
  pushad
  .if __subsystem == IMAGE_SUBSYSTEM_UNKNOWN
      mov @strSubSys, offset strSubSysUNK
  .elseif __subsystem == IMAGE_SUBSYSTEM_NATIVE
      mov @strSubSys, offset strSubSysNATIVE
  .elseif __subsystem == IMAGE_SUBSYSTEM_WINDOWS_GUI
      .if __magic == IMAGE_NT_OPTIONAL_HDR32_MAGIC
          mov @strSubSys, offset strSubSysW32GUI
      .elseif __magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC
          mov @strSubSys, offset strSubSysW64GUI
      .elseif __magic == IMAGE_ROM_OPTIONAL_HDR_MAGIC
          mov @strSubSys, offset strSubSysROMGUI
      .else
          mov @strSubSys, offset strSubSysWINGUI
      .endif
  .elseif __subsystem == IMAGE_SUBSYSTEM_WINDOWS_CUI
      .if __magic == IMAGE_NT_OPTIONAL_HDR32_MAGIC
          mov @strSubSys, offset strSubSysW32CUI
      .elseif __magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC 
          mov @strSubSys, offset strSubSysW64CUI
      .elseif __magic == IMAGE_ROM_OPTIONAL_HDR_MAGIC
          mov @strSubSys, offset strSubSysROMCUI
      .else
          mov @strSubSys, offset strSubSysWINCUI
      .endif
  .elseif __subsystem == IMAGE_SUBSYSTEM_OS2_CUI
      mov @strSubSys, offset strSubSysOS2CUI
  .elseif __subsystem == IMAGE_SUBSYSTEM_POSIX_CUI
      mov @strSubSys, offset strSubSysPSXCUI
  .elseif __subsystem == IMAGE_SUBSYSTEM_NATIVE_WINDOWS
      mov @strSubSys, offset strSubSysW9XDRV
  .elseif __subsystem == IMAGE_SUBSYSTEM_WINDOWS_CE_GUI
      mov @strSubSys, offset strSubSysWCEGUI
  .else
      mov @strSubSys, offset strSubSysOTHER
  .endif
  popad
  mov eax, @strSubSys
  ret
PE_GetSubsystemString endp

PE_GetSectionProperty proc NEAR32 STDCALL PUBLIC __strBuf:LPSTR, __dwBufSize:DWORD, __dwCharacteristic:DWORD
  local @dwRet:DWORD
  mov @dwRet, 0
  
  pushad
  invoke RtlZeroMemory, __strBuf, __dwBufSize
  xor ebx, ebx
  mov ebx, __strBuf
  xor eax, eax
  .if (__dwCharacteristic & IMAGE_SCN_MEM_READ)
      mov BYTE ptr [ebx + eax], 'R' ;82 ;'R': 52h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_MEM_WRITE)
      mov BYTE ptr [ebx + eax], 'W' ;87 ;'W': 57h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_MEM_EXECUTE)
      mov BYTE ptr [ebx + eax], 'E' ;69 ;'E': 45h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_MEM_SHARED)
      mov BYTE ptr [ebx + eax], 'S' ;83 ;'S': 53h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_MEM_DISCARDABLE)
      mov BYTE ptr [ebx + eax], 'D' ;68 ;'D': 44h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_CNT_CODE)
      mov BYTE ptr [ebx + eax], 'C' ;67 ;'C': 43h
      inc eax
  .endif
  
  .if (__dwCharacteristic & IMAGE_SCN_CNT_INITIALIZED_DATA)
      mov BYTE ptr [ebx + eax], 'I' ;73 ;'I': 49h
      inc eax
  .endif
  
  .if(__dwCharacteristic & IMAGE_SCN_CNT_UNINITIALIZED_DATA)
      mov BYTE ptr [ebx + ebx], 'U' ;85 ;'U': 55h
      inc ebx
  .endif
  mov @dwRet, eax
  popad
  mov eax, @dwRet
  ret
PE_GetSectionProperty endp

PE_GetFileType proc NEAR32 STDCALL PUBLIC __dwCharacteristics:DWORD
  local @strFileType:DWORD
  mov @strFileType, 0
  pushad
  .if __dwCharacteristics & IMAGE_FILE_DLL
      mov @strFileType, offset strFileDLL
  .elseif __dwCharacteristics & IMAGE_FILE_RELOCS_STRIPPED
      mov @strFileType, offset strFileEXE
  .elseif __dwCharacteristics & IMAGE_FILE_SYSTEM
      mov @strFileType, offset strFileSYS
  .else
      mov @strFileType, offset strFileUNK
  .endif
  popad
  mov eax, @strFileType
  ret
PE_GetFileType endp

PE_Encrpty proc NEAR32 STDCALL PUBLIC __lpStart:LPBYTE, __dwLength:DWORD, __dwKey:DWORD
  pushad
  
  xor esi, esi
  mov esi, __lpStart
  
  xor ax, ax
  xor cx, cx
  xor ebx, ebx
  
  .while ebx < __dwLength
     mov al, BYTE PTR [esi + ebx] ;;copy byte
     mov ah, al
     mov cl, 4
     shr ah, cl ;;ah = ah >> 4; bit[7:4] --> bit[3:0]
     mov cl, 4
     shl al, cl ;;al = al << 4; bin[3:0] --> bit[7:4]
     or  al, ah ;;al = al | ah
     mov BYTE PTR [esi + ebx], al ;;write back byte
     inc ebx
  .endw
  
  popad
  mov eax, __dwLength
  ret
PE_Encrpty endp

PE_Decrpty proc NEAR32 STDCALL PUBLIC __lpStart:LPBYTE, __dwLength:DWORD, __dwKey:DWORD
  pushad
  
  xor esi, esi
  mov esi, __lpStart
  
  xor ax, ax
  xor cx, cx
  xor ebx, ebx
  
  .while ebx < __dwLength
     mov al, BYTE PTR [esi + ebx] ;;copy byte
     mov ah, al
     mov cl, 4
     shr ah, cl ;;ah = ah >> 4; bit[7:4] --> bit[3:0]
     mov cl, 4
     shl al, cl ;;al = al << 4; bin[3:0] --> bit[7:4]
     or  al, ah ;;al = al | ah
     mov BYTE PTR [esi + ebx], al ;;write back byte
     inc ebx
  .endw
  
  popad
  mov eax, __dwLength
  ret
PE_Decrpty endp

PE_Rva2Foa proc NEAR32 STDCALL PUBLIC __dwRva:DWORD
  local @wCount:WORD
  local @dwFoa:DWORD, @dwBegin:DWORD, @dwEnd:DWORD;
  
  .if ((g_lpBlkTbl == NULL) || (g_lpFilHdr == NULL))
      mov @dwFoa, 0
      jmp ERR_PE_Rva2Foa
  .endif
  
  mov @wCount,  0
  mov @dwFoa,   0
  mov @dwBegin, 0
  mov @dwEnd,   0
  
  pushad
  xor esi, esi
  mov esi, g_lpFilHdr    ;;; esi ---> IMAGE_FILE_HEADER
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSections]
  mov @wCount, ax        ;;;节的数量
  
  xor esi, esi
  mov esi, g_lpBlkTbl    ;;;节表基址
  
  push ecx
  xor ecx, ecx
  .while cx < @wCount
     ;;;current section
     mov edx, [esi + IMAGE_SECTION_HEADER.VirtualAddress]
     mov @dwBegin, edx
     add edx, [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
     mov @dwEnd, edx
     
     mov eax, __dwRva
     .if ((eax >= @dwBegin) && (eax <= @dwEnd))
         sub eax, [esi + IMAGE_SECTION_HEADER.VirtualAddress]    ;;; (__dwRva - lpSection->VirtualAddress)
         add eax, [esi + IMAGE_SECTION_HEADER.PointerToRawData]  ;;; + lpSection->PointerToRawData
         mov @dwFoa, eax
         .break
     .endif
     
     ;next
     inc cx                                ;;;next Index
     add esi, sizeof IMAGE_SECTION_HEADER  ;;;next SECTION
  .endw
  pop ecx
  popad
  
  ERR_PE_Rva2Foa:
  mov eax, @dwFoa
  ret
PE_Rva2Foa endp

PE_Foa2Rva proc NEAR32 STDCALL PUBLIC __dwFoa:DWORD
  local @wCount:WORD
  local @dwRva:DWORD, @dwBegin:DWORD, @dwEnd:DWORD;
  
  .if ((g_lpBlkTbl == NULL) || (g_lpFilHdr == NULL))
      mov @dwRva, 0
      jmp ERR_PE_Foa2Rva
  .endif
  
  mov @wCount,  0
  mov @dwRva,   0
  mov @dwBegin, 0
  mov @dwEnd,   0
  
  pushad
  xor esi, esi
  mov esi, g_lpFilHdr    ;;; esi ---> IMAGE_FILE_HEADER
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSections]
  mov @wCount, ax        ;;;节的数量
  
  xor esi, esi
  mov esi, g_lpBlkTbl    ;;;节表基址
  
  push ecx
  xor ecx, ecx
  .while cx < @wCount
     ;;;current section
     mov edx, [esi + IMAGE_SECTION_HEADER.PointerToRawData]
     mov @dwBegin, edx
     add edx, [esi + IMAGE_SECTION_HEADER.SizeOfRawData]
     mov @dwEnd, edx
     
     mov eax, __dwFoa
     .if ((eax >= @dwBegin) && (eax <= @dwEnd))
         sub eax, [esi + IMAGE_SECTION_HEADER.PointerToRawData]  ;;; (__dwFoa - lpSection->PointerToRawData)
         add eax, [esi + IMAGE_SECTION_HEADER.VirtualAddress]    ;;; + lpSection->VirtualAddress
         mov @dwRva, eax
         .break
     .endif
     
     ;next
     inc cx                                ;;;next Index
     add esi, sizeof IMAGE_SECTION_HEADER  ;;;next SECTION
  .endw
  pop ecx
  popad
  
  ERR_PE_Foa2Rva:
  mov eax, @dwRva
  ret
PE_Foa2Rva endp

PE_Parse proc NEAR32 STDCALL PUBLIC __lpdwResult:LPDWORD
  local @lpDosHdr:PIMAGE_DOS_HEADER
  local @lpNtHdr :PIMAGE_NT_HEADERS
  local @dwRet:DWORD
  
  mov @dwRet, TRUE
  mov [__lpdwResult], 0
  pushad
  
  .if (g_strBase == NULL)
      mov [__lpdwResult], 1
      mov @dwRet, FALSE
      jmp ERR_PE_Parse
  .endif
  
  xor esi, esi
  ;check DOS Header
  mov esi, g_strBase
  .if [esi + IMAGE_DOS_HEADER.e_magic] != IMAGE_DOS_SIGNATURE  ;Invalid DOS header
      mov [__lpdwResult], 2
      mov @dwRet, FALSE
      jmp ERR_PE_Parse
  .endif
  
  ;check NT Header
  add esi, [esi + IMAGE_DOS_HEADER.e_lfanew]
  .if [esi + IMAGE_NT_HEADERS.Signature] != IMAGE_NT_SIGNATURE ;Invalid NT header
      mov [__lpdwResult], 3
      mov @dwRet, FALSE
      jmp ERR_PE_Parse
  .endif
  
  xor esi, esi
  mov esi, g_strBase
  ;DOS Header
  mov g_lpDosHdr, esi
  
  ;NT Header
  add esi, [esi + IMAGE_DOS_HEADER.e_lfanew]
  mov g_lpNtHdr, esi
  
  ;File Header
  mov edx, esi
  add edx, sizeof IMAGE_NT_HEADERS.Signature
  mov g_lpFilHdr, edx
  
  ;Optional Header
  add edx, sizeof IMAGE_NT_HEADERS.FileHeader
  mov g_lpOptHdr, edx
  
  ;Data Directory
  xor ebx, ebx
  mov bl, IMAGE_NUMBEROF_DIRECTORY_ENTRIES ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_NUMBEROF_DIRECTORY_ENTRIES
  
  xor ebx, ebx
  mov ebx, sizeof IMAGE_OPTIONAL_HEADER
  sub ebx, eax                             ;BX = sizeof(IMAGE_OPTIONAL_HEADER) - (sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_NUMBEROF_DIRECTORY_ENTRIES)
  add edx, ebx
  mov g_lpDatDir, edx
  
  ;Section Table
  add esi, sizeof IMAGE_NT_HEADERS
  mov g_lpBlkTbl, esi
  
  ;;;;;;;;;;Export Directory;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_EXPORT     ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_EXPORT
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpExpBlk, ebx                      ;g_lpExpBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_EXPORT
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpExpTbl, eax                      ;g_lpExpTbl = EAX
  
  ;;;;;;;;;;Import Directory;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_IMPORT     ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_IMPORT
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpImpBlk, ebx                      ;g_lpImpBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_IMPORT
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpImpTbl, eax                      ;g_lpImpTbl = EAX
  
  ;;;;;;;;;;Resource Directory;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_RESOURCE   ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_RESOURCE
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpResBlk, ebx                      ;g_lpResBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_RESOURCE
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpResTbl, eax                      ;g_lpResTbl = EAX
  
  ;;;;;;;;;;Base Relocation Table;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_BASERELOC  ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_BASERELOC
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpRlcBlk, ebx                      ;g_lpRlcBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_BASERELOC
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpRlcTbl, eax                      ;g_lpRlcTbl = EAX
  
  ;;;;;;;;;;Debug Directory;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_DEBUG      ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_DEBUG
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpDbgBlk, ebx                      ;g_lpDbgBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_DEBUG
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpDbgTbl, eax                      ;g_lpDbgTbl = EAX
  
  ;;;;;;;;;;TLS Directory;;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_TLS        ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_TLS
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpTlsBlk, ebx                      ;g_lpTlsBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_TLS
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpTlsTbl, eax                      ;g_lpTlsTbl = EAX
  
  ;;;;;;;;;;Import Address Table (IAT);;;;;;;;;;
  xor ebx, ebx
  mov bl, IMAGE_DIRECTORY_ENTRY_IAT        ;BL: 乘数
  xor eax, eax
  mov al, sizeof IMAGE_DATA_DIRECTORY      ;AL: 被乘数
  mul bl                                   ;AX= 被乘数*乘数 = AL*BL = sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_IAT
  xor ebx, ebx
  mov ebx, g_lpDatDir                      ;EBX: 被加数
  add ebx, eax                             ;EAX: 加数
  mov g_lpIatBlk, ebx                      ;g_lpIatBlk = EBX + EAX = g_lpDatDir + EAX = g_lpDatDir + sizeof(IMAGE_DATA_DIRECTORY)*IMAGE_DIRECTORY_ENTRY_IAT
  invoke PE_Rva2Foa, [ebx + IMAGE_DATA_DIRECTORY.VirtualAddress]
  add eax, g_strBase                       ;EAX = g_strBase + FOA
  mov g_lpIatTbl, eax                      ;g_lpIatTbl = EAX
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;;OK
  mov [__lpdwResult], 0
  mov @dwRet, TRUE
  
  ERR_PE_Parse:
  popad
  mov eax, @dwRet
  ret
PE_Parse endp

AcquirePeFile proc NEAR32 STDCALL PUBLIC
  pushad
  invoke RtlZeroMemory, offset g_strFileName, offset DATA_SEG_END - offset g_strFileName
  
  ;mov g_hFile,    0
  ;mov g_hMapFile, 0
  ;mov g_lpvBase,  0
  ;mov g_strBase,  0
  ;mov g_lpDosHdr, 0 ;;;DOS Header
  ;mov g_lpNtHdr,  0 ;;;NT Header
  ;mov g_lpFilHdr, 0 ;;;File Header
  ;mov g_lpOptHdr, 0 ;;;Optional Header
  ;mov g_lpDatDir, 0 ;;;Data Directory
  ;mov g_lpBlkTbl, 0 ;;;Section Table
  ;mov g_lpExpBlk, 0 ;;;Export Block(VirtualAddress && Size)
  ;mov g_lpExpTbl, 0 ;;;Export Directory(FOA)
  ;mov g_lpImpBlk, 0 ;;;Import Block(VirtualAddress && Size)
  ;mov g_lpImpTbl, 0 ;;;Import Directory(FOA)
  ;mov g_lpResBlk, 0 ;;;Resource Directory(VirtualAddress && Size)
  ;mov g_lpResTbl, 0 ;;;Resource Directory(FOA)
  ;mov g_lpRlcBlk, 0 ;;;Base Relocation Block(VirtualAddress && Size)
  ;mov g_lpRlcTbl, 0 ;;;Base Relocation Table(FOA)
  ;mov g_lpDbgBlk, 0 ;;;Debug Block(VirtualAddress && Size)
  ;mov g_lpDbgTbl, 0 ;;;Debug Directory(FOA)
  ;mov g_lpTlsBlk, 0 ;;;TLS Block(VirtualAddress && Size)
  ;mov g_lpTlsTbl, 0 ;;;TLS Directory(FOA)
  ;mov g_lpIatBlk, 0 ;;;Import Address Table Block(VirtualAddress && Size)
  ;mov g_lpIatTbl, 0 ;;;Import Address Table(FOA)
  ;g_lpPeFile = NULL;
  ;this = NULL;
  ;this = (struct SPeFile*)malloc(sizeof(struct SPeFile));
  ;if(NULL == this)
  ;{
  ;  return (struct SPeFile*)NULL;
  ;}
  ;
  ;ZeroMemory(this, sizeof(struct SPeFile));
  ;
  ;this->Open    = PE_Open;
  ;this->OpenEx  = PE_OpenEx;
  ;this->MapFile = PE_MapFile;
  ;this->MapFileView   = PE_MapFileView;
  ;this->UnMapFileView = PE_UnMapFileView;
  ;this->Close = PE_Close;
  ;
  ;this->Rva2Foa = PE_Rva2Foa;
  ;this->Foa2Rva = PE_Foa2Rva;
  ;this->Parse   = PE_Parse;
  ;
  ;this->GetMachineString   = PE_GetMachineString;
  ;this->GetSubsystemString = PE_GetSubsystemString;
  ;this->GetSectionProperty = PE_GetSectionProperty;
  ;this->Encrpty = PE_Encrpty;
  ;this->Decrpty = PE_Decrpty;
  ;
  ;g_lpPeFile = this;
  ;return this;
  popad
  mov eax, TRUE
  ret
AcquirePeFile endp

ReleasePeFile proc NEAR32 STDCALL PUBLIC
  pushad
  ;if(this)
  ;{
  ;  free(this);
  ;  this = NULL;
  ;  g_lpPeFile = NULL;
  ;}
  popad
  mov eax, TRUE
  ret
ReleasePeFile endp

END