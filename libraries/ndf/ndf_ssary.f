      SUBROUTINE NDF_SSARY( IARY1, INDF, IARY2, STATUS )
*+
*  Name:
*     NDF_SSARY

*  Purpose:
*     Create an array section, using an NDF section as a template.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF_SSARY( IARY1, INDF, IARY2, STATUS )

*  Description:
*     The routine creates a "similar section" from an array (whose ARY_
*     system identifier is supplied) using an existing NDF section as a
*     template.  An identifier for the array section is returned and
*     this may subsequently be manipulated using the ARY_ system
*     routines (SUN/11).  The new array section will bear the same
*     relationship to its base array as the NDF template does to its
*     own base NDF.  Allowance is made for any pixel-index shifts which
*     may have been applied, so that the pixel-index system of the new
*     array section matches that of the NDF template.
*
*     This routine is intended for use when an array which must match
*     pixel-for-pixel with an NDF is stored in an NDF extension; if an
*     NDF section is obtained, then this routine may be used to obtain
*     a pixel-by-pixel matching section from the array.

*  Arguments:
*     IARY1 = INTEGER (Given)
*        The ARY_ system identifier for the array, or array section,
*        from which the new section is to be drawn.
*     INDF = INTEGER (Given)
*        NDF_ system identifier for the template NDF section (may also
*        be a base NDF).
*     IARY2 = INTEGER (Returned)
*        ARY_ system identifier for the new array section.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  This routine will normally generate an array section. However,
*     if the input array is a base array and the input NDF is a base
*     NDF with the same pixel-index bounds, then there is no need to
*     generate a section in order to access the required part of the
*     array. In this case, a base array identifier will be returned
*     instead.
*     -  It is the caller's responsibility to annul the ARY_ system
*     identifier issued by this routine (e.g. by calling ARY_ANNUL)
*     when it is no longer required. The NDF_ system will not perform
*     this task itself.
*     -  The new array generated by this routine will have the same
*     number of dimensions as the array from which it is derived. If
*     the template NDF has fewer dimensions, then the pixel-index
*     bounds of the extra array dimensions are preserved unchanged. If
*     the NDF has more dimensions, then the extra ones are ignored.
*     -  This routine takes account of the transfer windows of the
*     array and NDF supplied and will restrict the transfer window of
*     the new array section so as not to grant access to regions of the
*     base array which were not previously accessible through both the
*     input array and the NDF section.
*     -  If this routine is called with STATUS set, then a value of
*     ARY__NOID will be returned for the IARY2 argument, although no
*     further processing will occur. The same value will also be
*     returned if the routine should fail for any reason. The ARY__NOID
*     constant is defined in the include file ARY_PAR.

*  Algorithm:
*     -  Set an initial value of ARY__NOID for the IARY2 argument
*     before checking the inherited status.
*     -  Import the NDF identifier.
*     -  Obtain the array section using the NDF's data array as a
*     template.
*     -  If an error occurred, then report context information.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     8-DEC-1989 (RFWS):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants
      INCLUDE 'ARY_PAR'          ! ARY_ public constants

*  Global Variables:
      INCLUDE 'NDF_ACB'          ! NDF_ Access Control Block
*        ACB_DID( NDF__MXACB ) = INTEGER (Read)
*           ARY_ system identifier for the NDF's data array.

*  Arguments Given:
      INTEGER IARY1
      INTEGER INDF

*  Arguments Returned:
      INTEGER IARY2

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IACB               ! Index to the NDF entry in the ACB

*.

*  Set an initial value for the IARY2 argument.
      IARY2 = ARY__NOID

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Import the NDF identifier.
      CALL NDF1_IMPID( INDF, IACB, STATUS )

*  Obtain the array section, using the NDF's data array as a template.
      IF ( STATUS .EQ. SAI__OK ) THEN
         CALL ARY_SSECT( IARY1, ACB_DID( IACB ), IARY2, STATUS )
      END IF

*  If an error occurred, then report context information and call the
*  error tracing routine.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDF_SSARY_ERR',
     :   'NDF_SSARY: Error creating an array section using an NDF ' //
     :   'section as a template.', STATUS )
         CALL NDF1_TRACE( 'NDF_SSARY', STATUS )
      END IF

      END
