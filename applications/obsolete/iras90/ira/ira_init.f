      SUBROUTINE IRA_INIT( STATUS )
*+
*  Name:
*     IRA_INIT

*  Purpose:
*     Initialise the IRA astrometry package.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRA_INIT( STATUS )

*  Description:
*     This routine must be called before calling any other IRA routine
*     which has an "IDA" argument. It is not necessary to call this
*     routine before using routines such as IRA_DIST which do not have
*     an "IDA" argument. This routine annulls any currently valid IRA
*     identifiers, sets the NDF extension name in which the astrometry
*     structure is located to "IRAS", sets the name of the astrometry
*     structure to "ASTROMETRY", and resets graphics options to their
*     default values.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-JAN-1991 (DSB):
*        Original version.
*     27-APR-1991 (DSB):
*        Modified fro IRA version 2.
*     11-FEB-1993 (DSB):
*        Locators removed from common.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT constants
      INCLUDE 'IRA_PAR'          ! IRA constants.

*  Global Variables:
      INCLUDE 'IRA_COM'          ! IRA common blocks.
*        ACM_ASNAME = CHARACTER (Write)
*           HDS name of the IRA astrometry structure.
*        ACM_DROPT( IRA__NOPT ) = DOUBLE PRECISION (Write)
*           The graphics options values.
*        ACM_STATE = CHARACTER (Write)
*           Set to the value of symbolic constant IRA__GOING to indicate
*           that IRA has been initialised.
*        ACM_VALID( IRA__MAX ) = LOGICAL (Read and Write)
*           If true, then the associated elements of the other arrays
*           held in common contain valid astrometry information.
*        ACM_XNAME = CHARACTER (Write)
*           Name of an NDF extension in which the IRA astrometry
*           structure is expected to be located.

*  External References:
      EXTERNAL IRA1_INIT         ! Initialise global data.

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set ACM__STATE to the value of symbolic constant IRA__GOING to
*  indicate that IRA has been initialised.
      ACM_STATE = IRA__GOING

*  Annul all currently valid IRA identifiers.
      DO I = 1, IRA__MAX
         IF( ACM_VALID( I ) ) ACM_VALID( I ) = .FALSE.
      END DO

*  Initialise other values in common.
      ACM_XNAME = 'IRAS'
      ACM_ASNAME = 'ASTROMETRY'

*  Initialise graphics options.
      ACM_DROPT( 1 ) = 1.25D-2
      ACM_DROPT( 2 ) = 1.25D-2
      ACM_DROPT( 3 ) = 6.0D0
      ACM_DROPT( 4 ) = 1.0D0
      ACM_DROPT( 5 ) = -1.0D0
      ACM_DROPT( 6 ) = -1.0D0
      ACM_DROPT( 7 ) = 1.0D0
      ACM_DROPT( 8 ) = 1.0D0
      ACM_DROPT( 9 ) = -1.0D0
      ACM_DROPT( 10 ) = -1.0D0
      ACM_DROPT( 11 ) = 1.0D0
      ACM_DROPT( 12 ) = 1.0D0

*  If an error occurred, give the context.
 999  CONTINUE

      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'IRA_INIT_ERR1',
     :     'IRA_INIT: Unable to initialise the IRAS Astrometry package',
     :                 STATUS )
      END IF

      END
