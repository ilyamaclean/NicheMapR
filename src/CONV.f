      SUBROUTINE CONV

C     NICHEMAPR: SOFTWARE FOR BIOPHYSICAL MECHANISTIC NICHE MODELLING

C     COPYRIGHT (C) 2018 MICHAEL R. KEARNEY AND WARREN P. PORTER

C     THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY
C     IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
C     THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR (AT
C      YOUR OPTION) ANY LATER VERSION.

C     THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
C     WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
C     MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU
C     GENERAL PUBLIC LICENSE FOR MORE DETAILS.

C     YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
C     ALONG WITH THIS PROGRAM. IF NOT, SEE HTTP://WWW.GNU.ORG/LICENSES/.

C     COMPUTES CONVECTIVE HEAT EXCHANGE
C     ALL UNITS SI  (M,KG,S,C,K,J,PA)

      IMPLICIT NONE

      DOUBLE PRECISION A1,A2,A3,A4,A4B,A5,A6,AEFF,AHEIT,AL,ALENTH,ALT
      DOUBLE PRECISION AMASS,ANU,ANUFRE,AREF,AT,ATOT,AV,AWIDTH,BETA,BP
      DOUBLE PRECISION BREF,CONVAR,CP,CREF,CUSTOMGEOM,CUTFA,D,DB,DELTAT
      DOUBLE PRECISION DENSTY,DEPSUB,DIFVPR,EMISAN,F12,F13,F14,F15,F16
      DOUBLE PRECISION F21,F23,F24,F25,F26,F31,F32,F41,F42,F51,F52,F61
      DOUBLE PRECISION FATOSB,FATOSK,FLSHCOND,FLTYPE,G,GGROUP,GR,GRRE2
      DOUBLE PRECISION H2O_BALPAST,HC,HCFREE,HCFORC,HD,HDFORC,HDFREE
      DOUBLE PRECISION HTOVPR,PANT,PANTMAX,PATMOS,PEYES,PHI,PHIMAX
      DOUBLE PRECISION PHIMIN,PI,PMOUTH,PR,PR2,PTCOND,PTCOND_ORIG,QCOND
      DOUBLE PRECISION QCONV,QFORCED,QFREE,QIRIN,QIROUT,QMETAB,QRESP
      DOUBLE PRECISION QSEVAP,QSOLAR,R,RAYLEI,RE,RELHUM,RHO1_3,SC,SC2
      DOUBLE PRECISION SHFORC,SHFREE,SHP,SIDEX,SIG,SKINT,SKINW,SUBTK,TA
      DOUBLE PRECISION TCOEFF,THCOND,TOTLEN,TQSOL,TR,TRANS1,TSKIN,TSUBST
      DOUBLE PRECISION TWING,VEL,VISDYN,VISKIN,WCUT,WEVAP,WEYES,WQSOL
      DOUBLE PRECISION WRESP

      INTEGER GEOMETRY,NODNUM,WINGCALC,WINGMOD

      DIMENSION CUSTOMGEOM(8),SHP(3)

      COMMON/BEHAV2/GEOMETRY,NODNUM,CUSTOMGEOM,SHP
      COMMON/DIMENS/ALENTH,AWIDTH,AHEIT
      COMMON/EVAP1/WEYES,WRESP,WCUT,AEFF,CUTFA,HD,PEYES,SKINW
     & ,SKINT,HC,CONVAR,PMOUTH,PANT,PANTMAX
      COMMON/EVAP2/HDFREE,HDFORC
      COMMON/FUN1/QSOLAR,QIRIN,QMETAB,QRESP,QSEVAP,QIROUT,QCONV,QCOND
      COMMON/FUN2/AMASS,RELHUM,ATOT,FATOSK,FATOSB,EMISAN,SIG,FLSHCOND
      COMMON/FUN3/AL,TA,VEL,PTCOND,SUBTK,DEPSUB,TSUBST,PTCOND_ORIG
      COMMON/FUN4/TSKIN,R,WEVAP,TR,ALT,BP,H2O_BALPAST
      COMMON/WCOND/TOTLEN,AV,AT
      COMMON/WCONV/FLTYPE
      COMMON/WINGFUN/RHO1_3,TRANS1,AREF,BREF,CREF,PHI,F21,F31,F41,F51,
     & SIDEX,WQSOL,PHIMIN,PHIMAX,TWING,F12,F32,F42,F52,F61,TQSOL,A1,
     & A2,A3,A4,A4B,A5,A6,F13,F14,F15,F16,F23,F24,F25,F26,WINGCALC,
     & WINGMOD

      DATA PI/3.14159265/

C     ALT = ALTITUDE
C     ANU = NUSSELT NUMBER
C     ATOT = TOTAL AREA
C     BETA = COEFFICIENT OF THERMAL EXPANSION AT CONSTANT DENSITY (1/K)
C     (USED IN GRASHOF NUMBER (1/FLUID TEMP (C), I.E. AIR OR WATER)
C     BP = BAROMETRIC PRESSURE
C     CP = SPECIFIC HEAT OF DRY AIR (J/KG-C)
C     D = CHARACTERISTIC DIMENSION FOR CONVECTION
C     DB = DRY BULB TEMPERATURE (C)
C     DELTAT = TEMPERATURE DIFFERENCE
C     DENSTY = DENSITY OF AIR
C     DIFVPR = DIFFUSIVITY OF WATER VAPOR
C     FLTYPE = FLUID TYPE (0.0 = AIR; 1.0 = WATER)
C     G = ACCELERATION DUE TO GRAVITY
C     GGROUP = GROUP OF GRASHOF VARIABLES
C     GR = GRASHOF NUMBER
C     GRRE2 = GRASHOF/REYNOLDS NUMBER SQUARED
C     HC = HEAT TRANSFER COEFFICIENT
C     HCFREE = HEAT TRANSFER COEFFICIENT, FREE CONVECTION
C     HCFORC = HEAT TRANSFER COEFFICIENT, FORCED CONVECTION
C     HD = MASS TRANSFER COEFFICIENT
C     HDFREE = MASS TRANSFER COEFFICIENT, FREE CONVECTION
C     HDFORC = MASS TRANSFER COEFFICIENT, FORCED CONVECTION
C     HTOVPR = WATER VAPOR PRESSURE
C     IGEOM = CHOOSER FOR CONVECTION EQUATIONS ACTUALLY USED
C     GEOMETRY = NUMBER SPECIFYING GEOMETRY TO BE USED:
C      0 = PLATE, 1 = CYLINDER, 2 = ELLIPSOID, 3 = LIZARD
C      4 = FROG, 5 = USER SUPPLIED
C     PATMOS = ATMOSPHERIC PRESSURE
C     PR = PRANDTL NUMBER
C     QCONV = HEAT LOSS BY CONVECTION
C     RE = REYNOLD'S NUMBER
C     SC = SCHMIDT NUMBER
C     SH = SHERWOOD NUMBER
C     TA = AIR TEMPERATURE (C)
C     TCOEFF = TEMPERATURE COEFFICIENT OF EXPANSION OF AIR
C     RAYLEI = RAYLEIGH NUMBER = GRASHOF-PRANDTL PRODUCT
C     THCOND = THERMAL CONDUCTIVITY OF AIR
C     VEL = AIR VELOCITY
C     VISDYN = DYNAMIC VISCOSITY OF AIR
C     VISKIN = KINEMATIC VISCOSITY OF AIR
C     TSKIN = CURRENT GUESS OF OBJECT SURFACE TEMPERATURE

      ANUFRE=0.
      ANU=0.

C     SETTING THE CHARACTERISTIC DIMENSION FOR NUSSELT-REYNOLDS CORRELATIONS
      D = AL

      IF(WINGMOD.GT.0)THEN
C      MAKE THE CHARACTERISTIC DIMENSION INCRESE WITH HOW OPEN THE WINGS ARE
C      WHICH IS WORKED OUT AS A4 = D * CREF/100, WITH A4 THE AREA OF IMAGINARY SURFACE
C      SPANNING THE WINGS, BREF THE BODY LENGTH
       IF(WINGCALC.EQ.1)THEN
        D=CREF/100
       ELSE
        D=AL
       ENDIF
      ENDIF

      BETA=1./(TA+273.)
      CP=1.0057E+3
      G=9.80665
      
C     CONVECTIVE AREA CALCULATION = TOTAL AREA - VENTRAL AREA IN CONTACT WITH SUBSTRATE
      IF(WINGMOD.GT.0)THEN
C      REDUCE SURFACE AREA IF WINGS ARE CLOSED (PHI<=90) OR FLAT ON SUBSTRATE (PHI>180)
C      MIGHT WANT TO ALTER THIS TO ACCOUNT FOR BUTTERFLIES PERCHING ON VEG VS. ON A SUBSTRATE
       IF(WINGCALC.EQ.1)THEN
        CONVAR = ATOT
       ELSE
        CONVAR=PI*AL*ALENTH
        CONVAR=ATOT
       ENDIF
      ELSE
       CONVAR=ATOT-AV-AT
      ENDIF

C     USING ALTITUDE TO COMPUTE BP (SEE DRYAIR LISTING)
      BP=0.0
      DB=TA

C     GET THERMAL PROPERTIES OF DRY AIR AT CURRENT TEMP AND PRESSURE
      CALL DRYAIR(DB,BP,ALT,PATMOS,DENSTY,VISDYN,VISKIN,DIFVPR,
     *THCOND,HTOVPR,TCOEFF,GGROUP)

C     CHECKING TO SEE IF THE FLUID IS WATER, NOT AIR
      IF(FLTYPE.EQ.1.0) THEN
       CALL WATER(TA,BETA,CP,DENSTY,THCOND,VISDYN)
      ENDIF

C     COMPUTING PRANDLT AND SCHMIDT NUMBERS
      PR=CP*VISDYN/THCOND
      IF(FLTYPE.EQ.0.0) THEN
C      AIR
       SC=VISDYN/(DENSTY*DIFVPR)
      ELSE
C      WATER; NO MEANING
       SC=1.0
      ENDIF

C     SKIN/AIR TEMPERATURE DIFFERENCE
      DELTAT=TSKIN-TA
      IF(DELTAT.EQ.0.0000000)THEN
       DELTAT = 0.01
      ENDIF
      
C     COMPUTNIG GRASHOF NUMBER      
      GR=((DENSTY**2.)*BETA*G*(D**3.)*DELTAT)/(VISDYN**2.)
C     CORRECTING IF NEGATIVE DELTAT
      GR=ABS(GR)

C     AVOIDING DIVIDE BY ZERO IN FREE VS FORCED RAYLEI
      IF(VEL.LE.0.000000000000) VEL=0.0001
      
C     REYNOLDS NUMBER      
      RE=DENSTY*VEL*D/VISDYN

C     CHOOSING FREE OR FORCED CONVECTION
C     SIGNIFICANT FREE CONVECTION IF GR/RE**2 .GE. 20.0
C     KREITH (1965) P. 358
      GRRE2=GR/(RE**2.)

C     *********************  FREE CONVECTION  ********************
      IF(GEOMETRY.EQ.0)THEN
       RAYLEI=GR*PR
       ANUFRE=0.55*RAYLEI**0.25
      ENDIF

      IF((GEOMETRY.EQ.1).OR.(GEOMETRY.EQ.3).OR.(GEOMETRY.EQ.5))THEN
C      FREE CONVECTION OF A CYLINDER ******DOUBLE CHECK THEN BREAKPOINTS HERE!!!!
C      FROM P.334 KREITH (1965): MC ADAM'S 1954 RECOMMENDED COORDINATES
       RAYLEI=GR*PR
       IF(RAYLEI.LT.1.0E-05)THEN
        ANUFRE=0.4
        GO TO 15
       ENDIF
       IF(RAYLEI.LT.0.1)THEN
        ANUFRE=0.976*RAYLEI**0.0784
        GO TO 15
       ENDIF
       IF(RAYLEI.LE.100)THEN
        ANUFRE=1.1173*RAYLEI**0.1344
        GO TO 15
       ENDIF
       IF(RAYLEI.LT.10000.)THEN
        ANUFRE=0.7455*RAYLEI**0.2167
        GO TO 15
       ENDIF
       IF(RAYLEI.LT.1.0E+09)THEN
        ANUFRE=0.5168*RAYLEI**0.2501
        GO TO 15
       ENDIF
       IF(RAYLEI.LT.1.0E+12)THEN
        ANUFRE=0.5168*RAYLEI**0.2501
        GO TO 15
       ENDIF
      ENDIF

      IF((GEOMETRY.EQ.2).OR.(GEOMETRY.EQ.4))THEN
C      SPHERE FREE CONVECTION
C      FROM P.413 BIRD ET AL (1960) TRANSPORT PHENOMENA)
       RAYLEI=(GR**(1./4.))*(PR**(1./3.))
       ANUFRE=2.+0.60*RAYLEI
       IF(RAYLEI .LT. 200.) THEN
        GO TO 20
       ELSE
CC      WRITE(6,13) RAYLEI
C   13   FORMAT(1X,'(GR**.25)*(PR**.333) ',1E10.4,
C     *    ' IS TOO LARGE FOR CORREL.')
       ENDIF
      ENDIF
      GO TO 20

C     FORCED CONVECTION FOR ANIMAL

   15 CONTINUE

      IF((GEOMETRY.EQ.3).OR.(GEOMETRY.EQ.4).OR.(GEOMETRY.EQ.5))THEN
C      CALCULATE FORCED CONVECTION FOR LIZARDS, FROGS OR TURTLES
       PR2=.72
       SC2=.60
       IF((GEOMETRY.EQ.3).OR.(GEOMETRY.EQ.5))THEN
        ANU=0.35*RE**0.6
C       FROM P. 216, EDE; AN INTRODUCTION TO HEAT TRANSFER. 1967
        !SH = ANU*(SC2/PR2)**.333
       ENDIF
       IF(GEOMETRY.EQ.4)THEN
C       ***********************FROG******************************
C       C.R. TRACY'S LEOPARD FROGS - ECOL. MONOG. 1976 V. 46(3)
C       CHECKING FOR OUT OF BOUNDS VALUES
C       IF (RE .LT. 80.) THEN
C        WRITE(0,*)' RE, ',RE,',TOO SMALL FOR FROG ANCORR'
C       ELSE
C        IF (RE .GT. 40000.) THEN
C         WRITE(0,*)' RE, ',RE,',TOO LARGE FOR FROG ANCORR'
C        ENDIF
C       ENDIF
C       COMPUTING NUSSELT AND SHERWOOD NUMBERS
        IF(RE.LE.2000.) THEN
         ANU=0.88*RE**0.5
         !SH=0.76*RE**0.5
        ELSE
         ANU=0.258*RE**0.667
         !SH=0.216*RE**0.667
        ENDIF
       ENDIF
      ENDIF

   20 CONTINUE

      IF(WINGCALC.EQ.1)THEN
       RAYLEI=GR*PR
       ANUFRE=0.55*RAYLEI**0.25
      ENDIF

C     CALCULATING THE FREE CONVECTION HEAT TRANSFER COEFFICIENT, HC  (NU=HC*D/KAIR)
      HCFREE=(ANUFRE*THCOND)/D
C     CAP AT MIN VALUE FOR AIR OF 5 W/M2K HTTP://WWW.ENGINEERINGTOOLBOX.COM/CONVECTIVE-HEAT-TRANSFER-D_430.HTML
C      IF(HCFREE.LT.5)THEN
C       HCFREE=5
C      ENDIF

C     CALCULATING THE SHERWOOD NUMBER FROM THE COLBURN ANALOGY
C     (BIRD, STEWART & LIGHTFOOT, 1960. TRANSPORT PHENOMENA. WILEY.
      SHFREE=ANUFRE*(SC/PR)**(1./3.)
C     CALCULATING THE MASS TRANSFER COEFFICIENT FROM THE SHERWOOD NUMBER
      HDFREE=SHFREE*DIFVPR/D
C     CALCULATING THE CONVECTIVE HEAT LOSS AT THE SKIN
      QFREE=HCFREE*CONVAR*(TSKIN-TA)

C     *******************  FORCED CONVECTION  *********************
      IF(WINGMOD.GT.0)THEN
       GOTO 35 ! SKIP TO BUTTERFLY CONVECTION
      ENDIF

      IF(GEOMETRY.EQ.0)THEN
       ANU=0.102*RE**0.675*PR**(1./3.)
      ENDIF

      IF(GEOMETRY.EQ.1)THEN
C      FORCED CONVECTION OF A CYLINDER
C      ADJUSTING NU - RE CORRELATION FOR RE NUMBER (P. 260 MCADAMS,1954)
       IF(RE.LT.4.)THEN
        ANU=.891*RE**.33
        GO TO 40
       ENDIF
       IF(RE.LT.40.)THEN
        ANU=.821*RE**.385
        GO TO 40
       ENDIF
       IF(RE.LT.4000.)THEN
        ANU=.615*RE**.466
        GO TO 40
       ENDIF
       IF(RE.LT.40000.)THEN
        ANU=.174*RE**.618
        GO TO 40
       ENDIF
       IF(RE.LT.400000.)THEN
        ANU=.0239*RE**.805
        GO TO 40
       ENDIF
      ENDIF

      IF((GEOMETRY.EQ.2).OR.(GEOMETRY.EQ.4))THEN
C      FORCED CONVECTION IN SPHERE
C       ANU=0.34*RE**0.24 ! ORIGINAL RELATION
       ANU=0.35*RE**0.6 ! FROM McAdams, W.H. 1954. Heat Transmission. McGraw-Hill, New York, p.532
       GO TO 40
      ENDIF

C     FORCED CONVECTION FOR ANIMAL
   35 CONTINUE
      IF(WINGMOD.GT.0)THEN
       IF(WINGCALC.EQ.1)THEN
        ANU = 1.18*RE**0.5*PR**(1./3.)
       ELSE
C       GATES, EQ 9.90
C       ANU=1.06*RE**0.5
C       BELOW, 0 DEGREES ORIENTATION IS FIRST, THEN 90 DEGREES FOR FEMALES THEN FOR MALES
        IF(PHI.LE.100)THEN
         ANU=7.16966163653326*RE**0.0262414285714286
        ENDIF
        IF((PHI.GT.100).AND.(PHI.LE.125))THEN
         ANU=1.04562044604698*RE**0.2694125
        ENDIF
        IF((PHI.GT.125).AND.(PHI.LE.140))THEN
         ANU=0.998755268878792*RE**0.302962857142857
        ENDIF
        IF((PHI.GT.140).AND.(PHI.LE.160))THEN
         ANU=0.635917304973853*RE**0.348638571428571
        ENDIF
        IF(PHI.GT.160)THEN
         ANU=1.28899681613556*RE**0.29015125
        ENDIF
       ENDIF
      ENDIF
C  **************************************************************************
   40 CONTINUE
      HCFORC=ANU*THCOND/D ! HEAT TRANFER COEFFICIENT
      SHFORC=ANU*(SC/PR)**(1./3.) ! SHERWOOD NUMBER
      HDFORC=SHFORC*DIFVPR/D ! MASS TRANSFER COEFFICIENT
      QFORCED=HCFORC*CONVAR*(TSKIN-TA) ! FORCED CONVECTION HEAT TRANSFER
      QCONV=QFREE+QFORCED ! TOTAL CONVECTIVE TRANSFER
      HC=HCFREE+HCFORC ! TOTAL CONVECTIVE HEAT TRANSFER COEFFICIENT
      HD=HDFORC+HDFREE ! TOTAL MASS TRANSFER COEFFICIENT
      END
