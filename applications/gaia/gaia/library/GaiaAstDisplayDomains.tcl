#+
#  Name:
#     GaiaAstDisplayDomains

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Creates a toolbox for displaying the current coordinates in all
#     known domains.

#  Description:
#     This class creates a window that contains displays that show the
#     current coordinate in all the known domains.

#  Invocations:
#
#        GaiaAstDisplayDomains object_name [configuration options]
#
#     This creates an instance of a GaiaAstDisplayDomains object. The return is
#     the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this object.

#  Configuration options:
#    See itk_option define lines below.

#  Methods:
#     See method definitions below.

#  Inheritance:
#     TopLevelWidget.

#  Authors:
#     PWD: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     12-DEC-2001 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaAstDisplayDomains {}

itcl::class gaia::GaiaAstDisplayDomains {

   #  Inheritances:
   #  -------------

   inherit util::TopLevelWidget

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Evaluate any options
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ "GAIA: show coordinates for all systems ($itk_option(-number))"

      #  Create the short help window.
      make_short_help
      $itk_component(short_help) configure -width 40

      #  Add File menu for usual stuff.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0

      #  Add option to create a new window.
      $File add command -label {New window} \
         -command [code $this clone_me_] \
         -accelerator {Control-n}
      bind $w_ <Control-n> [code $this clone_me_]
      $short_help_win_ add_menu_short_help $File \
         {New window} {Create a new toolbox}

      #  Options to close window.
      $File add command -label {Close window   } \
         -command [code $this close] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this close]

      #  Add window help.
      add_help_button alldomains "On Window..."

      #  Only one element is available. A dropdown box showing the AST
      #  domains for the current image.
      itk_component add rule {
         LabelRule $w_.rule -text {Built-in coordinate readouts:}
      }

      #  We need read outs for all domains known to the displayed
      #  image.
      itk_component add readoutarea {
         frame $w_.readoutarea
      }
      update_displays_

      #  Add button to close window.
      itk_component add actionframe {frame $w_.action}

      #  Add a button to close window.
      itk_component add close {
         button $itk_component(actionframe).close -text Close \
	       -command [code $this close]
      }
      add_short_help $itk_component(close) {Close window}

      #  Pack window.
      pack $itk_component(rule) -side top -fill x -ipadx 1m -ipady 1m
      pack $itk_component(readoutarea) -side top -fill both -pady 3 -padx 3
      pack $itk_component(actionframe) -side bottom -fill x -pady 3 -padx 3
      pack $itk_component(close) -side right -expand 1 -pady 1 -padx 1

      #  Bind the wm deiconify event to restart tracing updates.
      bind [winfo toplevel $w_] <Map> [code $this start_trace_]
   }

   #  Destructor:
   #  -----------
   destructor  {
      stop_trace_
   }

   #  Methods:
   #  --------

   #  Create a new instance of this object.
   protected method clone_me_ {} {
      if { $itk_option(-clone_cmd) != {} } {
         eval $itk_option(-clone_cmd)
      }
   }

   #  Close this window.
   public method close {} {
      stop_trace_
      if { $itk_option(-really_die) } {
         delete object $this
      } else {
         wm withdraw $w_
      }
   }

   #  Recreate the components needed to display the coordinates.
   protected method update_displays_ {} {

      #  Clear any existing controls.
      if { [info exists domains_] }  {
         set i 0
         foreach domain "$domains_" {
            incr i
            catch {
               destroy $itk_component(frame$i)
               destroy $itk_component(x$i)
               destroy $itk_component(y$i)
               destroy $itk_component(label$i)
            }
         }
         unset domains_
      }

      #  Locate all the domains.
      set domains_ [$itk_option(-rtdimage) astdomains]
      set i 0
      set lwidth 15
      catch {
         set lwidth [expr 3+[string length $domains_]/[llength $domains_]]
      }
      foreach domain "$domains_" {
         incr i
         itk_component add frame$i {
            frame $itk_component(readoutarea).frame$i
         }
         set dframe $itk_component(frame$i)

         itk_component add label$i {
            label $dframe.label -text "$domain:" -width $lwidth -anchor e
         }

         set xvalues_($i) 0.0
         itk_component add x$i {
            entry $dframe.x -text "X value" -textvariable [scope xvalues_($i)]
         }
         set yvalues_($i) 0.0
         itk_component add y$i {
            entry $dframe.y -text "Y value" -textvariable [scope yvalues_($i)]
         }
         pack $dframe -side top -fill both -expand 1 -pady 3 -padx 3
         pack $itk_component(label$i) -side left -fill none
         pack $itk_component(x$i) -side left -fill x
         pack $itk_component(y$i) -side left -fill x
      }
      start_trace_
   }
   
   #  Called when new coordinates are to be shown.
   protected method update_readouts_ { args } {

      # Get the current base domain frame index.
      set current [$itk_option(-rtdimage) astget current]

      # Access variable with current X and Y coordinates.
      set var $itk_option(-rtdimage)
      global ::$var

      # For each domain, switch the image to it and then transform the
      # X and Y coordinates, update the readout. Trap problem domains
      # (3D etc.) and pass on to later ones.
      set i 0
      foreach domain $domains_ {
         catch {
            incr i
            $itk_option(-rtdimage) astset current $i
            set oldx [set ::${var}(X)]
            set oldy [set ::${var}(Y)]
            lassign [$itk_option(-rtdimage) astpix2cur $oldx $oldy] newx newy
            set xvalues_($i) $newx
            set yvalues_($i) $newy
         }
      }

      #  Restore default domain.
      $itk_option(-rtdimage) astset current $current
   }

   #  Method to call when the displayed image changes.
   public method image_changed {} {
      update_displays_
   }

   #  Start tracing changes in coordinates.
   protected method start_trace_ {} {
      if { ! $trace_active_ } {
         set var $itk_option(-rtdimage)
         global ::$var
         trace variable ::${var}(X) w [code $this update_readouts_]
         set trace_active_ 1
      }
   }

   #  Stop tracing variable (when closed or destroyed).
   protected method stop_trace_ {} {
      set var $itk_option(-rtdimage)
      global ::$var
      trace vdelete ::${var}(X) w [code $this update_readouts_]
      set trace_active_ 0
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Name of starrtdimage widget.
   itk_option define -rtdimage rtdimage Rtdimage {} {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0 {}

   #  Command to execute to create a new instance of this object.
   itk_option define -clone_cmd clone_cmd Clone_Cmd {}

   #  If this is a clone, then it should die rather than be withdrawn.
   itk_option define -really_die really_die Really_Die 0

   #  Protected variables: (available to instance)
   #  --------------------

   #  Domains that are available.
   protected variable domains_ {}
   protected variable xvalues_
   protected variable yvalues_

   #  Whether trace is active.
   protected variable trace_active_ 0

   #  Common variables: (shared by all instances)
   #  -----------------


#  End of class definition.
}
