      SUBROUTINE SEVAP

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

C     THIS SUBROUTINE COMPUTES SKIN EVAPORATION BASED ON THE MASS TRANSFER
C     COEFFICIENT, % OF SURFACE OF THE SKIN ACTING AS A FREE WATER SURFACE
C     AND EXPOSED TO THE AIR, AND THE VAPOR DENSITY GRADIENT BETWEEN THE
C     SURFACE AND THE AIR, EACH AT THEIR OWN TEMPERATURE.

      IMPLICIT NONE

      DOUBLE PRECISION ABSMAX,ABSMIN,AEFF,PEYES,AL,ALT
      DOUBLE PRECISION AMASS,ATOT,BP,CP,CUTFA
      DOUBLE PRECISION DENAIR,DB,DP,DELTAR,DEPSUB,E,EMISAN,ESAT,EXTREF
      DOUBLE PRECISION FATOSK,FATOSB,FLSHCOND,GEVAP
      DOUBLE PRECISION HD,HDFORC,HDFREE,HTOVPR,TSUBST
      DOUBLE PRECISION O2MAX,O2MIN,PATMOS,PCTEYE,PSTD,PTCOND,QSOLAR
      DOUBLE PRECISION QCOND,QCONV,QSEVAP,QIRIN,QIROUT,QMETAB,QRESP
      DOUBLE PRECISION R,RH,RELHUM,RQ,RW,SIG,SKINW,SPHEAT,SUBTK
      DOUBLE PRECISION TA,TAIR,TC,TDIGPR,TLUNG,TMAXPR,TMINPR,TSKIN
      DOUBLE PRECISION TR,TVIR,TVINC,V,VD,VDAIR,VDSURF,VEL,TBASK,TEMERGE
      DOUBLE PRECISION WATER,WB,WCUT,WEVAP,WEYES,WRESP,WTRPOT,XTRY
      DOUBLE PRECISION AIRVOL,CO2MOL,H2O_BALPAST
      DOUBLE PRECISION ANDENS,ASILP,EMISSB,EMISSK,FLUID,G
      DOUBLE PRECISION TPREF,HDD,SKINT,RAINFALL,HC,CONVAR,SIDEX,WQSOL
      DOUBLE PRECISION CUSTOMGEOM,MR_1,MR_2,MR_3,SHP,PTCOND_ORIG
      DOUBLE PRECISION RHO1_3,TRANS1,AREF,BREF,CREF,PHI,F21,F31,F41,F51
     &    ,PHIMIN,PHIMAX,TWING,F12,F32,F42,F52,F23,F24,F25,F26
     &,F61,TQSOL,A1,A2,A3,A4,A4B,A5,A6,F13,F14,F15,F16

      INTEGER LIVE,GEOMETRY,NODNUM,IDAY,IHOUR,DEB1,WINGMOD,WINGCALC

      CHARACTER*1 RAINACT

      DIMENSION CUSTOMGEOM(8),SHP(3)

      COMMON/FUN1/QSOLAR,QIRIN,QMETAB,QRESP,QSEVAP,QIROUT,QCONV,QCOND
      COMMON/FUN2/AMASS,RELHUM,ATOT,FATOSK,FATOSB,EMISAN,SIG,FLSHCOND
      COMMON/FUN3/AL,TA,VEL,PTCOND,SUBTK,DEPSUB,TSUBST,PTCOND_ORIG
      COMMON/FUN4/TSKIN,R,WEVAP,TR,ALT,BP,H2O_BALPAST
      COMMON/FUN6/SPHEAT,ABSMAX,ABSMIN,O2MAX,O2MIN,LIVE
      COMMON/WINGFUN/RHO1_3,TRANS1,AREF,BREF,CREF,PHI,F21,F31,F41,F51
     &,SIDEX,WQSOL,PHIMIN,PHIMAX,TWING,F12,F32,F42,F52
     &,F61,TQSOL,A1,A2,A3,A4,A4B,A5,A6,F13,F14,F15,F16,F23,F24,F25,F26
     &,WINGCALC,WINGMOD
      COMMON/EVAP1/PCTEYE,WEYES,WRESP,WCUT,AEFF,CUTFA,HD,PEYES,SKINW,
     &SKINT,HC,CONVAR
      COMMON/EVAP2/HDFREE,HDFORC
      COMMON/REVAP1/TLUNG,DELTAR,EXTREF,RQ,MR_1,MR_2,MR_3,DEB1
      COMMON/REVAP2/GEVAP,AIRVOL,CO2MOL
      COMMON/TPREFR/TMAXPR,TMINPR,TDIGPR,TPREF,TBASK,TEMERGE
      COMMON/BEHAV2/GEOMETRY,NODNUM,CUSTOMGEOM,SHP
      COMMON/GUESS/XTRY
      COMMON/RAINACT/RAINACT
      COMMON/TREG/TC
      COMMON/RAINFALLS/RAINFALL
      COMMON/DAYITR/IDAY
      COMMON/WDSUB1/ANDENS,ASILP,EMISSB,EMISSK,FLUID,G,IHOUR

      TAIR=TA
      V=VEL
      HDD=HDFREE+HDFORC
      XTRY=TC

C     CALCULATING SKIN SURFACE SATURATION VAPOR DENSITY
      RH = 100.
C     CHECK FOR TOO LOW A SURFACE TEMPERATURE
      IF(TSKIN.LT.0.) THEN
       DB=0.
      ELSE
       DB=TSKIN
      ENDIF

C     SETTING 3 PARAMETERS FOR WETAIR, SINCE RH IS KNOWN (SEE WETAIR2 LISTING)
      WB=0.
      DP=999.
C     BP CALCULATED FROM ALTITUDE USING THE STANDARD ATMOSPHERE
C     EQUATIONS FROM SUBROUTINE DRYAIR2    (TRACY ET AL,1972)
      PSTD=101325.
      PATMOS=PSTD*((1.-(.0065*ALT/288.))**(1./.190284))
      BP=PATMOS

      CALL WETAIR2(DB,WB,RH,DP,BP,E,ESAT,VD,RW,TVIR,TVINC,DENAIR,CP,
     * WTRPOT)
      VDSURF=VD

C     AIR VAPOR DENSITY
C     CHECKING FOR RAIN-LIMITED ACTIVITY
      IF(((RAINACT.EQ.'Y').OR.(RAINACT.EQ.'Y')).AND.(LIVE.EQ.1))THEN
       RH=99.
      ELSE
       RH=RELHUM
      ENDIF

      IF(RAINFALL.GT.1)THEN
       RH = 99.
      ENDIF

      DB=TAIR
      CALL WETAIR2(DB,WB,RH,DP,BP,E,ESAT,VD,RW,TVIR,TVINC,DENAIR,CP,
     * WTRPOT)
      VDAIR=VD

C     CHECKING FOR LIVING OBJECTS
      IF (LIVE .EQ. 1) THEN
C      OCULAR WATER LOSS
C      CHECKING FOR OPEN EYES (ACTIVE)
       IF((TC.GE.TBASK).AND.(TC.LE.TMAXPR))THEN
C       EYES OPEN
        WEYES=HDD*(PEYES/100.)*ATOT*(VDSURF-VDAIR)
       ELSE
C       EYES CLOSED AND RESTING
        WEYES = 0.0
       ENDIF
       WRESP = GEVAP/1000.
      ELSE
       WEYES=0.0
       WRESP=0.0
      ENDIF
C     END OF LIVE VS INANIMATE

      IF(LIVE.EQ.0)THEN
C      INANIMATE
       WCUT=AEFF*HDD*(VDSURF-VDAIR)
       WATER=WCUT
       GO TO 10
      ELSE
C      ANIMATE, CALCULATE BELOW
      ENDIF

      IF(WEYES.GT.0)THEN
       WCUT=(AEFF-(PEYES/100.)*ATOT*SKINW/100)*HDD*(VDSURF - VDAIR)
      ELSE
       WCUT=(AEFF+(PEYES/100.)*ATOT*SKINW/100)*HDD*(VDSURF - VDAIR)
      ENDIF
      WATER=WEYES+WRESP+WCUT
      PCTEYE=(WEYES/WATER)*100.
C     END OF COMPUTING AEFF FOR SURFACE OR NOT

   10 CONTINUE

C     FROM DRYAIR2: LATENT HEAT OF VAPORIZATION
      HTOVPR=2.5012E+06-2.3787E+03*TAIR
      QSEVAP=WATER*HTOVPR

C     KG/S TO G/S
      WEYES=WEYES*1000.
      WRESP=WRESP*1000.
      WCUT=WCUT*1000.
      WEVAP=WATER*1000.

      RETURN
      END