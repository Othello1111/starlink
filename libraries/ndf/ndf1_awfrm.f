      SUBROUTINE NDF1_AWFRM( IAX, IACB, FORM, STATUS )
*+
*  Name:
*     NDF1_AWFRM

*  Purpose:
*     Obtain the storage form of an axis width array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_AWFRM( IAX, IACB, FORM, STATUS )

*  Description:
*     The routine returns the storage form of an NDF axis width array
*     as an upper case character string. The NDF is identified by its
*     entry in the ACB.

*  Arguments:
*     IAX = INTEGER (Given)
*        Number of the axis for which informaton is required.
*     IACB = INTEGER (Given)
*        Index to the NDF entry in the ACB.
*     FORM = CHARACTER * ( * ) (Returned)
*        Axis width array storage form (upper case).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Obtain an index to the data object entry in the DCB.
*     -  Ensure that axis width array information is available.
*     -  If the axis width array exists, then determine its storage
*     form directly.
*     -  Otherwise, obtain the default storage form from the DCB.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     15-OCT-1990 (RFWS):
*        Original version, derived from the NDF1_ADFRM routine.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants
      INCLUDE 'ARY_PAR'          ! ARY_ public constants

*  Global Variables:
      INCLUDE 'NDF_DCB'          ! NDF_ Data Control Block
*        DCB_AWID( NDF__MXDIM, NDF__MXDCB ) = INTEGER (Read)
*           ARY_ system identifiers for axis width arrays.
*        DCB_AWFRM( NDF__MXDIM, NDF__MXDCB ) = CHARACTER * ( NDF__SZFRM
*        ) (Read)
*           Storage form of axis width arrays.

      INCLUDE 'NDF_ACB'          ! NDF_ Access Control Block
*        ACB_IDCB( NDF__MXACB ) = INTEGER (Read)
*           Index to data object entry in the DCB.

*  Arguments Given:
      INTEGER IAX
      INTEGER IACB

*  Arguments Returned:
      CHARACTER * ( * ) FORM

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IDCB               ! Index to data object entry in the DCB

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain an index to the data object entry in the DCB.
      IDCB = ACB_IDCB( IACB )

*  Ensure that axis width array information is available.
      CALL NDF1_DAW( IAX, IDCB, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*  If the axis width array exists, then determine its storage form
*  directly.
         IF ( DCB_AWID( IAX, IDCB ) .NE. ARY__NOID ) THEN
            CALL ARY_FORM( DCB_AWID( IAX, IDCB ), FORM, STATUS )

*  Otherwise, obtain the default storage form from the DCB.
         ELSE
            CALL NDF1_CCPY( DCB_AWFRM( IAX, IDCB ), FORM, STATUS )
         END IF
      END IF
       
*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_AWFRM', STATUS )

      END
