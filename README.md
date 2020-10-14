# ForSDAT
### Force Spectroscopy Data Analysis Toolkit

ForSDAT is a toolkit designed for the completely automated analysis of single molecule force spectroscopy measurements.

## Cite as:
[Duanis-Assaf, T., Razvag, Y. and Reches, M., 2019. ForSDAT: an automated platform for analyzing force spectroscopy measurements. Analytical Methods, 11(37), pp.4709-4718.](https://pubs.rsc.org/en/content/articlehtml/2019/ay/c9ay01150a)*

## Dependencies
ForSDAT requires the following frameworks, toolboxes and fileexchanges to operate:
* [Simple Framework](https://github.com/TaDuAs/Simple)
* [GUI Layout Toolbox](https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox)

## References
* ForSDAT uses code from [Fodis](https://github.com/galvanetto/Fodis) (N. Galvanetto, et al. Fodis: Software for Protein Unfolding Analysis, Biophysical Journal. 114 (2018) 1264–1266. doi:10.1016/j.bpj.2018.02.004) for loading binary force VS. distance curves.
These files (see "ForSDAT/ForSDAT Utils/+Fodis/+IO/") are available under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0), with updates made to the following files:
  * ForSDAT/ForSDAT Utils/+Fodis/+IO/readJPK.m
  * ForSDAT/ForSDAT Utils/+Fodis/+IO/extractGeneralHeaderInformation.m
  * ForSDAT/ForSDAT Utils/+Fodis/+IO/extractSharedHeaderInformation.m
* [log4m](https://www.mathworks.com/matlabcentral/fileexchange/37701-log4m-a-powerful-and-simple-logger-for-matlab)
* [structofarrays2arrayofstructs](https://www.mathworks.com/matlabcentral/fileexchange/40712-convert-from-a-structure-of-arrays-into-an-array-of-structures)
