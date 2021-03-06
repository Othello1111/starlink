      SUBROUTINE GETSET (VL,VR,VB,VT,WL,WR,WB,WT,LF)
C
C GETSET returns to its caller the current values of the parameters
C defining the mapping from the user system to the fractional system
C (in GKS terminology, the mapping from world coordinates to normalized
C device coordinates).
C
C VL, VR, VB, and VT define the viewport (in the fractional system), WL,
C WR, WB, and WT the window (in the user system), and LF the nature of
C the mapping, according to the following table:
C
C    1  -  x linear, y linear
C    2  -  x linear, y logarithmic
C    3  -  x logarithmic, y linear
C    4  -  x logarithmic, y logarithmic
C
C Declare the common block containing the linear-log and mirror-imaging
C flags.
C
      COMMON /IUTLCM/ LL,MI,MX,MY,IU(96)
C
C Define variables to receive the GKS viewport and window.
C
      DIMENSION VP(4),WD(4)
C
C Retrieve the number of the current GKS normalization transformation.
C
      CALL GQCNTN (IE,NT)
C
C Retrieve the definition of that normalization transformation.
C
      CALL GQNT (NT,IE,WD,VP)
C
C Pass the viewport definition to the caller.
C
      VL=VP(1)
      VR=VP(2)
      VB=VP(3)
      VT=VP(4)
C
C Pass the linear/log flag and a (possibly modified) window definition
C to the caller.
C
      LF=LL
C
      IF (LL.EQ.1.OR.LL.EQ.2) THEN
        WL=WD(1)
        WR=WD(2)
      ELSE
        WL=10.**WD(1)
        WR=10.**WD(2)
      END IF
C
      IF (MI.GE.3) THEN
        WW=WL
        WL=WR
        WR=WW
      END IF
C
      IF (LL.EQ.1.OR.LL.EQ.3) THEN
        WB=WD(3)
        WT=WD(4)
      ELSE
        WB=10.**WD(3)
        WT=10.**WD(4)
      END IF
C
      IF (MI.EQ.2.OR.MI.GE.4) THEN
        WW=WB
        WB=WT
        WT=WW
      END IF
C
      RETURN
C
      END
