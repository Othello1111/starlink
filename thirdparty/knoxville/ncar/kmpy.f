      FUNCTION KMPY (IY)
C
C Given a y coordinate IY in the metacode system, KMPY(IY) is a y
C coordinate in the plotter system.
C
      COMMON /IUTLCM/ LL,MI,MX,MY,IU(96)
      KMPY=1+IFIX((2.**MY-1.)*FLOAT(IY)/32767.)
      RETURN
      END
