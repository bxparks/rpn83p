;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; The main entry point and exit routines.
;------------------------------------------------------------------------------

main:
    call setFastSpeed
    bcall(_RunIndicOff)
    res appAutoScroll, (iy + appFlags) ; disable auto scroll
    res appTextSave, (iy + appFlags) ; disable shawdow text
    res lwrCaseActive, (iy + appLwrCaseFlag) ; disable ALPHA-ALPHA lowercase
    bcall(_ClrLCDFull)

    call restoreAppState
    jr nc, initAlways
    ; Initialize everything if restoreAppState() fails.
    bcall(_InitErrorCode)
    bcall(_InitInputBuf)
    call initStack
    call initRegs
    call initMenu
    call initBase
    call initStat
    call initCfit
    call initTvm
initAlways:
    ; If restoreAppState() suceeds, only the following are initialized.
    call initArgBuf ; Start with Command Arg parser off.
    call initLastX ; Always copy TI-OS 'ANS' to 'X'
    call initDisplay ; Always initialize the display.
    call initTvmSolver ; Always init TVM solver
    call sanitizeMenu ; Sanitize the current (menuGroupId)

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
    call rclX
    bcall(_StoAns) ; transfer RPN83P 'X' to TI-OS 'ANS'
    call storeAppState
    set appAutoScroll, (iy + appFlags)
    ld (iy + textFlags), 0 ; reset text flags
    bcall(_ClrLCDFull)
    bcall(_HomeUp)

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

; Set CPU speed to 15 MHz on supported hardware (83+SE, 84+, 84+SE) on OS 1.13
; or higher. See TI-83 Plus SDK reference for SetExSpeed().
setFastSpeed:
    bcall(_GetBaseVer) ; OS version in A, B
    cp 2 ; check major version
    jr nc, above112 ; if 2.x then > 1.12
    cp 1 ; if 0.x, then < 1.12
    ret nz ; major version == 1
    ld a, b
    cp 13 ; check minor version
    ret c ; < 1.13
above112:
    ld a, $ff
    bcall(_SetExSpeed)
    ret
