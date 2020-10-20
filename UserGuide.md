# ForSDAT User Guide

## Installation

### Prerequisites

* Install Matlab R2019a or newer (ForSDAT may work with older versions, but there may be some discrepancies)
* Get Flow Framework
  * Go to [Flow Framework Source Code](https://github.com/TaDuAs/Flow)
  * Download the repository (these libraries are required for ForSDAT to operate)
  * Add Flow framework into your Matlab path


### ForSDAT Source Code
* Browse [ForSDAT Source Code](https://github.com/TaDuAs/ForSDAT)
* Download the repository
* Add ForSDAT source code to your Matlab path

## Using ForSDAT
ForSDAT GUI is not yet available, but it operates as a Matlab command line application.

ForSDAT manages reading of data from files, raw data analysis, and can export the data once analysis is complete.
The application also saves the accepted data of each batch analysis (each batch of force curves) for later “cooked data analysis”, 
These data are compiled under “Experiment Repositories”.
Experiment repositories are collections of analyzed data which contain the results of all the experiments you performed with a specific molecule/treatment, i.e. all the scanner speeds.
Each molecule, substrate or treatment you use should be managed under a separate experiment repository. 
ForSDAT can later use the data in the experiment repositories to further analyzed by Bell-Evans modeling.

Supplemented scripts and configuration files show how to use the ForSDAT application as a whole.
See [ForSDAT/Examples/appBasedProcess.m](https://github.com/TaDuAs/ForSDAT/blob/master/Examples/appBasedProcess.m) for performing a batch analysis of force curves.
At the end of the analysis, a histogram is generated.
See [ForSDAT/Examples/bellEvansExample.m](https://github.com/TaDuAs/ForSDAT/blob/master/Examples/bellEvansExample.m) for performing a "post analysis" Bell-Evans modeling on an experiment repository.
See [ForSDAT/Examples/ExampleProject.xml](https://github.com/TaDuAs/ForSDAT/blob/master/Examples/ExampleProject.xml) for example ForSDAT configuration file.

If however, the application is not required for some reason, the core functionality of ForSDAT raw data analysis (analysis of force vs. distance curves)
is available under the package ForSDAT.Core. The analysis pipeline can be applied on force vs distance curves one at a time to receive the output data struct.
Each analysis component can be applied to the data separately as well. This course of action is less recommended though.
See [ForSDAT/Examples/standAloneCoreProcess.m](https://github.com/TaDuAs/ForSDAT/blob/master/Examples/standAloneCoreProcess.m) for example of using ForSDAT.Core analysis as a standalone script.