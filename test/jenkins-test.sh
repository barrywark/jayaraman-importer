#!/bin/bash

echo "Running tests with $MATLAB_ROOT..."
export PATH=$MATLAB_ROOT/bin:$PATH
touch startup.m
matlab -nodisplay -nodesktop -r "addpath(getenv('OVATION_MATLAB'));addpath(getenv('YAML_PATH'));addpath(getenv('IMPORT_SRC_DIR'));addpath(getenv('MATLAB_XUNIT_PATH'));addpath(getenv('EXTERNALS_SRC_DIR'));addpath(fullfile(pwd(), 'test'));javaaddpath(getenv('YAML_JAR'));javaaddpath(getenv('OVATION_JAR_PATH'));ovation.OvationMatlabStartup(); build_test_database(test); runtests('test', '-xmlfile', 'test-output.xml'); exit(0)"