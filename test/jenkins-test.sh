#!/bin/bash

echo "Running tests with $MATLAB..."
export PATH=$MATLAB_ROOT/bin:$PATH
touch startup.m
matlab -nodisplay -nodesktop -r "addpath(getenv('OVATION_MATLAB'));addpath(getenv('IMPORT_SRC_DIR'));addpath(getenv('MATLAB_XUNIT_PATH'));addpath(getenv('EXTERNALS_SRC_DIR'));javaaddpath(getenv('OVATION_JAR_PATH'));ovation.OvationMatlabStartup(); runtestsuite test; exit(0)"