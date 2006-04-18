      SUBROUTINE SUBPAR_MAXC(NAMECODE, VALUE, STATUS)
*+
*  Name:
*     SUBPAR_MAXC
 
*  Purpose:
*     To set the maximum value which the parameter may take.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SUBPAR_MAXC( NAMECODE, VALUE, STATUS )
 
*  Description:
*     This routine saves the specified value in the SUBPAR common
*     'values' array corresponding with the type of the parameter,
*     and sets up the PARMAX array to point to it.
*     If a position in the values list has already been allocated
*     (even by a call in an earlier invocation) it will be re-used to
*     avoid running out of space after multiple invocations.
*     There are four different routines (C=R,I,D or C) to handle
*     VALUE of type REAL, INTEGER etc. Each attempts to convert
*     VALUE to the type of the parameter and checks against any
*     RANGE set in the Interface File before saving it.
*     STATUS has the normal effect.
*     The following SUBPAR error status values may be set-
*     CONER    Failure in data type conversion.
*     MNMXFL   MIN/MAX storage space full.
*     MNMXTY   Invalid parameter type for MIN/MAX value.
*     MNMXEX   MIN/MAX value outside RANGE.
*     The type (PARMAX(2,NAMECODE) is set to -1 if the routine fails
*     This indicates that no value is set. The fact may be used to
*     unset values.
*     Note that it is possible to exit with space reserved but no
*     maximum value set.
*  Arguments:
*     NAMECODE = INTEGER (Given)
*        The pointer to the common blocks for the parameter.
*     VALUE = REAL (Given)
*        The required maximum parameter value.
 
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Copyright:
*     Copyright (C) 1990, 1991, 1992, 1993 Science & Engineering Research Council.
*     Copyright (C) 1996 Central Laboratory of the Research Councils.
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
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     27-SEP-1990 (AJC):
*        Original version.
*     12-FEB-1991 (AJC):
*        Allow for unset MAX values (pointer -ve). Unset if error.
*     18-NOV-1992 (AJC):
*        Use portable conversion
*     10-MAR-1993 (AJC):
*        Add DAT_PAR for SUBPAR_CMN
*     21-MAY-1993 (AJC):
*        Allow when active
*      1_FEB-1996 (AJC):
*        Use SUBPAR__STRLEN
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'       ! SUBPAR constants
      INCLUDE 'SUBPAR_ERR'       ! SUBPAR error status values
                                 !
*  Global Variables:
      INCLUDE 'SUBPAR_CMN'       ! SUBPAR common blocks etc.
 
*  Arguments Given:
      INTEGER NAMECODE
      CHARACTER*(*)VALUE
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  External References:
 
*  Local Variables:
      INTEGER TYPE               ! The type of the parameter
      REAL TREAL                 ! Temporary REAL value
      INTEGER TINT               ! Temporary INTEGER value
      DOUBLE PRECISION TDOUBLE   ! Temporary DOUBLE value
      CHARACTER*(SUBPAR__STRLEN) TCHAR   ! Temporary CHARACTER value
      LOGICAL OK                 ! If value within constraints
*.
*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Get parameter type
      TYPE = MOD(PARTYPE(NAMECODE), 10)

*  For the appropriate type, obtain the pointer to storage space
*  in the values list for the parameter's MAX value.
*  If there is any previously allocated space, re-use it; otherwise
*  obtain free space
*  Then attempt to convert the given value.
*  If the conversion is OK, check that the value is within any
*  RANGE set in the Interface File. If everything is OK, store
*  the value and update the pointer array.

      IF ( TYPE .EQ. SUBPAR__CHAR ) THEN
*     Parameter is CHARACTER

*     Find storage for its MAX value
         IF ( PARMAX(1,NAMECODE) .EQ. 0 ) THEN
*        Space is not already allocated
            IF ( CHARPTR .LT. SUBPAR__MAXLIMS ) THEN
               CHARPTR = CHARPTR + 1
               PARMAX(1, NAMECODE) = CHARPTR

            ELSE
               STATUS = SUBPAR__MNMXFL
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP( 'SUP_MAX2', 'SUBPAR: Parameter ^NAME'
     :         // ' - ran out of space for MAX values', STATUS )
            END IF

         END IF

         IF ( STATUS .EQ. SAI__OK ) THEN
*        Space is allocated
*        Convert value to upper case
*        Check value is within any limits.
*        (.FALSE. means don't check existing MIN/MAX.)
            TCHAR = VALUE
            CALL CHR_UCASE( TCHAR )
            CALL SUBPAR_RANGEC( NAMECODE, TCHAR, .FALSE.,
     :                          OK, STATUS )
            IF( STATUS .EQ. SAI__OK ) THEN
*           Allowed value, set it.
               CHARLIST(PARMAX(1,NAMECODE)) = TCHAR
               PARMAX(2, NAMECODE) = SUBPAR__CHAR

            ELSE
*           Error on checking
               IF ( STATUS .EQ. SUBPAR__OUTRANGE )
     :              STATUS = SUBPAR__MNMXEX
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_SETC( 'VAL', VALUE )
               CALL EMS_REP( 'SUP_MAX1',
     :         'SUBPAR: Parameter ^NAME - ' //
     :         'failed to define maximum value', STATUS )

            END IF

         END IF

      ELSEIF ( TYPE .EQ. SUBPAR__REAL ) THEN
*     Parameter is REAL
*     Find storage for its MAX value
         IF ( PARMAX(1,NAMECODE) .EQ. 0 ) THEN
*        Space is not already allocated
            IF ( REALPTR .LT. SUBPAR__MAXLIMS ) THEN
               REALPTR = REALPTR + 1
               PARMAX(1, NAMECODE) = REALPTR
            ELSE
               STATUS = SUBPAR__MNMXFL
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP( 'SUP_MAX5', 'SUBPAR: Parameter ^NAME'
     :         // ' - ran out of space for MAX values', STATUS )
            END IF
         END IF 

         IF ( STATUS .EQ. SAI__OK ) THEN
*        Space is allocated
*        Convert the value to the parameter type
            CALL CHR_CTOR( VALUE, TREAL, STATUS )

*        If successfully converted, check it's within any limits.
            IF ( STATUS .EQ. SAI__OK ) THEN
*           (.FALSE. means don't check existing MIN/MAX.)
               CALL SUBPAR_RANGER( NAMECODE, TREAL, .FALSE.,
     :                             OK, STATUS )
               IF ( STATUS .EQ. SAI__OK ) THEN
*              Allowed value, set it.
                  REALLIST(PARMAX(1,NAMECODE)) = TREAL
                  PARMAX(2, NAMECODE) = SUBPAR__REAL

               ELSE
*              Illegal value - outside range
                  IF ( STATUS .EQ. SUBPAR__OUTRANGE )
     :                 STATUS = SUBPAR__MNMXEX
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETC( 'VAL', VALUE )
                  CALL EMS_REP( 'SUP_MAX3',
     :            'SUBPAR: Parameter ^NAME - ' //
     :            'failed to define maximum value', STATUS )

               END IF

            ELSE
               STATUS = SUBPAR__CONER
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_SETC( 'VAL', VALUE )
               CALL EMS_REP( 'SUP_MAX4',
     :         'SUBPAR: Parameter ^NAME - ' //
     :         'failed to convert ^VAL to REAL', STATUS )
            ENDIF

         END IF

      ELSEIF ( TYPE .EQ. SUBPAR__INTEGER ) THEN
*     Parameter is INTEGER
*     Find storage for its MAX value
         IF ( PARMAX(1,NAMECODE) .EQ. 0 ) THEN
*        Space is not already allocated
            IF ( INTPTR .LT. SUBPAR__MAXLIMS ) THEN
               INTPTR = INTPTR + 1
               PARMAX(1, NAMECODE) = INTPTR
            ELSE
               STATUS = SUBPAR__MNMXFL
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP( 'SUP_MAX5', 'SUBPAR: Parameter ^NAME'
     :         // ' - ran out of space for MAX values', STATUS )
            END IF
         END IF 

         IF ( STATUS .EQ. SAI__OK ) THEN
*        Space is allocated
*        Convert the value to the parameter type
            CALL CHR_CTOI( VALUE, TINT, STATUS )

*        If successfully converted, check it's within any limits.
            IF ( STATUS .EQ. SAI__OK ) THEN
*           (.FALSE. means don't check existing MIN/MAX.)
               CALL SUBPAR_RANGEI( NAMECODE, TINT, .FALSE.,
     :                             OK, STATUS )
               IF ( STATUS .EQ. SAI__OK ) THEN
*              Allowed value, set it.
                  INTLIST(PARMAX(1,NAMECODE)) = TINT
                  PARMAX(2, NAMECODE) = SUBPAR__INTEGER

               ELSE
*              Illegal value - outside range
                  IF ( STATUS .EQ. SUBPAR__OUTRANGE )
     :                 STATUS = SUBPAR__MNMXEX
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETC( 'VAL', VALUE )
                  CALL EMS_REP( 'SUP_MAX3',
     :            'SUBPAR: Parameter ^NAME - ' //
     :            'failed to define maximum value', STATUS )

               END IF

            ELSE
               STATUS = SUBPAR__CONER
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_SETC( 'VAL', VALUE )
               CALL EMS_REP( 'SUP_MAX4',
     :         'SUBPAR: Parameter ^NAME - ' //
     :         'failed to convert ^VAL to INTEGER', STATUS )
            ENDIF

         END IF

      ELSEIF ( TYPE .EQ. SUBPAR__DOUBLE ) THEN
*     Parameter is DOUBLE PRECISION
*     Find storage for its MAX value
         IF ( PARMAX(1,NAMECODE) .EQ. 0 ) THEN
*        Space is not already allocated
            IF ( DOUBLEPTR .LT. SUBPAR__MAXLIMS ) THEN
               DOUBLEPTR = DOUBLEPTR + 1
               PARMAX(1, NAMECODE) = DOUBLEPTR
            ELSE
               STATUS = SUBPAR__MNMXFL
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP( 'SUP_MAX5', 'SUBPAR: Parameter ^NAME'
     :         // ' - ran out of space for MAX values', STATUS )
            END IF
         END IF 

         IF ( STATUS .EQ. SAI__OK ) THEN
*        Space is allocated
*        Convert the value to the parameter type
            CALL CHR_CTOD( VALUE, TDOUBLE, STATUS )

*        If successfully converted, check it's within any limits.
            IF ( STATUS .EQ. SAI__OK ) THEN
*           (.FALSE. means don't check existing MIN/MAX.)
               CALL SUBPAR_RANGED( NAMECODE, TDOUBLE, .FALSE.,
     :                             OK, STATUS )
               IF ( STATUS .EQ. SAI__OK ) THEN
*              Allowed value, set it.
                  DOUBLELIST(PARMAX(1,NAMECODE)) = TDOUBLE
                  PARMAX(2, NAMECODE) = SUBPAR__DOUBLE

               ELSE
*              Illegal value - outside range
                  IF ( STATUS .EQ. SUBPAR__OUTRANGE )
     :                 STATUS = SUBPAR__MNMXEX
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETC( 'VAL', VALUE )
                  CALL EMS_REP( 'SUP_MAX3',
     :            'SUBPAR: Parameter ^NAME - ' //
     :            'failed to define maximum value', STATUS )

               END IF

            ELSE
               STATUS = SUBPAR__CONER
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_SETC( 'VAL', VALUE )
               CALL EMS_REP( 'SUP_MAX4',
     :         'SUBPAR: Parameter ^NAME - ' //
     :         'failed to convert ^VAL to DOUBLE PRECISION',
     :          STATUS )
            ENDIF

         END IF

      ELSE
*     Attempt to set a maximum value for disallowed type.
         STATUS = SUBPAR__MNMXTY
         CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP( 'SUP_MAX12', 'SUBPAR: Parameter ^NAME' //
     :   ' - cannot set maximum value for this type', STATUS )
      END IF

*  Unset maximum value if routine failed
      IF ( STATUS .NE. SAI__OK ) PARMAX(2,NAMECODE) = -1

      END
