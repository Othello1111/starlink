C----------------------------------------------------------------------------

      SUBROUTINE MKHIS (X, Y, N, XFAC)

C  Routine to generate histogram from X and Y point pairs ( suitable
C  for plotting routines which draw straight lines between
C  successive points.

      IMPLICIT  NONE

C     Formal parameters

      REAL    X(*)     ! X array
      REAL    Y(*)     ! Y array
      INTEGER N        ! No of (x,y) point pairs
      REAL    XFAC     ! Nominal channel width

C     Local variables:

      INTEGER I, J
      REAL    XLEFT, XRIGHT

C  Ok, go...

D     CALL SXGTIDLE
D     TYPE *, ' -- mkhis --'
D     TYPE *, '    input # points = ', N

      XLEFT = X(N) + 0.5*XFAC

      DO I = 1, N
        J = N+1 - I

        XRIGHT = XLEFT
        IF (J.EQ.1) THEN
          XLEFT = X(1) - 0.5*XFAC
        ELSE
          XLEFT = 0.5 * (X(J)+X(J-1))
        END IF

        Y(2*J)   = Y(J)
        X(2*J)   = XRIGHT
        Y(2*J-1) = Y(J)
        X(2*J-1) = XLEFT
      END DO

      N = 2*N

D     TYPE *, '    output # points = ', N
D     CALL SXGTTGRAPH

      RETURN
      END


