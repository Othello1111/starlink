C
C
C
        SUBROUTINE TICKS(LMAJ,LMIN)
C
        COMMON /TICK/ MAJX,MINX,MAJY,MINY
        REAL MAJX,MINX,MAJY,MINY
C
C  THE FOLLOWING IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR
C
        CALL Q8QST4('GRAPHX','GRIDAL','TICKS','VERSION 01')
C
        CALL TICK4(LMAJ,LMIN,LMAJ,LMIN)
C
        RETURN
        END
