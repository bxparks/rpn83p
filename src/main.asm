;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; The main entry point and exit routines.
;------------------------------------------------------------------------------

main:
    call setIsRtcAvailable
    call setFastSpeed
    bcall(_SaveOSState)
    bcall(_RunIndicOff)
    res appAutoScroll, (iy + appFlags) ; disable auto scroll
    res appTextSave, (iy + appFlags) ; disable shawdow text
    res lwrCaseActive, (iy + appLwrCaseFlag) ; disable ALPHA-ALPHA lowercase
    bcall(_ClrLCDFull)

    bcall(_RestoreAppState)
    jr nc, initAlways
    ; Initialize everything if RestoreAppState() fails.
    bcall(_ColdInitErrorCode)
    bcall(_ColdInitInputBuf)
    bcall(_ColdInitDate)
    bcall(_ColdInitRtc)
    bcall(_ColdInitMenu)
    bcall(_ColdInitBase)
    bcall(_ColdInitComplex)
    bcall(_ColdInitModes)
    call coldInitStat
    call initCfit
    call initTvm
initAlways:
    ; If RestoreAppState() suceeds, only the following are initialized.
    bcall(_InitArgBuf) ; Start with command ArgScanner off.
    bcall(_SanitizeMenu) ; Sanitize currentMenuGroupId currentMenuRowIndex
    call updateNumResultMode
    call updateComplexMode
    call initStack
    call initRegs
    call initStatRegs
    call initLastX ; Always copy TI-OS 'ANS' to 'X'
    call initDisplay ; Always initialize the display.
    call initTvmSolver ; Always init TVM solver

    ; Initialize the App monitor so that we can intercept the Put Away (2ND
    ; OFF) signal.
    ld hl, appVectors
    bcall(_AppInit)

    ; Jump into the main keyboard input parsing loop.
    jp processMainCommands

;------------------------------------------------------------------------------

; Clean up and exit app.
;   - Called explicitly upon 2ND QUIT.
;   - Called by TI-OS application monitor upon 2ND OFF.
; See the TI-83 Plus SDK reference for PutAway().
mainExit:
    ; Save appState and close various appVars.
    call storeAns
    call closeStack
    call closeRegs
    call closeStatRegs
    bcall(_StoreAppState)

    ; Clean up the screen.
    set appAutoScroll, (iy + appFlags)
    ld (iy + textFlags), 0 ; reset text flags
    bcall(_ClrLCDFull)
    bcall(_HomeUp)

    ; Restore various OS states, and terminate the app.
    bcall(_RestoreOSState)
    bcall(_ReloadAppEntryVecs) ; App Loader in control of monitor
    bit monAbandon, (iy + monFlags) ; if turning off: ZF=1
    jr nz, appTurningOff
    ; If not turning off, then force control back to the home screen.
    ; Note: this will terminate the link activity that caused the application
    ; to be terminated.
    ld a, iAll ; all interrupts on
    out (intrptEnPort), a
    bcall(_LCD_DRIVERON) ; turn on the LCD
    set onRunning, (iy + onFlags) ; on interrupt running
    ei ; enable interrupts
    bjump(_JForceCmdNoChar) ; force to home screen
appTurningOff:
    bjump(_PutAway) ; force App locader to do its put away

; Description: Store OP1 to Ans, but only if OP1 is Real or Complex.
storeAns:
    call rclX ; OP1=X
    call checkOp1RealOrComplex ; ZF=1 if real or complex
    ret nz
    bcall(_StoAns) ; transfer to TI-OS 'ANS' (supports complex numbers)
    ret

; Set up the AppVectors so that we can intercept the Put Away Notification upon
; '2ND QUIT' or '2ND OFF'. See TI-83 Plus SDK documentation.
appVectors:
    .dw dummyVector
    .dw dummyVector
    .dw mainExit
    .dw dummyVector
    .dw dummyVector
    .dw dummyVector
    .db appTextSaveF

dummyVector:
    ret

;------------------------------------------------------------------------------

; Description: Determine the value of 'isRtcAvailable' flag. As far as I know
; right now, the RTC chip exists on the:
;   - TI-84+
;   - TI-84+SE
;   - TI-84+ Pocket SE
;   - TI-84 Pocket.fr (?)
;
; The RTC does NOT exist on the:
;   - TI-83+
;   - TI-83+SE
;
; There is an OS function named NZIf83Plus() (see the TI 83 Plus SDK, or
; https://wikiti.brandonw.net/index.php?title=83Plus:BCALLs:50E0), but
; NZIf83Plus() returns Z for the 83+SE as well, which does NOT have an RTC. So
; we have to go lower level. The GetSysInfo() returns a number of status bytes
; at the location pointed by HL, Byte 2 is what we want. It contains the
; hardwareVersion: 0 is 83+, 1 is 83+SE, 2 is 84+, 3 is 84+SE
; (https://wikiti.brandonw.net/index.php?title=83Plus:BCALLs:50DD). For for
; this routine, we want hardwareVersion>=2.
;
; Another tricky thing is that GetSysInfo() exists only for OS ver >= 1.13, so
; we have to check that before we can call it. If the OS is < 1.13, I guess we
; will have to assume that the RTC does NOT exist.
setIsRtcAvailable:
    call checkOS113 ; CF=0 if OS>=1.13
    jr c, setIsRtcAvailableFalse
    ld hl, OP1
    bcall(_GetSysInfo) ; HL[2]=hardware revision; HL[3][4]=isTI83plus
    ld a, (OP1+2) ; A=hardwareVersion (0=83+,1=83+SE,2=84+,3=84+SE)
    cp 2 ; CF=1 if 83+,83+SE
    jr c, setIsRtcAvailableFalse
setIsRtcAvailableTrue:
    ld a, 1
    ld (isRtcAvailable), a
    ret
setIsRtcAvailableFalse:
    xor a
    ld (isRtcAvailable), a
    ret

; Description: Set CPU speed to 15 MHz on supported hardware (83+SE, 84+,
; 84+SE) on OS 1.13 or higher. See TI-83 Plus SDK reference for SetExSpeed().
setFastSpeed:
    call checkOS113 ; CF=0 if OS>=1.13
    ret c
    ld a, $ff
    bcall(_SetExSpeed)
    ret

; Description: Check if OS is >= 1.13.
; Output: CF=0 if OS >= 1.13; 1 otherwise
checkOS113:
    bcall(_GetBaseVer) ; OS version in A (major), B (minor)
    cp 1 ; CF=1 if major < 1; CF=0 and ZF=0 if major > 1
    ret nz ; returns if major >= 2 or < 1
    ld a, b
    cp 13 ; CF=0 if minor version > 13, otherwise CF=1
    ret
