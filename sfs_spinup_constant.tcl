#---------------------------------------------------------
# 1.  IMPORT PARFLOW TCL PACKAGE
# 2.  SET PROCESSORS
# 3.  SETUP RUN DIRECTORY
# 4.  COPY INPUT FILES
# 5.  SPECIFY TOPO SLOPES
# 6.  COMPUTATIONAL GRID
# 7.  SPINUP KEYS
# 8.  TIMING (units: hr)
# 9.  TIME CYCLES (units: hr)
# 10. INITIAL CONDITIONS: WATER PRESSURE
# 11. BOUNDARY CONDITIONS: PRESSURE
# 12. SUBSURFACE LAYERS
# 13. GEOMETRY INPUTS
# 14. PERMEABILITY (units: m/hr)
# 15. RELATIVE PERMEABILITY
# 16. POROSITY
# 17. SATURATION
# 18. SPECIFIC STORAGE
# 19. MANNINGS COEFFICIENT
# 20. PHASES AND PHASE SOURCES
# 21. GRAVITY
# 22. DOMAIN
# 23. MOBILITY
# 24. CONTAMINANTS, RETARDATION, WELLS
# 25. EXACT SOLUTION SPECIFICATION FOR ERROR CALCULATIONS
# 26. SET SOLVER PARAMETERS
# 27. OUTPUT SETTINGS
# 28. DISTRIBUTE, RUN SIMULATION, UNDISTRIBUTE
#---------------------------------------------------------




#---------------------------------------------------------
# RUN NOTES: 
#---------------------------------------------------------
# pf spinup for south fork salmon domain
# 5e5 timesteps (dt=1hr)
# constant value: 0.0001
# output every 2000 timesteps




#---------------------------------------
# 1. IMPORT PARFLOW TCL PACKAGE
#---------------------------------------
set tcl_precision 17
lappend auto_path $env(PARFLOW_DIR)/bin
package require parflow
namespace import Parflow::*
pfset FileVersion 4
#---------------------------------------




#--------------------------
# 2. SET PROCESSORS
#--------------------------
pfset Process.Topology.P 4
pfset Process.Topology.Q 4
pfset Process.Topology.R 1
#--------------------------




#------------------------------------------------------
# 3. SETUP RUN DIRECTORY
#------------------------------------------------------
set runname spinup_overlandflow
cd "output_files"
file mkdir $runname 
cd $runname
#------------------------------------------------------
file copy -force ../../input_files/sfs_slopex.pfb .
file copy -force ../../input_files/sfs_slopey.pfb .
file copy -force ../../input_files/sfs.pfsol .
file copy -force ../../input_files/sfs_grid3d.v3.pfb .
#------------------------------------------------------
#file copy -force "../clm_input/sfs_clmin.dat" .
#file copy -force "../clm_input/sfs_vegp.dat"  .
#file copy -force "../clm_input/sfs_vegm.dat"  .
#------------------------------------------------------
puts "Files Copied"
#------------------------------------------------------




#--------------------------------------------
# 5. SPECIFY TOPO SLOPES
#--------------------------------------------
pfset TopoSlopesX.Type        "PFBFile"
pfset TopoSlopesY.Type        "PFBFile"
#--------------------------------------------
pfset TopoSlopesX.GeomNames   "domain"
pfset TopoSlopesY.GeomNames   "domain"
#--------------------------------------------
pfset TopoSlopesX.FileName    sfs_slopex.pfb
pfset TopoSlopesY.FileName    sfs_slopey.pfb
#--------------------------------------------




#----------------------------------------
# 6. COMPUTATIONAL GRID
#----------------------------------------
pfset ComputationalGrid.Lower.X   0.0
pfset ComputationalGrid.Lower.Y   0.0
pfset ComputationalGrid.Lower.Z   0.0
#----------------------------------------
pfset ComputationalGrid.NX        64
pfset ComputationalGrid.NY        128
pfset ComputationalGrid.NZ        5
#----------------------------------------
pfset ComputationalGrid.DX        1000.0
pfset ComputationalGrid.DY        1000.0
pfset ComputationalGrid.DZ        200.0
#----------------------------------------




#-------------------------------------
# 7. SPINUP KEYS
#-------------------------------------
#pfset OverlandFlowSpinUp        1
#pfset OverlandSpinupDampP1      10.0
#pfset OverlandSpinupDampP2      0.1
#-------------------------------------




#-----------------------------------------
# 8. TIMING (units: hr)
#-----------------------------------------
pfset TimingInfo.StartCount      0
#-----------------------------------------
pfset TimingInfo.BaseUnit        1.0
#-----------------------------------------
pfset TimeStep.Type              Constant
pfset TimeStep.Value             1.0
#-----------------------------------------
pfset TimingInfo.StartTime       0.0
pfset TimingInfo.StopTime        500000
#-----------------------------------------
pfset TimingInfo.DumpInterval    2000
#-----------------------------------------




#----------------------------------------------------------
# 9. TIME CYCLES (units: hr)
#----------------------------------------------------------
pfset Cycle.Names                       "constant rainrec"
#----------------------------------------------------------
pfset Cycle.constant.Names              "alltime"
pfset Cycle.constant.alltime.Length     1
pfset Cycle.constant.Repeat             -1
#----------------------------------------------------------
pfset Cycle.rainrec.Names               "rain rec"
pfset Cycle.rainrec.rain.Length         500
pfset Cycle.rainrec.rec.Length          4500
pfset Cycle.rainrec.Repeat              -1
#----------------------------------------------------------




#------------------------------------------------------------
# 10. INITIAL CONDITIONS: WATER PRESSURE
#------------------------------------------------------------
pfset ICPressure.Type                       HydroStaticPatch
pfset ICPressure.GeomNames                  domain
#------------------------------------------------------------
pfset Geom.domain.ICPressure.RefGeom        domain
pfset Geom.domain.ICPressure.Value          0
pfset Geom.domain.ICPressure.RefPatch       bottom
#------------------------------------------------------------




#-----------------------------------------------------------------
# 11. BOUNDARY CONDITIONS: PRESSURE
#-----------------------------------------------------------------
pfset Solver.EvapTransFile                      False
#-----------------------------------------------------------------
pfset BCPressure.PatchNames                     "land top bottom"
#-----------------------------------------------------------------
pfset Patch.land.BCPressure.Type                FluxConst
pfset Patch.land.BCPressure.Cycle               "constant"
pfset Patch.land.BCPressure.alltime.Value       0.0
#-----------------------------------------------------------------
pfset Patch.top.BCPressure.Type                 FluxConst
pfset Patch.top.BCPressure.Cycle                "constant"
pfset Patch.top.BCPressure.alltime.Value        -0.0001
#pfset Patch.top.BCPressure.rain.Value           -0.001
#pfset Patch.top.BCPressure.rec.Value            0
#-----------------------------------------------------------------
pfset Patch.bottom.BCPressure.Type              FluxConst
pfset Patch.bottom.BCPressure.Cycle             "constant"
pfset Patch.bottom.BCPressure.alltime.Value     0.0
#-----------------------------------------------------------------




#------------------------------------------
# 12. SUBSURFACE LAYERS
#------------------------------------------
pfset Solver.Nonlinear.VariableDz   True
#------------------------------------------
pfset dzScale.GeomNames             domain
pfset dzScale.Type                  nzList
pfset dzScale.nzListNumber          5
#------------------------------------------
pfset Cell.0.dzScale.Value          0.5
pfset Cell.1.dzScale.Value          0.005
pfset Cell.2.dzScale.Value          0.003
pfset Cell.3.dzScale.Value          0.0015
pfset Cell.4.dzScale.Value          0.0005
#------------------------------------------




#-----------------------------------------------------------------------------------
# 13. GEOMETRY INPUTS
#-----------------------------------------------------------------------------------
pfset GeomInput.Names                  "domaininput indicatorinput"
#-----------------------------------------------------------------------------------
pfset GeomInput.domaininput.GeomName   domain
pfset GeomInput.domaininput.GeomNames   domain
pfset GeomInput.domaininput.InputType  SolidFile
pfset GeomInput.domaininput.FileName   sfs.pfsol
pfset Geom.domain.Patches              "land top bottom"
#-----------------------------------------------------------------------------------
pfset GeomInput.indicatorinput.GeomNames   "s1 s2 s3 s4 s5 g1 g2 g3 g4 g5 g6 b1 b2"
pfset GeomInput.indicatorinput.InputType   IndicatorField
pfset Geom.indicatorinput.FileName         "sfs_grid3d.v3.pfb"
#-----------------------------------------------------------------------------------
pfset GeomInput.s1.Value    2
pfset GeomInput.s2.Value    3
pfset GeomInput.s3.Value    4
pfset GeomInput.s4.Value    6
pfset GeomInput.s5.Value    7
pfset GeomInput.g1.Value    21
pfset GeomInput.g2.Value    22
pfset GeomInput.g3.Value    23
pfset GeomInput.g4.Value    24
pfset GeomInput.g5.Value    25
pfset GeomInput.g6.Value    26
pfset GeomInput.b1.Value    19
pfset GeomInput.b2.Value    20
#-----------------------------------------------------------------------------------




#--------------------------------------------------------------------------------------
# 14. PERMEABILITY (units: m/hr)
#--------------------------------------------------------------------------------------
pfset Geom.Perm.Names                  "domain s1 s2 s3 s4 s5 g1 g2 g3 g4 g5 g6 b1 b2"
#--------------------------------------------------------------------------------------
pfset Geom.domain.Perm.Type            Constant
pfset Geom.s1.Perm.Type                Constant
pfset Geom.s2.Perm.Type                Constant
pfset Geom.s3.Perm.Type                Constant
pfset Geom.s4.Perm.Type                Constant
pfset Geom.s5.Perm.Type                Constant
pfset Geom.g1.Perm.Type                Constant
pfset Geom.g2.Perm.Type                Constant
pfset Geom.g3.Perm.Type                Constant
pfset Geom.g4.Perm.Type                Constant
pfset Geom.g5.Perm.Type                Constant
pfset Geom.g6.Perm.Type                Constant
pfset Geom.b1.Perm.Type                Constant
pfset Geom.b2.Perm.Type                Constant
#--------------------------------------------------------------------------------------
pfset Geom.domain.Perm.Value           0.02
pfset Geom.s1.Perm.Value               0.043630356
pfset Geom.s2.Perm.Value               0.015841225
pfset Geom.s3.Perm.Value               0.007582087
pfset Geom.s4.Perm.Value               0.005009435
pfset Geom.s5.Perm.Value               0.005492736
pfset Geom.g1.Perm.Value               0.02
pfset Geom.g2.Perm.Value               0.03
pfset Geom.g3.Perm.Value               0.04
pfset Geom.g4.Perm.Value               0.05
pfset Geom.g5.Perm.Value               0.06
pfset Geom.g6.Perm.Value               0.08
pfset Geom.b1.Perm.Value               0.005
pfset Geom.b2.Perm.Value               0.01
#--------------------------------------------------------------------------------------
pfset Perm.TensorType                  TensorByGeom
pfset Geom.Perm.TensorByGeom.Names     "domain"
pfset Geom.domain.Perm.TensorValX      1.0d0
pfset Geom.domain.Perm.TensorValY      1.0d0
pfset Geom.domain.Perm.TensorValZ      1.0d0
#--------------------------------------------------------------------------------------




#------------------------------------------------------------------------
# 15. RELATIVE PERMEABILITY
#------------------------------------------------------------------------
pfset Phase.RelPerm.Type                         VanGenuchten
pfset Phase.RelPerm.GeomNames                    "domain s1 s2 s3 s4 s5"
#------------------------------------------------------------------------
pfset Geom.domain.RelPerm.Alpha                  1.0
pfset Geom.s1.RelPerm.Alpha                      3.467
pfset Geom.s2.RelPerm.Alpha                      2.692
pfset Geom.s3.RelPerm.Alpha                      0.501
pfset Geom.s4.RelPerm.Alpha                      1.122
pfset Geom.s5.RelPerm.Alpha                      2.089
#------------------------------------------------------------------------ 
pfset Geom.domain.RelPerm.N                      3.0
pfset Geom.s1.RelPerm.N                          2.738
pfset Geom.s2.RelPerm.N                          2.445
pfset Geom.s3.RelPerm.N                          2.659
pfset Geom.s4.RelPerm.N                          2.479
pfset Geom.s5.RelPerm.N                          2.318
#------------------------------------------------------------------------
pfset Geom.domain.RelPerm.NumSamplePoints        20000
pfset Geom.s1.RelPerm.NumSamplePoints            20000
pfset Geom.s2.RelPerm.NumSamplePoints            20000
pfset Geom.s3.RelPerm.NumSamplePoints            20000
pfset Geom.s4.RelPerm.NumSamplePoints            20000
pfset Geom.s5.RelPerm.NumSamplePoints            20000
#------------------------------------------------------------------------
pfset Geom.domain.RelPerm.MinPressureHead        -300
pfset Geom.s1.RelPerm.MinPressureHead            -300
pfset Geom.s2.RelPerm.MinPressureHead            -300
pfset Geom.s3.RelPerm.MinPressureHead            -300
pfset Geom.s4.RelPerm.MinPressureHead            -300
pfset Geom.s5.RelPerm.MinPressureHead            -300
#------------------------------------------------------------------------
pfset Geom.domain.RelPerm.InterpolationMethod    Linear
pfset Geom.s1.RelPerm.InterpolationMethod        Linear
pfset Geom.s2.RelPerm.InterpolationMethod        Linear
pfset Geom.s3.RelPerm.InterpolationMethod        Linear
pfset Geom.s4.RelPerm.InterpolationMethod        Linear
pfset Geom.s5.RelPerm.InterpolationMethod        Linear
#------------------------------------------------------------------------




#---------------------------------------------------------------------------------
# 16. POROSITY
#---------------------------------------------------------------------------------
pfset Geom.Porosity.GeomNames           "domain s1 s2 s3 s4 s5 g1 g2 g3 g4 g5 g6"
#---------------------------------------------------------------------------------
pfset Geom.domain.Porosity.Type         Constant
pfset Geom.s1.Porosity.Type             Constant
pfset Geom.s2.Porosity.Type             Constant
pfset Geom.s3.Porosity.Type             Constant
pfset Geom.s4.Porosity.Type             Constant
pfset Geom.s5.Porosity.Type             Constant
pfset Geom.g1.Porosity.Type             Constant
pfset Geom.g2.Porosity.Type             Constant
pfset Geom.g3.Porosity.Type             Constant
pfset Geom.g4.Porosity.Type             Constant
pfset Geom.g5.Porosity.Type             Constant
pfset Geom.g6.Porosity.Type             Constant
#---------------------------------------------------------------------------------
pfset Geom.domain.Porosity.Value        0.33
pfset Geom.s1.Porosity.Value            0.39
pfset Geom.s2.Porosity.Value            0.387
pfset Geom.s3.Porosity.Value            0.439
pfset Geom.s4.Porosity.Value            0.399
pfset Geom.s5.Porosity.Value            0.384
pfset Geom.g1.Porosity.Value            0.33
pfset Geom.g2.Porosity.Value            0.33
pfset Geom.g3.Porosity.Value            0.33
pfset Geom.g4.Porosity.Value            0.33
pfset Geom.g5.Porosity.Value            0.33
pfset Geom.g6.Porosity.Value            0.33
#---------------------------------------------------------------------------------




#-----------------------------------------------------------------
# 17. SATURATION
#-----------------------------------------------------------------
pfset Phase.Saturation.Type               VanGenuchten
pfset Phase.Saturation.GeomNames          "domain s1 s2 s3 s4 s5"
#-----------------------------------------------------------------
pfset Geom.domain.Saturation.Alpha        1.0
pfset Geom.s1.Saturation.Alpha            3.467
pfset Geom.s2.Saturation.Alpha            2.692
pfset Geom.s3.Saturation.Alpha            0.501
pfset Geom.s4.Saturation.Alpha            1.122
pfset Geom.s5.Saturation.Alpha            2.089
#-----------------------------------------------------------------
pfset Geom.domain.Saturation.N            3.0
pfset Geom.s1.Saturation.N                2.738
pfset Geom.s2.Saturation.N                2.445
pfset Geom.s3.Saturation.N                2.659
pfset Geom.s4.Saturation.N                2.479
pfset Geom.s5.Saturation.N                2.318
#-----------------------------------------------------------------
pfset Geom.domain.Saturation.SRes         0.001
pfset Geom.s1.Saturation.SRes             0.0001
pfset Geom.s2.Saturation.SRes             0.0001
pfset Geom.s3.Saturation.SRes             0.0001
pfset Geom.s4.Saturation.SRes             0.0001
pfset Geom.s5.Saturation.SRes             0.0001
#-----------------------------------------------------------------
pfset Geom.domain.Saturation.SSat         1.0
pfset Geom.s1.Saturation.SSat             1.0
pfset Geom.s2.Saturation.SSat             1.0
pfset Geom.s3.Saturation.SSat             1.0
pfset Geom.s4.Saturation.SSat             1.0
pfset Geom.s5.Saturation.SSat             1.0
#-----------------------------------------------------------------




#--------------------------------------------------
# 18. SPECIFIC STORAGE
#--------------------------------------------------
pfset SpecificStorage.GeomNames           "domain"
pfset SpecificStorage.Type                Constant
pfset Geom.domain.SpecificStorage.Value   1.0e-4
#--------------------------------------------------




#-----------------------------------------------
# 19. MANNINGS COEFFICIENT
#-----------------------------------------------
pfset Mannings.GeomNames             "domain"
pfset Mannings.Type                  "Constant"
pfset Mannings.Geom.domain.Value     0.0000044
#-----------------------------------------------




#----------------------------------------------------------
# 20. PHASES AND PHASE SOURCES
#----------------------------------------------------------
pfset Phase.Names                                 "water"
#----------------------------------------------------------
pfset Phase.water.Density.Type	                  Constant
pfset Phase.water.Density.Value	                  1.0
#----------------------------------------------------------
pfset Phase.water.Viscosity.Type                  Constant
pfset Phase.water.Viscosity.Value                 1.0
#----------------------------------------------------------
pfset PhaseSources.water.Type                     Constant
pfset PhaseSources.water.GeomNames                domain
pfset PhaseSources.water.Geom.domain.Value        0.0
#----------------------------------------------------------




#-------------------------------
# 21. GRAVITY
#-------------------------------
pfset Gravity               1.0
#-------------------------------




#--------------------------------
# 22. DOMAIN
#--------------------------------
pfset Domain.GeomName     domain
#--------------------------------




#-----------------------------------------------
# 23. MOBILITY
#-----------------------------------------------
pfset Phase.water.Mobility.Type        Constant
pfset Phase.water.Mobility.Value       1.0
#-----------------------------------------------




#--------------------------------------------
# 24. CONTAMINANTS, RETARDATION, WELLS
#--------------------------------------------
pfset Contaminants.Names                  ""
#--------------------------------------------
pfset Geom.Retardation.GeomNames          ""
#--------------------------------------------
pfset Wells.Names                         ""
#--------------------------------------------




#---------------------------------------------------------
# 25. EXACT SOLUTION SPECIFICATION FOR ERROR CALCULATIONS
#---------------------------------------------------------
pfset KnownSolution               NoKnownSolution
#---------------------------------------------------------




#---------------------------------------------------------------------
# 26. SET SOLVER PARAMETERS
#---------------------------------------------------------------------
pfset Solver                                             Richards
pfset Solver.TerrainFollowingGrid                        True
pfset Solver.Nonlinear.UseJacobian                       True
pfset Solver.Nonlinear.EtaChoice                         EtaConstant
pfset Solver.Linear.Preconditioner                       PFMG
pfset Solver.Linear.Preconditioner.PCMatrixType          FullJacobian
#---------------------------------------------------------------------
pfset Solver.MaxIter                                     1000000
pfset Solver.MaxConvergenceFailures                      5
pfset Solver.Linear.KrylovDimension                      500
pfset Solver.Linear.MaxRestarts                          8
pfset Solver.Nonlinear.MaxIter                           80
pfset Solver.Nonlinear.ResidualTol                       1e-5
pfset Solver.Nonlinear.EtaValue                          1e-3
pfset Solver.Nonlinear.DerivativeEpsilon                 1e-16
pfset Solver.Nonlinear.StepTol                           1e-25
#---------------------------------------------------------------------




#-----------------------------------------------------------
# 27. OUTPUT SETTINGS
#-----------------------------------------------------------
pfset Solver.WriteSiloSpecificStorage                 True
pfset Solver.WriteSiloMannings                        True
pfset Solver.WriteSiloMask                            True
pfset Solver.WriteSiloSlopes                          True
pfset Solver.WriteSiloSubsurfData                     True
pfset Solver.WriteSiloPressure                        True
pfset Solver.WriteSiloSaturation                      True
pfset Solver.WriteSiloEvapTrans                       False
pfset Solver.WriteSiloEvapTransSum                    False
pfset Solver.WriteSiloOverlandSum                     True
pfset Solver.WriteSiloCLM                             False
#-----------------------------------------------------------
pfset Solver.WriteCLMBinary                           False
#-----------------------------------------------------------
pfset Solver.PrintSubsurfData                         True
pfset Solver.PrintMask                                True
pfset Solver.PrintVelocities                          False
pfset Solver.PrintSaturation                          True
pfset Solver.PrintPressure                            True
pfset Solver.PrintSubsurfData                         True
#-----------------------------------------------------------




#----------------------------------------------
# 28. DISTRIBUTE, RUN SIMULATION, UNDISTRIBUTE
#----------------------------------------------
pfdist -nz 1 sfs_slopex.pfb
pfdist -nz 1 sfs_slopey.pfb
pfdist sfs_grid3d.v3.pfb
#----------------------------------------------
puts    $runname
pfrun   $runname
pfundist $runname
#----------------------------------------------
pfundist sfs_slopex.pfb
pfundist sfs_slopey.pfb
pfundist sfs_grid3d.v3.pfb
#----------------------------------------------
puts "ParFlow run complete"
#----------------------------------------------




#---------------------------------------------------------
# 1.  IMPORT PARFLOW TCL PACKAGE
# 2.  SET PROCESSORS
# 3.  SETUP RUN DIRECTORY
# 4.  COPY INPUT FILES
# 5.  SPECIFY TOPO SLOPES
# 6.  COMPUTATIONAL GRID
# 7.  SPINUP KEYS
# 8.  TIMING (units: hr)
# 9.  TIME CYCLES (units: hr)
# 10. INITIAL CONDITIONS: WATER PRESSURE
# 11. BOUNDARY CONDITIONS: PRESSURE
# 12. SUBSURFACE LAYERS
# 13. GEOMETRY INPUTS
# 14. PERMEABILITY (units: m/hr)
# 15. RELATIVE PERMEABILITY
# 16. POROSITY
# 17. SATURATION
# 18. SPECIFIC STORAGE
# 19. MANNINGS COEFFICIENT
# 20. PHASES AND PHASE SOURCES
# 21. GRAVITY
# 22. DOMAIN
# 23. MOBILITY
# 24. CONTAMINANTS, RETARDATION, WELLS
# 25. EXACT SOLUTION SPECIFICATION FOR ERROR CALCULATIONS
# 26. SET SOLVER PARAMETERS
# 27. OUTPUT SETTINGS
# 28. DISTRIBUTE, RUN SIMULATION, UNDISTRIBUTE
#---------------------------------------------------------















