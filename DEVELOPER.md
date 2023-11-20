# Developer Notes

Notes for the developers of the RPN83P app, likely myself in 6 months when I
cannot remember how the code works.

## DRAW Mode

The secret `DRAW` (maybe call it "Debug") modes are activated by the `2ND DRAW`
command. It prompts the user for a number, like the `FIX` or `STO` command.
Currently 4 modes defined:

- 0 (drawNodeNormal): Normal rendering, this is the default.
- 1 (drawModeTvmSolverI): Single step through the `I%YR` TVM Solver
  calculations, and show the iteration counter (`tvmSolverCount`), and the
  internal interest rate variables (`tvmI0`, `tvmI1`) in place of the RPN stack
  variables (T,Z,Y,X). The program waits for a key before executing the next
  iteration.
- 2 (drawModeTvmSolverF): Same as (1), except show the values of the function
  whose roots we are trying to solve at `tvmI0` and `tvmI1`, in other words,
  show the variables `tvmNPMT0` and `tvmNPMT1`.
- 3 (drawModeInputBuf): Show the `inputBuf` (the edit buffer when entering
  digits) in the Debug line just below the Status line. The `X` register is now
  always shown, instead of being overwritten by the `inputBuf` in Edit mode.
  This helps debugging the complex interaction between the input buffer and the
  X register.
