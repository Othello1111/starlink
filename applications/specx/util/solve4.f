*  History:
*     19 Nov 1993 (hme):
*        Remove TABs.
C-----------------------------------------------------------------------

      SUBROUTINE SOLVE4(ATA,ATFD,EPSLON,MM,NMAX)

C   This is a general subroutine to solve up to NMAX simultaneous
C   linear equations.
C   The technique used is gaussian elimination with partial pivoting of
C   rows and back substitution.
C   Some improvement in speed may be possible if pivoting is not actually
C   performed but pivot indices are arranged in the new array.

C   FORMAL PARAMETERS AS FOLLOWS:
C       ATA    : NMAX*NMAX MATRIX CONTAINING COEFFICIENTS
C       ATFD   :  NMAX VECTOR OF INDEPENDENT TERMS
C       EPSLON :  SOLUTION VECTOR
C       MM     :  NUMBER OF EQUATIONS TO BE SOLVED
C
 
      DIMENSION ATA(NMAX,NMAX),ATFD(1),EPSLON(1)

C   SOLUTION STARTS EQUAL TO VECTOR OF INDEPENDENT TERMS

      DO 605 I=1,MM
  605 EPSLON(I)=ATFD(I)
C
C   ITERATIVE REDUCTION TO UPPER TRIANGULAR MATRIX STARTS HERE.
C
      DO 650 N=1,MM-1
      I=N
      EX=0.0
C
C   FIND GREATEST ABSOLUTE VALUE LEFT IN COLUMN
C
      ANMAX=ABS(ATA(N,N))
      DO 620 M=N+1,MM
      AMAG=ABS(ATA(M,N))
      IF(AMAG.LE.ANMAX)   GO TO 620
      ANMAX=AMAG
      I=M
  620 CONTINUE
      IF(I.EQ.N)   GO TO 635
C
C   PIVOT IF DIAGONAL ELEMENT NOT GREATEST
C   I.E. SWAP ROWS SO THAT GREATEST VALUE OCCURS IN A(N,N)
C
      DO 630 J=N,MM
      AROW=ATA(I,J)
      ATA(I,J)=ATA(N,J)
      ATA(N,J)=AROW
  630 CONTINUE
C
C   ALSO SWAP TERMS IN INDEPENDENT VECTOR
C
      EX=EPSLON(I)
      EPSLON(I)=EPSLON(N)
      EPSLON(N)=EX
C
C   NORMALIZE ROW SO THAT DIAGONAL ELEMENT IS 1.0
C
  635 PIVOT =ATA(N,N)
      DO 645 J=N,MM
  645 ATA(N,J)=ATA(N,J)/PIVOT
      EPSLON(N)=EPSLON(N)/PIVOT
C
C   SUBTRACT OFF SUBSEQUENT EQUATIONS TO GIVE ZEROS IN POSITIONS BELOW
C   DIAGONAL ELEMENT
C
      K=N+1
      DO 650 I=K,MM
      ROWKEY=ATA(I,N)
      DO 655 J=N,MM
      ATA(I,J)=ATA(I,J)-ATA(N,J)*ROWKEY
  655 CONTINUE
      EPSLON(I)=EPSLON(I)-EPSLON(N)*ROWKEY
  650 CONTINUE
C
C   NORMALIZE LAST EQUATION (ATA(MM,MM)=EPSLON(MM))
C
      EPSLON(MM)=EPSLON(MM)/ATA(MM,MM)
      ATA(MM,MM)=1.
C
C   BACK SUBSTITUTION
C
      DO 660 K=1,MM-1
      N=MM+1-K
      DO 660 L=K,MM-1
      I=MM-L
      ROWKEY=ATA(I,N)
      DO 665 J=N,MM
      ATA(I,J)=ATA(I,J)-ATA(N,J)*ROWKEY
  665 CONTINUE
      EPSLON(I)=EPSLON(I)-EPSLON(N)*ROWKEY
  660 CONTINUE
      RETURN
      END


