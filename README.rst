=========================================
Jayaraman lab's importer code for Ovation
=========================================


This project contains Matlab [#]_ code for importing data for Vivek Jayaraman's lab into the `Ovation Scientific Data Management System <http://physionconsulting.com/web/Ovation.html>`.

The importer is modularized into individual Matlab functions that import components of the Jayaraman data:

- ``insertXSGEpoch`` and ``appendXSG`` which insert a new ovation.Epoch for an XSG file or append an XSG file to an existing ``ovation.Epoch`` respectively
- ``appendScanImageTiff`` which appends a ScanImage TIFF's data to an existing ``ovation.Epoch``
- ``appendSeq`` which appends a .seq data file to an existing ``ovation.Epoch``

Basic Usage
-----------

To use the importer:

#. add the project directory to the Matlab path
#. Choose an Ovation ``Experiment`` object to insert data into. To create a ``Project`` and ``Experiment``::

    >> import ovation.*
    >> context = NewDataContext(<path_to_connection_file>, <username>);
    >> project = context.insertProject(<project name>, <project purpose>, <project start date>);
    >> experiment = project.insertExperiment(<expt purpose>, <expt start date>);

#. TODO: add the rest

Automated tests
---------------

To run the automated test suite:

#. Add ``jayaraman-importer`` folder to the Matlab path
#. Add Matlab xUnit (``jayaraman-importer/matlab-xunit-doctest/xunit``) to the Matlab path
#. From within the ``jayaraman-importer/test`` directory::
    
    >> runtestsuite
    




.. [#] Matlab is a registered trademark of The Mathworks, Inc..


