#+
#  Name:
#     GaiaImagePanel.tcl

#  Purpose:
#     Defines a class for creating a control panel for the GAIA main window.

#  Type of Module:
#     [incr Tk] class

#  Description:
#     This is class extends the RtdImagePanel class to add the extras
#     facilities required for the GAIA interface. This consists of the
#     extras needed to add autocuts and colour/intensity table controls.

#  Invocation:
#     GaiaImagePanel name [configuration options]

#  Authors:
#     PWD: Peter Draper (STARLINK)
#     {enter_new_authors_here}

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Inherits:
#     Methods and configuration options of SkyCat (and Rtd).

#  History:
#     26-SEP-1997 (PWD):
#        Original version
#     3-FEB-1999 (PWD):
#        Added quick selections for color and itt tables.
#     25-MAR-1998 (ALLAN):
#        Changed ($f) to ([file tail $f]) in object entry, to save space
#     2-MAR-1999 (PWD):
#        Converted for Skycat 2.3.2.
#     21-NOV-2005 (PWD):
#        Converted for Skycat 2.7.4.
#     {enter_changes_here}

#-

itk::usual GaiaImagePanel {}

itcl::class gaia::GaiaImagePanel {
   inherit rtd::RtdImagePanel

   #  Constructor.
   constructor {args} {

      #  Remove fonts as we want to override these.
      itk_option remove rtd::RtdImagePanel::labelfont
      itk_option remove rtd::RtdImagePanel::valuefont
      eval itk_initialize $args

      #  OK to proceed now as all set up (including image_ variable?).
      set make_now_ 1
      make_layout
   }

   #  Override the make_layout method so the panel has percentiles
   #  cuts and colour table controls added.
   method make_layout {} {

      if { ! $make_now_ } {
         #  Hack to stop base constructor from calling this method
         #  prematurely.
         return
      }
      blt::table $w_
      add_short_help $w_ {Image information area}

      #  The RtdImage code sets this array for us to speed up the panel
      #  update by using the -textvariable option
      set var $image_
      global ::$var

      set row -1

      #  Display object name
      if {$itk_option(-showobject)} {
         itk_component add object {
            util::LabelValue $w_.object \
               -text "Object:" \
               -valuefont $itk_option(-valuefont) \
               -orient horizontal \
               -labelfont $itk_option(-labelfont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -anchor e \
               -relief groove
         }
         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ $itk_component(object)  [incr row],0 -fill x -anchor e
         } else {
            blt::table $w_ $itk_component(object)  [incr row],0 -fill x -anchor e -columnspan 3
         }
         add_short_help $itk_component(object) {Filename or Object name (filename )}
      }

      # X and Y
      if {$itk_option(-showxy)} {
         itk_component add x {
            util::LabelValue $w_.x \
               -text "X:" \
               -textvariable ${var}(X) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add y {
            util::LabelValue $w_.y \
               -text "Y:" \
               -textvariable ${var}(Y) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         itk_component add value {
            util::LabelValue $w_.value \
               -text "Value:" \
               -textvariable ${var}(VALUE) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ \
               $itk_component(x)       [incr row],0 -fill x -anchor w \
               $itk_component(y)       [incr row],0 -fill x -anchor w \
               $itk_component(value)   [incr row],0 -fill x -anchor w
         } else {
            blt::table $w_ \
               $itk_component(x)       [incr row],0 -fill x -anchor w \
               $itk_component(y)       $row,1 -fill x -anchor w \
               $itk_component(value)   $row,2 -fill x -anchor w
         }

         #  Workaround for bug in itcl2.0.
         $itk_component(x) config -textvariable ${var}(X)
         $itk_component(y) config -textvariable ${var}(Y)
         $itk_component(value) config -textvariable ${var}(VALUE)

         add_short_help $itk_component(x) {X image coordinates at mouse pointer}
         add_short_help $itk_component(y) {Y image coordinates at mouse pointer}
         add_short_help $itk_component(value) {Raw image value at X,Y coordinates}
      }

      #  Ra and dec.
      if {$itk_option(-showwcs)} {
         itk_component add ra {
            util::LabelValue $w_.ra \
               -text "a:" \
               -textvariable ${var}(RA) \
               -labelfont $itk_option(-wcsfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add dec {
            util::LabelValue $w_.dec \
               -text "d:" \
               -textvariable ${var}(DEC) \
               -labelfont $itk_option(-wcsfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add equinox {
            util::LabelValue $w_.equinox \
               -text "Equinox:" \
               -textvariable ${var}(EQUINOX) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ \
               $itk_component(ra)      [incr row],0 -fill x -anchor w \
               $itk_component(dec)     [incr row],0 -fill x -anchor w \
               $itk_component(equinox) [incr row],0 -fill x -anchor w
         } else {
            blt::table $w_ \
               $itk_component(ra)      [incr row],0 -fill x -anchor w \
               $itk_component(dec)     $row,1 -fill x -anchor w \
               $itk_component(equinox) $row,2 -fill x -anchor w
         }

         #  Workaround for bug in itcl2.0.
         $itk_component(ra) config -textvariable ${var}(RA)
         $itk_component(dec) config -textvariable ${var}(DEC)
         $itk_component(equinox) config -textvariable ${var}(EQUINOX)

         add_short_help $itk_component(ra)  {World Coordinates RA value}
         add_short_help $itk_component(dec)  {World Coordinates DEC value}
         add_short_help $itk_component(equinox) {World Coordinates equinox (default: J2000)}
      }

      #  Min and max values.
      if {$itk_option(-showminmax)} {
         itk_component add min {
            util::LabelValue $w_.min \
               -text "Min:" \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add max {
            util::LabelValue $w_.max \
               -text "Max:" \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add bitpix {
            util::LabelValue $w_.bitpix \
               -text "Bitpix:" \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ \
               $itk_component(min)     [incr row],0 -fill x -anchor w \
               $itk_component(max)     [incr row],0 -fill x -anchor w
         } else {
            blt::table $w_ \
               $itk_component(min)     [incr row],0 -fill x -anchor w \
               $itk_component(max)     $row,1 -fill x -anchor w
         }

         add_short_help $itk_component(min) {Estimated minimum raw image value}
         add_short_help $itk_component(max) {Estimated maximum raw image value}
         add_short_help $itk_component(bitpix) {Raw image FITS data type code}
      }

      #  PWD: Add a series of buttons to set the cut levels.
      if {$itk_option(-showcut) } {
         itk_component add aframe {
            frame $w_.aframe -borderwidth 2 -relief flat
         }
         set lwidth [expr $itk_option(-labelwidth)+6]
         itk_component add autocut {
            LabelCommandMenu $itk_component(aframe).autocut \
               -text "Auto Cut:" \
               -labelwidth $lwidth \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -anchor e
         }
         add_short_help $itk_component(autocut) \
            {Select a quick percentiles image cut, based on what you see not whole image}
         foreach value {100 99.5 99 98 95 90 80 70 60 50} {
            $itk_component(autocut) add \
               -label "$value%" \
               -command [code $this set_percent_level $value] \
         }

         #  Select a colour table.
         itk_component add autocolor {
            LabelCommandMenu $itk_component(aframe).autocolor \
               -text "Color Map:" \
               -labelwidth $lwidth \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -anchor e
         }
         add_short_help $itk_component(autocolor) \
            {Select a quick colour map (more in View...Colors)}
         foreach {name value} \
            {default real greyscale ramp color bgyrw heat heat pastel pastel} {
            $itk_component(autocolor) add \
               -label "$name" \
               -command [code $this set_colormap_ $value] \
         }

         #  Select an ITT table.
         itk_component add autoitt {
            LabelCommandMenu $itk_component(aframe).autoitt \
               -text "Intensity Map:" \
               -labelwidth $lwidth \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -anchor e
         }
         add_short_help $itk_component(autoitt) \
            {Select a quick intensity transfer table (more in View...Colors)}
         foreach {name value} \
            {default ramp {hist equalize} equa log log
            {negative ramp} neg wrapped lasritt} {
            $itk_component(autoitt) add \
               -label "$name" \
               -command [code $this set_ittmap_ $value] \
         }
         pack $itk_component(autocut) -expand 1 -ipadx 1m -ipady 1m
         pack $itk_component(autocolor) -expand 1 -ipadx 1m -ipady 1m
         pack $itk_component(autoitt) -expand 1 -ipadx 1m -ipady 1m

         # XXX how does this pack?
         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ \
               $itk_component(aframe) [incr row],0 -rowspan 3 -anchor w
            incr row 2
         } else {
            blt::table $w_ \
               $itk_component(aframe) $row,2 -rowspan 3 -anchor w
         }
      }

      # cut level controls
      if {$itk_option(-showcut)} {
         itk_component add low {
            util::LabelEntry $w_.low \
               -text "Low:" \
               -command [code $this set_cut_levels] \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -anchor e \
               -relief sunken \
               -validate real
         } {
            keep -state
         }
         itk_component add high {
            util::LabelEntry $w_.high \
               -text "High:" \
               -command [code $this set_cut_levels] \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -anchor e \
               -relief sunken \
               -validate real
         }  {
            keep -state
         }

         if { "$itk_option(-panel_orient)" == "vertical" } {
            blt::table $w_ \
               $itk_component(low)     [incr row],0 -fill x -anchor w \
               $itk_component(high)    [incr row],0 -fill x -anchor w \
         } else {
            blt::table $w_ \
               $itk_component(low)     [incr row],0 -fill x -anchor w \
               $itk_component(high)    $row,1 -fill x -anchor w \
         }

         add_short_help $itk_component(low) {Image low cut value, type return after editing value}
         add_short_help $itk_component(high) {Image high cut value, type return after editing value}
      }

      #  Image transformation controls.
      if {$itk_option(-showtrans)} {
         itk_component add trans {
            rtd::RtdImageTrans $w_.trans \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth [max $itk_option(-labelwidth) 5] \
               -relief flat \
               -panel_orient $itk_option(-panel_orient) \
               -min_scale $itk_option(-min_scale) \
               -max_scale $itk_option(-max_scale) \
               -image $itk_option(-image)
         } {
            keep -state
         }
         blt::table $w_ \
            $itk_component(trans)   [incr row],0 -fill x -anchor w -columnspan 2
      }

      # canvas for real-time status display
      # PWD: need to keep these components, but there placement isn't ideal
      # as tramples in intensity map component, so move down a row...
      itk_component add cameraStatus {
         canvas $w_.status -width 0 -height 0
      }
      if { "$itk_option(-panel_orient)" == "vertical" } {
         $w_.status config -width 10 -height 36
         blt::table $w_ \
            $itk_component(cameraStatus)  [incr row 2],0 -fill both -anchor nw
      } else {
         blt::table $w_ \
            $itk_component(cameraStatus)  [incr row],2 -fill both -anchor nw
      }

      if { $itk_option(-ukirt_ql) } {
         add_ukirt_panel_
      }
      blt::table configure $w_ c2 -padx 1m
   }


   #  Add UKIRT Quick Look statistics panel. This code by mt@roe.ac.uk.
   protected method add_ukirt_panel_ {} {

      #  The StarRtdImage code sets this array for us to speed up the panel
      #  update by using the -textvariable option
      set var $image_
      global ::$var

      # XY1 and XY2
      if { $itk_option(-showxy) } {
         itk_component add xy1 {
            util::LabelValue $w_.xy1 \
               -text "X1, Y1:" \
               -textvariable ${var}(X) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add xy2 {
            util::LabelValue $w_.xy2 \
               -text "X2, Y2:" \
               -textvariable ${var}(Y) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         itk_component add pixels {
            util::LabelValue $w_.pixels \
               -text "Pixels:" \
               -textvariable ${var}(PIXELS) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         blt::table $w_ \
            $itk_component(xy1)       6,0 -fill x -anchor w \
            $itk_component(xy2)       6,1 -fill x -anchor w \
            $itk_component(pixels)   6,2 -fill x -anchor w

         #  Workaround for bug in itcl2.0.
         $itk_component(xy1) config -textvariable ${var}(XY1)
         $itk_component(xy2) config -textvariable ${var}(XY2)
         $itk_component(pixels) config -textvariable ${var}(PIXELS)

         add_short_help $itk_component(xy1) {Top left position for the Statistic box}
         add_short_help $itk_component(xy2) {Bottom right position for the Statistic box}
         add_short_help $itk_component(pixels) {Number of pixels for the statistic box}

      }

      #  Smin, smax and total.
      if {$itk_option(-showxy)} {
         itk_component add smin {
            util::LabelValue $w_.smin \
               -text "S_Min:" \
               -textvariable ${var}(SMIN) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add smax {
            util::LabelValue $w_.smax \
               -text "S_Max:" \
               -textvariable ${var}(SMAX) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         itk_component add total {
            util::LabelValue $w_.total \
               -text "Total:" \
               -textvariable ${var}(TOTAL) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         blt::table $w_ \
            $itk_component(smin)       7,0 -fill x -anchor w \
            $itk_component(smax)       7,1 -fill x -anchor w \
            $itk_component(total)   7,2 -fill x -anchor w

         #  Workaround for bug in itcl2.0.
         $itk_component(smin) config -textvariable ${var}(SMIN)
         $itk_component(smax) config -textvariable ${var}(SMAX)
         $itk_component(total) config -textvariable ${var}(TOTAL)

         add_short_help $itk_component(smin) {The minmium value in  the Statistic box}
         add_short_help $itk_component(smax) {The maxmium value in  the Statistic box}
         add_short_help $itk_component(total) {The total value  of for all pixels in  the statistic box}

      }

      #  Mean and std.
      if {$itk_option(-showxy)} {
         itk_component add mean {
            util::LabelValue $w_.mean \
               -text "Mean:" \
               -textvariable ${var}(MEAN) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }
         itk_component add std {
            util::LabelValue $w_.std \
               -text "Std:" \
               -textvariable ${var}(STD) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth $itk_option(-labelwidth) \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         itk_component add sid {
            util::LabelValue $w_.sid \
               -text "RowCut:" \
               -textvariable ${var}(ROWCUT) \
               -labelfont $itk_option(-labelfont) \
               -valuefont $itk_option(-valuefont) \
               -labelwidth 6 \
               -valuewidth $itk_option(-valuewidth) \
               -relief groove \
               -anchor e
         }

         blt::table $w_ \
            $itk_component(mean)       8,0 -fill x -anchor w \
            $itk_component(std)       8,1 -fill x -anchor w \
            $itk_component(sid)   8,2 -fill x -anchor w

         #  Workaround for bug in itcl2.0.
         $itk_component(mean) config -textvariable ${var}(MEAN)
         $itk_component(std) config -textvariable ${var}(STD)
         $itk_component(sid) config -textvariable ${var}(ROWCUT)

         add_short_help $itk_component(mean) {The mean of all values for the Statistic box}
         add_short_help $itk_component(std) {The std of all values from the mean  for the Statistic box}
         add_short_help $itk_component(sid) { Number for the row-cut}

      }
   }

   #  Set the cut levels using a given percentage cut...
   method set_percent_level {percent} {
      busy {$image_ autocut -percent $percent}
      lassign [$image_ cut] low high
      $itk_component(low) config -value $low
      $itk_component(high) config -value $high
      catch {[$itk_option(-image) component cut] update_graph}
   }

   #  Set the colormap
   protected method set_colormap_ {map} {
      global gaia_library
      $image_ cmap file $gaia_library/colormaps/$map.lasc
   }

   #  Set the ITT map.
   protected method set_ittmap_ {map} {
      global gaia_library
      $image_ itt file $gaia_library/colormaps/$map.iasc
   }

   #  Update the display with the current image values (overriden for
   #  float panel changes). Note fix to stop floating point compares.
   public method updateValues {} {
      if {$itk_option(-showobject)} {
         set s [$image_ object]
         set f [file tail [$image_ fullname]]
         if { "z$s" == "z" } {
            $itk_component(object) config -value "$f"
         } else {
            $itk_component(object) config -value "$s (file:$f)"
         }
      }

      if {$itk_option(-showminmax)} {
         $itk_component(min) config -value [$image_ min]
         $itk_component(max) config -value [$image_ max]
         $itk_component(bitpix) config -value [$image_ bitpix]
      }

      if {$itk_option(-showcut)} {
         #  avoid conflict with user typing
         lassign [$image_ cut] low high
         set f [focus]
         if {"$f" != "[$itk_component(low) component entry]"} {
            $itk_component(low) config -value $low
         }
         if {"$f" != "[$itk_component(high) component entry]"} {
            $itk_component(high) config -value $high
         }
      }
      update_cut_window

      if {$itk_option(-showtrans)} {
         $itk_component(trans) update_trans
      }
   }


   #  Override the set the cut levels method to use GaiaImageCut
   #  instead of RtdImageCut
   method cut_level_dialog {} {
      if {[$image_ isclear]} {
         warning_dialog "No image is currently loaded" $w_
         return
      }
      utilReUseWidget gaia::GaiaImageCut $w_.cut \
         -image $itk_option(-image) \
         -shorthelpwin $itk_option(-shorthelpwin) \
         -transient 1 \
         -command [code $this updateValues]
   }


   #   Define the fonts as the RtdImagePanel ones are not available on
   #   all Linux systems.
   itk_option define -labelfont labelFont LabelFont -adobe-helvetica-bold-r-normal-*-12*
   itk_option define -valuefont valueFont ValueFont -adobe-helvetica-medium-r-normal-*-12*

   #  Define whether we need to show the UKIRT quick look part of the
   #  panel.
   itk_option define -ukirt_ql ukirt_ql UKIRT_QL 0

   #   Protected variable.
   protected variable make_now_ 0

}
