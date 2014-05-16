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
! #                   2.5, 2.6, 2.7                             #
! #  Release Date :   December 2005  (2.0)                      #
! #  Release Date :   March 2007     (2.2)                      #
! #  Release Date :   October 2007   (2.3)                      #
! #  Release Date :   December 2008  (2.4)                      #
! #  Release Date :   April 2009     (2.4R)                     #
! #  Release Date :   July 2009      (2.4RT)                    #
! #  Release Date :   October 2010   (2.4RTC)                   #
! #  Release Date :   March 2011     (2.5)                      #
! #  Release Date :   May 2012       (2.6)                      #
! #  Release Date :   May 2014       (2.7)                      #
! #                                                             #
! #       NEW: TOTAL COLUMN JACOBIANS          (2.4)            #
! #       NEW: BPDF Land-surface KERNELS       (2.4R)           #
! #       NEW: Thermal Emission Treatment      (2.4RT)          #
! #       Consolidated BRDF treatment          (2.4RTC)         #
! #       f77/f90 Release                      (2.5)            #
! #       External SS / New I/O Structures     (2.6)            #
! #                                                             #
! #       Surface-leaving, BRDF Albedo-scaling (2.7)            # 
! #       Taylor series, Black-body Jacobians  (2.7)            #
! #                                                             #
! ###############################################################

!    #####################################################
!    #                                                   #
!    #   This Version of VLIDORT comes with a GNU-style  #
!    #   license. Please read the license carefully.     #
!    #                                                   #
!    #####################################################

! ###############################################################
! #                                                             #
! # Subroutines in this Module                                  #
! #                                                             #
! #            VBRDF_LIN_INPUTMASTER                            #
! #            VBRDF_LIN_MAINMASTER                             #
! #                                                             #
! ###############################################################


MODULE vbrdf_LinSup_masters_m

      PRIVATE
      PUBLIC :: VBRDF_LIN_INPUTMASTER, &
                VBRDF_LIN_MAINMASTER

      CONTAINS

      SUBROUTINE VBRDF_LIN_INPUTMASTER ( &
        FILNAM,               & ! Input
        VBRDF_Sup_In,         & ! Outputs
        VBRDF_LinSup_In,      & ! Outputs
        VBRDF_Sup_InputStatus ) ! Outputs

!  Input routine for BRDF program

!  Observational Geometry Inputs. Marked with !@@
!     Installed 31 december 2012. 
!       Observation-Geometry input control.       DO_USER_OBSGEOMS
!       Observation-Geometry input control.       N_USER_OBSGEOMS
!       User-defined Observation Geometry angles. USER_OBSGEOMS
!     Added solar_sources flag for better control (DO_SOLAR_SOURCES)
!     Added Overall-exact flag for better control (DO_EXACT)

      USE VLIDORT_PARS
      USE VBRDF_FINDPAR_M

      USE vbrdf_sup_inputs_def
      USE vbrdf_sup_outputs_def

      USE vbrdf_linsup_inputs_def

!  Implicit none

      IMPLICIT NONE

!  Arguments
!  ---------

      CHARACTER (LEN=*), INTENT(IN) :: FILNAM

      TYPE(VBRDF_Sup_Inputs)   , INTENT(OUT) :: VBRDF_Sup_In
      TYPE(VBRDF_LinSup_Inputs), INTENT(OUT) :: VBRDF_LinSup_In

      TYPE(VBRDF_Input_Exception_Handling), INTENT(OUT) :: &
        VBRDF_Sup_InputStatus

!  Local variables
!  ---------------

!  Stream angle flag

      LOGICAL ::          DO_USER_STREAMS

!  BRDF surface flag
!    ---> Really should be true here

      LOGICAL ::          DO_BRDF_SURFACE

!  Surface emission

      LOGICAL ::          DO_SURFACE_EMISSION

!   !@@ Solar sources + Observational Geometry flag !@@

      LOGICAL ::          DO_SOLAR_SOURCES
      LOGICAL ::          DO_USER_OBSGEOMS

!  Number of Stokes components

      INTEGER ::          NSTOKES

!  Number and index-list and names of bidirectional functions

      INTEGER ::            N_BRDF_KERNELS
      INTEGER ::            WHICH_BRDF ( MAX_BRDF_KERNELS )
      CHARACTER (LEN=10) :: BRDF_NAMES ( MAX_BRDF_KERNELS )

!  Parameters required for Kernel families

      INTEGER ::          N_BRDF_PARAMETERS ( MAX_BRDF_KERNELS )
      DOUBLE PRECISION :: BRDF_PARAMETERS &
          ( MAX_BRDF_KERNELS, MAX_BRDF_PARAMETERS )

!  Lambertian Surface control

      LOGICAL ::          LAMBERTIAN_KERNEL_FLAG ( MAX_BRDF_KERNELS )

!  Input kernel amplitude factors

      DOUBLE PRECISION :: BRDF_FACTORS ( MAX_BRDF_KERNELS )

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      LOGICAL   :: DO_WSA_SCALING
      LOGICAL   :: DO_BSA_SCALING
      REAL(fpk) :: WSA_VALUE, BSA_VALUE

!  Number of azimuth quadrature streams for BRDF

      INTEGER ::          NSTREAMS_BRDF

!  Shadowing effect flag (only for Cox-Munk type kernels)

      LOGICAL ::          DO_SHADOW_EFFECT

!  Exact flag (!@@) and Exact only flag --> no Fourier term calculations

      LOGICAL ::          DO_EXACT
      LOGICAL ::          DO_EXACTONLY

!  Multiple reflectance correction for Glitter kernels

      LOGICAL ::          DO_MSRCORR
      INTEGER ::          MSRCORR_ORDER
      LOGICAL ::          DO_MSRCORR_EXACTONLY
      INTEGER ::          MSRCORR_NMUQUAD
      INTEGER ::          MSRCORR_NPHIQUAD

!  Flags for WF of bidirectional function parameters and factors

      LOGICAL ::          DO_KERNEL_FACTOR_WFS  ( MAX_BRDF_KERNELS )
      LOGICAL ::          DO_KERNEL_PARAMS_WFS  ( MAX_BRDF_KERNELS, &
                                                  MAX_BRDF_PARAMETERS )

!  Derived quantity (tells you when to do BRDF derivatives)

      LOGICAL ::          DO_KPARAMS_DERIVS  ( MAX_BRDF_KERNELS )

!  WSA and BSA scaling options. Weighting function flags.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      LOGICAL ::          DO_WSAVALUE_WF
      LOGICAL ::          DO_BSAVALUE_WF

!  Number of surface weighting functions

      INTEGER ::          N_SURFACE_WFS
      INTEGER ::          N_KERNEL_FACTOR_WFS
      INTEGER ::          N_KERNEL_PARAMS_WFS

!  Number of discrete ordinate streams

      INTEGER ::          NSTREAMS

!  Local angle control

      INTEGER ::          NBEAMS
      INTEGER ::          N_USER_STREAMS
      INTEGER ::          N_USER_RELAZMS

!  Angles

      DOUBLE PRECISION :: BEAM_SZAS   (MAXBEAMS)
      DOUBLE PRECISION :: USER_RELAZMS(MAX_USER_RELAZMS)
      DOUBLE PRECISION :: USER_ANGLES (MAX_USER_STREAMS)

!  !@@ Local Observational Geometry control and angles

      INTEGER ::          N_USER_OBSGEOMS
      DOUBLE PRECISION :: USER_OBSGEOMS (MAX_USER_OBSGEOMS,3)

!  Exception handling. New code, 18 May 2010
!     Message Length should be at least 120 Characters

      INTEGER ::             STATUS
      INTEGER ::             NMESSAGES
      CHARACTER (LEN=120) :: MESSAGES ( 0:MAX_MESSAGES )
      CHARACTER (LEN=120) :: ACTIONS ( 0:MAX_MESSAGES )

!  local variables
!  ===============

      CHARACTER (LEN=9), PARAMETER :: PREFIX = 'BRDFSUP -'

      INTEGER ::            DUM_INDEX, DUM_NPARS
      CHARACTER (LEN=10) :: DUM_NAME
      LOGICAL ::            ERROR
      CHARACTER (LEN=80) :: PAR_STR
      INTEGER ::            I, J, K, L, FILUNIT, NM

!  Check list of Kernel names

      CHARACTER (LEN=10) :: BRDF_CHECK_NAMES ( MAXBRDF_IDX )

      BRDF_CHECK_NAMES = (/ &
                           'Lambertian', &
                           'Ross-thin ', &
                           'Ross-thick', &
                           'Li-sparse ', &
                           'Li-dense  ', &
                           'Hapke     ', &
                           'Roujean   ', &
                           'Rahman    ', &
                           'Cox-Munk  ', &
                           'GissCoxMnk', &
                           'GCMcomplex', &
                           'BPDF2009  '/)

!  Initialize Exception handling

      STATUS = VLIDORT_SUCCESS

      MESSAGES(1:MAX_MESSAGES) = ' '
      ACTIONS (1:MAX_MESSAGES) = ' '

      NMESSAGES       = 0
      MESSAGES(0)     = 'Successful Read of VLIDORT Input file'
      ACTIONS(0)      = 'No Action required for this Task'

!  Local error handling initialization

      ERROR  = .FALSE.
      NM     = NMESSAGES

!  Open file

      FILUNIT = VLIDORT_INUNIT
      OPEN(VLIDORT_INUNIT,FILE=FILNAM,ERR=300,STATUS='OLD')

!  Initialize Angle control
!  ========================

      DO_USER_OBSGEOMS = .FALSE.  !@@ New line
      DO_SOLAR_SOURCES = .FALSE.  !@@ New line

      DO_USER_STREAMS = .FALSE.
      NSTREAMS = 0

      NBEAMS   = 0
      DO I = 1, MAXBEAMS
        BEAM_SZAS(I) = ZERO
      ENDDO
      N_USER_STREAMS = 0
      DO I = 1, MAX_USER_STREAMS
        USER_ANGLES(I) = ZERO
      ENDDO
      N_USER_RELAZMS = 0
      DO I = 1, MAX_USER_RELAZMS
        USER_RELAZMS(I) = ZERO
      ENDDO

! !@@ Observational Geometry

      N_USER_OBSGEOMS = 0
      DO I = 1, MAX_USER_OBSGEOMS
        USER_OBSGEOMS(I,1:3) = ZERO
      ENDDO

      NSTOKES = 0

!  Initialize Surface stuff
!  ========================

      NSTREAMS_BRDF  = 0
      N_BRDF_KERNELS = 0

      DO_SHADOW_EFFECT    = .FALSE.
      DO_EXACT            = .FALSE.       !@@  New line
      DO_EXACTONLY        = .FALSE.
      DO_SURFACE_EMISSION = .FALSE.

      DO_MSRCORR           = .FALSE.
      MSRCORR_ORDER        = 0
      DO_MSRCORR_EXACTONLY = .FALSE.
      MSRCORR_NMUQUAD      = 0
      MSRCORR_NPHIQUAD     = 0

      DO K = 1, MAX_BRDF_KERNELS
        LAMBERTIAN_KERNEL_FLAG(K) = .FALSE.
        BRDF_FACTORS(K) = ZERO
        DO L = 1, MAX_BRDF_PARAMETERS
          BRDF_PARAMETERS(K,L) = ZERO
        ENDDO
      ENDDO

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      DO_WSA_SCALING = .false.
      DO_BSA_SCALING = .false.
      WSA_VALUE      = zero
      BSA_VALUE      = zero
      DO_WSAVALUE_WF = .false.
      DO_BSAVALUE_WF = .false.

!  Linearized stuff

      N_SURFACE_WFS       = 0
      N_KERNEL_FACTOR_WFS = 0
      N_KERNEL_PARAMS_WFS = 0
      DO K = 1, MAX_BRDF_KERNELS
        DO_KPARAMS_DERIVS(K) = .FALSE.
        DO_KERNEL_FACTOR_WFS(K) = .FALSE.
        DO L = 1, MAX_BRDF_PARAMETERS
          DO_KERNEL_PARAMS_WFS(K,L) = .FALSE.
        ENDDO
      ENDDO

!  number of Stokes components
!  ===========================

      PAR_STR = 'Number of Stokes vector components'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
          READ (FILUNIT,*,ERR=998) NSTOKES
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Read Angle stuff
!  ================

!  Basic control for solar sources

      PAR_STR = 'Use solar sources?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SOLAR_SOURCES
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  User-defined Stream angle

      PAR_STR = 'Use user-defined viewing zenith angles?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
          READ (FILUNIT,*,ERR=998) DO_USER_STREAMS
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Discrete ordinates

      PAR_STR = 'Number of half-space streams'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) NSTREAMS
      CALL FINDPAR_ERROR (ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  All numbers are now checked against maximum dimensions

      IF ( NSTREAMS .GT. MAXSTREAMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = 'Number of half-space streams > maximum dimension'
        ACTIONS(NM)  = 'Re-set input value or increase MAXSTREAMS dimension'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        GO TO 764
      ENDIF

!  Observational Geometry    !@@
!  ======================

!  !@@ New flag, Observational Geometry

      IF ( DO_SOLAR_SOURCES ) THEN
         PAR_STR = 'Do Observation Geometry?'
         IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
              READ (FILUNIT,*,ERR=998) DO_USER_OBSGEOMS
         CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  !@@ Observational Geometry control
!     ---- check not exceeding dimensioned number

      IF ( DO_USER_OBSGEOMS ) THEN
        PAR_STR = 'Number of Observation Geometry inputs'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) N_USER_OBSGEOMS
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
        IF ( N_USER_OBSGEOMS .GT. MAX_USER_OBSGEOMS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of ObsGeometry inputs > Maximum dimension'
          ACTIONS(NM)  = 'Re-set input or increase MAX_USER_OBSGEOMS dimension'
          STATUS       = VLIDORT_SERIOUS
          NMESSAGES    = NM
          GO TO 764
        ENDIF
      ENDIF

!  !@@ Observational Geometry control
!     Automatic setting of NBEAMS, N_USER_STREAMS, N_USER_RELAZMS

      IF ( DO_USER_OBSGEOMS ) THEN
         NBEAMS          = N_USER_OBSGEOMS
         N_USER_STREAMS  = N_USER_OBSGEOMS
         N_USER_RELAZMS  = N_USER_OBSGEOMS
         DO_USER_STREAMS = .TRUE.
      ENDIF

!  !@@ Observational Geometry control

      IF ( DO_USER_OBSGEOMS ) THEN
        PAR_STR = 'Observation Geometry inputs'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
           DO I = 1, N_USER_OBSGEOMS
             READ (FILUNIT,*,ERR=998)&
               USER_OBSGEOMS(I,1), USER_OBSGEOMS(I,2), USER_OBSGEOMS(I,3)
           ENDDO
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Set angles

      IF ( DO_USER_OBSGEOMS ) THEN
         BEAM_SZAS   (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,1)
         USER_ANGLES (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,2)
         USER_RELAZMS(1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,3)
         GO TO 5667
      ENDIF

!  Solar beams
!  ===========

!  number of Solar zenith angles

      PAR_STR = 'Number of solar zenith angles'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) NBEAMS
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  check not exceeding dimensioned number

      IF ( NBEAMS .GT. MAXBEAMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = 'Number of solar zenith angles > maximum dimension'
        ACTIONS(NM)  = 'Re-set input value or increase MAXBEAMS dimension'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        GO TO 764
      ENDIF

!  TOA solar zenith angle inputs

      PAR_STR = 'Solar zenith angles (degrees)'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
        DO I = 1, NBEAMS
          READ (FILUNIT,*,ERR=998) BEAM_SZAS(I)
        ENDDO
      ENDIF
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Azimuth angles
!  ==============

!  Number of angles

      PAR_STR = 'Number of user-defined relative azimuth angles'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) N_USER_RELAZMS
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  check not exceeding dimensioned number

      IF ( N_USER_RELAZMS .GT. MAX_USER_RELAZMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = 'Number of relative azimuth angles > maximum dimension'
        ACTIONS(NM)  = 'Re-set input value or increase MAX_USER_RELAZMS dimension'
        STATUS       = VLIDORT_SERIOUS
        NMESSAGES    = NM
        GO TO 764
      ENDIF

!  Angles

      PAR_STR = 'User-defined relative azimuth angles (degrees)'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
        DO I = 1, N_USER_RELAZMS
          READ (FILUNIT,*,ERR=998) USER_RELAZMS(I)
        ENDDO
      ENDIF
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  User defined stream angles (should be positive)
!  ==========================

      IF ( DO_USER_STREAMS ) THEN

!  Number of angles

        PAR_STR = 'Number of user-defined viewing zenith angles'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) N_USER_STREAMS
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check dimension

        IF ( N_USER_STREAMS .GT. MAX_USER_STREAMS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of viewing zenith angles > maximum dimension'
          ACTIONS(NM)  = 'Re-set input value or increase MAX_USER_STREAMS dimension'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          GO TO 764
        ENDIF

!  Angles

        PAR_STR = 'User-defined viewing zenith angles (degrees)'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
          DO I = 1, N_USER_STREAMS
            READ (FILUNIT,*,ERR=998) USER_ANGLES(I)
          ENDDO
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      ENDIF

!  !@@ Continuation point for Skipping the Lattice-input angles

5667  continue

!  Surface stuff
!  =============

!  BRDF input
!  ----------

!  Basic flag

      PAR_STR = 'Do BRDF surface?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_BRDF_SURFACE
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Surface emission flag

      PAR_STR = 'Do surface emission?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SURFACE_EMISSION
      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Only if set

      IF ( DO_BRDF_SURFACE ) THEN

!  Basic BRDF inputs
!  -----------------

!  number of kernels

        PAR_STR = 'Number of BRDF kernels'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
              READ (FILUNIT,*,ERR=998) N_BRDF_KERNELS
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check Dimension

        IF ( N_BRDF_KERNELS .GT. MAX_BRDF_KERNELS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of BRDF Kernels > maximum dimension (=3)'
          ACTIONS(NM)  = 'Re-set input value or increase MAX_BRDF_KERNELS dimension'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          GO TO 764
        ENDIF

!  number of BRDF azimuth streams, check this value

        PAR_STR = 'Number of BRDF azimuth angles'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) NSTREAMS_BRDF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

        IF ( NSTREAMS_BRDF .GT. MAXSTREAMS_BRDF ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of  BRDF streams > maximum dimension'
          ACTIONS(NM)  = 'Re-set input value or increase MAXSTREAMS_BRDF dimension'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          GO TO 764
        ENDIF

!  Main kernel input

        PAR_STR = 'Kernel names, indices, amplitudes, # parameters, parameters'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
          DO I = 1, N_BRDF_KERNELS
            READ (FILUNIT,56,ERR=998) &
                BRDF_NAMES(I), WHICH_BRDF(I), BRDF_FACTORS(I), &
               N_BRDF_PARAMETERS(I),(BRDF_PARAMETERS(I,K),K=1,3)
          ENDDO
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
 56     FORMAT( A10, I2, F6.2, I2, 3F12.6 )

!  Check Kernel indices are within bounds. Check BRDF name is on accepted list

        DO K = 1, N_BRDF_KERNELS
          IF ( WHICH_BRDF(K).GT.MAXBRDF_IDX.OR.WHICH_BRDF(K).LE.0) THEN
            NM = NM + 1
            MESSAGES(NM) = 'Bad input: BRDF Index not on list of indices'
            ACTIONS(NM)  = 'Re-set input value: Look in VLIDORT_PARS for correct index'
            STATUS = VLIDORT_SERIOUS
            NMESSAGES = NM
            GO TO 764
          ELSE
            IF ( BRDF_NAMES(K).NE.BRDF_CHECK_NAMES(WHICH_BRDF(K)) ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: BRDF kernel name not one of accepted list'
              ACTIONS(NM)  = 'Re-set input value: Look in VLIDORT_PARS for correct name'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF
          ENDIF
        ENDDO

!  Set the Lambertian kernel flags

        DO I = 1, N_BRDF_KERNELS
          IF ( BRDF_NAMES(I) .EQ. 'Lambertian' ) THEN
            LAMBERTIAN_KERNEL_FLAG(I) = .true.
          ENDIF
        ENDDO

!  Shadowing input (for Cox-Munk types)

        DO I = 1, N_BRDF_KERNELS
         IF ( BRDF_NAMES(I) .EQ. 'Cox-Munk  ' .OR. &
              BRDF_NAMES(I) .EQ. 'GissCoxMnk' .OR. &
              BRDF_NAMES(I) .EQ. 'GCMcomplex' ) THEN
           PAR_STR = 'Do shadow effect for glitter kernels?'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
            READ (FILUNIT,*,ERR=998)DO_SHADOW_EFFECT
           ENDIF
          ENDIF
        ENDDO
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  !@@ Overall-Exact flag

        PAR_STR = 'Do Overall-Exact kernels?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
           READ (FILUNIT,*,ERR=998)DO_EXACT
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Exact only flag. Only if above is set (!@@)

        IF ( DO_EXACT ) THEN
          PAR_STR = 'Do Exact-only (no Fourier) kernels?'
          IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
             READ (FILUNIT,*,ERR=998)DO_EXACTONLY
          ENDIF
          CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
        ENDIF

!  Multiple reflectance correction (for Cox-Munk types)
!  ----------------------------------------------------

!  General flag

        DO I = 1, N_BRDF_KERNELS
         IF ( BRDF_NAMES(I) .EQ. 'Cox-Munk  ' .OR. &
              BRDF_NAMES(I) .EQ. 'GissCoxMnk' .OR. &
              BRDF_NAMES(I) .EQ. 'GCMcomplex' ) THEN
           PAR_STR = 'Do multiple reflectance for All glitter kernels?'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
            READ (FILUNIT,*,ERR=998)DO_MSRCORR
           ENDIF
         ENDIF
        ENDDO
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  Specific MSRCORR inputs

        IF ( DO_MSRCORR ) THEN
           PAR_STR = 'Do multiple reflectance for Exact-only glitter kernels?'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
            READ (FILUNIT,*,ERR=998)DO_MSRCORR_EXACTONLY
           ENDIF
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  MSRCORR scattering order

        IF ( DO_MSRCORR ) THEN
           PAR_STR = 'Multiple reflectance scattering order for glitter kernels'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR )) THEN
            READ (FILUNIT,*,ERR=998)MSRCORR_ORDER
           ENDIF
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  MSRCORR quadrature orders

        IF ( DO_MSRCORR ) THEN
           PAR_STR = 'Multiple reflectance scattering; Polar quadrature order'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR )) THEN
            READ (FILUNIT,*,ERR=998)MSRCORR_NMUQUAD
           ENDIF
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

        IF ( DO_MSRCORR ) THEN
           PAR_STR = 'Multiple reflectance scattering; Azimuth quadrature order'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR )) THEN
            READ (FILUNIT,*,ERR=998)MSRCORR_NPHIQUAD
           ENDIF
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  Check MSCORR dimensions

        IF ( DO_MSRCORR ) THEN
           IF ( MSRCORR_NMUQUAD .gt. max_msrs_muquad ) then
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: MSR polar quadrature No. > Dimensioning'
              ACTIONS(NM)  = 'Increase value of max_msrs_muquad in vlidort_pars'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
           IF ( MSRCORR_NPHIQUAD .gt. max_msrs_phiquad ) then
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: MSR azimuth quadrature No. > Dimensioning'
              ACTIONS(NM)  = 'Increase value of max_msrs_phiquad in vlidort_pars'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
        ENDIF

!  Check on MSRCORR order

        IF ( DO_MSRCORR ) THEN
           IF ( MSRCORR_ORDER .EQ.0 ) then
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: MSR is on, but scattering order = 0'
              ACTIONS(NM)  = 'Turn off MSRCORR flags and proceed with warning'
              DO_MSRCORR = .false. ; DO_MSRCORR_EXACTONLY = .false.
              STATUS = VLIDORT_WARNING
              NMESSAGES = NM
           ENDIF
        ENDIF

!  TEMPORARY LIMITATION TO MSR ORDER = 1
!        IF ( DO_MSRCORR ) THEN
!           IF ( MSRCORR_ORDER .GT.1 ) then
!              NM = NM + 1
!              MESSAGES(NM) = 'Bad input: MSR is on, but scattering order  > 1'
!              ACTIONS(NM)  = 'Temporary limitation; abort for now'
!              STATUS = VLIDORT_SERIOUS
!              NMESSAGES = NM
!              GO TO 764
!           ENDIF
!        ENDIF

!  White-Sky and Black-Sky Albedo scalings. New for Version 2.7
!  ============================================================

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

!  White-Sky inputs
!  ----------------

!  White-sky Albedo scaling

        PAR_STR = 'Do white-sky albedo scaling?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
           READ (FILUNIT,*,ERR=998)DO_WSA_SCALING
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  WSA value. This could be extracted from a data set.....

        IF ( DO_WSA_SCALING  ) THEN
           PAR_STR = 'White-sky albedo value'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
              READ (FILUNIT,*,ERR=998)WSA_VALUE
           ENDIF
           CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)
        ENDIF

!  Check WSA value

        IF ( DO_WSA_SCALING  ) THEN
           IF ( WSA_VALUE .le.zero .or. WSA_VALUE .gt. one ) then
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: White-sky-albedo value not in the range [0,1]'
              ACTIONS(NM)  = 'Fix the input'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
        ENDIF

!  Black-Sky inputs
!  ----------------

!  Black-sky Albedo scaling.

        PAR_STR = 'Do black-sky albedo scaling?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
           READ (FILUNIT,*,ERR=998)DO_BSA_SCALING
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)

!  Cannot have BSA and WSA together

        IF ( DO_BSA_SCALING .and. DO_WSA_SCALING ) THEN
           NM = NM + 1
           MESSAGES(NM) = 'Bad input: Cannot apply both Black-sky albedo and White-sky albedo scalings!'
           ACTIONS(NM)  = 'Make a choice of which one you want! '
           STATUS = VLIDORT_SERIOUS
           NMESSAGES = NM
           GOTO 764
        ENDIF

!  BSA value. This could be extracted from a data set.....
!    WARNING: ONLY ALLOWED ONE VALUE HERE...................

        IF ( DO_BSA_SCALING  ) THEN
           PAR_STR = 'Black-sky albedo value'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
              READ (FILUNIT,*,ERR=998)BSA_VALUE
           ENDIF
           CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)
        ENDIF

!  Check BSA value

        IF ( DO_BSA_SCALING  ) THEN
           IF ( BSA_VALUE .le.zero .or. BSA_VALUE .gt. one ) then
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: Black-sky-albedo value is not in the range [0,1]'
              ACTIONS(NM)  = 'Fix the input'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
        ENDIF

!  Check that Solar source flag is on for Black sky albedo

        IF ( DO_BSA_SCALING  ) THEN
           IF ( .not. DO_SOLAR_SOURCES ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: Cannot have Black-sky albedo if Solar_sources not turned on'
              ACTIONS(NM)  = 'Fix the input (turn on DO_SOLAR_SOURCES)'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
        ENDIF

!  Check that there is only one beam for Black sky albedo

        IF ( DO_BSA_SCALING  ) THEN
           IF ( NBEAMS.gt.1 ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: Cannot have Black-sky albedo with more than 1 solar angle'
              ACTIONS(NM)  = 'Fix the input (set NBEAMS = 1)'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
           ENDIF
        ENDIF

!  Linearized input
!  ----------------

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

!      WSA/BSA Jacobians, only if flag has been set
!       Just one surface WF (skip Kernel derivatives)
!       Options here are mutually exclusive (already checked)

        IF ( DO_WSA_SCALING  ) THEN
           PAR_STR = 'Do white-sky albedo Jacobian?'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
              READ (FILUNIT,*,ERR=998)DO_WSAVALUE_WF
           ENDIF
           CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)
           IF (DO_WSAVALUE_WF) THEN
              N_SURFACE_WFS  = 1 ; go to 675
           ENDIF
        ENDIF

        IF ( DO_BSA_SCALING  ) THEN
           PAR_STR = 'Do black-sky albedo Jacobian?'
           IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
              READ (FILUNIT,*,ERR=998)DO_BSAVALUE_WF
           ENDIF
           CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS)
           IF (DO_BSAVALUE_WF) THEN
              N_SURFACE_WFS  = 1 ; go to 675
           ENDIF
        ENDIF

!  Kernel Amplitude/parameter Jacobian inputs.
!  Not allowed linearized inputs with GCMCRI

        PAR_STR = 'Kernels, indices, # pars, Factor Jacobian flag, Par Jacobian flags'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
          DO I = 1, N_BRDF_KERNELS
            READ (FILUNIT,57,ERR=998) &
               DUM_NAME, DUM_INDEX,DUM_NPARS,DO_KERNEL_FACTOR_WFS(I), &
               (DO_KERNEL_PARAMS_WFS(I,J),J=1,3)

            IF ( DUM_NAME .EQ. 'GCMcomplex' ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'GCMcomplex BRDF Kernel cannot be linearized yet'
              ACTIONS(NM)  = 'Use GISSCoxMunk kernel instead'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF

            IF ( DUM_NAME .NE. BRDF_NAMES(I) ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Input BRDF Kernel name not same as earlier list'
              ACTIONS(NM)  = 'Jacobian inputs not consistent with Regular BRDF kernel inputs'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF

            IF ( DUM_INDEX .NE. WHICH_BRDF(I) ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Input BRDF Index name not same as earlier list'
              ACTIONS(NM)  = 'Check second occurence of BRDF kernel Index'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF

            IF ( DUM_NPARS .NE. N_BRDF_PARAMETERS(I) ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Input Number of BRDF parameters not same as earlier list'
              ACTIONS(NM)  = 'Check second occurence of N_BRDF_PARAMETERS'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF

!  Compute total number of pars

            IF ( DO_KERNEL_FACTOR_WFS(I) ) THEN
              N_KERNEL_FACTOR_WFS = N_KERNEL_FACTOR_WFS  + 1
            ENDIF
            DO J = 1, N_BRDF_PARAMETERS(I)
              IF ( DO_KERNEL_PARAMS_WFS(I,J) ) THEN
                N_KERNEL_PARAMS_WFS = N_KERNEL_PARAMS_WFS + 1
              ENDIF
            ENDDO
            DO_KPARAMS_DERIVS(I) = (N_KERNEL_PARAMS_WFS.GT.0)

          ENDDO
          N_SURFACE_WFS = N_KERNEL_FACTOR_WFS+N_KERNEL_PARAMS_WFS
        ENDIF

        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
 57     FORMAT( A10, I3, I2, 1X, L2, 2X, 3L2 )

!  Continuation point for avoiding Linearized Kernel/Factor inputs

675     continue

!  Check total number of BRDF weighting functions is not out of bounds

        IF ( N_SURFACE_WFS .GT. MAX_SURFACEWFS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of Surface WFs > maximum dimension'
          ACTIONS(NM)  = 'Re-set input value or increase MAX_SURFACEWFS dimension'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          GO TO 764
        ENDIF

!  Check Kernel indices are within bounds. Check BRDF name is on accepted list

        DO K = 1, N_BRDF_KERNELS
          IF ( WHICH_BRDF(K).GT.MAXBRDF_IDX.OR.WHICH_BRDF(K).LE.0) THEN
            NM = NM + 1
            MESSAGES(NM) = 'Bad input: BRDF Index not on list of indices'
            ACTIONS(NM)  = 'Re-set input value: Look in VLIDORT_PARS for correct index'
            STATUS = VLIDORT_SERIOUS
            NMESSAGES = NM
            GO TO 764
          ELSE
            IF ( BRDF_NAMES(K).NE.BRDF_CHECK_NAMES(WHICH_BRDF(K)) ) THEN
              NM = NM + 1
              MESSAGES(NM) = 'Bad input: BRDF kernel name not one of accepted list'
              ACTIONS(NM)  = 'Re-set input value: Look in VLIDORT_PARS for correct name'
              STATUS = VLIDORT_SERIOUS
              NMESSAGES = NM
              GO TO 764
            ENDIF
          ENDIF
        ENDDO

!  End BRDF surface clause

      ENDIF

!  Successful finish

      CLOSE(FILUNIT)

!mick fix
      NMESSAGES = NM

!  Copy Control inputs

      VBRDF_Sup_In%BS_DO_USER_STREAMS     = DO_USER_STREAMS
      VBRDF_Sup_In%BS_DO_BRDF_SURFACE     = DO_BRDF_SURFACE
      VBRDF_Sup_In%BS_DO_SURFACE_EMISSION = DO_SURFACE_EMISSION
      VBRDF_Sup_In%BS_DO_SOLAR_SOURCES    = DO_SOLAR_SOURCES   !@@
      VBRDF_Sup_In%BS_DO_USER_OBSGEOMS    = DO_USER_OBSGEOMS   !@@

!  Copy Geometry results

      VBRDF_Sup_In%BS_NSTOKES           = NSTOKES
      VBRDF_Sup_In%BS_NSTREAMS          = NSTREAMS
      VBRDF_Sup_In%BS_NBEAMS            = NBEAMS
      VBRDF_Sup_In%BS_BEAM_SZAS         = BEAM_SZAS
      VBRDF_Sup_In%BS_N_USER_RELAZMS    = N_USER_RELAZMS
      VBRDF_Sup_In%BS_USER_RELAZMS      = USER_RELAZMS
      VBRDF_Sup_In%BS_N_USER_STREAMS    = N_USER_STREAMS
      VBRDF_Sup_In%BS_USER_ANGLES_INPUT = USER_ANGLES
      VBRDF_Sup_In%BS_N_USER_OBSGEOMS   = N_USER_OBSGEOMS !@@
      VBRDF_Sup_In%BS_USER_OBSGEOMS     = USER_OBSGEOMS   !@@

!  Copy BRDF inputs

      VBRDF_Sup_In%BS_N_BRDF_KERNELS         = N_BRDF_KERNELS
      VBRDF_Sup_In%BS_BRDF_NAMES             = BRDF_NAMES
      VBRDF_Sup_In%BS_WHICH_BRDF             = WHICH_BRDF
      VBRDF_Sup_In%BS_N_BRDF_PARAMETERS      = N_BRDF_PARAMETERS
      VBRDF_Sup_In%BS_BRDF_PARAMETERS        = BRDF_PARAMETERS
      VBRDF_Sup_In%BS_LAMBERTIAN_KERNEL_FLAG = LAMBERTIAN_KERNEL_FLAG
      VBRDF_Sup_In%BS_BRDF_FACTORS           = BRDF_FACTORS
      VBRDF_Sup_In%BS_NSTREAMS_BRDF          = NSTREAMS_BRDF

      VBRDF_Sup_In%BS_DO_SHADOW_EFFECT       = DO_SHADOW_EFFECT
      VBRDF_Sup_In%BS_DO_EXACT               = DO_EXACT         !@@
      VBRDF_Sup_In%BS_DO_EXACTONLY           = DO_EXACTONLY

      VBRDF_Sup_In%BS_DO_GLITTER_MSRCORR           = DO_MSRCORR
      VBRDF_Sup_In%BS_DO_GLITTER_MSRCORR_EXACTONLY = DO_MSRCORR_EXACTONLY
      VBRDF_Sup_In%BS_GLITTER_MSRCORR_ORDER        = MSRCORR_ORDER
      VBRDF_Sup_In%BS_GLITTER_MSRCORR_NMUQUAD      = MSRCORR_NMUQUAD
      VBRDF_Sup_In%BS_GLITTER_MSRCORR_NPHIQUAD     = MSRCORR_NPHIQUAD

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      VBRDF_Sup_In%BS_DO_WSA_SCALING = DO_WSA_SCALING
      VBRDF_Sup_In%BS_DO_BSA_SCALING = DO_BSA_SCALING
      VBRDF_Sup_In%BS_WSA_VALUE      = WSA_VALUE
      VBRDF_Sup_In%BS_BSA_VALUE      = BSA_VALUE

!  Copy linearized BRDF inputs

      VBRDF_LinSup_In%BS_DO_KERNEL_FACTOR_WFS   = DO_KERNEL_FACTOR_WFS
      VBRDF_LinSup_In%BS_DO_KERNEL_PARAMS_WFS   = DO_KERNEL_PARAMS_WFS
      VBRDF_LinSup_In%BS_DO_KPARAMS_DERIVS      = DO_KPARAMS_DERIVS
      VBRDF_LinSup_In%BS_N_SURFACE_WFS          = N_SURFACE_WFS
      VBRDF_LinSup_In%BS_N_KERNEL_FACTOR_WFS    = N_KERNEL_FACTOR_WFS
      VBRDF_LinSup_In%BS_N_KERNEL_PARAMS_WFS    = N_KERNEL_PARAMS_WFS
      VBRDF_LinSup_In%BS_DO_WSAVALUE_WF         = DO_WSAVALUE_WF         ! New Version 2.7
      VBRDF_LinSup_In%BS_DO_BSAVALUE_WF         = DO_BSAVALUE_WF         ! New Version 2.7

!  Exception handling

      VBRDF_Sup_InputStatus%BS_STATUS_INPUTREAD = STATUS
      VBRDF_Sup_InputStatus%BS_NINPUTMESSAGES   = NMESSAGES
      VBRDF_Sup_InputStatus%BS_INPUTMESSAGES    = MESSAGES
      VBRDF_Sup_InputStatus%BS_INPUTACTIONS     = ACTIONS

!  Normal return

      RETURN

!  Open file error

300   CONTINUE
      STATUS = VLIDORT_SERIOUS
      NMESSAGES = NMESSAGES + 1
      MESSAGES(NMESSAGES) = 'openfile failure for '//trim(adjustl(FILNAM))
      ACTIONS(NMESSAGES)  = 'Find the Right input file!!'
      CLOSE(FILUNIT)
      GO TO 764

!  Line read error - abort immediately

998   CONTINUE
      STATUS = VLIDORT_SERIOUS
      NMESSAGES = NMESSAGES + 1
      MESSAGES(NMESSAGES) = 'read failure for '//trim(adjustl(PAR_STR))
      ACTIONS(NMESSAGES)  = 'Re-set: Entry is incorrect in input file'
      CLOSE(FILUNIT)

!  Final error copying

764   CONTINUE

      VBRDF_Sup_InputStatus%BS_STATUS_INPUTREAD = STATUS
      VBRDF_Sup_InputStatus%BS_NINPUTMESSAGES   = NMESSAGES
      VBRDF_Sup_InputStatus%BS_INPUTMESSAGES    = MESSAGES
      VBRDF_Sup_InputStatus%BS_INPUTACTIONS     = ACTIONS

!  Finish

      RETURN
      END SUBROUTINE VBRDF_LIN_INPUTMASTER

!

      SUBROUTINE VBRDF_LIN_MAINMASTER (  &
        DO_DEBUG_RESTORATION,   & ! Inputs
        NMOMENTS_INPUT,         & ! Inputs
        VBRDF_Sup_In,           & ! Inputs
        VBRDF_LinSup_In,        & ! Inputs
        VBRDF_Sup_Out,          & ! Outputs
        VBRDF_LinSup_Out,       & ! Outputs
        VBRDF_Sup_OutputStatus )  ! Output Status

!  Prepares the bidirectional reflectance functions necessary for VLIDORT.

!  Observational Geometry Inputs. Marked with !@@
!     Installed 31 december 2012. 
!       Observation-Geometry input control.       DO_USER_OBSGEOMS
!       Observation-Geometry input control.       N_USER_OBSGEOMS
!       User-defined Observation Geometry angles. USER_OBSGEOMS
!     Added solar_sources flag for better control (DO_SOLAR_SOURCES)
!     Added Overall-exact flag for better control (DO_EXACT)

!  Upgrade Version 2.7 for WSA/BSA implementation. Marked with !{2.7}

      USE VLIDORT_PARS

      USE vbrdf_sup_inputs_def
      USE vbrdf_linsup_inputs_def

      USE vbrdf_sup_outputs_def
      USE vbrdf_linsup_outputs_def

      USE vbrdf_sup_aux_m, only : BRDF_GAULEG,              &
                                  BRDF_QUADRATURE_Gaussian, &
                                  BRDF_QUADRATURE_Trapezoid

      USE vbrdf_sup_kernels_m
      USE vbrdf_linsup_kernels_m

      USE vbrdf_sup_routines_m
      USE vbrdf_linsup_routines_m

!  Implicit none

      IMPLICIT NONE

!  Inputs
!  ------

!  Debug flag for restoration

      LOGICAL, INTENT(IN) ::                 DO_DEBUG_RESTORATION

!  Input number of moments (only used for restoration debug)

      INTEGER, INTENT(IN) ::                 NMOMENTS_INPUT

!  Input structures
!  ----------------

      TYPE(VBRDF_Sup_Inputs)    , INTENT(IN)  :: VBRDF_Sup_In
      TYPE(VBRDF_LinSup_Inputs) , INTENT(IN)  :: VBRDF_LinSup_In

!  Output structures
!  -----------------

      TYPE(VBRDF_Sup_Outputs)   , INTENT(OUT) :: VBRDF_Sup_Out
      TYPE(VBRDF_LinSup_Outputs), INTENT(OUT) :: VBRDF_LinSup_Out

!  Exception handling introduced 02 April 2014 for Version 2.7

      TYPE(VBRDF_Output_Exception_Handling), INTENT(OUT) :: VBRDF_Sup_OutputStatus

!  VLIDORT local variables
!  ++++++++++++++++++++++

!  Input arguments
!  ===============

!  User stream Control

      LOGICAL ::          DO_USER_STREAMS

!  Surface emission

      LOGICAL ::          DO_SURFACE_EMISSION

!  number of Stokes components

      INTEGER ::          NSTOKES

!   Number and index-list of bidirectional functions

      INTEGER ::          N_BRDF_KERNELS
      INTEGER ::          WHICH_BRDF ( MAX_BRDF_KERNELS )

!  Parameters required for Kernel families

      INTEGER ::          N_BRDF_PARAMETERS ( MAX_BRDF_KERNELS )
      DOUBLE PRECISION :: BRDF_PARAMETERS ( MAX_BRDF_KERNELS, MAX_BRDF_PARAMETERS )

!  BRDF names

      CHARACTER (LEN=10) :: BRDF_NAMES ( MAX_BRDF_KERNELS )

!  Lambertian Surface control

      LOGICAL ::          LAMBERTIAN_KERNEL_FLAG ( MAX_BRDF_KERNELS )

!  Input kernel amplitude factors

      DOUBLE PRECISION :: BRDF_FACTORS ( MAX_BRDF_KERNELS )

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      LOGICAL   :: DO_WSA_SCALING
      LOGICAL   :: DO_BSA_SCALING
      REAL(fpk) :: WSA_VALUE, BSA_VALUE

!  Number of azimuth quadrature streams for BRDF

      INTEGER ::          NSTREAMS_BRDF

!  Shadowing effect flag (only for Cox-Munk type kernels)

      LOGICAL ::          DO_SHADOW_EFFECT

!   !@@ Solar sources + Observational Geometry flag !@@

      LOGICAL ::          DO_SOLAR_SOURCES
      LOGICAL ::          DO_USER_OBSGEOMS

!  Exact only flag (no Fourier term calculations)

      LOGICAL ::          DO_EXACT
      LOGICAL ::          DO_EXACTONLY

!  Multiple reflectance correction for Glitter kernels

      LOGICAL ::          DO_MSRCORR
      LOGICAL ::          DO_MSRCORR_EXACTONLY
      INTEGER ::          MSRCORR_ORDER
      INTEGER ::          N_MUQUAD, N_PHIQUAD

!   Flags for WF of bidirectional function parameters and factors

      LOGICAL ::          DO_KERNEL_FACTOR_WFS ( MAX_BRDF_KERNELS )
      LOGICAL ::          DO_KERNEL_PARAMS_WFS ( MAX_BRDF_KERNELS, MAX_BRDF_PARAMETERS )

!  derived quantity (tells you when to do BRDF derivatives)

      LOGICAL ::          DO_KPARAMS_DERIVS ( MAX_BRDF_KERNELS )

!  WSA and BSA scaling options. Weighting function flags
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      LOGICAL ::          DO_WSAVALUE_WF
      LOGICAL ::          DO_BSAVALUE_WF

!  number of surfaceweighting functions

      INTEGER ::          N_SURFACE_WFS
      INTEGER ::          N_KERNEL_FACTOR_WFS
      INTEGER ::          N_KERNEL_PARAMS_WFS

!  Local angle control

      INTEGER ::          NSTREAMS
      INTEGER ::          NBEAMS
      INTEGER ::          N_USER_STREAMS
      INTEGER ::          N_USER_RELAZMS

!  Local angles

      DOUBLE PRECISION :: BEAM_SZAS   (MAXBEAMS)
      DOUBLE PRECISION :: USER_RELAZMS(MAX_USER_RELAZMS)
      DOUBLE PRECISION :: USER_ANGLES (MAX_USER_STREAMS)

!  !@@ Local Observational Geometry control and angles

      INTEGER ::          N_USER_OBSGEOMS
      DOUBLE PRECISION :: USER_OBSGEOMS (MAX_USER_OBSGEOMS,3)

!  BRDF External functions
!  =======================

!  lambertian

!      EXTERNAL         LAMBERTIAN_VFUNCTION

!  Modis-type kernels

!      EXTERNAL         ROSSTHIN_VFUNCTION
!      EXTERNAL         ROSSTHICK_VFUNCTION
!      EXTERNAL         LISPARSE_VFUNCTION
!      EXTERNAL         LIDENSE_VFUNCTION
!      EXTERNAL         HAPKE_VFUNCTION
!      EXTERNAL         ROUJEAN_VFUNCTION
!      EXTERNAL         RAHMAN_VFUNCTION

!  Cox-munk types

!      EXTERNAL         COXMUNK_VFUNCTION
!      EXTERNAL         COXMUNK_VFUNCTION_DB
!      EXTERNAL         GISSCOXMUNK_VFUNCTION
!      EXTERNAL         GISSCOXMUNK_VFUNCTION_DB

!  GCM CRI is not an external call
!      EXTERNAL         GCMCRI_VFUNCTION
!      EXTERNAL         GCMCRI_VFUNCTION_DB

!  new for Version 2.4R, introduced 30 April 2009, 6 May 2009
!    2009 function is final Kernel supplied by Breon, May 5 2009.

!      EXTERNAL         BPDF2009_VFUNCTION

!  Local BRDF functions
!  ====================

!  at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: BRDFUNC &
          ( MAXSTOKES_SQ, MAXSTREAMS, MAXSTREAMS, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: BRDFUNC_0 &
          ( MAXSTOKES_SQ, MAXSTREAMS, MAXBEAMS, MAXSTREAMS_BRDF )

!  at user-defined stream directions

      DOUBLE PRECISION :: USER_BRDFUNC &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAXSTREAMS, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: USER_BRDFUNC_0 &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAXBEAMS, MAXSTREAMS_BRDF )

!  DB Kernel values

      DOUBLE PRECISION :: DBKERNEL_BRDFUNC &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAX_USER_RELAZMS, MAXBEAMS )

!  Values for Emissivity

      DOUBLE PRECISION :: EBRDFUNC &
          ( MAXSTOKES_SQ, MAXSTREAMS, MAXSTHALF_BRDF, MAXSTREAMS_BRDF)
      DOUBLE PRECISION :: USER_EBRDFUNC &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAXSTHALF_BRDF, MAXSTREAMS_BRDF)

!  Values for WSA/BSA scaling options. New, Version 2.7

      DOUBLE PRECISION :: SCALING_BRDFUNC &
          ( MAXSTREAMS_SCALING, MAXSTREAMS_SCALING, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: SCALING_BRDFUNC_0 &
          ( MAXSTREAMS_SCALING, MAXSTREAMS_BRDF )

!  Local Linearizations of BRDF functions (parameter derivatives)
!  ==============================================================

!  at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: D_BRDFUNC   ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                                     MAXSTREAMS, MAXSTREAMS, &
                                     MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: D_BRDFUNC_0 ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                                     MAXSTREAMS, MAXBEAMS, &
                                     MAXSTREAMS_BRDF )

!  at user-defined stream directions

      DOUBLE PRECISION :: D_USER_BRDFUNC &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAXSTREAMS, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: D_USER_BRDFUNC_0 &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAXBEAMS, MAXSTREAMS_BRDF )

!  Linearized Exact DB values

      DOUBLE PRECISION :: D_DBKERNEL_BRDFUNC &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAX_USER_RELAZMS, MAXBEAMS )

!  Values for Emissivity

      DOUBLE PRECISION :: D_EBRDFUNC &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, MAXSTREAMS, &
                       MAXSTHALF_BRDF, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: D_USER_EBRDFUNC &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAXSTHALF_BRDF, &
                       MAXSTREAMS_BRDF )

!  Values for WSA/BSA scaling options. New, Version 2.7

      DOUBLE PRECISION :: D_SCALING_BRDFUNC &
          ( MAX_BRDF_PARAMETERS, MAXSTREAMS_SCALING, MAXSTREAMS_SCALING, MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: D_SCALING_BRDFUNC_0 &
          ( MAX_BRDF_PARAMETERS, MAXSTREAMS_SCALING, MAXSTREAMS_BRDF )

!  Local angles, and cosine/sines/weights
!  ======================================

!  Azimuths

      DOUBLE PRECISION :: PHIANG(MAX_USER_RELAZMS)
      DOUBLE PRECISION :: COSPHI(MAX_USER_RELAZMS)
      DOUBLE PRECISION :: SINPHI(MAX_USER_RELAZMS)

!  SZAs

      DOUBLE PRECISION :: SZASURCOS(MAXBEAMS)
      DOUBLE PRECISION :: SZASURSIN(MAXBEAMS)

!  Discrete ordinates

      DOUBLE PRECISION :: QUAD_STREAMS(MAXSTREAMS)
      DOUBLE PRECISION :: QUAD_WEIGHTS(MAXSTREAMS)
      DOUBLE PRECISION :: QUAD_SINES  (MAXSTREAMS)

!  Viewing zenith streams

      DOUBLE PRECISION :: USER_STREAMS(MAX_USER_STREAMS)
      DOUBLE PRECISION :: USER_SINES  (MAX_USER_STREAMS)

!  BRDF azimuth quadrature streams

      INTEGER ::          NBRDF_HALF
      DOUBLE PRECISION :: X_BRDF  ( MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: CX_BRDF ( MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: SX_BRDF ( MAXSTREAMS_BRDF )
      DOUBLE PRECISION :: A_BRDF  ( MAXSTREAMS_BRDF )

!  BRDF azimuth quadrature streams For emission calculations

      DOUBLE PRECISION :: BAX_BRDF ( MAXSTHALF_BRDF )
      DOUBLE PRECISION :: CXE_BRDF ( MAXSTHALF_BRDF )
      DOUBLE PRECISION :: SXE_BRDF ( MAXSTHALF_BRDF )

!  Azimuth factors

      DOUBLE PRECISION :: BRDF_COSAZMFAC(MAXSTREAMS_BRDF)
      DOUBLE PRECISION :: BRDF_SINAZMFAC(MAXSTREAMS_BRDF)

!  Local arrays for MSR quadrature

      DOUBLE PRECISION :: X_MUQUAD (max_msrs_muquad)
      DOUBLE PRECISION :: W_MUQUAD (max_msrs_muquad)
      DOUBLE PRECISION :: SX_MUQUAD (max_msrs_muquad)
      DOUBLE PRECISION :: WXX_MUQUAD (max_msrs_muquad)

      DOUBLE PRECISION :: X_PHIQUAD (max_msrs_phiquad)
      DOUBLE PRECISION :: W_PHIQUAD (max_msrs_phiquad)

!  Local kernel Fourier components
!  ===============================

!  at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: LOCAL_BRDF_F &
          ( MAXSTOKES_SQ, MAXSTREAMS, MAXSTREAMS )
      DOUBLE PRECISION :: LOCAL_BRDF_F_0 &
          ( MAXSTOKES_SQ, MAXSTREAMS, MAXBEAMS   )

!  at user-defined stream directions

      DOUBLE PRECISION :: LOCAL_USER_BRDF_F &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAXSTREAMS )
      DOUBLE PRECISION :: LOCAL_USER_BRDF_F_0 &
          ( MAXSTOKES_SQ, MAX_USER_STREAMS, MAXBEAMS   )

!  emissivities

      DOUBLE PRECISION :: LOCAL_EMISSIVITY ( MAXSTOKES, MAXSTREAMS )
      DOUBLE PRECISION :: LOCAL_USER_EMISSIVITY ( MAXSTOKES, MAX_USER_STREAMS )

!  WSA/BSA scaling componnets, at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: SCALING_BRDF_F   ( MAXSTREAMS_SCALING, MAXSTREAMS_SCALING )
      DOUBLE PRECISION :: SCALING_BRDF_F_0 ( MAXSTREAMS_SCALING   )

!  Local Derivative-kernel Fourier components
!  ==========================================

!  at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: D_LOCAL_BRDF_F &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, MAXSTREAMS, &
                       MAXSTREAMS )
      DOUBLE PRECISION :: D_LOCAL_BRDF_F_0 &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, MAXSTREAMS, &
                       MAXBEAMS )

!  at user-defined stream directions

      DOUBLE PRECISION :: D_LOCAL_USER_BRDF_F &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAXSTREAMS )
      DOUBLE PRECISION :: D_LOCAL_USER_BRDF_F_0 &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES_SQ, &
                       MAX_USER_STREAMS, MAXBEAMS )

!  emissivities

      DOUBLE PRECISION :: D_LOCAL_EMISSIVITY &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES, MAXSTREAMS )
      DOUBLE PRECISION :: D_LOCAL_USER_EMISSIVITY &
                     ( MAX_BRDF_PARAMETERS, MAXSTOKES, &
                       MAX_USER_STREAMS )

!  WSA/BSA scaling componnets, at quadrature (discrete ordinate) angles

      DOUBLE PRECISION :: D_SCALING_BRDF_F   ( MAX_BRDF_PARAMETERS, MAXSTREAMS_SCALING, MAXSTREAMS_SCALING )
      DOUBLE PRECISION :: D_SCALING_BRDF_F_0 ( MAX_BRDF_PARAMETERS, MAXSTREAMS_SCALING   )

!  Exception handling. New code, 02 April 2014. Version 2.7
!     Message Length should be at least 120 Characters

      INTEGER ::             STATUS
      INTEGER ::             NMESSAGES
      CHARACTER (LEN=120) :: MESSAGES ( 0:MAX_MESSAGES )

!  Other local variables
!  =====================

!  Discrete ordinates (local, for Albedo scaling). Version 2.7.

      INTEGER            :: SCALING_NSTREAMS
      DOUBLE PRECISION   :: SCALING_QUAD_STREAMS(MAXSTREAMS_SCALING)
      DOUBLE PRECISION   :: SCALING_QUAD_WEIGHTS(MAXSTREAMS_SCALING)
      DOUBLE PRECISION   :: SCALING_QUAD_SINES  (MAXSTREAMS_SCALING)
      DOUBLE PRECISION   :: SCALING_QUAD_STRMWTS(MAXSTREAMS_SCALING)

!  White-sky and Black-sky albedos. Version 2.7.

      LOGICAL          :: DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSAorBSA_Jacobian
      DOUBLE PRECISION :: WSA_CALC (MAX_BRDF_KERNELS), TOTAL_WSA_CALC, D_TOTAL_WSA_CALC (MAX_SURFACEWFS )
      DOUBLE PRECISION :: BSA_CALC (MAX_BRDF_KERNELS), TOTAL_BSA_CALC, D_TOTAL_BSA_CALC (MAX_SURFACEWFS )

!  help

      INTEGER          :: WOFFSET ( MAX_BRDF_KERNELS)
      INTEGER          :: K, B, I, I1, J, IB, UI, UM, IA, M, O1, Q, P, W, WBSA
      INTEGER          :: BRDF_NPARS, NMOMENTS, NSTOKESSQ, N_phiquad_HALF
      DOUBLE PRECISION :: PARS ( MAX_BRDF_PARAMETERS )
      LOGICAL          :: DERIVS ( MAX_BRDF_PARAMETERS )
      DOUBLE PRECISION :: MUX, DELFAC, HELP_A, SUM, ARGUMENT, XM, FF
      LOGICAL          :: ADD_FOURIER, LOCAL_MSR
      DOUBLE PRECISION :: T0, T00, T1, T2, SCALING_0, SCALING, D_TOTAL_ALBEDO_CALC (MAX_SURFACEWFS)

      INTEGER, PARAMETER :: LUM = 1   !@@
      INTEGER, PARAMETER :: LUA = 1   !@@

!  Default, use Gaussian quadrature

      LOGICAL, PARAMETER :: DO_BRDFQUAD_GAUSSIAN = .true.

!  Local check of Albedo

      LOGICAL, PARAMETER :: DO_CHECK_ALBEDO = .true.

!  Initialize Exception handling
!  -----------------------------

      STATUS = VLIDORT_SUCCESS
      MESSAGES(1:MAX_MESSAGES) = ' '
      NMESSAGES       = 0
      MESSAGES(0)     = 'Successful Execution of VLIDORT BRDF Sup Master'

!  Copy from input structure
!  -------------------------

!  Copy Control inputs

      DO_USER_STREAMS     = VBRDF_Sup_In%BS_DO_USER_STREAMS
      !DO_BRDF_SURFACE     = VBRDF_Sup_In%BS_DO_BRDF_SURFACE
      DO_SURFACE_EMISSION = VBRDF_Sup_In%BS_DO_SURFACE_EMISSION

!  Set number of stokes elements and streams

      NSTOKES  = VBRDF_Sup_In%BS_NSTOKES
      NSTREAMS = VBRDF_Sup_In%BS_NSTREAMS

!  Copy Geometry results

!  !@@ New lines

      DO_SOLAR_SOURCES = VBRDF_Sup_In%BS_DO_SOLAR_SOURCES
      DO_USER_OBSGEOMS = VBRDF_Sup_In%BS_DO_USER_OBSGEOMS

!   !@@ Observational Geometry + Solar sources Optionalities
!   !@@ Either set from User Observational Geometry
!          Or Copy from Usual lattice input

      IF ( DO_USER_OBSGEOMS ) THEN
        N_USER_OBSGEOMS = VBRDF_Sup_In%BS_N_USER_OBSGEOMS
        USER_OBSGEOMS   = VBRDF_Sup_In%BS_USER_OBSGEOMS
        IF ( DO_SOLAR_SOURCES ) THEN
          NBEAMS          = N_USER_OBSGEOMS
          N_USER_STREAMS  = N_USER_OBSGEOMS
          N_USER_RELAZMS  = N_USER_OBSGEOMS
          BEAM_SZAS   (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,1)
          USER_ANGLES (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,2)
          USER_RELAZMS(1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,3)
        ELSE
          NBEAMS         = 1 ; BEAM_SZAS      = ZERO
          N_USER_RELAZMS = 1 ; USER_RELAZMS   = ZERO
          N_USER_STREAMS = N_USER_OBSGEOMS
          USER_ANGLES(1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,2)
        ENDIF
      ELSE
        IF ( DO_SOLAR_SOURCES ) THEN
          NBEAMS         = VBRDF_Sup_In%BS_NBEAMS
          BEAM_SZAS      = VBRDF_Sup_In%BS_BEAM_SZAS
          N_USER_RELAZMS = VBRDF_Sup_In%BS_N_USER_RELAZMS
          USER_RELAZMS   = VBRDF_Sup_In%BS_USER_RELAZMS
          N_USER_STREAMS = VBRDF_Sup_In%BS_N_USER_STREAMS
          USER_ANGLES    = VBRDF_Sup_In%BS_USER_ANGLES_INPUT
        ELSE
          NBEAMS         = 1 ; BEAM_SZAS      = ZERO
          N_USER_RELAZMS = 1 ; USER_RELAZMS   = ZERO
          N_USER_STREAMS    = VBRDF_Sup_In%BS_N_USER_STREAMS
          USER_ANGLES = VBRDF_Sup_In%BS_USER_ANGLES_INPUT
        ENDIF
      ENDIF

!  Copy BRDF inputs

      N_BRDF_KERNELS         = VBRDF_Sup_In%BS_N_BRDF_KERNELS
      BRDF_NAMES             = VBRDF_Sup_In%BS_BRDF_NAMES
      WHICH_BRDF             = VBRDF_Sup_In%BS_WHICH_BRDF
      N_BRDF_PARAMETERS      = VBRDF_Sup_In%BS_N_BRDF_PARAMETERS
      BRDF_PARAMETERS        = VBRDF_Sup_In%BS_BRDF_PARAMETERS
      LAMBERTIAN_KERNEL_FLAG = VBRDF_Sup_In%BS_LAMBERTIAN_KERNEL_FLAG
      BRDF_FACTORS           = VBRDF_Sup_In%BS_BRDF_FACTORS
      NSTREAMS_BRDF          = VBRDF_Sup_In%BS_NSTREAMS_BRDF
      DO_SHADOW_EFFECT       = VBRDF_Sup_In%BS_DO_SHADOW_EFFECT
      DO_EXACT               = VBRDF_Sup_In%BS_DO_EXACT          !@@
      DO_EXACTONLY           = VBRDF_Sup_In%BS_DO_EXACTONLY

!  WSA and BSA scaling options.
!   Revised, 14-15 April 2014, first introduced 02 April 2014, Version 2.7
!      WSA = White-sky albedo. BSA = Black-sky albedo.

      DO_WSA_SCALING      = VBRDF_Sup_In%BS_DO_WSA_SCALING
      DO_BSA_SCALING      = VBRDF_Sup_In%BS_DO_BSA_SCALING
      WSA_VALUE           = VBRDF_Sup_In%BS_WSA_VALUE
      BSA_VALUE           = VBRDF_Sup_In%BS_BSA_VALUE

!  Local flags

      DO_LOCAL_WSA = DO_WSA_SCALING .or.  DO_CHECK_ALBEDO
      DO_LOCAL_BSA = DO_BSA_SCALING .and. DO_SOLAR_SOURCES

!  Copy linearized BRDF inputs

      DO_KERNEL_FACTOR_WFS   = VBRDF_LinSup_In%BS_DO_KERNEL_FACTOR_WFS
      DO_KERNEL_PARAMS_WFS   = VBRDF_LinSup_In%BS_DO_KERNEL_PARAMS_WFS
      DO_KPARAMS_DERIVS      = VBRDF_LinSup_In%BS_DO_KPARAMS_DERIVS
      N_SURFACE_WFS          = VBRDF_LinSup_In%BS_N_SURFACE_WFS
      N_KERNEL_FACTOR_WFS    = VBRDF_LinSup_In%BS_N_KERNEL_FACTOR_WFS
      N_KERNEL_PARAMS_WFS    = VBRDF_LinSup_In%BS_N_KERNEL_PARAMS_WFS
      DO_WSAVALUE_WF         = VBRDF_LinSup_In%BS_DO_WSAVALUE_WF           ! New, Version 2.7
      DO_BSAVALUE_WF         = VBRDF_LinSup_In%BS_DO_BSAVALUE_WF           ! New, Version 2.7

!  Local flag

      do_WSAorBSA_Jacobian = do_WSAVALUE_WF .or. do_BSAVALUE_WF

!  Copy MSR inputs

      DO_MSRCORR             = VBRDF_Sup_In%BS_DO_GLITTER_MSRCORR
      DO_MSRCORR_EXACTONLY   = VBRDF_Sup_In%BS_DO_GLITTER_MSRCORR_EXACTONLY
      MSRCORR_ORDER          = VBRDF_Sup_In%BS_GLITTER_MSRCORR_ORDER
      N_MUQUAD               = VBRDF_Sup_In%BS_GLITTER_MSRCORR_NMUQUAD
      N_PHIQUAD              = VBRDF_Sup_In%BS_GLITTER_MSRCORR_NPHIQUAD

!  Main code
!  ---------

!  Set up Quadrature streams for output
!    QUAD_STRMWTS dropped for Version 2.7 (now redefined for local WSA/BSA scaling)

      CALL BRDF_GAULEG ( 0.0d0, 1.0d0, QUAD_STREAMS, QUAD_WEIGHTS, NSTREAMS )
      DO I = 1, NSTREAMS
        QUAD_SINES(I) = DSQRT(1.0d0-QUAD_STREAMS(I)*QUAD_STREAMS(I))
      enddo

!  Set up Quadrature streams for WSA/BSA Scaling. New code, Version 2.7

      IF ( DO_LOCAL_WSA .or. DO_LOCAL_BSA ) THEN
         SCALING_NSTREAMS = MAXSTREAMS_SCALING
         CALL BRDF_GAULEG ( 0.0d0, 1.0d0, SCALING_QUAD_STREAMS, SCALING_QUAD_WEIGHTS, SCALING_NSTREAMS )
         DO I = 1, SCALING_NSTREAMS
            SCALING_QUAD_SINES(I)   = SQRT(1.0d0-SCALING_QUAD_STREAMS(I)*SCALING_QUAD_STREAMS(I))
            SCALING_QUAD_STRMWTS(I) = SCALING_QUAD_STREAMS(I) * SCALING_QUAD_WEIGHTS(I)
         enddo
      ENDIF

!  Number of Stokes components squared
!    ** Bookkeeping for surface kernel Cox-Munk types
!    ** Only the Giss CoxMunk kernel is vectorized (as of 19 January 2009)

!  Rob Fix, 14 March 2014. NSTOKESSQ > 1 for BPDF
!    ** Now, the BPDF 2009 kernel is vectorized

!   Additional code for complex RI Giss Cox-Munk, 15 march 2010.
!     3 parameters are PARS(1) = sigma_sq
!                      PARS(2) = Real (RI)
!                      PARS(3) = Imag (RI)

      NSTOKESSQ  = 1
      DO K = 1, N_BRDF_KERNELS
         IF ( BRDF_NAMES(K) .EQ. 'Cox-Munk  ' .OR. &
              BRDF_NAMES(K) .EQ. 'GissCoxMnk' ) THEN
            N_BRDF_PARAMETERS(K) = 3
            IF ( DO_SHADOW_EFFECT ) THEN
              BRDF_PARAMETERS(K,3) = ONE
            ELSE
              BRDF_PARAMETERS(K,3) = ZERO
            ENDIF
         ELSE IF ( BRDF_NAMES(K) .EQ. 'GCMcomplex' ) THEN
            N_BRDF_PARAMETERS(K) = 3
         ENDIF
          IF ( BRDF_NAMES(K) .EQ. 'GissCoxMnk'  .OR. &
               BRDF_NAMES(K) .EQ. 'GCMcomplex'  .OR. &
               BRDF_NAMES(K) .EQ. 'BPDF2009  ' ) THEN
            NSTOKESSQ = NSTOKES * NSTOKES
         ENDIF
      ENDDO

!  Number of Fourier components to calculate

      IF ( DO_DEBUG_RESTORATION ) THEN
        NMOMENTS = NMOMENTS_INPUT
      ELSE
        NMOMENTS = 2 * NSTREAMS - 1
      ENDIF

!  Half number of moments

      NBRDF_HALF = NSTREAMS_BRDF / 2

!  Usable solar beams. !@@ Optionality, added 12/31/12
!    Warning, this should be the BOA angle. OK for the non-refractive case

      IF ( DO_SOLAR_SOURCES ) THEN
        DO IB = 1, NBEAMS
          MUX =  COS(BEAM_SZAS(IB)*DEG_TO_RAD)
          SZASURCOS(IB) = MUX
          SZASURSIN(IB) = SQRT(1.0D0-MUX*MUX)
        ENDDO
      ELSE
        SZASURCOS = 0.0D0 ; SZASURSIN = 0.0D0
      ENDIF

!  Viewing angles

      DO UM = 1, N_USER_STREAMS
        USER_STREAMS(UM) = COS(USER_ANGLES(UM)*DEG_TO_RAD)
        USER_SINES(UM)   = SQRT(ONE-USER_STREAMS(UM)*USER_STREAMS(UM))
      ENDDO

! Optionality, added 12/31/12

      IF ( DO_EXACT.and.DO_SOLAR_SOURCES ) THEN
        DO IA = 1, N_USER_RELAZMS
          PHIANG(IA) = USER_RELAZMS(IA)*DEG_TO_RAD
          COSPHI(IA) = COS(PHIANG(IA))
          SINPHI(IA) = SIN(PHIANG(IA))
        ENDDO
      ENDIF

!  BRDF quadrature
!  ---------------

!  Save these quantities for efficient coding

      IF ( DO_BRDFQUAD_GAUSSIAN ) then
        CALL BRDF_QUADRATURE_Gaussian &
           ( DO_SURFACE_EMISSION, NSTREAMS_BRDF, NBRDF_HALF, &
             X_BRDF, CX_BRDF, SX_BRDF, A_BRDF, &
             BAX_BRDF, CXE_BRDF, SXE_BRDF )
      ELSE
        CALL BRDF_QUADRATURE_Trapezoid &
           ( DO_SURFACE_EMISSION, NSTREAMS_BRDF, NBRDF_HALF, &
             X_BRDF, CX_BRDF, SX_BRDF, A_BRDF, &
             BAX_BRDF, CXE_BRDF, SXE_BRDF )
      ENDIF

!  Number of weighting functions, and offset
!    * Offset not required for WSA/BSA Jacobians. New code Version 2.7
!    * Exception handling introduced Version 2.7

      WOFFSET = 0
      IF ( .not. DO_BSAVALUE_WF .and. .not. DO_WSAVALUE_WF ) then
         W = 0 ;  WOFFSET(1) = 0
         DO K = 1, N_BRDF_KERNELS
            IF ( DO_KERNEL_FACTOR_WFS(K) ) W = W + 1
            DO P = 1, N_BRDF_PARAMETERS(K)
               IF ( DO_KERNEL_PARAMS_WFS(K,P) ) W = W + 1
            ENDDO
            IF ( K.LT.N_BRDF_KERNELS ) WOFFSET(K+1) = W
         ENDDO
         N_SURFACE_WFS = N_KERNEL_FACTOR_WFS + N_KERNEL_PARAMS_WFS
         IF ( W .ne. N_SURFACE_WFS ) then
            NMESSAGES = NMESSAGES + 1
            MESSAGES(NMESSAGES) = 'Fatal - Bookkeeping Incorrect for Kernel factor/parameter Jacobians'
            STATUS = VLIDORT_SERIOUS
            GO TO 899
         ENDIF
      ENDIF

!  Set up the MSR points
!  ---------------------

!  Air to water, Polar quadrature

      if ( DO_MSRCORR  ) THEN
         CALL brdf_gauleg ( ZERO, ONE, X_muquad, W_muquad, n_muquad )
         DO I = 1, N_MUQUAD
            XM = X_MUQUAD(I)
            SX_MUQUAD(I) = DSQRT(ONE-XM*XM)
            WXX_MUQUAD(I) = XM * XM * W_MUQUAD(I)
         ENDDO
      endif

!  Azimuth quadrature

      if ( DO_MSRCORR  ) THEN
         N_phiquad_HALF = N_PHIQUAD / 2
         CALL brdf_gauleg ( ZERO, ONE, X_PHIQUAD, W_PHIQUAD, N_PHIQUAD_HALF )
         DO I = 1, N_PHIQUAD_HALF
           I1 = I + N_PHIQUAD_HALF
           X_PHIQUAD(I1) = - X_PHIQUAD(I)
           W_PHIQUAD(I1) =   W_PHIQUAD(I)
         ENDDO
         DO I = 1, N_PHIQUAD
            X_PHIQUAD(I)  = PIE * X_PHIQUAD(I)
         ENDDO
      ENDIF

!  Initialise ALL outputs
!  ----------------------

!  Zero Exact Direct Beam BRDF

      VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC = ZERO

!  Zero the BRDF Fourier components

      VBRDF_Sup_Out%BS_BRDF_F_0 = ZERO
      VBRDF_Sup_Out%BS_BRDF_F   = ZERO
      VBRDF_Sup_Out%BS_USER_BRDF_F_0 = ZERO
      VBRDF_Sup_Out%BS_USER_BRDF_F   = ZERO

!  Initialize surface emissivity
!    Set to zero if you are using Albedo Scaling

      if ( do_wsa_scaling .or. do_bsa_scaling ) then
         VBRDF_Sup_Out%BS_EMISSIVITY      = ZERO
         VBRDF_Sup_Out%BS_USER_EMISSIVITY = ZERO
      else
         VBRDF_Sup_Out%BS_EMISSIVITY      = ONE
         VBRDF_Sup_Out%BS_USER_EMISSIVITY = ONE
      endif

!  initialize linearized quantities

      VBRDF_LinSup_Out%BS_LS_BRDF_F_0      = ZERO
      VBRDF_LinSup_Out%BS_LS_BRDF_F        = ZERO
      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0 = ZERO
      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F   = ZERO

      VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC = ZERO

      VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY = ZERO
      VBRDF_LinSup_Out%BS_LS_EMISSIVITY      = ZERO

!  Initialize WSA/BSA albedos

      WSA_CALC = zero ; TOTAL_WSA_CALC = zero ; D_TOTAL_WSA_CALC = zero
      BSA_CALC = zero ; TOTAL_BSA_CALC = zero ; D_TOTAL_BSA_CALC = zero

!  Fill BRDF arrays
!  ----------------

      DO K = 1, N_BRDF_KERNELS

!  Copy parameter variables into local quantities

        PARS = zero ; DERIVS = .false.
        BRDF_NPARS = N_BRDF_PARAMETERS(K)
        DO B = 1, MAX_BRDF_PARAMETERS
          PARS(B) = BRDF_PARAMETERS(K,B)
        ENDDO
        IF ( DO_KPARAMS_DERIVS(K) ) THEN
          DO P = 1, MAX_BRDF_PARAMETERS
            DERIVS(P) = DO_KERNEL_PARAMS_WFS(K,P)
          ENDDO
        ENDIF

!  Local MSRCORR flag

        LOCAL_MSR = .false.
        IF ( WHICH_BRDF(K) .EQ. COXMUNK_IDX     .or. &
             WHICH_BRDF(K) .EQ. GISSCOXMUNK_IDX .or. &
             WHICH_BRDF(K) .EQ. GISSCOXMUNK_CRI_IDX ) THEN
           LOCAL_MSR = DO_MSRCORR
        ENDIF

!  Lambertian kernel, (0 free parameters)

        IF ( WHICH_BRDF(K) .EQ. LAMBERTIAN_IDX ) THEN
          CALL VBRDF_MAKER &
             ( LAMBERTIAN_VFUNCTION, LAMBERTIAN_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
        ENDIF

!  Ross thin kernel, (0 free parameters)

        IF ( WHICH_BRDF(K) .EQ. ROSSTHIN_IDX ) THEN
          CALL VBRDF_MAKER &
             ( ROSSTHIN_VFUNCTION, ROSSTHIN_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
        ENDIF

!  Ross thick kernel, (0 free parameters)

        IF ( WHICH_BRDF(K) .EQ. ROSSTHICK_IDX ) THEN
          CALL VBRDF_MAKER &
             ( ROSSTHICK_VFUNCTION, ROSSTHICK_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
        ENDIF

!  Li Sparse kernel; 2 free parameters

        IF ( WHICH_BRDF(K) .EQ. LISPARSE_IDX ) THEN
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( LISPARSE_VFUNCTION_PLUS, LISPARSE_VFUNCTION_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
          ELSE
            CALL VBRDF_MAKER &
             ( LISPARSE_VFUNCTION, LISPARSE_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  Li Dense kernel; 2 free parameters

        IF ( WHICH_BRDF(K) .EQ. LIDENSE_IDX ) THEN
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( LIDENSE_VFUNCTION_PLUS, LIDENSE_VFUNCTION_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
          ELSE
            CALL VBRDF_MAKER &
             ( LIDENSE_VFUNCTION, LIDENSE_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  Hapke kernel (3 free parameters)

        IF ( WHICH_BRDF(K) .EQ. HAPKE_IDX ) THEN
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( HAPKE_VFUNCTION_PLUS, HAPKE_VFUNCTION_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
          ELSE
            CALL VBRDF_MAKER &
             ( HAPKE_VFUNCTION, HAPKE_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  Roujean kernel (0 free parameters)

        IF ( WHICH_BRDF(K) .EQ. ROUJEAN_IDX ) THEN
          CALL VBRDF_MAKER &
             ( ROUJEAN_VFUNCTION, ROUJEAN_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
        ENDIF

!  Rahman kernel (3 free parameters)

        IF ( WHICH_BRDF(K) .EQ. RAHMAN_IDX ) THEN
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( RAHMAN_VFUNCTION_PLUS, RAHMAN_VFUNCTION_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
          ELSE
            CALL VBRDF_MAKER &
             ( RAHMAN_VFUNCTION, RAHMAN_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  Scalar-only original Cox-Munk kernel: (2 free parameters, Shadow = Th
!    Distinguish between MS case.....

        IF ( WHICH_BRDF(K) .EQ. COXMUNK_IDX ) THEN
          IF ( DO_SHADOW_EFFECT ) PARS(3) = 1.0d0
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( COXMUNK_VFUNCTION_PLUS, COXMUNK_VFUNCTION_DB_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
         ELSE
           CALL VBRDF_MAKER &
             ( COXMUNK_VFUNCTION, COXMUNK_VFUNCTION_DB, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  GISS Vector Cox-Munk kernel: (2 free parameters, Shadow = Third). Rea
!    Distinguish between MS case.....

        IF ( WHICH_BRDF(K) .EQ. GISSCOXMUNK_IDX ) THEN
          IF ( DO_SHADOW_EFFECT ) PARS(3) = 1.0d0
          IF ( DO_KPARAMS_DERIVS(K) ) THEN
            CALL VBRDF_LIN_MAKER &
             ( GISSCOXMUNK_VFUNCTION_PLUS, GISSCOXMUNK_VFUNCTION_DB_PLUS, &
               DO_LOCAL_WSA, DO_LOCAL_BSA, DO_WSA_SCALING,                           & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                         &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,         &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, n_muquad, n_phiquad,            &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                     &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                     &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                   &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS, DERIVS,           &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,           & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                         &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,      &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                              & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                   & ! output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0,                                   & ! output, New line, Version 2.7
               D_DBKERNEL_BRDFUNC, D_BRDFUNC, D_USER_BRDFUNC,                        & ! output
               D_BRDFUNC_0, D_USER_BRDFUNC_0, D_EBRDFUNC, D_USER_EBRDFUNC,           & ! output
               D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0 )                                ! output, New line, Version 2.7
         ELSE
           CALL VBRDF_MAKER &
             ( GISSCOXMUNK_VFUNCTION, GISSCOXMUNK_VFUNCTION_DB, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
          ENDIF
        ENDIF

!  New code . Giss Cox_munk with Complex RI : (3 Free parameters). Shadow
!   NO LINEARIZATION with this Kernel

        IF ( WHICH_BRDF(K) .EQ. GISSCOXMUNK_CRI_IDX ) THEN
          CALL VBRDF_GCMCRI_MAKER &
             ( DO_LOCAL_WSA, DO_LOCAL_BSA,                                        & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                      &
               DO_EXACTONLY, DO_USER_STREAMS, DO_SURFACE_EMISSION,                &
               DO_SHADOW_EFFECT, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,  &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                  &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                  &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,                &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,                &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,        & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF, n_muquad, n_phiquad, &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,   &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                           & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,                & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                                ! output, New line, Version 2.7
        ENDIF

!  BPDF 2009 kernel (0 free parameters)

        IF ( WHICH_BRDF(K) .EQ. BPDF2009_IDX ) THEN
          CALL VBRDF_MAKER &
             ( BPDF2009_VFUNCTION, BPDF2009_VFUNCTION, &
               DO_LOCAL_WSA, DO_LOCAL_BSA,                                       & ! New line, Version 2.7
               DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, DO_EXACT,                     &
               DO_EXACTONLY, LOCAL_MSR, DO_MSRCORR_EXACTONLY, MSRCORR_ORDER,     &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, N_MUQUAD, N_PHIQUAD,        &
               NSTREAMS_BRDF, NBRDF_HALF, NSTOKESSQ, BRDF_NPARS,                 &
               NSTREAMS, NBEAMS, N_USER_STREAMS, N_USER_RELAZMS,                 &
               QUAD_STREAMS, QUAD_SINES, USER_STREAMS, USER_SINES,               &
               SZASURCOS, SZASURSIN, PHIANG, COSPHI, SINPHI, PARS,               &
               SCALING_NSTREAMS, SCALING_QUAD_STREAMS, SCALING_QUAD_SINES,       & ! New line, Version 2.7
               X_BRDF, CX_BRDF, SX_BRDF, CXE_BRDF, SXE_BRDF,                     &
               X_MUQUAD, W_MUQUAD, SX_MUQUAD, WXX_MUQUAD, X_PHIQUAD, W_PHIQUAD,  &
               DBKERNEL_BRDFUNC, BRDFUNC, USER_BRDFUNC,                          & ! output
               BRDFUNC_0, USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC,               & ! Output
               SCALING_BRDFUNC, SCALING_BRDFUNC_0  )                               ! output, New line, Version 2.7
        ENDIF

!  Exact BRDFUNC
!  ------------

!  factor

        FF = BRDF_FACTORS(K)

!  Compute Exact Direct Beam BRDF
!   !@@ Observational Geometry, Optionalities 12/31/12

        IF ( DO_USER_OBSGEOMS ) THEN 
          DO O1 = 1, NSTOKESSQ
            DO IB = 1, NBEAMS
              VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(O1,LUM,LUA,IB) = &
                VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(O1,LUM,LUA,IB) &
                + FF * DBKERNEL_BRDFUNC(O1,LUM,LUA,IB)
            ENDDO
          ENDDO
        ELSE
          DO O1 = 1, NSTOKESSQ
            DO IA = 1, N_USER_RELAZMS
              DO IB = 1, NBEAMS
                DO UM = 1, N_USER_STREAMS
                  VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(O1,UM,IA,IB) = &
                    VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(O1,UM,IA,IB) &
                    + FF * DBKERNEL_BRDFUNC(O1,UM,IA,IB)
                ENDDO
              ENDDO
            ENDDO
          ENDDO
        ENDIF

!  If BSA or WSA Jacobian, Skip the next wection

        if ( do_WSAorBSA_Jacobian ) goto 553

!  Linearization w.r.t Kernel Factor

        W  = WOFFSET(K)
        IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
          W = W + 1
          IF ( DO_USER_OBSGEOMS ) THEN
            DO O1 = 1, NSTOKESSQ
              DO IB = 1, NBEAMS
                VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,O1,LUM,LUA,IB) = &
                  DBKERNEL_BRDFUNC(O1,LUM,LUA,IB)
              ENDDO
            ENDDO
          ELSE
            DO O1 = 1, NSTOKESSQ
              DO IA = 1, N_USER_RELAZMS
                DO IB = 1, NBEAMS
                  DO UM = 1, N_USER_STREAMS
                    VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,O1,UM,IA,IB) = &
                      DBKERNEL_BRDFUNC(O1,UM,IA,IB)
                  ENDDO
                ENDDO
              ENDDO
            ENDDO
          ENDIF
        ENDIF

!  Linearization w.r.t Kernel parameters

        DO P = 1, BRDF_NPARS
          IF ( DERIVS(P) ) THEN
            W = W + 1
            IF ( DO_USER_OBSGEOMS ) THEN
              DO O1 = 1, NSTOKESSQ
                DO IB = 1, NBEAMS
                  VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,O1,LUM,LUA,IB) = &
                    FF * D_DBKERNEL_BRDFUNC(P,O1,LUM,LUA,IB)
                ENDDO
              ENDDO
            ELSE
              DO O1 = 1, NSTOKESSQ
                DO IA = 1, N_USER_RELAZMS
                  DO IB = 1, NBEAMS
                    DO UM = 1, N_USER_STREAMS
                      VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,O1,UM,IA,IB) = &
                        FF * D_DBKERNEL_BRDFUNC(P,O1,UM,IA,IB)
                    ENDDO
                  ENDDO
                ENDDO
              ENDDO
            ENDIF
          ENDIF
        ENDDO

!  Continuation point for avoiding BSA Jacobian

553     continue

!  Scaling Section. New code, 15 April 2014 for Version 2.7
!  ========================================================

!  Get the requisite Fourier 0 components

        IF ( DO_LOCAL_WSA .or. DO_LOCAL_BSA ) THEN
           CALL SCALING_FOURIER_ZERO &
                ( DO_LOCAL_WSA, DO_LOCAL_BSA, LAMBERTIAN_KERNEL_FLAG(K), &
                  SCALING_NSTREAMS, NSTREAMS_BRDF,                       &
                  A_BRDF, SCALING_BRDFUNC, SCALING_BRDFUNC_0,            &
                  SCALING_BRDF_F, SCALING_BRDF_F_0 )
           IF ( .not. do_WSAorBSA_Jacobian .and. BRDF_NPARS .gt. 0) then
              CALL LIN_SCALING_FOURIER_ZERO &
                ( DO_LOCAL_WSA, DO_LOCAL_BSA, LAMBERTIAN_KERNEL_FLAG(K), &
                  BRDF_NPARS, DERIVS, SCALING_NSTREAMS, NSTREAMS_BRDF,   &
                  A_BRDF, D_SCALING_BRDFUNC, D_SCALING_BRDFUNC_0,        &
                  D_SCALING_BRDF_F, D_SCALING_BRDF_F_0 )
           ENDIF
        ENDIF

!  White-sky Spherical albedo. Code Upgraded for Version 2.7
!  ---------------------------------------------------------

        IF ( DO_LOCAL_WSA ) THEN

!  Only for non-Lambertian kernels (trivially = 1 otherwise)

           WSA_CALC(K) = ONE
           IF ( .NOT. LAMBERTIAN_KERNEL_FLAG(K) ) THEN
              HELP_A = ZERO
              DO I = 1, SCALING_NSTREAMS
                 SUM = DOT_PRODUCT(SCALING_BRDF_F(I,1:SCALING_NSTREAMS),SCALING_QUAD_STRMWTS(1:SCALING_NSTREAMS))
                HELP_A = HELP_A + SUM * SCALING_QUAD_STRMWTS(I)
              ENDDO
              WSA_CALC(K) = HELP_A * FOUR
           ENDIF
           TOTAL_WSA_CALC = TOTAL_WSA_CALC + BRDF_FACTORS(K) * WSA_CALC(K)

!  Perform consistency check on total white-sky spherical albedo
!    -- This is only done after the kernel summation is finished
!    -- If failed, go to 899 and the error output

           IF ( K.eq.N_BRDF_KERNELS ) then
              if ( TOTAL_WSA_CALC .le. zero ) then
                 STATUS = VLIDORT_SERIOUS ; NMESSAGES = NMESSAGES + 1
                 MESSAGES(NMESSAGES) = 'Fatal error: Total White-sky albedo is Negative; examine BRDF Amplitudes'
              else if ( TOTAL_WSA_CALC .gt. one ) then
                 STATUS = VLIDORT_SERIOUS ; NMESSAGES = NMESSAGES + 1
                 MESSAGES(NMESSAGES) = 'Fatal error: Total White-sky albedo is > 1; examine BRDF Amplitudes'
              endif
              IF (STATUS.NE.vlidort_success) GO TO 899
           endif

!  Derivatives of WSA w.r.t. parameter/factor variables. New section, Version 2.7
!    - Not valid if you are doing WSA-scaling Jacobian

           if ( .not. do_WSAorBSA_Jacobian .and.N_SURFACE_WFS .gt. 0 ) then
              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                 W = W + 1
                 D_TOTAL_WSA_CALC(W) = WSA_CALC(K) 
              ENDIF
              DO P = 1, BRDF_NPARS
                 IF ( DERIVS(P) ) THEN
                    W = W + 1 ; Q = 1 ; HELP_A = ZERO
                    DO I = 1, SCALING_NSTREAMS
                       SUM = DOT_PRODUCT(D_SCALING_BRDF_F(P,I,1:SCALING_NSTREAMS),SCALING_QUAD_STRMWTS(1:SCALING_NSTREAMS))
                       HELP_A = HELP_A + SUM * SCALING_QUAD_STRMWTS(I)
                    ENDDO
                    D_TOTAL_WSA_CALC(W) = BRDF_FACTORS(K) * HELP_A * FOUR
                 ENDIF
              ENDDO
           ENDIF

!  End WSA clause

        ENDIF

!  Black-sky Albedo, only for 1 solar beam. Code Upgraded for Version 2.7
!  ---------------------------------------

!  Compute it for non-Lambertian kernels
!     No check necessary, as the WSA is always checked (regardless of whether scaling is applied)

        IF (  DO_LOCAL_BSA ) THEN

!  Compute it for non-Lambertian kernels

           BSA_CALC(K) = ONE
           IF ( .NOT. LAMBERTIAN_KERNEL_FLAG(K) ) THEN
              BSA_CALC(K) = TWO * DOT_PRODUCT(SCALING_BRDF_F_0(1:SCALING_NSTREAMS),SCALING_QUAD_STRMWTS(1:SCALING_NSTREAMS))
           ENDIF
           TOTAL_BSA_CALC = TOTAL_BSA_CALC + BRDF_FACTORS(K) * BSA_CALC(K)

!  Derivatives of BSA w.r.t. parameter/factor variables. New section, Version 2.7
!    - Not valid if you are doing WSA-scaling Jacobian

           if ( .not. do_WSAorBSA_Jacobian .and.N_SURFACE_WFS .gt. 0 ) then
              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                 W = W + 1
                 D_TOTAL_BSA_CALC(W) = BSA_CALC(K) 
              ENDIF
              DO P = 1, BRDF_NPARS
                 IF ( DERIVS(P) ) THEN
                    W = W + 1 ; HELP_A = ZERO
                    HELP_A = DOT_PRODUCT(D_SCALING_BRDF_F_0(P,1:SCALING_NSTREAMS),SCALING_QUAD_STRMWTS(1:SCALING_NSTREAMS))
                    D_TOTAL_BSA_CALC(W) = BRDF_FACTORS(K) * HELP_A * TWO
                 ENDIF
              ENDDO
           ENDIF

!  End BSA clause

        ENDIF

!  !@@. Skip Fourier section, if Exact-only

        IF ( DO_EXACTONLY ) go to 676

!  Fourier Work now
!  ================

        DO M = 0, NMOMENTS

!  Fourier addition flag

          ADD_FOURIER = ( .NOT.LAMBERTIAN_KERNEL_FLAG(K) .OR. &
                          (LAMBERTIAN_KERNEL_FLAG(K) .AND. M.EQ.0) )

!  surface reflectance factors, Weighted Azimuth factors

          IF ( M .EQ. 0 ) THEN
            DELFAC   = ONE
            DO I = 1, NSTREAMS_BRDF
              BRDF_COSAZMFAC(I) = A_BRDF(I)
              BRDF_SINAZMFAC(I) = ZERO
            ENDDO
          ELSE
            DELFAC   = TWO
            DO I = 1, NSTREAMS_BRDF
              ARGUMENT = DBLE(M) * X_BRDF(I)
              BRDF_COSAZMFAC(I) = A_BRDF(I) * DCOS ( ARGUMENT )
              BRDF_SINAZMFAC(I) = A_BRDF(I) * DSIN ( ARGUMENT )
            ENDDO
          ENDIF

!  Call

          CALL VBRDF_FOURIER &
             ( DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, &
               DO_USER_STREAMS, DO_SURFACE_EMISSION, &
               LAMBERTIAN_KERNEL_FLAG(K), M, NSTOKES, NSTOKESSQ, NBEAMS, &
               NSTREAMS, N_USER_STREAMS, NSTREAMS_BRDF, NBRDF_HALF, &
               DELFAC, BRDF_FACTORS(K), BRDF_COSAZMFAC, BRDF_SINAZMFAC, &
               A_BRDF, BAX_BRDF, BRDFUNC, USER_BRDFUNC, BRDFUNC_0, &
               USER_BRDFUNC_0, EBRDFUNC, USER_EBRDFUNC, &
               LOCAL_BRDF_F, LOCAL_BRDF_F_0, LOCAL_USER_BRDF_F, &
               LOCAL_USER_BRDF_F_0, LOCAL_EMISSIVITY, &
               LOCAL_USER_EMISSIVITY )

!  Linear call

          IF ( BRDF_NPARS .GT. 0 ) THEN
            CALL VBRDF_LIN_FOURIER &
               ( DO_SOLAR_SOURCES, DO_USER_OBSGEOMS, &
                 DO_USER_STREAMS, DO_SURFACE_EMISSION, &
                 LAMBERTIAN_KERNEL_FLAG(K), M, NSTOKES, NSTOKESSQ, &
                 NBEAMS, NSTREAMS, N_USER_STREAMS, NSTREAMS_BRDF, &
                 NBRDF_HALF, BRDF_NPARS, DERIVS, DELFAC, &
                 BRDF_FACTORS(K), BRDF_COSAZMFAC, BRDF_SINAZMFAC, &
                 A_BRDF, BAX_BRDF, D_BRDFUNC, D_USER_BRDFUNC, &
                 D_BRDFUNC_0, D_USER_BRDFUNC_0, &
                 D_EBRDFUNC, D_USER_EBRDFUNC, &
                 D_LOCAL_BRDF_F, D_LOCAL_BRDF_F_0, &
                 D_LOCAL_USER_BRDF_F, D_LOCAL_USER_BRDF_F_0, &
                 D_LOCAL_EMISSIVITY,  D_LOCAL_USER_EMISSIVITY )
          ENDIF

!  Start Fourier addition

          IF ( ADD_FOURIER ) THEN

!  Kernel combinations (for quadrature reflectance)
!  ------------------------------------------------

!  factor

            FF = BRDF_FACTORS(K)

!  Kernel combinations (for quadrature-quadrature reflectance)
!   !@@ Code separated 12/31/12

!  ... Basic

            DO Q = 1, NSTOKESSQ
              DO I = 1, NSTREAMS
                DO J = 1, NSTREAMS
                  VBRDF_Sup_Out%BS_BRDF_F(M,Q,I,J) = &
                    VBRDF_Sup_Out%BS_BRDF_F(M,Q,I,J) &
                    + FF*LOCAL_BRDF_F(Q,I,J)
                ENDDO
              ENDDO
            ENDDO

!  ... Linearization w.r.t Kernel Factor

            W  = WOFFSET(K)
            IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
              W = W + 1
              DO Q = 1, NSTOKESSQ
                DO I = 1, NSTREAMS
                  DO J = 1, NSTREAMS
                    VBRDF_LinSup_Out%BS_LS_BRDF_F(W,M,Q,I,J) = &
                                     LOCAL_BRDF_F(Q,I,J)
                  ENDDO
                ENDDO
              ENDDO
            ENDIF

!  ... Linearization w.r.t Kernel parameters

            DO P = 1, BRDF_NPARS
              IF ( DERIVS(P) ) THEN
                W = W + 1
                DO Q = 1, NSTOKESSQ
                  DO I = 1, NSTREAMS
                    DO J = 1, NSTREAMS
                      VBRDF_LinSup_Out%BS_LS_BRDF_F(W,M,Q,I,J) = &
                                  FF*D_LOCAL_BRDF_F(P,Q,I,J)
                    ENDDO
                  ENDDO
                ENDDO
              ENDIF
            ENDDO

!  Kernel combinations (for Solar-quadrature reflectance)
!   !@@ Solar sources, Optionality 12/31/12

            IF ( DO_SOLAR_SOURCES ) THEN

!  ... Basic

              DO Q = 1, NSTOKESSQ
                DO I = 1, NSTREAMS
                  DO IB = 1, NBEAMS
                    VBRDF_Sup_Out%BS_BRDF_F_0(M,Q,I,IB) = &
                      VBRDF_Sup_Out%BS_BRDF_F_0(M,Q,I,IB) &
                      + FF*LOCAL_BRDF_F_0(Q,I,IB)
                  ENDDO
                ENDDO
              ENDDO

!  ... Linearization w.r.t Kernel Factor

              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                W = W + 1
                DO Q = 1, NSTOKESSQ
                  DO I = 1, NSTREAMS
                    DO IB = 1, NBEAMS
                      VBRDF_LinSup_Out%BS_LS_BRDF_F_0(W,M,Q,I,IB) = &
                                       LOCAL_BRDF_F_0(Q,I,IB)
                    ENDDO
                  ENDDO
                ENDDO
              ENDIF

!  ... Linearization w.r.t Kernel parameters

              DO P = 1, BRDF_NPARS
                IF ( DERIVS(P) ) THEN
                  W = W + 1
                  DO Q = 1, NSTOKESSQ
                    DO I = 1, NSTREAMS
                      DO IB = 1, NBEAMS
                        VBRDF_LinSup_Out%BS_LS_BRDF_F_0(W,M,Q,I,IB) = &
                                    FF*D_LOCAL_BRDF_F_0(P,Q,I,IB)
                      ENDDO
                    ENDDO
                  ENDDO
                ENDIF
              ENDDO

!  End solar option

            ENDIF

!  Kernel combinations (for user-stream reflectance)
!  -------------------------------------------------

            IF ( DO_USER_STREAMS ) THEN

!  Kernel combinations (for Quadrature-to-Userstream reflectance)
!   !@@ Code separated 12/31/12

!  ... Basic

              DO Q = 1, NSTOKESSQ
                DO UM = 1, N_USER_STREAMS
                  DO J = 1, NSTREAMS
                    VBRDF_Sup_Out%BS_USER_BRDF_F(M,Q,UM,J) = &
                      VBRDF_Sup_Out%BS_USER_BRDF_F(M,Q,UM,J) &
                      + FF*LOCAL_USER_BRDF_F(Q,UM,J)
                  ENDDO
                ENDDO
              ENDDO

!  ... Linearization w.r.t Kernel Factor

              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                W = W + 1
                DO Q = 1, NSTOKESSQ
                  DO UM = 1, N_USER_STREAMS
                    DO J = 1, NSTREAMS
                      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F(W,M,Q,UM,J) = &
                                       LOCAL_USER_BRDF_F(Q,UM,J)
                    ENDDO
                  ENDDO
                ENDDO
              ENDIF

!  ... Linearization w.r.t Kernel parameters

              DO P = 1, BRDF_NPARS
                IF ( DERIVS(P) ) THEN
                  W = W + 1
                  DO Q = 1, NSTOKESSQ
                    DO UM = 1, N_USER_STREAMS
                      DO J = 1, NSTREAMS
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F(W,M,Q,UM,J) = &
                            FF*D_LOCAL_USER_BRDF_F(P,Q,UM,J)
                      ENDDO
                    ENDDO
                  ENDDO
                ENDIF
              ENDDO

!  End user-clause

            ENDIF

!  Kernel combinations (for Solar-to-Userstream reflectance)
!   !@@ Generally only required for a MS + SS Truncated calculation
!   !@@ Observational Goemetry and Solar sources, Optionalities 12/31/12

            IF ( DO_USER_STREAMS.and.DO_SOLAR_SOURCES ) THEN

!  ... Basic

              IF ( DO_USER_OBSGEOMS ) THEN
                DO Q = 1, NSTOKESSQ
                  DO IB = 1, NBEAMS
                    VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,LUM,IB) = &
                      VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,LUM,IB) &
                      + FF*LOCAL_USER_BRDF_F_0(Q,LUM,IB)
                  ENDDO
                ENDDO
              ELSE
                DO Q = 1, NSTOKESSQ
                  DO UM = 1, N_USER_STREAMS
                    DO IB = 1, NBEAMS
                      VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,UM,IB) = &
                        VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,UM,IB) &
                        + FF*LOCAL_USER_BRDF_F_0(Q,UM,IB)
                    ENDDO
                  ENDDO
                ENDDO
              ENDIF

!  ... Linearization w.r.t Kernel Factor

              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                W = W + 1
                IF ( DO_USER_OBSGEOMS ) THEN
                  DO Q = 1, NSTOKESSQ
                    DO IB = 1, NBEAMS
                      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,LUM,IB) = &
                        LOCAL_USER_BRDF_F_0(Q,LUM,IB)
                    ENDDO
                  ENDDO
                ELSE
                  DO Q = 1, NSTOKESSQ
                    DO UM = 1, N_USER_STREAMS
                      DO IB = 1, NBEAMS
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,UM,IB) = &
                          LOCAL_USER_BRDF_F_0(Q,UM,IB)
                      ENDDO
                    ENDDO
                  ENDDO
                ENDIF
              ENDIF

!  ... Linearization w.r.t Kernel parameters

              DO P = 1, BRDF_NPARS
                IF ( DERIVS(P) ) THEN
                  W = W + 1
                  IF ( DO_USER_OBSGEOMS ) THEN
                    DO Q = 1, NSTOKESSQ
                      DO IB = 1, NBEAMS
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,LUM,IB) = &
                            FF*D_LOCAL_USER_BRDF_F_0(P,Q,LUM,IB)
                      ENDDO
                    ENDDO
                  ELSE
                    DO Q = 1, NSTOKESSQ
                      DO UM = 1, N_USER_STREAMS
                        DO IB = 1, NBEAMS
                          VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,UM,IB) = &
                              FF*D_LOCAL_USER_BRDF_F_0(P,Q,UM,IB)
                        ENDDO
                      ENDDO
                    ENDDO
                  ENDIF
                ENDIF
              ENDDO

!  End solar and user-clause

            ENDIF

!  Total emissivities
!  ------------------

!  only if flagged

            IF ( DO_SURFACE_EMISSION .AND.  M .EQ. 0 ) THEN

!  Basic kernel contributions
!  VErsion 2.7, Surely need BRDF factors..........

              DO Q = 1, NSTOKES
                DO I = 1, NSTREAMS
                  VBRDF_Sup_Out%BS_EMISSIVITY(Q,I) = &
                  VBRDF_Sup_Out%BS_EMISSIVITY(Q,I) - LOCAL_EMISSIVITY(Q,I)
                ENDDO
                IF ( DO_USER_STREAMS ) THEN
                  DO UI = 1, N_USER_STREAMS
                    VBRDF_Sup_Out%BS_USER_EMISSIVITY(Q,UI) = &
                    VBRDF_Sup_Out%BS_USER_EMISSIVITY(Q,UI) - FF*LOCAL_USER_EMISSIVITY(Q,UI)
! former            VBRDF_Sup_Out%BS_USER_EMISSIVITY(Q,UI) - LOCAL_USER_EMISSIVITY(Q,UI)
                  ENDDO
                ENDIF
              ENDDO

!  Linearization w.r.t Kernel Factor

              W  = WOFFSET(K)
              IF ( DO_KERNEL_FACTOR_WFS(K) ) THEN
                W = W + 1
                DO Q = 1, NSTOKES
                  DO I = 1, NSTREAMS
                    VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I) = - LOCAL_EMISSIVITY(Q,I)
! former            VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I) = - LOCAL_EMISSIVITY(Q,I) / FF
                  ENDDO
                  IF ( DO_USER_STREAMS ) THEN
                    DO UI = 1, N_USER_STREAMS
                      VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UI) = - LOCAL_USER_EMISSIVITY(Q,UI)
! former              VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UI) = - LOCAL_USER_EMISSIVITY(Q,UI) / FF
                    ENDDO
                  ENDIF
                ENDDO
              ENDIF

!  Linearization w.r.t Kernel parameters

              DO P = 1, BRDF_NPARS
                IF ( DERIVS(P) ) THEN
                  W = W + 1
                  DO Q = 1, NSTOKES
                    DO I = 1, NSTREAMS
                      VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I) = - FF*D_LOCAL_EMISSIVITY(P,Q,I)
! former              VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I) = - D_LOCAL_EMISSIVITY(P,Q,I)
                    ENDDO
                    IF ( DO_USER_STREAMS ) THEN
                      DO UI = 1, N_USER_STREAMS
                        VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UI) = - FF*D_LOCAL_USER_EMISSIVITY(P,Q,UI)
! former                VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UI) = - D_LOCAL_USER_EMISSIVITY(P,Q,UI)
                      ENDDO
                    ENDIF
                  ENDDO
                ENDIF
              ENDDO

!  End emissivity clause

            ENDIF

!  End Fourier addition

          ENDIF

!  End Fourier loop

        ENDDO

!  continuation point for skipping Fourier work. !@@

676     continue

!  End kernel loop

      ENDDO

!  Now perform normalizations and scaling with White-sky or Black-sky albedos. New section, 02-15 April 2014
!  =========================================================================================================
!  only if flagged.

      IF ( DO_WSA_SCALING .or. DO_BSA_SCALING ) THEN

!  set scaling factor

         WBSA = 1
         if ( DO_WSA_SCALING ) then
            SCALING_0 = one / TOTAL_WSA_CALC
            SCALING   = SCALING_0 * WSA_VALUE
            D_TOTAL_ALBEDO_CALC = D_TOTAL_WSA_CALC 
         else
            SCALING_0 = one / TOTAL_BSA_CALC
            SCALING   = SCALING_0 * BSA_VALUE
            D_TOTAL_ALBEDO_CALC = D_TOTAL_BSA_CALC 
         endif

!  BRDF Scaling : Start loop over matrix entries
!  ---------------------------------------------

         DO Q = 1, NSTOKESSQ

!  Scaling the Exact Direct Beam BRDF and its derivatives
!  ------------------------------------------------------

!  First scale derivatives, then the BRDF itself (order is important)
!    Either Scale White-Sky Jacobian, or scale the kernel factor/parameter Jacobians

!  Observational  Geometries

            IF ( DO_USER_OBSGEOMS ) THEN
              DO IB = 1, NBEAMS
                T0 = VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(Q,LUM,LUA,IB) ; T00 = SCALING * T0
                VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(Q,LUM,LUA,IB) = T00
                IF ( DO_WSAorBSA_Jacobian ) THEN
                  VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(WBSA,Q,LUM,LUA,IB) = SCALING_0 * T0
                ELSE IF ( N_SURFACE_WFS .gt. 0) then
                  DO W = 1, N_SURFACE_WFS
                    T1 = VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,Q,LUM,LUA,IB)
                    T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                    VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,Q,LUM,LUA,IB) = SCALING * T1 - SCALING_0 * T2
                  ENDDO
                ENDIF
              ENDDO
            ENDIF

!  Lattice Geometries

            IF (.not. DO_USER_OBSGEOMS ) THEN
              DO IA = 1, N_USER_RELAZMS
                DO IB = 1, NBEAMS
                  DO UM = 1, N_USER_STREAMS
                    T0 = VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(Q,UM,IA,IB) ; T00 = SCALING * T0
                    VBRDF_Sup_Out%BS_EXACTDB_BRDFUNC(Q,UM,IA,IB) = T00
                    IF ( DO_WSAorBSA_Jacobian ) THEN
                      VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(WBSA,Q,UM,IA,IB) = SCALING_0 * T0
                    ELSE IF ( N_SURFACE_WFS .gt. 0) then
                      DO W = 1, N_SURFACE_WFS
                        T1 = VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,Q,UM,IA,IB)
                        T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                        VBRDF_LinSup_Out%BS_LS_EXACTDB_BRDFUNC(W,Q,UM,IA,IB) = SCALING * T1 - SCALING_0 * T2
                      ENDDO
                    ENDIF
                  ENDDO
                ENDDO
              ENDDO
            ENDIF

!  Scaling for the Fourier terms
!  -----------------------------

            DO M = 0, NMOMENTS

!  quadrature-quadrature  reflectance

              DO I = 1, NSTREAMS
                DO J = 1, NSTREAMS
                  T0 = VBRDF_Sup_Out%BS_BRDF_F(M,Q,I,J) ; T00 = SCALING * T0
                  VBRDF_Sup_Out%BS_BRDF_F(M,Q,I,J) = T00
                  IF ( DO_WSAorBSA_Jacobian ) THEN
                    VBRDF_LinSup_Out%BS_LS_BRDF_F(WBSA,M,Q,I,J) = SCALING_0 * T0
                  ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                    DO W = 1, N_SURFACE_WFS
                      T1 = VBRDF_LinSup_Out%BS_LS_BRDF_F(W,M,Q,I,J)
                      T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                      VBRDF_LinSup_Out%BS_LS_BRDF_F(W,M,Q,I,J) = SCALING * T1 - SCALING_0 * T2
                    ENDDO
                  ENDIF
                ENDDO
              ENDDO

!  Solar-quadrature  reflectance

              IF ( DO_SOLAR_SOURCES ) THEN
                Do I = 1, NSTREAMS
                  Do IB = 1, NBEAMS
                    T0 = VBRDF_Sup_Out%BS_BRDF_F_0(M,Q,I,IB) ; T00 = SCALING * T0
                    VBRDF_Sup_Out%BS_BRDF_F_0(M,Q,I,IB) = T00
                    IF ( DO_WSAorBSA_Jacobian ) THEN
                      VBRDF_LinSup_Out%BS_LS_BRDF_F_0(WBSA,M,Q,I,IB) = SCALING_0 * T0
                    ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                      DO W = 1, N_SURFACE_WFS
                        T1 = VBRDF_LinSup_Out%BS_LS_BRDF_F_0(W,M,Q,I,IB)
                        T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                        VBRDF_LinSup_Out%BS_LS_BRDF_F_0(W,M,Q,I,IB) = SCALING * T1 - SCALING_0 * T2
                      ENDDO
                    ENDIF
                  ENDDO
                ENDDO
              ENDIF

!  Quadrature-to-Userstream reflectance

              IF ( DO_USER_STREAMS ) THEN
                Do UM = 1, N_USER_STREAMS
                  Do I = 1, NSTREAMS
                    T0 = VBRDF_Sup_Out%BS_USER_BRDF_F(M,Q,UM,I) ; T00 = SCALING * T0
                    VBRDF_Sup_Out%BS_USER_BRDF_F(M,Q,UM,I) = T00
                    IF ( DO_WSAorBSA_Jacobian ) THEN
                      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F(WBSA,M,Q,UM,I) = SCALING_0 * T0
                    ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                      DO W = 1, N_SURFACE_WFS
                        T1 = VBRDF_LinSup_Out%BS_LS_USER_BRDF_F(W,M,Q,UM,I)
                        T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F(W,M,Q,UM,I) = SCALING * T1 - SCALING_0 * T2
                      ENDDO
                    ENDIF
                  ENDDO
                ENDDO
              ENDIF

!  Solar-to-Userstream reflectance

              IF ( DO_USER_STREAMS.and.DO_SOLAR_SOURCES ) THEN
                IF ( DO_USER_OBSGEOMS ) THEN
                  Do IB = 1, NBEAMS
                    T0 = VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,LUM,IB) ; T00 = SCALING * T0
                    VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,LUM,IB) = T00
                    IF ( DO_WSAorBSA_Jacobian ) THEN
                      VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(WBSA,M,Q,LUM,IB) = SCALING_0 * T0
                    ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                      DO W = 1, N_SURFACE_WFS
                        T1 = VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,LUM,IB)
                        T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,LUM,IB) = SCALING * T1 - SCALING_0 * T2
                      ENDDO
                    ENDIF
                  ENDDO
                ELSE
                  DO UM = 1, N_USER_STREAMS
                    Do IB = 1, NBEAMS
                      T0 = VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,UM,IB) ; T00 = SCALING * T0
                      VBRDF_Sup_Out%BS_USER_BRDF_F_0(M,Q,UM,IB) = T00
                      IF ( DO_WSAorBSA_Jacobian ) THEN
                        VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(WBSA,M,Q,UM,IB) = SCALING_0 * T0
                      ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                        DO W = 1, N_SURFACE_WFS
                          T1 = VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,UM,IB)
                          T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                          VBRDF_LinSup_Out%BS_LS_USER_BRDF_F_0(W,M,Q,UM,IB) = SCALING * T1 - SCALING_0 * T2
                        ENDDO
                      ENDIF
                    ENDDO
                  ENDDO
                ENDIF
              ENDIF

!  End Fourier Loop

            ENDDO

!  End reflectance Matrix Loop

         ENDDO

!  Emissivity scaling
!  ------------------

!  Unscaled Emissivity will be < 0
 
         IF ( DO_SURFACE_EMISSION ) THEN
           DO Q = 1, NSTOKES
             Do I = 1, NSTREAMS
               T0 = VBRDF_Sup_Out%BS_EMISSIVITY(Q,I) ; T00 = SCALING * T0
               VBRDF_Sup_Out%BS_EMISSIVITY(Q,I) = ONE + T00
               IF ( DO_WSAorBSA_Jacobian ) THEN
                 VBRDF_LinSup_Out%BS_LS_EMISSIVITY(WBSA,Q,I) = SCALING_0 * T0
               ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                 DO W = 1, N_SURFACE_WFS
                   T1 = VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I)
                   T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                   VBRDF_LinSup_Out%BS_LS_EMISSIVITY(W,Q,I) = SCALING * T1 - SCALING_0 * T2
                 ENDDO
               ENDIF
             enddo
             IF ( DO_USER_STREAMS ) THEN
               Do UM = 1, N_USER_STREAMS
                 T0 = VBRDF_Sup_Out%BS_USER_EMISSIVITY(Q,UM) ; T00 = SCALING * T0
                 VBRDF_Sup_Out%BS_USER_EMISSIVITY(Q,UM) = ONE +  T00
                 IF ( DO_WSAorBSA_Jacobian ) THEN
                   VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(WBSA,Q,UM) = SCALING_0 * T0
                 ELSE IF ( N_SURFACE_WFS .gt. 0) THEN
                   DO W = 1, N_SURFACE_WFS
                     T1 = VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UM)
                     T2 = T00 * D_TOTAL_ALBEDO_CALC(W)
                     VBRDF_LinSup_Out%BS_LS_USER_EMISSIVITY(W,Q,UM) = SCALING * T1 - SCALING_0 * T2
                   ENDDO
                 ENDIF
               enddo
             ENDIF
           ENDDO
         ENDIF

!  End scaling option

      ENDIF

!  Continuation point for Error Finish from Consistency Check of Spherical Albedo

899   continue

!  write Exception handling to output structure

      VBRDF_Sup_OutputStatus%BS_STATUS_OUTPUT   = STATUS
      VBRDF_Sup_OutputStatus%BS_NOUTPUTMESSAGES = NMESSAGES
      VBRDF_Sup_OutputStatus%BS_OUTPUTMESSAGES  = MESSAGES

!  Finish

      RETURN
      END SUBROUTINE VBRDF_LIN_MAINMASTER

      END MODULE vbrdf_LinSup_masters_m

