      SUBROUTINE BDI2_TICHK( NARG, ARGS, OARG, STATUS )
*+
*  Name:
*     BDI2_TICHK

*  Purpose:
*     Service FileItemChk(TimeSeries,FITSfile,item) requests from the BDI system

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL BDI2_TICHK( NARG, ARGS, OARG, STATUS )

*  Description:
*     Service FileItemChk(TimeSeries,FITSfile,item) requests from the BDI system

*  Arguments:
*     NARG = INTEGER (given)
*        Number of method arguments
*     ARGS(*) = INTEGER (given)
*        ADI identifier of method arguments
*     OARG = INTEGER (returned)
*        Output data
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
*     package:bdi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     9 Aug 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Arguments Given:
      INTEGER                   NARG, ARGS(*)

*  Arguments Returned:
      INTEGER                   OARG

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			CHR_INSET
        LOGICAL			CHR_INSET

*  Local Variables:
      CHARACTER*20		ITEM

      INTEGER			BCOL			! Binary table column
      INTEGER			TIHDU			! RATE hdu id

      LOGICAL			OK			! Object exists/ok?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract the arguments
      CALL ADI_GET0C( ARGS(3), ITEM, STATUS )

*  Locate the RATE hdu
      CALL ADI2_FNDHDU( ARGS(2), 'RATE', .FALSE., TIHDU, STATUS )

*  Switch on the various items
*  Primary data
      IF ( ITEM .EQ. 'Data' ) THEN
        CALL ADI2_FNDBTC( TIHDU, 'RATE', BCOL, STATUS )
        OK = (BCOL.GT.0)

*  Channel axis
      ELSE IF ( ITEM .EQ. 'Axis_1_Data' ) THEN
        CALL ADI2_FNDBTC( TIHDU, 'TIME', BCOL, STATUS )
        OK = (BCOL.GT.0)

*  Data error
      ELSE IF ( ITEM .EQ. 'Error' ) THEN
        CALL ADI2_FNDBTC( TIHDU, 'ERROR', BCOL, STATUS )
        OK = (BCOL.GT.0)

*  These things can be supported automatically
      ELSE IF ( CHR_INSET( 'Label,Units,Axes,Axis_1_Label,Axis_1_Units',
     :                     ITEM ) ) THEN
        OK = .TRUE.

*  Nothing else is supported for OGIP time series
      ELSE
        OK = .FALSE.

      END IF

*  Release the RATE hdu
      CALL ADI_ERASE( TIHDU, STATUS )

*  Create return valuie
      CALL ADI_NEWV0L( OK, OARG, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'BDI2_TICHK', STATUS )

      END
