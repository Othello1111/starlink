      SUBROUTINE NDF1_HDCRE( IDCB, STATUS )
*+
*  Name:
*     NDF1_HDCRE

*  Purpose:
*     Create a history component for an NDF, if necessary.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_HDCRE( IDCB, STATUS )

*  Description:
*     The routine ensures that a history component exists for an NDF,
*     creating one if necessary. Associated locators are stored in the
*     DCB. The routine returns without action if a history component
*     already exists.

*  Arguments:
*     IDCB = INTEGER (Given)
*        Index to a DCB entry identifying the NDF for which a history
*        component is required.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     5-MAY-1993 (RFWS):
*        Original version.
*     11-MAY-1993 (RFWS):
*        Moved current date/time formatting to another routine.
*     2-JUN-1993 (RFWS):
*        Obtain and format the date/time as separate operations. Also
*        use NDF__SZHDT to declare the date/time string length.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants      
      INCLUDE 'NDF_PAR'          ! NDF_ public constants      

*  Global Variables:
      INCLUDE 'NDF_DCB'          ! NDF_ Data Control Block
*        DCB_HLOC( NDF__MXDCB ) = CHARACTER * ( DAT__SZLOC ) (Read and
*        Write)
*           Locator for NDF history component.
*        DCB_HRLOC( NDF__MXDCB ) = CHARACTER * ( DAT__SZLOC ) (Write)
*           Locator for array of history records.
*        DCB_KH( NDF__MXDCB ) = LOGICAL (Write)
*           Whether DCB information is available for the NDF's history
*           component.
*        DCB_LOC( NDF__MXDCB ) = CHARACTER * ( DAT__SZLOC ) (Read)
*           Data object locator.

*  Arguments Given:
      INTEGER IDCB

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( NDF__SZHDT ) TIME ! Formatted creation time string
      INTEGER DIM( 1 )           ! Object dimension sizes
      INTEGER YMDHM( 5 )         ! Integer date/time field values
      REAL SEC                   ! Seconds field value

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Ensure that history structure information is available in the DCB.
      CALL NDF1_DH( IDCB, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*  Check if a history component is already present. There is nothing to
*  do if it is.
         IF ( DCB_HLOC( IDCB ) .EQ. DAT__NOLOC ) THEN

*  If not, then create a new scalar history component and obtain a
*  locator for it to be stored in the DCB.
            CALL DAT_NEW( DCB_LOC( IDCB ), 'HISTORY', 'HISTORY', 0,
     :                    DIM, STATUS )
            CALL DAT_FIND( DCB_LOC( IDCB ), 'HISTORY',
     :                     DCB_HLOC( IDCB ), STATUS )

*  Obtain the current date and time and convert it to standard history
*  format.
            CALL NDF1_GTIME( YMDHM, SEC, STATUS )
            CALL NDF1_FMHDT( YMDHM, SEC, TIME, STATUS )

*  Create a scalar CREATED component in the history structure and write
*  the creation time to it.
            CALL DAT_NEW0C( DCB_HLOC( IDCB ), 'CREATED', NDF__SZHDT,
     :                      STATUS )
            CALL CMP_PUT0C( DCB_HLOC( IDCB ), 'CREATED', TIME, STATUS )

*  Also create a scalar CURRENT_RECORD component and initialise it to
*  zero.
            CALL DAT_NEW0I( DCB_HLOC( IDCB ), 'CURRENT_RECORD', STATUS )
            CALL CMP_PUT0I( DCB_HLOC( IDCB ), 'CURRENT_RECORD', 0,
     :                      STATUS )

*  Create a 1-dimensional RECORDS array of structures (initially with
*  10 elements). This will hold the history records themselves. Obtain
*  a locator to this structure for storage in the DCB.
            DIM( 1 ) = 10
            CALL DAT_NEW( DCB_HLOC( IDCB ), 'RECORDS', 'HIST_REC', 1,
     :                    DIM, STATUS )
            CALL DAT_FIND( DCB_HLOC( IDCB ), 'RECORDS',
     :                     DCB_HRLOC( IDCB ), STATUS )

*  If an error occurred, then annul any new locators which may have
*  been acquired and erase the history structure which may have been
*  created.
            IF ( STATUS .NE. SAI__OK ) THEN
               CALL DAT_ANNUL( DCB_HRLOC( IDCB ), STATUS )
               CALL DAT_ANNUL( DCB_HLOC( IDCB ), STATUS )
               CALL ERR_BEGIN( STATUS )
               CALL DAT_ERASE( DCB_LOC( IDCB ), 'HISTORY', STATUS )
               CALL ERR_END( STATUS )
            END IF

*  Note whether DCB history information is up to date.
            DCB_KH( IDCB ) = ( STATUS .EQ. SAI__OK )
         END IF
      END IF
 
*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_HDCRE', STATUS )

      END
