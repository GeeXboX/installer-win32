#------------------------------------------------------------------------------------------#
# Project settings
SetCompressor /SOLID /FINAL lzma
Name "GeeXboX"
OutFile "GeeXboX Installer for Windows.exe"
!define VERSION "0.2"
!define VERSIONTYPE " beta"
Caption "GeeXboX Installer for Windows ${VERSION}${VERSIONTYPE}"
UninstallCaption "GeeXboX Uninstaller for Windows ${VERSION}${VERSIONTYPE}"
BrandingText "GeeXboX - Linux Open Media Center"
ShowInstDetails show
ShowUninstDetails nevershow
RequestExecutionLevel admin

!define MULTIUSER_EXECUTIONLEVEL Admin
!define MULTIUSER_INIT_TEXT_ADMINREQUIRED "You must run this installer as administrator!"

!include MultiUser.nsh
!include FileFunc.nsh
!include TextFunc.nsh
!include WordFunc.nsh
!include MUI2.nsh

!insertmacro DriveSpace
!insertmacro GetDrives
!insertmacro GetSize
!insertmacro DirState
!insertmacro FileJoin

!insertmacro LineRead
!insertmacro LineSum
!insertmacro WordReplace
!insertmacro WordFind2X

#------------------------------------------------------------------------------------------#
# Used constants and variables
!define GrubSize 250
Var /GLOBAL InstType
Var /GLOBAL MultiBootInst
Var /GLOBAL DedicatedInst
Var /GLOBAL WinVer
Var /GLOBAL msg
Var /GLOBAL TempFolder
Var /GLOBAL DriveNumber
Var /GLOBAL Iso
Var /GLOBAL DriveListBox
Var /GLOBAL DriveLabel
Var /GLOBAL RegBootDir
Var /GLOBAL GeexboxSize
Var /GLOBAL DefaultOS
Var /GLOBAL TimeOut
Var /GLOBAL TimeOutValue
Var /GLOBAL TimeOutBU
Var /GLOBAL BootDrive
Var /GLOBAL DefaultOSFlag
Var /GLOBAL DefaultOSBU
Var /GLOBAL NoGrub
Var /GLOBAL NoGrubFlag
Var /GLOBAL BootDevice
Var /GLOBAL VistaID
Var /GLOBAL Dialog
Var /GLOBAL IsoPath
Var /GLOBAL BrowseButton
Var /GLOBAL ProcessButton
Var /GLOBAL IsoStatusBox
Var /GLOBAL IsoStatusText
Var /GLOBAL Processing

#------------------------------------------------------------------------------------------#
# UI setting
!define MUI_ICON geexbox.ico
!define MUI_UNICON geexbox.ico
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "logo.bmp"
!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_TEXT "Your installation is not yet complete !$\n$\nAre you sure you want to quit GeeXboX installation ?"
!define MUI_ABORTWARNING_CANCEL_DEFAULT
!define MUI_CUSTOMFUNCTION_ABORT CleanUp

# Welcome Page Setting
!define MUI_WELCOMEFINISHPAGE_BITMAP "side.bmp"
!define MUI_WELCOMEPAGE_TITLE "Welcome to the GeeXboX installation wizard"
!define MUI_WELCOMEPAGE_TEXT  "$\n$\nThis wizard will guide you through the installation of GeeXboX from distributed or generated iso to your hard disk or USB disk.$\n$\n$\n\
Please read the GUI messages on upcoming pages carefully as you proceed through the installation process.$\n$\n$\n"

# License Page Setting
!define MUI_TEXT_LICENSE_TITLE "Usage and License Information"
!define MUI_TEXT_LICENSE_SUBTITLE "Please read carefully before proceeding."
!define MUI_LICENSEPAGE_TEXT_TOP  "Press PageDown or use mouse wheel to view the rest of this information"
!define MUI_LICENSEPAGE_TEXT_BOTTOM "If you accept what you read, click the <I Agree> button below to proceed."

# Finish Page Setting
!define MUI_FINISHPAGE_TITLE "GeeXboX installation complete !"
!define MUI_FINISHPAGE_TEXT_LARGE
!define MUI_FINISHPAGE_TEXT "$\nGeeXboX has been succesfully installed to $BootDrive.$\n$\n$\n$\nFor more information on using GeeXboX, please click on the link underneath to visit GeeXboX homepage.$\n$\n$\n$\nThanks for using GeeXboX Installer for Windows."
!define MUI_FINISHPAGE_LINK "Visit GeeXboX homepage."
!define MUI_FINISHPAGE_LINK_LOCATION "http://www.geexbox.org/en/index.html"


#------------------------------------------------------------------------------------------#
# Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE license.txt

PageEx custom
  PageCallbacks SelectInstType SetInstType
PageExEnd

PageEx custom
  PageCallbacks SelectIso
PageExEnd

PageEx custom
  PageCallbacks InstConfig SetInstCfg
PageExEnd

!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_PAGE_FINISH

#------------------------------------------------------------------------------------------#
# Uninstall Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES


#------------------------------------------------------------------------------------------#
# Sections
Section "copy GeeXboX"
  Call CopyGeexbox
SectionEnd

Section "install grub4dos" InstGrubFlag
  Call InstGrub
SectionEnd

Section "write menu.lst" WriteLstFlag
  Call WriteGrubMenu
SectionEnd

Section "install syslinux" InstSyslinuxFlag
  Call InstSyslinux
SectionEnd

Section "write syslinux.cfg" WriteCfgFlag
  Call WriteSyslinuxCfg
SectionEnd

Section "write uninstall" WriteUninstFlag
  Call WriteUninstaller
SectionEnd

Section "Uninstall"
  Call un.Uninstaller
SectionEnd



#------------------------------------------------------------------------------------------#
# Functions

#--------------------------------------------#
# Installer init
Function .onInit

# Check user previledge
  !insertmacro MULTIUSER_INIT

# Check multiple instances
  System::Call /NOUNLOAD  'kernel32::CreateMutexA(i 0, i 0, t "myMutex") i .r1 ?e'
  Pop $R0
  ${If} $R0 != 0
    MessageBox MB_OK|MB_ICONEXCLAMATION "Another instance of this installer is already running!$\n$\nPress 'OK' to exit the installer."
    Abort
  ${Endif}

# Get Windows version
  ClearErrors
  ReadRegStr $WinVer HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  IfErrors 0 +2
  Strcpy $WinVer 0
  ${If} $WinVer >= 7  # beyond Vista
    MessageBox MB_OK|MB_ICONEXCLAMATION "The version of Windows you are running is currently not supported by this installer !$\n$\nPress 'OK' to exit the installer."
    Abort
  ${EndIf}

  Strcpy $TempFolder "$TEMP\GEEXins"
  Strcpy $Iso ""
  Strcpy $InstType 1

FunctionEnd


#--------------------------------------------#
# Uninstaller init
Function un.onInit

# Check user previledge
  !insertmacro MULTIUSER_UNINIT

# Check multiple instances
  System::Call /NOUNLOAD  'kernel32::CreateMutexA(i 0, i 0, t "myMutex") i .r1 ?e'
  Pop $R0
  ${If} $R0 != 0
    MessageBox MB_OK|MB_ICONEXCLAMATION "Another instance of this uninstaller is already running!$\n$\nPress 'OK' to exit the installer."
    Abort
  ${Endif}
FunctionEnd


#--------------------------------------------#
# Select installation type: Windows multi-boot or dedicated disk/partition
Function SelectInstType

  !insertmacro MUI_HEADER_TEXT "Select GeeXboX installation type" "Click on <Next> button to proceed."
# Create UI
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    RMDir /r /REBOOTOK $TempFolder
    Quit
  ${EndIf}

  ${NSD_CreateGroupBox} 7u 0u -13u -1u "Select the installation type you wish to use :"
  Pop $0
  ${NSD_CreateLabel} 22u 25u -39u 39u "    GeeXboX will be installed to Windows booting partition (FAT, FAT32 or NTFS) to multi-boot with Windows at next startup. A uninstaller will be saved, enabling you to uninstall GeeXboX cleanly and completely. Pre-existing multi-boot options, if any, in your Windows boot loader will not be affected by installation or uninstallation."
  Pop $0
  ${NSD_CreateRadioButton} 20u 10u -39u 13u "Install to Windows boot partition :"
  Pop $MultiBootInst
  ${NSD_CreateLabel} 22u 90u -39u 45u "    GeeXboX will be installed to a pre-formatted FAT or FAT32 (NTFS is not supported) hard disk partition, USB disk partition or USB disk without partitioning. Boot sector of target device will be written to and no uninstaller will be provided. Hard disk partition needs to be set as active to be bootable, otherwise you will need another bootloader to boot the partition."
  Pop $0
  ${NSD_CreateRadioButton} 20u 75u -39u 13u "Install to drive/partition dedicated to GeeXboX :"
  Pop $DedicatedInst
  ${If} $InstType == 1
    ${NSD_SetState} $MultiBootInst 1
  ${Else}
    ${NSD_SetState} $DedicatedInst 1   
  ${EndIf}
  nsDialogs::Show

FunctionEnd


#--------------------------------------------#
Function SetInstType

  ${NSD_GetState} $MultiBootInst $InstType	; 1, multi-boot; 0, dedicated;
  ${If} $InstType == 1
    SectionSetFlags ${InstGrubFlag} 1
    SectionSetFlags ${WriteLstFlag} 1
    SectionSetFlags ${InstSyslinuxFlag} 0
    SectionSetFlags ${WriteCfgFlag} 0
    SectionSetFlags ${WriteUninstFlag} 1
  ${Else}
    SectionSetFlags ${InstGrubFlag} 0
    SectionSetFlags ${WriteLstFlag} 0
    SectionSetFlags ${InstSyslinuxFlag} 1
    SectionSetFlags ${WriteCfgFlag} 1
    SectionSetFlags ${WriteUninstFlag} 0 
  ${EndIf}

FunctionEnd


#--------------------------------------------#
Function SelectIso

  !insertmacro MUI_HEADER_TEXT "Select source GeeXboX ISO" "Click on <Browse> button to select your GeeXboX ISO."

# Disable next button
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 0

# Create UI
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Call CleanUp
    Quit
  ${EndIf}

  ${NSD_CreateGroupBox} 7u 0u -13u 55u "Choose the GeeXboX ISO you wish to install :"
  Pop $0
  ${NSD_CreateFileRequest} 20u 16u -39u 13u "$Iso"
  Pop $IsoPath
  ${NSD_OnChange} $IsoPath CheckIsoExist

  ${NSD_CreateBrowseButton}  -70u 35u 50u 13u "Browse"
  Pop $BrowseButton
  ${NSD_OnClick} $BrowseButton BrowseIso

  ${NSD_CreateBrowseButton}  -140u 35u 50u 13u "Process"
  Pop $ProcessButton
  ${NSD_OnClick} $ProcessButton ProcessIso
  EnableWindow $ProcessButton 0

  Strcmp $Iso "" +2 0
    Call CheckIsoExist

  ${NSD_CreateGroupBox} 7u 60u -13u 75u "Processing selected ISO :"
  Pop $IsoStatusBox
  ShowWindow $IsoStatusBox ${SW_HIDE}

  ${NSD_CreateListBox} 20u 71u -39u 60u ""
  Pop $IsoStatusText
  ShowWindow $IsoStatusText ${SW_HIDE}

  nsDialogs::Show

FunctionEnd


#--------------------------------------------#
Function BrowseIso

  Pop $0
  nsDialogs::SelectFileDialog /NOUNLOAD open "" "GeeXboX ISO|geexbox*.iso"
  Pop $0
  Strcpy $1 $0 "" -4
  ${If} $1 == ".iso"
    ${NSD_SetText} $IsoPath $0
  ${EndIf}

FunctionEnd


#--------------------------------------------#
Function CheckIsoExist

# Check iso file existence
  ${NSD_GetText} $IsoPath $Iso
  ${If} $Iso != ""
    Strcpy $1 $Iso "" -4
    Strcmp $1 ".iso" 0 +4
    IfFileExists $Iso 0 +3
    EnableWindow $ProcessButton 1
    !insertmacro MUI_HEADER_TEXT "Processing source GeeXboX ISO" "Click on <Process> button to start processing your GeeXboX ISO."
    Nop
  ${EndIf}

FunctionEnd



#--------------------------------------------#
# Remove last string (if OPTYPE is 1) of list box LB and add MESSAGE
# Crude way to imitate a log window
!macro LBUpdate LB MESSAGE OPTYPE
  Strcmp ${OPTYPE} "1" 0 +5 
  SendMessage ${LB} ${LB_GETCOUNT} 0 0 $0
  Strcmp $0 "0" +3 0
    IntOp $0 $0 - 1
  SendMessage ${LB} ${LB_DELETESTRING} $0 0
  ${NSD_LB_AddString} ${LB} ${MESSAGE}
  System::Call /NOUNLOAD  'user32.dll::UpdateWindow(i $HWNDPARENT)'
!macroend


#--------------------------------------------#
Function ProcessIso

# Enable processing log windows

  ShowWindow $IsoStatusBox ${SW_SHOW}
  System::Call /NOUNLOAD  'user32.dll::UpdateWindow(i $HWNDPARENT)'
  ShowWindow $IsoStatusText ${SW_SHOW}
  System::Call /NOUNLOAD  'user32.dll::UpdateWindow(i $HWNDPARENT)'

lblchecktemp:

  Strcpy $Processing "Checking temporary install directory ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0
  IfFileExists "$TempFolder" lblcleartemp lblcreatetemp

lblcleartemp:
  Strcpy $Processing "$ProcessingExists."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Clearing pre-existing temporary install directory ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  ClearErrors
  IfFileExists "$TempFolder\*.*" 0 lbldeletetemp
    RMDir /r $TempFolder
    IfErrors 0 lblcreatetemp
      ${DirState} "$TempFolder" $0
      Strcmp $0 "0" lblextract lbltempfailure

lbldeletetemp:
  Delete "$TempFolder"
  IfErrors  0 lblcreatetemp

lbltempfailure:
    Strcpy $Processing "$ProcessingFailed!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Unable to clear temporary install directory !$\n$\nThere might be something wrong with your $TEMP.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblchecktemp IDCANCEL 0
    Call CleanUp
    Quit

lblcreatetemp:
  Strcpy $Processing "$ProcessingDone."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Creating temporary install directory ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  ClearErrors
  CreateDirectory $TempFolder
  IfErrors 0 lblextract
    Strcpy $Processing "$ProcessingFailed!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Unable to create temporary install directory !$\n$\nThere might be something wrong with your $TEMP.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblchecktemp IDCANCEL 0
    Call CleanUp
    Quit

lblextract:
  Strcpy $Processing "$ProcessingOK."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Extracting installation tools ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  SetOutpath $TempFolder
  ClearErrors
  File 7z.exe
  IfErrors lblextracterror 0
  ClearErrors
  File 7z.dll
  IfErrors lblextracterror 0
  ClearErrors
  File mkzftree.exe
  IfErrors lblextracterror lblextractiso

lblextracterror:
  Strcpy $Processing "$ProcessingERROR!"
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error extracting installation tools to temporary directory !$\n$\nThis installer could be corrupt or there might be something wrong with your $TEMP.$\n$\nPress 'OK' to to retry or 'Cancel' to exit the installer." IDOK +3 IDCANCEL 0
  Call CleanUp
  Quit
  Strcpy $Processing "Retry extracting installation tools ? "
  !insertmacro LBUpdate $IsoStatusText $Processing 0
  Goto lblextract  

lblextractiso:
  Strcpy $Processing "$ProcessingOK."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Extracting $Iso ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  nsExec::Exec '"$TempFolder\7z.exe" x $\"$Iso$\"'
  Pop $1
  ${If} $1 == "error"
    Strcpy $Processing "$ProcessingERROR!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error extacting $Iso !$\n$\nThe ISO could be corrupt or there might be something wrong with your $TEMP.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblextractisoretry IDCANCEL 0
    Call CleanUp
    Quit

lblextractisoretry:
  Strcpy $Processing "Retry extracting $Iso ? "
  !insertmacro LBUpdate $IsoStatusText $Processing 0
  RMDir /r "$TempFolder\GEEXBOX"
  RMDir /r "$TempFolder\[BOOT]"
  Goto lblextractiso 

  ${ElseIf} $1 == "timeout"
    Strcpy $Processing "$ProcessingTIMEOUT!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Extaction of $Iso timeout!$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblextractisoretry IDCANCEL 0
    Call CleanUp
    Quit
  ${EndIf}

lblcheckfiles:

  Strcpy $Processing "$ProcessingOK."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Checking GeeXboX file tree ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  IfFileExists "$TempFolder\GEEXBOX\*.tar.lzma" 0 lblmissingfile
  IfFileExists "$TempFolder\GEEXBOX\boot\vmlinuz" 0 lblmissingfile
  IfFileExists "$TempFolder\GEEXBOX\boot\initrd.gz" 0 lblmissingfile
  IfFileExists "$TempFolder\GEEXBOX\sbin\init" 0 lblmissingfile
  IfFileExists "$TempFolder\GEEXBOX\etc\mplayer\mplayer.conf" 0 lblmissingfile
  IfFileExists "$TempFolder\GEEXBOX\boot\isolinux.cfg" 0 lblmissingfile
  Goto lbldecompress

lblmissingfile:

  Strcpy $Processing "$ProcessingERROR! File missing!"
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "File missing from extracted GeeXboX file tree!$\n$\nThe ISO could be corrupt or there might be something wrong with your $TEMP.$\n$\nPress 'OK' to return and select another ISO or 'Cancel' to exit the installer." IDOK lblabort IDCANCEL 0
  Call CleanUp
  Quit

lblabort:
  Call CleanUp
  return


lbldecompress:
  Strcpy $Processing "$ProcessingOK."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  Strcpy $Processing "Decompressing GeeXboX file tree ..."
  !insertmacro LBUpdate $IsoStatusText $Processing 0

  IfFileExists "$TempFolder\install\*.*" 0 +2
    RMDir /r "$TempFolder\install"
  nsExec::Exec '"$TempFolder\mkzftree.exe" -u $\"$TempFolder\GEEXBOX$\" install'
  Pop $1
  ${If} $1 == "error"
    Strcpy $Processing "$ProcessingERROR!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error decompressing GeeXboX file tree !$\n$\nThe ISO could be corrupt or there might be something wrong with your $TEMP.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lbldecompressretry IDCANCEL 0
    Call CleanUp
    Quit

lbldecompressretry:
  Strcpy $Processing "Retry decompressing GeeXboX file tree ? "
  !insertmacro LBUpdate $IsoStatusText $Processing 0
  Goto lbldecompress

  ${ElseIf} $1 == "timeout"
    Strcpy $Processing "$ProcessingTIMEOUT!"
    !insertmacro LBUpdate $IsoStatusText $Processing 1
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Decompressing of GeeXboX file tree timeout!$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lbldecompressretry IDCANCEL 0
    Call CleanUp
    Quit
  ${EndIf}

  Strcpy $Processing "$ProcessingOK."
  !insertmacro LBUpdate $IsoStatusText $Processing 1
  !insertmacro MUI_HEADER_TEXT "GeeXboX ISO processing success" "Click on <Next> button to proceed."
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 1
  GetDlgItem $0 $HWNDPARENT 3
  EnableWindow $0 0

FunctionEnd


#--------------------------------------------#
Function InstConfig

  !insertmacro MUI_HEADER_TEXT "Configure GeeXboX Installation" "Click on <Install> button to start installation"

  ${GetSize} "$TempFolder\install" "/S=0K" $GeexboxSize $0 $1
  SectionSetSize "copy GeeXboX" $GeexboxSize
  Strcpy $BootDevice ""

  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog
  ${If} $Dialog == error
    Call CleanUp
    Quit
  ${EndIf}

  ${If} $InstType == 1
    ${NSD_CreateGroupBox} 7u 0u -13u 52u "Choose the drive you wish to install GeeXboX to:"
    Pop $0
    ${NSD_CreateDroplist} 20u 16u 30u 13u ""
  ${Else}
    ${NSD_CreateGroupBox} 7u 8u -10u 128u "Choose the drive you wish to install GeeXboX to:"
    Pop $0
    ${NSD_CreateDroplist} 35u 28u 110u 13u ""
  ${EndIf}
  Pop $DriveListBox
  ${NSD_OnChange} $DriveListBox DriveChange


lblretrygetdrive:
  Call LocateDrives
  Call CheckDriveNumber
  Strcmp $0 1 lblretrygetdrive

  ${If} $BootDevice == ""
    Strcpy $BootDevice "/dev/sda"
  ${EndIf}


  ${If} $InstType == 1
    ${NSD_CreateLabel} 70u 18u 220u 13u ""
    Pop $DriveLabel
    ${NSD_CreateLabel} 25u 35u 250u 13u "WARNING: Pre-existing \GEEXBOX on selected drive WILL BE OVERWRITTEN!"
    Pop $0
  ${Else}
    ${NSD_CreateLabel} 35u 46u 230u 13u ""
    Pop $DriveLabel
    ${NSD_CreateLabel} 25u 65u 250u 60u "WARNING:$\n$\n    Pre-existing \GEEXBOX on selected drive WILL BE OVERWRITTEN!$\n$\n    Boot sector of the selected drive/partition will be written to.$\n$\n    The boot sector operation is IRREVERSIBLE !"
    Pop $0
  ${EndIf}

  SendMessage $DriveListBox ${CB_SETCURSEL} 0 0
  Call DriveChange

  ${If} $InstType == 1

  ${NSD_CreateGroupBox} 7u 60u -13u 80u "Configuring Windows multi-boot menu :"
  Pop $0

  ${NSD_CreateLabel} 22u 76u 210u 13u "Install GeeXboX but skip boot-loader operations?"
  Pop $0

  ${NSD_CreateCheckBox} 240u 73u 30u 13u "Yes"
  Pop $NoGrub

  ${NSD_OnClick} $NoGrub NoGrubMB

  ${NSD_CreateLabel} 22u 97u 210u 13u "Do you want to make GeeXboX the default booting OS?"
  Pop $0

  ${NSD_CreateCheckBox} 240u 94u 30u 13u "Yes"
  Pop $DefaultOS

  ${NSD_CreateLabel} 22u 120u 210u 13u "Timeout value (in seconds) before booting default OS:"
  Pop $0

  ${NSD_CreateDroplist} 240u 117u 25u 13u ""
  Pop $TimeOut
  SendMessage $TimeOut ${CB_ADDSTRING} 0 "STR:5"
  SendMessage $TimeOut ${CB_ADDSTRING} 0 "STR:15"
  SendMessage $TimeOut ${CB_ADDSTRING} 0 "STR:30"
  SendMessage $TimeOut ${CB_SETCURSEL} 1 0

  ${Else}


  ${EndIf}
  nsDialogs::Show

FunctionEnd


#--------------------------------------------#
Function NoGrubMB

  ${NSD_GetState} $NoGrub $0
  Strcmp $0 1 0 lblgrubmb
  MessageBox MB_YESNO|MB_ICONEXCLAMATION "You have selected to install GeeXboX without installing the corresponding boot-loader.$\n$\nYou should only select this option when updating existing GeeXboX installed using this installer.$\n$\nPress 'YES' to confirm your selection or 'NO' to cancel." IDYES lblnogrubmb IDNO 0
  ${NSD_SetState} $NoGrub 0
  Return

lblnogrubmb:
  ${NSD_SetState} $DefaultOS 0
  EnableWindow $DefaultOS 0
  EnableWindow $TimeOut 0
  Return

lblgrubmb:
  EnableWindow $DefaultOS 1
  EnableWindow $TimeOut 1

FunctionEnd


#--------------------------------------------#
Function DriveChange

  SendMessage $DriveListBox ${CB_GETCURSEL} 0 0 $0
  System::Call /NOUNLOAD  'user32::SendMessage(i$DriveListBox, i${CB_GETLBTEXT}, ir0, t.r0)'
  Strcpy $0 $0 3
  IntOp $1 $GeexboxSize + ${GrubSize}
  ${DriveSpace} "$0" "/D=F /S=K" $0
  SendMessage $DriveLabel ${WM_SETTEXT} 0 "STR:Free space required: $1KB  Free space available: $0KB"
  ${If} $0 < $1
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 0
  ${Else}
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
  ${EndIf}

FunctionEnd


#--------------------------------------------#
Function SetInstCfg

  SendMessage $DriveListBox ${CB_GETCURSEL} 0 0 $0
  System::Call /NOUNLOAD  'user32::SendMessage(i$DriveListBox, i${CB_GETLBTEXT}, ir0, t.r0)'
  Strcpy $BootDrive $0 3

  Intcmp $InstType 1 +2 0
    Return

  ${NSD_GetState} $NoGrub $0
  Strcpy $NoGrubFlag $0

  ${NSD_GetState} $DefaultOS $0
  Strcpy $DefaultOSFlag $0

  SendMessage $TimeOut ${CB_GETCURSEL} 0 0 $0 
  System::Call /NOUNLOAD  'user32::SendMessage(i$TimeOut, i${CB_GETLBTEXT}, ir0, t.r0)'
  Strcpy $TimeOutValue $0

FunctionEnd



#--------------------------------------------#
# Get boot drive from registry or else get all drives with correct loader files
Function LocateDrives

  Strcpy $RegBootDir ""
  IntOp $DriveNumber 0 + 0
  ReadRegStr $RegBootDir HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Setup "BootDir"
  Strcmp $RegBootDir ""	lblgetdrive 0
    ${If} $InstType == 1
      Strcpy $9 $RegBootDir
      Call CheckDrive
      IntCmp $DriveNumber 1 0 lblgetdrive
      ${If} $WinVer >= 4		; guess disk number and partition number from registry. not guaranteed to be correct!
        Strcpy $1 ""
        ReadRegStr $1 HKLM SYSTEM\CurrentControlSet\Control "SystemBootDevice"
        ${If} $1 != ""
          ${WordFind2X} $1 "(" ")" "+2" $2	; disk
          ${WordFind2X} $1 "(" ")" "+3" $3	; rdisk
          ${WordFind2X} $1 "(" ")" "+4" $4	; partition
          IntOp $2 $2 + $3
          IntOp $2 $2 + 1
          Strcpy $3 "0abcdefghijklmnopqrstuvwxyz"
          Strcpy $2 $3 1 $2
          Strcpy $BootDevice "/dev/sd$2$4"
        ${EndIf}
      ${EndIf}
    Return
    ${EndIf}

lblgetdrive:
  ${If} $InstType == 1
    ${GetDrives} "HDD" "CheckDrive"
  ${Else}
    ${GetDrives} "FDD+HDD" "CheckDrive"
  ${EndIf}

FunctionEnd


#--------------------------------------------#
# Check drive validity according to installation type
Function CheckDrive

  IntOp $0 0 + 0		; validity flag

  ${If} $InstType == 1
# Detect boot loader presence according to windows version
    ${If} $WinVer >= 6 # Vista
      IfFileExists "$9bootmgr" 0 +2
        IntOp $0 1 + 0
    ${ElseIf} $WinVer >= 4 # NT/2000/XP
      IfFileExists "$9ntldr" 0 +4
      IfFileExists "$9NTDETECT.COM" 0 +3
      IfFileExists "$9boot.ini" 0 +2
        IntOp $0 1 + 0
    ${Else}  # 98/Me
      IfFileExists "$9MSDOS.SYS" 0 +3
      IfFileExists "$9IO.SYS" 0 +2
        IntOp $0 1 + 0
    ${EndIf}

  ${Else}
    ${If} $9 != $RegBootDir	; discard booting partition for dedicated install
    System::Call /NOUNLOAD 'kernel32::GetVolumeInformation(t r9, t .r1, i 1024, i .., i .., i .., t .r2, i 1024 ) i ..'
    Strcmp $2 "" lblgetdrive
    Strcmp $1 "" 0 +2
      Strcpy $1 "NoLabel"      
    Strcpy $3 $2 3
    Strcmp $3 "FAT" 0 +3
      IntOp $0 1 + 0
      Strcpy $9 "$9 ($1,$2)"
    ${EndIf}
  ${EndIf}

  ${If} $0 == 1
    IntOp $DriveNumber $DriveNumber + 1
    SendMessage $DriveListBox ${CB_ADDSTRING} 0 "STR:$9"
  ${Endif}

lblgetdrive:
  Strcpy $msg "KeepSearching"
  Push $msg

FunctionEnd


#--------------------------------------------#
Function CheckDriveNumber

  Strcpy $0 0
  ${If} $DriveNumber == 0
    ${If} $InstType == 1
      MessageBox MB_YESNO|MB_ICONEXCLAMATION "Unable to locate Windows boot loader on any hard drive(s) !$\n$\nYour Windows is booted in a way incompatible with this installer.$\n$\nPress 'YES' to redetect or 'NO' to exit the installer." IDYES lblretry IDNO 0
      Call CleanUp
      Quit
    ${Else}
      MessageBox MB_YESNO|MB_ICONEXCLAMATION "Unable to find any FAT/FAT32 drive(s) !$\n$\nPress 'YES' to redetect or 'NO' to exit the installer." IDYES lblretry IDNO 0
      Call CleanUp
      Quit
    ${Endif}
  ${Else}
    Return
  ${EndIf}

lblretry:
  Strcpy $0 1

FunctionEnd


#--------------------------------------------#
Function CopyGeexbox

  SetDetailsPrint none
  SetOutPath $BootDriveGEEXBOX
  SetDetailsPrint both
  DetailPrint "Installing GeeXboX to $BootDrive ..."
  DetailPrint "Checking source directory ..."
  IfFileExists "$TempFolder\install\*.*" lblchecktarget 0
  MessageBox MB_OK|MB_ICONEXCLAMATION "Decompressed GeeXboX files not found!$\r$\nThis is a fatal error and installation can not proceed.$\r$\nPress 'OK' to exit the installer."
  Call CleanUp
  Quit 

lblchecktarget:
  DetailPrint "Done"
  DetailPrint "Checking target directory ..."
  IfFileExists "$BootDriveGEEXBOX" lblcleartarget lblcreatetarget

lblcleartarget:
  DetailPrint "$BootDriveGEEXBOX exists."
  DetailPrint "Clearing $BootDriveGEEXBOX ..."
  SetDetailsPrint none

  IfFileExists "$BootDriveGEEXBOX\*.*" 0 lbldeletetarget
    ClearErrors
    RMDir /r $BootDriveGEEXBOX
    IfErrors 0 lblcreatetarget
      ${DirState} "$BootDriveGEEXBOX" $0
      Strcmp $0 "0" lblcopygeexbox lbltargetfailure

lbldeletetarget:
  ClearErrors
  Delete "$BootDriveGEEXBOX"
  IfErrors  0 lblcreatetarget

lbltargetfailure:
  SetDetailsPrint both
  DetailPrint "Clearing $BootDriveGEEXBOX Failed!"
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Unable to clear $BootDriveGEEXBOX !$\n$\nThere might be something wrong with your $BootDrive.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK 0 IDCANCEL +3
  DetailPrint "Retry selected."
  Goto lblchecktarget
  Call CleanUp
  Quit

lblcreatetarget:
  SetDetailsPrint both
  DetailPrint "Done"
  DetailPrint "Creating target directory ..."
  SetDetailsPrint none
  ClearErrors
  CreateDirectory $BootDriveGEEXBOX
  IfErrors 0 lblcopygeexbox
    DetailPrint "Failed!"
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Unable to create $BootDriveGEEXBOX !$\n$\nThere might be something wrong with your $BOOTDRIVE.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblchecktarget IDCANCEL 0
    Call CleanUp
    Quit

lblcopygeexbox:
  SetDetailsPrint both
  DetailPrint "Done"
  DetailPrint "Copying GeeXboX files ..."
  SetDetailsPrint none
  ClearErrors
  CopyFiles /SILENT "$TempFolder\install\*.*" "$BootDriveGEEXBOX\"
  SetDetailsPrint both
  IfErrors +4 0
    DetailPrint "Done"
    SetDetailsPrint none
    Return

    DetailPrint "Error!"
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error copying GeeXboX files to $BootDriveGEEXBOX !$\n$\nThere might be something wrong with your $BOOTDRIVE.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblchecktarget IDCANCEL 0
    Call CleanUpRoot
    Call CleanUp
    Quit

FunctionEnd

#--------------------------------------------#
# Install grub4dos according Windows version
Function InstGrub
  Intcmp $NoGrubFlag 0 +2 0
    Return
  SetDetailsPrint both
  DetailPrint "Copying Grub4DOS files ..."
  SetDetailsPrint none
  SetOutPath $BootDrive

lblcopygrub:
  ClearErrors
  ${If} $WinVer >= 6 # Vista
    File gxldr
    File gxldr.mbr
  ${ElseIf} $WinVer >= 4 # NT/2000/XP
    File gxldr
  ${Else}  # 98/Me
    File gxgrub.exe
  ${EndIf}
  IfErrors 0 lblinstgrub
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error copying Grub4DOS files to $BootDrive !$\n$\nThere might be something wrong with your $BOOTDRIVE.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblcopygrub IDCANCEL 0
    Call CleanUpRoot
    Call CleanUp
    Quit

lblinstgrub:
  SetDetailsPrint both
  DetailPrint "Done."
  DetailPrint "Configuring Windows multi-boot menu ..."
  SetDetailsPrint none
  ${If} $WinVer >= 6 # Vista
    Call InstGrubVista
  ${ElseIf} $WinVer >= 4 # NT/2000/XP
    Call InstGrubXP
  ${Else}  # 98/Me
    Call InstGrub98
  ${EndIf}
  SetDetailsPrint both
  DetailPrint "Done."

FunctionEnd

#--------------------------------------------#
Function InstGrubVista

lblbcdedit:
  Strcpy $VistaID ""
  nsExec::ExecToStack '"bcdedit" /enum {bootmgr} /v'
  Pop $1
  Pop $2
  Pop $0
  Pop $0
  Strcpy $0 $2 52
  Strcmp $0 "There are no matching objects or the store is empty." 0 +8
    nsExec::ExecToStack '"bcdedit" /enum {fwbootmgr} /v'
    Pop $1
    Pop $2
    Pop $0
    Pop $0
  Strcpy $0 $2 52
  Strcmp $2 "There are no matching objects or the store is empty." lblbcderror 0
  ${WordFind2X} $2 "default" "$\r$\n" "+1" $0
  ${WordReplace} $0 " " "" "+" $DefaultOSBU
  ${WordFind2X} $2 "timeout" "$\r$\n" "+1" $3
  ${WordReplace} $3 " " "" "+" $TimeOutBU
  Strcmp $TimeOutBU "" 0 +2
    Strcpy $TimeOutBU "0"
  nsExec::ExecToStack '"bcdedit" /create /d "GeeXboX" /application bootsector'
  Pop $1
  Pop $2
  Pop $0
  Pop $0
  IntCmp $1 0 lblbcdedit2 lblbcderror

lblbcderror:
  SetDetailsPrint both
  DetailPrint "$1;$2"
  SetDetailsPrint none
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "There was an error while installing GeeXboX boot options to Vista boot manager!$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblbcdedit IDCANCEL 0
  Call CleanUP
  Call CleanUpRoot
  Call CleanUpGrub
  Quit

lblbcdedit2:
  ${WordFind2X} $2 "{" "}" "-1" $VistaID
  Strcpy $VistaID "{$VistaID}"

  Strcpy $0 $BootDrive 2
  nsExec::Exec '"bcdedit" /set $VistaID device  partition=$0'
  nsExec::Exec '"bcdedit" /set $VistaID path \gxldr.mbr'
  nsExec::Exec '"bcdedit" /displayorder $VistaID /addlast' 
  nsExec::Exec '"bcdedit" /timeout $TimeOutValue'
  ${If} $DefaultOSFlag == 1
     nsExec::Exec '"bcdedit" /default $VistaID'
  ${EndIf}

FunctionEnd


#--------------------------------------------#
Function InstGrubXP

  SetFileAttributes "$BootDriveboot.ini" NORMAL
  WriteIniStr "$BootDriveboot.ini" "operating systems" "$BootDrivegxldr" '"GeeXboX"'
  ReadIniStr $TimeOutBU "$BootDriveboot.ini" "boot loader" "timeout"		; backup previous timeout
  Strcmp $TimeOutBU "" 0 +2
    Strcpy $TimeOutBU "0"
  WriteIniStr "$BootDriveboot.ini" "boot loader" "timeout" $TimeoutValue
  ReadIniStr $DefaultOSBU "$BootDriveboot.ini" "boot loader" "default"		; backup previous default os
  ${If} $DefaultOSFlag == 1
    WriteIniStr "$BootDriveboot.ini" "boot loader" "default" "$BootDrivegxldr"
  ${EndIf}
  SetFileAttributes "$BootDriveboot.ini" HIDDEN|SYSTEM|READONLY

FunctionEnd


#--------------------------------------------#
Function InstGrub98

  IfFileExists "$BootDriveconfig.sys" 0 lblnoconfig
    SetFileAttributes "$BootDriveconfig.sys" NORMAL
    ReadINIStr $1 "$BootDriveconfig.sys" "menu" "menuitem"
    Strcmp $1 "" 0 lblhasmenu
  Delete "$BootDrivegeexbox.sys"
  FlushINI "$BootDrivegeexbox.sys"
  Rename "$BootDriveconfig.sys" "$BootDrivegeexbox.sys"
  FlushINI "$BootDriveconfig.sys"
  FlushINI "$BootDrivegeexbox.sys"

lblnoconfig:
  FileOpen $0 "$BootDriveconfig.sys" w
  FileWrite $0 "REM The following part was written by GeeXboX installer for Windows"
  FileClose $0


  WriteIniStr "$BootDriveconfig.sys" "menu" "menucolor" "15,0"
  FlushINI "$BootDriveconfig.sys"
  WriteIniStr "$BootDriveconfig.sys" "menu" "menuitem" "Windows,Windows$\r$\n"
  FlushINI "$BootDriveconfig.sys"

lblhasmenu:
  WriteIniStr "$BootDriveconfig.sys" "menu" "submenu" "GeeXboX,GeeXboX"
  FlushINI "$BootDriveconfig.sys"
  WriteIniStr "$BootDriveconfig.sys" "GeeXboX" "menuitem" "GeeXboX1,GeeXboX"
  FlushINI "$BootDriveconfig.sys"
  ReadIniStr $DefaultOSBU "$BootDriveconfig.sys" "menu" "menudefault"
  ${If} $DefaultOSFlag == 1
    WriteIniStr "$BootDriveconfig.sys" "menu" "menudefault" "GeeXboX,$TimeOutValue"
    FlushINI "$BootDriveconfig.sys"
  ${EndIf}
  WriteIniStr "$BootDriveconfig.sys" "GeeXboX1" "device" "gxgrub.exe"
  FlushINI "$BootDriveconfig.sys"
  WriteIniStr "$BootDriveconfig.sys" "Windows" "REM just in case no previous windows entry" ""
  FlushINI "$BootDriveconfig.sys"
  Strcmp $1 "" 0 lblnomenu1
    WriteIniStr "$BootDriveconfig.sys" "Windows" "REM The Above part was written by GeeXboX installer for Windows" ""
    FlushINI "$BootDriveconfig.sys"
    ${FileJoin} "$BootDriveconfig.sys" "$BootDrivegeexbox.sys" ""
    FlushINI "$BootDriveconfig.sys"
    Delete /REBOOTOK "$BootDrivegeexbox.sys"
    FlushINI "$BootDrivegeexbox.sys"
lblnomenu1:
  SetFileAttributes "$BootDriveconfig.sys" HIDDEN|SYSTEM|READONLY

FunctionEnd


#--------------------------------------------#
Function WriteGrubMenu
  SetDetailsPrint both
  DetailPrint "Writing $BootDriveGEEXBOX\boot\menu.lst ..."
  SetDetailsPrint none
  IfFileExists $BootDriveGEEXBOX\boot\isolinux.cfg lblcfg 0
  MessageBox MB_OK|MB_ICONEXCLAMATION "$BootDriveGEEXBOX\boot\isolinux.cfg not found!$\r$\nThis is a fatal error and installation can not proceed.$\r$\nPress 'OK' to exit the installer."
  Call CleanUp
  Call CleanUpRoot
  Call CleanUpGrub
  Quit 

lblcfg:

  FileOpen $0 $BootDriveGEEXBOX\boot\menu.lst w
  FileWrite $0 "#This file was written by 'GeeXboX installer for Windows' for grub4dos boot loader.$\r$\n$\r$\n$\r$\n"
  FileWrite $0 "splashimage /GEEXBOX/usr/share/grub-splash.xpm.gz$\r$\ntimeout 15$\r$\ndefault 0$\r$\n$\r$\n$\r$\n"
  FileClose $0
  Call CFG2LST
  SetDetailsPrint both
  DetailPrint "Done."
  DetailPrint "Cleaning up temporary files ..."
  SetDetailsPrint none
  Call CleanUp
  SetDetailsPrint both
  DetailPrint "Done"
FunctionEnd


#--------------------------------------------#
Function CFG2LST

  FileOpen $R0 $BootDriveGEEXBOX\boot\menu.lst a
  FileSeek $R0 0 END

# Get command line
  Strcpy $0 0				; counter
  Strcpy $1 ""				; entry flag
  ${LineSum} "$BootDriveGEEXBOX\boot\isolinux.cfg" $R1

lblcfg2lstloop:
  IntOp $0 $0 + 1
  ${If} $0 > $R1
    FileWrite $R0 "title Return to Windows Boot Menu ...$\r$\n"
    FileWrite $R0 "chainloader +1$\r$\n"
    FileWrite $R0 "boot$\r$\n"
    FileClose $R0
    Return
  ${EndIf}
  ${LineRead} "$BootDriveGEEXBOX\boot\isolinux.cfg" "$0" $2
  Strcmp $2 "" lblcfg2lstloop
  Strcpy $3 $2 5
  Strcmp $3 "LABEL" 0 +3
    Strcpy $1 1
    Goto lblcfg2lstloop
  Strcmp $1 "" lblcfg2lstloop		; not in entry
  Strcpy $3 $2 8
  Strcmp $3 "  MENU L" 0 next		; create new entry
    Strcpy $3 $2 "" 13
    ${WordReplace} $3 "disk" "removable disk" "+" $4
    FileWrite $R0 "title $4$\r$\n"
    Goto lblcfg2lstloop
next:
  Strcmp $3 "  APPEND" 0 lblcfg2lstloop		; write new entry
    Strcpy $3 $2 "" 26
    ${WordReplace} $3 "boot=cdrom" "boot=$BootDevice" "+" $4
    FileWrite $R0 "kernel=/GEEXBOX/boot/vmlinuz $4 $\r$\ninitrd=/GEEXBOX/boot/initrd.gz$\r$\n$\r$\n"
    Strcpy $1 ""
    Goto lblcfg2lstloop

FunctionEnd


#--------------------------------------------#
Function InstSyslinux
  SetDetailsPrint both
  Strcpy $1 $BootDrive 2
  ${If} $WinVer >= 4 # NT/2000/XP
    DetailPrint "Installing Syslinux ..."
    SetDetailsPrint none
    SetOutPath $TempFolder

lblcopysyslinux:
    ClearErrors
    File syslinux.exe
    IfErrors 0 lblinstsyslinux
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error extracting Syslinux files !$\n$\nThe installer could be corrupt or there might be something wrong with your $TempFolder.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblcopysyslinux IDCANCEL 0
      Call CleanUpRoot
      Call CleanUp
      Quit

lblinstsyslinux:
    Delete "$BootDriveldlinux.sys"
    IfFileExists "$BootDriveldlinux.sys" 0 +5
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error deleting pre-existing Syslinux files !$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblinstsyslinux IDCANCEL 0
      Call CleanUpRoot
      Call CleanUp
      Quit

    nsExec::Exec '"$TempFolder\syslinux.exe" -f $1'
    Pop $0
    IfFileExists "$BootDriveldlinux.sys" 0 +2
      Strcpy $0 "0"
    ${If} $0 == "timeout"
      SetDetailsPrint both
      DetailPrint "Timeout!"
      SetDetailsPrint none
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Timeout installing Syslinux !$\n$\nPlease check your $BootDrive is correctly installed and writable.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblinstsyslinux IDCANCEL 0
      Call CleanUp
      Call CleanUpRoot
      Quit

    ${ElseIf} $0 == "error"
    ${OrIf} $0 != 0
      SetDetailsPrint both
      DetailPrint "Error!"
      SetDetailsPrint none
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error installing Syslinux !$\n$\nPlease check your $BootDrive is correctly installed and writable.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblinstsyslinux IDCANCEL 0
      Call CleanUp
      Call CleanUpRoot
      Quit
    ${EndIf}
    SetDetailsPrint both
    DetailPrint "Done."
    SetDetailsPrint none

  ${Else}				; syslinux seems to work improperly in 98/Me in certain cases. use grub4dos instead.
    DetailPrint "Installing Grub4DOS ..."
    SetDetailsPrint none
    SectionSetFlags ${WriteCfgFlag} 0
lblinstgrub1:
    nsExec::Exec '"sys.com" $1'
    Pop $0
    ${If} $0 == "timeout"
      SetDetailsPrint both
      DetailPrint "Timeout!"
      SetDetailsPrint none
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Timeout transferring system files to $BootDrive !$\n$\nPlease check your $BootDrive is correctly installed and writable.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblinstgrub1 IDCANCEL 0
      Call CleanUp
      Call CleanUpRoot
      Quit

    ${ElseIf} $0 == "error"
    ${OrIf} $0 != 0
      SetDetailsPrint both
      DetailPrint "Error!"
      SetDetailsPrint none
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Error transferring system files to $BootDrive !$\n$\nPlease check your $BootDrive is correctly installed and writable.$\n$\nPress 'OK' to retry or 'Cancel' to exit the installer." IDOK lblinstgrub1 IDCANCEL 0
      Call CleanUp
      Call CleanUpRoot
      Quit
    ${EndIf}    
    SetOutPath $BootDrive
    File gxgrub.exe
    IfFileExists "$BootDriveconfig.sys" 0 +2
      Rename "$BootDriveconfig.sys" "$BootDriveconfig.bak"
    FileOpen $0 "$BootDriveconfig.sys" w
    FileWrite $0 "#This file was written by 'GeeXboX installer for Windows' for grub4dos boot loader.$\r$\n$device=gxgrub.exe$\r$\n"
    FileClose $0
    SetDetailsPrint both
    DetailPrint "Done."
    SetDetailsPrint none
    Call WriteGrubMenu

  ${EndIf}

FunctionEnd


#--------------------------------------------#
Function WriteSyslinuxCfg

  SetDetailsPrint both
  DetailPrint "Writing $BootDrivesyslinux.cfg ..."
  SetDetailsPrint none
  IfFileExists $BootDriveGEEXBOX\boot\isolinux.cfg lblwritecfg 0
  MessageBox MB_OK|MB_ICONEXCLAMATION "$BootDriveGEEXBOX\boot\isolinux.cfg not found!$\r$\nThis is a fatal error and installation can not proceed.$\r$\nPress 'OK' to exit the installer."
  Call CleanUp
  Call CleanUpRoot
  Call CleanUpGrub
  Quit 

lblwritecfg:

  FileOpen $0 $BootDrivesyslinux.cfg w
  FileWrite $0 "#This file was written by 'GeeXboX installer for Windows' for Syslinux boot loader.$\r$\n$\r$\n$\r$\n"
  Strcpy $1 0				; counter
  ${LineSum} "$BootDriveGEEXBOX\boot\isolinux.cfg" $R1

lblwritecfgloop:
  IntOp $1 $1 + 1
  ${If} $1 <= $R1
    ${LineRead} "$BootDriveGEEXBOX\boot\isolinux.cfg" "$1" $2
    ${WordReplace} $2 "boot=cdrom" "boot=$BootDevice" "+" $3
    ${WordReplace} $3 "#CFG#" "" "+" $2
    ${WordReplace} $2 "vesamenu.c32" "/GEEXBOX/boot/vesamenu.c32" "+" $3
    ${WordReplace} $3 "splash.png" "/GEEXBOX/boot/splash.png" "+" $2
    ${WordReplace} $2 "vmlinuz" "/GEEXBOX/boot/vmlinuz" "+" $3
    ${WordReplace} $3 "initrd.gz" "/GEEXBOX/boot/initrd.gz" "+" $2
    FileWrite $0 "$2$\r$\n"
    Goto lblwritecfgloop
  ${EndIf}

  SetDetailsPrint both
  DetailPrint "Done."
  DetailPrint "Cleaning up temporary files ..."
  SetDetailsPrint none
  Call CleanUp
  SetDetailsPrint both
  DetailPrint "Done"
  SetRebootFlag false

FunctionEnd



#--------------------------------------------#
Function WriteUninstaller

  SetDetailsPrint none
  SetOutPath $BootDriveGEEXBOX
  ${If} $NoGrubFlag == 0
  SetDetailsPrint both
  DetailPrint "Saving uninstall information to registry ..."
  SetDetailsPrint none
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "DisplayName" "GeeXboX - Linux Open Media Centre"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "UninstallString" "$BootDriveGEEXBOX\uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "NoRepair" 1
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "drive" "$BootDrive"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "windows" "$Winver"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "default" $DefaultOSFlag
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "timeout" $TimeOutBU
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "defaultOS" "$DefaultOSBU"
  ${If} $WinVer >= 6
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "vista" "$VistaID"
  ${EndIf}
  ${EndIf}
  SetDetailsPrint both
  DetailPrint "Writing uninstaller ..."
  SetDetailsPrint none
  WriteUninstaller $BootDriveGEEXBOX\uninstall.exe
  SetDetailsPrint both
  DetailPrint "Done."

FunctionEnd



#--------------------------------------------#
Function un.Uninstaller

  SetDetailsPrint none
  MessageBox MB_YESNO|MB_ICONEXCLAMATION "GeeXboX and related boot-loader files will be deleted !$\n$\nAre you sure ?" IDYES +2 IDNO 0
  Quit
  ReadRegStr $BootDrive HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "drive"
  Strcmp $BootDrive "" lblunquit
  IfFileExists "$BootDriveGEEXBOX\*.*" +3 0
  MessageBox MB_OK|MB_ICONEXCLAMATION "It appears that GeeXboX was not installed using your current Windows system !$\n$\nUninstallation will now abort."
  Quit
  ReadRegStr $WinVer HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "windows"
  Strcmp $WinVer "" lblunquit
  ReadRegDWORD $DefaultOSFlag HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "default"
  ReadRegStr $DefaultOSBU HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "defaultOS"
  Strcmp $DefaultOSFlag "" lblunquit
  ReadRegStr $TimeOutBU HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "timeout"
  Strcmp $TimeOutBU "" lblunquit
  ${If} $WinVer >= 6
    ReadRegStr $VistaID HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX" "vista"
    ${If} $VistaID == ""
      Goto lblunquit
    ${EndIf}
  ${EndIf}
  Goto lbluninstall

lblunquit:
  MessageBox MB_OK|MB_ICONEXCLAMATION "Uninstall information missing or corrupt !$\n$\nUninstallation will now abort."
  Quit

lbluninstall:

  RMDir /r /REBOOTOK $BootDriveGEEXBOX

  ${If} $WinVer >= 6 # Vista
    Delete /REBOOTOK $BootDrivegxldr
    Delete /REBOOTOK $BootDrivegxldr.mbr
    nsExec::Exec '"bcdedit" /timeout $TimeOutBU'
    nsExec::Exec '"bcdedit" /delete $VistaID'
    ${If} $DefaultOSFlag == 1
      nsExec::Exec '"bcdedit" /default $DefaultOSBU'
    ${EndIf}
  ${ElseIf} $WinVer >= 4 # NT/2000/XP
    Delete /REBOOTOK $BootDrivegxldr
    SetFileAttributes "$BootDriveboot.ini" NORMAL
    DeleteIniStr "$BootDriveboot.ini" "operating systems" "$BootDrivegxldr"
    WriteIniStr "$BootDriveboot.ini" "boot loader" "timeout" $TimeOutBU
    ${If} $DefaultOSFlag == 1
      WriteIniStr "$BootDriveboot.ini" "boot loader" "default" $DefaultOSBU
    ${EndIf}
    SetFileAttributes "$BootDriveboot.ini" HIDDEN|SYSTEM|READONLY
  ${Else}  # 98/Me
    Delete /REBOOTOK $BootDrivegxgrub.exe
    SetFileAttributes "$BootDriveconfig.sys" NORMAL
    DeleteIniStr "$BootDriveconfig.sys" "menu" "submenu"
    FlushINI "$BootDriveconfig.sys"
    DeleteIniSec "$BootDriveconfig.sys" "GeeXboX"
    FlushINI "$BootDriveconfig.sys"
    DeleteIniSec "$BootDriveconfig.sys" "GeeXboX1"
    FlushINI "$BootDriveconfig.sys"
      ${If} $DefaultOSFlag == 1
        WriteIniStr "$BootDriveconfig.sys" "menu" "menudefault" $DefaultOSBU
        FlushINI "$BootDriveconfig.sys"
      ${EndIf} 
    SetFileAttributes "$BootDriveconfig.sys" HIDDEN|SYSTEM|READONLY
  ${EndIf}
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GEEXBOX"

  MessageBox MB_OK|MB_ICONEXCLAMATION "Uninstall is now complete !$\n$\nSome files in $BootDrive and $BootDriveGEEXBOX may have not been deleted yet, but will be deleted on next Windows boot.$\n$\nPress 'OK' to exit uninstaller."
  Quit

FunctionEnd




#--------------------------------------------#
Function CleanUp
  SetDetailsPrint none
  RMDir /r /REBOOTOK $TempFolder
  SetDetailsPrint both
FunctionEnd

Function CleanUpRoot
  SetDetailsPrint none
  RMDir /r /REBOOTOK $BootDriveGEEXBOX
  SetDetailsPrint both
FunctionEnd

Function CleanUpGrub
  SetDetailsPrint none
  ${If} $NoGrubFlag == 0
  ${If} $WinVer >= 6 # Vista
    Delete /REBOOTOK $BootDrivegxldr
    Delete /REBOOTOK $BootDrivegxldr.mbr
  ${ElseIf} $WinVer >= 4 # NT/2000/XP
    Delete /REBOOTOK $BootDrivegxldr
  ${Else}  # 98/Me
    Delete /REBOOTOK $BootDrivegxgrub.exe
  ${EndIf}
  ${EndIf}
  SetDetailsPrint both
FunctionEnd



#--------------------------------------------#
!insertmacro MUI_LANGUAGE "English"
