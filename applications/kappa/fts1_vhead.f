      SUBROUTINE FTS1_VHEAD( BUFFER, FIXED, CARD, STATUS )
*+
*  Name:
*     FTS1_VHEAD

*  Purpose:
*     Validates a FITS header card and reconstitutes to the standard.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL FTS1_VHEAD( BUFFER, FIXED, CARD, STATUS )

*  Description:
*     This routines takes a buffer containing text similar to a FITS
*     header card and attempts to produce a correctly formatted FITS
*     header card.  The validation process performs the following
*     checks the input buffer:
*       a) the length of the input buffer is no more than 80
*       characters, otherwise it is truncated;
*       b) the keyword only contains uppercase Latin alphabetic
*       characters, numbers, underscore, and hyphen (this is a fatal
*       error except for lowercase letters);
*       c) value cards have an equals sign in column 9 and a space in
*       column 10;
*       d) quotes enclose character values;
*       e) single quotes inside string values are doubled;
*       f) character values are left justified to column 11 (retaining
*       leading blanks) and contain at least 8 characters (padding with
*       spaces if necessary);
*       g) non-character values are right justified to column 30 for
*       mandatory keywords, or when the fixed format is requested
*       (unless the value is double-precision requiring more than 20
*       digits);
*       h) the comment delimiter is in column 32 for the mandatory
*       keywords or when the fixed format is requested for non-character
*       values, or is at least two characters following the value
*       otherwise;
*       i) an equals sign in column 9 of a commentary card is replaced
*       by a space, issuing a warning message at normal reporting
*       level; and
*       j) comments begin at least two columns after the end of the
*       comment delimiter.
*
*     Some non-fatal errors---a), b), c), d), and i)---produce warning
*     messages at message level MSG__NORM.

*  Arguments:
*     BUFFER = CHARACTER * ( * ) (Given)
*        The FITS header 'card' to be validated.
*     FIXED = LOGICAL (Given)
*        If this is .TRUE., all values use the FITS fixed format with
*        left-justified character strings starting two columns after
*     CARD = CHARACTER * ( 80 ) (Returned)
*        The validated FITS header 'card'.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1994 September 8 (MJC):
*        Original version.
*     1996 July 26 (MJC):
*        Distinguish between mandatory and other keywords for
*        non-character values.   Add the FIXED argument.
*     21-MAR-2000 (DSB):
*        Modified to retain trailing spaces within string values.
*        Fixed bug which caused random character strings to be used as
*        comments for string keywords if no comment was supplied in the header.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MSG_PAR'          ! Message constants

*  Arguments Given:
      CHARACTER * ( * ) BUFFER
      LOGICAL FIXED

*  Arguments Returned:
      CHARACTER * ( 80 ) CARD

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Length of string less trailing blanks

*  Local Constants:
      INTEGER COMILN             ! Maximum length of a FITS inline
                                 ! comment
      PARAMETER ( COMILN = 69 )

      INTEGER CFIXED             ! Standard column to which to right
                                 ! justify values for fixed format
      PARAMETER ( CFIXED = 30 )

      INTEGER COMPOS             ! Standard column of the comment
                                 ! delimiter
      PARAMETER ( COMPOS = CFIXED + 2 )

      INTEGER FITSLN             ! Length of a FITS card image
      PARAMETER ( FITSLN = 80 )

      INTEGER KEYLN              ! Maximum length of a FITS keyword
      PARAMETER ( KEYLN = 8 )

      INTEGER MINFCV             ! Minimum number of characters in a
                                 ! FITS character value
      PARAMETER( MINFCV = 8 )

      INTEGER VALLN              ! Maximum length of a FITS value
      PARAMETER ( VALLN = 70 )

*  Local Variables:
      CHARACTER * ( VALLN ) CDUMMY ! Work string for value
      INTEGER CLEN               ! String length
      INTEGER COLEQS             ! Character pointer to the equals sign
      INTEGER CPOS               ! Integer pointer for appending
                                 ! right-justified non-character values 
      INTEGER CSTAT              ! Status value in CHR calls
      INTEGER ENDW               ! Column position of the end of the
                                 ! header value (w.r.t. = sign)
      CHARACTER * ( COMILN ) FITCOM ! FITS comment
      CHARACTER * ( VALLN ) FITDAT ! FITS value
      CHARACTER * ( KEYLN ) FITNAM ! FITS keyword
      INTEGER IVAL               ! Holds integer value
      INTEGER LSTAT              ! Local status
      LOGICAL LVAL               ! Value of a logical FITS item
      LOGICAL MANDAT             ! Keyword is mandatory?
      INTEGER NCBUFF             ! Number of characters in input card
      INTEGER NCC                ! Column of FITS comment delimiter
      INTEGER NCCOM              ! Number of characters in FITS
                                 ! COMMENT or HISTORY card
      INTEGER NCCQ               ! Column of FITS trailing quote for
                                 ! character value
      INTEGER NCCQ2              ! Column of FITS trailing quote for
                                 ! character value (work variable)
      INTEGER NCDQ               ! Column of FITS double quote for
                                 ! character value
      INTEGER NCFD               ! Column position in output FITS
                                 ! character value (final double quote)
      INTEGER NCFS               ! Column position in output FITS
                                 ! character value (final single quote)
      INTEGER NCOMS              ! Column from where to start search
                                 ! for FITS comment delimiter
      INTEGER NCSQ               ! Column of FITS single quote for
                                 ! character value
      INTEGER NCSTQ              ! Column from where to start search
                                 ! for a trailing quote for a FITS
                                 ! character value
      INTEGER NWORD              ! Number of words in value (fixed at 1)
      REAL RVAL                  ! Holds real value
      INTEGER STARTW             ! Column position of the start of the
                                 ! header value (w.r.t. = sign)
      LOGICAL TRAILQ             ! True when value has a trailing quote
      LOGICAL VALDEF             ! True if the value is defined
      LOGICAL VALID              ! True when a FITS header is valid
      LOGICAL VALKEY             ! True if the keyword is valid

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the validated card.
      CARD = ' '
      VALID = .TRUE.

*  Validate the length of the card.
*  ================================

*  Get the length excluding trailing blanks.
      NCBUFF = CHR_LEN( BUFFER )

*  The effective length must be no longer than the mandatory length of a
*  FITS header card.  Issue a warning, but continue, truncating the
*  text.
      IF ( NCBUFF .GT. FITSLN ) THEN
         VALID = .FALSE.
         CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_LONG',
     :     'Header line contains more than 80 characters' , STATUS )
      END IF

*  The bulk of the routine follows.  It extracts the various components
*  of the FITS card image, so that they can be reconstituted into a
*  valid card.

*  Extract and validate the keyword.
*  =================================

*  First 8 characters contain the keyword.
      FITNAM = BUFFER( 1:KEYLN )

*  Look for a blank keyword.  Copy the blank card image to the validated
*  card.
      IF ( FITNAM .EQ. ' ' ) THEN
         CARD = BUFFER

      ELSE IF ( FITNAM .EQ. 'END     ' ) THEN

*  Check that the END card does not contain superfluous text.
         IF ( BUFFER( 9:80 ) .NE. ' ' ) THEN

*  Report the error and go to the next record of the translation table.
            STATUS = SAI__ERROR
            CALL ERR_REP( 'FTS1_VHEAD_ENDEXTRA',
     :        'The END keyword ^KEY includes superfluous characters, '/
     :        /'thereby violating the FITS standard.', STATUS )
               GOTO 999

*  There is nothing else to parse for the END card.
         ELSE
             CARD = BUFFER

         END IF

      ELSE

*  Assume that the keyword is in columns 1 to 8.  It would involve lots
*  of unwarranted and complex parsing to cope without that assumption.
*  Of course, the user may have put in a leading space or removed a
*  trailing space that they may feel this should handle, however, it
*  should be clear from the error message that there is something wrong
*  with the keyword or position of the equals sign.

*  Validate the keyword.
         CALL FTS1_ISKEY( FITNAM, VALKEY, STATUS )
         IF ( .NOT. VALKEY ) THEN

*  Store a message token for the error report or warning message, before
*  the keyword is converted to uppercase.
            CALL MSG_SETC( 'KEY', FITNAM )

*  Make an uppercase copy of the keyword, as we may be able to continue
*  using this and only give a warning.
            CALL CHR_UCASE( FITNAM )
            CALL FTS1_ISKEY( FITNAM, VALKEY, STATUS )

            IF ( .NOT. VALKEY ) THEN

*  Report the error and go to the next record of the translation table.
               STATUS = SAI__ERROR
               CALL ERR_REP( 'FTS1_VHEAD_INVKEY',
     :           'The keyword ^KEY includes characters other than '/
     :           /'numbers, uppercase letters, hyphen, and underscore '/
     :           /'thereby violating the FITS standard.', STATUS )
               GOTO 999

*  Use the uppercase keyword, but issue a warning.
            ELSE
               VALID = .FALSE.
               CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_LOCASE',
     :           'The keyword ^KEY contained invalid lowercase '/
     :           /'alphabetic characters.', STATUS )
            END IF
         END IF

*  Deal with the special case of COMMENT and HISTORY keywords.
         IF ( FITNAM .EQ. 'HISTORY' .OR.
     :        FITNAM .EQ. 'COMMENT' ) THEN

*  Locate the first equals sign.
            COLEQS = INDEX( BUFFER, '=' )

*  If the equals sign is column 9, it is bad practice so remove it.
            IF ( COLEQS .EQ. KEYLN + 1 ) THEN
               VALID = .FALSE.
               CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_COMEQS',
     :           'The commentary has a value.  Removed the offending '/
     :           /'equals sign.', STATUS )
               CARD = FITNAM//' '//BUFFER( 10: )
            ELSE
               CARD = BUFFER
            END IF
         ELSE

*  The value is not defined yet.
            VALDEF = .FALSE.

*  Locate the first equals sign.
            COLEQS = INDEX( BUFFER, '=' )

*  If the equals sign is absent, insert one.
            IF ( COLEQS .EQ. 0 ) THEN
               VALID = .FALSE.
               CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_NOEQS',
     :           'The header card has no equals sign.', STATUS )
               COLEQS = 9

*  Report if the equals sign is misplaced.
            ELSE IF ( COLEQS .NE. 9 ) THEN
               VALID = .FALSE.
               CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_MISPLEQS',
     :           'The header card has a misplaced value.', STATUS )

            ELSE IF ( BUFFER( COLEQS+1:COLEQS+1 ) .NE. ' ' ) THEN
               VALID = .FALSE.
               CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_NOEQSPACE',
     :           'The header card has no space following the equals '/
     :           /'sign.', STATUS )

            END IF

*  Determine whether the keyword is mandatory.  Need to converted
*  columns 6 to 8 to see if it is an integer for the NAXISn keyword.
            CSTAT = 0
            CALL CHR_CTOI( FITNAM( 6:8 ), IVAL, CSTAT )
            MANDAT = FITNAM .EQ. 'SIMPLE' .OR. FITNAM .EQ. 'END' .OR.
     :               FITNAM .EQ. 'NAXIS' .OR.
     :               ( FITNAM( 1:5 ) .EQ. 'NAXIS' .AND. CSTAT .EQ. 0 )

*  Copy the buffer from the equals sign and remove the leading blanks.
            CDUMMY = BUFFER( COLEQS + 1: )
            CALL CHR_LDBLK( CDUMMY )

*  Columns of 11:30 should contain FITS item value if numeric or
*  logical.  Character values may extend to column 80.  Column 10
*  should be a space immediately following the equals sign.  To protect
*  against non-fatal errors in the input buffer this coding should
*  allow for additional or no spaces between the value and equals sign.
*  Search for the leading quote.
            IF ( CDUMMY( 1:1 ) .EQ. '''' ) THEN

*  Initialise the character value.
               FITDAT = ' '

*  Determine where the initial quote is located.
*  =============================================
               NCSTQ = INDEX( BUFFER( COLEQS+1: ), '''' ) + COLEQS

*  Determine where the trailing quote is located.
*  ==============================================

*  First look for any double quotes.  These mean a single quote, so
*  O'Hara appears as O''Hara in a FITS card image.  Start the search
*  immediately after the leading quote, and subsequently immediately
*  following a double quote.  Prevent the search extending beyond the
*  end of the value.  Keep a count of the absolute column.  Enclosed
*  quotes that should be double but are single will be tested for
*  later.
               NCDQ = 1
               NCFD = 1
               NCSTQ = NCSTQ + 1
               DO WHILE ( NCDQ .NE. 0 )
                  NCDQ = INDEX( BUFFER( NCSTQ: ), '''''' )

*  If there is no double quote no action is necessary.  When there is,
*  we form part of the value, removing the second quote.
                  IF ( NCDQ .GT. 0 ) THEN
                     FITDAT( NCFD: NCFD + NCDQ ) =
     :                       BUFFER( NCSTQ: NCSTQ + NCDQ )

*  Increment the counter to where to append to the value.
                     NCFD = NCFD + NCDQ

*  Increment the counter in the FITS card, skipping over the double
*  quote.
                     NCSTQ = NCSTQ + NCDQ + 1
                  END IF
               END DO

*  We need some method for detecting single quotes within the string.
*  Any that lie before the last correctly doubled quote will be in the
*  string.  The single quotes get doubled later.  The following
*  algorithm is far from foolproof, but it will catch some errors in
*  the input card.
*
*  The method assumes that the next slash will be a comment rather than
*  literal text in the string.  Find the location of the comment
*  delimiter.  Start just before the normal position just in case some
*  characters have been removed before it, but not too far in case we
*  confuse a slash in the value with the comment delimiter when there
*  is no closing quote.  When there is no comment delimiter, the search
*  for the closing quote continues to the end of the card.  Specify the
*  position of the notional closing quote.
               NCCOM = INDEX( BUFFER( MAX( COMPOS - 3, NCSTQ ): ), '/' )
               IF ( NCCOM .EQ. 0 ) THEN
                  NCCOM = FITSLN
                  NCCQ2 = FITSLN
               ELSE
                  NCCOM = MAX( COMPOS - 3, NCSTQ ) + NCCOM - 1
                  NCCQ2 = NCCOM - 2
               END IF

*  Find any quotes after the last double-quote, or the initial quote.
*  The last of these is taken to be the actual final quote, and earlier
*  single quotes in the single as part of the string.
               NCCQ = 1
               NCFS = 1
               TRAILQ = .FALSE.
               DO WHILE ( NCCQ .NE. 0 )
                  NCCQ = INDEX( BUFFER( NCSTQ:NCCOM ), '''' )

*  If there is no single quote no action is necessary.  When there is,
                  IF ( NCCQ .GT. 0 ) THEN

*  Record the trailing quote and its position.
                     TRAILQ = .TRUE.

*  Append the remainder or all of the value (the latter when there is
*  no double quote in the FITS card image) to the value, and including
*  the quote.  If it is the last quote, later it will be removed from
*  the value.
                     FITDAT( NCFD:NCFD + NCCQ - 1 ) =
     :                       BUFFER( NCSTQ:NCSTQ + NCCQ - 1 )

*  Increment the counter to where to append to the value.
                     NCFD = NCFD + NCCQ

*  Increment the counter in the FITS card, skipping over the single
*  quote.
                     NCSTQ = NCSTQ + NCCQ

                  END IF
               END DO

*  Extract the character value.
*  ============================

*  There is no trailing quote so assume that the character value
*  extends to the end of the card image.  Copy the value.
               IF ( .NOT. TRAILQ ) THEN
                  FITDAT = BUFFER( NCSTQ:NCCQ2 )

*  Assign the position of the closing quote.
                  NCCQ = NCCQ2 + 2
               ELSE
                  NCCQ = NCSTQ - 1

*  Remove the trailing quote from the value.
                  FITDAT( NCFD-1:NCFD-1 ) = ' '
               END IF

*  The value is defined.
               VALDEF = .TRUE.

*  Make NCFD hold the original length of the FITSDAT string (including
*  any trailing spaces which were included inside the delimiting quotes).
               NCFD = NCFD - 2

*  Define the column from which to look for a comment, i.e. one column
*  after the trailing quote.
               NCOMS = MIN( COMPOS - 2, NCCQ + 1 )

*  Extract string containing the non-character value.
*  ==================================================

*  Extracting the value is more straightforward for other types.
            ELSE

*  Select the first word following the equals sign.  Ignore the local
*  status as there will usually be a comment following, and we only
*  want the (non-complex) value.
               CALL CHR_DCWRD( BUFFER( COLEQS + 1: ), 1, NWORD,
     :                         STARTW, ENDW, FITDAT, LSTAT )

*  Allow for any trailing comment delimiter abutted to the value by
*  setting the value to blanks from this point in the extract word.
*  The column positions are with respect to the equals sign.
               NCC = INDEX( FITDAT, '/' )
               IF ( NCC .EQ. 0 ) THEN
                  NCOMS = ENDW + 1

               ELSE
                  FITDAT( NCC: ) = ' '
                  NCOMS = NCC + STARTW

               END IF

*  Shift the origin of the character pointer used to start the search
*  for the comment to the start of the whole header.
               NCOMS = NCOMS + COLEQS

            END IF

*  Extract the comment.
*  ====================

*  Look for the comment delimiter character---slash.
            NCC = INDEX( BUFFER( NCOMS: ), '/' ) + NCOMS - 1
            IF ( NCC .EQ. NCOMS - 1 ) THEN
               FITCOM = ' '

*  Deal with the special case of a comment delimiter, but no comment.
            ELSE IF ( CHR_LEN( BUFFER( NCC: ) ) .EQ. 1 ) THEN
               FITCOM = ' '

*  Extract the comment associated with the keyword.  Watch for a
*  leading space, which can be ignored.
            ELSE IF ( BUFFER( NCC+1:NCC+1 ) .EQ. ' ' ) THEN
               FITCOM = BUFFER( NCC+2: )
            ELSE
               FITCOM = BUFFER( NCC+1: )
            END IF

*  Find the type of the value.
*  ===========================

*  Although we have partially done this, i.e. located a character
*  value, there are naughty people who don't put the quotes about the
*  character value.  For these it is assumed that the value extends no
*  further than column 30 of the FITS card-image.

*  Double any single quotes in a string.
*  -------------------------------------

*  Look to see if it's already been identified as a string.
            IF ( VALDEF ) THEN

*  Any single quotes present in the string must be doubled.
*  Copy the value to a dummy string for expansion.
               CDUMMY = FITDAT( : NCFD )

*  Initialise the pointers.
               NCSQ = 1
               NCSTQ = 1
               NCFS = 1

*  Search for the single quotes.
               DO WHILE ( NCSQ .NE. 0 )
                  NCSQ = INDEX( CDUMMY( NCSTQ: ), '''' )

*  If there is no single quote no action is necessary.  When there is,
*  we form part of the value, adding the second quote.
                  IF ( NCSQ .GT. 0 ) THEN
                     FITDAT( NCFS: NCFS + NCSQ ) =
     :                       CDUMMY( NCSTQ: NCSTQ + NCSQ - 1 )//''''

*  Increment the counter to where to append to the value.
                     NCFS = NCFS + NCSQ + 1

*  Increment the length of the FITDAT string including trailing spaces.
                     NCFD = NCFD + 1

*  Increment the counter in the FITS card, skipping over the single
*  quote.
                     NCSTQ = NCSTQ + NCSQ

*  Fill the remainder of the value.
                  ELSE
                     FITDAT( NCFS: ) = CDUMMY( NCSTQ: )
                  END IF
               END DO

*  Write the output card for the character value.
*  ----------------------------------------------

*  Find the length of the string.  This must have at least the minimum
*  number of characters, even it is blank.
               NCCOM = MAX( MINFCV, NCFD )

*  Form the output card, enclosing the string in single quotes.  Do no
*  start the comment before a space after the closing quote or before
*  the standard position
               CARD = FITNAM//'= '''//FITDAT( :NCCOM )//''''
               IF( CHR_LEN( FITCOM ) .GT. 0 ) THEN
                  CPOS = MAX( COMPOS - 1, NCCOM + 13 )
                  CALL CHR_APPND( '/ '//FITCOM, CARD, CPOS )
               END IF
            ELSE

*  Other types:
*  ------------

*  Make a copy of the value.
               CDUMMY = FITDAT

*  Obtain the length of the value in characters removing leading and
*  trailing spaces.
               CALL CHR_LDBLK( CDUMMY )
               CLEN = CHR_LEN( CDUMMY )

*  Create the start of the FITS header.
               CARD = FITNAM//'= '

*  Define the column where the value is to start in the rewritten
*  header card.  Right justify the value to column 30 for the
*  fixed-format manadatory headers.  For other keywords just insert the
*  value as found but ensuring that the column following the equals
*  sign is a space.
               IF ( MANDAT .OR. FIXED ) THEN
                  CPOS = CFIXED - CLEN
               ELSE
                  CPOS = COLEQS + 1
               END IF

*  Check for an INTEGER.
*  ---------------------
               CSTAT = 0
               CALL CHR_CTOI( FITDAT, IVAL, CSTAT )
               IF ( CSTAT .EQ. 0 .AND. CLEN .GT. 0 ) THEN

*  Create the output card by appending the value and as much of the
*  comment as will fit into the header card.  Preserve the supplied
*  formatting when the the format is not fixed.
                  IF ( MANDAT .OR. FIXED ) THEN
                     CALL CHR_APPND( CDUMMY, CARD, CPOS )
                  ELSE
                     CALL CHR_APPND( FITDAT, CARD, CPOS )
                  END IF
                  IF( CHR_LEN( FITCOM ) .GT. 0 ) THEN
                     CALL CHR_APPND( ' / '//FITCOM, CARD, CPOS )
                  END IF
               ELSE

*  Check for a floating-point value.
*  ---------------------------------
                  CSTAT = 0
                  CALL CHR_CTOR( FITDAT, RVAL, CSTAT )
                  IF ( CSTAT .EQ. 0 .AND. CLEN .GT. 0 ) THEN

*  Even with fixed format allow for a double-precision value to be
*  displaced in full.
                     IF ( CLEN .GT. 20 .AND. FIXED ) CPOS = COLEQS + 1

*  Create the output card by appending the value and as much of the
*  comment as will fit into the header card.  Preserve the supplied
*  formatting when the the format is not fixed.
                     IF ( MANDAT .OR. FIXED ) THEN
                        CALL CHR_APPND( CDUMMY, CARD, CPOS )
                     ELSE
                        CALL CHR_APPND( FITDAT, CARD, CPOS )
                     END IF
                     IF( CHR_LEN( FITCOM ) .GT. 0 ) THEN
                        CALL CHR_APPND( ' / '//FITCOM, CARD, CPOS )
                     END IF
                  ELSE

*  Check for a logical.
*  --------------------

*  Note it should be a T or F in the header column 30 (20 in the data
*  value) for fixed-format.
                     CSTAT = 0
                     CALL CHR_CTOL( CDUMMY, LVAL, CSTAT )
                     IF ( CSTAT .EQ. 0 .AND. CLEN .GT. 0 ) THEN
                        CDUMMY = 'F'
                        IF ( LVAL ) CDUMMY = 'T'

*  Create the output card by appending the value and as much of the
*  comment as will fit into the header card.
                        CALL CHR_APPND( CDUMMY, CARD, CPOS )
                        IF( CHR_LEN( FITCOM ) .GT. 0 ) THEN
                           CALL CHR_APPND( ' / '//FITCOM, CARD, CPOS )
                        END IF

*  Unquoted string:
*  ----------------
                     ELSE

*  Assume it's just a character string without enclosing quotes.
*  Issue a warning that the quotes are missing.
                        VALID = .FALSE.
                        CALL MSG_OUTIF( MSG__NORM, 'FITS_VHEAD_NOQUOTE',
     :                    'The character value is not enclosed in '/
     :                    /'quotes.', STATUS )

*  Any single quotes present in the string must be doubled.

*  Initialise the pointers.
                        NCSQ = 1
                        NCSTQ = 1
                        NCFS = 1

*  Copy the value to a dummy string for expansion, retaining leading
*  blanks.
                        CDUMMY = FITDAT

*  Search for the single quotes.
                        DO WHILE ( NCSQ .NE. 0 )
                           NCSQ = INDEX( CDUMMY( NCSTQ: ), '''' )

*  If there is no single quote no action is necessary.  When there is,
*  we form part of the value, adding the second quote.
                           IF ( NCSQ .GT. 0 ) THEN
                              FITDAT( NCFS: NCFS + NCSQ ) =
     :                          CDUMMY( NCSTQ: NCSTQ + NCSQ - 1 )//''''

*  Increment the counter to where to append to the value.
                              NCFS = NCFS + NCSQ + 1

*  Increment the counter in the FITS card, skipping over the single
*  quote.
                              NCSTQ = NCSTQ + NCSQ

*  Fill the remainder of the value.
                           ELSE
                              FITDAT( NCFS: ) = CDUMMY( NCSTQ: )
                           END IF
                        END DO

*  Find the length of the string.  This must have at least the minimum
*  number of characters, even it is blank.
                        NCCOM = MAX( MINFCV, CHR_LEN( FITDAT ) )

*  Form the output card, enclosing the string in single quotes.  Do no
*  start the comment before a space after the closing quote or before
*  the standard position
                        CARD = FITNAM//'= '''//FITDAT( :NCCOM )//''''
                        IF( CHR_LEN( FITCOM ) .GT. 0 ) THEN
                           CPOS = MAX( COMPOS - 1, NCCOM + 13 )
                           CALL CHR_APPND( '/ '//FITCOM, CARD, CPOS )
                        END IF
                     END IF
                  END IF
               END IF
            END IF
         END IF
      END IF

*  Make a contextual message to go with the specific warning messages.
*  Add a blank line for easier reading of the separate warnings.
      IF ( .NOT. VALID ) THEN
         CALL MSG_SETC( 'CARD', BUFFER )
         CALL MSG_OUTIF( MSG__NORM, 'FTS1_VHEAD_INVCARD',
     :     'The invalid header was: "^CARD"', STATUS )
         CALL MSG_BLANK( STATUS )
      END IF

  999 CONTINUE

      END
