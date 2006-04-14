/*+
 *  Name:
 *     emsRep

 *  Purpose:
 *     Report an error message.

 *  Language:
 *     Starlink ANSI C

 *  Invocation:
 *     emsRep( err, text, status )

 *  Description:
 *     This function provides a C interface for the Error Message 
 *     Service routine EMS_REP (written in Fortran).

 *  Arguments:
 *     err = const char * (Given)
 *        The error message name.
 *     text = const char * (Given)
 *        The error message text.
 *     status = int * (Given and Returned)
 *        The global status value.

*  Copyright:
*     Copyright (C) 1990, 1991 Science & Engineering Research Council.
*     Copyright (C) 1999, 2001 Central Laboratory of the Research Councls.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

 *  Authors:
 *     PCTR: P.C.T. Rees (STARLINK)
 *     AJC: A.J. Chipperfield (STARLINK)
 *     RTP: R.T.Platon (STARLINK)
 *     {enter_new_authors_here}

 *  History:
 *     6-JUN-1990 (PCTR):
 *        Original version, coded as a C macro function.
 *     16-AUG-1990 (PCTR):
 *        C function code.
 *     21-JUN-1991 (PCTR):
 *        Made all given character strings type "const".
 *     13-MAY-1999 (AJC):
 *        Renamed from ems_rep_c
 *     14-FEB-2001 (RTP):
 *        Rewritten in C from Fortran routine EMS_REP
 *      2-MAR-2001 (AJC):
 *        Properly import strings
 *        and remove incorrect copying at end
 *        Add maxlen arg to ems1Form
 *        Don't pass err to ems1Form
 *     {enter_further_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *-
 */

/* Include Statements: */
#include <string.h>                   /* String handling library functions */
#include "sae_par.h"                  /* SAE_ public constant definitions */
#include "ems_par.h"                  /* EMS_ public constant definitions */
#include "ems_err.h"                  /* EMS_ error codes */
#include "ems_sys.h"                  /* EMS_ private macro definitions */
#include "ems.h"                      /* EMS_ function prototypes */
#include "ems1.h"                     /* EMS_ Internal function prototypes */
#include "ems_msgtb.h"                /* EMS_ message table */

/* Function Definitons: */
void emsRep( const char *err, const char *text, int *status ){
   int istat;                         /* Internal status */
   int mlen;                          /* Length of final error message text */
   int plen;                          /* Length of the message name */
   char mstr[EMS__SZMSG+1];           /* Final error message text */
   char pstr[EMS__SZPAR+1];           /* Local error name text */
 
   TRACE( "emsRep" );

/*  Check the inherited status: if it is SAI__OK, then set status to
 *  EMS__BADOK and store an additional message in the error table.
 */
      if ( *status == SAI__OK ) {

/*     Set the status equal to EMS__BADOK. */
         *status = EMS__BADOK;

/*     Make an additional error report. */
         strcpy(pstr, "EMS_REP_BADOK");
         plen = strlen( pstr );
         strcpy(mstr,
           "STATUS not set in call to EMS_REP (improper use of EMS_REP).");
         mlen = strlen( mstr );

/*     Store the additional message in the error table (first create a new
 *     error reporting context to avoid loss of tokens in the base level).
 *     Associate status EMS__BADOK with the additional message.
 *     If EMS1_ESTOR returns an error status it will be ignored but will
 *     almost certainly be repeated later with the given message.
 */
         emsMark();
         istat = EMS__BADOK;
         ems1Estor( pstr, plen, mstr, mlen, &istat );

/*     Release the error reporting context. */
         emsRlse();

/*     Set the given message status to EMS__UNSET */
         istat = EMS__UNSET;

/*  Else, a normal bad status is given - set ISTAT to the given status value */
     } else {
         istat = *status;
     }

/*  Now form the given error message.
 *  Status is not altered by this routine.
 */
     ems1Form( (char*) text, EMS__SZMSG, !msgstm, mstr, &mlen, &istat );

/*  Use EMS1_ESTOR to store the error message in the error table. */
     plen = MAX( 1, strlen( err ) );
     ems1Estor( (char*)err, plen, mstr, mlen, &istat );

/*  Check the returned status for message output errors and attempt to
 *  report an additional error in the case of failure - but only on the
 *  first occasion.
 */
     if ( istat == EMS__OPTER && *status != EMS__OPTER ) {
         *status = EMS__OPTER;
         strcpy(pstr, "EMS_REP_OPTER");
         plen = strlen( pstr );
         strcpy(mstr, "EMS_REP: Error encountered during message output.");
         mlen = strlen( mstr );
         ems1Estor( pstr, plen, mstr, mlen, &istat );
     }

     return;
}
