      SUBROUTINE POLCAL( STATUS )
*+
*  Name:
*     POLCAL

*  Purpose:
*     Converts a set of analysed intensity images into a cube holding Stokes 
*     vectors.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL POLCAL( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application converts a set of 2D intensity images into a
*     3D data cube holding a Stokes vector at every pixel in the area
*     covered by the supplied intensity images.
*
*     Each input image should contain either the O or E ray image
*     extracted from a single dual-beam exposure. The sky backgrounds
*     should have been removed, and they should have been re-sampled so
*     that a given pixel corresponds to the same point on the sky in all 
*     images.
*
*     Both circular and linear polarization can be measured (see
*     parameter PMODE). For linear polarization, the output cube has
*     3 planes which contain I, Q and U values (in that order). For circular 
*     polarization, the output cube has 2 planes which contain I and V values. 
*
*     If input images for all four half-wave plate positions are provided
*     (0, 22.5, 45 and 67.5 degrees) then a correction is made for any difference
*     in sensitivity of the two channels (such as can be caused by the
*     use of polarized flat-field for instance). This correction is known
*     as the "F-factor" and is based on the redundancy provided by using four 
*     half-wave plate positions. If images with the required half-wave plate 
*     positions are not provided, then it is assumed that the two channels 
*     are equally sensitive (that is, an F-factor of 1.0 is used).
*
*     Corrections are also made for any difference in exposure times for
*     the supplied intensity images. These are based on the fact that the 
*     sum of the O and E ray intensities should always equal the total
*     intensity (after any F-factor correction), and should therefore be
*     the same for all pairs of corresponding O and E ray images if they have 
*     equal exposure times.
*
*     The E and F factors are calculated by inter-comparing pairs of
*     intensity images to estimate their relative scale factor and zero
*     point. This estimation is an iterative process, and is controlled by
*     parameters TOLS, TOLZ, SKYSUP and MAXIT.

*  Usage:
*     polcal in out

*  ADAM Parameters:
*     ETOL = _REAL (Read)
*        The E factors are found using an iterative procedure in which 
*        the supplied intensity images are corrected using the current
*        estimates of the E factors, and new estimates are then
*        calculated on the basis of these corrected images. This procedure
*        continues until the change in E-factor produced by an iteration
*        is less than the value supplied for ETOL, or the maximum number
*        of iterations specified by parameter MAXIT is reached. [0.01]
*     ILEVEL = _INTEGER (Read)
*        Specifies the amount of information to display on the screen.
*        Zero suppresses all output. A value of 1 produces minimal output
*        describing such things as the E and F factors adopted, and a
*        value of 2 produces more verbose output including details of
*        each iteration in the iterative process used to calculate the E
*        and F factors. [1]
*     IN = NDF (Read)
*        A group specifying the names of the input intensity images. This
*        may take the form of a comma separated list, or any of the other 
*        forms described in the help on "Group Expressions".
*     MAXIT = _INTEGER (Read)
*        This parameter specifies the maximum number of iterations to
*        be used when inter-comparing pairs of input images to determine 
*        their relative scale-factor and/or zero-point. If the specified 
*        number of iterations is exceeded without achieving the accuracy 
*        required by the settings of the TOLS and TOLZ parameters, then a 
*        warning message will be issued, but the results will still be used. 
*        The value given for MAXIT must be at least one. [30]
*     OUT = NDF (Read)
*        The name of the output 3D cube holding the Stokes parameters.
*        The x-y plane of this cube covers the overlap region of the 
*        supplied intensity images. Plane 1 contains the total intensity. 
*        The other planes contain either Q and U, or V, depending on the 
*        value of parameter PMODE.
*     PMODE = LITERAL (Read)
*        The mode of operation; CIRCULAR for measuring circular polarization, 
*        or LINEAR for measuring linear polarization. In circular mode, the
*        only legal values for the POLPACK extension item "WPLATE" are 0.0
*        and 45.0. [LINEAR]
*     SKYSUP = _REAL (Read)
*        A positive "sky noise suppression factor" used to control the
*        effects of sky noise when pairs of input images are
*        inter-compared to determine their relative scale-factor. It is
*        intended to prevent the resulting scale-factor estimate being
*        biased by the many similar values present in the "sky
*        background" of typical astronomical data.  SKYSUP controls an
*        algorithm which reduces the weight given to data where there
*        is a high density of points with the same value, in order to
*        suppress this effect. 
*
*        A SKYSUP value of unity can often be effective, but a value
*        set by the approximate ratio of sky pixels to useful object
*        pixels (i.e. those containing non-sky signal) in a "typical"
*        image will usually be better. The precise value
*        is not critical. A value of zero disables the sky noise
*        suppression algorithm completely. The default value for SKYSUP
*        is 10. This is normally reasonable for CCD frames of extended 
*        objects such as galaxies, but a larger value, say 100, may give 
*        slightly better results for star fields. [10]
*     TITLE = LITERAL (Read)
*        A title for the output cube. [Output from POLCAL]
*     TOLS = _REAL (Read)
*        This parameter defines the accuracy tolerance to be achieved
*        when inter-comparing pairs of input images to determine their 
*        relative scale-factor. The value given for TOLS specifies the 
*        tolerable fractional error in the estimation of the relative 
*        scale-factor between any pair of input NDFs. This value must 
*        be positive. [0.001]
*     TOLZ = _REAL (Read)
*        This parameter defines the accuracy tolerance to be achieved
*        when inter-comparing pairs of input images to determine their 
*        relative zero-points. The value given for TOLZ specifies the 
*        tolerable absolute error in the estimation of the relative 
*        zero-point between any pair of input images whose relative 
*        scale-factor is unity. The value used is multiplied by the relative 
*        scale-factor estimate (which reflects the fact that an image with 
*        a larger data range can tolerate a larger error in estimating its
*        zero-point). The TOLS value supplied must be positive. [0.05]
*     VARIANCE = _LOGICAL (Read)
*        This parameter should be set to a TRUE value if variances are to
*        be included in the output cube. This can only be done if all the
*        input intensity images have associated variance values. A null (!)
*        value results in variance values being created if possible, but
*        not otherwise. [!]
 
*  Examples:
*     polcal "*_O,*_E" stokes
*        This example uses all images in the current directory which have
*        file names ending with either "_O" or "_E", and stores the
*        corresponding I, Q and U values in the 3d cube "stokes".

*  Notes:
*     -  An item named STOKES is added to the POLPACK extension. It is a
*     character string identifying the quantity stored in each plane of
*     the cube. For linear polarimetry, it is set to "IQU", and for
*     circular polarimetry it is set to "IV".

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils
 
*  Authors:
*     TMG: Tim Gledhill (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-JUL-1997 (TMG):
*        Original version.
*     15-MAY-1998 (DSB):
*        Prologue re-written.
*     02-JUN-1998 (TMG):
*        Added extra workspace array IPID to hold character identifiers
*     4-JUN-1998 (DSB):
*        Modified allocation of IPID workspace to include length of each
*        character identifier. Extended image identifiers from max of 10
*        characters to 30 characters. Modified call to POL_CALE to include
*        trailing length specifier for IPID strings.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'DAT_PAR'          ! HDS constants
      INCLUDE 'PAR_ERR'          ! PAR error constants
      
*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      REAL SLA_RANGE             ! Put angle into range [-PI,+PI]

*  Local Constants:
      INTEGER MAXIN              ! Maximim number of input images
      PARAMETER ( MAXIN = 1024 )

      INTEGER MAXSET             ! Maximum number of polarsation sets
      PARAMETER ( MAXSET = 256 )

      CHARACTER * ( 1 ) LEFT     ! Determines the order of the O and E
                                 ! ray in the calculations.
      PARAMETER ( LEFT = 'O' )

      REAL DTOR                  ! Degrees to radians conversion factor
      PARAMETER( DTOR = 1.7453293E-2 )

      INTEGER IDLEN              ! Max. length of an image identifier string
      PARAMETER ( IDLEN = 30 ) 

*  Local Variables:
      INTEGER NDFIN( MAXIN )     ! Input NDF identifiers
      INTEGER NIM, NVAL, NSET    ! Number of input images, validated
                                 ! input images and resulting
                                 ! polarisation data sets.
      INTEGER LBND( 3 ), UBND( 3) ! image bounds
      INTEGER NDIM               ! image dimensionality
      INTEGER NPOS               ! Number of waveplate positions (2 for
                                 ! circular and 4 for linear).
      INTEGER I, J, IVAL, IPOS,
     :     PVAL, ISET            ! Loop counters
      INTEGER NDFVAL( MAXIN )    ! Validated NDF identifiers
      INTEGER IPAIR( MAXIN )     ! List of pairs
      INTEGER NSTATE( 4 )        ! Number of valid images at each
                                 ! waveplate position
      INTEGER PSET( 8, MAXSET )  ! List of validated images sorted
                                 ! into polarisation states.
      INTEGER NPAIR              ! number of polarimetric pairs
      INTEGER INDFT              ! Temporary NDF identifier
      INTEGER IVAL_L, IVAL_R
      INTEGER NI, NQ, NU         ! number of possible estimates of I, Q
                                 ! and U
      INTEGER IPDIN( 8, MAXSET ), IPVIN( 8, MAXSET )
                                 ! pointers to mapped data and variance
      INTEGER IPDCOR( 8, MAXSET ), IPVCOR( 8, MAXSET )
                                 ! pointers to mapped data corrected
                                 ! with E and F factors
      INTEGER NDFOUT             ! output NDF identifer.
      INTEGER IPDOUT, IPVOUT     ! pointers to output data and variance
      INTEGER NEL, NOUT          ! number of mapped elements.
      INTEGER MAXIT              ! maximum number of iterations for
                                 ! image intercomparisons
      INTEGER ILEVEL             ! user information level
      INTEGER IPFEST, IPVFEST    ! workspace for F factor estimates
      INTEGER IPTI1, IPTI2       ! workspace for total intensity images
      INTEGER IPID               ! workspace for identifiers
      INTEGER IPEEST, IPZEST     ! workspace for E factor and zero
                                 ! shift estimates
      INTEGER IPDE               ! workspace for E factor convergence
                                 ! estimates
      INTEGER IPVEEST, IPVZEST   ! workspace for variances on E factor
                                 ! and zero shift estimates
      INTEGER IPWEIGHT           ! workspace for image weightings
      INTEGER IPIEST, IPQEST, IPUEST
                                 ! workspace for estimates of I, Q U
      INTEGER IPVIEST, IPVQEST, IPVUEST
                                 ! workspace for variances on estimates
                                 ! of I, Q and U
      INTEGER IWCS               ! Identifier for the WCS information
       
      REAL ANGROT( MAXIN )       ! Position angle of WPLATE=0.0 axis
      REAL WPLATE( MAXIN )       ! Waveplate positions of images 
      REAL TOLS, TOLZ            ! tolerances for image intercomparisons
      REAL SKYSUP                ! sky supression factor
      REAL ETOL                  ! tolerance for E factor convergences
      REAL F, VF                 ! F factor and its variance
      
      CHARACTER * ( 8 )  PMODE   ! Polarimetry mode (LINEAR or CIRCULAR)
      CHARACTER * ( IDLEN ) IMGID( MAXIN )
                                 ! Image ID descriptor
      CHARACTER * ( 1 ) RAY( MAXIN )
                                 ! Image ray identifer.
      CHARACTER * ( NDF__SZTYP ) TYPE
                                 ! NDF data type
      CHARACTER * ( IDLEN ) ID( 4, MAXSET )
                                 ! Image ID string
      CHARACTER * ( 40 ) TITLE   ! Title for output NDF
      CHARACTER * ( 40 ) LABEL   ! Label for output NDF
      CHARACTER * ( 3 ) PLANES   ! Quantities stored in output planes
      CHARACTER * ( DAT__SZLOC ) XLOC ! Locator for output POLPACK extension
      
      LOGICAL DESCOK             ! Image descriptors OK?
      LOGICAL GOTVAR             ! Was value supplied for parameter VARIANCE?
      LOGICAL VAR                ! Variance information present and
                                 ! required in output?
      LOGICAL USED( MAXIN )      ! flag for images that have been
                                 ! processed


* TEMPORARY TSP SECTION FOR DIAGNOSTIC OUTPUT!!!!!!
* 
c      INTEGER MP_INDEX,MP_I,MP_Q,MP_U
c      INTEGER NX,NY,IERR,NERR
c      CHARACTER * ( DAT__SZLOC ) TSPLOC,ILOC,SLOC,QLOC,ULOC
      
*  Local Data:
      REAL WPREF( 4 )            ! The actual waveplate positions that
                                 ! are expected
      DATA WPREF / 0.0,45.0,22.5,67.5 /
*      DATA WPREF / 22.5,67.5,0.0,45.0 / 
      
      
*  Internal References:
      LOGICAL PAIRED             ! define an internal function to
                                 ! determine if two images are
                                 ! polarimetric pairs.
      PAIRED( I, J ) = ( IMGID( I ) .EQ. IMGID( J ) .AND.
     :                   WPLATE( I ) .EQ. WPLATE( J ) .AND.
     :                   RAY( I ) .NE. RAY( J ) )

      
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) GO TO 99

*  Start an NDF context.
      CALL NDF_BEGIN

*  Find out whether we are doing linear or circular polarimetry. In
*  circular polarimetry mode there are 2 waveplate positions and in
*  linear polarimetry mode 4 waveplate positions.
      CALL PAR_CHOIC( 'PMODE', 'LINEAR', 'LINEAR,CIRCULAR', .TRUE.,
     :                PMODE, STATUS )
      NPOS = 4
      IF ( PMODE .EQ. 'CIRCULAR' ) NPOS = 2
      
*  Access the input NDFs using 'READ' access so that they will not be
*  deleted when released. The minimum number of images allowed is 2
*  in circular mode and 4 in linear mode although in order to calculate
*  the instrumental polarisation efficiency twice this number of images
*  are needed.
      CALL NDFAC( 'IN', 'READ', NPOS, MAXIN, NIM, NDFIN, STATUS )

*  Replace the identifiers to the supplied NDFs with identifiers for
*  sections of the supplied NDFs which have equal bounds. Abort if there
*  is an error since this means that some of the images do not overlap.
      CALL NDF_MBNDN( 'TRIM', NIM, NDFIN, STATUS )      
      IF ( STATUS .NE. SAI__OK ) GO TO 99
      
*  Get the image dimensions and data type by looking at the first mapped
*  NDF.
      CALL NDF_BOUND( NDFIN( 1 ), 2, LBND, UBND, NDIM, STATUS )
      CALL NDF_TYPE( NDFIN( 1 ), 'DATA', TYPE, STATUS )

*  Obtain the required descriptor information from the images. The
*  descriptors should have been inserted into a polarimetry extension by
*  previous stages of processing. We may want to access history
*  information here as well to check whether previous mandatory
*  processing stages have been completed successfully (not done at
*  the moment).  
      IVAL = 1
      DO I = 1, NIM

*  Initialise the descriptor items.
         WPLATE( IVAL ) = VAL__BADR
         IMGID( IVAL ) = ' '
         RAY( IVAL ) = ' '
         DESCOK = .FALSE.
         ANGROT( IVAL ) = VAL__BADR

*  Get the descriptor items for this image.
         CALL NDF_XGT0R( NDFIN( I ), 'POLPACK', 'WPLATE',
     :                   WPLATE( IVAL ), STATUS )
         CALL NDF_XGT0C( NDFIN( I ), 'POLPACK', 'IMGID',
     :                   IMGID( IVAL ), STATUS )
         CALL NDF_XGT0C( NDFIN( I ), 'POLPACK', 'RAY', RAY( IVAL ),
     :                   STATUS )
         CALL NDF_XGT0R( NDFIN( I ), 'POLPACK', 'ANGROT', 
     :                   ANGROT( IVAL ), STATUS )

*  If the descriptors were obtained, check them for validity. The
*  WPLATE descriptor is checked against a constant array containing
*  the accepted values. The RAY descriptor should be either O or E
*  (corresponding to Ordinary and Extraordinary rays). The IMGID should
*  simply be a non-null character identifier. The ANGROT value should all
*  be very close to the the first value.
         IF ( STATUS .EQ. SAI__OK ) THEN

            DO IPOS = 1, NPOS
               IF ( WPLATE( IVAL ) .EQ. WPREF( IPOS ) ) THEN
                  DESCOK = .TRUE.
               ENDIF
            ENDDO

            IF( .NOT. DESCOK ) THEN
               CALL MSG_SETC( 'I', 'WPLATE' )
               CALL MSG_SETR( 'V', WPLATE( IVAL ) )

            ELSE IF( RAY( IVAL ) .NE. 'O' .AND. 
     :               RAY( IVAL ) .NE. 'E' ) THEN
               DESCOK = .FALSE.
               CALL MSG_SETC( 'I', 'RAY' )
               CALL MSG_SETC( 'V', RAY( IVAL ) )

            ELSE IF( IMGID( IVAL ) .EQ. ' ' ) THEN
               DESCOK = .FALSE.
               CALL MSG_SETC( 'I', 'IMGID' )
               CALL MSG_SETC( 'V', ' ' )

            ELSE IF( ABS( SLA_RANGE( DTOR*( ANGROT( IVAL ) - ANGROT( 1 )
     :                   ) ) ) .GT. 0.008 ) THEN
               DESCOK = .FALSE.

               CALL MSG_OUT( ' ', 'POLCAL: The analysis angle '//
     :                       '(ANGROT) must be the same in all '//
     :                       'input frames.', STATUS )

               CALL MSG_SETC( 'I', 'ANGROT' )
               CALL MSG_SETR( 'V', ANGROT( IVAL ) )

            END IF

*  If this image has valid descriptors then add it to the list of
*  validated images and increment the number of valid images.
            IF ( DESCOK ) THEN
               NDFVAL( IVAL ) = NDFIN( I )
               IVAL = IVAL + 1

*  If the descriptors are NOT valid then give a warning message but
*  continue looking for other valid images.
            ELSE
               CALL NDF_MSG( 'NDF', NDFIN( I ) )
               CALL MSG_OUT( ' ', 'POLCAL: The POLPACK extension item'//
     :                       ' ^I does not exist in ''^NDF''or has '//
     :                       'the illegal value ''^V''.', STATUS )
            ENDIF

*  If an error occured whilst obtaining the descriptors, then notify the
*  user but contine with the other images by flushing the error now.
         ELSE
            CALL ERR_FLUSH( STATUS )
            CALL NDF_MSG( 'NDF', NDFIN( I ) )
            CALL MSG_OUT( ' ', 'POLCAL: Cannot access the POLPACK '//
     :                         'extension in ''^NDF''.', STATUS )
         ENDIF
      ENDDO

*  Determine the number of validated input images. If there are no valid
*  input images then report an error and abort.
      NVAL = IVAL - 1
      IF ( NVAL .EQ. 0 .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'POLCAL_NOVALID', 'POLCAL: None of the input ' //
     :        'NDFs have valid POLPACK extensions.' , STATUS )
         GO TO 99
      ENDIF

*  Check the status value so that we can be sure that any error condition
*  detected after the next subroutine call was generated within the
*  called subroutine.
      IF( STATUS .NE. SAI__OK ) GO TO 99

*  See if the user wants variance information to be propagated through
*  to the output data.
      CALL PAR_GET0L( 'VARIANCE', VAR, STATUS )

*  Set a flag and annull the error if a null value was supplied for
*  VARIANCE. In this case we assume .TRUE. for VAR if all the inputs
*  have VARIANCE components, and .FALSE. otherwise.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTVAR = .FALSE.
      ELSE
         GOTVAR = .TRUE.
      END IF         

*  If the user wants variance information to be propagated (if possible) then
*  see if variances are present in the input data. All input images
*  must have variance information for it to be propagated. If this is
*  not the case then warn the user if an explicit requested to propagate
*  variances was made.
      IF ( VAR .AND. GOTVAR .OR. .NOT. GOTVAR ) THEN

         CALL NDF_STATE( NDFVAL( 1 ), 'VARIANCE', VAR, STATUS )
         DO IVAL = 2, NVAL
            IF ( VAR ) CALL NDF_STATE( NDFVAL( IVAL ), 'VARIANCE', VAR,
     :                                 STATUS )
         ENDDO

         IF ( .NOT. VAR .AND. GOTVAR ) THEN
            CALL MSG_OUT( ' ', 'POLCAL: VARIANCE information was ' //
     :           'requested in the output. However, not all of the ' //
     :           'input images have VARIANCES so NO output VARIANCE ' //
     :           'can be calculated.', STATUS )
         ENDIF

      ENDIF

*  Get the parmeter values for image intercomparisons.
      CALL PAR_GET0R( 'TOLS', TOLS, STATUS )
      CALL PAR_GET0R( 'TOLZ', TOLZ, STATUS )
      CALL PAR_GET0I( 'MAXIT', MAXIT, STATUS )
      CALL PAR_GET0R( 'SKYSUP', SKYSUP, STATUS )
      CALL PAR_GET0R( 'ETOL', ETOL, STATUS )
      
*  Get the information level determining how much information is sent to
*  the user.
      CALL PAR_GET0I( 'ILEVEL', ILEVEL, STATUS )

*  If user information is required, print out the number of input and
*  validated images.
      IF ( ILEVEL .GT. 0 ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_SETI( 'NIM', NIM )
         CALL MSG_OUT( ' ', '   ^NIM input NDFs accessed.', STATUS )
         CALL MSG_SETI( 'NVAL', NVAL )
         CALL MSG_OUT( ' ', '   ^NVAL input NDFs validated.',
     :                 STATUS )
      ENDIF
            
*  The images are now sorted into groups from which the polarisation
*  parameters can be calculated. For linear polarimetry this corresponds
*  to groups of 8 (4 waveplate positions) to calculate I, Q and U and for
*  circular polarimetry to groups of 4 (2 waveplate positions) to
*  calculate I and V. However sets can be partially filled as long as the
*  missing information is present somewhere in another set. First
*  initialise flags to show that none of the images have been treated yet.
      DO IVAL = 1, NVAL
         USED( IVAL ) = .FALSE.
      ENDDO

*  Each image should have a polarimetric pair - an image from the same
*  exposure (same IMGID, same WPLATE) but orthogonal polarisation state
*  (different RAY). Find each image's pair. Count the number of valid
*  pairs. In principle it is possible to use unpaired images in the
*  processing, but at some cost to the final error - however this is
*  not supported here, unpaired images are not used.
      NPAIR = 0
      DO IVAL = 1, NVAL
         DO PVAL = 1, NVAL
            IF ( PAIRED( IVAL, PVAL ) ) THEN
               IPAIR( IVAL ) = PVAL
               NPAIR = NPAIR + 1
               GOTO 1
            ENDIF
         ENDDO
               
*  If an image does not have a pair give a warning and flag it as 'used'
*  so that it will not take part in the processing.
         CALL NDF_MSG( 'NDF', NDFVAL( IVAL ) )
         CALL MSG_OUT( ' ', ' POLCAL: ''^NDF'' does not have a '//
     :                 'polarimetric pair and will not be used.', 
     :                 STATUS )
         USED( IVAL ) = .TRUE.
 1       CONTINUE
      ENDDO
      NPAIR = NPAIR / 2
      
*  If there are no valid pairs then quit.
      IF ( NPAIR .EQ. 0 ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'POLCAL_NOPAIRS', 'POLCAL: There are no ' //
     :                 'usable images. Cannot continue.', STATUS )
         GO TO 99
      ENDIF
         
*  This section sorts the validated images into data sets than can be
*  processed into polarimetric information. Each data set will contain
*  2*NPOS images, consisting of pairs from each waveplate position.
*  First clear the counters for images in each polarisation state.

*  Initialise an array to hold counts of the number of images in each
*  waveplate position.
      DO IPOS = 1, 4
         NSTATE( IPOS ) = 0
      ENDDO

*  Initialise an array to hold the NDF identifiers of input images
*  according to their polarisation state (2 for each waveplate position
*  corresponding to O and E ray).
      DO ISET = 1, MAXSET
         DO IPOS = 1, NPOS
            PSET( 2 * IPOS - 1, ISET ) = 0
            PSET( 2 * IPOS, ISET ) = 0
         ENDDO
      ENDDO

*  Loop through the images looking for images that have not been used
*  yet.
      DO IVAL = 1, NVAL
         IF ( .NOT. USED( IVAL ) ) THEN

*  Sort the image into a polarisation state and do the same for its
*  pair. Record the image as used. Remember the image identifers in each
*  state so that we can easily reference the image IDs later on.
            DO IPOS = 1, NPOS
               IF ( WPLATE( IVAL ) .EQ. WPREF( IPOS ) ) THEN
                  NSTATE( IPOS ) = NSTATE( IPOS ) + 1
                  IF ( RAY( IVAL ) .EQ. LEFT ) THEN
                     PSET( 2 * IPOS - 1, NSTATE( IPOS ) ) = IVAL
                     PSET( 2 * IPOS, NSTATE( IPOS ) ) = IPAIR( IVAL )
                  ELSE
                     PSET( 2 * IPOS - 1, NSTATE( IPOS ) ) =
     :                    IPAIR( IVAL )
                     PSET( 2 * IPOS, NSTATE( IPOS ) ) = IVAL
                  ENDIF
                  USED( IVAL ) = .TRUE.
                  USED( IPAIR( IVAL ) ) = .TRUE.
                  ID( IPOS, NSTATE( IPOS ) ) = IMGID( IVAL )
               ENDIF
            ENDDO
         ENDIF
      ENDDO

*  Find out the maximum number of images in any polarisation state. Also
*  find out how many estimates of I, Q and U are possible. In circular
*  mode the Q estimates will be estimates of V.
      NSET = 0
      DO IPOS = 1, NPOS
         NSET = MAX( NSET, NSTATE( IPOS ) )
      ENDDO
      NQ = NSTATE( 1 ) + NSTATE( 2 )
      NU = NSTATE( 3 ) + NSTATE( 4 )
      NI = NQ + NU

*  Consistency check: In linear mode both NQ and NU should be non-zero
*  otherwise the polarisation cannot be calculated. In circular mode
*  only NQ should ne non-zero.
      IF ( STATUS .NE. SAI__OK ) GOTO 99

      IF ( NQ .EQ. 0 ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'POLCAL_BADLIN', 'POLCAL: There is not ' //
     :                 'enough information to calculate the ' //
     :                 'polarisation. Cannot continue.', STATUS )
         GO TO 99

      ELSE IF ( PMODE .EQ. 'LINEAR' .AND. NU .EQ. 0 ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'POLCAL_BADLIN', 'POLCAL: There is not ' //
     :                 'enough information to calculate the linear ' //
     :                 'polarisation. Cannot continue.', STATUS )
         GO TO 99

      ELSE IF ( PMODE .EQ. 'CIRCULAR' .AND. NU .NE. 0 ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'POLCAL_BADCIR', 'POLCAL: The detected ' //
     :        'images are compatible with linear polarimetry but ' //
     :        'PMODE=CIRCULAR is selected. Cannot continue.', STATUS )
         GO TO 99

      ENDIF
         
*  Loop to map the input data and variances (if required). Loop through
*  the polarisation data sets including partially complete ones.
      DO ISET = 1, NSET

*  Map the data arrays of each NDF section, and if all NDFs have
*  VARIANCE components, also map the VARIANCE components. If variances
*  are not required then assign the pointers to mapped variance arrays
*  to the data arrays, since they will not be used.
         DO IPOS = 1, NPOS
            IF ( NSTATE( IPOS ) .GE. ISET ) THEN
               IVAL_L = PSET( 2 * IPOS -1, ISET )
               IVAL_R = PSET( 2 * IPOS, ISET )
               CALL NDF_MAP( NDFVAL( IVAL_L ), 'DATA', TYPE, 'READ',
     :              IPDIN( 2 * IPOS - 1, ISET ), NEL, STATUS )
               CALL NDF_MAP( NDFVAL( IVAL_R ), 'DATA', TYPE, 'READ',
     :              IPDIN( 2 * IPOS, ISET ), NEL, STATUS )
               IF( VAR ) THEN
                  CALL NDF_MAP( NDFVAL( IVAL_L ), 'VARIANCE', TYPE,
     :                 'READ', IPVIN( 2 * IPOS - 1, ISET ), NEL,
     :                 STATUS )
                  CALL NDF_MAP( NDFVAL( IVAL_R ), 'VARIANCE', TYPE,
     :                 'READ', IPVIN( 2 * IPOS, ISET ), NEL, STATUS )
               ELSE
                  IPVIN( 2 * IPOS - 1, ISET ) = IPDIN( 2 * IPOS - 1,
     :                   ISET )
                  IPVIN( 2 * IPOS, ISET ) = IPDIN( 2 * IPOS, ISET ) 
               ENDIF

*  Allocate workspace to hold the images that have been corrected for E
*  and F factors. If variance information is required then allocate space
*  for the corrected variance arrays as well (otherwise point the
*  variance arrays at the data).
               CALL PSX_CALLOC( NEL, '_REAL',
     :              IPDCOR( 2 * IPOS - 1, ISET ), STATUS )
               CALL PSX_CALLOC( NEL, '_REAL', IPDCOR( 2 * IPOS, ISET ),
     :                          STATUS )
               IF ( VAR ) THEN
                  CALL PSX_CALLOC( NEL, '_REAL',
     :              IPVCOR( 2 * IPOS - 1, ISET ), STATUS )
                  CALL PSX_CALLOC( NEL, '_REAL',
     :                 IPVCOR( 2 * IPOS, ISET ), STATUS )
               ELSE
                  IPVCOR( 2 * IPOS - 1, ISET ) =
     :                 IPDCOR( 2 * IPOS - 1, ISET )
                  IPVCOR( 2 * IPOS, ISET ) = IPDCOR( 2 * IPOS, ISET )
               ENDIF
            ENDIF
         ENDDO
      ENDDO

*  Abort if an error has occured.
      IF ( STATUS .NE. SAI__OK ) GO TO 99

* Allocate some workspace to hold estimates of the F factor and its
* variance.
      CALL PSX_CALLOC( 2 * NSET, '_REAL', IPFEST, STATUS )
      CALL PSX_CALLOC( 2 * NSET, '_REAL', IPVFEST, STATUS )
      
*  Calculate the polarisation-dependent instrumental efficiency (F
*  factor). This gives the relative efficiency of the right hand
*  polarimeter channel relative to the left hand channel.
      CALL POL_CALF( NEL, NSET, NPOS, IPDIN, IPVIN, NSTATE, VAR, TOLS,
     :               TOLZ, MAXIT, SKYSUP, ID, ILEVEL, %VAL( IPFEST ),
     :               %VAL( IPVFEST ), F, VF, STATUS )

* Release unwanted workspace. Abort if an error has occurred.
      CALL PSX_FREE( IPFEST, STATUS )
      CALL PSX_FREE( IPVFEST, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 99
      
*  Allocate workspace to hold total intensity image pairs when
*  calculating the E factors. 
      CALL PSX_CALLOC( NEL * NPAIR, '_REAL', IPTI1, STATUS )
      CALL PSX_CALLOC( NEL * NPAIR, '_REAL', IPTI2, STATUS )

* Allocate space for scale factor and zero shift estimate, used during
* image intercomparisons when calculating the E factor. If variances are
* required then allocate space for the variances on these quantities as
* well. If variances are not required then allocate an array to hold
* weighting factors used instead of the variances when forming median
* images.
      CALL PSX_CALLOC( NPAIR, '_REAL', IPEEST, STATUS )
      CALL PSX_CALLOC( NPAIR, '_REAL', IPZEST, STATUS )
      CALL PSX_CALLOC( NPAIR, '_REAL', IPDE, STATUS )
      CALL PSX_CALLOC( NPAIR, '_DOUBLE', IPWEIGHT, STATUS )
      IF ( VAR ) THEN
         CALL PSX_CALLOC( NPAIR, '_REAL', IPVEEST, STATUS )
         CALL PSX_CALLOC( NPAIR, '_REAL', IPVZEST, STATUS )
      ELSE
         IPVEEST = IPEEST
         IPVZEST = IPZEST
      ENDIF

* Allocate Space to hold a character identifer for each pair.
      CALL PSX_CALLOC( IDLEN*NPAIR, '_CHAR', IPID, STATUS )
      
*  Calculate the time-dependent instrumental efficiency (E factor). This
*  gives the relative efficiency of the instrument between exposures.
*  This routine also produces E and F factor corrected output images.
      CALL POL_CALE( NEL, NSET, NPOS, NPAIR,  IPDIN, IPVIN, NSTATE,
     :               VAR, TOLS, TOLZ, MAXIT, SKYSUP, %VAL( IPID ), ID, 
     :               ILEVEL, F,
     :               ETOL, %VAL( IPWEIGHT ), IPDCOR, IPVCOR,
     :               %VAL( IPEEST ), %VAL( IPZEST ), %VAL( IPVEEST ),
     :               %VAL( IPVZEST ), %VAL( IPDE ), %VAL( IPTI1 ),
     :               %VAL( IPTI2 ), STATUS, %VAL( IDLEN ) )

*   Release unwanted workspace. Keep the weight array (if defined) for
*   use when calculating the stokes parameters.

      CALL PSX_FREE( IPEEST, STATUS )
      CALL PSX_FREE( IPZEST, STATUS )
      CALL PSX_FREE( IPDE, STATUS )
      CALL PSX_FREE( IPID, STATUS )
      IF ( VAR ) THEN
         CALL PSX_FREE( IPVEEST, STATUS )
         CALL PSX_FREE( IPVZEST, STATUS )
      ENDIF
      
*  Get an AST identifier for the FrameSet held in the WCS component 
*  of the first input NDF. This will be propagated to the output NDF.
*  First create a 3D super-set from the input 2D image. This needs
*  to be done because the WCS information will be stored with the 3D 
*  output NDF and so needs to have a 3D base Frame. Then get the WCS info
*  from this 3D NDF.
      LBND( 3 ) = 1
      UBND( 3 ) = 1
      CALL NDF_SECT( NDFVAL( 1 ), 3, LBND, UBND, INDFT, STATUS ) 
      CALL NDF_GTWCS( INDFT, IWCS, STATUS )

*  At this point we can release the input images since we now have
*  versions corrected with the efficiency factors. Do this by ending the
*  current NDF context.
      CALL NDF_END( STATUS )

*  Release the workspace that was used to hold the total intensity image
*  pairs. Abort on error.
      CALL PSX_FREE( IPTI1, STATUS )
      CALL PSX_FREE( IPTI2, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 99
      
*  Alloacate space for the I and Q and U estimates. If no U estimates are
*  possible ( circular mode) then assign a dummy pointer.
      CALL PSX_CALLOC( NEL * NI, '_REAL', IPIEST, STATUS )
      CALL PSX_CALLOC( NEL * NI, '_REAL', IPQEST, STATUS )
      IF ( NU .GT. 0 ) THEN
         CALL PSX_CALLOC( NEL * NI, '_REAL', IPUEST, STATUS )
      ELSE
         IPUEST = IPQEST
      ENDIF
        
*  If variance information is required then allocate space for the
*  variance estimates on each of the stokes parameters. These will be
*  used to form the weighted median images. Again, only allocate space
*  for the U variance if we can calculate U.
      IF ( VAR ) THEN
         CALL PSX_CALLOC( NEL * NI, '_REAL', IPVIEST, STATUS )
         CALL PSX_CALLOC( NEL * NI, '_REAL', IPVQEST, STATUS )
         IF ( NU .GT. 0 ) THEN
            CALL PSX_CALLOC( NEL * NI, '_REAL', IPVUEST, STATUS )
         ELSE
            IPVUEST = IPVQEST
         ENDIF
 
*  If variance information is not to be calculated then assign dummy
*  pointers.
      ELSE
         IPVIEST = IPIEST
         IPVQEST = IPQEST
         IF ( NU .GT. 0 ) THEN
            IPVUEST = IPUEST
         ENDIF
      ENDIF

* Obtain an output data cube to hold the polarisation images. In linear
* mode the output cube will contain I, Q, U. In circular mode it will
* contain I, V. If variances have been calculated then the variance
* information will be propagated to the output. Begin another NDF
* context.
      CALL NDF_BEGIN
      LBND( 3 ) = 1
      IF ( PMODE .EQ. 'LINEAR' ) THEN
         UBND( 3 ) = 3
         TITLE = 'Output from POLPACK: Linear polarimetry'
         LABEL = 'Stokes parameters (I, Q, U)'
         PLANES = 'IQU'
      ELSE
         UBND( 3 ) = 2
         TITLE = 'Output from POLPACK: Circular polarimetry'
         LABEL = 'Stokes parameters (I, V)'
         PLANES = 'IV'
      ENDIF
      CALL NDF_CREAT( 'OUT', '_REAL', 3, LBND, UBND, NDFOUT, STATUS )

*  Set the default TITLE component for the output, and then ask the user for a
*  new title.
      CALL NDF_CPUT( TITLE, NDFOUT, 'TITLE', STATUS )
      CALL NDF_CINP( 'TITLE', NDFOUT, 'TITLE', STATUS )

*  Set the LABEL component for the output.
      CALL NDF_CPUT( LABEL, NDFOUT, 'LABEL', STATUS )

*  Store world coordinate information in the output NDF. All the input 
*  NDFs are assumed to be aligned with each other, and with the output 
*  NDF. So just copy the WCS component from the first input NDF to the 
*  output NDF, and then annul the AST identifier.
      CALL NDF_PTWCS( IWCS, NDFOUT, STATUS )
      CALL AST_ANNUL( IWCS, STATUS )

*  Create a POLPACK extension containing a character array identifying the
*  quantities stored in each plane of the DATA array, and the angle
*  between the first pixel axis and the analyser (i.e. WPLATE=0.0) axis.
*  This angle is just copied from the first input NDF, since there can be
*  no rotation between input images.
      CALL NDF_XNEW( NDFOUT, 'POLPACK', 'POLPACK', 0, 0, XLOC, STATUS )
      CALL NDF_XPT0C( PLANES( : UBND( 3 ) - LBND( 3 ) + 1 ), NDFOUT, 
     :                'POLPACK', 'STOKES', STATUS ) 
      CALL NDF_XPT0R( ANGROT( 1 ), NDFOUT, 'POLPACK', 'ANGROT', STATUS ) 
      CALL DAT_ANNUL( XLOC, STATUS )         

* Map the output DATA array and if necessary, the VARIANCE array.
      CALL NDF_MAP( NDFOUT, 'DATA', '_REAL', 'WRITE/BAD', IPDOUT, NOUT,
     :              STATUS )
      IF( VAR ) THEN
         CALL NDF_MAP( NDFOUT, 'VARIANCE', '_REAL', 'WRITE/BAD',
     :                        IPVOUT, NOUT, STATUS )
      ELSE
         IPVOUT = IPDOUT
      ENDIF

* Pass the images and parameters to the routine that calculates the
* polarisation. Put the results directly into the output array.
      CALL POL_CALP( NEL, NSET, NPOS, NI,  IPDCOR, IPVCOR, NSTATE,
     :               VAR, %VAL( IPIEST ), %VAL( IPVIEST ),
     :               %VAL( IPQEST ), %VAL( IPVQEST ), %VAL( IPUEST ),
     :               %VAL( IPVUEST ), %VAL( IPWEIGHT ), %VAL( IPDOUT ),
     :               %VAL( IPVOUT ), STATUS )


* TEMPORARY SECTION TO CREATE AN OUTPUT TSP STRUVCTURE.
* =====================================================

* Create an output TSP data structure.

c      NX = UBND( 1 ) - LBND( 1 ) + 1
c      NY = UBND( 2 ) - LBND( 2 ) + 1 
c      CALL DAT_CREAT( 'TSPOUT', 'NDF', 0, 0, STATUS )
c      CALL DAT_ASSOC( 'TSPOUT', 'WRITE', TSPLOC, STATUS )
c      CALL TSP_CREATE_2D( TSPLOC, NX, NY, 'QU', .FALSE.,
c     :                    .FALSE., STATUS )

* Map the stokes components.

c      CALL TSP_MAP_DATA( TSPLOC, 'WRITE', MP_I, ILOC, STATUS )
c      CALL TSP_GET_STOKES( TSPLOC, 'Q', SLOC, STATUS )
c      CALL TSP_MAP_DATA( SLOC, 'WRITE', MP_Q, QLOC, STATUS )
c      CALL DAT_ANNUL( SLOC, STATUS )
c      CALL TSP_GET_STOKES( TSPLOC, 'U', SLOC, STATUS )
c      CALL TSP_MAP_DATA( SLOC, 'WRITE', MP_U, ULOC, STATUS )
c      CALL DAT_ANNUL( SLOC, STATUS )

* Copy the results into the TSP structures.

c      CALL VEC_RTOR( .TRUE., NEL, %VAL( IPDOUT ), %VAL( MP_I ), IERR,
c     :     NERR, STATUS )
c      MP_INDEX = IPDOUT + 4 * NEL
c      CALL VEC_RTOR( .TRUE., NEL, %VAL( MP_INDEX ), %VAL( MP_Q ), IERR,
c     :     NERR, STATUS )
c      MP_INDEX = MP_INDEX + 4 * NEL
c      CALL VEC_RTOR( .TRUE., NEL, %VAL( MP_INDEX ), %VAL( MP_U ), IERR,
c     :     NERR, STATUS )

* Unmap and annul TSP locators.

c      CALL TSP_UNMAP( ILOC, STATUS )
c      CALL TSP_UNMAP( QLOC, STATUS )
c      CALL TSP_UNMAP( ULOC, STATUS )
c      CALL DAT_ANNUL( TSPLOC, STATUS )

* End of TSP section.
* ===================
      
* Release unwanted workspace.
      CALL PSX_FREE( IPIEST, STATUS )
      CALL PSX_FREE( IPQEST, STATUS )
      IF ( NU .GT. 0 ) THEN
         CALL PSX_FREE( IPUEST, STATUS )
      ENDIF
      IF ( VAR ) THEN
         CALL PSX_FREE( IPVIEST, STATUS )
         CALL PSX_FREE( IPVQEST, STATUS )
         IF ( NU .GT. 0 ) THEN
            CALL PSX_FREE( IPVUEST, STATUS )
         ENDIF
      ELSE
         CALL PSX_FREE( IPWEIGHT, STATUS )
      ENDIF

* Close down.
 99   CONTINUE
      
*  End the NDF context.
      CALL NDF_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'POLCAL_ERROR', 'POLCAL: Error producing '//
     :                 'Stokes parameters.', STATUS )
      END IF

      END
