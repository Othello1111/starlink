      SUBROUTINE NDF1_HSPLT( NAME, F1, F2, P1, P2, STATUS )
*+
*  Name:
*     NDF1_HSPLT

*  Purpose:
*     Split an HDS object name into a file name and a path name.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_HSPLT( NAME, F1, F2, P1, P2, STATUS )

*  Description:
*     This routine analyses a general HDS object name and locates the
*     substrings which specify the container file name and the path
*     name of the object within the file.

*  Arguments:
*     NAME = CHARACTER * ( * ) (Given)
*        HDS object name to be analysed.
*     F1 = INTEGER (Returned)
*        Character position of the start of the file name.
*     F2 = INTEGER (Returned)
*        Character position of the end of the file name.
*     P1 = INTEGER (Returned)
*        Character position of the start of the path name.
*     P2 = INTEGER (Returned)
*        Character position of the end of the path name.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  If the routine succeeds, then F1 and F2 will always identify
*     the container file name.
*     -  If the object describes a top-level object, then there will be
*     no path name. In this case, P2 will be returned greater than P1.
*     Otherwise, P1 and P2 will identify the path name.
*     -  This routine performs some checks on the validity of the
*     object name supplied, but these are not comprehensive. Only an
*     attempt to locate the object will fully validate the name.
*     -  Any blank characters which surround the file or path names
*     will be excluded from the returned character string positions.

*  Machine-specific features used:
*     This routine unavoidably has to make assumptions about the format
*     of VAX/VMS and POSIX file names.

*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     26-FEB-1991 (RFWS):
*        Original version.
*     16-OCT-1991 (RFWS):
*        Allow the returned path name to contain a leading '.' if
*        present.
*     17-OCT-1991 (RFWS):
*        Fixed bug: path name limits not being returned after earier
*        changes.
*     17-JAN-1992 (RFWS):
*        Added handling of POSIX filenames, as well as VMS.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_ERR'          ! NDF_ error codes      

*  Arguments Given:
      CHARACTER * ( * ) NAME

*  Arguments Returned:
      INTEGER F1
      INTEGER F2
      INTEGER P1
      INTEGER P2

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Significant length of a string

*  Local Variables:
      CHARACTER * ( 1 ) DUM1     ! Dummy argument
      CHARACTER * ( 1 ) DUM2     ! Dummy argument
      CHARACTER * ( 1 ) DUM3     ! Dummy argument
      CHARACTER * ( 1 ) DUM4     ! Dummy argument
      CHARACTER * ( 30 ) SYSNAM  ! Name of operating system
      INTEGER F                  ! Position of first non-blank character
      INTEGER I1                 ! First INDEX result
      INTEGER I2                 ! Second INDEX result
      INTEGER IEND               ! Position of end of file name
      INTEGER ISTART             ! Position of start of path name
      INTEGER L                  ! Position of last non-blank character

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise and find the first and last non-blank characters in the
*  object name.
      CALL CHR_FANDL( NAME, F, L )

*  If the name is blank, then report an error.
      IF ( F .GT. L ) THEN
         STATUS = NDF__NAMIN
         CALL ERR_REP( 'NDF1_HSPLT_BLNK',
     :                 'Blank NDF name supplied.',
     :                 STATUS )

*  If the first non-blank character is a quote.
*  ===========================================

*  Search for the closing quote.
      ELSE IF ( NAME( F : F ) .EQ. '"' ) THEN
         IEND = 0
         IF ( L .GT. F ) THEN
            IEND = INDEX( NAME( F + 1 : L ), '"' )
            IF ( IEND .NE. 0 ) IEND = IEND + F
         END IF

*  If the closing quote is missing, then report an error.
         IF ( IEND .EQ. 0 ) THEN
            STATUS = NDF__NAMIN
            CALL MSG_SETC( 'NAME', NAME( F : L ) )
            CALL ERR_REP( 'NDF1_HSPLT_QTE',
     :                    'Missing quote in the NDF name ''^NAME''.',
     :                    STATUS )

*  If the quotes are consecutive, then report an error.
         ELSE IF ( IEND .EQ. F + 1 ) THEN
            STATUS = NDF__NAMIN
            CALL MSG_SETC( 'NAME', NAME( F : L ) )
            CALL ERR_REP( 'NDF1_HSPLT_NON',
     :                    'File name absent in the NDF name ''^NAME''.',
     :                    STATUS )

*  Otherwise, find the first and last non-blank characters in the
*  filename which appears between the quotes.
         ELSE
            CALL CHR_FANDL( NAME( F + 1 : IEND - 1 ), F1, F2 )

*  If the file name is blank, then report an error.
            IF ( F1 .GT. F2 ) THEN
               STATUS = NDF__NAMIN
               CALL MSG_SETC( 'NAME', NAME( F : L ) )
               CALL ERR_REP( 'NDF1_HSPLT_BLQ',
     :                       'Quoted filename is blank in the NDF ' //
     :                       'name ''^NAME''.',
     :                       STATUS )

*  Otherwise, derive the position of the file name string.
            ELSE
               F1 = F1 + F
               F2 = F2 + F
            END IF
         END IF

*  If there have been no errors, then attempt to find the position of
*  the path name string.
         IF ( STATUS .EQ. SAI__OK ) THEN

*  If the file name extends to the end of the object name string, then
*  there is no path name (i.e. it is a top-level object), so return
*  a "null" position.
            IF ( IEND .GE. L ) THEN
               P1 = 1
               P2 = 0

*  Otherwise, find the first and last non-blank character positions in
*  whatever follows the file name.
            ELSE
               CALL CHR_FANDL( NAME( IEND + 1 : L ), ISTART, L )
               ISTART = ISTART + IEND
               L = L + IEND

*  If this candidate path name does not start with a '.' or a '(', then
*  there is a top-level name present. This must be ignored (the actual
*  file name fills this role).
               IF ( ( NAME( ISTART : ISTART ) .NE. '.' ) .AND.
     :              ( NAME( ISTART : ISTART ) .NE. '(' ) ) THEN

*  Find the first following occurrence of a '.' or '('.
                  I1 = INDEX( NAME( ISTART : L ), '.' )
                  I2 = INDEX( NAME( ISTART : L ), '(' )
                  IF ( ( I1 .EQ. 0 ) .OR.
     :                 ( ( I2 .NE. 0 ) .AND. ( I2 .LT. I1 ) ) ) THEN
                     I1 = I2
                  END IF

*  Move the starting position to the character found, or beyond the
*  last non-blank character if a '.' or '(' was not found.
                  IF ( I1 .NE. 0 ) THEN
                     ISTART = ISTART + I1 - 1
                  ELSE
                     ISTART = L + 1
                  END IF
               END IF

*  If we are beyond the end of the input name string, then only a
*  top-level object name is present. Ignore it (i.e. return a "null"
*  path name position).
               IF ( ISTART .GT. L ) THEN
                  P1 = 1
                  P2 = 0

*  Otherwise return the path name limits.
               ELSE
                  P1 = ISTART
                  P2 = L
               END IF
            END IF
         END IF

*  If the file name is not quoted.
*  ==============================
*
*  Its end must be detected. First determine which operating system is
*  in use, as this determines the file name format.
      ELSE
         CALL PSX_UNAME( SYSNAM, DUM1, DUM2, DUM3, DUM4, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            CALL CHR_UCASE( SYSNAM )

*  If we are on VMS, then search for a ']' or '>' character, which may
*  mark the end of an explicit directory specification (note the latter
*  may result if a file name is entered on a DCL command line).
            IF ( INDEX( SYSNAM, 'VMS' ) .NE. 0 ) THEN
               IEND = INDEX( NAME( F : L ), ']' )
               IF ( IEND .EQ. 0 ) IEND = INDEX( NAME( F : L ), '>' )

*  If there is no explicit directory reference, then search for a ':'
*  which may mark the end of a logical name representing the directory.
*  Also search for a '('. The ':' can be used only if it occurs before
*  the '(', otherwise it is part of a subscript expression.
               IF ( IEND .EQ. 0 ) THEN
                  I1 = INDEX( NAME( F : L ), ':' )
                  I2 = INDEX( NAME( F : L ), '(' )
                  IF ( ( I2 .EQ. 0 ) .OR. ( I1 .LT. I2 ) ) IEND = I1
               END IF

*  Correct for the starting position of the search.
               IEND = IEND + F - 1

*  If we are not on VMS, then assume POSIX file name format. Search for
*  the last '/' character which delimits the final field of the file's
*  path name.
            ELSE
               DO 1 IEND = L, F, -1
                  IF ( NAME( IEND : IEND ) .EQ. '/' ) GO TO 2
 1             CONTINUE
 2             CONTINUE              
            END IF

*  Having located the end of the directory specification (if any), now
*  search for a '.' or a '(' which marks the end of the first field in
*  the object path name.
            IF ( IEND .LT. L ) THEN
               I1 = INDEX( NAME( IEND + 1 : L ), '.' )
               I2 = INDEX( NAME( IEND + 1 : L ), '(' )
               IF ( ( I1 .EQ. 0 ) .OR.
     :              ( ( I2 .NE. 0 ) .AND. ( I2 .LT. I1 ) ) ) THEN
                  I1 = I2
               END IF

*  If no such terminating character exists, then use the whole name
*  string as the file name. Otherwise, select the first path name field
*  for use as the file name.
               IF ( I1 .EQ. 0 ) THEN
                  IEND = L
               ELSE
                  IEND = IEND + I1 - 1
               END IF
            END IF

*  If a '.' occurs in the first character position, then report an
*  error.
            IF ( IEND .LT. F ) THEN
               STATUS = NDF__NAMIN
               CALL MSG_SETC( 'NAME', NAME( F : L ) )
               CALL ERR_REP( 'NDF1_HSPLT_MSF',
     :                       'Missing field in the NDF name ''^NAME''.',
     :                       STATUS )

*  Otherwise, note the file name position, omitting any trailing
*  blanks.
            ELSE
               F1 = F
               F2 = F1 + CHR_LEN( NAME( F : IEND ) ) - 1
            END IF

*  If no errors have occurred, then attempt to locate the path name
*  string.
            IF ( STATUS .EQ. SAI__OK ) THEN

*  If the file name extends to the end of the object name string, then
*  there is no path name (i.e. it is a top-level object), so return
*  a "null" position.
               IF ( IEND .GE. L ) THEN
                  P1 = 1
                  P2 = 0

*  Otherwise, eliminate any leading blanks from the candidate path name
*  which follows the file name and return the path name limits.
               ELSE
                  CALL CHR_FANDL( NAME( IEND + 1 : L ), ISTART, L )
                  P1 = ISTART + IEND
                  P2 = L + IEND
               END IF
            END IF
         END IF
      END IF

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_HSPLT', STATUS )

      END
