/* Subroutine:  psx_geteuid( uid, status )
*+
*  Name:
*     PSX_GETEUID

*  Purpose:
*     Gets the effective user ID

*  Language:
*     ANSI C

*  Invocation:
*     CALL PSX_GETEUID( UID, STATUS )

*  Description:
*     The routine obtains the effective user identification number of the 
*     calling process and returns the value in UID.

*  Arguments:
*     UID = INTEGER (Returned)
*        The value of the effective user ID.
*     STATUS = INTEGER (Given)
*        The global status.

*  References:
*     -  POSIX standard (1988), section 4.2.1
      
*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council

*  Notes:
*     - On unsupported platforms this function return 0.
      
*  Authors:
*     PMA: Peter Allan (Starlink, RAL)
*     AJC: Alan Chipperfield (Starlink, RAL)
*     PWD: Peter W. Draper (Starlink, Durham University)
*     {enter_new_authors_here}

*  History:
*     26-FEB-1991 (PMA):
*        Original version.
*     27-JUN-1991 (PMA):
*        Changed IMPORT and EXPORT macros to GENPTR.
*     23-JUN-2000 (AJC):
*        Remove refs to VMS in prologue
*     20-JUL-2004 (PWD):
*        Added default behaviour for unsupported platforms.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
-----------------------------------------------------------------------------
*/

#include <config.h>

/* Global Constants:		.					    */

#if defined(vms)
#include <unixlib>		 /* VMS definintions for Unix functions	    */
#else
#  if HAVE_SYS_TYPES_H
#    include <sys/types.h>
#  endif
#  if HAVE_UNISTD_H
#    include <unistd.h>
#  endif
#endif

#include "f77.h"		 /* C - Fortran interface		    */
#include "sae_par.h"		 /* ADAM constants			    */


F77_SUBROUTINE(psx_geteuid)( INTEGER(uid), INTEGER(status) )
{

/* Pointers to Arguments:						    */

   GENPTR_INTEGER(uid)
   GENPTR_INTEGER(status)

/* Check inherited global status.					    */

   if( *status != SAI__OK ) return;

/* Get the effective user ID.						    */
#if HAVE_GETEUID
   *uid = (F77_INTEGER_TYPE)geteuid();
#else
   *uid = (F77_INTEGER_TYPE)0;
#endif
}
