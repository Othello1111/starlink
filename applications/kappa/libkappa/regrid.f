      SUBROUTINE REGRID( STATUS )
*+
*  Name:
*     REGRID

*  Purpose:
*     Applies a geometrical transformation to an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL REGRID( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application uses a specified Mapping to re-grid the pixel
*     positions in an NDF. The specified Mapping should transform pixel 
*     co-ordinates in the input NDF into the corresponding pixel 
*     co-ordinates in the output NDF. 
*
*     By default, the bounds of the output pixel grid are chosen so that
*     they just encompasses all the transformed input data, but they can
*     be set explicitly using parameters LBOUND and UBOUND.
*
*     The data value stored at each output pixel is determined by 
*     transforming the pixel co-ordinates at the centre of the output 
*     pixel using the inverse of the supplied Mapping. This gives the
*     corresponding pixel co-ordinates in the input NDF. In general this
*     input position will not correspond to a pixel centre, and so the
*     input data arrays (Data and Variance) must be interpolated to obtain 
*     the values for the output pixel. The scheme used to perform this
*     interpolation can be selected using parameter METHOD.
*
*     The Mapping to use can be supplied in several different ways (see
*     parameter MAPPING). 

*  Usage:
*     regrid in out [method]

*  ADAM Parameters:
*     IN = NDF (Read)
*        The NDF to be transformed.
*     LBOUND( ) = _INTEGER (Read)
*        The lower pixel-index bounds of the output NDF.  The number of
*        values must be equal to the number of dimensions in the output 
*        NDF.  If a null value is supplied, default bounds will be used 
*        which are just low enough to fit in all the transformed pixels 
*        of the input NDF. [!]
*     MAPPING = FILENAME (Read)
*        The name of a file containing the Mapping to be used, or null (!)
*        if the input NDF is to be mapped into its own current Frame. If a 
*        file is supplied, the forward direction of the Mapping should 
*        transform pixel co-ordinates in the input NDF into the 
*        corresponding pixel co-ordinates in the output NDF. The file 
*        may be:
*
*        - A text file containing a textual representation of the AST Mapping 
*        to use. Such files can be created by WCSADD.
*
*        - A text file containing a textual representation of an AST
*        FrameSet. If the FrameSet contains a Frame with Domain PIXEL,
*        then the Mapping used is the Mapping from the PIXEL Frame to the
*        current Frame. If there is no PIXEL Frame in the FrameSet, then
*        the Mapping used is the Mapping from the base Frame to the Current 
*        Frame.
*
*        - A FITS file. The Mapping used is the Mapping from the FITS
*        pixel co-ordinates in which the centre of the bottom left pixel
*        is at co-ordinates (1,1), to the co-ordinate system represented 
*        by the primary WCS headers, CRVAL, CRPIX, etc.
*
*        - An NDF. The Mapping used is the Mapping from the PIXEL Frame
*        to the Current Frame of its WCS FrameSet.
*
*        If a null (!) value is supplied, the Mapping used is the Mapping 
*        from pixel co-ordinates in the input NDF to the current Frame in 
*        the input NDF. The output NDF will then have pixel co-ordinates 
*        which match the co-ordinates of the current Frame of the input 
*        NDF (apart from possible additional scalings as specified by the
*        SCALE parameter).
*     METHOD = LITERAL (Read)
*        The interpolation method used to resample the input array.
*        The following values are permitted:
*
*        -  "Nearest"   -- Nearest neighbour sampling.
*
*        -  "Linear"    -- Linear interpolation.
*
*        -  "Sinc"      -- Sum of surrounding pixels weighted using
*                          a 1-d sinc(pi*x) kernel.
*
*        -  "SincSinc"  -- Sum of surrounding pixels weighted using
*                          a 1-d sinc(pi*x)*sinc(k*pi*x) kernel.
*
*        -  "SincCos"   -- Sum of surrounding pixels weighted using
*                          a 1-d sinc(pi*x)*cos(k*pi*x) kernel.
*
*        -  "SincGauss" -- Sum of surrounding pixels weighted using
*                          a 1-d sinc(pi*x)*exp(-k*x*x) kernel.
*
*        -  "BlockAve"  -- Block averaging over all pixels in the 
*                          surrounding N-dimensional cube.
*
*        In the above, sinc(z)=sin(z)/z.  Some of these schemes will 
*        require additional parameters to be supplied via the PARAMS 
*        parameter.  A more detailed discussion of these schemes is
*        given in the "Sub-Pixel Interpolation Schemes" section below.
*        [current value]
*     OUT = NDF (Write)
*        The transformed NDF.
*     PARAMS( ) = _DOUBLE (Read)
*        Parameters required to control the resampling scheme.  One or
*        more values may be required to specify the exact resampling
*        behaviour, according to the value of the METHOD parameter.
*        See the section on "Sub-Pixel Interpolation Schemes".
*     SCALE( ) = _DOUBLE (Read)
*        Axis scaling factors which are used to modify the supplied Mapping.
*        If the number of supplied values is less than the number of output
*        axes associated with the Mapping, the final supplied value is
*        duplicated for the missing axes. In effect, transformed input 
*        co-ordinate axis values would be multiplied by these factors to 
*        obtain the corresponding output pixel co-ordinates. If a null (!) 
*        value is supplied for SCALE, then default values are used which 
*        depends on the value of parameter MAPPING. If a null value is 
*        supplied for MAPPING then the default scaling factors are chosen 
*        so that pixels retain their original size (very roughly) after
*        transformation. If as non-null value is supplied for MAPPING then 
*        the default scaling factor used is 1.0 for each axis (i.e. no 
*        scaling). [!]
*     TITLE = LITERAL (Read)
*        A Title for the output NDF structure.  A null value (!)
*        propagates the title from the input NDF to the output NDF. [!]
*     TOL = _DOUBLE (Read)
*        The maximum tolerable geometrical distortion which may be
*        introduced as a result of approximating non-linear Mappings 
*        by a set of piece-wise linear transforms.  The resampling
*        algorithm approximates non-linear co-ordinate transformations
*        in order to improve performance, and this parameter controls
*        how inaccurate the resulting approximation is allowed to be,
*        as a displacement in pixels of the input NDF.  A value of 
*        zero will ensure that no such approximation is done, at the 
*        expense of increasing execution time.
*        [0.2]
*     UBOUND( ) = _INTEGER (Read)
*        The upper pixel-index bounds of the output NDF.  The number of
*        values must be equal to the number of dimensions of the output
*        NDF.  If a null value is supplied, default bounds will be used 
*        which are just high enough to fit in all the transformed pixels 
*        of the input NDF. [!]

*  Examples:
*     regrid sg28948 sg28948r mapping=rotate.ast
*        Here sg28948 is resampled into a new co-ordinate system using
*        the AST Mapping stored in a text file called rotate.ast (which
*        may have been created using WCSADD for instance).
*     regrid flat distorted mapping=\!
*        This transforms the NDF called flat.sdf into its current
*        co-ordinate Frame, writing the result to an NDF called
*        distorted.sdf.  It uses nearest-neighbour resampling.
*        If the units of the PIXEL and current co-ordinate Frames of 
*        flat are of similar size, then the pixel co-ordinates of 
*        distorted will be the same as the current co-ordinates of
*        flat, but if there is a large scale discrepancy a scaling 
*        factor will be applied to give the output NDF a similar size 
*        to the input one.  The output NDF will be just large enough 
*        to hold the transformed copies of all the pixels from "flat".
*     regrid flat distorted mapping=\! scale=1 method=sinccos params=[0,3]
*        As the previous example, but the additional scaling factor will
*        not be applied even in the case of large size discrepancy,
*        and a sinc*cos 1-dimensional resampling kernel is used which
*        rolls off at a distance of 3 pixels from the central one.
*     regrid flat distorted mapping=\! scale=0.2 method=blockave params=2
*        In this case, an additional shrinking factor of 0.2 is being
*        applied to the output NDF (i.e. performed following the 
*        Mapping from pixel to current co-ordinates), and the resampling
*        is being done using a block averaging scheme in which a 
*        cube extending two pixels either side of the central pixel
*        is averaged over to produce the output value.  If the 
*        PIXEL-domain and current Frame pixels have (about) the same 
*        size, this will result in every pixel from the input NDF 
*        adding a contribution to one pixel of the output NDF.
*     regrid a119 a119s mapping=\! lbound=[1,-20] ubound=[256,172]
*        This transforms the NDF called a119 into an NDF called a119s.
*        It uses nearest-neighbour resampling.  The shape of a119s 
*        is forced to be (1:256,-20:172) regardless of the location
*        of the transformed pixels of a119.

*  Sub-Pixel Interpolation Schemes:
*     There is no such thing as a perfect sub-pixel interpolation
*     scheme and, in practice, all resampling will result in some
*     degradation of gridded data.  A range of schemes is therefore
*     provided, from which you can choose the one which best suits
*     your needs.
*
*     In general, a balance must be struck between schemes which tend
*     to degrade sharp features in the data by smoothing them, and
*     those which attempt to preserve sharp features. The latter will
*     often tend to introduce unwanted oscillations, typically visible
*     as "ringing" around sharp features and edges, especially if the
*     data are under-sampled (i.e. if the sharpest features are less
*     than about two pixels across). In practice, a good interpolation
*     scheme is likely to be a compromise and may exhibit some aspects
*     of both these features.
*
*     For under-sampled data, some interpolation schemes may appear to
*     preserve data resolution because they transform single input
*     pixels into single output pixels, rather than spreading their
*     data between several output pixels. While this may look
*     better cosmetically, it can result in a geometrical shift of
*     sharp features in the data. You should beware of this if you
*     plan to use such features (e.g.) for image alignment.
*
*     The following are two easy-to-use sub-pixel interpolation
*     schemes which are generally applicable:
*
*     - "Nearest" -- This is the simplest possible scheme, in which
*     the value of the input pixel with the nearest centre to the
*     interpolation point is used. This is very quick to execute and
*     will preserve single-pixel features in the data, but may
*     displace them by up to half their width along each dimension. It
*     often gives a good cosmetic result, so is useful for quick-look
*     processing, but is unsuitable if accurate geometrical
*     transformation is required.
*
*     - "Linear" -- This scheme uses linear interpolation
*     between the nearest neighbouring pixels in the
*     input grid (there are two neighbours in one dimension, four
*     neighbours in two dimensions, eight in three dimensions,
*     etc.). It is superior to the nearest-pixel scheme (above) in not
*     displacing features in the data, yet it still executes fairly
*     rapidly. It is generally a safe choice if you do not have any
*     particular reason to favour another scheme, since it cannot
*     introduce oscillations. However, it does introduce some spatial
*     smoothing which varies according to the distance of the
*     interpolation point from the neighbouring pixels. This can
*     degrade the shape of sharp features in the data in a
*     position-dependent way. It may also show in the output variance
*     grid (if used) as a pattern of stripes or fringes.
*
*     An alternative set of interpolation schemes is based on forming
*     the interpolated value from the weighted sum of a set of
*     surrounding pixel values (not necessarily just the nearest
*     neighbours). This approach has its origins in the theory of
*     digital filtering, in which interpolated values are obtained by
*     conceptually passing the sampled data (represented by a grid of
*     delta functions) through a linear filter which implements a
*     convolution. Because the convolution kernel is continuous, the
*     convolution yields a continuous function which may then be
*     evaluated at fractional pixel positions. The (possibly
*     multi-dimensional) kernel is usually regarded as "separable" and
*     formed from the product of a set of identical 1-dimensional
*     kernel functions, evaluated along each dimension. Different
*     interpolation schemes are then distinguished by the choice of
*     this 1-dimensional interpolation kernel. The number of
*     surrounding pixels which contribute to the result may also be
*     varied.
*
*     From a practical standpoint, it is useful to divide the weighted
*     sum of pixel values by the sum of the weights when determining
*     the interpolated value.  Strictly, this means that a true
*     convolution is no longer being performed. However, the
*     distinction is rarely important in practice because (for
*     slightly subtle reasons) the sum of weights is always
*     approximately constant for good interpolation kernels. The
*     advantage of this technique, which is used here, is that it can
*     easily accommodate missing data and tends to minimise unwanted
*     oscillations at the edges of the data grid.
*
*     In the following schemes, which are based on a 1-dimensional
*     interpolation kernel, the first element of the PARAMS parameter
*     should be used to specify how many pixels are to contribute to the
*     interpolated result on either side of the interpolation point in
*     each dimension (the nearest integer value is used). Execution time
*     increases rapidly with this number. Typically, a value of 2 is
*     appropriate and the minimum value used will be 1 (i.e. two pixels
*     altogether, on on either side of the interpolation point). A value 
*     of zero or less may be given for PARAMS(1) to indicate that a 
*     suitable number of pixels should be calculated automatically.
*
*     - "Sinc" -- This scheme uses a sinc(pi*x) kernel, where x is the
*     pixel offset from the interpolation point and sinc(z)=sin(z)/z. This
*     sometimes features as an "optimal" interpolation kernel in books on
*     image processing. Its supposed optimality depends on the assumption
*     that the data are band-limited (i.e. have no spatial frequencies above
*     a certain value) and are adequately sampled. In practice, astronomical
*     data rarely meet these requirements. In addition, high spatial
*     frequencies are often present due (e.g.) to image defects and cosmic
*     ray events. Consequently, substantial ringing can be experienced with
*     this kernel. The kernel also decays slowly with distance, so that
*     many surrounding pixels are required, leading to poor performance.
*     Abruptly truncating it, by using only a few neighbouring pixels,
*     improves performance and may reduce ringing (if PARAMS(1) is set to
*     zero, then only two pixels will be used on either side). However, a
*     more gradual truncation, as implemented by other kernels, is generally
*     to be preferred. This kernel is provided mainly so that you can
*     convince yourself not to use it!
*
*     - "SincSinc" -- This scheme uses an improved kernel, of the form
*     sinc(pi*x).sinc(k*pi*x), with k a constant, out to the point where
*     sinc(k*pi*x) goes to zero, and zero beyond. The second sinc() factor
*     provides an "envelope" which gradually rolls off the normal sinc(pi*x)
*     kernel at large offsets. The width of this envelope is specified by
*     giving the number of pixels offset at which it goes to zero by means
*     of the PARAMS(2) value, which should be at least 1.0 (in addition,
*     setting PARAMS(1) to zero will select the number of contributing
*     pixels so as to utilise the full width of the kernel, out to where it
*     reaches zero). The case given by PARAMS(1)=2, PARAMS(2)=2 is typically
*     a good choice and is sometimes known as the Lanczos kernel. This is a
*     valuable general-purpose interpolation scheme, intermediate in its
*     visual effect on images between the "Nearest" and "Linear"
*     schemes. Although the kernel is slightly oscillatory, ringing is
*     adequately suppressed if the data are well sampled.
*
*     - "SincCos" -- This scheme uses a kernel of the form
*     sinc(pi*x)*cos(k*pi*x), with k a constant, out to the point where
*     cos(k*pi*x) goes to zero, and zero beyond. As above, the cos() factor
*     provides an envelope which gradually rolls off the sinc() kernel
*     at large offsets. The width of this envelope is specified by giving
*     the number of pixels offset at which it goes to zero by means
*     of the PARAMS(2) value, which should be at least 1.0 (in addition,
*     setting PARAMS(1) to zero will select the number of contributing
*     pixels so as to utilise the full width of the kernel, out to where it
*     reaches zero). This scheme gives similar results to the
*     "SincSinc" scheme, which it resembles.
*
*     - "SincGauss" -- This scheme uses a kernel of the form
*     sinc(pi*x).exp(-k*x*x), with k a positive constant. Here, the sinc()
*     kernel is rolled off using a Gaussian envelope which is specified by
*     giving its full-width at half-maximum (FWHM) by means of the PARAMS(2)
*     value, which should be at least 0.1 (in addition, setting PARAMS(1)
*     to zero will select the number of contributing pixels so as to utilise
*     the width of the kernel out to where the envelope declines to 1% of its
*     maximum value). On astronomical images and spectra, good results are
*     often obtained by approximately matching the FWHM of the
*     envelope function, given by PARAMS(2), to the point spread function
*     of the input data. However, there does not seem to be any theoretical
*     reason for this.
*
*     In addition, the following scheme is provided which is not based
*     on a 1-dimensional kernel:
*
*     - "BlockAve" -- This scheme simply takes an average of all the
*     pixels on the input grid in a cube centred on the interpolation
*     point.  The number of pixels in the cube is determined by the
*     value of the first element of the PARAMS array, which gives
*     the number of pixels in each dimension on either side of the
*     central point.  Hence a block of (2 * PARAMS(1))**NDIM_IN
*     pixels in the input grid will be examined to determine the
*     value of the output pixel.  If the input NDF has no variance,
*     then all valid pixels in this cube
*     will be averaged in to the result with equal weight.
*     If a variance is present, then each input pixel will be 
*     weighted proportionally to the reciprocal of its variance; any
*     pixel without a valid variance will be discarded.  This scheme
*     is suitable where the output grid is much coarser than the 
*     input grid; if the ratio of pixel sizes is R then a suitable
*     value of PARAMS(1) may be R/2.

*  Notes:
*     - If the input NDF contains a Variance component, a Variance 
*     component will be written to the output NDF.  It will be 
*     calculated on the assumption that errors on the input data 
*     values are statistically independent and that their variance
*     estimates may simply be summed (with appropriate weighting 
*     factors) when several input pixels contribute to an output data 
*     value. If this assumption is not valid, then the output error
*     estimates may be biased. In addition, note that the statistical
*     errors on neighbouring output data values (as well as the 
*     estimates of those errors) may often be correlated, even if the
*     above assumption about the input data is correct, because of
*     the sub-pixel interpolation schemes employed. 
*
*     - This task is based on the AST_RESAMPLE<X> routine described in
*     SUN/210.

*  Implementation Status:
*     -  No flux conservation flag has been implemented.
*     -  The LABEL, UNITS, and HISTORY components, and all extensions are 
*     propagated. TITLE is controlled by the TITLE parameter. DATA,
*     VARIANCE and WCS are propagated after appropriate modification. The
*     QUALITY component is also propagated if Nearest Neighbour
*     interpolation is being used. The AXIS components is not propagated.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     -  There can be an arbitrary number of NDF dimensions.

*  Related Applications:
*     KAPPA: FLIP, ROTATE, SLIDE, WCSADD, WCSALIGN.
*     CCDPACK: TRANLIST, TRANNDF, WCSEDIT.

*  Authors:
*     MBT: Mark Taylor (STARLINK)
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     10-DEC-2001 (MBT):
*        Original version.
*     8-Jan-2002 (DSB):
*        Prologue modified. Some parameter defaults and logic changed. Allow 
*        the extra scale factor to be different for each axis. Protect
*        against AST__BAD values being returned by AST_TRAN.
*     15-Jan-2001 (DSB):
*        Modified propagation of WCS to use KPG1_ASFIX. Re-named
*        from RESAMPLE to REGRID. Propagate QUALITY if Nearest Neighbour
*        interpolation is being used.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST definitions and declarations
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'NDF_PAR'          ! NDF system constants
      INCLUDE 'PAR_ERR'          ! Parameter system error constants

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER KPG1_FLOOR         ! Most positive integer .LE. a given real
      INTEGER KPG1_CEIL          ! Most negative integer .GE. a given real
      EXTERNAL AST_ISAMAPPING

*  Local Variables:
      CHARACTER DTYPE * ( NDF__SZFTP ) ! Full data type name
      CHARACTER ITYPE * ( NDF__SZTYP ) ! HDS Data type name
      CHARACTER METHOD * ( 16 )  ! Name of resampling scheme
      DOUBLE PRECISION DLBNDI( NDF__MXDIM ) ! Lower bounds of input array
      DOUBLE PRECISION DUBNDI( NDF__MXDIM ) ! Upper bounds of input array
      DOUBLE PRECISION LPO       ! Lower bound in output array
      DOUBLE PRECISION PARAMS( 4 ) ! Additional parameters for resampler
      DOUBLE PRECISION PT1I( NDF__MXDIM ) ! First input point
      DOUBLE PRECISION PT1O( NDF__MXDIM ) ! First output point
      DOUBLE PRECISION PT2I( NDF__MXDIM ) ! Second input point
      DOUBLE PRECISION PT2O( NDF__MXDIM ) ! Second output point
      DOUBLE PRECISION SCALE( NDF__MXDIM ) ! Axis scale factors
      DOUBLE PRECISION SCVAL     ! Value of a single axis scale factor
      DOUBLE PRECISION TOL       ! Tolerance for linear transform approximation
      DOUBLE PRECISION UPO       ! Upper bound in output array
      DOUBLE PRECISION XL( NDF__MXDIM ) ! Position of lowest value
      DOUBLE PRECISION XU( NDF__MXDIM ) ! Position of highest value
      INTEGER BMAX( NDF__MXDIM ) ! Maximum values for array bounds
      INTEGER ELI                ! Number of elements in input NDF
      INTEGER ELO                ! Number of elements in output NDF
      INTEGER FLAGS              ! Flags sent to AST_RESAMPLE<X>
      INTEGER I                  ! Loop variable
      INTEGER INTERP             ! Resampling scheme identifier
      INTEGER IPDATI             ! Pointer to input Data array
      INTEGER IPDATO             ! Pointer to output Data array
      INTEGER IPQUAI             ! Pointer to input Quality array
      INTEGER IPQUAO             ! Pointer to output Quality array
      INTEGER IPVARI             ! Pointer to input Variance array
      INTEGER IPVARO             ! Pointer to output Variance array
      INTEGER JFRM               ! Index of Frame for joining FrameSets
      INTEGER LBDEF( NDF__MXDIM ) ! Default value for LBOUND
      INTEGER LBNDI( NDF__MXDIM ) ! Lower bounds of input NDF pixel co-ordinates
      INTEGER LBNDO( NDF__MXDIM ) ! Lower bounds of output NDF
      INTEGER MAPHI              ! Half-pixel shift Mapping at input end
      INTEGER MAPHIO             ! Mapping with half-pixel shifts at both ends
      INTEGER MAPHO              ! Half-pixel shift Mapping at output end
      INTEGER MAPIO              ! Mapping from input to output NDF
      INTEGER MAPJ               ! Mapping to perform extra scalings
      INTEGER MAPX               ! Basic Mapping to use (without extra scaling)
      INTEGER MAXPIX             ! Max size of linear approximation region
      INTEGER NBAD               ! Number of bad pixels
      INTEGER NDFI               ! NDF identifier of input NDF
      INTEGER NDFO               ! NDF identifier of output NDF
      INTEGER NDIMI              ! Number of dimensions of input NDF
      INTEGER NDIMO              ! Number of dimensions of output NDF
      INTEGER NPARAM             ! Number of parameters required for resampler
      INTEGER NSCALE             ! Number of supplied scale factors
      INTEGER UBDEF( NDF__MXDIM ) ! Default value for UBOUND
      INTEGER UBNDI( NDF__MXDIM ) ! Upper bounds of input NDF pixel co-ordinates
      INTEGER UBNDO( NDF__MXDIM ) ! Upper bounds of output NDF
      INTEGER WCSI               ! WCS FrameSet of input NDF
      INTEGER WCSO               ! WCS FrameSet of the output NDF
      LOGICAL BAD                ! May there be bad pixels?
      LOGICAL CURENT             ! Resample into current Frame?
      LOGICAL HASQUA             ! Does the input NDF have Quality component?
      LOGICAL HASVAR             ! Does the input NDF have Variance component?
      LOGICAL SCEQU              ! Are all axis scale factors equal?
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Start a new AST context.
      CALL AST_BEGIN( STATUS )

*  Start a new NDF context.
      CALL NDF_BEGIN

*  Obtain the input NDF and get the transformation Mapping.
*  ========================================================

*  Open the input NDF.
      CALL LPG_ASSOC( 'IN', 'READ', NDFI, STATUS )

*  Get its dimensions.
      CALL NDF_BOUND( NDFI, NDF__MXDIM, LBNDI, UBNDI, NDIMI, STATUS )

*  See if it has a Variance component.
      CALL NDF_STATE( NDFI, 'VARIANCE', HASVAR, STATUS )
*  Obtain its WCS component.
      CALL KPG1_GTWCS( NDFI, WCSI, STATUS )

*  Attempt to get an externally supplied Mapping - read it from a file.
*  N.B. do not tell ATL1_GTOBJ to look for a Mapping, since in this 
*  case it will extract the Mapping from a FrameSet for us, which
*  we need to do for ourselves if it is going to be done. If a null 
*  value is supplied, annul the error and indicate that the NDF is 
*  to be mapped into its own current Frame.
      IF( STATUS .NE. SAI__OK ) GO TO 999
      CALL ATL1_GTOBJ( 'MAPPING', ' ', AST_NULL, MAPX, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         CURENT = .TRUE.
         MAPX = WCSI

*  In the event of any other error, write an explanatory comment (ATL1_GTOBJ
*  does not generate very user-friendly messages) and bail out.
      ELSE IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'REGRID_ERR1', 'REGRID: $MAPPING does not '//
     :                 'contain an AST Object.', STATUS )
         GO TO 999

*  If an external Object was obtained succesfully, report an error if it
*  is not a Mapping (it may be a FrameSet, which is-a Mapping).
      ELSE IF( .NOT. AST_ISAMAPPING( MAPX, STATUS ) ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR2', 'REGRID: File $MAPPING does'//
     :                 ' not contain an AST Mapping or FrameSet.', 
     :                 STATUS )
         GO TO 999

*  A usable external Mapping has been supplied. Indicate that we will
*  not be mapping the NDF into its own current Frame.
      ELSE
         CURENT = .FALSE.
      END IF

*  If this is a FrameSet then extract the Mapping explicitly.
      IF ( AST_ISAFRAMESET( MAPX, STATUS ) ) THEN

*  See whether a PIXEL-domain Frame exists.
          CALL KPG1_ASFFR( MAPX, 'PIXEL', JFRM, STATUS )

*  If so, we will use the PIXEL->current Mapping.
          IF ( JFRM .NE. AST__NOFRAME ) THEN
             MAPX = AST_GETMAPPING( MAPX, JFRM, AST__CURRENT, STATUS )

*  Otherwise, use the base->current Mapping.
          ELSE
             MAPX = AST_GETMAPPING( MAPX, AST__BASE, AST__CURRENT,
     :                              STATUS )
          END IF
      END IF

*  Check the base Frame of the Mapping has the right number of dimensions.
      IF ( AST_GETI( MAPX, 'Nin', STATUS ) .NE. NDIMI ) THEN
         CALL MSG_SETI( 'NAX', AST_GETI( MAPX, 'Nin', STATUS ) )
         CALL MSG_SETI( 'NDIM', NDIMI )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR3', 'REGRID: Mapping has ^NAX '//
     :                 'input axes and NDF has ^NDIM dimensions', 
     :                 STATUS )
         GO TO 999
      END IF

*  Get the number of output axes of the Mapping, which will be the 
*  dimensionality of the output NDF.
      NDIMO = AST_GETI( MAPX, 'Nout', STATUS )
      
*  Check that resampling into this Frame will be possible.
      IF ( STATUS .NE. SAI__OK ) GO TO 999
      IF ( NDIMO .GT. NDF__MXDIM ) THEN
         CALL MSG_SETI( 'NDIM', NDIMO )
         CALL MSG_SETI( 'MAX', NDF__MXDIM )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR4', 'REGRID: Output Frame has '//
     :                 '^NDIM dimensions - maximum is ^MAX.', STATUS )
         GO TO 999
      END IF

*  Get the qualifications to the transformation.
*  =============================================

*  Initialise the resampling routine control flags.
      FLAGS = 0

*  Get the method for calculating the output array value from the
*  input values.
      CALL PAR_CHOIC( 'METHOD', 'NEAREST', 'NEAREST,LINEAR,SINC,'//
     :                'SINCSINC,SINCCOS,SINCGAUSS,BLOCKAVE', .FALSE.,
     :                METHOD, STATUS )

      IF ( STATUS .NE. SAI__OK ) GO TO 999
      IF ( METHOD .EQ. 'NEAREST' ) THEN
         CALL MSG_SETC( 'M', 'Nearest Neighbour' )
         INTERP = AST__NEAREST
         NPARAM = 0
      ELSE IF ( METHOD .EQ. 'LINEAR' ) THEN
         CALL MSG_SETC( 'M', 'Bilinear' )
         INTERP = AST__LINEAR
         NPARAM = 0
      ELSE IF ( METHOD .EQ. 'SINC' ) THEN
         CALL MSG_SETC( 'M', 'Sinc' )
         INTERP = AST__SINC
         NPARAM = 1
      ELSE IF ( METHOD .EQ. 'SINCSINC' ) THEN
         CALL MSG_SETC( 'M', 'SincSinc' )
         INTERP = AST__SINCSINC
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'SINCCOS' ) THEN
         CALL MSG_SETC( 'M', 'SincCos' )
         INTERP = AST__SINCCOS
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'SINCGAUSS' ) THEN
         CALL MSG_SETC( 'M', 'SincGauss' )
         INTERP = AST__SINCGAUSS
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'BLOCKAVE' ) THEN
         CALL MSG_SETC( 'M', 'BlockAve' )
         INTERP = AST__BLOCKAVE
         NPARAM = 1
      END IF
      CALL MSG_OUT( 'REGRID_MSG1', '  Using ^M interpolation.', 
     :              STATUS )

*  Get an additional parameter vector if required.
      IF ( NPARAM .GT. 0 ) THEN
         CALL PAR_EXACD( 'PARAMS', NPARAM, PARAMS, STATUS )
      END IF

*  Get the tolerance for Mapping linear approximation.
      CALL PAR_GET0D( 'TOL', TOL, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Set the initial scale size for the Mapping linear approximation
*  algorithm (see AST_RESAMPLE<X> documentation).
      MAXPIX = 50

*  Add an additional scaling factor to the Mapping.
*  ================================================

*  Get the values of the scale factors from the parameter system. If a null
*  (!) is supplied, annul the error and calculate default values.
      IF( STATUS .NE. SAI__OK ) GO TO 999
      CALL PAR_GET1D( 'SCALE', NDIMO, SCALE, NSCALE, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN 
         CALL ERR_ANNUL( STATUS )

*  If we are using a Mapping specified by parameter MAPPING, the default
*  scaling factor is unity on all axes. Otherwise, we need to calculate
*  suitable default values.
         IF( .NOT. CURENT ) THEN
            SCVAL = 1.0
            SCEQU = .TRUE.
         ELSE

*  Work out the 'size' of a pixel in the input and output arrays.  
*  The purpose of this is just to decide whether they are about the 
*  same size; if they are then SCALE will default to unity, if not 
*  then it will default to some size-equalising factor for each axis.  
*  First set up the corners in the base Frame of a single pixel at teh
*  centre of th einput image.
            DO I = 1, NDIMI
               PT1I( I ) = 0.5D0 * DBLE( LBNDI( I ) + UBNDI( I ) ) - 0.5D0
               PT2I( I ) = PT1I( I ) + 1D0
            END DO

*  Now find the bounds within the output image of this pixel.
            DO I = 1, NDIMO
               CALL AST_MAPBOX( MAPX, PT1I, PT2I, .TRUE., I, PT1O( I ),
     :                          PT2O( I ), XL, XU, STATUS )
            END DO

*  Find the scaling factors which result in the transformed and scaled
*  pixel having a size of unity on each axis. Ignore values between 0.25
*  and 4. If any transformed position is bad, use a scaling factor of 
*  1.0 for that axis.
            SCVAL = 0.0
            DO I = 1, NDIMO
               IF( PT1O( I ) .NE. AST__BAD .AND. 
     :             PT2O( I ) .NE. AST__BAD ) THEN
                  SCALE( I ) = ABS( PT2O( I ) - PT1O( I ) )

                  IF( SCALE( I ) .GT. 0.0 ) THEN
                     IF( SCALE( I ) .LE. 0.25 .OR. 
     :                   SCALE( I ) .GE. 4.0 ) THEN
                        SCALE( I ) = 1.0/SCALE( I )

                     ELSE
                        SCALE( I ) = 1.0

                     END IF                     

                  ELSE
                     SCALE( I ) = 1.0

                  END IF                  

               ELSE
                  SCALE( I ) = 1.0

               END IF

*  Note if all scale values are equal (SCEQU), and not what this
*  value is (SCVAL).
               IF( I .EQ. 1 ) THEN
                  SCVAL = SCALE( 1 )
                  SCEQU = .TRUE.
               ELSE IF( SCALE( I ) .NE. SCVAL ) THEN
                  SCEQU = .FALSE.
               END IF
                  
            END DO
            
         END IF

*  If SCALE values were supplied, see if they are all the same, and copy
*  thre last value to any missing values.
      ELSE
         SCVAL = SCALE( 1 )
         SCEQU = .TRUE.
         DO I = 2, NDIMO
            IF( I .LE. NSCALE ) THEN
               IF( SCALE( I ) .NE. SCVAL ) SCEQU = .FALSE.
            ELSE
               SCALE( I ) = SCALE( NSCALE )
            END IF
         END DO

      END IF

*  If any scale factor is not unity, report them all, and use them.
      IF( .NOT. SCEQU .OR. SCVAL .NE. 1.0 ) THEN     

         IF( SCEQU ) THEN 
            CALL MSG_SETR( 'S', REAL( SCVAL ) )
            CALL MSG_OUT( 'REGRID_MSG2 ', '  The supplied Mapping '//
     :                    'is being modified by a scale factor of ^S '//
     :                    'on each axis.', STATUS )      
           MAPJ = AST_ZOOMMAP( NDIMO, SCVAL, ' ', STATUS )

         ELSE
            DO I = 1, NDIMO 
               CALL MSG_SETR( 'S', REAL( SCALE( I ) ) )
               IF( I .NE. NDIMO ) CALL MSG_SETC( 'S', ',' )
            END DO
            CALL MSG_OUT( 'REGRID_MSG3', '  The supplied Mapping is'//
     :                    '  being modified by scale factors of (^S).',
     :                    STATUS )      
            MAPJ = AST_MATRIXMAP( NDIMI, NDIMO, 1, SCALE, ' ', STATUS )
         END IF 

*  Generate the actual mapping from the input to output array, by
*  combining the Mapping from base to current frames and the Mapping
*  created above. Simplify it.
         MAPIO = AST_SIMPLIFY( AST_CMPMAP( MAPX, MAPJ, .TRUE., ' ',
     :                                     STATUS ), STATUS )

*  Just clone the original Mapping if the scale factor is unity.
      ELSE
         MAPJ = AST_UNITMAP( NDIMO, ' ', STATUS )
         MAPIO = AST_CLONE( MAPX, STATUS )
      END IF

*  Get the bounds of the output NDF.
*  =================================

*  Work out the bounds of an array which would contain the resampled 
*  copy of the whole input array.
      DO I = 1, NDIMI
         DLBNDI( I ) = DBLE( LBNDI( I ) - 1 )
         DUBNDI( I ) = DBLE( UBNDI( I ) )
      END DO
      DO I = 1, NDIMO
         CALL AST_MAPBOX( MAPIO, DLBNDI, DUBNDI, .TRUE., I, LPO, UPO,
     :                    XL, XU, STATUS )
         LBDEF( I ) = KPG1_FLOOR( REAL( LPO ) ) + 1
         UBDEF( I ) = KPG1_CEIL( REAL( UPO ) )
         BMAX( I ) = VAL__MAXI
      END DO

*  Get the actual values for these bounds from the parameter system, 
*  using the calculated values as defaults.
      CALL PAR_GDR1I( 'LBOUND', NDIMO, LBDEF, VAL__MINI, VAL__MAXI,
     :                .TRUE., LBNDO, STATUS )
      CALL PAR_GRM1I( 'UBOUND', NDIMO, UBDEF, LBNDO, BMAX, .TRUE.,
     :                UBNDO, STATUS )

*  Do a check that there is some overlap between the requested range
*  and the resampled image of the NDF.
      DO I = 1, NDIMO
         IF ( UBNDO( I ) .LT. LBDEF( I ) .OR. 
     :        LBNDO( I ) .GT. UBDEF( I ) ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'REGRID_ERR5', 'REGRID: Requested '//
     :                    'bounds are entirely outside resampled '//
     :                    'region', STATUS )
            GO TO 999
         END IF
      END DO

*  Create and configure the output NDF.
*  ====================================

*  Create a new NDF by propagation from the input one.
      CALL LPG_PROP( NDFI, 'UNIT', 'OUT', NDFO, STATUS )

*  Get a title for the new NDF from the parameter system.
      CALL NDF_CINP( 'TITLE', NDFO, 'TITLE', STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Set the shape of the output NDF.
      CALL NDF_SBND( NDIMO, LBNDO, UBNDO, NDFO, STATUS )

*  Determine a data type which can be used for operations on the
*  Data and possibly Variance components of the NDF.
      CALL NDF_MTYPN( '_BYTE,_UBYTE,_WORD,_UWORD,_INTEGER,_REAL,'//
     :                '_DOUBLE', 1, NDFI, 'DATA,VARIANCE', ITYPE,
     :                DTYPE, STATUS )

*  Set the Data and possibly Variance component data types.
      CALL NDF_STYPE( ITYPE, NDFO, 'DATA', STATUS )
      IF ( HASVAR ) THEN
         CALL NDF_STYPE( ITYPE, NDFO, 'VARIANCE', STATUS )
      END IF
      
*  Store a suitably modified copy of the input WCS in the output.
      CALL KPG1_ASFIX( MAPIO, NDFI, NDFO, STATUS )

*  Map the array components.
*  =========================

*  Map the Data array of the input and output NDFs.
      CALL NDF_MAP( NDFI, 'DATA', ITYPE, 'READ', IPDATI, ELI, STATUS )
      CALL NDF_MAP( NDFO, 'DATA', ITYPE, 'WRITE', IPDATO, ELO,
     :              STATUS )

*  Find out if there may be bad pixels in the mapped Data array.
      CALL NDF_BAD( NDFI, 'DATA', .FALSE., BAD, STATUS )

*  Map the Variance component of the input and output NDFs if we are
*  processing variances.
      IF ( HASVAR ) THEN
         CALL NDF_MAP( NDFI, 'VARIANCE', ITYPE, 'READ', IPVARI, ELI,
     :                 STATUS )
         CALL NDF_MAP( NDFO, 'VARIANCE', ITYPE, 'WRITE', IPVARO,
     :                 ELO, STATUS )

*  Unless we already know of bad values in the Data component, see 
*  whether the Variance component may contain them.
         IF ( .NOT. BAD ) THEN
            CALL NDF_BAD( NDFI, 'VARIANCE', .FALSE., BAD, STATUS )
         END IF

*  Record the fact that variances should be processed.
         FLAGS = FLAGS + AST__USEVAR
      END IF

*  If either the Data or Variance component of the input NDF may have
*  bad values, record this fact.
      IF ( BAD ) THEN
         FLAGS = FLAGS + AST__USEBAD
      END IF

*  Perform the resampling.
*  =======================

*  Since AST_RESAMPLE<X> requires the centre of pixels to be represented
*  by integers (the LBND and UBND arrays) it is necessary to add a 
*  half-pixel shift onto both ends of the Mapping prior to executing
*  the resample.  First construct a Mapping which transforms minus a 
*  half pixel in every input dimension.
      DO I = 1, NDIMI
         PT1I( I ) = 0D0
         PT2I( I ) = 1D0
         PT1O( I ) = PT1I( I ) - 0.5D0
         PT2O( I ) = PT2I( I ) - 0.5D0
      END DO
      MAPHI = AST_WINMAP( NDIMI, PT1I, PT2I, PT1O, PT2O, ' ', STATUS )

*  Then one which transforms plus a half-pixel in every output dimension.
      DO I = 1, NDIMO
         PT1I( I ) = 0D0
         PT2I( I ) = 1D0
         PT1O( I ) = PT1I( I ) + 0.5D0
         PT2O( I ) = PT2I( I ) + 0.5D0
      END DO
      MAPHO = AST_WINMAP( NDIMO, PT1I, PT2I, PT1O, PT2O, ' ', STATUS )

*  Combine these to get a Mapping which does what we want it to,
*  correcting for the half pixel at either end.
      MAPHIO = AST_CMPMAP( MAPHI, MAPIO, .TRUE., ' ', STATUS )
      MAPHIO = AST_CMPMAP( MAPHIO, MAPHO, .TRUE., ' ', STATUS )
      MAPHIO = AST_SIMPLIFY( MAPHIO, STATUS )

*  Perform the resampling according to data type.
      IF ( ITYPE .EQ. '_BYTE' ) THEN
         NBAD = AST_RESAMPLEB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )

      ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
         NBAD = AST_RESAMPLEUB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                          %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                          AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                          VAL__BADUB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                          UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                          STATUS )

      ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
         NBAD = AST_RESAMPLEW( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADW, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )

      ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
         NBAD = AST_RESAMPLEUW( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                          %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                          AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                          VAL__BADUW, NDIMO, LBNDO, UBNDO, LBNDO,
     :                          UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                          STATUS )

      ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
         NBAD = AST_RESAMPLEI( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADI, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )

      ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
         NBAD = AST_RESAMPLER( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADR, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )

      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         NBAD = AST_RESAMPLED( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADD, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
      END IF

*  We can set the bad pixels flag according to the bad pixel count 
*  returned from AST_RESAMPLE<X>.
      BAD = NBAD .GT. 0
      CALL NDF_SBAD( BAD, NDFO, 'DATA', STATUS )
      IF ( HASVAR ) THEN
         CALL NDF_SBAD( BAD, NDFO, 'VARIANCE', STATUS )
      END IF

*  If using Nearest Neighbour interpolation, resample any QUALITY array.
*  =====================================================================
      CALL NDF_STATE( NDFI, 'QUALITY', HASQUA, STATUS )
      IF( INTERP .EQ. AST__NEAREST .AND. HASQUA ) THEN

*  Map the QUALITY array of the input and output NDFs. Note, QUALITY
*  arrays should always be mapped as _UBYTE.
         CALL NDF_MAP( NDFI, 'DATA', '_UBYTE', 'READ', IPQUAI, ELI, 
     :                 STATUS )
         CALL NDF_MAP( NDFO, 'DATA', '_UBYTE', 'WRITE', IPQUAO, ELO,
     :                 STATUS )

*  Do the resampling.
         NBAD = AST_RESAMPLEUB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                          %VAL( IPQUAI ), %VAL( IPQUAI ), INTERP,
     :                          AST_NULL, PARAMS, 0, TOL, MAXPIX,
     :                          VAL__BADUB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                          UBNDO, %VAL( IPQUAO ), %VAL( IPQUAO ),
     :                          STATUS )

      END IF

*  Tidy up.
*  ========

*  Annul (and unmap) the input and output NDFs.
      CALL NDF_ANNUL( NDFI, STATUS )
      CALL NDF_ANNUL( NDFO, STATUS )

*  Error exit label.
  999 CONTINUE

*  Exit the NDF context.
      CALL NDF_END( STATUS )

*  Exit the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'REGRID_ERR6', 'REGRID: Unable to '//
     :                 'transform the NDF.', STATUS )
      END IF

      END
