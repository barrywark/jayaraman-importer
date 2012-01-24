==========================================
Vivek Jayaraman's lab importer for Ovation
==========================================


This project contains Matlab[1]_ code for importing data for Vivek Jayaraman's lab into the `Ovation Scientific Data Management System <http://physionconsulting.com/web/Ovation.html>`.

Basic Usage
-----------

To use the importer:

#. add the project directory to the Matlab path
#. Choose an Ovation ``Experiment`` object to insert data into. To create a ``Project`` and ``Experiment``::

    >> import ovation.*
    >> context = NewDataContext(<path_to_connection_file>, <username>);
    >> project = context.insertProject(<project name>, <project purpose>, <project start date>);
    >> experiment = project.insertExperiment(<expt purpose>, <expt start date>);
#. Insert a PL-DA-PS ``.PDS`` file as an ``EpochGroup``::

    >> epochGroup = ImportPladpsPDS(experiment,...
        <path to PDS file>,...
        trialFunctionName,...
        experimentTimeZone)
        

#. Export spike sorting data from a ``.plx`` to a Matlab ``.mat`` file::
    
    >> plx2mat ??
    
#. Append ``DerivedResponses`` with spike times and spike waveforms to ``Epochs`` already in the database::

    >> ImportPladpsPlx(epochGroup,...
        plxFilePath,...
        expFilePath);

This step will will issue a warning ``Epochs`` in the plexon data are not already represented by ``Epoch`` instances in the Ovation database.


Automated tests
---------------

To run the automated test suite:

#. Add ``pldaps-importer`` folder to the Matlab path
#. Add Matlab xUnit (``pldaps-importer/matlab-xunit-doctest/xunit``) to the Matlab path
#. From within the ``pldaps-importer/test`` directory::
    
    >> runtestsuite
    




.. [1] Matlab is a registered trademark of The Mathworks, Inc..


