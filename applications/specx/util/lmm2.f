*  History:
*     19 Nov 1993 (hme):
*        Remove TABs.
*        The statement WRITE(LU,101) ((I,X(I)),I=1,NPST) (two
*        occurences) had to be changed. The redundant parantheses seem
*        to constitute a syntax violation.
C-----------------------------------------------------------------------
C
      SUBROUTINE LMM2(X,F,A,SUMSQ,N,NP,TOL,EXPND,DECR,ITS,IER,
     * C,G,WORK,ICON,LU,FUNVAL)
C
C
      DIMENSION X(1),F(1),A(1),C(1),G(1),WORK(1),ICON(1),IIX(110)
      DOUBLE PRECISION S,SSS,SSF,SSR,WW,SSN,SUMSQ
      CHARACTER IX(110)*1
      EXTERNAL FUNVAL
      REAL MACHEP
C
C
C     LEVENBERG,MARQUARDT,MORRISON ALGORITHM IMPLEMENTED FOLLOWING
C     SUGGESTION OF GOLUB ( SEE OSBORNE 'SOME ASPECTS OF NONLINEAR LEAST
C     SQUARES CALCULATIONS' EDITOR F.A. LOOTSMA ACADEMIC PRESS). MAIN
C     FEATURE OF THIS ROUTINE IS AN IMPROVED TEST FOR ACCEPTING 
C     PREDICTED CORRECTION AND ADJUSTING LEVENBERG PARAMETER EPS
C
C     VARIABLES
C
C     X(1)  VECTOR OF INDEPENDENT VARIABLES
C           INPUT; CONTAINS ESTIMATE OF SOLUTION
C           OUTPUT; CONTAINS SOLUTION VECTOR OR LAST ATTEMPT
C
C     F(1)  STORAGE FOR F VECTOR OF TERMS IN SUM OF SQUARES 
C           OUTPUT; VECTOR OF TERMS (USUALLY RESIDUALS ) IN SUM
C           OF SQUARES
C
C     A(1)  STORAGE OF GRAD F BY COLUMNS
C           I.E. THE DERIVATIVES OF ALL THE F(I) W.R.T.
C           THE FIRST PARAMETER FOLLOWED BY ALL THE DERIVATIVES
C           W.R.T. THE SECOND PARAMETER, ETC.
C
C     SUMSQ OUTPUT; CONTAINS SUM OF SQUARES
C
C     N     INPUT; NO.OF TERMS IN SUM OF SQUARES
C
C     NP    INPUT; NO. OF PARAMETERS INCLUDING ANY TO BE HELD CONSTANT
C
C     TOL   INPUT; TOLERANCE ON CALCULATION OF SUM OF SQUARES
C
C     EXPND INPUT; FACTOR BY WHICH EPS INREASED IF TEST ON SUM OF
C           SQUARES FAILS, SUGGESTED VALUE 1.5
C
C     DECR  INPUT; FACTOR BY WHICH EPS DECREASED IF TEST ON SUM OF
C           SQUARES SUCCEEDS ON FIRST ATTEMPT, SUGGESTED VALUE 0.5
C
C     ITS   INPUT; MAX NUMBER OF ITERATIONS
C           OUTPUT; ACTUAL NUMBER OF ITERATIONS
C
C     IER   INPUT;=-1+(100*NCONST)  NO PRINTING
C                 = 0+(100*NCONST)  PRINTING AFTER CONVERGENCE ONLY
C                 = 1+(100*NCONST)  PRINT DIAGNOSTIC INFORMATION
C                 = 2+(100*NCONST)  AS ABOVE PLUS GRADIENT CHECK
C           WHERE NCONST = NO. OF PARAMETERS TO BE HELD CONSTANT
C           OUTPUT;=1 SUCCESSFUL TERMINATION
C                  =2 MAX ITS EXCEEDED
C                  =3 EPS EXCEEDS1.D6
C                  =4 ALL GRADIENTS ZERO FOR ONE OR MORE PARAMETES
C                  =5 NO. OF PARAMETERS LESS THAN ONE
C
C     C(1)  OUTPUT; CONTAINS APPROXIMATE STANDARD ERRORS OF PARAMETER 
C                   ESTIMATES
C
C     G(1)  OUTPUT; CONTAINS A VECTOR OF UNCORRELATED RESIDUALS
C
C     WORK(1)    WORKING SPACE, MUST BE DIMENSIONED AT LEAST
C                NPR*(NPR+5) +NCONST IN CALLING PROGRAM,
C                WHERE NCONST IS THE NUMBER OF PARAMETERS TO BE HELD
C                CONSTANT AND NPR =NP-NCONST
C
C     ICON(1)    INPUT; ICON(I)=1 IF THE I-TH PARAMETER IS TO BE HELD
C                       CONSTANT
C                              =0 OTHERWISE
C
C     LU         INPUT; LOGICAL UNIT NUMBER OF OUTPUT FILE
C
C
C     FUNVAL     USER SUPPLIED SUBROUTINE REQUIRED TO SET VALUES OF SUMSQ,
C                F & A.
C     DECLARATION MUST BE :
C        SUBROUTINE FUNVAL(X,F,WORK,SUMSQ,IFL)
C        IF IFL=1 SETS ALL VALUES
C        IF IFL=2 SETS SUMSQ ONLY, MUST NOT ALTER A,F
C
C     N.B. THE VALUE OF IFL IS SUPPLIED BY LMM2 AND MUST NOT BE CHANGED
C
C
C    MACHEP IS A MACHINE DEPENDENT CONSTANT
C
C
C
      MACHEP=1.E-08
      NCONST=(IER+1)/100
      IPRINT=IER-100*NCONST
      IF(NCONST.NE.0)   GO TO 48
      DO 47 I=1,NP
   47 ICON(I)=0
   48 CONTINUE
C
C**** CHECK GRADIENT CALCULATION IF IER=2
C
      IF(IPRINT.NE.2)   GO TO 50
      CALL FUNVAL(X,G,A,SSN,1)
      WRITE(LU,401)
      DO 402 I=1,NP
      J=ICON(I)
      IF(J.EQ.1)   GO TO 402
      WRITE(LU,119) I
      L1= (I-1)*N+1
      L2=I*N
      WRITE(LU,120) (A(L),L=L1,L2)
  402 CONTINUE
      WRITE(LU,425)
      DO 404 I9=1,NP
      J=ICON(I9)
      IF(J.EQ.1)   GO TO 404
      WRITE(LU,119) I9
      X0=X(I9)
      X(I9)=1.01*X0
      IF(X0.EQ.0.0)   X(I9)=X0+.001
      CALL FUNVAL(X,F,A,S,1)
      DO 412 J=1,N
  412 F(J)=(F(J)-G(J))/(X(I9)-X0)
      WRITE(LU,120) (F(J),J=1,N)
      X(I9)=X0
  404 CONTINUE
C
C**** SET UP STARTING VALUES
C
   50 IF(IPRINT.LE.0)   GO TO 41
      WRITE(LU,102)
   41 MAXITS=ITS
      EPS=1.0
      ITS=0
      IC=0
C
C**** CHECK ICON AGAINST NCONST
C
      NPST=NP
      IF(NCONST.EQ.0)   GO TO 35
      IP=0
      DO 39 I=1,NP
   39 IP=IP+ICON(I)
      IF(IP.EQ.NCONST)   GO TO 37
      WRITE(LU,118) IP
      NCONST=IP
   37 NP = NP - NCONST
      IF(NP.GT.0)   GO TO 35
      WRITE(LU,117) NP
      IER=5
      RETURN
   35 IDA=NP*NP
      IDU=IDA+NP
      ID =IDU+NP
      IDX=ID +NP
      IY=IDX+NP
C
C**** START OF ITERATIVE CYCLE
C 
   40 ITS=ITS+1
      NITS=0
      CALL FUNVAL(X,F,A,SSF,1)
      IF(NCONST.EQ.0)   GO TO 38
      J=0
      DO 58 I=1,NPST
      K=ICON(I)
      J=J+K
      IF(J.EQ.0.OR.K.EQ.1) GO TO 58
      II=(I-1)*N
      KK=(I-J-1)*N
      DO 54 K=1,N
   54 A(KK+K) = A(II+K)
   58 CONTINUE
C
C**** SCALE THE MATRIX OF DERIVATIVES SO THAT COLUMNS
C**** HAVE LENGTH = 1. SCALE FACTOR I STORED IN WORK(ID+I)
C**** FOR PARAMETER I.
C
   38 DO 1  I=1,NP
      II=(I-1)*N
      S=0.D0
      DO 2 J=1,N
    2 S=S+A(II+J)**2
      IF(S.NE.0.D0)   GO TO 23
      WRITE(LU,121) I
      IER=4
      RETURN
   23 S=1.D0/DSQRT(S)
      DO 3 J=1,N
    3 A(II+J)=A(II+J)*S
    1 WORK(ID+I)=S
      IF(IPRINT.LE.0)   GO TO 42
      WRITE(LU,100) ITS,EPS,SSF
C
C**** HOUSEHOLDER TRANSFORMATION OF DERIVATIVES AND COLUMN
C**** OF RESIDUALS, AND TEST FOR SINGULARITIES.
C
   42 DO 4 I=1,NP
      II=(I-1)*N
      S=0.D0
      DO 5 J=I,N
    5 S=S+A(II+J)**2
      S=DSQRT(S)
      IF(S.GT.100.*MACHEP) GO TO 24
      IF(ITS.NE.1)   GO TO 49
      S=S+MACHEP
      GO TO 24
   49 WRITE(LU,122) I
      II=I
      J=1
   27 IF(ICON(J).EQ.0)   GO TO 46
      II=II+1
   46 J=J+1
      IF(J.LE.II)   GO TO 27
      ICON(II)=1
      NP=NP-1
      NCONST=NCONST+1
      GO TO 40
   24 IF(A(II+I).GT.0.) S=-S
      WORK(IDA+I)=S
      A(II+I)=A(II+I)-S
      IF(I.EQ.NP)   GO TO 6
      IP1=I+1
      KK=I*N
      DO 7 K=IP1,NP
      S=0.D0
      DO 8 J=1,N
    8 S=S+A(II+J)*A(KK+J)
      S=-S/(WORK(IDA+I)*A(II+I))
      DO 9 J=I,N
    9 A(KK+J)=A(KK+J)-S*A(II+J)
    7 KK=KK+N
    6 S=0.D0
      DO 20 J=I,N
   20 S=S+A(II+J)*F(J)
      S=-S/(WORK(IDA+I)*A(II+I))
      DO 21 J=I,N
      F(J)=F(J)-S*A(II+J)
   21 CONTINUE
    4 CONTINUE
C
C**** COMPUTE SUM OF SQUARES OF RESIDUALS
C
      NP1=NP+1
      SSR=0.D0
      DO 22 I=NP1,N
   22 SSR=SSR+F(I)**2
C
C**** FACTOR EPS APENDAGE, TRANSFORM RHS
C**** UPPER TRIANGLE OF TRANSFORMED MATRIX STORED IN W.
C**** (I,J) ELEMENT STORED IN WORK(I-1*NP+J)
C
   19 IP=0
      DO 30 I=1,NP
      DO 31 J=1,I
   31 WORK(IP+J)=0.
      WORK(IP+I)=EPS
   30 IP=IP+NP
      IP=0
      DO 10 I=1,NP
      C(I)=0.
      S=WORK(IDA+I)**2
      IP1=I+1
      IL1=I-1
      DO 12 J=1,I
   12 S=S+WORK(IP+J)**2
      S=DSQRT(S)
      IF(WORK(IDA+I).GT.0.)   S=-S
      WORK(IDU+I)=S
      WW=WORK(IDA+I)-S
      IF(I.EQ.NP)   GO TO 18
      KP=IP+NP
      DO 13 K=IP1,NP
      KK=(K-1)*N+1
      S=A(KK)*WW
      IF(I.EQ.1)   GO TO 11
      DO 14 J=1,IL1
   14 S=S+WORK(IP+J)*WORK(KP+J)
   11 S=-S/(WORK(IDU+I)*WW)
      WORK(IP+K)=A(KK)-S*WW
      DO 15 J=1,I
   15 WORK(KP+J)=WORK(KP+J)-S*WORK(IP+J)
   13 KP=KP+NP
   18 S=F(I)*WW
      DO 16 J=1,I
   16 S=S+WORK(IP+J)*C(J)
      S=-S/(WORK(IDU+I)*WW)
      WORK(IDX+I)=F(I)-S*WW
      DO 17 J=1,I
   17 C(J)=C(J)-S*WORK(IP+J)
   10 IP=IP+NP
C
C**** BACK SUBSTITUTION, NEW VALUES OF PARAMETER I STORED IN WORK(IY+I)
C
      WORK(IY)=WORK(IY)/WORK(ID)
      KP=(NP-1)*NP
      DO 25 I=2,NP
      K=NP-I+1
      KP1=K+1
      KP=KP-NP
      S=0.D0
      DO 26 J=KP1,NP
   26 S=S+WORK(KP+J)*WORK(IDX+J)
   25 WORK(IDX+K)=(WORK(IDX+K)-S)/WORK(IDU+K)
      SSS=SSR
      J=0
      DO 32 I=1,NP
   36 II=I+J
      K=ICON(II)
      IF(K.EQ.1)   WORK(IY+II)=X(II)
      J=J+K
      IF(K.EQ.1)   GO TO 36
      SSS=SSS+C(I)**2
      WORK(IDX+I)=WORK(IDX+I)*WORK(ID+I)
   32 WORK(IY+II)=X(II)-WORK(IDX+I)
      NITS=NITS+1
C
C**** TEST FOR CONVERGENCE
C
      CALL FUNVAL(WORK(IY+1),F,A,SSN,2)
      S=0.5D0*(SSF-SSN)/(SSF-SSS)
      IF(IPRINT.LE.0)   GO TO 43
      WRITE(LU,103) NITS,EPS,SSN,SSS,S
   43 IF(S.GE.1.D-4)   GO TO 28
      EPS=EXPND*EPS
      IC=0
      IER=3
      IF(EPS.LT.1.E6)   GO TO 19
      WRITE(LU,45)
      GO TO 910
   28 DO 29 I=1,NPST
   29 X(I)=WORK(IY+I)
      IF(IPRINT.LE.0)   GO TO 44
      WRITE(LU,101) (I,X(I), I=1,NPST)
   44 IER=2
      IF(ITS.GE.MAXITS)   GO TO 220
      IER=1
      IF((DSQRT(SSF)-DSQRT(SSS))/(1.D0+DSQRT(SSF)).LE.TOL)   GO TO 220
      IF(NITS.EQ.1)    EPS=EPS*DECR
      IC=0
      GO TO 40
C
C**** CONVERGENCE TEST SATISFIED OR MAXITS REACHED
C
  220 SUMSQ=SSN
      IF(IC.EQ.1)   GO TO 90
      IF(SSF-SSN.LE.SSF*1000.*MACHEP)  GO TO 90
      IF(ITS.LT.MAXITS)   GO TO 82
      WRITE(LU,104) ITS
      GO TO 910
   82 IF(IPRINT.GE.0)   WRITE(LU,105)
      IF(IPRINT.EQ.0)   WRITE(LU,100) ITS,EPS,SSN
      IF(IPRINT.EQ.0)   WRITE(LU,101) (I,X(I), I=1,NPST)
      IC=1
      EPS=EPS*DECR
      GO TO 40
   90 DO 91 I=1,N
   91 G(I)=F(I)
      X0=0.
      IF(N.GT.NP)   X0=SUMSQ/(N-NP)
      II=0
      DO 33 I=1,NP
      A(II+I)=WORK(IDA+I)
      IF(WORK(IDA+I).EQ.0.0)   GO TO 87
      S=1.0/WORK(ID+I)
   87 DO 34 J=1,I
   34 A(II+J)=A(II+J)*S
   33 II=II+N
C
C**** INVERT UPPER TRIANGULAR MATRIX
C
      II=0
      DO 70 I=1,NP
      IF(A(II+I).EQ.0.0)   GO TO 59
      A(II+I)=1.0/A(II+I)
   59 IF(I.EQ.1)   GO TO 70
      IL1=I-1
      DO 65 J=1,IL1
      S=0.D0
      DO 60 K=J,IL1
      KJ=(K-1)*N+J
   60 S=S-A(II+K)*A(KJ)
   65 A(II+J)=S*A(II+I)
   70 II=II+N
C
C**** MULTIPLY INVERSE BY ITS TRANSPOSE
C
      L=0
      II=0
      DO 80 I=1,NP
      DO 79 J=1,I
      L=L+1
      S=0.D0
      KK=II
      DO 75 K=I,NP
      S=S+A(KK+I)*A(KK+J)
   75 KK=KK+N
   79 WORK(L)=S*X0
   80 II=II+N
C
C**** PRINT PARAMETER ESTIMATES AND THEIR STANDARD ERRORS
C**** AND CORRELATIONS OF PARAMETER ESTIMATES
C
      IF(IPRINT.GE.0)   WRITE(LU,106)
      KK=1
      J=0
      DO 92 I=1,NP
  88  II=I+J
      K=ICON(II)
      J=J+K
      IF(K.EQ.1)   GO TO 88
      C(I)=SQRT(WORK(KK))
      KK=KK+I+1
   92 IF(IPRINT.GE.0)   WRITE(LU,107) II,X(II),C(I)
      IF(NP.GE.N)   GO TO 910
      IF(IPRINT.GE.0)   WRITE(LU,108)
      L=0
      KJ=0
      DO 95 I=1,NP
   89 II=I+KJ
      K=ICON(II)
      KJ=KJ+K
      IF(K.EQ.1)   GO TO 89
      IF(C(I).NE.0)   GO TO 83
      C(I)=MACHEP
      GO TO 95
   83 DO 94 J=1,I
      L=L+1
   94 WORK(IY+J)=WORK(L)/(C(I)*C(J))
      IF(IPRINT.GE.0) WRITE(LU,109) II,(WORK(IY+J),J=1,I)
   95 CONTINUE
      IF(IPRINT.GE.0)   WRITE(LU,110) X0
      CALL FUNVAL(X,F,A,SUMSQ,1)
      IF(IPRINT.LT.0)   GO TO 900
C
C**** GRAPHICAL PLOT OF RESIDUALS
C**** ADAPTED FROM SUBROUTINE DOTPLOT BY D.CULPIN
C**** USES CHARACTER FORMAT WHICH IS NOT ANSI FORTRAN
C
      X0=SQRT(X0)
      IC=0
      ID=110
   93 IF(IC+ID.GT.N)   ID=N-IC
      WRITE(LU,111)
      XL=3.5*X0
      DO 96 I=1,ID
      IX(I)=' '
   96 IF(F(I+IC).GT.XL)   IX(I)='O'
      WRITE(LU,112) (IX(I),I=1,ID)
   97 XU=XL
      XL=XU-X0
      YU=XU/X0
      YL=XL/X0
      DO 98 I=1,ID
      IX(I)=' '
   98 IF(F(I+IC).LE.XU.AND.F(I+IC).GT.XL)   IX(I)='*'
      WRITE(LU,113) YL,YU,(IX(I),I=1,ID)
      IF(XL.GT.-3.4*X0)   GO TO 97
      DO 99 I=1,ID
      IX(I)=' '
   99 IF(F(I+IC).LE.XL)   IX(I)='O'
      WRITE(LU,114) (IX(I),I=1,ID)
      DO 85 I=1,ID
      IX(I)=' '
   85 IF(I.EQ.10*(I/10)) IX(I)=';'
      WRITE(LU,115) (IX(I),I=1,ID)
      K=(ID/10)+1
      DO 86 I=1,K
   86 IIX(I)=10*(I-1)+IC
      WRITE(LU,116) (IIX(I),I=1,K)
      IC=IC+100
      IF(IC.LT.N-10)   GO TO 93
C
C**** RELOCATE VAR-COV MATRIX AND STANDARD ERRORS IF NCONST.NE.0
C
  900 IF(NCONST.EQ.0)   RETURN
      L=NP*(NP+1)/2
      L2=NP
      I=NPST
  904 K=ICON(I)
      IF(K.EQ.1)   GO TO 903
      C(I)=C(L2)
      L2=L2-1
      J=I
  901 K=I*(I-1)/2+J
      WORK(K)=WORK(L)
      L=L-1
  902 J=J-1
      IF(J.LE.0)   GO TO 903
      K=ICON(J)
      IF(K.LT.0)   GO TO 902
      GO TO 901
  903 I=I-1
      IF(I.GT.0)   GO TO 904
  910 NP=NPST
      RETURN
   45 FORMAT(20X,32HERROR, EPS HAS REACHED A MILLION/)
  100 FORMAT(7H   ITS=,I3,5H EPS=,E14.6,7H SUMSQ=,D14.6)
  101 FORMAT(4(3H X(,I2,1H),E14.6))
  102 FORMAT(50H1   NONLINEAR LEAST SQUARES BY LEVENBERG ALGORITHM)
  103 FORMAT(7H  NITS=,I3,5H EPS=,E14.6,7H SUMSQ=,D14.6,
     *11H RES SUMSQ=,D14.6,6H PSI =, E14.6)
  104 FORMAT(/20X,21HFAILED TO CONVERGE IN,I6,11H ITERATIONS/)
  105 FORMAT(/20X,23HEVIDENCE OF CONVERGENCE/)
  106 FORMAT(/15X,32HPARAMETER ESTIMATES(APPROX.S.E.))
  107 FORMAT(I10,E22.6,3H  (,E10.4,1H))
  108 FORMAT(/20X,35HCORRELATIONS OF PARAMETER ESTIMATES)
  109 FORMAT(/I6,(10F12.5))
  110 FORMAT(///20X,
     *52HPLOT OF STANDARDIZED RESIDUALS (STANDARD DEVIATION =,E10.3,1H))
  111 FORMAT(//18H ST.DEVS.FROM ZERO/)
  112 FORMAT(19H  MORE THAN  3.5  ;110A1)
  113 FORMAT(F8.1,3H TO,F5.1,2X,1H;,110A1)
  114 FORMAT(19H  LESS THAN -3.5  ;110A1)
  115 FORMAT(18X,1H;,110A1)
  116 FORMAT(9X,12I10/)
  117 FORMAT(/10X,
     *32HNO. OF PARAMETERS TO BE VARIED =,I8,14HLESS THAN ONE,/)
  118 FORMAT(/10X,45HICON INCONSISTENT WITH NCONST, NCONST RESET =,
     1 I8/)
  119 FORMAT(2X,13HPARAMETER NO.,I8)
  120 FORMAT(8E16.7)
  121 FORMAT(/5X,37HALL GRADIENTS ZERO FOR THIS PARAMETER,I8)
  122 FORMAT(2X,9HPARAMETER,I8,
     148H IS LINEARLY DEPENDANT UPON PREVIOUS PARAMETERS/5X,
     231HPARAMETER WILL BE KEPT CONSTANT)
  401 FORMAT(//5X,21HGRADIENTS FROM FUNVAL)
  425 FORMAT(//5X,26HGRADIENTS FROM DIFFERENCES)
      END
C
