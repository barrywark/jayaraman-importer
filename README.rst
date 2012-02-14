=========================================
Jayaraman lab's importer code for Ovation
=========================================


This project contains Matlab [#]_ code for importing data for Vivek Jayaraman's lab into the `Ovation Scientific Data Management System <http://physionconsulting.com/web/Ovation.html>`_.

The importer is modularized into individual Matlab functions that import components of the Jayaraman data:

- ``insertFlyArenaEpoch`` which inserts a new ``ovation.Epoch`` corresponding to single trial in the fly arena
- ``appendTreadmill`` which appends Treadmill data to an existing ``ovation.Epoch``
- ``appendXSG`` which appends an Ephus XSG file to an existing ``ovation.Epoch``
- ``appendScanImageTiff`` which appends a ScanImage TIFF's data to an existing ``ovation.Epoch``
- ``appendSeq`` which appends a .seq data file to an existing ``ovation.Epoch``

Documentation of the specification for each import module is available on the project `wiki <https://github.com/physion/jayaraman-importer/wiki>`_.

The top-level ``ImportJayaramanTrials`` function calls the individual modules to import appropriate data for a number of trials. Trial information (including necessary metadata and paths to the relevant data files) is provided as a Matlab struct per trial. See https://github.com/physion/jayaraman-importer/wiki for a description of the trial structure.

.. _basic-usage-section:

Basic Usage
-----------

To use the importer:

#. Add the Importer ``src/`` directory to the Matlab path
#. Choose an Ovation ``Experiment`` object to insert data into. To create a ``Project`` and ``Experiment``::

    >> import ovation.*
    >> context = NewDataContext(<path_to_connection_file>, <username>);
    >> project = ovation.projectForInsertion(context, <project name>, (<project start date>), (<project purpose>));
    >> experiment = ovation.experimentForInsertion(project, <year>, <month>, <day> <timezone>, (<expt purpose>), (<hr>, <min>, <sec>));
	
#. Insert one or more ``EpochGroup`` objects, replacing ``<label>`` with the desired ``EpochGroup`` label and the arguments to ``datetime`` with the start time and date of the ``EpochGroup`` (see ``help ovation.datetime``)::

    >> epochGroup = experiment.insertEpochGroup(<label>, datetime(...));
    
#. Create a Matlab structure array of trial structures (see https://github.com/physion/jayaraman-importer/wiki) and import the corresponding trial data::
	
	>> for i = 1:ntrials
		% fill in trials(i) structure
	end
	>> InsertJayaramanTrials(epochGroup, trials);

Automated tests
---------------

To run the automated test suite:

#. Add the ``jayaraman-importer/src`` folder to the Matlab path
#. Add the ``jayaraman-importer/test`` folder to the Matlab path
#. Add Matlab xUnit (``jayaraman-importer/matlab-xunit-doctest/xunit``) to the Matlab path
#. From within the ``jayaraman-importer/`` directory::
    
    >> runtestsuite test
    


License
-------

*Please see license.txt for bundled project licenses*

Copyright (c) 2012, Physion Consulting LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


.. [#] Matlab is a registered trademark of The Mathworks, Inc..


