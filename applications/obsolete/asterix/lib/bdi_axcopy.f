      SUBROUTINE BDI_AXCOPY( ID, IAX, ITEMS, OID, OAX, STATUS )
*+
*  Name:
*     BDI_AXCOPY

*  Purpose:
*     Copy the named axis items from input to output

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL BDI_AXCOPY( ID, IAX, ITEMS, OID, OAX, STATUS )

*  Description:
*     Copies the named items from the IAX'th axis of ID to the OAX'th
*     axis of OID.

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of BinDS, Array or Scalar object, or derivatives
*        thereof
*     IAX = INTEGER (given)
*        Axis number of the items to be mapped
*     ITEMS = CHARACTER*(*) (given)
*        List of items to be mapped
*     OID = INTEGER (given)
*        ADI identifier of the object to which the axis items will be copied
*     OAX = INTEGER (given)
*        Axis number in the output for the copied items
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     BDI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/bdi.html

*  Keywords:
*     package:bdi, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*      9 Aug 1995 (DJA):
*        Original version.
*     10 Nov 1995 (DJA):
*        Extended to allow copying of whole axis
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER			ID, IAX, OID, OAX
      CHARACTER*(*)		ITEMS

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*20		LITEM1, LITEM2		! Local item names

      INTEGER                   C1, C2                  ! Character pointers
      INTEGER                   IITEM                   ! Item counter
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Have items been specified?
      IF ( ITEMS .GT. ' ' ) THEN

*    Loop over items while more of them and status is ok
        CALL UDI0_CREITI( ITEMS, C1, C2, IITEM, STATUS )
        DO WHILE ( (C1.NE.0) .AND. (STATUS.EQ.SAI__OK) )

*    Construct the item names
 10       FORMAT( 'Axis_', I1, '_', A )
          WRITE( LITEM1, 10 ) IAX, ITEMS(C1:C2)
          WRITE( LITEM2, 10 ) OAX, ITEMS(C1:C2)

*      Copy the axis item
          CALL BDI_COPY( ID, LITEM1, OID, LITEM2, STATUS )

*      Advance iterator to next item
          CALL UDI0_ADVITI( ITEMS, C1, C2, IITEM, STATUS )

        END DO

*  Simple axis copy
      ELSE

*    Construct the item names
 20     FORMAT( 'Axis_', I1 )
        WRITE( LITEM1, 20 ) IAX
        WRITE( LITEM2, 20 ) OAX

*    Copy axes
        CALL BDI_COPY( ID, LITEM1, OID, LITEM2, STATUS )

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'BDI_AXCOPY', STATUS )

      END
