      SUBROUTINE POLREG( STATUS )
*+
*  Name:
*     polreg

*  Purpose:
*     Extract and align O and E ray areas from a set of images.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL POLREG( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This routine extacts and aligns areas containing corresponding rays 
*     from a set of images containing dual or single beam polarimetry data. 
*
*     In dual-beam mode, two output images are created for each
*     supplied input image, one containing the O-ray areas and the other
*     containing the E-ray areas from the corresponding input image. All
*     output images are aligned pixel-for-pixel. In single-beam mode, only 
*     one output image is created for each input image.
*     
*     The mappings between rays and images are determined from a set of 
*     fiducial positions supplied by the user, using an integrated 
*     graphical user interface (GUI) which activates various applications 
*     from the KAPPA, CCDPACK and POLPACK packages. The same GUI is used to 
*     specify masks enclosing the O and E ray areas of each image (each mask
*     comprises one or more polygonal areas). For each input image, the 
*     contents of the O-ray mask is copied to the corresponding "O-ray"
*     output, and the contents of the E-ray mask is copied to the corresponding
*     "E-ray" output. In single-beam mode only a single mask is used
*     (notionally the "O-ray" mask), but the user has the option of not
*     supplying any mask at all, in which case the whole input image is 
*     copied to the output.
*
*     Various options controlling the behaviour of the GUI can be set on
*     the command line by assigning values to the parameters listed below.
*     Alternatively, they can be set using the "Options" menu in the menu 
*     bar at the top of the GUI. If not supplied on the command line, these 
*     parameters usually adopt the values they had on the previous
*     invocation of PolReg. The values shown in square brackets in the
*     parameter descriptions below are the initial default values.
*
*     Detailed information on the operation of PolReg and how to use the GUI 
*     is available by clicking on the "Help" button at the right hand end of 
*     the menu bar.

*  Usage:
*     polreg in out_o out_e

*  ADAM Parameters:
*     BADCOL = LITERAL (Update)
*        The colour with which to represent missing data. This should be
*        one of RED, BLUE, GREEN, CYAN, MAGENTA, YELLOW, BLACK. Any
*        unambiguous abbreviation can be supplied, and the value is
*        case-insensitive. [CYAN]
*     CURCOL = LITERAL (Update)
*        The colour with which to mark the objects (i.e. image features
*        or masks) currently being entered by the user. This should be
*        one of RED, BLUE, GREEN, CYAN, MAGENTA, YELLOW, BLACK. Any
*        unambiguous abbreviation can be supplied, and the value is
*        case-insensitive. [RED]
*     DPI = _INTEGER (Read)
*        The dots per inch on the display screen. Some X servers fail to 
*        supply the correct value, resulting in the GUI being unplesantly
*        small or large. For this reason, an explicit value may be supplied 
*        using this parameter. If a null (!) value is supplied, then the
*        DPI value returned by the X server is used. This parameter may
*        also be used to adjust the size of the GUI to the user's
*        preference, even if the DPI value returned by the X server is correct.
*        Note, this value cannot be set from the GUI's "Options" menu. [!]
*     DUALBEAM = _LOGICAL (Read)
*        If a true value is suplied, then PolReg will operate in
*        dual-beam mode, producing two output images for each input image.
*        Otherwise, it will operate in single-beam mode, with one output
*        image being produced for each input image. In single-beam mode,
*        the output image is notionally referred to as the "O-ray" image,
*        and all the GUI controls related to the E-ray areas are disabled.
*        Note, this parameter cannot be set from the GUI's "Options"
*        menu. [TRUE]
*     FITTYPE = _INTEGER (Update)
*        The type of mapping which should be used between images. This
*        may take the following values:
*        
*        1 - Shift of origin.
*
*        2 - Shift of origin and rotation.
*
*        3 - Shift of origin and magnification.
*
*        4 - Shift of origin, rotation and magnification.
*
*        5 - A full 6 parameter mapping of the form:
*
*              X_out = C1  +  C2 * X_in  +  C3 * Y_in
*              Y_out = C4  +  C5 * X_in  +  C6 * Y_in
*
*            This form of mapping allows the rotation and magnification
*            to be different for each axis, and is unlikely to be of use 
*            with most polarimetry data. [1]
*     HELPAREA = _LOGICAL (Update)
*        If a true value is supplied, then dynamic help information will be
*        displayed in a box at the bottom of the GUI. This information
*        describes the component of the GUI currently under the mouse 
*        pointer. [TRUE]
*     IN = NDF (Read)
*        A list of input images. Note, the input images cannot be
*        specified within the GUI.
*     LOGFILE = LITERAL (Read)
*        The name of a log file to which will be written all the messages
*        generated by the applications activated by the GUI. If "stdout"
*        is supplied, then the messages will be directed to standard
*        output (usually the screen). If a null (!) value is supplied, then 
*        no log file will be created. Note, this parameter cannot be set 
*        from the GUI's "Options" menu. [!]
*     NEWCOLMAP = _LOGICAL (Read)
*        If a true value is supplied for NEWCOLMAP, then the GUI will use
*        its own private colour map. Otherwise it will share the standard 
*        colour map. Note, with a false value for NEWCOLMAP, there may 
*        be insufficient free colours in the standard colour map (i.e. if
*        other X applications are running). In this case polreg will report 
*        an error and abort. If this happens, try re-running with a true
*        value for NEWCOLMAP. [FALSE]
*     OEFITTYPE = _INTEGER (Update)
*        The type of mapping which should be used between O and E rays. See
*        parameter FITTYPE for a description of the allowed values. [1]
*     OUT = LITERAL (Write)
*        A list of the names of the output images to create in single-beam
*        mode. These should correspond one-for-one to the input images
*        supplied using parameter IN. This parameter is only accessed if
*        parameter DUALBEAM is given a false value. Note, the output images 
*        cannot be specified within the GUI.
*     OUT_E = LITERAL (Write)
*        A list of the names of the E-ray output images to create in dual-beam
*        mode. These should correspond one-for-one to the input images
*        supplied using parameter IN. This parameter is only accessed if
*        parameter DUALBEAM is given a true value. Note, the output images 
*        cannot be specified within the GUI.
*     OUT_O = LITERAL (Write)
*        A list of the names of the O-ray output images to create in dual-beam
*        mode. These should correspond one-for-one to the input images
*        supplied using parameter IN. This parameter is only accessed if
*        parameter DUALBEAM is given a true value. Note, the output images 
*        cannot be specified within the GUI.
*     PERCENTILES( 2 ) = _REAL (Update)
*        The percentiles that define the scaling limits for the displayed
*        images. For example, [25,75] would scale between the quartile 
*        values. [5,95]
*     PSFSIZE = _INTEGER (Update)
*        This value controls the centroiding process which is used to find 
*        accurate centres for the features identified using the mouse.
*        It should be set roughly to the width (in pixels) of the
*        features which are to be used to align the images. If the
*        accurate positions wander too far from the original position, then
*        a smaller value should be supplied. If it is set to zero, then
*        no centroiding is performed, and the raw feature positions are
*        used as supplied. [3]
*     REFCOL = LITERAL (Update)
*        The colour with which to mark the reference objects (i.e. image 
*        features or masks). This should be one of RED, BLUE, GREEN, CYAN, 
*        MAGENTA, YELLOW, BLACK. Any unambiguous abbreviation can be supplied, 
*        and the value is case-insensitive. [GREEN]
*     SELCOL = LITERAL (Update)
*        The colour with which to mark the selected area of the image (if any).
*        This should be one of RED, BLUE, GREEN, CYAN, MAGENTA, YELLOW, BLACK. 
*        Any unambiguous abbreviation can be supplied, and the value is 
*        case-insensitive. [RED]
*     STATUSAREA = _LOGICAL (Update)
*        If a true value is supplied, then information describing the
*        currently displayed image, current options values, etc, will be 
*        displayed in a box underneath the displayed image. The contents
*        of this box can be selected using the "Options" menu in the GUI.
*        [TRUE]
*     VIEW = LITERAL (Update)
*        This controls how images are placed within the image display
*        area of the GUI when a new image is selected using the "Images"
*        menu. It may take one of the following values:
*    
*        ZOOMED - The new image is displayed with the curremt zoom factor 
*        and image centre. 
*
*        UNZOOMED - The zoom factor and image centre are reset so that
*        the new image just fills the image display area in at least one 
*        dimension. [ZOOMED]
*
*     XHAIR = _LOGICAL (Update)
*        If a true value is supplied, then a cross hair will be used
*        instead of a pointer while the mouse is over the image display
*        area. [TRUE]
*     XHAIRCOL = LITERAL (Update)
*        The colour with which to draw the cross-hair (if required). This 
*        should be one of RED, BLUE, GREEN, CYAN, MAGENTA, YELLOW, BLACK. Any
*        unambiguous abbreviation can be supplied, and the value is
*        case-insensitive. [YELLOW]

*  Examples:
*     polreg 'im1,im2' '*_o' '*_e' 
*        This example aligns and extracts the O and E ray areas from the two 
*        images `im1` and `im2`, and stores them in the images `im1_o`,
*        `im1_e`, `im2_o` and `im2_e`. The current values for all other 
*        parameters are used.
*     polreg ^in_files.lis out=^out_files.lis dualbeam=no reset
*        This example uses single-beam mode. It reads the names of input 
*        images from the text file `in_files.lis`, aligns them and stores 
*        them in the images named in the text file `out_files.lis`. All
*        other parameters are reset to their initial default values listed 
*        in the parameter descriptions above.

*  Implementation Status:
*     - The output images are created from the input images using KAPPA 
*     application SEGMENT (to extract the mask areas), and the CCDPACK 
*     application TRANNDF (to align them). The documentation for these
*     applications should be consulted for details of which NDF components
*     are processed, what numerical data types are used for the processing, 
*     etc.

*  Notes:
*     - The following components are added to the POLPACK extension in the 
*     output images (the extension is first created if it does not
*     already exist): 
*
*     ROTATION (_REAL): The clockwise rotation from the input 
*     image to the output image (in degrees). If the input image already
*     contains a POLPACK extension, then the value of ROTATION written to the
*     output image is the sum of the input image value and the value
*     implied by the new mapping.
*
*     YROTATION (_REAL): This component is only written to the extension
*     if the output image may contain shear. It is the clockwise
*     rotation from the input image Y axis to the output image Y axis (in
*     degrees). In this case the ROTATION component (see above) is understood 
*     as giving the rotation of the X axis. If the input image already
*     contains a POLPACK extension, then the value of YROTATION written to the
*     output image is the sum of the input image value and the value
*     implied by the new mapping.
*
*     RAY (_CHAR): A label identifying which of the two rays the image
*     contains. This will be either "O" or "E". This is only written in
*     dual-beam mode (see parameter DUALBEAM).
*
*     IMGID (_CHAR): An identifier for the input image from which the
*     output image was derived. If the input image already contains a
*     POLPACK extension with a IMGID value, then the IMGID value is copied
*     unchanged to the corresponding output images. Otherwise, the name of
*     the input image (without a directoty path) is used.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-APR-1997 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}


      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_ERR'          ! PAR_ error constants

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN

*  Local Constants:
      CHARACTER COLS*40
      PARAMETER ( COLS = 'RED,BLUE,GREEN,CYAN,MAGENTA,YELLOW,BLACK' )

*  Local Variables:
      CHARACTER
     :        BADCOL*7,          ! Colour for missing pixels
     :        CURCOL*7,          ! Colour for the current objects
     :        LOGFIL*80,         ! Name of required log file
     :        REFCOL*7,          ! Colour for the reference objects
     :        SELCOL*7,          ! Colour for the selected area box
     :        SI*80,             ! String describing required status items
     :        VIEW*8,            ! The view requried for new images
     :        XHRCOL*7           ! Colour for the cross-hair
      INTEGER
     :        DPI,               ! Dots per inch to use
     :        FIT,               ! Fit type for aligning images
     :        IGRP1,             ! Identifier for input NDF group
     :        IGRP2,             ! Identifier for output O-ray NDF group
     :        IGRP3,             ! Identifier for output E-ray NDF group
     :        OEFIT,             ! Fit type for aligning the O and E rays
     :        PSF,               ! Size of feature to search for
     :        SIZE,              ! Total size of the input group
     :        SIZEO              ! Total size of the output group (=SIZE)
      LOGICAL 
     :        NEWCM,             ! Use a new colour map?
     :        DBEAM,             ! Run in Dual-beam mode?
     :        HAREA,             ! Is the help area to be displayed?
     :        SAREA,             ! Is the status area to be displayed?
     :        XHAIR              ! Is a cross-hair required?
      REAL
     :        PERCNT(2),         ! Display percentiles
     :        PERDEF(2)          ! Default display percentiles

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get a group containing the names of the NDFs to be processed.
      CALL RDNDF( 'IN', 0, 1, '  Give more image names...', IGRP1, 
     :            SIZE, STATUS )

*  See if we should run in dual-beam mode.
      CALL PAR_GET0L( 'DUALBEAM', DBEAM, STATUS )

*  Get the output images. How this is done depends on whether we are
*  in single or dual beam mode.
      IF ( DBEAM ) THEN

*  Get a group containing the names of the output NDFs to hold the
*  registered O-ray areas. Base modification elements on the group 
*  containing the input NDFs.
         CALL WRNDF( 'OUT_O', IGRP1, SIZE, SIZE, 
     :               '  Give more image names...', IGRP2, SIZEO, 
     :               STATUS )

*  Get a group containing the names of the output NDFs to hold the
*  registered E-ray areas. Base modification elements on the group 
*  containing the input NDFs.
         CALL WRNDF( 'OUT_E', IGRP1, SIZE, SIZE, 
     :               '  Give more image names...', IGRP3, SIZEO, 
     :               STATUS )

*  In single beam mode, we just get a single set of output images, using
*  parameter OUT. The second group identifier is set equal to the first
*  to indicate this.
      ELSE
         CALL WRNDF( 'OUT', IGRP1, SIZE, SIZE, 
     :               '  Give more image names...', IGRP2, SIZEO, 
     :               STATUS )
         IGRP3 = IGRP2

      END IF

*  See if a new colour map should be used.
      CALL PAR_GET0L( 'NEWCOLMAP', NEWCM, STATUS )

*  See if a cross hair should be used over the image display area.
      CALL PAR_GET0L( 'XHAIR', XHAIR, STATUS )

*  See if the help area is to be displayed.
      CALL PAR_GET0L( 'HELPAREA', HAREA, STATUS )

*  See if the images are to be displayed as an aligned or stacked.
      CALL PAR_CHOIC( 'VIEW', 'Zoomed', 'Zoomed,Unzoomed', .FALSE., 
     :                 VIEW, STATUS )

*  See if the status area is to be displayed.
      CALL PAR_GET0L( 'STATUSAREA', SAREA, STATUS )

*  Get the size of the image features to search for.
      CALL PAR_GET0I( 'PSFSIZE', PSF, STATUS )
      IF ( PSF .LT. 0 ) PSF = 0

*  Get the dots per inch to assume for the screen. A null valu means
*  use the normal TK value. Annull the error if it occurs.
      IF ( STATUS .EQ. SAI__OK ) THEN
         CALL PAR_GET0I( 'DPI', DPI, STATUS )
         IF ( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            DPI = -1
         END IF
      END IF

*  Get an encoded string describing which status items are to be included 
*  in the status area, and in what order. 
      CALL PAR_GET0C( 'ITEMS', SI, STATUS )

*  Get the name of a logfile.
      IF ( STATUS .EQ. SAI__OK ) THEN
         CALL PAR_GET0C( 'LOGFILE', LOGFIL, STATUS )
         IF( STATUS .EQ. PAR__NULL ) THEN
            LOGFIL = ' '
            CALL ERR_ANNUL( STATUS )
         ELSE
            CALL CHR_RMBLK( LOGFIL )
         END IF
      END IF

* Get the fit types to be used when aligning images, and the 
* O and E rays.
      CALL PAR_GET0I( 'FITTYPE', FIT, STATUS )
      FIT = MIN( 5, MAX( 1, FIT ) )

      CALL PAR_GET0I( 'OEFITTYPE', OEFIT, STATUS )
      OEFIT = MIN( 5, MAX( 1, OEFIT ) )

*  Get the colours to use for various parts of the display.
      CALL PAR_CHOIC( 'BADCOL', 'CYAN', COLS, .FALSE., BADCOL, STATUS )
      CALL CHR_LCASE( BADCOL )

      CALL PAR_CHOIC( 'CURCOL', 'RED', COLS, .FALSE., CURCOL, STATUS )
      CALL CHR_LCASE( CURCOL )

      CALL PAR_CHOIC( 'REFCOL', 'GREEN', COLS, .FALSE., REFCOL, STATUS )
      CALL CHR_LCASE( REFCOL )

      CALL PAR_CHOIC( 'SELCOL', 'RED', COLS, .FALSE., SELCOL, STATUS )
      CALL CHR_LCASE( SELCOL )

      CALL PAR_CHOIC( 'XHAIRCOL', 'RED', COLS, .FALSE., XHRCOL, STATUS )
      CALL CHR_LCASE( XHRCOL )

* Find the display percentiles required. 
      PERDEF( 1 ) = -1.0
      PERDEF( 2 ) = -1.0
      CALL PAR_GDR1R( 'PERCENTILES', 2, PERDEF, 0.0, 100.0,
     :                .FALSE., PERCNT, STATUS )

*  Execute the TCL script.
      CALL DOPLRG( IGRP1, IGRP2, IGRP3, DPI, HAREA, SAREA, PSF, 
     :             SI, FIT, OEFIT, LOGFIL( : CHR_LEN( LOGFIL ) ),
     :             BADCOL, CURCOL, REFCOL, SELCOL, VIEW, PERCNT(1),
     :             PERCNT(2), NEWCM, XHAIR, XHRCOL, STATUS )

*  The various options values may have been altered by the use of the 
*  "Options" menu in the GUI. Write them back to the parameter file in case.
      CALL PAR_PUT0L( 'XHAIR', XHAIR, STATUS )
      CALL PAR_PUT0L( 'HELPAREA', HAREA, STATUS )
      CALL PAR_PUT0L( 'STATUSAREA', SAREA, STATUS )
      CALL PAR_PUT0I( 'PSFSIZE', PSF, STATUS )    
      CALL PAR_PUT0C( 'ITEMS', SI( : CHR_LEN( SI ) ), STATUS )
      CALL PAR_PUT0I( 'FITTYPE', FIT, STATUS )
      CALL PAR_PUT0I( 'OEFITTYPE', OEFIT, STATUS )
      CALL CHR_UCASE( BADCOL )
      CALL PAR_PUT0C( 'BADCOL', BADCOL, STATUS )
      CALL CHR_UCASE( CURCOL )
      CALL PAR_PUT0C( 'CURCOL', CURCOL, STATUS )
      CALL CHR_UCASE( REFCOL )
      CALL PAR_PUT0C( 'REFCOL', REFCOL, STATUS )
      CALL CHR_UCASE( SELCOL )
      CALL PAR_PUT0C( 'SELCOL', SELCOL, STATUS )
      CALL CHR_UCASE( XHRCOL )
      CALL PAR_PUT0C( 'XHAIRCOL', XHRCOL, STATUS )
      CALL PAR_PUT1R( 'PERCENTILES', 2, PERCNT, STATUS )
      CALL PAR_PUT0C( 'VIEW', VIEW, STATUS )

*  Delete the groups.
      CALL GRP_DELET( IGRP1, STATUS )
      CALL GRP_DELET( IGRP2, STATUS )
      IF ( DBEAM ) CALL GRP_DELET( IGRP3, STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN

*  If a null parameter was given or a parameter abort was requested, 
*  annul the error.
         IF( STATUS .EQ. PAR__NULL .OR. STATUS .EQ. PAR__ABORT ) THEN
            CALL ERR_ANNUL( STATUS )

*  If any other error occurred, then report a contextual message.
         ELSE
            CALL ERR_REP( 'POLREG_ERR3', 'POLREG: Unable to register '//
     :                    'dual beam polarisation data.', STATUS )
         END IF

      END IF

      END
