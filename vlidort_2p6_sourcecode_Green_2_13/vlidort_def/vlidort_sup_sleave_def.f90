
! ###############################################################
! #                                                             #
! #                    THE VECTOR LIDORT MODEL                  #
! #                                                             #
! #  (Vector LInearized Discrete Ordinate Radiative Transfer)   #
! #   -      --         -        -        -         -           #
! #                                                             #
! ###############################################################

! ###############################################################
! #                                                             #
! #  Author :      Robert. J. D. Spurr                          #
! #                                                             #
! #  Address :     RT Solutions, inc.                           #
! #                9 Channing Street                            #
! #                Cambridge, MA 02138, USA                     #
! #                Tel: (617) 492 1183                          #
! #                                                             #
! #  Email :       rtsolutions@verizon.net                      #
! #                                                             #
! #  Versions     :   2.0, 2.2, 2.3, 2.4, 2.4R, 2.4RT, 2.4RTC,  #
! #                   2.5, 2.6                                  #
! #  Release Date :   December 2005  (2.0)                      #
! #  Release Date :   March 2007     (2.2)                      #
! #  Release Date :   October 2007   (2.3)                      #
! #  Release Date :   December 2008  (2.4)                      #
! #  Release Date :   April 2009     (2.4R)                     #
! #  Release Date :   July 2009      (2.4RT)                    #
! #  Release Date :   October 2010   (2.4RTC)                   #
! #  Release Date :   March 2011     (2.5)                      #
! #  Release Date :   May 2012       (2.6)                      #
! #                                                             #
! #       NEW: TOTAL COLUMN JACOBIANS         (2.4)             #
! #       NEW: BPDF Land-surface KERNELS      (2.4R)            #
! #       NEW: Thermal Emission Treatment     (2.4RT)           #
! #       Consolidated BRDF treatment         (2.4RTC)          #
! #       f77/f90 Release                     (2.5)             #
! #       External SS / New I/O Structures    (2.6)             #
! #                                                             #
! ###############################################################

!    #####################################################
!    #                                                   #
!    #   This Version of VLIDORT comes with a GNU-style  #
!    #   license. Please read the license carefully.     #
!    #                                                   #
!    #####################################################

      MODULE VLIDORT_Sup_SLEAVE_def

!    Introduced to VLIDORT, 17 May 2012, R. Spurr, RT Solutions Inc.

!  This module contains the following structures:
!     VLIDORT_Sup_SLEAVE    Intent(In)  for VLIDORT,
!                           Intent(Out) for VLIDORT SleaveSup

      USE VLIDORT_PARS

      IMPLICIT NONE

! #####################################################################
! #####################################################################

      TYPE VLIDORT_Sup_SLEAVE

!  Isotropic Surface leaving term (if flag set)

      REAL(fpk), dimension ( MAXSTOKES, MAXBEAMS ) :: &
        TS_SLTERM_ISOTROPIC

!  Exact Surface-Leaving term

      REAL(fpk), dimension ( MAXSTOKES, MAX_USER_STREAMS, &
        MAX_USER_RELAZMS, MAXBEAMS ) :: TS_SLTERM_USERANGLES

!  Fourier components of Surface-leaving terms:
!    Every solar direction, SL-transmitted quadrature streams
!    Every solar direction, SL-transmitted user streams

      REAL(fpk), dimension ( 0:MAXMOMENTS, MAXSTOKES, MAXSTREAMS, &
        MAXBEAMS )   :: TS_SLTERM_F_0
      REAL(fpk), dimension ( 0:MAXMOMENTS, MAXSTOKES, MAX_USER_STREAMS, &
        MAXBEAMS )   :: TS_USER_SLTERM_F_0

      END TYPE VLIDORT_Sup_SLEAVE

! #####################################################################
! #####################################################################

!  EVERYTHING PUBLIC HERE

      PRIVATE
      PUBLIC :: VLIDORT_Sup_SLEAVE

      END MODULE VLIDORT_Sup_SLEAVE_def
