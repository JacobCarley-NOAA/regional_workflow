#!/bin/bash -l
#
#-----------------------------------------------------------------------
#
# This script generates:
#
# 1) A NetCDF initial condition (IC) file on a regional grid for the
#    date/time on which the analysis files in the directory specified by
#    INIDIR are valid.  Note that this file does not include data in the
#    halo of this regional grid (that data is found in the boundary con-
#    dition (BC) files).
#
# 2) A NetCDF surface file on the regional grid.  As with the IC file,
#    this file does not include data in the halo.
#
# 3) A NetCDF boundary condition (BC) file containing data on the halo
#    of the regional grid at the initial time (i.e. at the same time as
#    the one at which the IC file is valid).
#
# 4) A NetCDF "control" file named gfs_ctrl.nc that contains infor-
#    mation on the vertical coordinate and the number of tracers for
#    which initial and boundary conditions are provided.
#
# All four of these NetCDF files are placed in the directory specified
# by WORKDIR_ICSLBCS_CDATE, defined as
#
#   WORKDIR_ICSLBCS_CDATE="$WORKDIR_ICSLBCS/$CDATE"
#
# where CDATE is the externally specified starting date and cycle hour
# of the current forecast.
#
#-----------------------------------------------------------------------

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set the name of and create the directory in which the output from this
# script will be placed (if it doesn't already exist).
#
#-----------------------------------------------------------------------
#
WORKDIR_ICSLBCS_CDATE="$WORKDIR_ICSLBCS/$CDATE"
WORKDIR_ICSLBCS_CDATE_ICSSURF_WORK="$WORKDIR_ICSLBCS_CDATE/ICSSURF_work"
mkdir_vrfy -p "$WORKDIR_ICSLBCS_CDATE_ICSSURF_WORK"
cd ${WORKDIR_ICSLBCS_CDATE_ICSSURF_WORK}
#-----------------------------------------------------------------------
#
# Set the directory in which all executables called by this script are
# located.
#
#-----------------------------------------------------------------------
#
export exec_dir="$FV3SAR_DIR/exec"
#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
case "$MACHINE" in
#
"WCOSS_C")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"WCOSS")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"DELL")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

   ulimit -s unlimited
   ulimit -a

   module purge
   module load intel/18.1.163
   module load impi/5.1.1.109
   module load netcdf/4.3.0
   module load hdf5/1.8.14
   module load wgrib2/2.0.8
   module load contrib wrap-mpi
   module list

  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"JET")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"ODIN")
#
  ;;
#
"CHEYENNE")
#
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Create links to the grid and orography files with 4 halo cells.  These
# are needed by chgres_cube to create the boundary data.
#
#-----------------------------------------------------------------------
#
# Are these still needed for chgres_cube?
#
ln_vrfy -sf $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh4_T7}.nc \
            $WORKDIR_SHVE/${CRES}_grid.tile7.nc

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh4_T7}.nc \
            $WORKDIR_SHVE/${CRES}_oro_data.tile7.nc
#
#-----------------------------------------------------------------------
#
# Find the directory in which the wgrib2 executable is located.
#
#-----------------------------------------------------------------------
#
WGRIB2_DIR=$( which wgrib2 ) || print_err_msg_exit "\
Directory in which the wgrib2 executable is located not found:
  WGRIB2_DIR = \"${WGRIB2_DIR}\"
"
#
#-----------------------------------------------------------------------
#
# Set the directory containing the external model output files.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FILES_DIR="${EXTRN_MDL_FILES_BASEDIR_ICSSURF}/${CDATE}"
#
#-----------------------------------------------------------------------
#
# Source the file (generated by a previous task) that contains variable
# definitions (e.g. forecast hours, file and directory names, etc) re-
# lated to the exteranl model run that is providing fields from which
# we will generate LBC files for the FV3SAR.
#
#-----------------------------------------------------------------------
#
. ${EXTRN_MDL_FILES_DIR}/${EXTRN_MDL_INFO_FN}
#
#-----------------------------------------------------------------------
#
# Get the name of the external model to use in the chgres FORTRAN name-
# list file.
#
#-----------------------------------------------------------------------
#
case "$EXTRN_MDL_NAME_ICSSURF" in
#
"GFS")
  external_model="GFS"
  ;;
"RAPX")
  external_model="RAP"
  ;;
"HRRRX")
  external_model="HRRR"
  ;;
*)
  print_err_msg_exit "\
The external model name to use in the chgres FORTRAN namelist file is 
not specified for this external model:
  EXTRN_MDL_NAME_ICSSURF = \"${EXTRN_MDL_NAME_ICSSURF}\"
"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Get the name of the physics suite to use in the chgres FORTRAN name-
# list file.
#
#-----------------------------------------------------------------------
#
case "$CCPP_phys_suite" in
#
"GFS")
  phys_suite="GFS"
  ;;
"GSD")
  phys_suite="GSD"
  ;;
*)
  print_err_msg_exit "\
The physics suite name to use in the chgres FORTRAN namelist file is not
specified for this physics suite:
  CCPP_phys_suite = \"${CCPP_phys_suite}\"
"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Get the starting year, month, day, and hour of the the external model
# run.
#
#-----------------------------------------------------------------------
#
#yyyy="${EXTRN_MDL_CDATE:0:4}"
mm="${EXTRN_MDL_CDATE:4:2}"
dd="${EXTRN_MDL_CDATE:6:2}"
hh="${EXTRN_MDL_CDATE:8:2}"
#yyyymmdd="${EXTRN_MDL_CDATE:0:8}"
#
#-----------------------------------------------------------------------
#
# Set external model output file name(s) and file type/format.  Note 
# that these are now inputs into chgres.
#
#-----------------------------------------------------------------------
#
fn_atm_nemsio=""
fn_sfc_nemsio=""
fn_grib2=""
input_type=""

case "$EXTRN_MDL_NAME_ICSSURF" in
"GFS")
  fn_atm_nemsio="${EXTRN_MDL_FNS[0]}"
  fn_sfc_nemsio="${EXTRN_MDL_FNS[1]}"
  input_type="gfs_gaussian" # For spectral GFS Gaussian grid in nemsio format.
#  input_type="gaussian"     # For FV3-GFS Gaussian grid in nemsio format.
  ;;
"RAPX")
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
  ;;
"HRRRX")
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
  ;;
*)
  print_err_msg_exit "\
The external model output file name(s) and file type/format to use in the
chgres FORTRAN namelist file are not specified for this external model:
  EXTRN_MDL_NAME_ICSSURF = \"${EXTRN_MDL_NAME_ICSSURF}\"
"
  ;;
esac
#
#-----------------------------------------------------------------------
#
# Build the FORTRAN namelist file that chgres_cube will read in.
#
#-----------------------------------------------------------------------
#

# fix_dir_target_grid="${BASEDIR}/JP_grid_HRRR_like_fix_files_chgres_cube"
# base_install_dir="${SORCDIR}/chgres_cube.fd"

#
# As an alternative to the cat command below, we can have a template for
# the namelist file and use the set_file_param(.sh) function to set 
# namelist entries in it.  The set_file_param function will print out a
# message and exit if it fails to set a variable in the file.
#

{ cat > fort.41 <<EOF
&config
 fix_dir_target_grid="/scratch3/BMC/det/beck/FV3-CAM/sfc_climo_final_C3343"
 mosaic_file_target_grid="${EXPTDIR}/INPUT/${CRES}_mosaic.nc"
 orog_dir_target_grid="${EXPTDIR}/INPUT"
 orog_files_target_grid="${CRES}_oro_data.tile7.halo${nh4_T7}.nc"
 vcoord_file_target_grid="${FV3SAR_DIR}/fix/fix_am/global_hyblev.l65.txt"
 mosaic_file_input_grid=""
 orog_dir_input_grid=""
 base_install_dir="/scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix"
 wgrib2_path="${WGRIB2_DIR}"
 data_dir_input_grid="${EXTRN_MDL_FILES_DIR}"
 atm_files_input_grid="${fn_atm_nemsio}"
 sfc_files_input_grid="${fn_sfc_nemsio}"
 grib2_file_input_grid="${fn_grib2}"
 cycle_mon=${mm}
 cycle_day=${dd}
 cycle_hour=${hh}
 convert_atm=.true.
 convert_sfc=.true.
 convert_nst=.false.
 regional=1
 input_type="${input_type}"
 external_model="${external_model}"
 phys_suite="${phys_suite}"
 numsoil_out=9
 geogrid_file_input_grid="/scratch3/BMC/det/beck/FV3-CAM/geo_em.d01.nc"
 replace_vgtyp=.false.
 replace_sotyp=.false.
 replace_vgfrc=.false.
 tg3_from_soil=.true.
/
EOF
} || print_err_msg_exit "\
\"cat\" command to create a namelist file for chgres_cube to generate ICs,
surface fields, and the 0-th hour (initial) LBCs returned with nonzero 
status."

# tracers_input= "spfh","clwmr","o3mr"
#
#-----------------------------------------------------------------------
#
# Run chgres_cube.
#
#-----------------------------------------------------------------------
#
#${APRUN} ${exec_dir}/global_chgres.exe || print_err_msg_exit "\
#${APRUN} /scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix/sorc/chgres_cube.fd/exec/global_chgres.exe || print_err_msg_exit "\
${APRUN} /scratch3/BMC/det/beck/FV3-CAM/UFS_UTILS_chgres_bug_fix/exec/chgres_cube.exe || print_err_msg_exit "\
Call to executable to generate surface and initial conditions files for
the FV3SAR failed."
#
#-----------------------------------------------------------------------
#
# Move initial condition, surface, control, and 0-th hour lateral bound-
# ary files to ICs_BCs directory. 
#
#-----------------------------------------------------------------------
#
mv_vrfy out.atm.tile7.nc ${WORKDIR_ICSLBCS_CDATE}/gfs_data.tile7.nc
mv_vrfy out.sfc.tile7.nc ${WORKDIR_ICSLBCS_CDATE}/sfc_data.tile7.nc
mv_vrfy gfs_ctrl.nc ${WORKDIR_ICSLBCS_CDATE}
mv_vrfy gfs_bndy.nc ${WORKDIR_ICSLBCS_CDATE}/gfs_bndy.tile7.000.nc
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
Initial condition, surface, and 0-th hour lateral boundary condition
files (in NetCDF format) generated successfully!!!
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
