      SUBROUTINE NDF1_H2AST( DATA, ILINE, LINE, STATUS )
*+
* Name:
*    NDF1_H2AST

*  Purpose:
*     Copy AST_ data from an HDS object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_H2AST( DATA, ILINE, LINE, STATUS )

*  Description:
*     This routine copies a line of text representing AST_ data from a
*     specified element of a 1-dimensional character array. It is
*     intended for use when reading AST_ data from an HDS object (i.e
*     an HDS _CHAR array).

*  Arguments:
*     DATA( * ) = CHARACTER * ( * ) (Given)
*        The character array from which the text is to be copied.
*     ILINE = INTEGER (Given)
*        The index of the element in DATA which is to provide the text
*        (the contents of other elements are ignored).
*     LINE = CHARACTER * ( * ) (Returned)
*        The line of text obtained.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1997 Rutherford Appleton Laboratory.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     24-JUN-1997 (RFWS):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      
*  Arguments Given:
      CHARACTER * ( * ) DATA( * )
      INTEGER ILINE
      
*  Arguments Returned:
      CHARACTER * ( * ) LINE
      
*  Status:
      INTEGER STATUS             ! Global status

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract the required line of text.
      LINE = DATA( ILINE )

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_H2AST', STATUS )

      END
