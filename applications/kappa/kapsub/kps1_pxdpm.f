      SUBROUTINE KPS1_PXDPM( NDIM, IMASK, EXPAND, EL, MASK, STATUS )
*+
*  Name:
*     KPS1_PXDPM

*  Purpose:
*     Initialise the mask array for PIXDUPE.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_PXDPM( NDIM, IMASK, EXPAND, EL, MASK, STATUS )

*  Description:
*     This routine stores bad values in the supplied array, except for the
*     pixel with indices given by IMASK, which is set to 1. 

*  Arguments:
*     NDIM = INTEGER (Given)
*        No.of dimensions in MASK.
*     IMASK( NDIM ) = INTEGER (Given)
*        Indices of the pixel to be set to 1.
*     EXPAND( NDIM ) = INTEGER (Given)
*        The dimensions of the MASK array.
*     EL = INTEGER (Given)
*        The total number of pixels in the mask array.
*     MASK( * ) = REAL (Returned)
*        The mask array.
*     STATUS = INTEGER (Given and Returned)
*        The inherited status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     11-NOV-2004 (DSB):
*        Initial version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! no default typing allowed

*  Global Constants: 
      INCLUDE 'SAE_PAR'        ! Global SSE parameters 
      INCLUDE 'PRM_PAR'        ! VAL__ constants

*  Arguments Given:
      INTEGER NDIM
      INTEGER IMASK( NDIM )
      INTEGER EXPAND( NDIM )
      INTEGER EL

*  Arguments Returned:
      REAL MASK( * )

*  Global Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER I
      INTEGER IV
*.

*  Check inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Fill the array with VAL__BADR.
      DO I = 1, EL
         MASK( I ) = VAL__BADR
      END DO
      
*  Find the vector index of the pixel with indices given by IMASK.
      IV = IMASK( NDIM ) - 1
      DO I = NDIM - 1, 1, -1
         IV = IMASK( I ) - 1 + IV * EXPAND( I )
      END DO
      IV = IV + 1

*  Set this element to 1.0
      IF( IV .GT. 0 .AND. IV .LE. EL ) THEN
         MASK( IV ) = 1.0

      ELSE
         CALL MSG_SETI( 'EL', EL )
         CALL MSG_SETI( 'IV', IV )
         CALL ERR_REP( 'KPS1_PXDPM_ERR1', 'KPS1_PXDPM: Vectorised '//
     :                 'array index ^IV is out of bounds [1,^EL] '//
     :                 '(internal KAPPA programming error).', STATUS )
      END IF

      END
