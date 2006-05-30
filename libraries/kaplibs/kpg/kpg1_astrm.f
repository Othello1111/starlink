      SUBROUTINE KPG1_ASTRM( IWCS, DEFAX, LBND, UBND, WORK, STATUS )
*+
*  Name:
*     KPG1_ASTRM

*  Purpose:
*     Trim axes from the current Frame of a FrameSet.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_ASTRM( IWCS, DEFAX, LBND, UBND, WORK, STATUS )

*  Description:
*     This routine ensures that the number of axes in the current Frame of 
*     the supplied FrameSet is the same as the number in the base Frame.
*     If this is not the case on entry, a new Frame with the required number 
*     of axes is created and added into the FrameSet and becomes the new 
*     current Frame. 
*
*     If the original current Frame has too few axes, the new Frame is a 
*     copy of the original current frame with extra simple axes added to 
*     the end. These extra axes are supplied a value of AST__BAD by the 
*     Mapping which connects the original current Frame to the new current 
*     Frame.
*
*     If the original current Frame has too many axes, the user is
*     allowed to select a subset of the original axes using the environment
*     parameter USEAXIS (see below). A new Frame is created by picking
*     these selected axes from the original current Frame. This Frame is
*     added into the FrameSet using a Mapping which has a forward
*     transformation which simply drops the values for the unselected axes.
*     The inverse transformation (from new to old Frame) attempts to
*     assign usable values for the dropped axes if possible. This is only
*     possible if the value for a dropped axis can be determined uniquely
*     from the value of one of the selected axes. This may be the case
*     for instance in a situation where (RA,wavelength) axes were
*     selected from the (RA,Dec,Wavelength) axes describing a 2D longslit
*     spectrum. The missing Dec value can probably be determined from the
*     RA value because the relationship between RA and Dec is determined
*     by the position and orientation of the slit on the sky. If it is
*     not possible to determine the value for a dropped axis in this way,
*     then what happens depends on whether or not any Frames can be found
*     in the FrameSet that are Regions having a Domain name of "ROI<n>", 
*     where "<n>" is a positive integer. If no such Frame can be found, 
*     AST__BAD is supplied for the dropped axis.
*
*     If the supplied current Frame has too many axes, and one or more ROI 
*     Regions are found in the FrameSet, then a new Frame is added into
*     the FrameSet for each ROI Region found. These new Frames are all
*     equivalent, containing axes from the supplied current Frame as
*     specified by the USEAXIS parameter, and they are all connected to
*     the supplied current Frame via a PermMap. Each PermMap has a
*     forward transformation that simply drops the unwanted axis values.
*     The inverse transformation of each PermMap supplies suitable values 
*     for the unwanted axes. These are determined by transforming the
*     bounding box of the corresponding ROI Region into the original current 
*     Frame. The Domain name of the corresponding ROI Region is stored in
*     the Ident attribute of the new Frame, and is also appended to the
*     end of the Frame's Domain. The new Frame corresponding to the lowest 
*     numbered ROI Region is left as the current Frame on exit.

*  Parameters:
*     The name of the following environment parameter(s) are hard-wired 
*     into this subroutine in order to ensure conformity between application. 
*
*     USEAXIS = LITERAL (Read)
*        A set of NDIM axes to be selected from the current Frame. Each 
*        axis can be specified either by giving its index within the current 
*        Frame in the range 1 to the number of axes in the Frame, or by
*        giving its symbol. This parameter is only accessed if the original 
*        current Frame in the supplied FrameSet has too many axes. The value 
*        should be given as a GRP group expression, with default control 
*        characters. 

*  Arguments:
*     IWCS = INTEGER (Given)
*        The FrameSet to use. A new current Frame may be added to the
*        FrameSet by this routine.
*     DEFAX( * ) = INTEGER (Given)
*        This array should have one element for each axis in the base
*        Frame of the supplied FrameSet. The i'th value is the index 
*        within the original current Frame of the axis which is to be
*        associated with the i'th base Frame axis by default. Only used
*        if no better defaults can be found by splitting the FrameSet 
*        Mapping.
*     LBND( * ) = INTEGER (Given)
*        The lower pixel bound on each pixel axis. Array length should be
*        at least equal to the number of base Frame axes in IWCS.
*     UBND( * ) = INTEGER (Given)
*        The upper pixel bound on each pixel axis. Array length should be
*        at least equal to the number of base Frame axes in IWCS.
*     WORK( * ) = INTEGER (Given)
*        Work space. It's length should be at least twice as large as the
*        largest pixel dimension implied by LBND and UBND.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2005 Particle Physics & Astronomy Research Council.
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
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-JUL-2005 (DSB):
*        Original version.
*     2-DEC-2005 (DSB):
*        Added DEFAX to argument list.
*     25-MAY-2006 (DSB):
*        Added support for ROI Regions.
*     30-MAY-2006 (DSB):
*        Avoid the same Domain name being used for all ROI current Frames.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'AST_PAR'          ! AST constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      INTEGER IWCS
      INTEGER DEFAX( * )
      INTEGER LBND( * )
      INTEGER UBND( * )
      DOUBLE PRECISION WORK( * )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN

*  Local Variables:
      CHARACTER DOM*20
      CHARACTER NEWDOM*40
      CHARACTER TTL*80             
      DOUBLE PRECISION CLBND
      DOUBLE PRECISION CONST( NDF__MXDIM )
      DOUBLE PRECISION CUBND
      DOUBLE PRECISION PX
      DOUBLE PRECISION RLBND( NDF__MXDIM )
      DOUBLE PRECISION RUBND( NDF__MXDIM )
      DOUBLE PRECISION XL( NDF__MXDIM )
      DOUBLE PRECISION XU( NDF__MXDIM )
      INTEGER BCMAP
      INTEGER CFRM
      INTEGER CSTAT
      INTEGER CURAXES( NDF__MXDIM )
      INTEGER CURF
      INTEGER FRM
      INTEGER I                    
      INTEGER IAT
      INTEGER IAX
      INTEGER IAXIS( NDF__MXDIM )  
      INTEGER ICUR0
      INTEGER ICUR1
      INTEGER INVAXES( NDF__MXDIM )
      INTEGER IPOUT
      INTEGER IS
      INTEGER IU
      INTEGER J
      INTEGER JU
      INTEGER K
      INTEGER KS
      INTEGER L
      INTEGER LTTL                 
      INTEGER LUTMAP( NDF__MXDIM )
      INTEGER MAP1
      INTEGER MAP2
      INTEGER MAP3
      INTEGER MAP4
      INTEGER MAP5
      INTEGER N
      INTEGER NDIM
      INTEGER NEWCUR               
      INTEGER NFC                  
      INTEGER NFRM
      INTEGER NX
      INTEGER PIXAXES( NDF__MXDIM )
      INTEGER SFRM
      LOGICAL MAPPED
      LOGICAL UNIT
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the base->current Mapping.
      BCMAP = AST_GETMAPPING( IWCS, AST__BASE, AST__CURRENT, STATUS )

*  Get the number of axes in the original current Frame.
      NFC = MIN( NDF__MXDIM, AST_GETI( BCMAP, 'NOUT', STATUS ) )

*  Get the number of base Frame (i.e. pixel) axes.
      NDIM = MIN( NDF__MXDIM, AST_GETI( BCMAP, 'NIN', STATUS ) )

*  First deal with cases where the current Frame has too many axes. 
*  ================================================================
      IF( NFC .GT. NDIM ) THEN

*  Get a pointer to the current Frame.
         CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )

*  Determine which current Frame axes are to be retained. Our first
*  choice for default axes are those which are fed by the base Frame 
*  axes. Find these axes now.
         DO I = 1, NDIM
            PIXAXES( I ) = I
         END DO
         CALL AST_MAPSPLIT( BCMAP, NDIM, PIXAXES, CURAXES, MAP1, 
     :                      STATUS )
      
*  If this could not be done, use the defaults supplied in DEFAX. 
         IF( MAP1 .NE. AST__NULL ) THEN
            IF( AST_GETI( MAP1, 'Nout', STATUS ) .NE. NDIM ) THEN
               CALL AST_ANNUL( MAP1, STATUS )
            END IF
         END IF

         IF( MAP1 .EQ. AST__NULL ) THEN
            DO I = 1, NDIM
               CURAXES( I ) = DEFAX( I )
            END DO
         END IF

*  Allow the user to select the current Frame axes to use, using the above
*  defaults.
         CALL KPG1_GTAXI( 'USEAXIS', IWCS, NDIM, CURAXES, STATUS )

*  Create a new Frame by picking the selected axes from the original
*  current Frame. 
         NEWCUR = AST_PICKAXES( IWCS, NDIM, CURAXES, MAP1, STATUS )

*  If the original Current Frame is a CmpFrame, the Frame created from
*  the above call to AST_PICKAXES may not have inherited its Title. If
*  the Frame created above has no Title, but the original Frame had, then
*  copy the original Frame's Title to the new Frame.
         IF( AST_TEST( IWCS, 'TITLE', STATUS ) .AND.
     :       .NOT. AST_TEST( NEWCUR, 'TITLE', STATUS ) ) THEN
            TTL = AST_GETC( IWCS, 'TITLE', STATUS )
            LTTL = MAX( 1, CHR_LEN( TTL ) )
            CALL AST_SETC( NEWCUR, 'TITLE', TTL( : LTTL ), STATUS )
         END IF

*  Determine a Mapping which can be used to join the existing current Frame 
*  to the Frame containing just the selected axes. We do not simply use 
*  the PermMap returned by AST_PICKAXES above will assign AST__BAD values 
*  to the missing axes when using the inverse transformation. It may be 
*  possible to do better than this by using any interpdenendencies between 
*  axes to predict the value to assign to missing axes on the basis of the 
*  value of the selected axes.

*  Produce an array with one element for each current Frame axis. If a
*  current Frame axis is selected, store its index within the selected
*  axis frame. If the current Frame axis has not been selected, store zero.
         DO I = 1, NFC
            INVAXES( I ) = 0
            LUTMAP( I ) = AST__NULL
         END DO

         DO I = 1, NDIM
            INVAXES( CURAXES( I ) ) = I
         END DO

*  Loop round all pixel axes.
         DO I = 1, NDIM
            MAPPED = .FALSE.

*  Find which current Frame axes are fed by this pixel axis, and this pixel
*  axis alone. Pass on unless this pixel axis feeds at least 2 current frame
*  axes
            CALL AST_MAPSPLIT( BCMAP, 1, I, IAXIS, MAP1, STATUS )
            IF( MAP1 .NE. AST__NULL ) THEN
               N = AST_GETI( MAP1, 'Nout', STATUS )
               IF( N .GT. 1 ) THEN                  

*  Get a Frame holding just the current Frame axes which are specified by the
*  current pixel axis alone. This Frame is used to normalise values later
*  on.
                  SFRM = AST_PICKAXES( CFRM, N, IAXIS, MAP5, STATUS )

*  Loop round the current Frame axes fed by the pixel axis, passing over
*  axes which have been selected by the user.
                  DO J = 1, N
                     IU = IAXIS( J )
                     JU = J
                     IF( INVAXES( IU ) .EQ. 0 ) THEN

*  The J'th output from MAP1 corresponds to a current Frame axis which
*  has not been selected by the user. The Mapping from selected Frame to
*  current Frame needs to introduce a value for this axis. We now see if  
*  the value for this unselected current Frame axis can be determined from 
*  the value of one of the selected axes (if any) which are fed by the same 
*  pixel axis. Loop again round the current Frame axes fed by the pixel
*  axis, this time passing over axes which have not been selected by the user.
                        DO K = 1, N

*  Also pass on if the unselected axis IU has already been assigned a value
*  on a previous pass through the K loop.
                           IF( INVAXES( IU ) .EQ. 0 ) THEN
                              IS = IAXIS( K ) 
                              KS = K
                              IF( INVAXES( IS ) .GT. 0 ) THEN

*  So now, IS and IU are the indices of two current Frame axes which are
*  both fed from the same single pixel axis (pixel axis I). Axis IS has
*  been selected by the user, but axis IU has not been selected by the
*  user. Since they are both fed from same pixel axis, it may be
*  possible to determine the value of axis IU on the basis of the value of
*  axis IS. We try to do this by creating a CmpMap containing two LutMaps 
*  which converts the IS value into the IU value (via the pixel value). Set 
*  up an array holding values for the pixel axis at 0.5 pixel intervals. 
*  Transform this array of pixel values using MAP1 to get the corresponding 
*  IU and IS values. Then create a CmpMap which uses the IS values as X and 
*  the IU values as Y. Store in an array indexed by current Frame axis IU.
                                  IF( .NOT. MAPPED ) THEN
                                     MAPPED = .TRUE.
                                     PX = DBLE( LBND( I ) ) - 0.25D0
                                     NX = 2*( UBND( I ) - LBND( I ) 
     :                                        + 1 ) 
        
                                     DO L = 1, NX
                                        WORK( L ) = PX + ( L - 1 )*
     :                                              0.5D0
                                     END DO
        
                                     CALL PSX_CALLOC( N*NX, '_DOUBLE',
     :                                                IPOUT, STATUS )
        
                                     CALL AST_TRANN( MAP1, NX, 1, NX, 
     :                                      WORK, .TRUE., N, NX, 
     :                                      %VAL( CNF_PVAL( IPOUT ) ), 
     :                                      STATUS )
                                  END IF
        
                                  CALL KPG1_MKLUT( KS, JU, NX, N, SFRM,
     :                                      %VAL( CNF_PVAL( IPOUT ) ),
     :                                      LUTMAP( IU ), STATUS )

*  Note the index of the selected axis which feeds the unselected current 
*  frame axis.
                                 IF( LUTMAP( IU ) .NE. AST__NULL ) 
     :                                  INVAXES( IU ) = INVAXES( IS )

                              END IF
                           END IF
                        END DO
                     END IF
                  END DO
               END IF
            END IF

            IF( MAPPED ) CALL PSX_FREE( IPOUT, STATUS )

         END DO

*  So now, we have two arrays, INVAXES and LUTMAP, each of which has an
*  element for each current Frame axis. For each such axis, INVAXES holds
*  the index of an associated axis within the Frame of selected axes, or 
*  zero if the current axis value cannot be determined from the selected 
*  axes. If INVAXES is non-zero, then the corresponding element of LUTMAP 
*  will hold AST__NULL if the current Frame axis is selected (in which
*  case the value for the current Frame axis is simply copied form the
*  associated selected axis). If the current Frame axis is NOT selected
*  LUTMAP will hold a Mapping with a forward transformation which can be 
*  used to transform values of the associated selected axis into values 
*  for the unselected current Frame axis. The next job is to create a
*  Mapping from this information which connects the current Frame and the
*  selected axis Frame. The forward transformation copies the selected
*  current Frame axes to the selected axis Frame and drops values for the
*  unselected axis. The inverse transformation copies the selected axis
*  Frame axis values to the corresponding axes in the current Frame and
*  introduces (if possible) corresponding values for the unselected current
*  Frame axes. A value of AST__BAD is assigned to any unselected current 
*  Frame axis for which this is not possible. 

*  Create a UnitMap which can be used to copy all the NFC current Frame
*  axis values to the following PermMap. This UnitMap will be encapsulated 
*  within a TranMap so that its inverse transformation will not be used.
         MAP1 = AST_UNITMAP( NFC, ' ', STATUS )

*  Now create a CmpMap which will provide the inverse transformation in
*  the TranMap (from the NFC inputs of the following PermMap to the NFC
*  axes of the current Frame). Each selected current Frame axis is simply
*  copied using a 1-D UnitMap. Values for the unselected axes are created
*  using the LutMaps found above, if possible. Any unselected axes which
*  cannot be created form one of the selected axes use a UnitMap to simply 
*  copy the AST__BAD value supplied by the following PermMap.
         IF( LUTMAP( 1 ) .EQ. AST__NULL ) THEN
            LUTMAP( 1 ) = AST_UNITMAP( 1, ' ', STATUS )
            UNIT = .TRUE.
         ELSE
            UNIT = .FALSE.
         END IF
         MAP2 = AST_CLONE( LUTMAP( 1 ), STATUS )

         DO I = 2, NFC
            IF( LUTMAP( I ) .EQ. AST__NULL ) THEN
               LUTMAP( I ) = AST_UNITMAP( 1, '', STATUS )
            ELSE
               UNIT = .FALSE.
            END IF
            MAP2 = AST_CMPMAP( MAP2, LUTMAP( I ), .FALSE., ' ', 
     :                         STATUS )
         END DO

*  If the splitting gave us some advantage, create the TranMap to combine 
*  these two Mappings.
         IF( .NOT. UNIT ) THEN
            CALL AST_INVERT( MAP2, STATUS )
            MAP3 = AST_TRANMAP( MAP1, MAP2, ' ', STATUS )

*  Create the following PermMap which has an input for every current
*  Frame axis and an output for each selected axis.
            MAP4 = AST_PERMMAP( NFC, INVAXES, NDIM, CURAXES, AST__BAD, 
     :                          ' ', STATUS )

*  Combine the TranMap and the PermMap in series, and simplify.
            MAP5 = AST_SIMPLIFY( AST_CMPMAP( MAP3, MAP4, .TRUE., ' ', 
     :                                       STATUS ), STATUS )

*  Add the selected axis Frame into the FrameSet using this CmpMap to
*  connect it to the original current Frame. It becomes the current Frame.
            CALL AST_ADDFRAME( IWCS, AST__CURRENT, MAP5, NEWCUR, 
     :                         STATUS )

*  If splitting the Mapping did not allow us to assign a value to any
*  unwanted axes, then we look to see if there are an Regions in the
*  FrameSet with a Domain of "ROI<k>" where <k> is a positive integer.
         ELSE

*  Note the index of the original current Frame.
            ICUR0 = AST_GETI( IWCS, 'Current', STATUS )

*  Indicate the new current Frame has not yet been set. 
            ICUR1 = AST__NOFRAME

*  Loop round all Frames in the supplied FrameSet.
            NFRM = AST_GETI( IWCS, 'Nframe', STATUS )
            DO I = 1, NFRM
               FRM = AST_GETFRAME( IWCS, I, STATUS )

*  Pass on if this Frame is not a Region, or if its Domain value does not
*  begin with the string "ROI".
               IF( AST_ISAREGION( FRM, STATUS ) ) THEN
                  DOM = AST_GETC( FRM, 'Domain', STATUS )
                  IF( DOM( : 3 ) .EQ. 'ROI' .AND. 
     :                STATUS .EQ. SAI__OK ) THEN

*  Attempt to read an integer from the rest of the Domain name. Check the
*  CHR status afterwards to see if an integer was read succesfully.
                     CSTAT = SAI__OK
                     CALL CHR_CTOI( DOM( 4 : ), K, CSTAT )
                     IF( CSTAT .EQ. SAI__OK ) THEN

*  Get the Mapping from the ROI Region to the original current Frame.
                        MAP2 = AST_GETMAPPING( IWCS, I, ICUR0, STATUS )

*  Get the bounding box of the Region
                        CALL AST_GETREGIONBOUNDS( FRM, RLBND, RUBND, 
     :                                            STATUS )

*  Loop round all axes in the original current Frame.
                        J = 1
                        DO IAX = 1, NFC

*  If this is not an unwanted axis, pass on.
                           IF( INVAXES( IAX ) .LE. 0 ) THEN

*  Find the bounds of the Region on the current output axis.
                              CALL AST_MAPBOX( MAP2, RLBND, RUBND, 
     :                                         .TRUE., IAX, CLBND,
     :                                         CUBND, XL, XU, STATUS )

*  Use the mid value as the value to be returned by the inverse
*  transformation of the PermMap.
                              CONST( J ) = 0.5*( CLBND + CUBND )
                              INVAXES( IAX ) = -J

                           END IF
                        END DO

*  Create the PermMap.
                        MAP1 = AST_PERMMAP( NFC, INVAXES, NDIM, CURAXES, 
     :                                      CONST, ' ', STATUS )

*  Take a copy of the new current Frame and set its Ident attribute to
*  identify the corresponding ROI Region. Also append the same string to
*  the end of the Domain name.
                        CURF = AST_COPY( NEWCUR, STATUS )
                        CALL AST_SETC( CURF, 'Ident', DOM, STATUS )

                        NEWDOM = AST_GETC( CURF, 'Domain', STATUS )
                        IAT = CHR_LEN( NEWDOM )
                        CALL CHR_APPND( "-", NEWDOM, IAT )
                        CALL CHR_APPND( DOM, NEWDOM, IAT )
                        CALL AST_SETC( CURF, 'Domain', NEWDOM( : IAT ), 
     :                                 STATUS )

*  Add this Frame into the FrameSet using the above PermMap to connect it to 
*  the original current Frame. It becomes the current Frame.
                        CALL AST_ADDFRAME( IWCS, ICUR0, MAP1, CURF, 
     :                                     STATUS )

*  If the index of the new current Frame has not yet been noted, note it
*  now.
                        IF( ICUR1 .EQ. AST__NOFRAME ) THEN
                           ICUR1 = AST_GETI( IWCS, 'Current', STATUS )
                        END IF

*  Annul AST resources.
                        CALL AST_ANNUL( CURF, STATUS )
                        CALL AST_ANNUL( MAP1, STATUS )
                        CALL AST_ANNUL( MAP2, STATUS )

                     END IF
                  END IF
               END IF

               CALL AST_ANNUL( FRM, STATUS )
            END DO

*  If any ROI Regions were found, set the final current Frame. */
            IF( ICUR1 .NE. AST__NOFRAME ) THEN
               CALL AST_SETI( IWCS, 'Current', ICUR1, STATUS ) 

*  Otherwise, we connect the new current Frame to the original using a
*  PermMap that supplied AST__BAD for the unwanted axes. 
            ELSE
               MAP1 = AST_PERMMAP( NFC, INVAXES, NDIM, CURAXES, 
     :                             AST__BAD, ' ', STATUS )
               CALL AST_ADDFRAME( IWCS, AST__CURRENT, MAP1, NEWCUR, 
     :                            STATUS )
            END IF
         END IF

*  Now deal with cases where the original Current Frame has too few axes.
*  ======================================================================
      ELSE IF( NFC .LT. NDIM ) THEN

*  Use zero to indicate the extra axes required.
         DO I = 1, NFC
            IAXIS( I ) = I
         END DO            

         DO I = NFC + 1, NDIM
            IAXIS( I ) = 0
         END DO            

*  Create a new Frame by adding the extra default axes to the original
*  Current Frame. This also returns a PermMap which goes from the 
*  original Frame to the new one, using AST__BAD values for the
*  new un-selected axes.
         NEWCUR = AST_PICKAXES( IWCS, NDIM, IAXIS, MAP1, STATUS )

*  Add this new Frame into the FrameSet. It becomes the Current Frame.
         CALL AST_ADDFRAME( IWCS, AST__CURRENT, MAP1, NEWCUR, 
     :                      STATUS )

      END IF

*  End the AST context.
      CALL AST_END( STATUS )
    
      END
