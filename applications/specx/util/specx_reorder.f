*------------------------------------------------------------------------

      SUBROUTINE SPECX_REORDER (N, ISOURCE)

C  Routine to rearrange individual receiver spectra according to 
C  source array ISOURCE. Modified by JFL from SPECX_REORDER,
C  DATA array with variable sized quadrants catered for.

      IMPLICIT NONE

*     formal parameters:

      INTEGER   N
      INTEGER   ISOURCE(*)

*     include files:

      INCLUDE   'FLAGCOMM'
      INCLUDE   'STACKCOMM'

*     local variables:

      INTEGER   IPTR
      INTEGER   LENTGT
      INTEGER   NQ, K, OFFSET
      INTEGER   NTOTAL
      INTEGER   TARGET
      INTEGER   DSTART, DEND
      INTEGER   ISTAT

*     functions:

      INTEGER   NTOT
      INTEGER   IGETVM
      INTEGER   IFREEVM

*  Ok, go...

D     TYPE '('' # of sectors, sort array = '',I4.1,8I3.1)',
D    &          N, (ISOURCE(K),K=1,N)

C     First reorder data array
C     Get virtual memory and take copy of data 

      NTOTAL = NTOT(N)

      ISTAT = IGETVM (4*NTOTAL, .TRUE., 'SPECX_REORDER', IPTR)
      IF (ISTAT .ne. 0) THEN
        TYPE *, 'Trouble getting virtual memory for reordering:'
        TYPE *, ' ---', 4*NTOTAL, ' bytes requested'
        TYPE *, ' --- reordering not done'
        RETURN
      END IF

      CALL XCOPY  (4*NTOTAL, DATA, %VAL(IPTR))

      OFFSET = 1

C     and copy it back in the desired order

      DO NQ = 1, N

         TARGET = ISOURCE(NQ)

C        find start, end and length of target section

         DSTART = NTOT (TARGET-1)
         DEND   = NTOT (TARGET)
         LENTGT = NPTS (TARGET)

C        copy target section into output array

D        TYPE *, 'Copy of array segment from: start, end, length = ',
D    &            DSTART, DEND, LENTGT

         CALL XCOPY (4*LENTGT, %VAL(IPTR+ 4*DSTART), DATA(OFFSET))

C        and update offset

         OFFSET = OFFSET + LENTGT

      END DO

C     release virtual memory

      ISTAT = IFREEVM (IPTR)

C     What will happen to IQCEN?

      DO NQ = 1,N 
        IF (ISOURCE(NQ) .EQ. IQCEN) IQCEN = NQ
      END DO

C     Then rearrange quadrant dependent parameters

D     TYPE *, 'Sort of header variables: NQ = 1 to ', N-1

      DO NQ = 1, N-1

        IF (NQ.NE.ISOURCE(NQ)) THEN

          CALL EXCHNGE (NQ, ISOURCE(NQ), NPTS,   4)
          CALL EXCHNGE (NQ, ISOURCE(NQ), JFINC,  4)
          CALL EXCHNGE (NQ, ISOURCE(NQ), JFREST, 4)
          CALL EXCHNGE (NQ, ISOURCE(NQ), LOFREQ, 8)
          CALL EXCHNGE (NQ, ISOURCE(NQ), IFFREQ, 8)
          CALL EXCHNGE (NQ, ISOURCE(NQ), ITREC,  4)
          CALL EXCHNGE (NQ, ISOURCE(NQ), ITSKY,  4)
          CALL EXCHNGE (NQ, ISOURCE(NQ), ITTEL,  4)

          DO K = NQ,NQUAD
            IF (ISOURCE(K).EQ.NQ) THEN
              ISOURCE(K)  = ISOURCE(NQ)
              ISOURCE(NQ) = NQ
            END IF
          END DO

        END IF
      END DO


      END

*------------------------------------------------------------------------

