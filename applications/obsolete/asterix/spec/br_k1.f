*+  BR_K1 - Modified Bessel function of the second kind
      DOUBLE PRECISION FUNCTION BR_K1( A, STATUS )
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*     Andy Pollock (BHVAD::AMTP)
*    History :
*
*     20 Aug 85 : Original
*     13 Jan 93 : Remembers last value, and converted to D.P. (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      DOUBLE PRECISION A
*
*    Status :
*
      INTEGER STATUS
*
*    Function declarations :
*
      DOUBLE PRECISION S18ADF           ! NAG subroutine
*
*    Local variables :
*
      DOUBLE PRECISION LAST_A,LAST_K1	! Last A and K1 in this routine
      INTEGER FAIL                   	! NAG failure code
*
*    Local data :
*
      DATA    LAST_A/-1.0D0/		! Undefined for this value
*
*    Preserve across calls :
*
      SAVE    LAST_A,LAST_K1
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Different last time?
      IF (A.NE.LAST_A) THEN
        LAST_A = A
        FAIL=0
        LAST_K1 = S18ADF(A,FAIL)
        IF ( FAIL .NE. 0 ) THEN
          STATUS=SAI__ERROR
          CALL ERR_REP(' ',
     :                'IFAIL non-zero on exit from NAG routine S18ADF',
     :                STATUS)
        END IF
      END IF

      BR_K1 = LAST_K1

      END
