      SUBROUTINE FRSTS (XX,YY,IENT)
C
C THIS IS A SPECIAL VERSION OF THE SMOOTHING DASHED LINE PACKAGE.  LINES
C ARE SMOOTHED IN THE SAME WAY, BUT NO SOFTFARE DASHED LINES ARE USED.
C CONDITIONAL PLOTTING ROUTINES ARE CALL WHICH DETERMINE THE VISIBILITY
C OF A LINE SEGMENT BEFORE PLOTTING.
C
      SAVE
      DIMENSION       XSAVE(70)  ,YSAVE(70)  ,XP(70)     ,YP(70)     ,
     1                TEMP(70)
C
      COMMON /ISOSR7/ IENTRY     ,IONES
C
      DATA NP/150/
      DATA L1/70/
      DATA TENSN/2.5/
      DATA PI/3.14159265358/
      DATA SMALL/128./
C
      AVE(A,B) = .5*(A+B)
C
C  DECIDE IF FRSTS,VECTS,LASTS CALL
C
      GO TO ( 10, 20, 40),IENT
   10 DEG = 180./PI
      X = XX
      Y = YY
      LASTFL = 0
      SSLP1 = 0.0
      SSLPN = 0.0
      XSVN = 0.0
      YSVN = 0.0
C
C INITIALIZE THE POINT AND SEGMENT COUNTER
C N COUNTS THE NUMBER OF POINTS/SEGMENT
C
      N = 0
C
C NSEG = 0       FIRST SEGMENT
C NSEG = 1       MORE THAN ONE SEGMENT
C
      NSEG = 0
      CALL TR32 (X,Y,MX,MY)
C
C SAVE THE X,Y COORDINATES OF THE FIRST POINT
C XSV1           CONTAINS THE X COORDINATE OF THE FIRST POINT
C                OF A LINE
C YSV1           CONTAINS THE Y COORDINATE OF THE FIRST POINT
C                OF A LINE
C
      XSV1 = MX
      YSV1 = MY
      GO TO  30
C
C ************************* ENTRY VECTS *************************
C     ENTRY VECTS (XX,YY)
C
   20 X = XX
      Y = YY
C
C VECTS          SAVES THE X,Y COORDINATES OF THE ACCEPTED
C                POINTS ON A LINE SEGMENT
C
      CALL TR32 (X,Y,MX,MY)
C
CIF THE NEW POINT IS TOO CLOSE TO THE PREVIOUS POINT, IGNORE IT
C
      IF (ABS(FLOAT(IFIX(XSVN)-MX))+ABS(FLOAT(IFIX(YSVN)-MY)) .LT.
     1    SMALL) RETURN
      IFLAG = 0
   30 N = N+1
C
C SAVE THE X,Y COORDINATES OF EACH POINT OF THE SEGMENT
C XSAVE          THE ARRAY OF X COORDINATES OF LINE SEGMENT
C YSAVE          THE ARRAY OF Y COORDINATES OF LINE SEGMENT
C
      XSAVE(N) = MX
      YSAVE(N) = MY
      XSVN = XSAVE(N)
      YSVN = YSAVE(N)
      IF (N .GE. L1-1) GO TO  50
      RETURN
C
C ************************* ENTRY LASTS *************************
C     ENTRY LASTS
C
   40 LASTFL = 1
C
C LASTS          CHECKS FOR PERIODIC LINES AND SETS UP
C                  THE CALLS TO KURV1S AND KURV2S
C
C IFLAG = 0      OK TO CALL LASTS DIRECTLY
C IFLAG = 1      LASTS WAS JUST CALLED FROM BY VECTS
C                IGNORE CALL TO LASTS
C
      IF (IFLAG .EQ. 1) RETURN
C
C COMPARE THE LAST POINT OF SEGMENT WITH FIRST POINT OF LINE
C
   50 IFLAG = 1
C
C IPRD = 0       PERIODIC LINE
C IPRD = 1       NON-PERIODIC LINE
C
      IPRD = 1
      IF (ABS(XSV1-XSVN)+ABS(YSV1-YSVN) .LT. SMALL) IPRD = 0
C
C TAKE CARE OF THE CASE OF ONLY TWO DISTINCT P0INTS ON A LINE
C
      IF (NSEG .GE. 1) GO TO  70
      IF (N-2) 160,150, 60
   60 IF (N .GE. 4) GO TO  70
      DX = XSAVE(2)-XSAVE(1)
      DY = YSAVE(2)-YSAVE(1)
      SLOPE = ATAN2(DY,DX)*DEG+90.
      IF (SLOPE .GE. 360.) SLOPE = SLOPE-360.
      IF (SLOPE .LE. 0.) SLOPE = SLOPE+360.
      SLP1 = SLOPE
      SLPN = SLOPE
      ISLPSW = 0
      SIGMA = TENSN
      GO TO 110
   70 SIGMA = TENSN
      IF (IPRD .GE. 1) GO TO  90
      IF (NSEG .GE. 1) GO TO  80
C
C SET UP FLAGS FOR A  1  SEGMENT, PERIODIC LINE
C
      ISLPSW = 4
      XSAVE(N) = XSV1
      YSAVE(N) = YSV1
      GO TO 110
C
C SET UP FLAGS FOR AN N-SEGMENT, PERIODIC LINE
C
   80 SLP1 = SSLPN
      SLPN = SSLP1
      ISLPSW = 0
      GO TO 110
   90 IF (NSEG .GE. 1) GO TO 100
C
C SET UP FLAGS FOR THE 1ST SEGMENT OF A NON-PERIODIC LINE
C
      ISLPSW = 3
      GO TO 110
C
C SET UP FLAGS FOR THE NTH SEGMENT OF A NON-PERIODIC LINE
C
  100 SLP1 = SSLPN
      ISLPSW = 1
C
C CALL THE SMOOTHING ROUTINES
C
  110 CALL KURV1S (N,XSAVE,YSAVE,SLP1,SLPN,XP,YP,TEMP,S,SIGMA,ISLPSW)
      IF (IPRD.EQ.0 .AND. NSEG.EQ.0 .AND. S.LT.70.) GO TO 170
      IENTRY = 1
C
C DETERMINE THE NUMBER OF POINTS TO INTERPOLATE FOR EACH SEGMENT
C
      IF (NSEG.GE.1 .AND. N.LT.L1-1) GO TO 120
      NPRIME = FLOAT(NP)-(S*FLOAT(NP))/(2.*32768.)
      IF (S .GE. 32768.) NPRIME = .5*FLOAT(NP)
      NPL = FLOAT(NPRIME)*S/32768.
      IF (NPL .LT. 2) NPL = 2
  120 DT = 1./FLOAT(NPL)
      IF (NSEG .LE. 0) CALL FRSTC (IFIX(XSAVE(1)),IFIX(YSAVE(1)),1)
      T = 0.0
      NSLPSW = 1
      IF (NSEG .GE. 1) NSLPSW = 0
      NSEG = 1
      CALL KURV2S (T,XS,YS,N,XSAVE,YSAVE,XP,YP,S,SIGMA,NSLPSW,SLP)
C
C SAVE SLOPE AT THE FIRST POINT OF THE LINE
C
      IF (NSLPSW .GE. 1) SSLP1 = SLP
      NSLPSW = 0
      XSOLD = XSAVE(1)
      YSOLD = YSAVE(1)
      DO 130 I=1,NPL
         T = T+DT
         TT = -T
         IF (I .EQ. NPL) NSLPSW = 1
         CALL KURV2S (TT,XS,YS,N,XSAVE,YSAVE,XP,YP,S,SIGMA,NSLPSW,SLP)
C
C SAVE THE LAST SLOPE OF THIS LINE SEGMENT
C
         IF (NSLPSW .GE. 1) SSLPN = SLP
C
C DRAW EACH PART OF THE LINE SEGMENT
C
         CALL FRSTC (IFIX(AVE(XSOLD,XS)),IFIX(AVE(YSOLD,YS)),2)
         CALL FRSTC (IFIX(XS),IFIX(YS),2)
         XSOLD = XS
         YSOLD = YS
  130 CONTINUE
      IF (IPRD .NE. 0) GO TO 140
C
C CONNECT THE LAST POINT WITH THE FIRST POINT OF A PERIODIC LINE
C
      CALL FRSTC (IFIX(AVE(XSOLD,XS)),IFIX(AVE(YSOLD,YS)),2)
      CALL FRSTC (IFIX(XSV1),IFIX(YSV1),2)
C
C BEGIN THE NEXT LINE SEGMENT WITH THE LAST POINT OF THIS SEGMENT
C
  140 XSAVE(1) = XS
      YSAVE(1) = YS
      N = 1
  150 CONTINUE
  160 RETURN
  170 N = 0
      RETURN
      END
