      SUBROUTINE CCG1_MER3R( STACK, NPIX, NLINES, VARS, MINPIX,
     :                         RESULT, NCON, STATUS )
*+
*  Name:
*     CCG1_MER3R

*  Purpose:
*     Combines data lines using a weighted mean.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_MER3R( STACK, NPIX, NLINES, VARS, MINPIX,
*                        RESULT, NCON, STATUS )

*  Description:
*     This routine accepts an array consisting a series of (vectorised)
*     lines of data. The data values in the lines are then combined to
*     form a weighted mean. The weights used are one-per-line and are
*     the reciprocal of values given in the array VARS. The output means
*     are returned in the array RESULT.

*  Notes
*     - this routine performs its work in double precision, but the
*     output is returned in single precision, therefore it should only
*     be used with data whose outputs are in the range of single
*     precision values. It accepts the data in any of the non-complex
*     formats as supported by PRIMDAT, the variances must be given in
*     double precision.

*  Arguments:
*     STACK( NPIX, NLINES ) = <COMM> (Given)
*        The array of lines which are to be combined into a single line.
*     NPIX = INTEGER (Given)
*        The number of pixels in a line of data.
*     NLINES = INTEGER (Given)
*        The number of lines of data in the stack.
*     VARS( NLINES ) = DOUBLE PRECISION (Given)
*        The variance to to used for each line of data.
*     MINPIX = INTEGER (Given)
*        The minimum number of pixels required to contribute to an
*        output pixel.
*     RESULT( NPIX ) = REAL (Returned)
*        The output line of data.
*     NCON( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        The actual number of contributing pixels from each input line
*        to the output line.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils
 
*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-MAY-1992 (PDRAPER):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      INTEGER NPIX
      INTEGER NLINES
      INTEGER MINPIX
      REAL STACK( NPIX, NLINES )
      DOUBLE PRECISION VARS( NLINES )

*  Arguments Given and Returned:
      DOUBLE PRECISION NCON( NLINES )

*  Arguments Returned:
      REAL RESULT( NPIX )

*  Status:
      INTEGER STATUS             ! Global status

*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Numerical error flag

*  External References:
      EXTERNAL NUM_TRAP
      INTEGER NUM_TRAP           ! Numerical error handler

*  Local Variables:
      INTEGER I                  ! Loop variable
      INTEGER J                  ! Loop variable
      DOUBLE PRECISION SUM1      ! Sum of weights
      DOUBLE PRECISION SUM2      ! Sum of weighted values
      DOUBLE PRECISION VAL       ! Present data value
      DOUBLE PRECISION VAR       ! Present weight
      INTEGER NGOOD              ! Number of good pixels

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.


*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Establish the numeric error handler.
      CALL NUM_HANDL( NUM_TRAP )
      DO 1 I = 1, NPIX

*  Loop over for all possible output pixels. Initialise sums.
         SUM1 = 0.0D0
         SUM2 = 0.0D0

*  Set good pixel count and reset num_error from any errors that have
*  occurred.
         NGOOD = 0
         NUM_ERROR = SAI__OK

*  Loop over all possible contributing pixels forming weighted mean
*  sums.
         DO 5 J = 1, NLINES
            IF( STACK( I, J ) .NE. VAL__BADR ) THEN

*  Convert input type to double precision before forming sums should be
*  no numeric errors on this attempt.
               VAL = NUM_RTOD( STACK( I, J ) )

*  Conversion increment good value counter.
               NGOOD = NGOOD + 1

*  Change variance to weight and sum weights.
               VAR = 1.0D0 / VARS( J )
               SUM1 = SUM1 + VAR

*  Form weighted mean sum.
               SUM2 = SUM2 + VAL * VAR

*  Update the contribution buffer - all values contribute when forming
*  mean.
               NCON( J ) = NCON( J ) + 1.0D0
            END IF
 5       CONTINUE

*  If there are sufficient good pixels output the result.
         IF ( NGOOD .GE. MINPIX ) THEN
            RESULT( I ) = REAL( SUM2 / SUM1 )

*  Trap numeric errors.
            IF ( NUM_ERROR .NE. SAI__OK ) THEN
               RESULT( I ) = VAL__BADR
            END IF
         ELSE

*  Not enough contributing pixels, set output invalid.
            RESULT( I ) = VAL__BADR
         END IF

 1    CONTINUE

*  Remove the numerical error handler.
      CALL NUM_REVRT
      END
* @(#)ccg1_mer3.gen	2.2     10/8/96     2
