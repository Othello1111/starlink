      SUBROUTINE NDF1_HUNMP( LOC, STATUS )
*+
*  Name:
*     NDF1_HUNMP

*  Purpose:
*     Unmap an HDS primitive object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_HUNMP( LOC, STATUS )

*  Description:
*     The routine unmaps an HDS object which has previously been mapped.

*  Arguments:
*     CHARACTER * ( * ) = LOC (Given)
*        Locator to HDS object.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  This routine exists because the DAT_UNMAP routine doesn't
*     execute if STATUS is set on entry. Thus, mapped data could
*     potentially remain unnecessarily mapped following recovery from
*     an error.
*     -  This routine attempts to execute even if STATUS is set on
*     entry, although no further error report will be made if it
*     subsequently fails under these circumstances.

*  Algorithm:
*     -  Save the error context on entry.
*     -  Unmap the HDS object.
*     -  Restore the error context.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     26-SEP-1989 (RFWS):
*        Original, derived from the equivalent ARY_ system routine.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants

*  Arguments Given:
      CHARACTER * ( * ) LOC

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER TSTAT              ! Temporary status variable

*.

*  Save the STATUS value and mark the error stack.
      TSTAT = STATUS
      CALL ERR_MARK
       
*  Unmap the HDS object.
      STATUS = SAI__OK
      CALL DAT_UNMAP( LOC, STATUS )
       
*  Annul any error if STATUS was previously bad, otherwise let the new
*  error report stand.
      IF ( STATUS .NE. SAI__OK ) THEN
         IF ( TSTAT .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            STATUS = TSTAT

*  Call error tracing routine if appropriate.
         ELSE
            CALL NDF1_TRACE( 'NDF1_HUNMP', STATUS )
         END IF
      ELSE
         STATUS = TSTAT
      END IF

*  Release error stack.
      CALL ERR_RLSE

      END
