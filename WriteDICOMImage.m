function WriteDICOMImage(varargin)
% WriteDICOMImage saves the provided image array to a series of DICOM CT 
% files. If DICOM header information is provided in the third input 
% argument, it will be used to populate the DICOM header for associating 
% the image set with a DICOM RTDOSE file.
%
% The following variables are required for proper execution: 
%   varargin{1}: structure containing the image data. Must contain
%       start, width, and data fields. See LoadImage for more information 
%       on the format of this object. Start and widths are in cm.
%   varargin{2}: string containing the path and prefix to write the DICOM 
%       CT files to. Names will be appended with _###.dcm, where ### is the 
%       slice number. MATLAB must have write access to this location to 
%       execute successfully.
%   varargin{3} (optional): structure containing the following DICOM header
%       fields: patientName, patientID, patientBirthDate, patientSex, 
%       patientAge, classUID, studyUID, seriesUID, frameRefUID, 
%       instanceUIDs, and seriesDescription. Note, not all fields must be
%       provided to execute.
%
% Below is an example of how this function is used:
%
%   % Create a random array of dose values with 120 slices
%   image.data = rand(512, 512, 120);
%
%   % Specify start coordinates of array (in cm)
%   image.start = [-25, -25, -15];
%
%   % Specify voxel size (in cm)
%   image.width = [0.098, 0.098, 0.25];
%
%   % Declare file name prefix and path to write dose to
%   dest = '/path_to_file/images';
%
%   % Declare DICOM Header information
%   info.patientName = 'DOE,JANE';
%   info.patientID = '12345678';
%   info.frameRefUID = ...
%       '2.16.840.1.114362.1.6.4.3.141209.9459257770.378448688.100.4';
%
%   % Execute WriteDICOMImage
%   WriteDICOMImage(image, dest, info);
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2015 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Check if MATLAB can find dicomwrite (Image Processing Toolbox)
if exist('dicomwrite', 'file') ~= 2
    
    % If not, throw an error
    if exist('Event', 'file') == 2
        Event(['The Image Processing Toolbox cannot be found and is ', ...
            'required by this function.'], 'ERROR');
    else
        error(['The Image Processing Toolbox cannot be found and is ', ...
            'required by this function.']);
    end
end

% Execute in try/catch statement
try
    
% Log start of DVH computation and start timer
if exist('Event', 'file') == 2
    Event(['Writing image to DICOM CT files ', varargin{2}, '_*']);
    tic;
end

% Initialize dicominfo structure with FileMetaInformationVersion
info.FileMetaInformationVersion = [0;1];

% Specify transfer syntax and implementation UIDs
info.TransferSyntaxUID = '1.2.840.10008.1.2';
info.ImplementationClassUID = '1.2.40.0.13.1.1';
info.ImplementationVersionName = 'dcm4che-2.0';
info.SpecificCharacterSet = 'ISO_IR 100';

% Specify class UID based on provided class
if nargin == 3 && isfield(varargin{3}, 'classUID')
    info.MediaStorageSOPClassUID = varargin{3}.classUID;

% Otherwise, assume it is CT
else
    info.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.2';
    info.Modality = 'CT';
end
info.SOPClassUID = info.MediaStorageSOPClassUID;

% Generate creation date/time
t = now;

% Specify creation date/time
info.InstanceCreationDate = datestr(t, 'yyyymmdd');
info.InstanceCreationTime = datestr(t, 'HHMMSS');

% Specify acquisition date/time
info.AcquisitionDate = datestr(t, 'yyyymmdd');
info.AcquisitionTime = datestr(t, 'HHMMSS');

% Specifty image type
info.ImageType = 'ORIGINAL/PRIMARY/AXIAL';

% Specify manufacturer, model, and software version
info.Manufacturer = ['MATLAB ', version];
info.ManufacturerModelName = 'WriteDICOMImage';
info.SoftwareVersion = '1.0';

% Specify series description (optional)
if nargin == 3 && isfield(varargin{3}, 'seriesDescription')
    info.SeriesDescription = varargin{3}.seriesDescription;
else
    info.SeriesDescription = '';
end

% Specify patient info (assume that if name isn't provided, nothing is
% provided)
if nargin == 3 && isfield(varargin{3}, 'patientName')
    
    % If name is a structure
    if isstruct(varargin{3}.patientName)
        
        % Add name from provided dicominfo
        info.PatientName = varargin{3}.patientName;
        
    % Otherwise, if name is a char array
    elseif ischar(varargin{3}.patientName)
        
        % Add name to family name
        info.PatientName.FamilyName = varargin{3}.patientName;
    
    % Otherwise, throw an error
    else
        if exist('Event', 'file') == 2
            Event('Provided patient name is an unknown format', 'ERROR');
        else
            error('Provided patient name is an unknown format');
        end
    end
    
    % Specify patient ID
    if isfield(varargin{3}, 'patientID')
        info.PatientID = varargin{3}.patientID;
    else
        info.PatientID = '';
    end
    
    % Specify patient birthdate
    if isfield(varargin{3}, 'patientBirthDate')
        info.PatientBirthDate = varargin{3}.patientBirthDate;
    else
        info.PatientBirthDate = '';
    end
    
    % Specify patient sex
    if isfield(varargin{3}, 'patientSex')
        info.PatientSex = varargin{3}.patientSex;
    else
        info.PatientSex = '';
    end
    
    % Specify patient age
    if isfield(varargin{3}, 'patientAge')
        info.PatientAge = varargin{3}.patientAge;
    else
        info.PatientAge = '';
    end
    
% If a valid screen size is returned (MATLAB was run without -nodisplay)
elseif usejava('jvm') && feature('ShowFigureWindows')
    
    % Prompt user for patient name
    input = inputdlg({'Family Name', 'Given Name', 'ID', 'Birth Date', ...
        'Sex', 'Age'}, 'Provide Patient Demographics', ...
        [1 50; 1 50; 1 30; 1 30; 1 10; 1 10]); 
    
    % Add provided input
    info.PatientName.FamilyName = char(input{1});
    info.PatientName.GivenName = char(input{2});
    info.PatientID = char(input{3});
    info.PatientBirthDate = char(input{4});
    info.PatientSex = char(input{5});
    info.PatientAge = char(input{6});
    
    % Clear temporary variables
    clear input;
    
% Otherwise, no data was provided and no UI exists to prompt user
else
    
    % Add generic data
    info.PatientName.FamilyName = 'DOE';
    info.PatientName.GivenName = 'J';
    info.PatientID = '00000000';
    info.PatientBirthDate = '';
    info.PatientSex = '';
    info.PatientAge = '';
end
    
% Specify slice thickness (in mm)
info.SliceThickness = varargin{1}.width(3) * 10; % mm

% Specify study UID
if nargin == 3 && isfield(varargin{3}, 'studyUID')
    info.StudyInstanceUID = varargin{3}.studyUID;
else
    info.StudyInstanceUID = '';
end

% Specify series UID
if nargin == 3 && isfield(varargin{3}, 'seriesUID')
    info.SeriesInstanceUID = varargin{3}.seriesUID;
else
    info.SeriesInstanceUID = '';
end

% Specify image position (in mm)
info.ImagePositionPatient = varargin{1}.start' .* [1;1;-1] * 10; % mm

% Adjust vertical position back to IEC
info.ImagePositionPatient(2) = -(varargin{1}.start(2) + ...
    varargin{1}.width(2) * (size(varargin{1}.data,2)-1)) * 10; % mm

% Specify frame of reference UID
if nargin == 3 && isfield(varargin{3}, 'frameRefUID')
    info.FrameOfReferenceUID = varargin{3}.frameRefUID;
else
    info.FrameOfReferenceUID = '';
end

% Specify image orientation
if nargin == 3 && isfield(varargin{3}, 'position')
    position = varargin{3}.position;

% If not provided, assume HFS
else
    position = 'HFS';
end

% Write image orientation and patient position
info.PatientPosition = position;
if strcmp(position, 'HFS')
    info.ImageOrientationPatient = [1;0;0;0;1;0];
elseif strcmp(position, 'FFS')
    info.ImageOrientationPatient = [-1;0;0;0;1;0];
elseif strcmp(position, 'HFP')
    info.ImageOrientationPatient = [1;0;0;0;-1;0];
elseif strcmp(position, 'FFP')
    info.ImageOrientationPatient = [-1;0;0;0;-1;0];
end

% Specify number of images
info.ImagesInAcquisition = size(varargin{1}.data, 3);

% Specify number of samples
info.SamplesPerPixel = 1;
info.PhotometricInterpretation = 'MONOCHROME2';

% Specify number of rows/columns
info.Rows = size(varargin{1}.data, 1);
info.Columns = size(varargin{1}.data, 2);

% Specify pixel spacing (in mm)
info.PixelSpacing = [varargin{1}.width(1); varargin{1}.width(2)] * 10; % mm

% Specify bit information
info.BitsAllocated = 16;
info.BitsStored = 16;
info.HighBit = 15;
info.PixelRepresentation = 0;

% If minimum image value is below zero, assume image is in HU and add 1024
if min(min(min(varargin{1}.data))) < 0
    varargin{1}.data = varargin{1}.data + 1024;
end

% Loop through CT Images
for i = 1:size(varargin{1}.data, 3)
    
    % If UID information has been provided
    if nargin == 3 && isfield(varargin{3}, 'instanceUIDs')
       
        % Use stored instance UID
        info.MediaStorageSOPInstanceUID = varargin{3}.instanceUIDs{i};
    
    % Otherwise, generate unique instance ID
    else
        info.MediaStorageSOPInstanceUID = dicomuid;
    end
    
    % Copy instance UID from media storage UID
    info.SOPInstanceUID = info.MediaStorageSOPInstanceUID;
    
    % Specify slice location (in mm)
    info.SliceLocation = (i - 1) * -varargin{1}.width(3) * 10; % mm
    
    % Update image position to slice location
    info.ImagePositionPatient(3) = -info.SliceLocation;
    
    % Write DICOM file using dicomwrite()
    dicomwrite(flip(rot90(uint16(varargin{1}.data(:,:,i)), 3), 2), ...
        [varargin{2}, sprintf('_%03i.dcm', i)], info, ...
        'CompressionMode', 'None', 'CreateMode', 'Copy', 'Endian', ...
        'ieee-le');
    
    % Log UID
    if exist('Event', 'file') == 2
        Event(sprintf('Image %i written with SOPInstanceUID %s', i, ...
            info.SOPInstanceUID));
    end
end

% Log completion of function
if exist('Event', 'file') == 2
    Event(sprintf(['DICOM CT export completed successfully in ', ...
        '%0.3f seconds'], toc));
end

% Clear temporary variables
clear info t i;

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end