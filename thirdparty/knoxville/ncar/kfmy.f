      FUNCTION KFMY (RY)
C
C Given a y coordinate RY in the fractional system, KFMY(RY) is a y
C coordinate in the metacode system.
C
      KFMY=IFIX(RY*32767.)
      RETURN
      END
