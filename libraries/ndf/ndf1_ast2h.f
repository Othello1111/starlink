      SUBROUTINE NDF1_AST2H( DATA, ILINE, LINE, STATUS )
*+
* Name:
*    NDF1_AST2H

*  Purpose:
*     Copy AST_ data to an HDS object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_AST2H( DATA, ILINE, LINE, STATUS )

*  Description:
*     This routine copies a line of text representing AST_ data into a
*     specified element of a 1-dimensional character array. It is
*     intended for use when writing AST_ data to an HDS object (i.e an
*     HDS _CHAR array).

*  Arguments:
*     DATA( * ) = CHARACTER * ( * ) (Given and Returned)
*        The character array into which the text is to be copied.
*     ILINE = INTEGER (Given)
*        The index of the element in DATA which is to receive the text
*        (the contents of other elements are returned unchanged).
*     LINE = CHARACTER * ( * ) (Given)
*        The line of text to be inserted.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     This routine departs from the conventional argument order so as to
*     accommodate the case where the DATA argument is a mapped HDS
*     character array.

*  Copyright:
*     Copyright (C) 1997 Rutherford Appleton Laboratory.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     23-JUN-1997 (RFWS):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      
*  Arguments Given and Returned:
      CHARACTER * ( * ) DATA( * )
      
*  Arguments Given:
      INTEGER ILINE
      CHARACTER * ( * ) LINE

*  Status:
      INTEGER STATUS             ! Global status

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
      
*  Copy the line of text.
      DATA( ILINE ) = LINE

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_AST2H', STATUS )

      END
