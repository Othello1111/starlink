      LOGICAL FUNCTION MSG1_GTSTM()
*+
*  Name:
*     MSG1_GTSTM

*  Purpose:
*     Get the value of element MSGSTM from the MSG_CMN common block.

*  Language:
*    Starlink Fortran 77

*  Invocation:
*     RESULT = MSG1_GTSTM()

*  Description:
*     This routine returns the value of element MSGSTM from the MSG_CMN 
*     common block. This should be used instead of directly accessing the
*     common block since access from a different shared library may result in
*     the comm block value being uninitialised by the corresponding BLOCK DATA
*     module.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-JUL-2004 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

      IMPLICIT NONE                     
      INCLUDE 'MSG_CMN'                 

      MSG1_GTSTM = MSGSTM

      END
