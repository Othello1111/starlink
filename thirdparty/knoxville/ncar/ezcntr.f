      SUBROUTINE EZCNTR (Z,M,N)
C
C CONTOURING VIA SHORTEST POSSIBLE ARGUMENT LIST
C ASSUMPTIONS --
C     ALL OF THE ARRAY IS TO BE CONTOURED,
C     CONTOUR LEVELS ARE PICKED INTERNALLY,
C     CONTOURING ROUTINE PICKS SCALE FACTORS,
C     HIGHS AND LOWS ARE MARKED,
C     NEGATIVE LINES ARE DRAWN WITH A DASHED LINE PATTERN,
C     EZCNTR CALLS FRAME AFTER DRAWING THE CONTOUR MAP.
C IF THESE ASSUMPTIONS ARE NOT MET, USE CONREC.
C
C ARGUMENTS
C     Z   ARRAY TO BE CONTOURED
C     M   FIRST DIMENSION OF Z
C     N   SECOND DIMENSION OF Z
C
      SAVE
      DIMENSION       Z(M,N)
      DATA NSET,NHI,NDASH/0,0,682/
C
C                             682=1252B
C THE FOLLOWING CALL IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR
C
      CALL Q8QST4 ('GRAPHX','CONREC','EZCNTR','VERSION 01')
C
      CALL CONREC (Z,M,M,N,0.,0.,0.,NSET,NHI,-NDASH)
      CALL FRAME
      RETURN
      END
