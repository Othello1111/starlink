      SUBROUTINE CCD1_CMPRR( BAD, VAR, EL, DAT1, VAR1, DAT2, VAR2,
     :                         GETS, GETZ, TOLS, TOLZ, MAXIT, SKYSUP,
     :                         SCALE, DSCALE, ZERO, DZERO, ORIGIN,
     :                         NPTS, NITER, DS, DZ, IP, WRK, WEIGHT,
     :                         SKYWT, STATUS )
*+
*  Name:
*     CCD1_CMPRR

*  Purpose:
*     Get relative scale factor and/or zero point for a pair of data
*     arrays.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_CMPRR( BAD, VAR, EL, DAT1, VAR1, DAT2, VAR2, GETS, GETZ,
*                      TOLS, TOLZ, MAXIT, SKYSUP, SCALE, DSCALE, ZERO,
*                      DZERO, ORIGIN, NPTS, NITER, DS, DZ, IP, WRK,
*                      WEIGHT, SKYWT, STATUS )

*  Description:
*     The routine determines the relative scale factor and/or zero
*     point difference which relates the values in two data arrays.
*     These data arrays are supposed to represent the same
*     observations, but to have been subject to multiplicative and/or
*     additive perturbations. Each is also assumed to have suffered the
*     addition of noise.  The routine seeks to estimate the parameters
*     SCALE and ZERO in the relation:
*
*        DAT2 = SCALE * ( DAT1 - ORIGIN ) + ZERO
*
*     which is fitted to the data arrays DAT1 and DAT2 using a robust
*     algorithm. The value of ORIGIN is chosen for computational
*     convenience and does not affect the nature of the fit.
*
*     The algorithm fits the straight line relationship above to the
*     data, allowing either or both of SCALE and ZERO to vary (if they
*     are fixed, they are set to 1 and 0 respectively). An analysis of
*     the errors on the fitted parameter(s) is then performed.  If a
*     SCALE value is being estimated, the fitting process may be
*     iterative. Otherwise, it is performed in a single pass.
*
*     The fitting process seeks simultaneously to minimise two
*     functions of the abolute values of a set of residuals, these
*     residuals being the weighted perpendicular distances of each
*     (DAT1,DAT2) data point from the straight line. The weights used
*     allow for noise by making use of optional variance information
*     and taking account of the resulting error ellipse associated with
*     each data point.  In addition, an algorithm is incorporated to
*     modify the weights in regions where there is a high density of
*     points, thus preventing the fit from being dominated by the "sky
*     background" in typical astronomical data. This leads to two sets
*     of weights (with and without sky noise suppression), and hence to
*     two functions of the weighted residuals (F1 and F2, respectively)
*     which may be minimised.
*
*     In the most general case (both GETS and GETZ set to .TRUE. and
*     sky noise suppression in use), the routine performs a slightly
*     unconventional fit. It minimises F1(S,Zopt) with respect to the
*     scale factor difference S to obtain an optimum value Sopt (Zopt,
*     the optimum zero point correction, being considered fixed). It
*     also simultaneously minimises F2(Sopt,Z) to obtain the optimum
*     zero point difference Zopt (in this case Sopt is considered
*     fixed). A self-consistent solution to these two minimisations is
*     sought which defines the final fit parameters Sopt and Zopt. This
*     approach has the advantage of suppressing sky noise in the
*     estimation of the scale factor, while using all the sky
*     information when estimating the zero point.
*
*     In cases where only one parameter is being estimated (or sky
*     noise suppression is not in use), only a single function of the
*     weighted absolute values of the residuals exists, and is
*     minimised in the conventional sense.

*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether it is necessary to check for the presence of bad values
*        in the input data (and variance) arrays.
*     VAR = LOGICAL (Given)
*        Whether variance information is available for the input data.
*     EL = INTEGER (Given)
*        Number of input data points.
*     DAT1( EL ) = REAL (Given)
*        First input data array.
*     VAR1( EL ) = REAL (Given)
*        Array of variance estimates for the data in the DAT1 array.
*        This argument is not accessed unless VAR is .TRUE..
*     DAT2( EL ) = REAL (Given)
*        Second input data array.
*     VAR2( EL ) = REAL (Given)
*        Array of variance estimates for the data in the DAT2 array.
*        This argument is not accessed unless VAR is .TRUE..
*     GETS = LOGICAL (Given)
*        Whether an estimate of the relative scale factor between the
*        two input data arrays is to be calculated. If .FALSE. is
*        specified, then the relative scale factor will be fixed at
*        unity.
*     GETZ = LOGICAL (Given)
*        Whether an estimate of the zero point shift between the two
*        input data arrays is to be calculated. If .FALSE. is
*        specified, then the zero point shift will be fixed at zero.
*     TOLS = REAL (Given)
*        Fractional accuracy tolerance required for estimates of the
*        relative scale factor. This argument is only used if an
*        iterative solution is necessary (which will be the case if
*        (GETS.AND.(GETZ.OR.VAR)) is .TRUE.). In this case, convergence
*        is not judged to have occurred unless the absolute value of
*        the fractional change in the scale factor estimate in the
*        final iteration was less than or equal to ABS(TOLS).
*     TOLZ = REAL (Given)
*        Accuracy tolerance required for estimates of the zero point
*        shift. This argument is only used if an iterative solution is
*        necessary (which will be the case if (GETS.AND.(GETZ.OR.VAR))
*        is .TRUE.). In this case, convergence is not judged to have
*        occurred unless the absolute value of the change in the zero
*        point estimate in the final iteration was less than or equal
*        to ABS(TOLZ*SCALE).
*     MAXIT = INTEGER (Given)
*        Maximum number of iterations to perform. This argument is only
*        used if an iterative solution is necessary (which will be the
*        case if (GETS.AND.(GETZ.OR.VAR)) is .TRUE.). The routine will
*        return once MAXIT iterations have been performed unless
*        convergence is achieved earlier. An error will be reported if
*        convergence has not been achieved after MAXIT iterations
*        A MAXIT value of at least 1 is always used.
*     SKYSUP = REAL (Given)
*        Sky noise suppression factor. When a relative scale factor is
*        being calculated, it can often be biased by the large number
*        of data values present in the "sky background" of typical
*        astronomical data. SKYSUP controls an algorithm which reduces
*        the weight given to data where there is a high density of
*        points with the same value in order to suppress this effect.
*        This value is only used if a scale factor is being estimated
*        (i.e. if GETS is .TRUE.).
*
*        To be more specific, the routine forms a histogram of the
*        values in each data array. Where the local density of points
*        in a histogram exceeds AVDEN/ABS(SKYSUP) (AVDEN being the
*        average density of points in the histogram as a whole) the
*        weight given to the data is modified by a reduction factor so
*        that the effective number of points is reduced to this
*        threshold value.  If two reduction factors need to be applied
*        to any data point (one from each histogram), then the actual
*        factor used is the geometric mean of the two.
*
*        A SKYSUP value of one is often effective, but a value set by
*        the approximate ratio of sky pixels to useful object pixels
*        may often be better.  A negative or zero value disables the
*        sky noise suppression algorithm completely.
*     SCALE = DOUBLE PRECISION (Returned)
*        Estimate of the relative scale factor in the linear expression
*        being fitted.  If GETS is .FALSE., a value of unity will be
*        returned.
*     DSCALE = DOUBLE PRECISION (Returned)
*        Estimate of the standard error on the SCALE value returned. If
*        GETS is .FALSE., a value of zero will be returned.
*     ZERO = DOUBLE PRECISION (Returned)
*        Estimate of the zero point shift appearing in the expression
*        being fitted. If GETZ is .FALSE, a value of zero will be
*        returned.
*     DZERO = DOUBLE PRECISION (Returned)
*        Estimate of the standard error on the ZERO value returned. If
*        GETZ is .FALSE., a value of zero will be returned.
*     ORIGIN = DOUBLE PRECISION (Returned)
*        Value of the false origin used in the expression being fitted.
*        The value returned makes no difference to the resulting
*        function (any change in ORIGIN being compensated by adjusting
*        the value of ZERO), but it forms an essential part of
*        modelling the errors on the results. To this end, the value of
*        ORIGIN is chosen so that the errors on the SCALE and ZERO
*        values are expected to be un-correlated. An ORIGIN value of
*        zero is always returned if either GETS or GETZ is .FALSE..
*     NPTS = INTEGER (Returned)
*        Number of "good" (i.e. non-bad) input data points which
*        contributed to the result. Note that a data value has to be
*        good in both input data arrays (and in the associated variance
*        arrays, if supplied) before it will be used.
*     NITER = INTEGER (Returned)
*        Number of iterations performed. The value returned will be
*        zero if an iterative solution was not necessary (this will be
*        the case if (GETS.AND.(GETZ.OR.VAR)) is .FALSE.). Otherwise,
*        the returned value will be at least 1, and may be as large as
*        MAXIT.
*     DS = DOUBLE PRECISION (Returned)
*        The (signed) change in the estimate of SCALE which took place
*        in the final iteration of an iterative solution.  A value of
*        zero will be returned if the solution was not iterative (which
*        will be the case if (GETS.AND.(GETZ.OR.VAR)) is .FALSE.).
*     DZ = DOUBLE PRECISION (Returned)
*        The (signed) change in the estimate of ZERO which took place
*        in the final iteration of an iterative solution.  A value of
*        zero will be returned if the solution was not iterative (which
*        will be the case if (GETS.AND.(GETZ.OR.VAR)) is .FALSE.).
*     IP( EL, j ) = INTEGER (Returned)
*        Workspace. If (GETS.AND.GETZ) is .TRUE., then j should equal
*        3, otherwise, if (GETS.OR.GETZ) is .TRUE., then j should equal
*        1, otherwise, the IP array is not referenced.
*     WRK( EL ) = REAL (Returned)
*        Workspace. This is only referenced if (GETS.OR.GETZ) is
*        .TRUE..
*     WEIGHT( EL, k ) = REAL (Returned)
*        Workspace. If (VAR.AND.GETS.AND.(SKYSUP.GT.0.0)) is .TRUE.,
*        then k should equal 2, otherwise, if
*        (VAR.OR.(GETS.AND.(SKYSUP.GT.0.0))) is .TRUE., then k should
*        equal 1, otherwise, the WEIGHT array is not referenced.
*     SKYWT( EL ) = REAL (Returned)
*        Workspace. This is only referenced if
*        (VAR.AND.GETS.AND.(SKYSUP.GT.0.0)) is .TRUE..
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     The algoritm is based around an iterative scheme for updating
*     each of the fitted parameters in turn, based on the current
*     values of the residuals. At each iteration, and for each
*     parameter, a set of corrections is calculated which would cause
*     each residual to be reduced to zero. A weighted median of these
*     corrections is then found and applied to the parameter in
*     question, the weights being chosen according to which parameter
*     is being updated (i.e. sky noise suppression, if used, is
*     included when updating the scale factor estimate, but not when
*     updating the zero point). Iterations continue until the
*     corrections become sufficiently small or the maximum number of
*     iterations is reached. In the case where only the ZERO parameter
*     is being estimated, or where only a scale factor is being
*     estimated and no variance information has been supplied, the
*     first correction is exact, so no further iterations need be
*     performed.
*
*     The finding of median corrections requires values to be partially
*     sorted (into a different order for each parameter being
*     corrected). The algorithm therefore maintains a set of pointers
*     which allow the data to be accessed in various sorted orders.
*     This allows each iteration to access the values in the order into
*     which they were sorted during the previous iteration, and thus to
*     reduce the time taken on iterations after the first.

*  Copyright:
*     Copyright (C) 1992 Science & Engineering Research Council

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     29-APR-1992 (RFWS):
*        Original version.
*     21-MAY-1992 (RFWS):
*        Substantial improvements to increase execution efficiency.
*     31-JUL-1992 (RFWS):
*        Removed the sky noise suppression from calculations of the
*        zero point and origin values (but retained it for scale factor
*        calculations) in cases where both values are being estimated.
*     15-JAN-1992 (PDRAPER):
*        Applied bug fix. Stopped going to 1 when bad values are
*        present - changed to go to 2.
*     18-SEP-1996 (PDRAPER):
*        Changed error function call to use PDA_DERF instead
*        of NAG routine S15AEF.
*     12-JAN-1998 (DSB):
*        Add checks that STATUS is SAI__OK before reporting new errors.
*        Add cast to REAL when passing DOUBLE PRECISION variables to
*        MSG_SETR.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Primitive data constants

*  Arguments Given:
      LOGICAL BAD
      LOGICAL VAR
      INTEGER EL
      REAL DAT1( EL )
      REAL VAR1( EL )
      REAL DAT2( EL )
      REAL VAR2( EL )
      LOGICAL GETS
      LOGICAL GETZ
      REAL TOLS
      REAL TOLZ
      INTEGER MAXIT
      REAL SKYSUP

*  Arguments Returned:
      DOUBLE PRECISION SCALE
      DOUBLE PRECISION DSCALE
      DOUBLE PRECISION ZERO
      DOUBLE PRECISION DZERO
      DOUBLE PRECISION ORIGIN
      INTEGER NPTS
      INTEGER NITER
      DOUBLE PRECISION DS
      DOUBLE PRECISION DZ
      INTEGER IP( EL, * )
      REAL WRK( EL )
      REAL WEIGHT( EL, * )
      REAL SKYWT( EL )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      REAL HALF                ! One half, in the required precision
      PARAMETER ( HALF = 1.0 / 2.0 )

*  External References:
      DOUBLE PRECISION PDA_DERF  ! Error function erf( x )
      EXTERNAL PDA_DERF

*  Local Variables:
      REAL ALPHA               ! Constant for projected distance
      REAL COSTH               ! COS( THETA)
      REAL COSTH2              ! COS( THETA ) ** 2
      REAL DEGF                ! Number of degrees of freedom
      REAL DELTA1              ! Distance of DAT1 value from origin
      REAL DELTA2              ! Distance of DAT2 above fitted line
      REAL DIST                ! Distance projected along fitted line
      REAL DTHETA              ! Angular error on fitted line
      REAL ERF                 ! Error function value
      REAL FACTOR              ! Error normalisation factor
      REAL ORI                 ! Iterative origin estimate
      REAL PI                  ! The constant
      REAL Q                   ! Quantile value
      REAL Q1                  ! Lower quantile value
      REAL Q2                  ! Upper quantile value
      REAL SCL                 ! Iterative scale factor estimate
      REAL SECTH               ! SEC( THETA )
      REAL SINTH               ! SIN( THETA )
      REAL SINTH2              ! SIN( THETA ) ** 2
      REAL SS                  ! Scale factor increment
      REAL THETA               ! Angle of slope of fitted line
      REAL TINY                ! Value too small to handle safely
      REAL ZER                 ! Iterative zero point estimate
      REAL ZZ                  ! Zero point increment
      INTEGER I                  ! Loop counter
      INTEGER IDIST              ! Workspace index for origin data
      INTEGER IFAIL              ! NAG error flag
      INTEGER II                 ! Index into input data arrays
      INTEGER IIP                ! Loop counter for IP array index
      INTEGER ISCALE             ! Workspace index for scale factor data
      INTEGER ITER               ! Iteration counter
      INTEGER IWS                ! Index to sky-noise-suppressed weights
      INTEGER IZERO              ! Workspace index for zero point data
      INTEGER NIP                ! Number of pointer arrays to maintain
      INTEGER NPAR               ! Number of parameters to estimate
      LOGICAL DOITER             ! Perform iterations?
      LOGICAL SUPSKY             ! Sky suppression factor specified?

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise:
*  ==========
*  Set defaults for the returned argument values.
      SCALE = 1.0D0
      DSCALE = 0.0D0
      ZERO = 0.0D0
      DZERO = 0.0D0
      ORIGIN = 0.0D0
      NPTS = 0
      NITER = 0
      DS = 0.0D0
      DZ = 0.0D0

*  Test if a scale factor or zero point is to be determined. If neither
*  is, then there is nothing more to do.
      IF ( GETS .OR. GETZ ) THEN

*  Determine the number of parameters being estimated.
         NPAR = 1
         IF ( GETS .AND. GETZ ) NPAR = 2

*  Set up indices for accessing sections of the IP workspace array.
*  Some or all of these may be required, depending on which information
*  must be maintained while estimating the fitting parameters.
         NIP = 0

*  An array of pointers to projected distance values must be held if
*  both a scale factor and zero point are being estimated.
         IF ( GETS .AND. GETZ ) THEN
            NIP = NIP + 1
            IDIST = NIP
         END IF

*  An array of pointers to scale factor residuals must be held if a
*  scale factor is being estimated.
         IF ( GETS ) THEN
            NIP = NIP + 1
            ISCALE = NIP
         END IF

*  An array of pointers to zero point residuals must be held if a zero
*  point is being estimated.
         IF ( GETZ ) THEN
            NIP = NIP + 1
            IZERO = NIP
         END IF

*  See whether sky noise suppression is required.
         SUPSKY = ( GETS .AND. ( SKYSUP .GT. 0.0 ) )

*  Set up an index to identify the section of the WEIGHT array which is
*  to hold weights to which sky suppression factors (if used) have been
*  applied.
         IF ( VAR .AND. SUPSKY ) THEN
            IWS = 2
         ELSE
            IWS = 1
         END IF

*  Determine if an iterative solution is required. This is only the
*  case if both a scale factor and zero point are being estimated, or
*  if a scale factor is being estimated in the presence of variance
*  information.
         DOITER = ( GETS .AND. ( GETZ .OR. VAR ) )

*  Select data:
*  ===========
*  Find the smallest variance value which is safe to handle.
         TINY = EL / NUM__MAXR

*  Loop to identify input data points to use.
         NPTS = 0
         DO 2 I = 1, EL

*  If bad pixels may be present, then reject them.
            IF ( BAD ) THEN
               IF ( ( DAT1( I ) .EQ. VAL__BADR ) .OR.
     :              ( DAT2( I ) .EQ. VAL__BADR ) ) GO TO 2
            END IF

*  If variance information is available and may contain bad pixels,
*  then reject them.
            IF ( VAR ) THEN
               IF ( BAD ) THEN
                  IF ( ( VAR1( I ) .EQ. VAL__BADR ) .OR.
     :                 ( VAR2( I ) .EQ. VAL__BADR ) ) GO TO 2
               END IF

*  Also reject any points whose variance values are not positive, or
*  are too small to handle safely.
               IF ( ( VAR1( I ) .LE. TINY ) .OR.
     :              ( VAR2( I ) .LE. TINY ) ) GO TO 2
            END IF

*  Count the number of data points used.
            NPTS = NPTS + 1

*  Initialise each array of pointers being held to point at the data
*  values being used.
            DO 1 IIP = 1, NIP
               IP( NPTS, IIP ) = I
 1          CONTINUE
 2       CONTINUE

*  If there are insufficient usable data values to obtain a fit, then
*  report an error.
         IF ( NPTS .LT. NPAR .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR

            IF ( GETS .AND. GETZ ) THEN
               CALL MSG_SETC( 'PAR', 'scale factor and zero point' )
            ELSE IF ( GETS ) THEN
               CALL MSG_SETC( 'PAR', 'scale factor' )
            ELSE IF ( GETZ ) THEN
               CALL MSG_SETC( 'PAR', 'zero point' )
            END IF

            IF ( NPTS .EQ. 0 ) THEN
               CALL ERR_REP( 'CCD1_CMPRR_0',
     :                       'No good data values available; cannot ' //
     :                       'estimate relative ^PAR.', STATUS )
            ELSE
               CALL ERR_REP( 'CCD1_CMPRR_1',
     :                       'Only one good data value available; ' //
     :                       'insufficient to estimate relative ' //
     :                       '^PAR.', STATUS )
            END IF

*  Abort the routine.
            GO TO 99
         END IF

*  Generate weight reduction factors for suppression of sky noise if
*  required. If variance information is present, put these factors into
*  the SKYWT array for subsequent merging with the variance
*  information. Otherwise, put them into the WEIGHT array for use
*  directly.
         IF ( SUPSKY ) THEN
            IF ( VAR ) THEN
               CALL CCD1_SKYSR( SKYSUP, NPTS, DAT1, DAT2, IP( 1, 1 ),
     :                            SKYWT, STATUS )
            ELSE
               CALL CCD1_SKYSR( SKYSUP, NPTS, DAT1, DAT2, IP( 1, 1 ),
     :                            WEIGHT, STATUS )
            END IF
         END IF

*  Iterate:
*  =======
*  Initialise values prior to iterating.
         SCL = 1.0
         ZER = 0.0
         ORI = 0.0
         SS = 0.0
         ZZ = 0.0
         ITER = 0

*  If both a scale factor and a zero point are being estimated, then
*  start the scale factor at zero (otherwise the origin value obtained
*  on the first iteration may be poor and the scale factor may not get
*  adjusted until the second iteration).
         IF ( GETS .AND. GETZ ) SCL = 0.0D0

*  Loop to iteratively estimate new values for the zero point and/or
*  scale factor. Test for convergence and that the maximum number of
*  iterations has not been reached. Ensure that at least one iteration
*  is always performed and count the number actually performed.
 3       CONTINUE                ! Start of "DO WHILE" loop
         IF ( ( ( ( ABS( SS ) .GT. ABS( TOLS * SCL ) ) .OR.
     :            ( ABS( ZZ ) .GT. ABS( TOLZ * SCL ) ) ) .AND.
     :          ( ITER .LT. MAXIT ) ) .OR.
     :        ( ITER .EQ. 0 ) ) THEN
            ITER = ITER + 1

*  Find the angle of slope of the currently fitted line and derive
*  the necessary trig functions.
            THETA = ATAN( SCL )
            COSTH = COS( THETA )
            COSTH2 = COSTH ** 2
            SINTH = SIN( THETA )
            SINTH2 = SINTH ** 2
            SECTH = 1.0 / COSTH
            ALPHA = SECTH - SCL * SINTH

*  Set up origin information and/or weighting factors:
*  ==================================================
*  If both a scale factor and a zero point are being estimated, or if
*  variance information is available, then then loop through the input
*  data points, using the first array of pointers to locate them.
            IF ( ( GETS .AND. GETZ ) .OR. VAR ) THEN
               DO 4 I = 1, NPTS
                  II = IP( I, 1 )

*  If both a scale factor and a zero point are being estimated, then a
*  false origin must be found. To allow this, fill the WRK array with
*  the distances between the point of projection of each data point on
*  to the currently fitted line and the point where this line crosses
*  the current origin. (Note that for efficiency we only calculate this
*  value to within a constant - the constant is added after finding the
*  median.)
                  IF ( GETS .AND. GETZ )
     :               WRK( II ) = DAT1( II ) * ALPHA + DAT2( II ) * SINTH

*  If variance information is available, then set up an associated
*  weighting factor for each point. This is the reciprocal of the
*  squared radius of the error ellipse along the direction normal to
*  the fitted line.
                  IF ( VAR ) THEN
                     WEIGHT( II, 1 ) = ( SINTH2 / VAR1( II ) +
     :                                   COSTH2 / VAR2( II ) )

*  If required, multiply this weight by the sky noise suppression
*  factor.
                     IF ( SUPSKY )
     :                  WEIGHT( II, 2 ) = WEIGHT( II, 1 ) * SKYWT( II )
                  END IF
 4             CONTINUE
            END IF

*  Find an origin:
*  ==============
*  If we are estimating both a scale factor and a zero point, then we
*  must find a suitable origin to ensure independence between these
*  values (in other cases the origin is simply left at zero).
            IF ( GETS .AND. GETZ ) THEN

*  Find the (weighted) median distance of all the input data points
*  when projected perpendicularly on to the currently fitted line.
*  Correct the result (for the constant omitted above) so that it
*  refers to the distance from the point where the line crosses the
*  current origin. Then project back on to the DAT1 axis.
               CALL CCD1_QNTLR( VAR, .FALSE., HALF, NPTS, WRK,
     :                            WEIGHT, IP( 1, IDIST ), Q, STATUS )
               Q = Q - ZER * SINTH - ORI * ALPHA
               Q = Q * COSTH

*  Apply this as a correction to the previous origin value and correct
*  the zero point for this change of origin, so that the fitted line is
*  not altered (the origin is a computational convenience, not part of
*  the fit).
               ORI = ORI + Q
               ZER = ZER + SCL * Q
            END IF

*  Estimate a new zero point:
*  =========================
*  If estimating a zero point, calculate the vertical distance between
*  each data point and the currently fitted line. (Note that for
*  efficiency we only calculate this to within a constant - the
*  constant is added after finding the median.)
            IF ( GETZ ) THEN
               DO 5 I = 1, NPTS
                  II = IP( I, IZERO )
                  WRK( II ) = DAT2( II ) - DAT1( II ) * SCL
 5             CONTINUE

*  Find the (weighted) median distance and correct the result for the
*  constant omitted above.
               CALL CCD1_QNTLR( VAR, .FALSE., HALF, NPTS, WRK,
     :                            WEIGHT, IP( 1, IZERO ), Q, STATUS )
               Q = Q + ORI * SCL - ZER

*  Apply the result as a correction to the current zero point.
*  Remember the increment as a test for convergence.
               ZER = ZER + Q
               ZZ = Q
            END IF

*  Estimate a new scale factor:
*  ===========================
*  If estimating a scale factor, set up an array representing the
*  angles through which the fitted line must be rotated (about the
*  current origin) to fit each data point. (Note that for efficiency we
*  need not calculate each angle but merely its tangent - this is
*  corrected for after taking the median.)
            IF ( GETS ) THEN
               DO 6 I = 1, NPTS
                  II = IP( I, ISCALE )

*  Generate the vertical distance of each point from the fitted line
*  (we actually need the perpendicular distance, but they are
*  proportional). Also form the distance between the perpendicular
*  projection of each point on to the line and the point where this
*  line crosses the current origin.
                  DELTA1 = DAT1( II ) - ORI
                  DELTA2 = DAT2( II ) - ( DELTA1 * SCL + ZER )
                  DIST = DELTA1 * SECTH + DELTA2 * SINTH

*  Form the ratio of these two quantities, protecting against possible
*  overflow or division by zero.  Assign an appropriately-signed
*  extreme value if overflow or division by zero would occur.
                  TINY = ABS( DELTA2 ) / NUM__MAXR
                  IF ( ABS( DIST ) .GT. TINY ) THEN
                     WRK( II ) = DELTA2 / DIST
                  ELSE
                     WRK( II ) = SIGN( NUM__MAXR, DELTA2 * DIST )
                  END IF
 6             CONTINUE

*  Find the (weighted) median ratio, using weights modified to suppress
*  sky noise, if required. Correct for the use of vertical distances
*  (instead of perpendicular distances) and convert to a rotation
*  angle.
               CALL CCD1_QNTLR( ( VAR .OR. SUPSKY ), .FALSE., HALF,
     :                            NPTS, WRK, WEIGHT( 1, IWS ),
     :                            IP( 1, ISCALE ), Q, STATUS )
               Q = ATAN( Q * COSTH )

*  Apply this as a correction to the angle of slope of the fitted line.
*  Remember the increment as a test for convergence.
               SS = SCL
               SCL = TAN( THETA + Q )
               SS = SCL - SS
            END IF

*  Return for another iteration if necessary.
            IF ( DOITER ) GO TO 3
         END IF

*  Return the results of the iterations.
         SCALE = SCL
         ZERO = ZER
         ORIGIN = ORI

*  Estimate errors:
*  ===============
*  If there are insufficient data points to estimate errors, then set
*  the error estimates to large values.
         IF ( NPTS .LE. NPAR ) THEN
            IF ( GETS ) DSCALE = NUM__MAXD
            IF ( GETZ ) DZERO = NUM__MAXD

*  Otherwise, obtain the error function (erf(x)) value needed for
*  finding the +/- 1-sigma quantiles in a normal distribution.
         ELSE
            IFAIL = 0
            ERF = PDA_DERF( SQRT( 0.5D0 ), IFAIL )

*  Set up a factor to convert quantile values into final error
*  estimates (note the factor pi/2 arises because we use a median,
*  which is a less efficient estimator than the mean).
            PI = ACOS( -1.0 )
            DEGF = NPTS - NPAR
            FACTOR = ( PI / 2.0 ) / SQRT( DEGF )

*  If a scale factor has been estimated, obtain the values of the +/-
*  1-sigma quantiles for the most recent distribution of scale factor
*  corrections. Use weights modified to suppress sky noise, if
*  required.
            IF ( GETS ) THEN
               CALL CCD1_QNTLR( ( VAR .OR. SUPSKY ), .TRUE.,
     :                            HALF * ( 1.0 - ERF ), NPTS, WRK,
     :                            WEIGHT( 1, IWS ), IP( 1, ISCALE ),
     :                            Q1, STATUS )
               CALL CCD1_QNTLR( ( VAR .OR. SUPSKY ), .TRUE.,
     :                            HALF * ( 1.0 + ERF ), NPTS, WRK,
     :                            WEIGHT( 1, IWS ), IP( 1, ISCALE ),
     :                            Q2, STATUS )

*  Convert the quantile values into rotation angles and derive the
*  angular error on the fitted line.
               THETA = ATAN( SCALE )
               COSTH = COS( THETA )
               Q1 = ATAN( Q1 * COSTH )
               Q2 = ATAN( Q2 * COSTH )
               DTHETA = FACTOR * HALF * ( Q2 - Q1 )

*  Calculate the scale factor error which results from this angular
*  error.
               DSCALE = HALF * ABS( TAN( THETA + DTHETA ) -
     :                              TAN( THETA - DTHETA ) )
            END IF

*  If a zero point has been estimated along with a scale factor, then
*  the distribution of zero point corrections must first be
*  re-calculated. (Note that for efficiency we only calculate these
*  values to within a constant, since only differences are required.)
            IF ( GETZ ) THEN
               IF ( GETS ) THEN
                  DO 7 I = 1, NPTS
                     II = IP( I, IZERO )
                     WRK( II ) = DAT2( II ) - DAT1( II ) * SCL
 7               CONTINUE
               END IF

*  Obtain values of the +/- 1-sigma quantiles for the final
*  distribution of zero point corrections and derive an error estimate
*  on the result.
               CALL CCD1_QNTLR( VAR, .TRUE.,
     :                            HALF * ( 1.0 - ERF ), NPTS, WRK,
     :                            WEIGHT, IP( 1, IZERO ), Q1, STATUS )
               CALL CCD1_QNTLR( VAR, .TRUE.,
     :                            HALF * ( 1.0 + ERF ), NPTS, WRK,
     :                            WEIGHT, IP( 1, IZERO ), Q2, STATUS )
               DZERO = FACTOR * HALF * ( Q2 - Q1 )
            END IF
         END IF

*  If iterations have been performed, return the number performed and
*  the final parameter corrections.
         IF ( DOITER ) THEN
            NITER = ITER
            IF ( GETS ) DS = SS
            IF ( GETZ ) DZ = ZZ

*  If the scale factor estimate did not converge, then make an error
*  report.
            IF ( STATUS .EQ. SAI__OK .AND. GETS .AND.
     :           ( ABS( SS ) .GT. ABS( TOLS * SCALE ) ) ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETR( 'TOLS', REAL( ABS( TOLS * SCALE ) ) )
               CALL MSG_SETI( 'MAXIT', MAX( MAXIT, 1 ) )
               CALL MSG_SETR( 'DS', SS )
               CALL ERR_REP( 'CCD1_CMPRR_DS',
     :                       'Estimation of relative scale factor ' //
     :                       'failed to converge to required ' //
     :                       'accuracy (^TOLS) after ^MAXIT ' //
     :                       'iteration(s) - change during final ' //
     :                       'iteration was ^DS', STATUS )
            END IF

*  If the zero point estimate did not converge, make a similar report.
            IF ( STATUS .EQ. SAI__OK .AND. GETZ .AND.
     :           ( ABS( ZZ ) .GT. ABS( TOLZ * SCALE ) ) ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETR( 'TOLZ', REAL( ABS( TOLZ * SCALE ) ) )
               CALL MSG_SETI( 'MAXIT', MAX( MAXIT, 1 ) )
               CALL MSG_SETR( 'DZ', ZZ )
               CALL ERR_REP( 'CCD1_CMPRR_DZ',
     :                       'Estimation of relative zero point ' //
     :                       'failed to converge to required ' //
     :                       'accuracy (^TOLZ) after ^MAXIT ' //
     :                       'iteration(s) - change during final ' //
     :                       'iteration was ^DZ', STATUS )
            END IF
         END IF
      END IF

*  Arrive here if an error occurs.
 99   CONTINUE

      END
* @(#)ccg1_cmpr.grd	1.2     9/19/96     1
