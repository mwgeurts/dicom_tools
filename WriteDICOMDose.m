function varargout = WriteDICOMDose(varargin)
% WriteDICOMDose saves the provided dose array to a DICOM RTDOSE file. If
% DICOM header information is provided in the third input argument, it will
% be used to populate the DICOM header for associating the DICOM RTDOSE
% file with an image set.
%
% The following variables are required for proper execution: 
%   varargin{1}: structure containing the calculated dose. Must contain
%       start, width, and data fields. See LoadDICOMDose for more info on 
%       the format of this object. Start and widths are in cm.
%   varargin{2}: string containing the path and name to write the DICOM 
%       RTDOSE file to. MATLAB must have write access to this location to 
%       execute successfully.
%   varargin{3} (optional): structure containing the following DICOM header
%       fields: patientName, patientID, patientBirthDate, patientSex, 
%       patientAge, classUID, studyUID, seriesUID, frameRefUID, 
%       instanceUIDs, seriesDescription, and referencedBeamNumber. Note, 
%       not all fields must be provided to execute.
%
% The following variables are returned upon successful completion:
%   varargout{1} (optional): dose SOP instance UID
%
% Below is an example of how this function is used:
%
%   % Create a random array of dose values with 120 slices
%   dose.data = rand(512, 512, 120);
%
%   % Specify start coordinates of array (in cm)
%   dose.start = [-25, -25, -15];
%
%   % Specify voxel size (in cm)
%   dose.width = [0.098, 0.098, 0.25];
%
%   % Declare file name and path to write dose to
%   dest = '/path_to_file/dose.dcm';
%
%   % Declare DICOM Header information
%   info.patientName = 'DOE,JANE';
%   info.patientID = '12345678';
%   info.frameRefUID = ...
%       '2.16.840.1.114362.1.6.4.3.141209.9459257770.378448688.100.4';
%
%   % Execute WriteDICOMDose
%   WriteDICOMDose(dose, dest, info);
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2016-2018 University of Wisconsin Board of Regents
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
    Event(['Writing dose to DICOM RTDOSE file ', varargin{2}]);
    tic;
end

% Initialize dicominfo structure with FileMetaInformationVersion
info.FileMetaInformationVersion = [0;1];

% Specify transfer syntax and implementation UIDs
info.TransferSyntaxUID = '1.2.840.10008.1.2';
info.ImplementationClassUID = '1.2.40.0.13.1.1';
info.ImplementationVersionName = 'dcm4che-2.0';
info.SpecificCharacterSet = 'ISO_IR 100';

% Specify class UID as RTDOSE
info.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.481.2';
info.SOPClassUID = info.MediaStorageSOPClassUID;
info.Modality = 'RTDOSE';

% Specify unique instance UID (this will be overwritten by dicomwrite)
info.MediaStorageSOPInstanceUID = dicomuid;
info.SOPInstanceUID = info.MediaStorageSOPInstanceUID;

% Generate creation date/time
if nargin == 3 && isfield(varargin{3}, 'timestamp')
    t = varargin{3}.timestamp;
else
    t = now;
end

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
info.ManufacturerModelName = 'WriteDICOMDose';
info.SoftwareVersion = '1.2';

% Specify series description (optional)
if nargin == 3 && isfield(varargin{3}, 'seriesDescription')
    info.SeriesDescription = varargin{3}.seriesDescription;
else
    info.SeriesDescription = '';
end

% Specify study description (optional)
if nargin == 3 && isfield(varargin{3}, 'studyDescription')
    info.StudyDescription = varargin{3}.studyDescription;
else
    info.StudyDescription = '';
end

% Specify referenced image sequences (optional)
if nargin == 3 && isfield(varargin{3}, 'instanceUIDs') && ...
        isfield(varargin{3}, 'classUID')
    
    % Loop through instance UIDs
    for i = 1:length(varargin{3}.instanceUIDs)
        
        % Add reference image class
        info.ReferencedImageSequence.(...
            sprintf('Item_%i', i)).ReferencedSOPClassUID = ...
            varargin{3}.classUID;
        
        % Add reference image UID
        info.ReferencedImageSequence.(...
            sprintf('Item_%i', i)).ReferencedSOPInstanceUID = ...
            varargin{3}.instanceUIDs{i};
    end
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
        info.PatientSex = upper(varargin{3}.patientSex(1));
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
    info.StudyInstanceUID = dicomuid;
end

% Specify unique series UID
info.SeriesInstanceUID = dicomuid;

% Specify image orientation
if nargin == 3 && isfield(varargin{3}, 'position')
    
    % Set orientation based on patient position
    if strcmpi(varargin{3}.position, 'HFP')
        info.ImageOrientationPatient = [-1;0;0;0;-1;0];
    elseif strcmpi(varargin{3}.position, 'FFS')
        info.ImageOrientationPatient = [-1;0;0;0;1;0];
    elseif strcmpi(varargin{3}.position, 'FFP')
        info.ImageOrientationPatient = [1;0;0;0;-1;0];
    else
        info.ImageOrientationPatient = [1;0;0;0;1;0];
    end

% Otherwise, assume standard (HFS) orientation
else
    info.ImageOrientationPatient = [1;0;0;0;1;0];
end

% Specify IEC-X position, in mm
info.ImagePositionPatient(1) = varargin{1}.start(1) * 10 * ...
    info.ImageOrientationPatient(1);

% Specify IEC-Z position, in mm
info.ImagePositionPatient(2) =  -(varargin{1}.start(2) + ...
    varargin{1}.width(2) * (size(varargin{1}.data,2)-1)) * 10 * ...
    info.ImageOrientationPatient(5); 

% Specify IEC-Y position, in mm
if isequal(info.ImageOrientationPatient, [1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [-1;0;0;0;-1;0]) 
    info.ImagePositionPatient(3) = -varargin{1}.start(3) * 10;
else
    info.ImagePositionPatient(3) = varargin{1}.start(3) * 10;
end

% Specify frame of reference UID
if nargin == 3 && isfield(varargin{3}, 'frameRefUID')
    info.FrameOfReferenceUID = varargin{3}.frameRefUID;
else
    info.FrameOfReferenceUID = dicomuid;
end

% Specify number of images
info.ImagesInAcquisition = 1;

% Specify number of samples
info.SamplesPerPixel = 1;
info.PhotometricInterpretation = 'MONOCHROME2';

% Specify slice location (in mm)
%info.SliceLocation = -info.ImagePositionPatient(3); % mm
info.SliceLocation = (0:size(varargin{1}.data, 3) - 1) * ...
    + varargin{1}.width(3) * 10; % mm

% Specify number of frames and grid frame offset vector (in mm)
info.NumberOfFrames = size(varargin{1}.data, 3);
info.GridFrameOffsetVector = (0:size(varargin{1}.data, 3) - 1) * ...
    -varargin{1}.width(3) * 10; % mm

% Specify number of rows/columns
info.Rows = size(varargin{1}.data, 2);
info.Columns = size(varargin{1}.data, 1);

% Specify pixel spacing (in mm)
info.PixelSpacing = [varargin{1}.width(1); varargin{1}.width(2)] * 10; % mm

% Specify bit information
info.BitsAllocated = 16;
info.BitsStored = 16;
info.HighBit = 15;
info.PixelRepresentation = 0;

% Specify dose information
info.DoseUnits = 'Gy';
info.DoseType = 'PHYSICAL';
info.TissueHeterogeneityCorrection = 'ROI_OVERRIDE';

% Compute and specify dose scaling factor
info.DoseGridScaling = max(max(max(varargin{1}.data))) / 65535;

% Specify referenced structure series UID
if nargin == 3 && isfield(varargin{3}, 'structureSetUID')
    info.ReferencedStructureSetSequence.Item_1.ReferencedSOPClassUID = ...
        '1.2.840.10008.5.1.4.1.1.481.3';
    info.ReferencedStructureSetSequence.Item_1.ReferencedSOPInstanceUID = ...
        varargin{3}.structureSetUID;
end

% Specify referenced RT plan UID
if nargin == 3 && isfield(varargin{3}, 'planUID')
    info.ReferencedRTPlanSequence.Item_1.ReferencedSOPClassUID = ...
        '1.2.840.10008.5.1.4.1.1.481.5';
    info.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID = ...
        varargin{3}.planUID;
end

% Specify dose summation type
% If a beam number was provided, assume this is a 
if nargin == 3 && isfield(varargin{3}, 'referencedBeamNumber') && ...
        varargin{3}.referencedBeamNumber > 0
    
    % Specify this dose as per beam
    info.DoseSummationType = 'BEAM';
    
    % Add referenced beam number
    info.ReferencedRTPlanSequence.Item_1.ReferencedFractionGroupSequence...
        .Item_1.ReferencedBeamSequence.Item_1.ReferencedBeamNumber = ...
        varargin{3}.referencedBeamNumber;
    
    % Add fraction group
    info.ReferencedRTPlanSequence.Item_1.ReferencedFractionGroupSequence...
        .Item_1.ReferencedFractionGroupNumber = 1;
    
% Otherwise, specify this dose as per plan
else
    info.DoseSummationType = 'PLAN';
end

% Write DICOM file using dicomwrite()
status = dicomwrite(reshape(flip(rot90(uint16(varargin{1}.data/...
    info.DoseGridScaling), 3), 2), [size(varargin{1}.data, 2) ...
    size(varargin{1}.data, 1) 1 size(varargin{1}.data, 3)]), varargin{2}, ...
    info, 'CompressionMode', 'None', 'CreateMode', 'Copy', 'Endian', ...
    'ieee-le', 'MultiframeSingleFile', true);

% If the UID is to be returned
if nargout == 1
   
    % Load the dicom file back into info
    info = dicominfo(varargin{2});
    
    % Return UID
    varargout{1} = info.SOPInstanceUID;
    
    % Log UID
    if exist('Event', 'file') == 2
        Event(['SOPInstanceUID set to ', info.SOPInstanceUID]);
    end
end

% Check write status
if isempty(status)
    
    % Log completion of function
    if exist('Event', 'file') == 2
        Event(sprintf(['DICOM RTDose export completed successfully in ', ...
            '%0.3f seconds'], toc));
    end
    
% If not empty, warn user of any errors
else
    
    % Log completion of function
    if exist('Event', 'file') == 2
        Event(sprintf(['DICOM RTDose export completed with one or more ', ...
            'warnings in %0.3f seconds'], toc), 'WARN');
    else
        warning('DICOM RTDose export completed with one or more warnings');
    end
end

% Clear temporary variables
clear info t i status;

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end



