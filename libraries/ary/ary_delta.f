      SUBROUTINE ARY_DELTA( IARY1, ZAXIS, TYPE, MINRAT, PLACE, ZRATIO,
     :                      IARY2, STATUS )
*+
*  Name:
*     ARY_DELTA

*  Purpose:
*     Compress an array using delta compression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARY_DELTA( IARY1, ZAXIS, TYPE, MINRAT, PLACE, ZRATIO, IARY2,
*                     STATUS )

*  Description:
*     The routine creates a copy of the supplied array stored in DELTA form,
*     which provides a lossless compression scheme for integer data. This
*     scheme assumes that adjacent integer values in the input array tend
*     to be close in value, and so differences between adjacent values can
*     be represented in fewer bits than the absolute values themselves.
*     The differences are taken along a nominated pixel axis within the
*     supplied array (specified by argument ZAXIS).
*
*     In practice, the scheme is limited currently to representing differences
*     between adjacent values using a HDS integer data type (specified by
*     argyument TYPE) - that is, arbitrary bit length is not yet supported.
*     So for instance an _INTEGER input array can be compressed by storing
*     differences as _WORD or _BYTE values, but a _WORD input array can only
*     be compressed by storing differences as _BYTE values.
*
*     Any input value that differs from its earlier neighbour by more than
*     the data range of the selected data type is stored explicitly using
*     the data type of the input array.
*
*     Further compression is achieved by replacing runs of equal input values
*     by a single occurrence of the value with a correspsonding repetition
*     count.
*
*     It should be noted that the degree of compression achieved is
*     dependent on the nature of the data, and it is possible for the
*     compressed array to occupy more space than the uncompressed array.
*     The compression factor actually achieved is returned in argument
*     ZRATIO (the ratio of the supplied array size to the compressed
*     array size). A minmum allowed compression ratio may be specified via
*     argument MINRAT. If the compression ratio is less than this value,
*     then the supplied array is left unchanged.

*  Arguments:
*     IARY1 = INTEGER (Given)
*        The input array identifier. An error is reported if the array is
*        already stored in DELTA form. Note, if the array is a SCALED array,
*        the internal integer values are compressed and the scale and zero
*        terms are stored in the compressed array.
*     ZAXIS = INTEGER (Given)
*        The index of the pixel axis along which differences are to be
*        taken. If this is zero, a default value will be selected that
*        gives the greatest compression. An error will be reported if a
*        value less than zero or greater than the number of axes in the
*        input array is supplied.
*     TYPE = CHARACTER * ( * ) (Given)
*        The data type in which to store the differences between adjacent
*        input values. This must be one of '_BYTE', '_WORD' or
*        '_INTEGER'. Additionally, a blank string may be supplied in which
*        case a default value will be selected that gives the greatest
*        compression.
*     MINRAT = REAL (Given)
*        The minimum allowed ZRATIO value. If compressing the input array
*        results in a ZRATIO value smaller than or equal to MINRAT, then
*        the supplied array is left unchanged. If the supplied value is
*        zero or negative, then the array will be compressed regardless of
*        the compression ratio.
*     PLACE = INTEGER (Given and Returned)
*        An array placeholder (e.g. generated by the ARY_PLACE routine)
*        which indicates the position in the data system where the new
*        array will reside. The placeholder is annulled by this
*        routine, and a value of ARY__NOPL will be returned (as defined
*        in the include file ARY_PAR).
*     ZRATIO = REAL (Returned)
*        The compression factor actually achieved (the ratio of the
*        supplied array size to the compressed array size). Genuine
*        compressions are represented by values more than 1.0, but values
*        less than 1.0 may be returned if the input data is not suited
*        to delta compression (i.e. if the "compression" actually expands
*        the array storage). Note, the returned value of ZRATIO may be
*        smaller than MINRAT, in which case the supplied array is left
*        unchanged. The returned compression factor is approximate as it
*        does not take into account the space occupied by the HDS metadata
*        describing the extra components of a DELTA array (i.e. the
*        component names, data types, dimensions, etc). This will only be
*        significant for very small arrays.
*     IARY2 = INTEGER (Returned)
*        Identifier for the new DELTA array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - The compression axis and compressed data type actually used can
*     be determined by passing the returned array to ARY_GTDLT.
*     -  This routine may only be used to compress a base array. If it is
*     called with an array which is not a base array, then it will return
*     without action. No error will result.
*     -  An error will result if the array, or any part of it, is
*     currently mapped for access (e.g. through another identifier).
*     -  An error will result if the array holds complex values.

*  Copyright:
*     Copyright (C) 2010 Science & Technology Facilities Council.
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
*     DSB: David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-OCT-2010 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'PRM_PAR'          ! VAL_ public constants
      INCLUDE 'ARY_PAR'          ! ARY_ public constants
      INCLUDE 'ARY_ERR'          ! ARY_ error constants
      INCLUDE 'ARY_CONST'        ! ARY_ private constants

*  Global Variables:
      INCLUDE 'ARY_DCB'          ! ARY_ Data Control Block
      INCLUDE 'ARY_ACB'          ! ARY_ Access Control Block
      INCLUDE 'ARY_PCB'          ! ARY_ Placeholder Control Block

*  Arguments Given:
      INTEGER IARY1
      INTEGER ZAXIS
      CHARACTER TYPE*(*)
      REAL MINRAT

*  Arguments Given and Returned:
      INTEGER PLACE

*  Arguments Returned:
      REAL ZRATIO
      INTEGER IARY2

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER CLOC*(DAT__SZLOC)! Locator for component
      CHARACTER NAME*(DAT__SZNAM)! Name of component
      CHARACTER TYPES( 3 )*( DAT__SZTYP ) ! Supported compressed data types
      INTEGER IACB1              ! Index to input array entry in the ACB
      INTEGER IACB2              ! Index to output array entry in the ACB
      INTEGER ICOMP              ! Component index
      INTEGER IDCB1              ! Index to input array entry in the DCB
      INTEGER IDCB2              ! Index to output array entry in the DCB
      INTEGER IPCB               ! Index to placeholder entry in the PCB
      INTEGER NCOMP              ! Component count
      INTEGER NDIM               ! Number of axes in supplied array
      INTEGER ZAX                ! Current compression axis
      INTEGER ZAXHI              ! Highest compression axis to test
      INTEGER ZAXLO              ! Lowest compression axis to test
      INTEGER ZAXUSE             ! Best compression axis
      INTEGER ZTY                ! Current compressed data type
      INTEGER ZTYHI              ! Highest compressed data type to test
      INTEGER ZTYLO              ! Lowest compressed data type to test
      INTEGER ZTYUSE             ! Best compressed data type
      LOGICAL ERASE              ! Whether to erase placeholder object
      REAL RATIO                 ! Compression ratio for current combination

      LOGICAL VALID


      DATA TYPES /'_BYTE', '_WORD', '_INTEGER' /
*.

*  Check inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Import the input array identifier.
      CALL ARY1_IMPID( IARY1, IACB1, STATUS )

*  Check it is safe to index an array.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Obtain an index to the input data object entry in the DCB and ensure
*  that storage form, data type and bounds information is available for it.
      IDCB1 = ACB_IDCB( IACB1 )
      CALL ARY1_DFRM( IDCB1, STATUS )
      CALL ARY1_DTYP( IDCB1, STATUS )
      CALL ARY1_DBND( IDCB1, STATUS )

*  Get the number of axes in the input array.
      NDIM = DCB_NDIM( IDCB1 )

*  Report an error if the array holds complex values.
      IF( DCB_CPX( IDCB1 ) .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = ARY__FRMCV
         CALL DAT_MSG( 'ARRAY', DCB_LOC( IDCB1 ) )
         CALL ERR_REP( 'ARY_DELTA_CPX', 'The array ^ARRAY holds '//
     :                 'complex values (possible programming '//
     :                 'error).', STATUS )
         GO TO 999
      END IF

*  Report an error if the ZAXIS value is wrong.
      IF( ( ZAXIS .LT. 0 .OR. ZAXIS .GT. NDIM ) .AND.
     :     STATUS .EQ. SAI__OK ) THEN
         STATUS = ARY__DIMIN
         CALL MSG_SETI( 'Z', ZAXIS )
         CALL MSG_SETI( 'N', NDIM )
         CALL ERR_REP( 'ARY_DELTA_DIM', 'Compression axis ^Z is'//
     :                 ' invalid - it should be in the range 1 '//
     :                 'to ^N (possible programming error).',
     :                 STATUS )
         GO TO 999
      END IF

*  Check the supplied TYPE. Report an error if it is not a signed integer
*  type, or blank.
      IF( TYPE .NE. '_INTEGER' .AND. TYPE .NE. '_WORD' .AND.
     :    TYPE .NE. '_BYTE' .AND. TYPE .NE. ' ' .AND.
     :    STATUS .EQ. SAI__OK ) THEN
         STATUS = ARY__TYPIN
         CALL MSG_SETC( 'T', TYPE )
         CALL ERR_REP( 'ARY_DELTA_DIM', 'Illegal compressed '//
     :                 'data type ''^T'' - (possible programming '//
     :                 'error).', STATUS )
         GO TO 999
      END IF

*  Check if the data object is mapped for access. Report an error if it is.
      IF( ( DCB_NWRIT( IDCB1 ) .NE. 0 ) .OR.
     :     ( DCB_NREAD( IDCB1 ) .NE. 0 ) .AND.
     :     STATUS .EQ. SAI__OK ) THEN
         STATUS = ARY__ISMAP
         CALL DAT_MSG( 'ARRAY', DCB_LOC( IDCB1 ) )
         CALL ERR_REP( 'ARY_DELTA_MAP', 'The array ^ARRAY is '//
     :                 'mapped for access, perhaps through '//
     :                 'another identifier (possible programming '//
     :                 'error).', STATUS )
         GO TO 999
      END IF

*  If the array is already compressed, report an error.
      IF( DCB_FRM( IDCB1 ) .EQ. 'DELTA' .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = ARY__FRMCV
         CALL DAT_MSG( 'ARRAY', DCB_LOC( IDCB1 ) )
         CALL ERR_REP( 'ARY_DELTA_DLT', 'The array ^ARRAY '//
     :                 'is already compressed.', STATUS )
         GO TO 999
      END IF

*  Import the array placeholder, converting it to a PCB index.
      IPCB = 0
      CALL ARY1_IMPPL( PLACE, IPCB, STATUS )

*  Do nothing if the array is not a base array.
      IF( .NOT. ACB_CUT( IACB1 ) .AND. STATUS .EQ. SAI__OK ) THEN

*  Create a new simple array structure in place of the placeholder
*  object, obtaining a DCB entry which refers to it. Creation of the
*  primitive array is deferred since we do not yet know how big it will need
*  to be.
         CALL ARY1_DCRE( .TRUE., DCB_TYP( IDCB1 ), DCB_CPX( IDCB1 ),
     :                   ACB_NDIM( IACB1 ), ACB_LBND( 1, IACB1 ),
     :                   ACB_UBND( 1, IACB1 ), PCB_TMP( IPCB ),
     :                   PCB_LOC( IPCB ), IDCB2, STATUS )

*  Erase all components within the data object - they will be re-created
*  in compressed form by ARY1_S2DLT.
         CALL DAT_NCOMP( DCB_LOC( IDCB2 ), NCOMP, STATUS )
         DO ICOMP = 1, NCOMP
            CALL DAT_INDEX( DCB_LOC( IDCB2 ), ICOMP, CLOC, STATUS )
            CALL DAT_NAME( CLOC, NAME, STATUS )
            CALL DAT_ANNUL( CLOC, STATUS )
            CALL DAT_ERASE( DCB_LOC( IDCB2 ), NAME, STATUS )
         END DO

*  If explicit values have been supplied for both ZAXIS and TYPE, just do
*  the conversion.
         IF( ZAXIS .NE. 0 .AND. TYPE .NE. ' ' ) THEN
            CALL ARY1_S2DLT( DCB_LOC( IDCB1 ), ZAXIS, TYPE,
     :                       DCB_LOC( IDCB2 ), ZRATIO, STATUS )

*  Otherwise, we test to see what combination of ZAXIS and TYPE gives the
*  best compression, and then compress using that ZAXis and TYPE.
         ELSE

*  Determine the range of ZAXIS to test.
            IF( ZAXIS .EQ. 0 ) THEN
               ZAXLO = 1
               ZAXHI = NDIM
            ELSE
               ZAXLO = ZAXIS
               ZAXHI = ZAXIS
            END IF

*  Determine the list of compressed data types to test.
            IF( TYPE .EQ. '_BYTE' ) THEN
               ZTYLO = 1
               ZTYHI = 1
            ELSE IF( TYPE .EQ. '_WORD' ) THEN
               ZTYLO = 2
               ZTYHI = 2
            ELSE IF( TYPE .EQ. '_INTEGER' ) THEN
               ZTYLO = 3
               ZTYHI = 3
            ELSE IF( DCB_TYP( IDCB1 ) .EQ. '_INTEGER' ) THEN
               ZTYLO = 1
               ZTYHI = 3
            ELSE IF( DCB_TYP( IDCB1 ) .EQ. '_WORD' ) THEN
               ZTYLO = 1
               ZTYHI = 2
            ELSE
               ZTYLO = 1
               ZTYHI = 1
            END IF

*  Initialise the best compression found so far.
            ZRATIO = VAL__MINR

*  Loop round all ZAXIS values
            DO ZAX = ZAXLO, ZAXHI

*  Loop round all compressed data types.
               DO ZTY = ZTYLO, ZTYHI

*  See how much compression could be expected using this combination of
*  compression axis and data type.
                  CALL ARY1_S2DLT( DCB_LOC( IDCB1 ), ZAX, TYPES( ZTY ),
     :                             ARY__NOLOC, RATIO, STATUS )

*  Record the current compresson axis and type if this combination gives
*  more compression than any other combination tested so far.
                  IF( RATIO .GT. ZRATIO ) THEN
                     ZRATIO = RATIO
                     ZAXUSE = ZAX
                     ZTYUSE = ZTY
                  END IF

               END DO
            END DO

*  Now do the compression using the best combination.
            CALL ARY1_S2DLT( DCB_LOC( IDCB1 ), ZAXUSE, TYPES( ZTYUSE ),
     :                       DCB_LOC( IDCB2 ), ZRATIO, STATUS )
         END IF

*  If all went well, store the new storage form in the DCB.
         IF( STATUS .EQ. SAI__OK ) THEN
            DCB_FRM( IDCB2 ) = 'DELTA'

*  Obtain a locator to the non-imaginary data component to the new array.
            CALL DAT_FIND( DCB_LOC( IDCB2 ), 'DATA', DCB_DLOC( IDCB2 ),
     :                     STATUS )

*  Indicate state information is out of date.
            DCB_KSTA( IDCB2 ) = .FALSE.

*  Create a base array entry in the ACB to refer to the output DCB entry.
            CALL ARY1_CRNBA( IDCB2, IACB2, STATUS )

*  Export an identifier for the output array.
            CALL ARY1_EXPID( IACB2, IARY2, STATUS )

*  If an error occurred, then annul the new ACB entry and reset the
*  IACB2 argument to zero.
            IF ( ( STATUS .NE. SAI__OK ) .AND. ( IACB2 .NE. 0 ) ) THEN
               CALL ARY1_ANL( IACB2, STATUS )
               IACB2 = 0
            END IF

         END IF
      END IF

*  Arrive here if an error occurrs.
 999  CONTINUE

*  Annul the placeholder, erasing the associated object if any error has
*  occurred or if the compression was not high enough.
      IF( IPCB .NE. 0 ) THEN
         ERASE = ( STATUS .NE. SAI__OK ) .OR.
     :           ( ZRATIO .LE. MINRAT .AND. MINRAT .GT. 0.0 )
         CALL ARY1_ANNPL( ERASE, IPCB, STATUS )
      END IF

*  Reset the PLACE argument.
      PLACE = ARY__NOPL

*  If an error occurred, then report context information and call the
*  error tracing routine.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ARY_DELTA_ERR', 'ARY_DELTA: Error compressing'//
     :                 ' an array using delta compression.', STATUS )
         CALL ARY1_TRACE( 'ARY_DELTA', STATUS )
      END IF

      END
