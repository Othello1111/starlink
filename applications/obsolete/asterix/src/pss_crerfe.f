*+  PSS_CRERFE - Create a results file field error
      SUBROUTINE PSS_CRERFE( SLOC, FLD, NDAT, NLEV, LEVS, PTR, STATUS )
*
*    Description :
*
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*     19 Jun 91 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
*
*    Status :
*
      INTEGER                  STATUS                  ! Run-time error
*
*    Import :
*
      CHARACTER*(DAT__SZLOC)   SLOC                    ! Results file
      CHARACTER*(*)            FLD                     ! Field name
      INTEGER                  NDAT                    ! Items per level
      INTEGER                  NLEV                    ! Number of error levels
      DOUBLE PRECISION         LEVS(*)                 ! Error levels
*
*    Export :
*
      INTEGER                  PTR                     ! Ptr to mapped field
*-

*    Check status
      IF ( STATUS .EQ. SAI__OK ) THEN

*      Create field error
        CALL SSO_CREFLDERR( SLOC, FLD, '_REAL', NDAT, NLEV, STATUS )

*      Map it
        CALL SSO_MAPFLDERR( SLOC, FLD, '_REAL', 'WRITE', PTR, STATUS )

*      Write error levels
        CALL SSO_PUTFITEM1D( SLOC, FLD, 'ELEVS', NLEV, LEVS, STATUS )

*      Write null error value
        CALL SSO_PUTFITEM0R( SLOC, FLD, 'NULLERROR', -1.0, STATUS )

      END IF

      END
