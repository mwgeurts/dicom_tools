## DICOM Manipulation Tools for MATLAB

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2015, University of Wisconsin Board of Regents

The DICOM Manipulation Tools for MATLAB are a compilation of functions that read and write DICOM RT files. These tools are used in various applications, including [systematic_error](https://github.com/mwgeurts/systematic_error) and [mvct_dose](https://github.com/mwgeurts/mvct_dose).


## Contents

* [Installation and Use](README.md#installation-and-use)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)
* [Tools and Examples](README.md#tools-and-examples)
  * [LoadDICOMImages](README.md#loaddicomimages)
  * [LoadDICOMStructures](README.md#loaddicomstructures)
  * [WriteDICOMDose](README.md#writedicomdose)
  * [WriteDVH](README.md#writedvh)
* [Event Calling](README.md#event-calling)

## Installation and Use

To install the DICOM Manipulation Tools, copy all MATLAB .m files and subfolders from this repository into your MATLAB path.  If installing as a submodule into another git repository, execute `git submodule add https://github.com/mwgeurts/dicom_tools`.

## Compatibility and Requirements

The DICOM Manipulation Tools have been validated for MATLAB versions 8.3 through 8.5 on Macintosh OSX 10.8 (Mountain Lion) through 10.10 (Yosemite). These tools use the MATLAB functions `dicominfo()`, `dicomread()`, and `dicomwrite()` to read and write to the provided DICOM destination files.

## Tools and Examples

The following subsections describe what inputs and return variables are used, and provides examples for basic operation of each tool. For more information, refer to the documentation within the source code.

### LoadDICOMImages

`LoadDICOMImages()` loads a series of single-frame DICOM CT images and returns a formatted structure for dose calculation. See below for more information on the structure format. This function will display a progress bar while it loads (unless MATLAB was executed with the `-nodisplay`, `-nodesktop`, or `-noFigureWindows` flags).

Note, non-HFS and multi-frame datasets have not currently been tested, so their compatibility with this function is unknown. Support will be added in a future release.

The following variables are required for proper execution: 

* path: string containing the path to the DICOM files
* names: cell array of strings containing all files to be loaded

The following variables are returned upon succesful completion:

* image: structure containing the image data, dimensions, width, type, start coordinates, and key DICOM header values. The data is a three dimensional array of CT values, while the dimensions, width, and start fields are three element vectors.  The DICOM header values are returned as a strings.

Below is an example of how this function is used:

```matlab
path = '/path/to/files/';
names = {
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm'
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'
};
image = LoadDICOMImages(path, names);
```

### LoadDICOMStructures

`LoadDICOMStructures()` loads a DICOM RT Structure Set (RTSS) file andextracts the structure information into a MATLAB cell array. See below for more information on the structure format.  This function mayoptionally also be passed with an atlas, whereby only structures matchingthe atlas include/exclude statements are returned. This function will display a progress bar while it loads (unless MATLAB was executed with the `-nodisplay`, `-nodesktop`, or `-noFigureWindows` flags).

The following variables are required for proper execution:   

* varargin{1}: string containing the path to the DICOM files  
* varargin{2}: string containing the DICOM RTSS file to be loaded  
* varargin{3}: structure of reference image.  Must include a frameRefUID field referencing the structure set, as well as dimensions, width, and start fields. See `LoadDICOMImages()` for more information.  
* varargin{4} (optional): cell array of atlas names, include/exclude  regex statements, and load flags (if zero, matched structures will not be loaded)

The following variable is returned upon succesful completion:  

* structures: cell array of structure names, color, frameRefUID, and 3D  mask array of same size as reference image containing fraction of voxel inclusion in structure

Below are examples of how this function is used:

```matlab
% Load DICOM images  
path = '/path/to/files/';  
names = { 
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm' 
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'  
};  
image = LoadDICOMImages(path, names);

% Load DICOM structure set   
name = '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641579.747.dcm';  
structures = LoadDICOMStructures(path, name, image);

% Load structure set again, this time with atlas  
atlas = LoadAtlas('atlas.xml');  
structures = LoadDICOMStructures(path, name, image, atlas);
```

### WriteDICOMDose

`WriteDICOMDose()` saves the provided dose array to a DICOM RTDOSE file. If DICOM header information is provided in the third input argument, it will be used to populate the DICOM header for associating the DICOM RTDOSE file with an image set.

The following variables are required for proper execution: 

* varargin{1}: structure containing the calculated dose. Must contain start, width, and data fields. See CalcDose for more information on the format of this object. Start and widths are in cm.
* varargin{2}: string containing the path and name to write the DICOM RTDOSE file to. MATLAB must have write access to this location to execute successfully.
* varargin{3} (optional): structure containing the following DICOM header fields: patientName, patientID, patientBirthDate, patientSex, patientAge, classUID, studyUID, seriesUID, frameRefUID, instanceUIDs, and seriesDescription. Note, not all fields must be provided to execute.

Below is an example of how this function is used:

```matlab
% Create a random array of dose values with 120 slices
dose.data = rand(512, 512, 120);

% Specify start coordinates of array (in cm)
dose.start = [-25, -25, -15];

% Specify voxel size (in cm)
dose.width = [0.098, 0.098, 0.25];

% Declare file name and path to write dose to
dest = '/path_to_file/dose.dcm';

% Declare DICOM Header information
info.patientName = 'DOE,JANE';
info.patientID = '12345678';
info.frameRefUID = ...
    '2.16.840.1.114362.1.6.4.3.141209.9459257770.378448688.100.4';

% Execute WriteDICOMDose
WriteDICOMDose(dose, dest, info);
````

### WriteDVH

`WriteDVH()` computes the DVH for each structure included in the image input variable given the dose input variable and writes the resulting DVHs to a comma-separated value file. The DVHs can also be optionally returned as an array. Note, if a DVH filename is not provided in the third input argument, WriteDVH will simply compute the DVH from the image, structures, and dose and optionally return the array.

The first row contains the file name, the second row contains column headers for each structure set (including the volume in cc in parentheses), with each subsequent row containing the percent volume of each structure at or above the dose specified in the first column (in Gy).  The resolution is determined by dividing the maximum dose by 1001.

The following variables are required for proper execution: 

* varargin{1}: structure containing the CT image data and structure set data. See LoadDICOMImages and LoadDICOMStructures for more information on the format of this object.
* varargin{2}: structure containing the calculated dose. Must contain start, width, and data fields. See CalcDose for more information on the format of this object. Start and widths are in cm.
* varargin{3} (optional): string containing the path and name to write the DVH .csv file to. MATLAB must have write access to this location to execute. If not provided, a DVH file will not be saved.

The following variables are returned upon succesful completion:

* varargout{1} (optional): a 1001 by n+1 array of cumulative DVH values for n structures where n+1 is the x-axis value (separated into 1001 bins).

Below are examples of how this function is used:

```matlab
% Load DICOM images
path = '/path/to/files/';
names = {
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm'
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
    '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'
};
image = LoadDICOMImages(path, names);

% Load DICOM structure set into image structure
name = '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641579.747.dcm';
image.structures = LoadDICOMStructures(path, name, image);

% Create dose array with same dimensions and coordinates as image
dose.data = rand(size(image.data));
dose.width = image.width;
dose.start = image.start;

% Declare file name and path to write DVH to
dest = '/path_to_file/dvh.csv';

% Execute WriteDVH
WriteDVH(image, dose, dest);

% Execute WriteDVH again, this time returning the DVH as an array
dvh = WriteDVH(image, dose, dest);

% Compute but do not save the DVH to a file
dvh = WriteDVH(image, dose);
```

## Event Calling

These functions optionally return execution status and error information to an `Event()` function. If available in the MATLAB path, `Event()` will be called with one or two variables: the first variable is a string containing the status information, while the second is the status classification (WARN or ERROR). If the status information is only informative, the second argument is not included.  Finally, if no `Event()` function is available errors will still be thrown via the standard `error()` MATLAB function.
