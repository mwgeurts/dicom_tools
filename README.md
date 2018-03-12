## DICOM Manipulation Tools for MATLAB&reg;

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2016-2018, University of Wisconsin Board of Regents

The DICOM Manipulation Tools for MATLAB are a compilation of functions that read and write DICOM RT files. These tools are used in various applications, including [exit_detector](https://github.com/mwgeurts/exit_detector), [systematic_error](https://github.com/mwgeurts/systematic_error) and [mvct_dose](https://github.com/mwgeurts/dicom_viewer). MATLAB is a registered trademark of MathWorks Inc. 


## Contents

* [Installation and Use](README.md#installation-and-use)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)
* [Tools and Examples](README.md#tools-and-examples)
  * [LoadDICOMImages](README.md#loaddicomimages)
  * [LoadDICOMStructures](README.md#loaddicomstructures)
  * [LoadDICOMDose](README.md#loaddicomdose)
  * [Load3ddose](README.md#load3ddose)
  * [ScanDICOMPath](README.md#scandicompath)
  * [WriteDICOMImage](README.md#writedicomimage)
  * [WriteDICOMStructures](README.md#writedicomstructures)
  * [WriteDICOMDose](README.md#writedicomdose)
  * [WriteDICOMTomoPlan](README.md#writedicomtomoplan)
  * [WriteDVH](README.md#writedvh)
* [Event Calling](README.md#event-calling)
* [License](README.md#license)

## Installation and Use

To install the DICOM Manipulation Tools, copy all MATLAB .m files from this repository into your MATLAB path.  If installing as a submodule into another git repository, execute `git submodule add https://github.com/mwgeurts/dicom_tools`.

## Compatibility and Requirements

The DICOM Manipulation Tools have been validated for MATLAB versions 8.3 through 8.5 on Macintosh OSX 10.8 (Mountain Lion) through 10.10 (Yosemite). These tools use the Image Processing Toolbox MATLAB functions `dicominfo()`, `dicomread()`, and `dicomwrite()` to read and write to the provided DICOM destination files.

## Tools and Examples

The following subsections describe what inputs and return variables are used, and provides examples for basic operation of each tool. For more information, refer to the documentation within the source code.

### LoadDICOMImages

`LoadDICOMImages()` loads a series of single-frame DICOM CT images and returns a formatted structure for dose calculation. See below for more information on the structure format. This function will display a progress bar while it loads (unless MATLAB was executed with the `-nodisplay`, `-nodesktop`, or `-noFigureWindows` flags).

Note, non-HFS and multi-frame datasets have not currently been tested, so their compatibility with this function is unknown.

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

### LoadDICOMDose

`LoadDICOMDose()` loads a DICOM RTDose object into a MATLAB structure that can be used for manipulation with other functions in this library.

The following variables are required for proper execution: 

* path: string containing the path to the DICOM files
* name: string containing the file name

The following variables are returned upon succesful completion:

* dose: structure containing the image data, dimensions, width, start coordinates, and key DICOM header values. The data is a three dimensional array of dose values in the units specified in the DICOM header, while the dimensions, width, and start fields are three element vectors. The DICOM header values are returned as strings.

Below is an example of how this function is used:

```matlab
path = '/path/to/files/';
name = '1.2.826.0.1.3680043.2.200.1679117636.903.83681.339.dcm';
dose = LoadDICOMDose(path, name);
```

### Load3ddose

`Load3ddose` loads a DOSEXYZnrc .3ddose file into a MATLAB structure that can be used for manipulation with other functions in this library. The file format was obtained from the DOSEXYZnrc user manual for version PIRS-794revB, https://nrc-cnrc.github.io/EGSnrc/doc/pirs794-dosxyznrc.pdf

The following variables are required for proper execution: 

* path: string containing the path to the DICOM files
* name: string containing the file name

The following variables are returned upon succesful completion:

* dose: structure containing the image data, error, dimensions, width, and start coordinates. The data and error fields is a three dimensional array of dose values, while the dimensions, width, and start fields are three element vectors.

Below is an example of how this function is used:

```matlab
path = '/path/to/files/';
name = 'example.3ddose';
dose = Load3ddose(path, name);
```

### ScanDICOMPath

`ScanDICOMPath` recursively searches a provided path for DICOM data and returns a cell array of DICOM images, RT structure sets, RT plan, and RT dose files along with basic header information found within the directory. DICOM files must contain the following minimum tags: SOPInstanceUID, MediaStorageSOPClassUID, Modality, PatientName, and PatientID.

This function will display a progress bar while it loads unless MATLAB was executed with the -nodisplay, -nodesktop, or -noFigureWindows flags or if a `Progress` input option is set to false. If the `DOSEXYZnrc` input option is set to true, this function will also identify DOSEXYZnrc Monte Carlo calculated dose files with a .3ddose extension and add them as RTDOSE options.

The following variables are required for proper execution: 

* path: string containing the path to the DICOM files, cell array of files, or path to a single file

Upon successful completion, the function will return an n x 11 cell array, where n is the number of files returned and the columns correspond to the following values:

* Column 1: string containing the file name
* Column 2: string containing the full path to the file
* Column 3: string containing the file modality ('CT', 'MR', 'RTDOSE', 'RTPLAN', or 'RTSTRUCT')
* Column 4: string containing the DICOM instance UID
* Column 5: string containing the patient name, starting with the last name separated by commas
* Column 6: string containing the patient's ID
* Column 7: string containing the frame of reference UID
* Column 8: string containing the study or referenced study UID
* Column 9: if RTPLAN or RTDOSE with a corresponding RTPLAN in the list, a string containing the plan name
* Column 10: if RTDOSE, the dose type ('PLAN' or 'BEAM')
* Column 11: if RTPLAN, a cell array of beam names, or if a BEAM RTDOSE, the corresponding beam name 

Below are examples of how this function is used:

```matlab
% Scan test_directory for DICOM files
list = ScanDICOMPath('../test_directory');

% Re-scan, hiding the progress bar and including DOSEXYZnrc files
list = ScanDICOMPath('../test_directory', 'Progress', false, ...
    'DOSEXYZnrc', true);

% List all CT file names found within the list
list(ismember(t(:,3), 'CT'))

% List all unique Frame of Reference UIDs in the list
unique(list(:,7))
```

### WriteDICOMImage

`WriteDICOMImage()` saves the provided image array to a series of DICOM CT files. If DICOM header information is provided in the third input argument, it will be used to populate the DICOM header for associating the image set with a DICOM RTDOSE file.

The following variables are required for proper execution: 

* varargin{1}: structure containing the image data. Must contain start, width, and data fields. See `LoadDICOMImages()` for more information  on the format of this object. Start and widths are in cm. 
* varargin{2}: string containing the path and prefix to write the DICOM CT files to. Names will be appended with _NUM.dcm, where NUM is the slice number. MATLAB must have write access to this location to execute successfully.
* varargin{3} (optional): structure containing the following DICOM header fields: patientName, patientID, patientBirthDate, patientSex, patientAge, classUID, studyUID, seriesUID, frameRefUID, instanceUIDs, and seriesDescription. Note, not all fields must be provided to execute.

The following variables are returned upon successful completion:

* varargout{1} (optional): cell array of image SOP instance UIDs

Below is an example of how this function is used:

```matlab
% Create a random array of dose values with 120 slices
image.data = rand(512, 512, 120);

% Specify start coordinates of array (in cm)
image.start = [-25, -25, -15];

% Specify voxel size (in cm)
image.width = [0.098, 0.098, 0.25];

% Declare file name prefix and path to write dose to
dest = '/path_to_file/images';

% Declare DICOM Header information
info.patientName = 'DOE,JANE';
info.patientID = '12345678';
info.frameRefUID = ...
'2.16.840.1.114362.1.6.4.3.141209.9459257770.378448688.100.4';

% Execute WriteDICOMImage
WriteDICOMImage(image, dest, info);
```

### WriteDICOMStructures

`WriteDICOMStructures()` saves the provided structure set to a DICOM file.

The following variables are required for proper execution: 

* varargin{1}: structure containing the structures. Must contain name, color, and points fields. See `LoadDICOMStructures()` for more information on the format of this object. Point positions are in cm.
* varargin{2}: string containing the path and name to write the DICOM RTSS file to. MATLAB must have write access to this location to execute successfully.
* varargin{3} (optional): structure containing the following DICOM header fields: patientName, patientID, patientBirthDate, patientSex, patientAge, classUID, studyUID, seriesUID, frameRefUID, instanceUIDs, and seriesDescription. Note, not all fields must be provided to execute.

The following variables are returned upon successful completion:

* varargout{1} (optional): structure set SOP instance UID

### WriteDICOMDose

`WriteDICOMDose()` saves the provided dose array to a DICOM RTDOSE file. If DICOM header information is provided in the third input argument, it will be used to populate the DICOM header for associating the DICOM RTDOSE file with an image set.

The following variables are required for proper execution: 

* varargin{1}: structure containing the calculated dose. Must contain start, width, and data fields. See `LoadDICOMDose()` for more information on the format of this object. Start and widths are in cm.
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
```

### WriteDICOMTomoPlan

`WriteDICOMTomoPlan()` saves the provided tomotherapy plan structure to a DICOM RTPlan file. If the patient demographics (name, ID, etc) are not included in the plan structure, the user will be prompted to provide them.

The following variables are required for proper execution:    

* plan: structure containing the calculated plan information. See [tomo_extract/LoadPlan.m](https://github.com/mwgeurts/tomo_extract/) for more information on the format of this structure.
* file: string containing the path and name to write the DICOM RTDOSE file to. MATLAB must have write access to this location to        execute successfully.

The following variables are returned upon successful completion:

* varargout{1} (optional): RT plan SOP instance UID

Below is an example of how this function is used (the functions `FindPlans()` and `LoadPlan()` are from the [tomo_extract](https://github.com/mwgeurts/tomo_extract/) repository:

```matlab
% Look for plans within a patient archive   
plans = FindPlans('/path/to/archive', 'name_patient.xml');

% Load the first plan   
plan = LoadPlan('/path/to/archive', 'name_patient.xml', plans{1});

% Execute WriteDICOMTomoPlan   
dest = '/file/to/write/plan/to/info.dcm';   
WriteDICOMTomoPlan(plan, dest);
```

### WriteDVH

`WriteDVH()` computes the DVH for each structure included in the image input variable given the dose input variable and writes the resulting DVHs to a comma-separated value file. The DVHs can also be optionally returned as an array. Note, if a DVH filename is not provided in the third input argument, WriteDVH will simply compute the DVH from the image, structures, and dose and optionally return the array.

The first row contains the file name, the second row contains column headers for each structure set (including the volume in cc in parentheses), with each subsequent row containing the percent volume of each structure at or above the dose specified in the first column (in Gy).  The resolution is determined by dividing the maximum dose by 1001.

The following variables are required for proper execution: 

* varargin{1}: structure containing the CT image data and structure set data. See `LoadDICOMImages()` and `LoadDICOMStructures()` for more information on the format of this object.
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

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
