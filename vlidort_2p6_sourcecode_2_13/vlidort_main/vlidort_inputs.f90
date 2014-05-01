! ###############################################################
! #                                                             #
! #                    THE VLIDORT  MODEL                       #
! #                                                             #
! #  Vectorized LInearized Discrete Ordinate Radiative Transfer #
! #  -          --         -        -        -         -        #
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

! ###############################################################
! #                                                             #
! # Subroutines in this Module                                  #
! #                                                             #
! #            VLIDORT_INPUT_MASTER (master)                    #
! #                                                             #
! #    Input-Master routine calls the following                 #
! #                                                             #
! #            VLIDORT_INIT_CONTROL_VARS                        #
! #            VLIDORT_INIT_MODEL_VARS                          #
! #            VLIDORT_INIT_THERMAL_VARS                        #
! #            VLIDORT_READ_INPUTS                              #
! #                                                             #
! #    These routines are called by the Main VLIDORT module     #
! #                                                             #
! #            VLIDORT_CHECK_INPUT                              #
! #            VLIDORT_DERIVE_INPUT                             #
! #                                                             #
! ###############################################################


      MODULE vlidort_inputs

      PRIVATE
      PUBLIC :: VLIDORT_INPUT_MASTER, &
                VLIDORT_INIT_CONTROL_VARS, &
                VLIDORT_INIT_MODEL_VARS, &
                VLIDORT_INIT_THERMAL_VARS, &
                VLIDORT_READ_INPUTS, &
                VLIDORT_CHECK_INPUT, &
                VLIDORT_DERIVE_INPUT

      CONTAINS

      SUBROUTINE VLIDORT_INPUT_MASTER ( &
        FILNAM,             & ! Input
        VLIDORT_FixIn,      & ! Outputs
        VLIDORT_ModIn,      & ! Outputs
        VLIDORT_InputStatus ) ! Outputs

      USE VLIDORT_PARS
      USE VLIDORT_Inputs_def
      USE VLIDORT_Outputs_def
      USE VLIDORT_AUX

      IMPLICIT NONE

!  Input data filename

      CHARACTER (LEN=*), INTENT(IN)  ::    FILNAM

!  Outputs

      TYPE(VLIDORT_Fixed_Inputs), INTENT (OUT)      :: VLIDORT_FixIn
      TYPE(VLIDORT_Modified_Inputs), INTENT (OUT)   :: VLIDORT_ModIn
      TYPE(VLIDORT_Input_Exception_Handling), &
                                       INTENT (OUT) :: VLIDORT_InputStatus

!  Local variables

      LOGICAL ::             DO_FULLRAD_MODE
      LOGICAL ::             DO_SSCORR_NADIR
      LOGICAL ::             DO_SSCORR_OUTGOING
      LOGICAL ::             DO_SSCORR_TRUNCATION

!  New 15 March 2012
      LOGICAL ::             DO_SS_EXTERNAL
!  New 17 May 2012
      LOGICAL ::             DO_SURFACE_LEAVING
      LOGICAL ::             DO_SL_ISOTROPIC

      LOGICAL ::             DO_SSFULL
      LOGICAL ::             DO_DOUBLE_CONVTEST
      LOGICAL ::             DO_SOLAR_SOURCES
      LOGICAL ::             DO_PLANE_PARALLEL
      LOGICAL ::             DO_REFRACTIVE_GEOMETRY
      LOGICAL ::             DO_CHAPMAN_FUNCTION
      LOGICAL ::             DO_RAYLEIGH_ONLY
      LOGICAL ::             DO_DELTAM_SCALING
      LOGICAL ::             DO_SOLUTION_SAVING
      LOGICAL ::             DO_BVP_TELESCOPING
      LOGICAL ::             DO_UPWELLING
      LOGICAL ::             DO_DNWELLING
      LOGICAL ::             DO_QUAD_OUTPUT
      LOGICAL ::             DO_USER_VZANGLES
      LOGICAL ::             DO_ADDITIONAL_MVOUT
      LOGICAL ::             DO_MVOUT_ONLY
      LOGICAL ::             DO_DEBUG_WRITE
      LOGICAL ::             DO_WRITE_INPUT
      LOGICAL ::             DO_WRITE_SCENARIO
      LOGICAL ::             DO_WRITE_FOURIER
      LOGICAL ::             DO_WRITE_RESULTS
      CHARACTER (LEN=60) ::  INPUT_WRITE_FILENAME
      CHARACTER (LEN=60) ::  SCENARIO_WRITE_FILENAME
      CHARACTER (LEN=60) ::  FOURIER_WRITE_FILENAME
      CHARACTER (LEN=60) ::  RESULTS_WRITE_FILENAME
      INTEGER ::             NSTOKES
      INTEGER ::             NSTREAMS
      INTEGER ::             NLAYERS
      INTEGER ::             NFINELAYERS
      INTEGER ::             NGREEK_MOMENTS_INPUT
      DOUBLE PRECISION ::    VLIDORT_ACCURACY
      DOUBLE PRECISION ::    FLUX_FACTOR
      INTEGER ::             N_SZANGLES
      DOUBLE PRECISION ::    SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION ::    EARTH_RADIUS
      DOUBLE PRECISION ::    RFINDEX_PARAMETER
      DOUBLE PRECISION ::    GEOMETRY_SPECHEIGHT
      INTEGER ::             N_USER_RELAZMS
      DOUBLE PRECISION ::    USER_RELAZMS  ( MAX_USER_RELAZMS )
      INTEGER ::             N_USER_VZANGLES
      DOUBLE PRECISION ::    USER_VZANGLES ( MAX_USER_VZANGLES )
      INTEGER ::             N_USER_LEVELS
      DOUBLE PRECISION ::    USER_LEVELS ( MAX_USER_LEVELS )
      LOGICAL ::             DO_LAMBERTIAN_SURFACE
      DOUBLE PRECISION ::    LAMBERTIAN_ALBEDO
      LOGICAL ::             DO_OBSERVATION_GEOMETRY
      INTEGER ::             N_USER_OBSGEOMS
      DOUBLE PRECISION ::    USER_OBSGEOMS ( MAX_USER_OBSGEOMS, 3 )

      LOGICAL ::             DO_THERMAL_EMISSION
      INTEGER ::             N_THERMAL_COEFFS
      DOUBLE PRECISION ::    THERMAL_BB_INPUT ( 0:MAXLAYERS )
      LOGICAL ::             DO_SURFACE_EMISSION
      DOUBLE PRECISION ::    SURFBB
      LOGICAL ::             DO_THERMAL_TRANSONLY

      LOGICAL ::             DO_SPECIALIST_OPTION_1
      LOGICAL ::             DO_SPECIALIST_OPTION_2
      LOGICAL ::             DO_SPECIALIST_OPTION_3
      LOGICAL ::             DO_TOA_CONTRIBS

      INTEGER ::             STATUS
      INTEGER ::             NMESSAGES
      CHARACTER (LEN=120) :: MESSAGES ( 0:MAX_MESSAGES )
      CHARACTER (LEN=120) :: ACTIONS ( 0:MAX_MESSAGES )

      INTEGER ::             STATUS_SUB, FILUNIT

!  Initialize status

      STATUS = VLIDORT_SUCCESS

      MESSAGES(1:MAX_MESSAGES) = ' '
      ACTIONS (1:MAX_MESSAGES) = ' '

      NMESSAGES       = 0
      MESSAGES(0)     = 'Successful Read of VLIDORT Input file'
      ACTIONS(0)      = 'No Action required for this Task'

!  Initialize variables
!    Surface-leaving terms added 17 May 2012

      CALL VLIDORT_INIT_CONTROL_VARS ( &
        DO_FULLRAD_MODE, DO_SSCORR_NADIR, &
        DO_SSCORR_OUTGOING, DO_SSCORR_TRUNCATION, &
        DO_SS_EXTERNAL, DO_SSFULL, DO_DOUBLE_CONVTEST, &
        DO_PLANE_PARALLEL, DO_REFRACTIVE_GEOMETRY, &
        DO_CHAPMAN_FUNCTION, DO_RAYLEIGH_ONLY, &
        DO_DELTAM_SCALING, DO_SOLUTION_SAVING, &
        DO_BVP_TELESCOPING, DO_UPWELLING, &
        DO_DNWELLING, DO_QUAD_OUTPUT, &
        DO_USER_VZANGLES, DO_ADDITIONAL_MVOUT, &
        DO_MVOUT_ONLY, DO_DEBUG_WRITE, &
        DO_WRITE_INPUT, DO_WRITE_SCENARIO, &
        DO_WRITE_FOURIER, DO_WRITE_RESULTS, &
        DO_LAMBERTIAN_SURFACE, DO_OBSERVATION_GEOMETRY, &
        DO_SPECIALIST_OPTION_1, DO_SPECIALIST_OPTION_2, &
        DO_SPECIALIST_OPTION_3, DO_TOA_CONTRIBS, &
        DO_SURFACE_LEAVING, DO_SL_ISOTROPIC )

      CALL VLIDORT_INIT_THERMAL_VARS ( &
        DO_THERMAL_EMISSION, N_THERMAL_COEFFS, &
        THERMAL_BB_INPUT, DO_SURFACE_EMISSION, &
        SURFBB, DO_THERMAL_TRANSONLY )

      CALL VLIDORT_INIT_MODEL_VARS ( &
        NSTOKES, NSTREAMS, &
        NLAYERS, NFINELAYERS, &
        NGREEK_MOMENTS_INPUT, VLIDORT_ACCURACY, &
        FLUX_FACTOR, N_SZANGLES, &
        SZANGLES, EARTH_RADIUS, &
        RFINDEX_PARAMETER, GEOMETRY_SPECHEIGHT, &
        N_USER_RELAZMS, USER_RELAZMS, &
        N_USER_VZANGLES, USER_VZANGLES, &
        N_USER_LEVELS, USER_LEVELS, &
        N_USER_OBSGEOMS, USER_OBSGEOMS, &
        LAMBERTIAN_ALBEDO )

!  Open file

      FILUNIT = VLIDORT_INUNIT
      OPEN(VLIDORT_INUNIT,FILE=FILNAM,ERR=300,STATUS='OLD')

!  Read standard inputs
!    Surface-leaving terms added 17 May 2012

      CALL VLIDORT_READ_INPUTS ( &
        DO_FULLRAD_MODE, DO_SSCORR_NADIR, &
        DO_SSCORR_OUTGOING, DO_SSCORR_TRUNCATION, &
        DO_SS_EXTERNAL, DO_SSFULL, DO_DOUBLE_CONVTEST, &
        DO_SOLAR_SOURCES, DO_PLANE_PARALLEL, &
        DO_REFRACTIVE_GEOMETRY, DO_CHAPMAN_FUNCTION, &
        DO_RAYLEIGH_ONLY, DO_DELTAM_SCALING, &
        DO_SOLUTION_SAVING, DO_BVP_TELESCOPING, &
        DO_UPWELLING, DO_DNWELLING, &
        DO_QUAD_OUTPUT, DO_USER_VZANGLES, &
        DO_SURFACE_LEAVING, DO_SL_ISOTROPIC,&
        DO_ADDITIONAL_MVOUT, DO_MVOUT_ONLY, &
        DO_OBSERVATION_GEOMETRY, &
        DO_DEBUG_WRITE, DO_WRITE_INPUT, &
        DO_WRITE_SCENARIO, DO_WRITE_FOURIER, &
        DO_WRITE_RESULTS, INPUT_WRITE_FILENAME, &
        SCENARIO_WRITE_FILENAME, FOURIER_WRITE_FILENAME, &
        RESULTS_WRITE_FILENAME, NSTOKES, &
        NSTREAMS, NLAYERS, &
        NFINELAYERS, NGREEK_MOMENTS_INPUT, &
        VLIDORT_ACCURACY, FLUX_FACTOR, &
        N_SZANGLES, SZANGLES, &
        EARTH_RADIUS, RFINDEX_PARAMETER, &
        GEOMETRY_SPECHEIGHT, N_USER_RELAZMS, &
        USER_RELAZMS, N_USER_VZANGLES, &
        USER_VZANGLES, N_USER_LEVELS, &
        USER_LEVELS, N_USER_OBSGEOMS, &
        USER_OBSGEOMS, DO_LAMBERTIAN_SURFACE, &
        LAMBERTIAN_ALBEDO, DO_THERMAL_EMISSION, &
        N_THERMAL_COEFFS, DO_SURFACE_EMISSION, &
        DO_THERMAL_TRANSONLY, &
        STATUS_SUB, NMESSAGES, MESSAGES, ACTIONS )

      IF ( STATUS_SUB .NE. VLIDORT_SUCCESS ) THEN
        STATUS = VLIDORT_SERIOUS
        VLIDORT_InputStatus%TS_STATUS_INPUTREAD = STATUS
        VLIDORT_InputStatus%TS_NINPUTMESSAGES   = NMESSAGES
        VLIDORT_InputStatus%TS_INPUTMESSAGES    = MESSAGES
        VLIDORT_InputStatus%TS_INPUTACTIONS     = ACTIONS
        CLOSE(FILUNIT)
        RETURN
      ENDIF

!  Normal execution: Copy all variables and return
!  -----------------------------------------------

!  First close file

      CLOSE(FILUNIT)

!  Copy data to structure variables:

!  Fixed Boolean inputs

      VLIDORT_FixIn%Bool%TS_DO_FULLRAD_MODE        = DO_FULLRAD_MODE
      VLIDORT_FixIn%Bool%TS_DO_SSCORR_TRUNCATION   = DO_SSCORR_TRUNCATION
!  New 15 march 2012
      VLIDORT_FixIn%Bool%TS_DO_SS_EXTERNAL         = DO_SS_EXTERNAL
      VLIDORT_FixIn%Bool%TS_DO_SSFULL              = DO_SSFULL
      VLIDORT_FixIn%Bool%TS_DO_THERMAL_EMISSION    = DO_THERMAL_EMISSION
      VLIDORT_FixIn%Bool%TS_DO_SURFACE_EMISSION    = DO_SURFACE_EMISSION
      VLIDORT_FixIn%Bool%TS_DO_PLANE_PARALLEL      = DO_PLANE_PARALLEL
      !VLIDORT_FixIn%Bool%TS_DO_BRDF_SURFACE        = DO_BRDF_SURFACE
      VLIDORT_FixIn%Bool%TS_DO_UPWELLING           = DO_UPWELLING
      VLIDORT_FixIn%Bool%TS_DO_DNWELLING           = DO_DNWELLING
      VLIDORT_FixIn%Bool%TS_DO_QUAD_OUTPUT         = DO_QUAD_OUTPUT
      VLIDORT_FixIn%Bool%TS_DO_TOA_CONTRIBS        = DO_TOA_CONTRIBS
      VLIDORT_FixIn%Bool%TS_DO_LAMBERTIAN_SURFACE  = DO_LAMBERTIAN_SURFACE
      VLIDORT_FixIn%Bool%TS_DO_SPECIALIST_OPTION_1 = DO_SPECIALIST_OPTION_1
      VLIDORT_FixIn%Bool%TS_DO_SPECIALIST_OPTION_2 = DO_SPECIALIST_OPTION_2
      VLIDORT_FixIn%Bool%TS_DO_SPECIALIST_OPTION_3 = DO_SPECIALIST_OPTION_3

!  New 17 May 2012
      VLIDORT_FixIn%Bool%TS_DO_SURFACE_LEAVING     = DO_SURFACE_LEAVING
      VLIDORT_FixIn%Bool%TS_DO_SL_ISOTROPIC        = DO_SL_ISOTROPIC

!  Fixed Control inputs

      VLIDORT_FixIn%Cont%TS_NSTOKES          = NSTOKES
      VLIDORT_FixIn%Cont%TS_NSTREAMS         = NSTREAMS
      VLIDORT_FixIn%Cont%TS_NLAYERS          = NLAYERS
      VLIDORT_FixIn%Cont%TS_NFINELAYERS      = NFINELAYERS
      VLIDORT_FixIn%Cont%TS_N_THERMAL_COEFFS = N_THERMAL_COEFFS
      VLIDORT_FixIn%Cont%TS_VLIDORT_ACCURACY = VLIDORT_ACCURACY

!  Fixed Beam inputs

      VLIDORT_FixIn%SunRays%TS_FLUX_FACTOR = FLUX_FACTOR

!  Fixed User Value inputs

      VLIDORT_FixIn%UserVal%TS_N_USER_LEVELS       = N_USER_LEVELS

!  Fixed Chapman Function inputs

      !VLIDORT_FixIn%Chapman%TS_HEIGHT_GRID       = HEIGHT_GRID
      !VLIDORT_FixIn%Chapman%TS_PRESSURE_GRID     = PRESSURE_GRID
      !VLIDORT_FixIn%Chapman%TS_TEMPERATURE_GRID  = TEMPERATURE_GRID
      !VLIDORT_FixIn%Chapman%TS_FINEGRID          = FINEGRID
      VLIDORT_FixIn%Chapman%TS_RFINDEX_PARAMETER = RFINDEX_PARAMETER

!  Fixed Optical inputs

      !VLIDORT_FixIn%Optical%TS_DELTAU_VERT_INPUT    = DELTAU_VERT_INPUT
      !VLIDORT_FixIn%Optical%TS_GREEKMAT_TOTAL_INPUT = GREEKMAT_TOTAL_INPUT
      VLIDORT_FixIn%Optical%TS_THERMAL_BB_INPUT     = THERMAL_BB_INPUT
      VLIDORT_FixIn%Optical%TS_LAMBERTIAN_ALBEDO    = LAMBERTIAN_ALBEDO
      VLIDORT_FixIn%Optical%TS_SURFACE_BB_INPUT     = SURFBB

!  Fixed Write inputs

      VLIDORT_FixIn%Write%TS_DO_DEBUG_WRITE          = DO_DEBUG_WRITE

      VLIDORT_FixIn%Write%TS_DO_WRITE_INPUT          = DO_WRITE_INPUT
      VLIDORT_FixIn%Write%TS_INPUT_WRITE_FILENAME    = INPUT_WRITE_FILENAME

      VLIDORT_FixIn%Write%TS_DO_WRITE_SCENARIO       = DO_WRITE_SCENARIO
      VLIDORT_FixIn%Write%TS_SCENARIO_WRITE_FILENAME = SCENARIO_WRITE_FILENAME

      VLIDORT_FixIn%Write%TS_DO_WRITE_FOURIER        = DO_WRITE_FOURIER
      VLIDORT_FixIn%Write%TS_FOURIER_WRITE_FILENAME  = FOURIER_WRITE_FILENAME

      VLIDORT_FixIn%Write%TS_DO_WRITE_RESULTS        = DO_WRITE_RESULTS
      VLIDORT_FixIn%Write%TS_RESULTS_WRITE_FILENAME  = RESULTS_WRITE_FILENAME

!  Modified Boolean inputs

      VLIDORT_ModIn%MBool%TS_DO_SSCORR_NADIR         = DO_SSCORR_NADIR
      VLIDORT_ModIn%MBool%TS_DO_SSCORR_OUTGOING      = DO_SSCORR_OUTGOING

      VLIDORT_ModIn%MBool%TS_DO_DOUBLE_CONVTEST      = DO_DOUBLE_CONVTEST
      VLIDORT_ModIn%MBool%TS_DO_SOLAR_SOURCES        = DO_SOLAR_SOURCES

      VLIDORT_ModIn%MBool%TS_DO_REFRACTIVE_GEOMETRY  = DO_REFRACTIVE_GEOMETRY
      VLIDORT_ModIn%MBool%TS_DO_CHAPMAN_FUNCTION     = DO_CHAPMAN_FUNCTION

      VLIDORT_ModIn%MBool%TS_DO_RAYLEIGH_ONLY        = DO_RAYLEIGH_ONLY
      !VLIDORT_ModIn%MBool%TS_DO_ISOTROPIC_ONLY       = DO_ISOTROPIC_ONLY
      !VLIDORT_ModIn%MBool%TS_DO_NO_AZIMUTH           = DO_NO_AZIMUTH
      !VLIDORT_ModIn%MBool%TS_DO_ALL_FOURIER          = DO_ALL_FOURIER

      VLIDORT_ModIn%MBool%TS_DO_DELTAM_SCALING       = DO_DELTAM_SCALING

      VLIDORT_ModIn%MBool%TS_DO_SOLUTION_SAVING      = DO_SOLUTION_SAVING
      VLIDORT_ModIn%MBool%TS_DO_BVP_TELESCOPING      = DO_BVP_TELESCOPING

      !VLIDORT_ModIn%MBool%TS_DO_USER_STREAMS         = DO_USER_STREAMS
      VLIDORT_ModIn%MBool%TS_DO_USER_VZANGLES        = DO_USER_VZANGLES

      VLIDORT_ModIn%MBool%TS_DO_ADDITIONAL_MVOUT     = DO_ADDITIONAL_MVOUT
      VLIDORT_ModIn%MBool%TS_DO_MVOUT_ONLY           = DO_MVOUT_ONLY

      VLIDORT_ModIn%MBool%TS_DO_THERMAL_TRANSONLY    = DO_THERMAL_TRANSONLY

      VLIDORT_ModIn%MBool%TS_DO_OBSERVATION_GEOMETRY = DO_OBSERVATION_GEOMETRY

!  Modified Control inputs

      VLIDORT_ModIn%MCont%TS_NGREEK_MOMENTS_INPUT = NGREEK_MOMENTS_INPUT

!  Modified Beam inputs

      !VLIDORT_ModIn%MSunRays%TS_NBEAMS      = NBEAMS
      VLIDORT_ModIn%MSunRays%TS_N_SZANGLES  = N_SZANGLES
      !VLIDORT_ModIn%MSunRays%TS_BEAM_SZAS   = BEAM_SZAS
      VLIDORT_ModIn%MSunRays%TS_SZANGLES    = SZANGLES

!  Modified User Value inputs

      VLIDORT_ModIn%MUserVal%TS_N_USER_RELAZMS      = N_USER_RELAZMS
      VLIDORT_ModIn%MUserVal%TS_USER_RELAZMS        = USER_RELAZMS

      !VLIDORT_ModIn%MUserVal%TS_N_USER_STREAMS      = N_USER_STREAMS
      VLIDORT_ModIn%MUserVal%TS_N_USER_VZANGLES     = N_USER_VZANGLES
      !VLIDORT_ModIn%MUserVal%TS_USER_ANGLES_INPUT   = USER_ANGLES
      VLIDORT_ModIn%MUserVal%TS_USER_VZANGLES_INPUT = USER_VZANGLES

      VLIDORT_ModIn%MUserVal%TS_USER_LEVELS         = USER_LEVELS

      VLIDORT_ModIn%MUserVal%TS_GEOMETRY_SPECHEIGHT = GEOMETRY_SPECHEIGHT

      VLIDORT_ModIn%MUserVal%TS_N_USER_OBSGEOMS     = N_USER_OBSGEOMS
      VLIDORT_ModIn%MUserVal%TS_USER_OBSGEOMS_INPUT = USER_OBSGEOMS

!  Modified Chapman Function inputs

      VLIDORT_ModIn%MChapman%TS_EARTH_RADIUS      = EARTH_RADIUS

!  Modified Optical inputs

      !VLIDORT_ModIn%MOptical%TS_OMEGA_TOTAL_INPUT    = OMEGA_TOTAL_INPUT

!  Exception handling

      VLIDORT_InputStatus%TS_STATUS_INPUTREAD = STATUS
      VLIDORT_InputStatus%TS_NINPUTMESSAGES   = NMESSAGES
      VLIDORT_InputStatus%TS_INPUTMESSAGES    = MESSAGES
      VLIDORT_InputStatus%TS_INPUTACTIONS     = ACTIONS

!  Return

      RETURN

!  Open file error
!  ---------------

300   CONTINUE
      STATUS = VLIDORT_SERIOUS
      NMESSAGES = NMESSAGES + 1
      MESSAGES(NMESSAGES) = &
             'openfile failure for '//FILNAM(1:LEN_STRING(FILNAM))
      ACTIONS(NMESSAGES)  = 'Find the Right File!!'
      CLOSE(FILUNIT)

      VLIDORT_InputStatus%TS_STATUS_INPUTREAD = STATUS
      VLIDORT_InputStatus%TS_NINPUTMESSAGES   = NMESSAGES
      VLIDORT_InputStatus%TS_INPUTMESSAGES    = MESSAGES
      VLIDORT_InputStatus%TS_INPUTACTIONS     = ACTIONS

!  Finish

      END SUBROUTINE VLIDORT_INPUT_MASTER

!

      SUBROUTINE VLIDORT_INIT_CONTROL_VARS ( &
        DO_FULLRAD_MODE, DO_SSCORR_NADIR, &
        DO_SSCORR_OUTGOING, DO_SSCORR_TRUNCATION, &
        DO_SS_EXTERNAL, DO_SSFULL, DO_DOUBLE_CONVTEST, &
        DO_PLANE_PARALLEL, DO_REFRACTIVE_GEOMETRY, &
        DO_CHAPMAN_FUNCTION, DO_RAYLEIGH_ONLY, &
        DO_DELTAM_SCALING, DO_SOLUTION_SAVING, &
        DO_BVP_TELESCOPING, DO_UPWELLING, &
        DO_DNWELLING, DO_QUAD_OUTPUT, &
        DO_USER_VZANGLES, DO_ADDITIONAL_MVOUT, &
        DO_MVOUT_ONLY, DO_DEBUG_WRITE, &
        DO_WRITE_INPUT, DO_WRITE_SCENARIO, &
        DO_WRITE_FOURIER, DO_WRITE_RESULTS, &
        DO_LAMBERTIAN_SURFACE, DO_OBSERVATION_GEOMETRY, &
        DO_SPECIALIST_OPTION_1, DO_SPECIALIST_OPTION_2, &
        DO_SPECIALIST_OPTION_3, DO_TOA_CONTRIBS, &
        DO_SURFACE_LEAVING, DO_SL_ISOTROPIC )

!  Initialises all control inputs for VLIDORT
!  ------------------------------------------

      USE VLIDORT_PARS

      IMPLICIT NONE

      LOGICAL, INTENT (OUT) ::             DO_FULLRAD_MODE
      LOGICAL, INTENT (OUT) ::             DO_SSCORR_NADIR
      LOGICAL, INTENT (OUT) ::             DO_SSCORR_OUTGOING
      LOGICAL, INTENT (OUT) ::             DO_SSCORR_TRUNCATION

!  New 15 March 2012
      LOGICAL, INTENT (OUT) ::             DO_SS_EXTERNAL

!  New 17 May 2012
      LOGICAL, INTENT (OUT) ::             DO_SURFACE_LEAVING
      LOGICAL, INTENT (OUT) ::             DO_SL_ISOTROPIC

      LOGICAL, INTENT (OUT) ::             DO_SSFULL
      LOGICAL, INTENT (OUT) ::             DO_DOUBLE_CONVTEST
      LOGICAL, INTENT (OUT) ::             DO_PLANE_PARALLEL
      LOGICAL, INTENT (OUT) ::             DO_REFRACTIVE_GEOMETRY
      LOGICAL, INTENT (OUT) ::             DO_CHAPMAN_FUNCTION
      LOGICAL, INTENT (OUT) ::             DO_RAYLEIGH_ONLY
      LOGICAL, INTENT (OUT) ::             DO_DELTAM_SCALING
      LOGICAL, INTENT (OUT) ::             DO_SOLUTION_SAVING
      LOGICAL, INTENT (OUT) ::             DO_BVP_TELESCOPING
      LOGICAL, INTENT (OUT) ::             DO_UPWELLING
      LOGICAL, INTENT (OUT) ::             DO_DNWELLING
      LOGICAL, INTENT (OUT) ::             DO_QUAD_OUTPUT
      LOGICAL, INTENT (OUT) ::             DO_USER_VZANGLES
      LOGICAL, INTENT (OUT) ::             DO_ADDITIONAL_MVOUT
      LOGICAL, INTENT (OUT) ::             DO_MVOUT_ONLY
      LOGICAL, INTENT (OUT) ::             DO_DEBUG_WRITE
      LOGICAL, INTENT (OUT) ::             DO_WRITE_INPUT
      LOGICAL, INTENT (OUT) ::             DO_WRITE_SCENARIO
      LOGICAL, INTENT (OUT) ::             DO_WRITE_FOURIER
      LOGICAL, INTENT (OUT) ::             DO_WRITE_RESULTS
      LOGICAL, INTENT (OUT) ::             DO_LAMBERTIAN_SURFACE
      LOGICAL, INTENT (OUT) ::             DO_OBSERVATION_GEOMETRY
      LOGICAL, INTENT (OUT) ::             DO_SPECIALIST_OPTION_1
      LOGICAL, INTENT (OUT) ::             DO_SPECIALIST_OPTION_2
      LOGICAL, INTENT (OUT) ::             DO_SPECIALIST_OPTION_3
      LOGICAL, INTENT (OUT) ::             DO_TOA_CONTRIBS

!  Mode calculations
!  -----------------

      DO_FULLRAD_MODE    = .FALSE.

!  Nadir single scatter correction (renamed).
!  Outgoing sphericity correction introduced, 31 January 2007.

      DO_SSCORR_NADIR    = .FALSE.
      DO_SSCORR_OUTGOING = .FALSE.

!  Additional deltam scaling for the single scatter corrections
!    Code added by R. Spurr, 07 September 2007

      DO_SSCORR_TRUNCATION = .FALSE.

!  External SS calculation - New 15 March 2012

      DO_SS_EXTERNAL     = .FALSE.

!  Surface leaving flags - New May 2012

      DO_SURFACE_LEAVING = .FALSE.
      DO_SL_ISOTROPIC    = .FALSE.

!  Full-up single scattering calculation

      DO_SSFULL          = .FALSE.

!  Convergence testing twice

      DO_DOUBLE_CONVTEST = .FALSE.

!  Solar beam options
!  ------------------

      DO_PLANE_PARALLEL      = .FALSE.
      DO_REFRACTIVE_GEOMETRY = .FALSE.
      DO_CHAPMAN_FUNCTION    = .FALSE.

!  Special options
!  ---------------

      DO_RAYLEIGH_ONLY  = .FALSE.

!  Do no azimuth relegated to a Bookkeeping variable
!      DO_NO_AZIMUTH      = .FALSE.
!  Isotropic only now been removed
!      DO_ISOTROPIC_ONLY = .FALSE.

!  Performance enhancements
!  ========================

!  Delta-M scaling now active version 2.

      DO_DELTAM_SCALING  = .FALSE.

!  New flags for version 2. RTSolutions 4/11/05

      DO_SOLUTION_SAVING = .FALSE.
      DO_BVP_TELESCOPING = .FALSE.

!  Write options
!  =============

      DO_DEBUG_WRITE       = .FALSE.
      DO_WRITE_INPUT       = .FALSE.
      DO_WRITE_RESULTS     = .FALSE.
      DO_WRITE_SCENARIO    = .FALSE.
      DO_WRITE_FOURIER     = .FALSE.

!  User-output options
!  -------------------

!  Initialize the Lambertian surface control

      DO_LAMBERTIAN_SURFACE = .FALSE.

!  Initialize the MV output flags

      DO_ADDITIONAL_MVOUT = .FALSE.
      DO_MVOUT_ONLY       = .FALSE.

!  User streams

      DO_USER_VZANGLES = .FALSE.

!  Upwelling and downwelling

      DO_UPWELLING = .FALSE.
      DO_DNWELLING = .FALSE.

!  Observation-Geometry input control

      DO_OBSERVATION_GEOMETRY = .FALSE.

!  Automatic settings in the bookkeeping routine

!      DO_DIRECT_BEAM        = .FALSE.
!      DO_CLASSICAL_SOLUTION = .FALSE.
!      DO_ALL_FOURIER        = .FALSE.

!  Specialist options. Should always be initialized here

      DO_SPECIALIST_OPTION_1 = .FALSE.
      DO_SPECIALIST_OPTION_2 = .FALSE.
      DO_SPECIALIST_OPTION_3 = .FALSE.

!  TOA contributions flag

      DO_TOA_CONTRIBS = .false.

!  Quadrature output is a debug flag only.

      DO_QUAD_OUTPUT  = .FALSE.

!  Finish

      RETURN
      END SUBROUTINE VLIDORT_INIT_CONTROL_VARS

!

      SUBROUTINE VLIDORT_INIT_THERMAL_VARS ( &
        DO_THERMAL_EMISSION, N_THERMAL_COEFFS, &
        THERMAL_BB_INPUT, DO_SURFACE_EMISSION, &
        SURFBB, DO_THERMAL_TRANSONLY )

      USE VLIDORT_PARS

      IMPLICIT NONE

      LOGICAL, INTENT (OUT) ::          DO_THERMAL_EMISSION
      INTEGER, INTENT (OUT) ::          N_THERMAL_COEFFS
      DOUBLE PRECISION, INTENT (OUT) :: THERMAL_BB_INPUT ( 0:MAXLAYERS )
      LOGICAL, INTENT (OUT) ::          DO_SURFACE_EMISSION
      DOUBLE PRECISION, INTENT (OUT) :: SURFBB
      LOGICAL, INTENT (OUT) ::          DO_THERMAL_TRANSONLY

!  Initialises all thermal inputs
!  ------------------------------

!  Local variables

      INTEGER ::            N

!  Initial emissivity control
!  ==========================

      DO_THERMAL_EMISSION = .FALSE.
      N_THERMAL_COEFFS = 0
      DO N = 0, MAXLAYERS
        THERMAL_BB_INPUT(N) = ZERO
      ENDDO

      DO_SURFACE_EMISSION = .FALSE.
      SURFBB    = ZERO

!  This flag introduced 31 July 2007 in LIDORT.

      DO_THERMAL_TRANSONLY = .FALSE.

!  Finish

      RETURN
      END SUBROUTINE VLIDORT_INIT_THERMAL_VARS

!

      SUBROUTINE VLIDORT_INIT_MODEL_VARS ( &
        NSTOKES, NSTREAMS, &
        NLAYERS, NFINELAYERS, &
        NGREEK_MOMENTS_INPUT, VLIDORT_ACCURACY, &
        FLUX_FACTOR, N_SZANGLES, &
        SZANGLES, EARTH_RADIUS, &
        RFINDEX_PARAMETER, GEOMETRY_SPECHEIGHT, &
        N_USER_RELAZMS, USER_RELAZMS, &
        N_USER_VZANGLES, USER_VZANGLES, &
        N_USER_LEVELS, USER_LEVELS, &
        N_USER_OBSGEOMS, USER_OBSGEOMS, &
        LAMBERTIAN_ALBEDO )

!  Initialises all file-read model inputs for VLIDORT
!  --------------------------------------------------

      USE VLIDORT_PARS

      IMPLICIT NONE

      INTEGER, INTENT (OUT) ::          NSTOKES
      INTEGER, INTENT (OUT) ::          NSTREAMS
      INTEGER, INTENT (OUT) ::          NLAYERS
      INTEGER, INTENT (OUT) ::          NFINELAYERS
      INTEGER, INTENT (OUT) ::          NGREEK_MOMENTS_INPUT
      DOUBLE PRECISION, INTENT (OUT) :: VLIDORT_ACCURACY
      DOUBLE PRECISION, INTENT (OUT) :: FLUX_FACTOR
      INTEGER, INTENT (OUT) ::          N_SZANGLES
      DOUBLE PRECISION, INTENT (OUT) :: SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (OUT) :: EARTH_RADIUS
      DOUBLE PRECISION, INTENT (OUT) :: RFINDEX_PARAMETER
      DOUBLE PRECISION, INTENT (OUT) :: GEOMETRY_SPECHEIGHT
      INTEGER, INTENT (OUT) ::          N_USER_RELAZMS
      DOUBLE PRECISION, INTENT (OUT) :: USER_RELAZMS  ( MAX_USER_RELAZMS )
      INTEGER, INTENT (OUT) ::          N_USER_VZANGLES
      DOUBLE PRECISION, INTENT (OUT) :: USER_VZANGLES ( MAX_USER_VZANGLES )
      INTEGER, INTENT (OUT) ::          N_USER_LEVELS
      DOUBLE PRECISION, INTENT (OUT) :: USER_LEVELS ( MAX_USER_LEVELS )
      INTEGER, INTENT (OUT) ::          N_USER_OBSGEOMS
      DOUBLE PRECISION, INTENT (OUT) :: USER_OBSGEOMS ( MAX_USER_OBSGEOMS, 3 )
      DOUBLE PRECISION, INTENT (OUT) :: LAMBERTIAN_ALBEDO

!  Local variables

      INTEGER ::            I

!  Basic integer inputs

      NSTOKES  = 0
      NSTREAMS = 0
      NLAYERS  = 0
      NFINELAYERS = 0

      NGREEK_MOMENTS_INPUT = 0

!  Accuracy. No more "zenith_tolerance"!

      VLIDORT_ACCURACY  = ZERO

!  Flux factor

      FLUX_FACTOR = ZERO

!  Solar beam (flux factor fixed to 1.0 in Bookkeeping, 17 January 2006)

      N_SZANGLES   = 0
      DO I = 1, MAX_SZANGLES
        SZANGLES(I) = ZERO
      ENDDO

!  Pseudo-spherical

      EARTH_RADIUS      = ZERO
      RFINDEX_PARAMETER = ZERO

!  Geometry specification height
!   (New, 06 August 2007)

      GEOMETRY_SPECHEIGHT = ZERO

!  Lambertian albedo

      LAMBERTIAN_ALBEDO = ZERO

!  User angles and levels

      N_USER_VZANGLES = 0
      N_USER_RELAZMS  = 0
      N_USER_LEVELS   = 0
      N_USER_OBSGEOMS = 0

      DO I = 1, MAX_USER_VZANGLES
        USER_VZANGLES(I) = ZERO
      ENDDO

      DO I = 1, MAX_USER_RELAZMS
        USER_RELAZMS(I) = ZERO
      ENDDO

      DO I = 1, MAX_USER_LEVELS
        USER_LEVELS(I) = ZERO
      ENDDO

      DO I = 1, MAX_USER_OBSGEOMS
        USER_OBSGEOMS(I,:) = ZERO
      ENDDO

! Finish

      RETURN
      END SUBROUTINE VLIDORT_INIT_MODEL_VARS

!

      SUBROUTINE VLIDORT_READ_INPUTS ( &
        DO_FULLRAD_MODE, DO_SSCORR_NADIR, &
        DO_SSCORR_OUTGOING, DO_SSCORR_TRUNCATION, &
        DO_SS_EXTERNAL, DO_SSFULL, DO_DOUBLE_CONVTEST, &
        DO_SOLAR_SOURCES, DO_PLANE_PARALLEL, &
        DO_REFRACTIVE_GEOMETRY, DO_CHAPMAN_FUNCTION, &
        DO_RAYLEIGH_ONLY, DO_DELTAM_SCALING, &
        DO_SOLUTION_SAVING, DO_BVP_TELESCOPING, &
        DO_UPWELLING, DO_DNWELLING, &
        DO_QUAD_OUTPUT, DO_USER_VZANGLES, &
        DO_SURFACE_LEAVING, DO_SL_ISOTROPIC,&
        DO_ADDITIONAL_MVOUT, DO_MVOUT_ONLY, &
        DO_OBSERVATION_GEOMETRY, &
        DO_DEBUG_WRITE, DO_WRITE_INPUT, &
        DO_WRITE_SCENARIO, DO_WRITE_FOURIER, &
        DO_WRITE_RESULTS, INPUT_WRITE_FILENAME, &
        SCENARIO_WRITE_FILENAME, FOURIER_WRITE_FILENAME, &
        RESULTS_WRITE_FILENAME, NSTOKES, &
        NSTREAMS, NLAYERS, &
        NFINELAYERS, NGREEK_MOMENTS_INPUT, &
        VLIDORT_ACCURACY, FLUX_FACTOR, &
        N_SZANGLES, SZANGLES, &
        EARTH_RADIUS, RFINDEX_PARAMETER, &
        GEOMETRY_SPECHEIGHT, N_USER_RELAZMS, &
        USER_RELAZMS, N_USER_VZANGLES, &
        USER_VZANGLES, N_USER_LEVELS, &
        USER_LEVELS, N_USER_OBSGEOMS, &
        USER_OBSGEOMS, DO_LAMBERTIAN_SURFACE, &
        LAMBERTIAN_ALBEDO, DO_THERMAL_EMISSION, &
        N_THERMAL_COEFFS, DO_SURFACE_EMISSION, &
        DO_THERMAL_TRANSONLY, &
        STATUS, NMESSAGES, MESSAGES, ACTIONS )

!  Read all control inputs for VLIDORT
!  -----------------------------------

      USE VLIDORT_PARS
      USE VLIDORT_AUX

      IMPLICIT NONE

      LOGICAL, INTENT (INOUT) ::             DO_FULLRAD_MODE
      LOGICAL, INTENT (INOUT) ::             DO_SSCORR_NADIR
      LOGICAL, INTENT (INOUT) ::             DO_SSCORR_OUTGOING
      LOGICAL, INTENT (INOUT) ::             DO_SSCORR_TRUNCATION

!  New 15 March 2012
      LOGICAL, INTENT (INOUT) ::             DO_SS_EXTERNAL

!  New 17 May 2012
      LOGICAL, INTENT (INOUT) ::             DO_SURFACE_LEAVING
      LOGICAL, INTENT (INOUT) ::             DO_SL_ISOTROPIC

      LOGICAL, INTENT (INOUT) ::             DO_SSFULL
      LOGICAL, INTENT (INOUT) ::             DO_DOUBLE_CONVTEST
      LOGICAL, INTENT (INOUT) ::             DO_SOLAR_SOURCES
      LOGICAL, INTENT (INOUT) ::             DO_PLANE_PARALLEL
      LOGICAL, INTENT (INOUT) ::             DO_REFRACTIVE_GEOMETRY
      LOGICAL, INTENT (INOUT) ::             DO_CHAPMAN_FUNCTION
      LOGICAL, INTENT (INOUT) ::             DO_RAYLEIGH_ONLY
      LOGICAL, INTENT (INOUT) ::             DO_DELTAM_SCALING
      LOGICAL, INTENT (INOUT) ::             DO_SOLUTION_SAVING
      LOGICAL, INTENT (INOUT) ::             DO_BVP_TELESCOPING
      LOGICAL, INTENT (INOUT) ::             DO_UPWELLING
      LOGICAL, INTENT (INOUT) ::             DO_DNWELLING
      LOGICAL, INTENT (INOUT) ::             DO_QUAD_OUTPUT
      LOGICAL, INTENT (INOUT) ::             DO_USER_VZANGLES
      LOGICAL, INTENT (INOUT) ::             DO_ADDITIONAL_MVOUT
      LOGICAL, INTENT (INOUT) ::             DO_MVOUT_ONLY
      LOGICAL, INTENT (INOUT) ::             DO_OBSERVATION_GEOMETRY
      LOGICAL, INTENT (INOUT) ::             DO_DEBUG_WRITE
      LOGICAL, INTENT (INOUT) ::             DO_WRITE_INPUT
      LOGICAL, INTENT (INOUT) ::             DO_WRITE_SCENARIO
      LOGICAL, INTENT (INOUT) ::             DO_WRITE_FOURIER
      LOGICAL, INTENT (INOUT) ::             DO_WRITE_RESULTS
      CHARACTER (LEN=60), INTENT (INOUT) ::  INPUT_WRITE_FILENAME
      CHARACTER (LEN=60), INTENT (INOUT) ::  SCENARIO_WRITE_FILENAME
      CHARACTER (LEN=60), INTENT (INOUT) ::  FOURIER_WRITE_FILENAME
      CHARACTER (LEN=60), INTENT (INOUT) ::  RESULTS_WRITE_FILENAME
      INTEGER, INTENT (INOUT) ::             NSTOKES
      INTEGER, INTENT (INOUT) ::             NSTREAMS
      INTEGER, INTENT (INOUT) ::             NLAYERS
      INTEGER, INTENT (INOUT) ::             NFINELAYERS
      INTEGER, INTENT (INOUT) ::             NGREEK_MOMENTS_INPUT
      DOUBLE PRECISION, INTENT (INOUT) ::    VLIDORT_ACCURACY
      DOUBLE PRECISION, INTENT (INOUT) ::    FLUX_FACTOR
      INTEGER, INTENT (INOUT) ::             N_SZANGLES
      DOUBLE PRECISION, INTENT (INOUT) ::    SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (INOUT) ::    EARTH_RADIUS
      DOUBLE PRECISION, INTENT (INOUT) ::    RFINDEX_PARAMETER
      DOUBLE PRECISION, INTENT (INOUT) ::    GEOMETRY_SPECHEIGHT
      INTEGER, INTENT (INOUT) ::             N_USER_RELAZMS
      DOUBLE PRECISION, INTENT (INOUT) ::    USER_RELAZMS  ( MAX_USER_RELAZMS )
      INTEGER, INTENT (INOUT) ::             N_USER_VZANGLES
      DOUBLE PRECISION, INTENT (INOUT) ::    USER_VZANGLES ( MAX_USER_VZANGLES )
      INTEGER, INTENT (INOUT) ::             N_USER_LEVELS
      DOUBLE PRECISION, INTENT (INOUT) ::    USER_LEVELS ( MAX_USER_LEVELS )
      INTEGER, INTENT (INOUT) ::             N_USER_OBSGEOMS
      DOUBLE PRECISION, INTENT (INOUT) ::    USER_OBSGEOMS ( MAX_USER_OBSGEOMS, 3 )
      LOGICAL, INTENT (INOUT) ::             DO_LAMBERTIAN_SURFACE
      DOUBLE PRECISION, INTENT (INOUT) ::    LAMBERTIAN_ALBEDO
      LOGICAL, INTENT (INOUT) ::             DO_THERMAL_EMISSION
      INTEGER, INTENT (INOUT) ::             N_THERMAL_COEFFS
      LOGICAL, INTENT (INOUT) ::             DO_SURFACE_EMISSION
      LOGICAL, INTENT (INOUT) ::             DO_THERMAL_TRANSONLY

      INTEGER, INTENT(OUT) ::                STATUS

      INTEGER, INTENT(INOUT) ::              NMESSAGES
      CHARACTER (LEN=*), INTENT(INOUT) ::    MESSAGES ( 0:MAX_MESSAGES )
      CHARACTER (LEN=*), INTENT(INOUT) ::    ACTIONS ( 0:MAX_MESSAGES )

!  Local variables
!  ---------------

      CHARACTER (LEN=9), PARAMETER :: &
        PREFIX = 'VLIDORT -'
      LOGICAL ::        ERROR
      CHARACTER (LEN=80) :: PAR_STR
!      LOGICAL         GFINDPAR
!      EXTERNAL        GFINDPAR
      INTEGER ::        I, FILUNIT, NM
!      EXTERNAL        LEN_STRING

!  Initialize status

      STATUS = VLIDORT_SUCCESS
      ERROR  = .FALSE.
      NM     = 0

!  These are already initialized in calling routine
!      MESSAGES(1:MAX_MESSAGES) = ' '
!      ACTIONS (1:MAX_MESSAGES) = ' '
!      NMESSAGES       = 0
!      MESSAGES(0)     = 'Successful Read of VLIDORT Input file'
!      ACTIONS(0)      = 'No Action required for this Task'

!  File unit

      FILUNIT = VLIDORT_INUNIT

!  1. read all CONTROL variables
!  =============================

!  Operation modes
!  ---------------

!  Full Stokes vector calculation

      PAR_STR = 'Do full Stokes vector calculation?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_FULLRAD_MODE
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Single scatter Corrections, calculations
!  ----------------------------------------

!  External single scatter correction. New 15 March 2012.

      PAR_STR = 'Do external single scatter correction?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SS_EXTERNAL
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Nadir single scatter correction

      PAR_STR = 'Do nadir single scatter correction?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SSCORR_NADIR
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Outgoing single scatter correction

      PAR_STR = 'Do outgoing single scatter correction?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SSCORR_OUTGOING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Full-up single scatter calculation

      PAR_STR = 'Do full-up single scatter calculation?'

      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SSFULL

      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Direct beam correction (BRDF options only)
!      PAR_STR = 'Do direct beam correction?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_DBCORRECTION
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Multiple scatter source function output control
!    Removed. 30 March 2007

!      PAR_STR = 'Output multiple scatter layer source functions?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) SAVE_LAYER_MSST
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Double convergence test

      PAR_STR = 'Do double convergence test?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_DOUBLE_CONVTEST
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Solar beam control
!  ------------------

!      PAR_STR = 'Include direct beam?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_DIRECT_BEAM
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Solution method (Classical only). Variable is set in DERIVE_INPUTS.

!      DO_CLASSICAL_SOLUTION = .TRUE.
!      PAR_STR = 'Use classical beam solution?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_CLASSICAL_SOLUTION
!      CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS )

!  Basic control

      PAR_STR = 'Use solar sources?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SOLAR_SOURCES
      CALL FINDPAR_ERROR &
      ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Other control options for the solar sources

      IF ( DO_SOLAR_SOURCES ) THEN

!  Pseudo-spherical control

        PAR_STR = 'Do plane-parallel treatment of direct beam?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_PLANE_PARALLEL
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Internal Chapman function calculation

        PAR_STR = 'Do internal Chapman function calculation?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_CHAPMAN_FUNCTION
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Refractive atmosphere

        PAR_STR = 'Do refractive geometry?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
            READ (FILUNIT,*,ERR=998) DO_REFRACTIVE_GEOMETRY
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  End control

      ENDIF

!  Numerical control (azimuth series)
!  ----------------------------------

!  Scatterers and phase function control

      PAR_STR='Do Rayleigh atmosphere only?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_RAYLEIGH_ONLY
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  START

!  Surface Leaving control (New 17 May 2012)
!  -----------------------

!  Basic control

      PAR_STR = 'Do surface-leaving term?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SURFACE_LEAVING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Isotropic control

      IF ( DO_SURFACE_LEAVING ) THEN
         PAR_STR = 'Do isotropic surface-leaving term?'
         IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) DO_SL_ISOTROPIC
         CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   END

!  New flag, Observational Geometry
!   Added, 25 October 12

      IF ( DO_SOLAR_SOURCES ) THEN
         PAR_STR = 'Do Observation Geometry?'
         IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
              READ (FILUNIT,*,ERR=998) DO_OBSERVATION_GEOMETRY
         CALL FINDPAR_ERROR &
           ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Removed isotropic-only option, 17 January 2006.
!      PAR_STR='Isotropic atmosphere only?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_ISOTROPIC_ONLY
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  No azimuth dependence (TRUE means Fourier m = 0 only )
!    Removed. Now this is a bookkeeping variable.
!    17 January 2006.
!      PAR_STR = 'No azimuth dependence in the solution?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_NO_AZIMUTH
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  All possible Fourier components (2N-1). Debug only
!      PAR_STR = 'Compute all Fourier components?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_ALL_FOURIER
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Performance control
!  -------------------

!  Delta-M scaling

!  Should only be set for solar beam sources

      IF ( DO_SOLAR_SOURCES ) THEN
       PAR_STR = 'Do delta-M scaling?'
       IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_DELTAM_SCALING
       CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Additional deltam scaling for either single-scatter corrections

      IF ( DO_SSCORR_NADIR.OR.DO_SSCORR_OUTGOING.OR.DO_SSFULL )  THEN
        PAR_STR = 'Do delta-M scaling on single scatter corrections?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SSCORR_TRUNCATION
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Solution saving mode.
!    New code, RJDS, RT Solutions, Inc. 4/11/05.

      PAR_STR = 'Do solution saving?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SOLUTION_SAVING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Boundary value problem (BVP) telescope mode.
!    New code, RJDS, RT Solutions, Inc. 4/11/05.

      PAR_STR = 'Do boundary-value telescoping?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_BVP_TELESCOPING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  User-defined output control
!  ---------------------------

!  Directional output control

      PAR_STR = 'Do upwelling output?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_UPWELLING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Do downwelling output?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_DNWELLING
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Stream angle and optical depth output control

!      PAR_STR = 'Include quadrature angles in output?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) DO_QUAD_OUTPUT
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Use user-defined viewing zenith angles?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
         READ (FILUNIT,*,ERR=998) DO_USER_VZANGLES
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Old code, version 2.3 and earlier............
!      PAR_STR = 'User-defined optical depths?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &   READ (FILUNIT,*,ERR=998) DO_USER_TAUS
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!      PAR_STR = 'Layer boundary optical depths?'
!      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &   READ (FILUNIT,*,ERR=998) DO_LBOUND_TAUS
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Mean-value output control

      PAR_STR = 'Do mean-value output additionally?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_ADDITIONAL_MVOUT
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Do only mean-value output?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_MVOUT_ONLY
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Write control
!  -------------

!  Output write flags

      PAR_STR = 'Do debug write?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_DEBUG_WRITE
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Do input control write?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_WRITE_INPUT
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Do input scenario write?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_WRITE_SCENARIO
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Do Fourier component output write?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_WRITE_FOURIER
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'DO results write?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_WRITE_RESULTS
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Output filenames

      PAR_STR = 'filename for input write'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,'(a)',ERR=998) INPUT_WRITE_FILENAME
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'filename for scenario write'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,'(a)',ERR=998) SCENARIO_WRITE_FILENAME
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'filename for Fourier output write'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,'(a)',ERR=998) FOURIER_WRITE_FILENAME
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'filename for main output'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,'(a)',ERR=998) RESULTS_WRITE_FILENAME
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  2. Read all model variables
!  ===========================

!  Stokes/streams/layers/moments (INTEGER input)

      PAR_STR = 'Number of Stokes vector components'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) NSTOKES
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Number of half-space streams'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) NSTREAMS
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      PAR_STR = 'Number of atmospheric layers'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) NLAYERS
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      IF ( DO_SSCORR_OUTGOING .OR. DO_SSFULL ) THEN
        PAR_STR = &
         'Number of fine layers (outgoing sphericity option only)'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) NFINELAYERS
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

      PAR_STR = 'Number of scattering matrix expansion coefficients'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) NGREEK_MOMENTS_INPUT
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  All numbers are now checked against maximum diensions
!  -----------------------------------------------------

!  New Exception handling code, 13 OCTOBER 2010

      IF ( NSTREAMS .GT. MAXSTREAMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
               'Entry under "Number of half-space streams" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
             'Re-set input value or increase MAXSTREAMS dimension '// &
             'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( NLAYERS .GT. MAXLAYERS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
               'Entry under "Number of atmospheric layers" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
             'Re-set input value or increase MAXLAYERS dimension '// &
             'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( DO_SSCORR_OUTGOING .or. DO_SSFULL ) THEN
        IF ( NFINELAYERS .GT. MAXFINELAYERS ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
               'Entry under "Number of fine layers..." >'// &
               ' allowed Maximum dimension'
          ACTIONS(NM)  = &
            'Re-set input value or increase MAXFINELAYERS dimension '// &
            'in VLIDORT_PARS'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          RETURN
        ENDIF
      ENDIF

      IF ( NGREEK_MOMENTS_INPUT .GT. MAXMOMENTS_INPUT ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
         'Entry under'// &
       ' "Number of input Scattering Matrix expansion coefficients" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
         'Re-set input value or increase MAXMOMENTS_INPUT dimension '// &
            'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( NSTOKES .GT. MAXSTOKES ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
         'Entry under'//' "Number of Stokes parameters" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = 'Re-set input value to 4 or less'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

!  Accuracy input
!  --------------

      PAR_STR = 'Fourier series convergence'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) VLIDORT_ACCURACY
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Zenith tolerance level. Now removed. 17 January 2006.

!  Flux constant. Should be set to 1 if no solar sources.
!   Formerly a Book-keeping variable set to 1 in "derive inputs"
!   Now (July 2009) allowed to vary because of thermal emission
!   Must take physical values if using solar + thermal.

      IF ( DO_SOLAR_SOURCES ) THEN
        PAR_STR = 'Solar flux constant'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) FLUX_FACTOR
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ELSE
        FLUX_FACTOR = 1.0d0
      ENDIF

!  Note the following possibility (not yet allowed for)
!        PAR_STR = 'TOA flux vector'
!        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR))
!     &     READ (FILUNIT,*,ERR=998) (FLUXVEC(I),I=1,MAXSTOKES)
!      CALL FINDPAR_ERROR
!     &  ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Geometry inputs
!  ---------------

!  Observational Geometry control
!   New, 25 October 2012
!     ---- check not exceeding dimensioned number

      IF ( DO_OBSERVATION_GEOMETRY ) THEN
        PAR_STR = 'Number of Observation Geometry inputs'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) N_USER_OBSGEOMS
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
        IF ( N_USER_OBSGEOMS .GT. MAX_USER_OBSGEOMS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Entry under "Number of Obsevation Geometry inputs" > allowed Maximum dimension'
          ACTIONS(NM)  = 'Re-set input value or increase MAX_USER_OBSGEOMS dimension in LIDORT_PARS'
          STATUS       = VLIDORT_SERIOUS
          NMESSAGES    = NM
          RETURN
        ENDIF
      ENDIF

      IF ( DO_OBSERVATION_GEOMETRY ) THEN

!  Observational Geometry control
!   New, 25 October 2012
!     ---- Automatic setting of N_SZANGLES, N_USER_VZANGLES, N_USER_RELAZMS,
!          and DO_USER_VZANGLES

        N_SZANGLES       = N_USER_OBSGEOMS
        N_USER_VZANGLES  = N_USER_OBSGEOMS
        N_USER_RELAZMS   = N_USER_OBSGEOMS
        DO_USER_VZANGLES = .true.

!  Observational Geometry inputs

        PAR_STR = 'Observation Geometry inputs'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
           DO I = 1, N_USER_OBSGEOMS
             READ (FILUNIT,*,ERR=998) USER_OBSGEOMS(I,1), USER_OBSGEOMS(I,2), USER_OBSGEOMS(I,3)
           ENDDO
        ENDIF
        CALL FINDPAR_ERROR ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!     ---- Automatic setting of SZANGLES, USER_VZANGLES, and USER_RELAZMS

        SZANGLES     (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,1)
        USER_VZANGLES(1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,2)
        USER_RELAZMS (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,3)

!     ---- Skip other geometry input reads

        GO TO 5665
      ENDIF

!  Solar zenith angles
!  -------------------

!  Number of Solar zenith angles

      PAR_STR = 'Number of solar zenith angles'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) N_SZANGLES
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check not exceeding dimensioned number

      IF ( N_SZANGLES .GT. MAX_SZANGLES ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
            'Entry under "Number of solar zenith angles" >'// &
            ' allowed Maximum dimension'
        ACTIONS(NM)  = &
            'Re-set input value or increase MAX_SZANGLES dimension '// &
            'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

!  BOA solar zenith angle inputs

      PAR_STR = 'Solar zenith angles (degrees)'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
        DO I = 1, N_SZANGLES
          READ (FILUNIT,*,ERR=998) SZANGLES(I)
        ENDDO
      ENDIF
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  User defined output control
!  ---------------------------

!  1.  Azimuthal input values

!  Number of azimuths

      PAR_STR = 'Number of user-defined relative azimuth angles'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) N_USER_RELAZMS
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check dimensioning for number of azimuths

      IF ( N_USER_RELAZMS .GT. MAX_USER_RELAZMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
             'Entry under "Number of ..... azimuth angles" >'// &
             ' allowed Maximum dimension'
        ACTIONS(NM)  = &
          'Re-set input value or increase MAX_USER_RELAZMS dimension '// &
          'in VLIDORT_PARS'
        STATUS       = VLIDORT_SERIOUS
        NMESSAGES    = NM
        RETURN
      ENDIF

!  Read in azimuths

      PAR_STR = 'User-defined relative azimuth angles (degrees)'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
        DO I = 1, N_USER_RELAZMS
          READ (FILUNIT,*,ERR=998) USER_RELAZMS(I)
        ENDDO
      ENDIF
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  2. User defined viewing zenith angles (should be positive)
!       ( Number, check dimension, values)

      IF ( DO_USER_VZANGLES ) THEN

        PAR_STR = 'Number of user-defined viewing zenith angles'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) N_USER_VZANGLES
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check dimensioning

        IF ( N_USER_VZANGLES .GT. MAX_USER_VZANGLES ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'Entry under "Number of .....viewing zenith angles" >'// &
             ' allowed Maximum dimension'
          ACTIONS(NM)  = &
        'Re-set input value or increase MAX_USER_VZANGLES dimension '// &
          'in VLIDORT_PARS'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          RETURN
        ENDIF

        PAR_STR = 'User-defined viewing zenith angles (degrees)'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
          DO I = 1, N_USER_VZANGLES
            READ (FILUNIT,*,ERR=998) USER_VZANGLES(I)
          ENDDO
        ENDIF
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      ENDIF

!  Continuation point for skipping normal geometry input reads

5665 CONTINUE

!  Input Geometry specfication height

      IF ( DO_SSCORR_OUTGOING ) THEN
        PAR_STR = 'Input geometry specification height (km)'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) GEOMETRY_SPECHEIGHT
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Pseudo-spherical inputs
!  -----------------------

! (only for Chapman function calculation)

      IF ( DO_CHAPMAN_FUNCTION ) THEN

        PAR_STR = 'Earth radius (km)'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) EARTH_RADIUS
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

        IF ( DO_REFRACTIVE_GEOMETRY ) THEN
          PAR_STR = 'Refractive index parameter'
          IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
               READ (FILUNIT,*,ERR=998) RFINDEX_PARAMETER
          CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
        ENDIF

      ENDIF

!  3. User defined level output   *** NEW SECTION ***
!  ============================

!  This is designed to ensure that output is not related to optical
!  depth (which is wavelength-dependent); we use a height-based system.

!  User defined boundary (whole layer) and off-boundary (partial layer)
!  output choices are specified as follows.
!       USER_LEVELS(1) = 0.0    Top of the first layer
!       USER_LEVELS(2) = 1.0    Bottom of the first layer
!       USER_LEVELS(3) = 17.49  Output is in Layer 18, at a distance of
!                               0.49 of the way down from top (in height

!    -- Number is checked now, to see if exceeds dimensioning

      PAR_STR = 'Number of user-defined output levels'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
              READ (FILUNIT,*,ERR=998) N_USER_LEVELS
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Check dimensioning

      IF ( N_USER_LEVELS .GT. MAX_USER_LEVELS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
             'Entry under "Number of ..... output levels" >'// &
             ' allowed Maximum dimension'
          ACTIONS(NM)  = &
          'Re-set input value or increase MAX_USER_LEVELS dimension '// &
          'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      PAR_STR = 'User-defined output levels'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) THEN
        DO I = 1, N_USER_LEVELS
          READ (FILUNIT,*,ERR=998) USER_LEVELS(I)
        ENDDO
      ENDIF
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  4. read all surface variables
!  =============================

!  Lambertian surface

      PAR_STR = 'Do Lambertian surface?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_LAMBERTIAN_SURFACE
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

      IF ( DO_LAMBERTIAN_SURFACE ) THEN
        PAR_STR = 'Lambertian albedo'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
             READ (FILUNIT,*,ERR=998) LAMBERTIAN_ALBEDO
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  BRDF input Handled through the Supplement
!    Version 2.4RTC Consolidation.............!!!!!!!!!!!!!!!!!!

!  5. read all thermal emission input variables
!  ============================================

!  Thermal controls

      PAR_STR = 'Do thermal emission?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_THERMAL_EMISSION
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Thermal control, transmittance only

      IF ( DO_THERMAL_EMISSION ) THEN
        PAR_STR = 'Do thermal emission, transmittance only?'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_THERMAL_TRANSONLY
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )
      ENDIF

!  Number of coefficients (includes a dimensioning check)

      IF ( DO_THERMAL_EMISSION ) THEN

        PAR_STR = 'Number of thermal coefficients'
        IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) N_THERMAL_COEFFS
        CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

        IF ( N_THERMAL_COEFFS .GT. MAX_THERMAL_COEFFS ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'Entry under "Number of thermal coefficients" >'// &
             ' allowed Maximum dimension'
            ACTIONS(NM)  = &
       'Re-set input value or increase MAX_THERMAL_COEFFS dimension '// &
          'in VLIDORT_PARS'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          RETURN
        ENDIF

      ENDIF

!  Surface emission control

      PAR_STR = 'Do surface emission?'
      IF (GFINDPAR ( FILUNIT, PREFIX, ERROR, PAR_STR)) &
           READ (FILUNIT,*,ERR=998) DO_SURFACE_EMISSION
      CALL FINDPAR_ERROR &
        ( ERROR, PAR_STR, STATUS, NM, MESSAGES, ACTIONS )

!  Normal return

!mick fix
      NMESSAGES = NM

      RETURN

!  Line read error - abort immediately

998   CONTINUE
      NM = NM + 1
      STATUS       = VLIDORT_SERIOUS
      MESSAGES(NM) = 'Read failure for entry below String: ' &
              //PAR_STR(1:LEN_STRING(PAR_STR))
      ACTIONS(NM)  = &
                 'Re-set value: Entry wrongly formatted in Input file'
      NMESSAGES    = NM

!  Finish

      RETURN
      END SUBROUTINE VLIDORT_READ_INPUTS

!

      SUBROUTINE VLIDORT_CHECK_INPUT ( &
        DO_SSFULL, DO_PLANE_PARALLEL, &
        DO_UPWELLING, DO_DNWELLING, &
        DO_QUAD_OUTPUT, DO_ADDITIONAL_MVOUT, &
        DO_MVOUT_ONLY, NSTOKES, &
        NSTREAMS, NLAYERS, &
        NFINELAYERS, N_USER_LEVELS, &
        HEIGHT_GRID, OMEGA_TOTAL_INPUT, &
        GREEKMAT_TOTAL_INPUT, DO_LAMBERTIAN_SURFACE, &
        DO_THERMAL_EMISSION, &
        DO_SPECIALIST_OPTION_2, DO_SPECIALIST_OPTION_3, &
        NLAYERS_NOMS, NLAYERS_CUTOFF, &
        DO_TOA_CONTRIBS, DO_NO_AZIMUTH, DO_SS_EXTERNAL, &
        DO_SSCORR_NADIR, DO_SSCORR_OUTGOING, &
        DO_SOLAR_SOURCES, DO_REFRACTIVE_GEOMETRY, &
        DO_CHAPMAN_FUNCTION, DO_RAYLEIGH_ONLY, &
        DO_DELTAM_SCALING, DO_SOLUTION_SAVING, &
        DO_BVP_TELESCOPING, DO_USER_VZANGLES, &
        DO_OBSERVATION_GEOMETRY, &
        NGREEK_MOMENTS_INPUT, N_SZANGLES, SZANGLES, &
        EARTH_RADIUS, GEOMETRY_SPECHEIGHT, &
        N_USER_RELAZMS, USER_RELAZMS, &
        N_USER_VZANGLES, USER_VZANGLES, &
        USER_LEVELS, &
        N_USER_OBSGEOMS, USER_OBSGEOMS, &
        DO_THERMAL_TRANSONLY, DO_ALL_FOURIER, &
        DO_DIRECT_BEAM, DO_CLASSICAL_SOLUTION, &
        N_OUT_STREAMS, OUT_ANGLES, &
        STATUS, NMESSAGES, MESSAGES, ACTIONS )

      USE VLIDORT_PARS
      USE VLIDORT_AUX

      IMPLICIT NONE

      LOGICAL, INTENT (IN) ::             DO_SSFULL
      LOGICAL, INTENT (IN) ::             DO_PLANE_PARALLEL
      LOGICAL, INTENT (IN) ::             DO_UPWELLING
      LOGICAL, INTENT (IN) ::             DO_DNWELLING
      LOGICAL, INTENT (IN) ::             DO_QUAD_OUTPUT
      LOGICAL, INTENT (IN) ::             DO_ADDITIONAL_MVOUT
      INTEGER, INTENT (IN) ::             NSTOKES
      INTEGER, INTENT (IN) ::             NSTREAMS
      INTEGER, INTENT (IN) ::             NLAYERS
      INTEGER, INTENT (IN) ::             NFINELAYERS
      INTEGER, INTENT (IN) ::             N_USER_LEVELS
      DOUBLE PRECISION, INTENT (IN) ::    HEIGHT_GRID ( 0:MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::    OMEGA_TOTAL_INPUT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::    GREEKMAT_TOTAL_INPUT &
          ( 0:MAXMOMENTS_INPUT, MAXLAYERS, MAXSTOKES_SQ )
      LOGICAL, INTENT (IN) ::             DO_LAMBERTIAN_SURFACE
      LOGICAL, INTENT (IN) ::             DO_THERMAL_EMISSION
      LOGICAL, INTENT (IN) ::             DO_SPECIALIST_OPTION_2
      LOGICAL, INTENT (IN) ::             DO_SPECIALIST_OPTION_3
      INTEGER, INTENT (IN) ::             NLAYERS_NOMS
      INTEGER, INTENT (IN) ::             NLAYERS_CUTOFF
      LOGICAL, INTENT (IN) ::             DO_TOA_CONTRIBS
      LOGICAL, INTENT (IN) ::             DO_NO_AZIMUTH
!  New 15 March 2012
      LOGICAL, INTENT (IN) ::             DO_SS_EXTERNAL

      LOGICAL, INTENT (INOUT) ::          DO_SSCORR_NADIR
      LOGICAL, INTENT (INOUT) ::          DO_SSCORR_OUTGOING
      LOGICAL, INTENT (INOUT) ::          DO_SOLAR_SOURCES
      LOGICAL, INTENT (INOUT) ::          DO_REFRACTIVE_GEOMETRY
      LOGICAL, INTENT (INOUT) ::          DO_CHAPMAN_FUNCTION
      LOGICAL, INTENT (INOUT) ::          DO_RAYLEIGH_ONLY
      LOGICAL, INTENT (INOUT) ::          DO_DELTAM_SCALING
      LOGICAL, INTENT (INOUT) ::          DO_SOLUTION_SAVING
      LOGICAL, INTENT (INOUT) ::          DO_MVOUT_ONLY
      LOGICAL, INTENT (INOUT) ::          DO_BVP_TELESCOPING
      LOGICAL, INTENT (INOUT) ::          DO_USER_VZANGLES
      LOGICAL, INTENT (INOUT) ::          DO_OBSERVATION_GEOMETRY
      INTEGER, INTENT (INOUT) ::          NGREEK_MOMENTS_INPUT
      INTEGER, INTENT (INOUT) ::          N_SZANGLES
      DOUBLE PRECISION, INTENT (INOUT) :: SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (INOUT) :: EARTH_RADIUS
      DOUBLE PRECISION, INTENT (INOUT) :: GEOMETRY_SPECHEIGHT
      INTEGER, INTENT (INOUT) ::          N_USER_RELAZMS
      DOUBLE PRECISION, INTENT (INOUT) :: USER_RELAZMS  ( MAX_USER_RELAZMS )
      INTEGER, INTENT (INOUT) ::          N_USER_VZANGLES
      DOUBLE PRECISION, INTENT (INOUT) :: USER_VZANGLES ( MAX_USER_VZANGLES )
      DOUBLE PRECISION, INTENT (INOUT) :: USER_LEVELS ( MAX_USER_LEVELS )
      INTEGER, INTENT (IN) ::             N_USER_OBSGEOMS
      DOUBLE PRECISION, INTENT (IN) ::    USER_OBSGEOMS ( MAX_USER_OBSGEOMS, 3 )
      LOGICAL, INTENT (INOUT) ::          DO_THERMAL_TRANSONLY

      LOGICAL, INTENT (OUT) ::            DO_ALL_FOURIER
      LOGICAL, INTENT (OUT) ::            DO_DIRECT_BEAM
      LOGICAL, INTENT (OUT) ::            DO_CLASSICAL_SOLUTION
      INTEGER, INTENT (OUT) ::            N_OUT_STREAMS
      DOUBLE PRECISION, INTENT (OUT) ::   OUT_ANGLES ( MAX_USER_STREAMS )
      INTEGER, INTENT (OUT) ::            STATUS
      INTEGER, INTENT (OUT) ::            NMESSAGES
      CHARACTER (LEN=*), INTENT (OUT) ::  MESSAGES ( 0:MAX_MESSAGES )
      CHARACTER (LEN=*), INTENT (OUT) ::  ACTIONS ( 0:MAX_MESSAGES )

!  Local variables
!  ---------------

      INTEGER ::           I, L, N, UTA, NSTART, NALLSTREAMS, NM
      INTEGER ::           INDEX_ANGLES ( MAX_USER_STREAMS )
      DOUBLE PRECISION  :: XT, ALL_ANGLES ( MAX_USER_STREAMS )
      CHARACTER (LEN=3) :: C3
      CHARACTER (LEN=2) :: C2
      LOGICAL ::           LOOP

!  Initialize output status

      STATUS = VLIDORT_SUCCESS
      MESSAGES(1:MAX_MESSAGES) = ' '
      ACTIONS (1:MAX_MESSAGES) = ' '

      NMESSAGES       = 0
      MESSAGES(0)     = 'Successful Check of VLIDORT Basic Input'
      ACTIONS(0)      = 'No Action required for this Task'

      NM = NMESSAGES

!  Automatic input
!    Flux factor set to unity. (21 December 2005)

      DO_ALL_FOURIER        = .FALSE.
      DO_CLASSICAL_SOLUTION = .TRUE.
      DO_DIRECT_BEAM        = .TRUE.

!  New code for the Observational Geometry
!  ---------------------------------------

      IF ( DO_OBSERVATION_GEOMETRY ) THEN

        IF ( .NOT.DO_SOLAR_SOURCES ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Bad input: DO_SOLAR_SOURCES not set for Observation Geometry option'
          ACTIONS(NM)  = &
            'Abort: must set DO_SOLAR_SOURCE'
          STATUS = VLIDORT_SERIOUS
        ENDIF

        IF ( DO_THERMAL_EMISSION ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Bad input: DO_THERMAL_EMISSION should not be set for Observation Geometry option'
          ACTIONS(NM)  = &
            'Abort: must turn off DO_THERMAL EMISSION'
          STATUS = VLIDORT_SERIOUS
        ENDIF

!  Very important numbers check

        IF ( N_USER_OBSGEOMS .GT. MAX_USER_OBSGEOMS ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Number of Observation Geometries > maximum dimension'
          ACTIONS(NM)  = 'Re-set input value or increase MAX_USER_OBSGEOMS dimension'
          STATUS       = VLIDORT_SERIOUS
          NMESSAGES    = NM
          RETURN
        ENDIF

!  Observational Geometry control
!   New, 25 October 2012
!     ---- Automatic setting of N_SZANGLES, N_USER_VZANGLES, N_USER_RELAZMS,
!          and DO_USER_VZANGLES

        N_SZANGLES       = N_USER_OBSGEOMS
        N_USER_VZANGLES  = N_USER_OBSGEOMS
        N_USER_RELAZMS   = N_USER_OBSGEOMS
        DO_USER_VZANGLES = .true.

!     ---- Automatic setting of SZANGLES, USER_VZANGLES, and USER_RELAZMS

        SZANGLES     (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,1)
        USER_VZANGLES(1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,2)
        USER_RELAZMS (1:N_USER_OBSGEOMS) = USER_OBSGEOMS(1:N_USER_OBSGEOMS,3)

      ENDIF

!  All numbers are now checked against maximum dimensions
!  ------------------------------------------------------

!  New Exception handling code, 13 OCTOBER 2010

      IF ( NSTREAMS .GT. MAXSTREAMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
               'Entry under "Number of half-space streams" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
             'Re-set input value or increase MAXSTREAMS dimension '// &
             'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( NLAYERS .GT. MAXLAYERS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
               'Entry under "Number of atmospheric layers" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
             'Re-set input value or increase MAXLAYERS dimension '// &
             'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( DO_SSCORR_OUTGOING .or. DO_SSFULL ) THEN
        IF ( NFINELAYERS .GT. MAXFINELAYERS ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
               'Entry under "Number of fine layers..." >'// &
               ' allowed Maximum dimension'
          ACTIONS(NM)  = &
            'Re-set input value or increase MAXFINELAYERS dimension '// &
            'in VLIDORT_PARS'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          RETURN
        ENDIF
      ENDIF

      IF ( NGREEK_MOMENTS_INPUT .GT. MAXMOMENTS_INPUT ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
         'Entry under'// &
       ' "Number of input Scattering Matrix expansion coefficients" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
         'Re-set input value or increase MAXMOMENTS_INPUT dimension '// &
            'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( NSTOKES .GT. MAXSTOKES ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
         'Entry under'//' "Number of Stokes parameters" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = 'Re-set input value to 4 or less'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

!  Check dimensioning for SZA/AZM/VZA/LEVELS

      IF ( N_SZANGLES .GT. MAX_SZANGLES ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
               'Entry under "Number of solar zenith angles" >'// &
               ' allowed Maximum dimension'
        ACTIONS(NM)  = &
            'Re-set input value or increase MAX_SZANGLES dimension '// &
            'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

      IF ( N_USER_RELAZMS .GT. MAX_USER_RELAZMS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
             'Entry under "Number of ..... azimuth angles" >'// &
             ' allowed Maximum dimension'
        ACTIONS(NM)  = &
          'Re-set input value or increase MAX_USER_RELAZMS dimension '// &
          'in VLIDORT_PARS'
        STATUS       = VLIDORT_SERIOUS
        NMESSAGES    = NM
        RETURN
      ENDIF

      IF ( DO_USER_VZANGLES ) THEN
        IF ( N_USER_VZANGLES .GT. MAX_USER_VZANGLES ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'Entry under "Number of .....viewing zenith angles" >'// &
             ' allowed Maximum dimension'
          ACTIONS(NM)  = &
          'Re-set input value or increase MAX_USER_VZANGLES dimension '// &
          'in VLIDORT_PARS'
          STATUS = VLIDORT_SERIOUS
          NMESSAGES = NM
          RETURN
        ENDIF
      ENDIF

      IF ( N_USER_LEVELS .GT. MAX_USER_LEVELS ) THEN
        NM = NM + 1
        MESSAGES(NM) = &
             'Entry under "Number of ..... output levels" >'// &
             ' allowed Maximum dimension'
        ACTIONS(NM)  = &
          'Re-set input value or increase MAX_USER_LEVELS dimension '// &
          'in VLIDORT_PARS'
        STATUS = VLIDORT_SERIOUS
        NMESSAGES = NM
        RETURN
      ENDIF

!  Check top level options Solar/Thermal, set warnings
!  ---------------------------------------------------

!  Check thermal or Solar sources present

      IF ( .NOT.DO_SOLAR_SOURCES.AND..NOT.DO_THERMAL_EMISSION ) THEN
        NM = NM + 1
        MESSAGES(NM) = 'Bad input: No solar or thermal sources'
        ACTIONS(NM)  = 'Abort: must set one of the source flags!'
        STATUS = VLIDORT_SERIOUS
      ENDIF

!  Switch off several flags with thermal-only option
!    Set default, regardless of whether solar sources are on.

      IF ( .NOT.DO_SOLAR_SOURCES.AND.DO_THERMAL_EMISSION ) THEN
       IF ( DO_SSCORR_NADIR ) THEN
         NM = NM + 1
         MESSAGES(NM) = &
           'Switch off SS correction, not needed for thermal-only'
         ACTIONS(NM) = &
           'Warning: SS correction flag turned off internally'
         STATUS = VLIDORT_WARNING
         DO_SSCORR_NADIR = .FALSE.
        ENDIF
      ENDIF

!  Set number of sources NBEAMS to 1 for the thermal-only default

      IF ( .NOT.DO_SOLAR_SOURCES.AND.DO_THERMAL_EMISSION ) THEN
        IF ( N_SZANGLES .NE. 1 ) THEN
         NM = NM + 1
         MESSAGES(NM) = 'Bad input: N_Szas set to 1 for thermal-only'
         ACTIONS(NM) = 'Warning: N_Szas set to 1 internally'
         STATUS = VLIDORT_WARNING
         N_SZANGLES = 1
        ENDIF
      ENDIF

!  Set number of sources NBEAMS to 1 for the thermal-only default

      IF ( .NOT.DO_SOLAR_SOURCES.AND.DO_THERMAL_EMISSION ) THEN
        IF ( N_USER_RELAZMS .NE. 1 ) THEN
         NM = NM + 1
         MESSAGES(NM) = &
              'Bad input: N_AZIMUTHS set to 1 for thermal-only'
         ACTIONS(NM) = &
               'Warning: N_USER_RELAZMS set to 1 internally'
         STATUS = VLIDORT_WARNING
         N_USER_RELAZMS = 1
        ENDIF
      ENDIF

!  Check inputs (both file-read and derived)
!  -----------------------------------------

!  Check Chapman function options

      IF ( DO_SOLAR_SOURCES ) THEN
       IF ( .NOT. DO_CHAPMAN_FUNCTION ) THEN
        IF ( DO_PLANE_PARALLEL ) THEN
          NM = NM + 1
          MESSAGES(NM)   = 'Chapman Function not set, plane parallel'
          ACTIONS(NM) = 'Warning: Chapman function set internally'
          STATUS = VLIDORT_WARNING
          DO_CHAPMAN_FUNCTION = .TRUE.
        ELSE
          NM = NM + 1
          MESSAGES(NM)   = 'Chapman Function not set, pseudo-spherical'
          ACTIONS(NM) = 'Have you set the CHAPMAN_FACTORS values?'
          STATUS = VLIDORT_SERIOUS
        ENDIF
       ENDIF
      ENDIF

!  Check sphericity corrections....Cannot both be turned on
!    --------- New code 31 January 2007

      IF ( DO_SOLAR_SOURCES ) THEN
        IF ( DO_SSCORR_NADIR .and. DO_SSCORR_OUTGOING ) THEN
          NM = NM + 1
          MESSAGES(NM)   = &
             'Cannot have both single scatter corrections on'
          ACTIONS(NM) = &
             'Turn off DO_SSCORR_NADIR and/or DO_SSCORR_OUTGOING'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

!  New 15 March 2012
!    Turn off SSCORR flags if the external SS calculation applies

      IF ( DO_SS_EXTERNAL ) then
        IF ( DO_SSCORR_NADIR ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'External SS calculation: Cannot have Nadir single scatter correction'
          ACTIONS(NM)  = 'Turn off DO_SSCORR_NADIR flag'
          STATUS = VLIDORT_SERIOUS
        ENDIF
        IF ( DO_SSCORR_OUTGOING ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'External SS calculation: Cannot have Outgoing single scatter correction'
          ACTIONS(NM)  = 'Turn off DO_SSCORR_OUTGOING flag'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

!  Check beam mode operation

      IF ( DO_SOLAR_SOURCES ) THEN
       IF ( DO_PLANE_PARALLEL ) THEN
        IF ( DO_REFRACTIVE_GEOMETRY ) THEN
         NM = NM + 1
         MESSAGES(NM) = &
        'Bad input: plane-parallel and refractive flags both set'
         ACTIONS(NM) = 'Warning: turn off Refraction internally'
         STATUS = VLIDORT_WARNING
         DO_REFRACTIVE_GEOMETRY = .FALSE.
        ENDIF
       ENDIF
      ENDIF

!  Check consistency of mean value input control
!  ---------------------------------------------

      IF ( DO_ADDITIONAL_MVOUT ) THEN
        IF ( DO_MVOUT_ONLY ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
               'Bad input: Cannot have both mean-value flags set'
          ACTIONS(NM)  = &
               'Warning: disable DO_MVOUT_ONLY flag internally'
          STATUS = VLIDORT_WARNING
          DO_MVOUT_ONLY = .FALSE.
        ENDIF
      ENDIF

!  Remove section on DO_NO_AZIMUTH. 17 January 2006

      IF ( .NOT.DO_ADDITIONAL_MVOUT ) THEN
        IF ( DO_MVOUT_ONLY ) THEN
          IF ( DO_USER_VZANGLES ) THEN
            NM = NM + 1
            MESSAGES(NM)   = &
               'Bad input: Mean-value option needs quadratures only'
            ACTIONS(NM) = &
               'Warning: DO_USER_VZANGLES flag disabled internally'
            STATUS = VLIDORT_WARNING
            DO_USER_VZANGLES = .FALSE.
          ENDIF
        ENDIF
      ENDIF

!  Check consistency of multiple scatter source term output control
!   ---SPecialist options. Removed 30 March 2007.

!      IF ( SAVE_LAYER_MSST ) THEN
!        IF ( .NOT. DO_USER_VZANGLES ) THEN
!          NM = NM + 1
!          MESSAGES(NM)   =
!     &   'Bad input: MSCAT. source term - USER_VZANGLES flag not set'
!          ACTIONS(NM) =
!     &   'Check DO_USER_VZANGLES and SAVE_LAYER_MSST flags'
!          STATUS = VLIDORT_SERIOUS
!        ENDIF
!      ENDIF

!  Check consistency of BVP_TELESCOPING and SOLUTION_SAVING flags
!  ---Warning. Set solution-saving internally

      IF (DO_BVP_TELESCOPING.AND..NOT.DO_SOLUTION_SAVING) THEN
        NM = NM + 1
        MESSAGES(NM) = &
        'Bad input: BVP telescoping -> solution saving must be set'
        ACTIONS(NM)  = 'Warning:  Solution saving was set internally'
        STATUS = VLIDORT_WARNING
        DO_SOLUTION_SAVING = .TRUE.
      ENDIF

!  Check consistency of Rayleigh-only and Isotropic-only cases
!   Removed 17 January 2006, Isotropic option removed.
!      IF ( DO_RAYLEIGH_ONLY .AND. DO_ISOTROPIC_ONLY ) THEN
!        NM = NM + 1
!        MESSAGES(NM)   =
!     &   'Bad input: Isotropic_only & Rayleigh-only flags both set'
!        ACTIONS(NM) =
!     &     'Check DO_RAYLEIGH_ONLY and DO_ISOTROPIC_ONLY flags'
!        STATUS = VLIDORT_SERIOUS
!      ENDIF

!  -----------Note the following in the scalar code -------------------

!  No Delta-M scaling with Rayleigh only
!   ---Warning. Turn off delta-M scaling.

      IF ( DO_RAYLEIGH_ONLY ) THEN
        IF ( DO_DELTAM_SCALING ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Bad input: No delta-M scaling with Rayleigh-only'
          ACTIONS(NM)  = &
            'Warning: DO_DELTAM_SCALING turned off internally'
          STATUS = VLIDORT_WARNING
          DO_DELTAM_SCALING = .FALSE.
        ENDIF
      ENDIF

!  No Delta-M scaling with Isotropic only
!   ---Warning. Turn off delta-M scaling.
!   Removed 17 January 2006, Isotropic option removed.
!      IF ( DO_ISOTROPIC_ONLY ) THEN
!        IF ( DO_DELTAM_SCALING ) THEN
!         NM = NM + 1
!          MESSAGES(NM) =
!     &     'Bad input: No delta-M scaling with Isotropic-only'
!          ACTIONS(NM)  =
!     &      'Warning: DO_DELTAM_SCALING turned off internally'
!          STATUS = VLIDORT_WARNING
!          DO_DELTAM_SCALING = .FALSE.
!        ENDIF
!      ENDIF

!  Check directional input

      IF ( .NOT.DO_UPWELLING .AND. .NOT. DO_DNWELLING ) THEN
        NM = NM + 1
        MESSAGES(NM) = 'Bad input: no directional input is set'
        ACTIONS(NM)  = &
            'Check DO_UPWELLING & DO_DNWELLING: one must be set!'
        STATUS = VLIDORT_SERIOUS
      ENDIF

!  Check number of input expansion coefficient moments (non-Rayleigh)
!  ------------------------------------------------------------------

!   Isotropic part Removed 17 January 2006, Isotropic option removed.

      IF ( .NOT.DO_RAYLEIGH_ONLY .AND. .NOT. DO_SSFULL ) THEN
        IF ( DO_DELTAM_SCALING ) THEN
          IF ( NGREEK_MOMENTS_INPUT.LT.2*NSTREAMS ) THEN
            NM = NM + 1
            MESSAGES(NM) = &
            'Bad input: Fewer than 2N expansion moments with delta-M'
            ACTIONS(NM) = &
             'Warning: Re-set NGREEK_MOMENTS_INPUT to 2N internally'
            STATUS = VLIDORT_WARNING
            NGREEK_MOMENTS_INPUT = 2*NSTREAMS
          ENDIF
        ELSE
          IF ( DO_SSCORR_NADIR .OR. DO_SSCORR_OUTGOING ) THEN
            IF ( NGREEK_MOMENTS_INPUT.LT.2*NSTREAMS-1 ) THEN
              NM = NM + 1
              MESSAGES(NM) = &
             'Bad input: Fewer than 2N-1 expansion moments without delta-M'
              ACTIONS(NM) = &
             'Warning: Re-set NGREEK_MOMENTS_INPUT to 2N-1 internally'
              STATUS = VLIDORT_WARNING
              NGREEK_MOMENTS_INPUT = 2*NSTREAMS - 1
            ENDIF
          ENDIF
        ENDIF

      ELSE

!  Checks for Rayleigh only option
!   All warnings.

        IF ( DO_RAYLEIGH_ONLY ) THEN

          IF ( NGREEK_MOMENTS_INPUT.NE.2 ) THEN
            NM = NM + 1
            MESSAGES(NM) = &
             'Bad input: Rayleigh-only, expansion momemts NOT = 2'
            ACTIONS(NM)  = &
             'Warning: Set NGREEK_MOMENTS_INPUT = 2 internally'
            STATUS = VLIDORT_WARNING
            NGREEK_MOMENTS_INPUT = 2
          ENDIF

          IF ( DO_BVP_TELESCOPING ) THEN
            NM = NM + 1
            MESSAGES(NM)   = &
         'Bad input: Bvp telescoping not possible, Rayleigh only'
            ACTIONS(NM) = 'Warning: Turn off BVP_TELESCOPING internally'
            STATUS = VLIDORT_WARNING
          ENDIF

          IF ( DO_SOLUTION_SAVING.and..not.do_thermal_transonly ) THEN
            NM = NM + 1
            MESSAGES(NM)   = &
         'Bad input: Solution saving not possible, Rayleigh only'
            ACTIONS(NM) = 'Warning: Turn off SOLUTION_SAVING internally'
            STATUS = VLIDORT_WARNING
          ENDIF

        ENDIF

!  Checks for Isotropic only option. All removed, 17 January 2006.

      ENDIF

!  Reset solution saving and bvp telescoping flags
!  Do not need the isotropic-only options

!      DO_SOLUTION_SAVING =  ( DO_SOLUTION_SAVING .AND.
!     &     ((.NOT.DO_RAYLEIGH_ONLY).OR.(.NOT.DO_ISOTROPIC_ONLY)) )
!      DO_BVP_TELESCOPING =  ( DO_BVP_TELESCOPING .AND.
!     &     ((.NOT.DO_RAYLEIGH_ONLY).OR.(.NOT.DO_ISOTROPIC_ONLY)) )

      DO_SOLUTION_SAVING =  ( DO_SOLUTION_SAVING .AND. &
           (.NOT.DO_RAYLEIGH_ONLY) )
      DO_BVP_TELESCOPING =  ( DO_BVP_TELESCOPING .AND. &
                     (.NOT.DO_RAYLEIGH_ONLY) )

!  BVP telescoping doesn't work with non-Lambertian surfaces
!   Reason, not yet coded. Theory already worked out.

      IF (  DO_BVP_TELESCOPING ) THEN
        IF ( .NOT. DO_LAMBERTIAN_SURFACE ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'BVP telescoping disabled for non-Lambertian'
          ACTIONS(NM)  = &
             'Turn off DO_BVP_TELESCOPING flag, done internally'
          STATUS = VLIDORT_WARNING
          DO_BVP_TELESCOPING = .FALSE.
        ENDIF
      ENDIF

!  BVP telescoping doesn't work with non-Lambertian surfaces
!   Reason, not yet coded. Theory already worked out.
!    ---WARNING. BVP telescoping Flag turned off

      IF (  DO_BVP_TELESCOPING ) THEN
        IF ( .NOT. DO_LAMBERTIAN_SURFACE ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'BVP telescoping must be disabled, non-Lambertian'
          ACTIONS(NM)  = &
             'Warning: DO_BVP_TELESCOPING turned off internally'
          STATUS = VLIDORT_WARNING
          DO_BVP_TELESCOPING = .FALSE.
        ENDIF
      ENDIF

!  Check azimuth-only conditions
!  -----------------------------

!  Check no-Azimuth flag. Now set internally
!    ---WARNING. Do-no-Azimuth Flag turned on
!      IF ( .NOT.DO_NO_AZIMUTH ) THEN
!        IF ( DO_USER_VZANGLES. AND. N_USER_VZANGLES.EQ.1 ) THEN
!          IF ( USER_ANGLES_INPUT(1) .EQ. ZERO ) THEN
!            NM = NM + 1
!            MESSAGES(NM) =
!     &         'Bad input: zenith-sky output requires no azimuth'
!            ACTIONS(NM)  =
!     &         'Warning: DO_NO_AZIMUTH flag set true internally'
!            STATUS = VLIDORT_WARNING
!          ENDIF
!        ENDIF
!      ENDIF

!  Check: OLD single scattering correction and Do Rayleigh
!    ---WARNING. SS Flag turned off
!  Check only required for the diffuse field calculations (Version 2.3)

      IF ( DO_SSCORR_NADIR ) THEN
        IF ( DO_RAYLEIGH_ONLY .AND. .NOT. DO_SSFULL ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
              'Bad input: No SS correction for Rayleigh only'
          ACTIONS(NM)  = &
              'Warning: DO_SSCORR_NADIR turned off internally'
          STATUS = VLIDORT_WARNING
          DO_SSCORR_NADIR = .FALSE.
        ENDIF
      ENDIF

!  Full-up single scatter, enabled 25 September 2007.
!   Single scatter corrections must be turned on

      IF ( DO_SSFULL ) THEN
        IF ( .not.DO_SSCORR_NADIR.and..not.DO_SSCORR_OUTGOING ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Bad input: Full SS, must have one SSCORR flag set'
          ACTIONS(NM)  = &
            'Full SS: default to use outgoing SS correction'
          STATUS = VLIDORT_WARNING
          DO_SSCORR_NADIR    = .FALSE.
          DO_SSCORR_OUTGOING = .TRUE.
        ENDIF
      ENDIF

!  Full-up single scatter, enabled 25 September 2007.
!   Diffuse-field Delta-M scaling must be turned off

      IF ( DO_SSFULL ) THEN
        IF ( DO_DELTAM_SCALING ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Bad input: Full SS, diffuse-field delta-M on'
          ACTIONS(NM)  = &
             'Full SS: default to deltam_scaling = false'
          STATUS = VLIDORT_WARNING
          DO_DELTAM_SCALING   = .FALSE.
        ENDIF
      ENDIF

!  Check thermal inputs
!  --------------------

!  If thermal transmittance only, check thermal flag

      IF ( .NOT. DO_THERMAL_EMISSION ) THEN
       IF ( DO_THERMAL_TRANSONLY ) THEN
         NM = NM + 1
         MESSAGES(NM) = &
           'Bad input: No thermal, must turn off transonly flag'
         ACTIONS(NM)  = &
           'Warning: DO_THERMAL_TRANSONLY turned off internally'
         STATUS = VLIDORT_WARNING
         DO_THERMAL_TRANSONLY = .FALSE.
       ENDIF
      ENDIF

!  Switch off a bunch of flags

      IF ( DO_THERMAL_EMISSION ) THEN
       IF ( DO_THERMAL_TRANSONLY ) THEN
!         DO_RAYLEIGH_ONLY  = .FALSE.
         DO_DELTAM_SCALING = .FALSE.
       ENDIF
      ENDIF

!  No solar sources for thermal transmittance

      IF ( DO_THERMAL_TRANSONLY ) THEN
        IF ( DO_SOLAR_SOURCES ) THEN
         NM = NM + 1
         MESSAGES(NM) = &
              'Bad input: thermal tranmsittance, must turn off solar'
         ACTIONS(NM)  = &
               'Warning: DO_SOLAR_SOURCES turned off internally'
         STATUS = VLIDORT_WARNING
         DO_SOLAR_SOURCES = .FALSE.
       ENDIF
      ENDIF

!  Check viewing geometry input
!  ----------------------------

!  Check earth radius (Chapman function only)
!    ---WARNING. Default value of 6371.0 will be set

      IF ( DO_CHAPMAN_FUNCTION ) THEN
        IF ( .NOT. DO_PLANE_PARALLEL ) THEN
          IF ( EARTH_RADIUS.LT.6320.0D0 .OR. &
               EARTH_RADIUS.GT.6420.0D0 ) THEN
            NM = NM + 1
            MESSAGES(NM) = &
              'Bad input: Earth radius outside of [6320-6420]'
            ACTIONS(NM)  = &
               'Warning: default value of 6371.0 was set'
            STATUS = VLIDORT_WARNING
            EARTH_RADIUS = 6371.0D0
          ENDIF
        ENDIF
      ENDIF

!  Check dimensioning on Legendre numbers (refractive geometry only)

      IF ( DO_REFRACTIVE_GEOMETRY ) THEN
        NALLSTREAMS = N_SZANGLES*NLAYERS + NSTREAMS + N_USER_VZANGLES
        IF ( NALLSTREAMS .GT. MAX_ALLSTRMS_P1 ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
            'Dimensioning error for refractive beam angles'
          ACTIONS(NM)  = &
            'Increase dimension MAX_ALLSTRMS_P1'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

!  Check GEOMETRY_SPECHEIGHT (only for outgoing sphericity correction)
!    GEOMETRY_SPECHEIGHT cannot be greater than HEIGHT_GRID(NLAYERS)

      IF ( DO_SSCORR_OUTGOING ) THEN
        IF ( GEOMETRY_SPECHEIGHT .GT. HEIGHT_GRID(NLAYERS) ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
               'GEOMETRY_SPECHEIGHT must be =< Input BOA-HEIGHT '
          ACTIONS(NM)  = &
               'Warning: Internal Re-set of GEOMETRY_SPECHEIGHT '
          STATUS = VLIDORT_WARNING
          GEOMETRY_SPECHEIGHT  = HEIGHT_GRID(NLAYERS)
        ENDIF
      ENDIF

!  Check solar zenith angle input

!mick hold - 9/26/2012
      !IF (DO_SOLAR_SOURCES ) THEN
        DO I = 1, N_SZANGLES
          IF ( SZANGLES(I) .LT. ZERO .OR. &
               SZANGLES(I) .GE. 90.0D0 ) THEN
            WRITE(C2,'(I2)')I
            NM = NM + 1
            MESSAGES(NM) = &
                'Bad input: out-of-range solar angle, no. '//C2
            ACTIONS(NM)  = &
                'Look at SZANGLES input, should be < 90 & > 0'
            STATUS = VLIDORT_SERIOUS
          ENDIF
        ENDDO
      !ELSE IF ( .NOT.DO_SOLAR_SOURCES .AND. DO_THERMAL_EMISSION ) THEN
      !  SZANGLES(1:N_SZANGLES) = ZERO
      !ENDIF

!  Check relative azimuths

      LOOP = .TRUE.
      I = 0
      DO WHILE (LOOP .AND. I.LT.N_USER_RELAZMS)
        I = I + 1
        IF ( USER_RELAZMS(I) .GT. 360.0D0   .OR. &
             USER_RELAZMS(I) .LT. ZERO ) THEN
          WRITE(C2,'(I2)')I
          NM = NM + 1
          MESSAGES(NM) = &
               'Bad input: out-of-range azimuth angle, no. '//C2
          ACTIONS(NM)  = &
               'Look at azimuth angle input, should be in [0,360]'
          LOOP = .FALSE.
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDDO

!  Limits on user-defined options

!      IF ( .NOT. DO_USER_VZANGLES .AND..NOT.DO_QUAD_OUTPUT ) THEN
!        NM = NM + 1
!        MESSAGES(NM) =
!     &       'Bad input: No angular stream output is specified'
!        ACTIONS(NM) =
!     &       'Check DO_USER_VZANGLES and DO_QUAD_OUTPUT flags'
!        STATUS = VLIDORT_SERIOUS
!      ENDIF

!  Check user-defined stream angles (should always be [0,90])

      IF ( DO_USER_VZANGLES ) THEN
        LOOP = .TRUE.
        I = 0
        DO WHILE (LOOP .AND. I.LT.N_USER_VZANGLES)
          I = I + 1
          IF ( USER_VZANGLES(I) .GT. 90.0   .OR. &
               USER_VZANGLES(I) .LT. ZERO ) THEN
            WRITE(C2,'(I2)')I
            NM = NM + 1
            MESSAGES(NM) = &
               'Bad input: out-of-range user stream, no. '//C2
            ACTIONS(NM)  = &
               'Look at user viewing zenith angle input'
            LOOP = .FALSE.
            STATUS = VLIDORT_SERIOUS
          ENDIF
        ENDDO
      ENDIF

!  Re-order the input angles
!  -------------------------

!  This section has been truncated. 28 March 2007

!mick fix - moved "N_OUT_STREAMS  = N_USER_VZANGLES" outside if block
!         & initialized OUT_ANGLES to ZERO in case DO_USER_VZANGLES = .FALSE.
      N_OUT_STREAMS  = N_USER_VZANGLES
      OUT_ANGLES     = ZERO
      IF ( DO_USER_VZANGLES ) THEN
        IF ( N_OUT_STREAMS .EQ. 1 ) THEN
          OUT_ANGLES(1) =  USER_VZANGLES(1)
        ELSE
          DO I = 1, N_USER_VZANGLES
            ALL_ANGLES(I) = USER_VZANGLES(I)
          ENDDO
          CALL INDEXX ( N_OUT_STREAMS, USER_VZANGLES, INDEX_ANGLES )
          DO I = 1, N_OUT_STREAMS
            OUT_ANGLES(I) = ALL_ANGLES(INDEX_ANGLES(I))
            USER_VZANGLES(I) = OUT_ANGLES(I)
          ENDDO
        ENDIF
      ENDIF

!  Check height grid input (Chapman function only)

      IF ( DO_CHAPMAN_FUNCTION ) THEN
        LOOP = .TRUE.
        I = 0
        DO WHILE (LOOP .AND. I.LT.NLAYERS)
          I = I + 1
          IF ( HEIGHT_GRID(I-1).LE.HEIGHT_GRID(I) ) THEN
            WRITE(C2,'(I2)')I
            NM = NM + 1
            MESSAGES(NM)   = &
            'Bad input: Height-grid not monotonically decreasing; Layer '//C2
            ACTIONS(NM) = 'Look at Height-grid input'
            LOOP = .FALSE.
            STATUS = VLIDORT_SERIOUS
          ENDIF
        ENDDO
      ENDIF

!  Check vertical outputs
!  ----------------------

!  Check vertical output levels (should always be within atmosphere!)

      LOOP = .TRUE.
      I = 0
      DO WHILE (LOOP .AND. I.LT.N_USER_LEVELS)
        I = I + 1
        IF ( USER_LEVELS(I) .GT. DBLE(NLAYERS) .OR. &
             USER_LEVELS(I) .LT. ZERO )  THEN
          WRITE(C2,'(I2)')I
          NM = NM + 1
          MESSAGES(NM) = &
                'Bad input: Out of range for level choice # '//C2
          ACTIONS(NM)  = 'Re-set level output '
          LOOP = .FALSE.
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDDO

!  Check repetition of vertical output choices

      UTA = 0
      LOOP = .TRUE.
      DO WHILE ( LOOP .AND. UTA .LT. N_USER_LEVELS )
        UTA = UTA + 1
        XT = USER_LEVELS(UTA)
        NSTART = 0
        DO N = 1, N_USER_LEVELS
          IF ( XT .EQ. USER_LEVELS(N)) NSTART = NSTART + 1
        ENDDO
        IF ( NSTART .NE. 1 ) THEN
          LOOP = .FALSE.
          NM = NM + 1
          MESSAGES(NM) = &
              'Bad input: repetition of vertical output choice'
          ACTIONS(NM)  = 'Re-set level output '
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDDO


!  Check geophysical scattering inputs
!  -----------------------------------

!  Check single scatter albedos

      IF ( .NOT. DO_THERMAL_TRANSONLY ) THEN
       DO L = 1, NLAYERS
        IF ( OMEGA_TOTAL_INPUT(L).GT.ONE-OMEGA_SMALLNUM ) THEN
          NM = NM + 1
          WRITE(C3,'(I3)')L
          MESSAGES(NM) = &
               'Bad input: SS-albedo too close to 1, layer '//C3
          ACTIONS(NM)  = 'Check SS-albedo input'
          STATUS = VLIDORT_SERIOUS
        ELSE IF ( OMEGA_TOTAL_INPUT(L).LT.OMEGA_SMALLNUM ) THEN
          NM = NM + 1
          WRITE(C3,'(I3)')L
          MESSAGES(NM) = &
                'Bad input: SS-albedo too close to 0, layer '//C3
          ACTIONS(NM)  = 'Check SS-albedo input'
          STATUS = VLIDORT_SERIOUS
        ENDIF
       ENDDO
      ENDIF

!  Solar beam, cannot be too small

      IF ( DO_SOLAR_SOURCES ) THEN
        DO L = 1, NLAYERS
         IF ( OMEGA_TOTAL_INPUT(L).LT.OMEGA_SMALLNUM ) THEN
          WRITE(C3,'(I3)')L
          NM = NM + 1
          MESSAGES(NM) = &
               'Bad input: SS-albedo too close to 0, layer '//C3
          ACTIONS(NM)  = 'Check SS-albedo input'
          STATUS = VLIDORT_SERIOUS
         ENDIF
        ENDDO
      ENDIF

!  Check first phase function moments

      IF ( .NOT. DO_THERMAL_TRANSONLY ) THEN
       DO L = 1, NLAYERS
        IF ( GREEKMAT_TOTAL_INPUT(0,L,1).NE.ONE ) THEN
          WRITE(C3,'(I3)')L
          NM = NM + 1
          MESSAGES(NM) = &
             'First phase moment (GREEK_11) not 1 for layer '//C3
          ACTIONS(NM)  = 'Check First phase function moment'
          STATUS = VLIDORT_SERIOUS
        ENDIF
       ENDDO
      ENDIF

!  Additional check on non-negativity of (1,1) moments.
!    Furnished 27 September 2007, as a result of input-checking.
!      DO N = 1, NLAYERS
!       DO L = 1, NGREEK_MOMENTS_INPUT
!        IF ( GREEKMAT_TOTAL_INPUT(L,N,1).LT.ZERO ) THEN
!         WRITE(C3,'(I3)')N
!         NM = NM + 1
!         MESSAGES(NM) =
!      &    'Some moments (GREEK_11) are NEGATIVE for layer '//C3
!         ACTIONS(NM) = 'Check Greek moments input - some bad values!'
!         STATUS = VLIDORT_SERIOUS
!        ENDIF
!       ENDDO
!      ENDDO

!  Specialist options, Check the given input

      IF ( DO_SPECIALIST_OPTION_2 ) THEN
        IF ( NLAYERS_NOMS .GT. NLAYERS-1 ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Bad input specialist option 2: NLAYERS_NOMS'
          ACTIONS(NM)  = 'Check NLAYERS_NOMS must be less than NLAYERS'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

      IF ( DO_SPECIALIST_OPTION_3 ) THEN
        IF ( NLAYERS_CUTOFF .lt. 2 ) THEN
          NM = NM + 1
          MESSAGES(NM) = 'Bad input specialist option 3: NLAYERS_CUTOFF'
          ACTIONS(NM)  = 'Check NLAYERS_CUTOFF must be greater than 1'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

!  TOA contributions
!    TOA Upwelling must be set, if you are using this flag

      IF ( DO_TOA_CONTRIBS ) THEN
        IF ( .not. DO_UPWELLING ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
             'Bad input TOA contributions, Upwelling Not set'
          ACTIONS(NM)  = 'Must set the DO_UPWELLING flag'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

      IF ( DO_TOA_CONTRIBS ) THEN
        N = 0
        DO UTA = 1, N_USER_LEVELS
          if ( USER_LEVELS(UTA) .ne. 0.0d0 ) N = N + 1
        ENDDO
        IF ( N .EQ. N_USER_LEVELS ) THEN
          NM = NM + 1
          MESSAGES(NM) = &
              'Bad input TOA contributions, Level TOA not set'
          ACTIONS(NM)  = 'Must set one level output to be TOA (0.0)'
          STATUS = VLIDORT_SERIOUS
        ENDIF
      ENDIF

!mick fix
      NMESSAGES = NM

!  Finish

      RETURN
      END SUBROUTINE VLIDORT_CHECK_INPUT

!

      SUBROUTINE VLIDORT_DERIVE_INPUT ( &
        DO_FULLRAD_MODE, DO_SSCORR_NADIR, DO_SSCORR_OUTGOING, DO_SSFULL, &
        DO_SOLAR_SOURCES, DO_REFRACTIVE_GEOMETRY, DO_RAYLEIGH_ONLY, &
        DO_UPWELLING, DO_DNWELLING, DO_USER_STREAMS, DO_OBSERVATION_GEOMETRY, &
        NSTOKES, NSTREAMS, NLAYERS, NGREEK_MOMENTS_INPUT, &
        N_SZANGLES, SZANGLES, SZA_LOCAL_INPUT, N_USER_RELAZMS, &
        N_USER_VZANGLES, USER_VZANGLES, N_USER_LEVELS, USER_LEVELS, &
        DELTAU_VERT_INPUT, &
        GREEKMAT_TOTAL_INPUT, DO_SURFACE_EMISSION, SURFBB, & 
        DO_THERMAL_TRANSONLY, DO_SPECIALIST_OPTION_2, NLAYERS_NOMS, &
        USER_VZANGLES_ADJUST, N_OUT_STREAMS, DO_SOLUTION_SAVING, &
        DO_BVP_TELESCOPING, DO_ADDITIONAL_MVOUT, DO_MVOUT_ONLY, &
        FLUX_FACTOR, OMEGA_TOTAL_INPUT, DO_DOUBLE_CONVTEST, &
        DO_ALL_FOURIER, DO_DIRECT_BEAM, DO_CLASSICAL_SOLUTION, &
        DO_DBCORRECTION, DO_NO_AZIMUTH, FLUXVEC, COS_SZANGLES, &
        SIN_SZANGLES, SUN_SZA_COSINES, QUAD_STREAMS, QUAD_WEIGHTS, &
        QUAD_STRMWTS, QUAD_HALFWTS, QUAD_SINES, QUAD_ANGLES, &
        DO_MSMODE_VLIDORT, NMOMENTS, NSTREAMS_2, &
        NTOTAL, N_SUBDIAG, N_SUPDIAG, NSTOKES_SQ, &
        NSTKS_NSTRMS, NSTKS_NSTRMS_2, NBEAMS, &
        NPARTICSOLS, MUELLER_INDEX, DMAT, GREEKMAT_INDEX, DO_REAL_EIGENSOLVER, &
        BVP_REGULAR_FLAG, LAYER_MAXMOMENTS, DO_LAYER_SCATTERING, N_CONVTESTS, &
        N_CONV_STREAMS, N_DIRECTIONS, WHICH_DIRECTIONS, &
        USER_STREAMS, USER_SINES, USER_SECANTS, PARTLAYERS_OUTFLAG, &
        PARTLAYERS_OUTINDEX, UTAU_LEVEL_MASK_UP, UTAU_LEVEL_MASK_DN, & 
        DO_PARTLAYERS, N_PARTLAYERS, PARTLAYERS_LAYERIDX, PARTLAYERS_VALUES, &
        N_LAYERSOURCE_UP, N_LAYERSOURCE_DN, N_ALLLAYERS_UP, &
        N_ALLLAYERS_DN, STERM_LAYERMASK_UP, STERM_LAYERMASK_DN, &
        DFLUX, TAUGRID_INPUT, &
        STATUS_SUB, MESSAGE )

      USE VLIDORT_PARS
      USE VLIDORT_AUX

      IMPLICIT NONE

      LOGICAL, INTENT (IN) ::             DO_FULLRAD_MODE
      LOGICAL, INTENT (IN) ::             DO_SSCORR_NADIR
      LOGICAL, INTENT (IN) ::             DO_SSCORR_OUTGOING
      LOGICAL, INTENT (IN) ::             DO_SSFULL
      LOGICAL, INTENT (IN) ::             DO_SOLAR_SOURCES
      LOGICAL, INTENT (IN) ::             DO_REFRACTIVE_GEOMETRY
      LOGICAL, INTENT (IN) ::             DO_RAYLEIGH_ONLY
      LOGICAL, INTENT (IN) ::             DO_UPWELLING
      LOGICAL, INTENT (IN) ::             DO_DNWELLING
      LOGICAL, INTENT (IN) ::             DO_USER_STREAMS
      LOGICAL, INTENT (IN) ::             DO_OBSERVATION_GEOMETRY
      INTEGER, INTENT (IN) ::             NSTOKES
      INTEGER, INTENT (IN) ::             NSTREAMS
      INTEGER, INTENT (IN) ::             NLAYERS
      DOUBLE PRECISION, INTENT (IN) ::    DELTAU_VERT_INPUT ( MAXLAYERS )
      INTEGER, INTENT (IN) ::             NGREEK_MOMENTS_INPUT
      INTEGER, INTENT (IN) ::             N_SZANGLES
      DOUBLE PRECISION, INTENT (IN) ::    SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (IN) ::    SZA_LOCAL_INPUT &
          ( 0:MAXLAYERS, MAX_SZANGLES )
      INTEGER, INTENT (IN) ::             N_USER_RELAZMS
      INTEGER, INTENT (IN) ::             N_USER_VZANGLES
      DOUBLE PRECISION, INTENT (IN) ::    USER_VZANGLES ( MAX_USER_VZANGLES )
      INTEGER, INTENT (IN) ::             N_USER_LEVELS
      DOUBLE PRECISION, INTENT (IN) ::    GREEKMAT_TOTAL_INPUT &
          ( 0:MAXMOMENTS_INPUT, MAXLAYERS, MAXSTOKES_SQ )
      LOGICAL, INTENT (IN) ::             DO_SURFACE_EMISSION
      DOUBLE PRECISION, INTENT (IN) ::    SURFBB
      LOGICAL, INTENT (IN) ::             DO_THERMAL_TRANSONLY
      LOGICAL, INTENT (IN) ::             DO_SPECIALIST_OPTION_2
      INTEGER, INTENT (IN) ::             NLAYERS_NOMS
      DOUBLE PRECISION, INTENT (IN) ::    USER_VZANGLES_ADJUST &
          ( MAX_USER_VZANGLES )
      INTEGER, INTENT (IN) ::             N_OUT_STREAMS
      DOUBLE PRECISION, INTENT (IN) ::    FLUX_FACTOR

      LOGICAL, INTENT (INOUT) ::          DO_SOLUTION_SAVING
      LOGICAL, INTENT (INOUT) ::          DO_BVP_TELESCOPING
      LOGICAL, INTENT (INOUT) ::          DO_ADDITIONAL_MVOUT
      LOGICAL, INTENT (INOUT) ::          DO_MVOUT_ONLY
      DOUBLE PRECISION, INTENT (INOUT) :: OMEGA_TOTAL_INPUT ( MAXLAYERS )
      LOGICAL, INTENT (INOUT) ::          DO_DOUBLE_CONVTEST
      LOGICAL, INTENT (INOUT) ::          DO_ALL_FOURIER
      LOGICAL, INTENT (INOUT) ::          DO_DIRECT_BEAM
      LOGICAL, INTENT (INOUT) ::          DO_CLASSICAL_SOLUTION
      LOGICAL, INTENT (INOUT) ::          DO_DBCORRECTION
      LOGICAL, INTENT (INOUT) ::          DO_NO_AZIMUTH
      DOUBLE PRECISION, INTENT (INOUT) :: USER_LEVELS ( MAX_USER_LEVELS )

      DOUBLE PRECISION, INTENT (OUT) ::   FLUXVEC ( MAXSTOKES )
      DOUBLE PRECISION, INTENT (OUT) ::   COS_SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (OUT) ::   SIN_SZANGLES ( MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (OUT) ::   SUN_SZA_COSINES &
          ( MAXLAYERS, MAX_SZANGLES )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_STREAMS ( MAXSTREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_WEIGHTS ( MAXSTREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_STRMWTS ( MAXSTREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_HALFWTS ( MAXSTREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_SINES   ( MAXSTREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   QUAD_ANGLES  ( MAXSTREAMS )
      LOGICAL, INTENT (OUT) ::            DO_MSMODE_VLIDORT
      INTEGER, INTENT (OUT) ::            NMOMENTS
      INTEGER, INTENT (OUT) ::            NSTREAMS_2
      INTEGER, INTENT (OUT) ::            NTOTAL
      INTEGER, INTENT (OUT) ::            N_SUBDIAG
      INTEGER, INTENT (OUT) ::            N_SUPDIAG
      INTEGER, INTENT (OUT) ::            NSTOKES_SQ
      INTEGER, INTENT (OUT) ::            NSTKS_NSTRMS
      INTEGER, INTENT (OUT) ::            NSTKS_NSTRMS_2
      INTEGER, INTENT (OUT) ::            NBEAMS
      INTEGER, INTENT (OUT) ::            NPARTICSOLS

      INTEGER, INTENT (OUT) ::            MUELLER_INDEX ( MAXSTOKES, MAXSTOKES )
      DOUBLE PRECISION, INTENT (OUT) ::   DMAT ( MAXSTOKES, MAXSTOKES )

      INTEGER, INTENT (OUT) ::            GREEKMAT_INDEX ( 6 )
      LOGICAL, INTENT (OUT) ::            DO_REAL_EIGENSOLVER &
          ( 0:MAXMOMENTS, MAXLAYERS )
      LOGICAL, INTENT (OUT) ::            BVP_REGULAR_FLAG ( 0:MAXMOMENTS )
      INTEGER, INTENT (OUT) ::            LAYER_MAXMOMENTS ( MAXLAYERS )
      LOGICAL, INTENT (OUT) ::            DO_LAYER_SCATTERING &
          ( 0:MAXMOMENTS, MAXLAYERS )
      INTEGER, INTENT (OUT) ::            N_CONVTESTS
      INTEGER, INTENT (OUT) ::            N_CONV_STREAMS
      INTEGER, INTENT (OUT) ::            N_DIRECTIONS
      INTEGER, INTENT (OUT) ::            WHICH_DIRECTIONS ( MAX_DIRECTIONS )
      DOUBLE PRECISION, INTENT (OUT) ::   USER_STREAMS  ( MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   USER_SINES    ( MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (OUT) ::   USER_SECANTS  ( MAX_USER_STREAMS )
      LOGICAL, INTENT (OUT) ::            PARTLAYERS_OUTFLAG ( MAX_USER_LEVELS )
      INTEGER, INTENT (OUT) ::            PARTLAYERS_OUTINDEX &
          ( MAX_USER_LEVELS )
      INTEGER, INTENT (OUT) ::            UTAU_LEVEL_MASK_UP ( MAX_USER_LEVELS )
      INTEGER, INTENT (OUT) ::            UTAU_LEVEL_MASK_DN ( MAX_USER_LEVELS )
      LOGICAL, INTENT (OUT) ::            DO_PARTLAYERS
      INTEGER, INTENT (OUT) ::            N_PARTLAYERS
      INTEGER, INTENT (OUT) ::            PARTLAYERS_LAYERIDX ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (OUT) ::   PARTLAYERS_VALUES ( MAX_PARTLAYERS )
      INTEGER, INTENT (OUT) ::            N_LAYERSOURCE_UP
      INTEGER, INTENT (OUT) ::            N_LAYERSOURCE_DN
      INTEGER, INTENT (OUT) ::            N_ALLLAYERS_UP
      INTEGER, INTENT (OUT) ::            N_ALLLAYERS_DN
      LOGICAL, INTENT (OUT) ::            STERM_LAYERMASK_UP ( MAXLAYERS )
      LOGICAL, INTENT (OUT) ::            STERM_LAYERMASK_DN ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (OUT) ::   DFLUX ( MAXSTOKES )
      DOUBLE PRECISION, INTENT (OUT) ::   TAUGRID_INPUT ( 0:MAXLAYERS )
      INTEGER, INTENT (OUT) ::            STATUS_SUB
      CHARACTER (LEN=*), INTENT (INOUT) ::  MESSAGE

!  Local variables
!  ---------------

      DOUBLE PRECISION :: MU1, MU2, DT, RT
      INTEGER ::          I, UT, N, UTA, NSTART, M, NAP, NS
      INTEGER ::          O1, O2, O1_S, MS2, P, NA, Q, QC, L, EC
      LOGICAL ::          LOOP, LOCAL_NADIR_ONLY
      INTEGER ::          CONV_START_STREAMS

      DOUBLE PRECISION :: DMAT_PSOLS &
          ( MAXSTOKES, MAXSTOKES, MAX_PSOLS )
      DOUBLE PRECISION :: DMAT_PSOLS_FLUXVEC &
          ( MAXSTOKES,MAX_PSOLS )

!  Set additional numbers (derived input)
!  ======================

!  Set status

      STATUS_SUB = VLIDORT_SUCCESS
      MESSAGE    = ' '

!  Automatic input

      DO_ALL_FOURIER        = .FALSE.
      DO_CLASSICAL_SOLUTION = .TRUE.
      DO_DIRECT_BEAM        = .TRUE.

!  SSFULL flag cancels some other flags. Not the DB correction !!!!

      IF ( DO_SSFULL ) THEN
        DO_DOUBLE_CONVTEST = .FALSE.
        DO_SOLUTION_SAVING = .FALSE.
        DO_BVP_TELESCOPING = .FALSE.
        DO_ADDITIONAL_MVOUT = .FALSE.
        DO_MVOUT_ONLY       = .FALSE.
      ENDIF

!  Set DB correction flag (this section 11 October 2010)

      DO_DBCORRECTION = .false.
      IF ( DO_SSFULL .or. DO_SSCORR_NADIR .or. DO_SSCORR_OUTGOING ) &
            DO_DBCORRECTION = .true.

!  Mode of operation
!   SS outgoing sphericity option, added 31 January 2007
!   SS full calculation option added 25 September 2007.

      DO_MSMODE_VLIDORT = .FALSE.
      IF ( DO_FULLRAD_MODE ) THEN
        IF ( .NOT. DO_SSFULL ) THEN
          IF ( DO_SSCORR_NADIR .OR. DO_SSCORR_OUTGOING ) THEN
            DO_MSMODE_VLIDORT = .TRUE.
          ENDIF
        ENDIF
      ELSE
        IF ( .NOT. DO_SSFULL ) THEN
          DO_MSMODE_VLIDORT = .TRUE.
        ENDIF
      ENDIF

!  New section. Setting the DO_NO_AZIMUTH flag
!    Rt Solutions. 17 January 2006. R. Spurr and V. Natraj.

!  DO_NO_AZIMUTH should be set internally only when:
!     (a) NSTOKES = 1 and nadir view only, and no SS correction
!     (b) MIFLUX_ONLY flag is true.
!     (c) SSFULL calculation flag is set

      LOCAL_NADIR_ONLY = .FALSE.
      IF ( N_USER_VZANGLES.EQ.1.and.USER_VZANGLES(1).EQ.ZERO ) THEN
        LOCAL_NADIR_ONLY = .TRUE.
      ENDIF
      DO_NO_AZIMUTH = .FALSE.
      IF ( (NSTOKES.EQ.1.AND.LOCAL_NADIR_ONLY.AND.(.NOT.DO_SSFULL.OR. &
            .NOT.DO_SSCORR_NADIR.OR..not.DO_SSCORR_OUTGOING)) &
             .OR.DO_MVOUT_ONLY  ) THEN
        DO_NO_AZIMUTH = .TRUE.
      ENDIF

!  Directional indices

      IF ( DO_UPWELLING .AND. DO_DNWELLING ) THEN
        N_DIRECTIONS = 2
        WHICH_DIRECTIONS(1) = UPIDX
        WHICH_DIRECTIONS(2) = DNIDX
      ELSE
        N_DIRECTIONS = 1
        WHICH_DIRECTIONS(2) = 0
        IF ( DO_UPWELLING ) THEN
          WHICH_DIRECTIONS(1) = UPIDX
        ELSE IF ( DO_DNWELLING) THEN
          WHICH_DIRECTIONS(1) = DNIDX
        ENDIF
      ENDIF

!  Flux vector set unity input.

      FLUXVEC(1) = ONE
      FLUXVEC(2) = ZERO
      FLUXVEC(3) = ZERO
      FLUXVEC(4) = ZERO

!  Convert Surface emission input.............. NOT USED....
!  Input values should be Watts/ sq m
!      IF ( DO_SURFACE_EMISSION ) THEN
!        FP_SURFBB = PI4 * SURFBB
!      ENDIF

!  Number of moments. Isotropic option removed 17 January 2006.

      IF ( DO_RAYLEIGH_ONLY ) THEN
        NMOMENTS = 2
      ENDIF
      IF ( .NOT.DO_RAYLEIGH_ONLY ) THEN
        NMOMENTS = MIN ( 2 * NSTREAMS - 1, NGREEK_MOMENTS_INPUT )
      ENDIF

!  Total quadratures (up and down)

      NSTREAMS_2 = 2*NSTREAMS

!  Additional quantities (Stokes)

      NSTOKES_SQ     = NSTOKES * NSTOKES
      NSTKS_NSTRMS   = NSTOKES * NSTREAMS
      NSTKS_NSTRMS_2 = NSTOKES * NSTREAMS_2

!  Mueller index

      DO O1 = 1, MAXSTOKES
        O1_S = MAXSTOKES*(O1 - 1)
        DO O2 = 1, MAXSTOKES
          MUELLER_INDEX(O1,O2) = O1_S + O2
        ENDDO
      ENDDO

!  Greek matrix index

      GREEKMAT_INDEX(1) = 1
      GREEKMAT_INDEX(2) = 6
      GREEKMAT_INDEX(3) = 2
      GREEKMAT_INDEX(4) = 11
      GREEKMAT_INDEX(5) = 12
      GREEKMAT_INDEX(6) = 16

!  Check number of particular solution modes
!   Current default is NPARTICSOLS = 1

      IF ( FLUXVEC(3).EQ.ZERO.AND.FLUXVEC(4).EQ.ZERO ) THEN
        NPARTICSOLS = 1
      ELSE
        NPARTICSOLS = 2
      ENDIF

!  D matrices, and multiply by Fluxvector

      DO O1 = 1, MAXSTOKES
        DFLUX(O1) = ZERO
        DO O2 = 1, MAXSTOKES
          DMAT(O1,O2) = ZERO
          DO P = 1, NPARTICSOLS
            DMAT_PSOLS(O1,O2,P) = ZERO
          ENDDO
        ENDDO
      ENDDO
      MS2 = MAXSTOKES/2
      DO O1 = 1, MS2
        O2 = O1 + MS2
        DMAT(O1,O1) = ONE
        DMAT(O2,O2) = -ONE
        DMAT_PSOLS(O1,O1,1) = ONE
        DMAT_PSOLS_FLUXVEC(O1,1) = FLUXVEC(O1)
        DFLUX(O1) = FLUXVEC(O1)
      ENDDO
      IF ( NPARTICSOLS .EQ. 2 ) THEN
        DO O1 = 1, MS2
          O2 = O1 + MS2
          DMAT_PSOLS(O2,O2,2) = ONE
          DMAT_PSOLS_FLUXVEC(O2,1) = FLUXVEC(O2)
          DFLUX(O2) = FLUXVEC(O2)
        ENDDO
      ENDIF

!  Set Quadrature abscissae and weights

      CALL GAULEG(ZERO,ONE,QUAD_STREAMS,QUAD_WEIGHTS,NSTREAMS)

!  Following code disabled from earlier versions
!      IF ( DO_FULL_QUADRATURE ) THEN
!        CALL GAULEG(-ONE,ONE,X2,A2,NSTR2)
!        DO I = 1, NSTREAMS
!          I1 = I + NSTREAMS
!          X(I) = X2(I1)
!          A(I) = A2(I1)
!        ENDDO
!      ENDIF

!  Set auxiliary quantities

      DO I = 1, NSTREAMS
        QUAD_STRMWTS(I) = QUAD_STREAMS(I)*QUAD_WEIGHTS(I)
        QUAD_HALFWTS(I) = HALF * QUAD_WEIGHTS(I)
        QUAD_ANGLES(I)  = DACOS(QUAD_STREAMS(I))/DEG_TO_RAD
        QUAD_SINES(I)   = DSQRT(ONE-QUAD_STREAMS(I)*QUAD_STREAMS(I))
      ENDDO

!  Size of boundary value problem matrices and vectors

      NTOTAL = NLAYERS*NSTKS_NSTRMS_2

!  Number of sub and super diagonals in band matrix (boundary value problem)

      IF ( NLAYERS .EQ. 1 ) THEN
        N_SUBDIAG = 2*NSTKS_NSTRMS - 1
        N_SUPDIAG = 2*NSTKS_NSTRMS - 1
      ELSE
        N_SUBDIAG = 3*NSTKS_NSTRMS - 1
        N_SUPDIAG = 3*NSTKS_NSTRMS - 1
      ENDIF

!  Solar zenith angle cosines/sines

      NBEAMS = N_SZANGLES
      DO I = 1, N_SZANGLES
        COS_SZANGLES(I)  = DCOS ( SZANGLES(I) * DEG_TO_RAD )
        SIN_SZANGLES(I) = DSQRT(ONE-COS_SZANGLES(I)*COS_SZANGLES(I))
      ENDDO

!  Set average cosines in the refractive geometry case

      IF ( DO_REFRACTIVE_GEOMETRY ) THEN
        DO I = 1, N_SZANGLES
          MU1 = DCOS(SZA_LOCAL_INPUT(0,I)*DEG_TO_RAD)
          DO N = 1, NLAYERS
            MU2 = DCOS(SZA_LOCAL_INPUT(N,I)*DEG_TO_RAD)
            SUN_SZA_COSINES(N,I) = HALF * ( MU1 + MU2 )
            MU1 = MU2
         ENDDO
        ENDDO
      ENDIF

!  Set performance flags
!  ---------------------

!  New section for Version 2.0 and higher.

!  Specialist Option 2: Set solution saving. BVP Telescoping
!   Set the layer-scattering flags to be false for all N up to NLAYERS_N

      IF ( DO_SPECIALIST_OPTION_2 ) THEN
        DO_SOLUTION_SAVING = .TRUE.
        DO_BVP_TELESCOPING = .TRUE.
        DO M = 0, NMOMENTS
          BVP_REGULAR_FLAG(M) = .FALSE.
          DO N = 1, NLAYERS_NOMS
            DO_LAYER_SCATTERING(M,N) = .FALSE.
          ENDDO
          DO N = NLAYERS_NOMS + 1, NLAYERS
            DO_LAYER_SCATTERING(M,N) = .TRUE.
          ENDDO
        ENDDO
        GO TO 4545
      ENDIF

!  Set the layer scattering flags
!  set the BVP telescoping flags

!  Initialise (M = Fourier index) to normal mode.

      DO M = 0, NMOMENTS
        BVP_REGULAR_FLAG(M) = .TRUE.
        DO N = 1, NLAYERS
          DO_LAYER_SCATTERING(M,N) = .TRUE.
        ENDDO
      ENDDO

!  Special clause for transmittance-only calculation
!   New flag, 31 July 2007. Move on to other bookkeeping

      IF ( DO_THERMAL_TRANSONLY ) THEN
        DO_SOLUTION_SAVING = .TRUE.
        DO N = 1, NLAYERS
          OMEGA_TOTAL_INPUT(N) = ZERO
          DO_LAYER_SCATTERING(0,N) = .FALSE.
        ENDDO
        GO TO 5557
      ENDIF

!  For M > 2 terms, if solution saving flag is set...
!  .... examine  Greek matrix entries (1,1) - no scattering if
!      they are all zero for L > M - 1.
!  [Equivalent to examining phase function moments]
!  Addition of Solution_saving flag, 22 November 2009.
!    Bug spotted by V. Natraj, 20 November 2009

!  No, should be set always, otherwise linearizations fail

      IF ( DO_SOLAR_SOURCES ) THEN
!       IF ( DO_SOLUTION_SAVING ) THEN
        DO M = 3, NMOMENTS
          QC = NMOMENTS - M + 1
          DO N = 1, NLAYERS
            Q = 0
            DO L = M, NMOMENTS
              IF(GREEKMAT_TOTAL_INPUT(L,N,1).EQ.ZERO)Q=Q+1
            ENDDO
            DO_LAYER_SCATTERING(M,N) = (Q.LT.QC)
          ENDDO
        ENDDO
!       ENDIF
      ENDIF

!  BVP telescoping (only if do_solution_saving is set)

      IF ( DO_SOLAR_SOURCES ) THEN
       IF ( DO_SOLUTION_SAVING ) THEN
        IF ( DO_BVP_TELESCOPING ) THEN
          DO M = 3, NMOMENTS
            Q = 0
            DO N = 1, NLAYERS
              IF (.NOT.DO_LAYER_SCATTERING(M,N))Q = Q + 1
            ENDDO
            IF ( Q.GT.1) BVP_REGULAR_FLAG(M) = .FALSE.
          ENDDO
        ENDIF
       ENDIF
      ENDIF

!    Set of Telescoped layers must be contiguous

      IF ( DO_SOLAR_SOURCES ) THEN
       IF ( DO_SOLUTION_SAVING ) THEN

        IF ( DO_BVP_TELESCOPING ) THEN
         DO M = 3, NMOMENTS
          NS = 0
          NAP = 0
          DO N = 1, NLAYERS
           IF ( DO_LAYER_SCATTERING(M,N) ) THEN
            NS = NS + 1
            NA = N
            IF ( NS.GT.1)  THEN
              IF ( NA.NE.NAP+1 ) THEN
                STATUS_SUB = VLIDORT_WARNING
                GO TO 4564
              ENDIF
            ENDIF
            NAP = NA
           ENDIF
          ENDDO
         ENDDO
        ENDIF

!  Collect warning and re-set default option

 4564   continue
        if ( STATUS_SUB .NE. VLIDORT_SUCCESS ) THEN
         MESSAGE = 'Telescoped layers not contiguous: turn off option'
         DO_BVP_TELESCOPING = .FALSE.
         DO M = 3, NMOMENTS
           BVP_REGULAR_FLAG(M) = .TRUE.
         ENDDO
        ENDIF

!  End clause

       ENDIF
      ENDIF

!  Continuation point for avoiding the default, if using Specialist # 2

 4545 CONTINUE

!  Save calculation time for single scattering.
!   Remove isotropic-only option. 17 January 2006.
!   Bug. 22 November 2006. L must be < Ngreek_moments_input in DO WHILE
!   Bug 31 January 2007. LAYER_MAXMOMENTS should be = nmoments_input

      IF ( DO_SOLAR_SOURCES ) THEN
       IF ( DO_SSCORR_NADIR .OR. DO_SSCORR_OUTGOING ) THEN
        IF ( DO_RAYLEIGH_ONLY ) THEN
          DO N = 1, NLAYERS
            LAYER_MAXMOMENTS(N) = 2
          ENDDO
        ELSE
         DO N = 1, NLAYERS
            L = 2
            LOOP = .TRUE.
            DO WHILE (LOOP.AND.L.LT.NGREEK_MOMENTS_INPUT)
              L = L + 1
              LOOP= (GREEKMAT_TOTAL_INPUT(L,N,1).NE.ZERO)
            ENDDO
!            LAYER_MAXMOMENTS(N) = L - 1
            LAYER_MAXMOMENTS(N) = L
          ENDDO
        ENDIF
       ENDIF
      ENDIF

!  Set the Eigensolver Mask. New section 21 December 2005.
!   1. Always set the Real Eigensolver for Rayleigh-only or Scalar-only
!   2. Otherwise, examine the occurrence of the "epsilon" Greek constant

      IF ( DO_RAYLEIGH_ONLY .OR. NSTOKES.EQ.1 ) THEN
       DO M = 0, NMOMENTS
        DO N = 1, NLAYERS
         DO_REAL_EIGENSOLVER(M,N) = .TRUE.
        ENDDO
       ENDDO
      ELSE
       DO M = 0, NMOMENTS
        DO N = 1, NLAYERS
         IF ( DO_LAYER_SCATTERING(M,N) ) THEN
           EC = 0
           DO L = M, NMOMENTS
!mick fix 1/22/2013 - added NSTOKES IF condition
            !IF (GREEKMAT_TOTAL_INPUT(L,N,12).NE.ZERO) EC = EC + 1
            IF (NSTOKES.EQ.4) THEN
              IF (GREEKMAT_TOTAL_INPUT(L,N,12).NE.ZERO ) EC = EC + 1
            ENDIF
           ENDDO
           DO_REAL_EIGENSOLVER(M,N) = (EC.EQ.ZERO)
!mick fix 2/17/11 - added ELSE
         ELSE
           DO_REAL_EIGENSOLVER(M,N) = .TRUE.
         ENDIF
        ENDDO
       ENDDO
      ENDIF

!  Debug

!      DO M = 0, NMOMENTS
!       write(*,'(I4,L2,5x,7L2)')M,BVP_REGULAR_FLAG(M),
!     &             (DO_LAYER_SCATTERING(M,N),N=1,7)
!        ENDDO
!      PAUSE

!  Continuation point

 5557 continue

!  User stream cosines and secants

      IF ( DO_USER_STREAMS ) THEN
        DO I = 1, N_USER_VZANGLES
!          USER_STREAMS(I) = DCOS(DEG_TO_RAD*USER_VZANGLES(I))
          USER_STREAMS(I) = DCOS(DEG_TO_RAD*USER_VZANGLES_ADJUST(I))
          USER_SECANTS(I) = ONE / USER_STREAMS(I)
          USER_SINES(I) = DSQRT(ONE-USER_STREAMS(I)*USER_STREAMS(I))
        ENDDO
      ENDIF

!  Number of tests to be applied for convergence
!  Number of streams for convergence
!    - Zenith tolerance no longer applies for the vector code
!    - Set CONV_START_STREAMS = 1. Do not examine for "Zenith_tolerance"

      CONV_START_STREAMS = 1
      N_CONV_STREAMS = N_OUT_STREAMS - CONV_START_STREAMS + 1

      IF ( .not. DO_OBSERVATION_GEOMETRY ) THEN
        N_CONVTESTS = N_USER_RELAZMS * N_CONV_STREAMS * N_DIRECTIONS
        N_CONVTESTS = N_CONVTESTS * N_USER_LEVELS
      ELSE
        N_CONVTESTS = N_DIRECTIONS * N_USER_LEVELS
      ENDIF

!  Sort out User vertical level outputs
!  ------------------------------------

!  Sort in ascending order

      IF ( N_USER_LEVELS .GT. 1 ) THEN
        CALL HPSORT(N_USER_LEVELS,USER_LEVELS)
      ENDIF

!  Mark all output levels not equal to layer boundary values

      NSTART = 0
      UT = 0
      DO UTA = 1, N_USER_LEVELS
        DT = USER_LEVELS(UTA)
        RT = DT - DBLE(INT(DT))
        N = INT(DT) + 1
        IF ( RT.GT.ZERO) THEN
          UT = UT + 1
          PARTLAYERS_OUTFLAG(UTA)  = .TRUE.
          PARTLAYERS_OUTINDEX(UTA) = UT
          PARTLAYERS_LAYERIDX(UT)  = N
          UTAU_LEVEL_MASK_UP(UTA) = N
          UTAU_LEVEL_MASK_DN(UTA) = N - 1
          PARTLAYERS_VALUES(UT)    = RT
        ELSE
          PARTLAYERS_OUTFLAG(UTA)  = .FALSE.
          PARTLAYERS_OUTINDEX(UTA) =   0
          UTAU_LEVEL_MASK_UP(UTA) = N - 1
          UTAU_LEVEL_MASK_DN(UTA) = N - 1
        ENDIF
      ENDDO
      N_PARTLAYERS = UT
      DO_PARTLAYERS = ( N_PARTLAYERS .NE. 0 )

!  Set masking and number of layer source terms
!  --------------------------------------------

!   .. for upwelling

!mick fix 6/25/2012 - initialize outside
      DO N = 1, NLAYERS
        STERM_LAYERMASK_UP(N) = .FALSE.
      ENDDO
      IF ( DO_UPWELLING ) THEN
        !DO N = 1, NLAYERS
        !  STERM_LAYERMASK_UP(N) = .FALSE.
        !ENDDO
        UTA = 1
        UT  = 1
        IF ( .NOT. PARTLAYERS_OUTFLAG(UTA) ) THEN
          N_LAYERSOURCE_UP = UTAU_LEVEL_MASK_UP(UTA) + 1
          N_ALLLAYERS_UP   = N_LAYERSOURCE_UP
        ELSE
          N_LAYERSOURCE_UP = PARTLAYERS_LAYERIDX(UT) + 1
          N_ALLLAYERS_UP   = N_LAYERSOURCE_UP - 1
        ENDIF
        DO N = NLAYERS, N_ALLLAYERS_UP, -1
          STERM_LAYERMASK_UP(N) = .TRUE.
        ENDDO
      ENDIF

!   .. for downwelling

!mick fix 6/25/2012 - initialize outside
      DO N = 1, NLAYERS
        STERM_LAYERMASK_DN(N) = .FALSE.
      ENDDO
      IF ( DO_DNWELLING ) THEN
        !DO N = 1, NLAYERS
        !  STERM_LAYERMASK_DN(N) = .FALSE.
        !ENDDO
        UTA = N_USER_LEVELS
        UT  = N_PARTLAYERS
        IF ( .NOT. PARTLAYERS_OUTFLAG(UTA) ) THEN
          N_LAYERSOURCE_DN = UTAU_LEVEL_MASK_DN(UTA)
          N_ALLLAYERS_DN   = N_LAYERSOURCE_DN
        ELSE
          N_LAYERSOURCE_DN = PARTLAYERS_LAYERIDX(UT)
          N_ALLLAYERS_DN   = N_LAYERSOURCE_DN
        ENDIF
        DO N = 1, N_ALLLAYERS_DN
          STERM_LAYERMASK_DN(N) = .TRUE.
        ENDDO
      ENDIF

!  Define TauGrid_Input
!  --------------------

      TAUGRID_INPUT(0) = ZERO
      DO N = 1, NLAYERS
        TAUGRID_INPUT(N) = TAUGRID_INPUT(N-1) + DELTAU_VERT_INPUT(N)
      END DO

!  Finish

      RETURN
      END SUBROUTINE VLIDORT_DERIVE_INPUT

      END MODULE vlidort_inputs

