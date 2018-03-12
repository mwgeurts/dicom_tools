function varargout = WriteDICOMStructures(varargin)
% WriteDICOMStructures saves the provided structure set to a DICOM file.
%
% The following variables are required for proper execution: 
%   varargin{1}: structure containing the structures. Must contain
%       name, color, and points fields. See LoadDICOMStructures for more 
%       information on the format of this object. Point positions are in 
%       cm.
%   varargin{2}: string containing the path and name to write the DICOM 
%       RTSS file to. MATLAB must have write access to this location to 
%       execute successfully.
%   varargin{3} (optional): structure containing the following DICOM header
%       fields: patientName, patientID, patientBirthDate, patientSex, 
%       patientAge, classUID, studyUID, seriesUID, frameRefUID, 
%       instanceUIDs, and seriesDescription. Note, not all fields must be
%       provided to execute.
%
% The following variables are returned upon successful completion:
%   varargout{1} (optional): structure set SOP instance UID
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
    Event(['Writing structure set to DICOM RTSS file ', varargin{2}]);
    tic;
end

% Initialize dicominfo structure with FileMetaInformationVersion
info.FileMetaInformationVersion = [0;1];

% Specify transfer syntax and implementation UIDs
info.TransferSyntaxUID = '1.2.840.10008.1.2';
info.ImplementationClassUID = '1.2.40.0.13.1.1';
info.ImplementationVersionName = 'dcm4che-2.0';
info.SpecificCharacterSet = 'ISO_IR 100';

% Specify class UID as structure set
info.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.481.3';
info.SOPClassUID = info.MediaStorageSOPClassUID;
info.Modality = 'RTSTRUCT';

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

% Specify structure set date/time
info.StructureSetDate = datestr(t, 'yyyymmdd');
info.StructureSetTime = datestr(t, 'HHMMSS');

% Specify manufacturer, model, and software version
info.Manufacturer = ['MATLAB ', version];
info.ManufacturerModelName = 'WriteDICOMStructures';
info.SoftwareVersion = '1.1';

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

% Specify structure set label (optional)
if nargin == 3 && isfield(varargin{3}, 'structureLabel')
    info.StructureSetLabel = varargin{3}.structureLabel;
else
    info.StructureSetLabel = '';
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

% Specify study UID
if nargin == 3 && isfield(varargin{3}, 'studyUID')
    info.StudyInstanceUID = varargin{3}.studyUID;
else
    info.StudyInstanceUID = dicomuid;
end

% Specify unique series UID
info.SeriesInstanceUID = dicomuid;

% Specify referenced class UID if one exists
if nargin == 3 && isfield(varargin{3}, 'classUID')
    info.ReferencedFrameOfReferenceSequence.Item_1...
        .RTReferencedStudySequence.Item_1.ReferencedSOPClassUID = ...
        varargin{3}.classUID;
end

% Specify frame of reference UID
if nargin == 3 && isfield(varargin{3}, 'frameRefUID')
    info.ReferencedFrameOfReferenceSequence.Item_1.FrameOfReferenceUID = ...
        varargin{3}.frameRefUID;
else
    info.ReferencedFrameOfReferenceSequence.Item_1.FrameOfReferenceUID = ...
        dicomuid;
end

% Specify referenced SOP class as Detached Study Management
info.ReferencedFrameOfReferenceSequence.Item_1.RTReferencedStudySequence...
    .Item_1.ReferencedSOPClassUID = '1.2.840.10008.3.1.2.3.1';

% Specify referenced study UID
info.ReferencedFrameOfReferenceSequence.Item_1.RTReferencedStudySequence...
    .Item_1.ReferencedSOPInstanceUID = info.StudyInstanceUID;

% Specify referenced series UID
if nargin == 3 && isfield(varargin{3}, 'seriesUID')
    info.ReferencedFrameOfReferenceSequence.Item_1...
        .RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence.Item_1...
        .SeriesInstanceUID = varargin{3}.seriesUID;
else
    info.ReferencedFrameOfReferenceSequence.Item_1...
        .RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence.Item_1...
        .SeriesInstanceUID = dicomuid;
end

% Specify referenced image instance UIDs
if nargin == 3 && isfield(varargin{3}, 'instanceUIDs')
    
    % Loop through image instance UIDs
    for i = 1:length(varargin{3}.instanceUIDs)
        
        % Specify referenced class UID if one exists
        if nargin == 3 && isfield(varargin{3}, 'classUID')
            info.ReferencedFrameOfReferenceSequence.Item_1...
                .RTReferencedStudySequence.Item_1...
                .RTReferencedSeriesSequence.Item_1.ContourImageSequence...
                .(sprintf('Item_%i', i)).ReferencedSOPClassUID = ...
                varargin{3}.classUID;
        end
        
        % Specify contour sequence reference UID
        info.ReferencedFrameOfReferenceSequence.Item_1...
            .RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence...
            .Item_1.ContourImageSequence.(sprintf('Item_%i', i))...
            .ReferencedSOPInstanceUID = varargin{3}.instanceUIDs{i};
    end
end

% Apply image orientation rotation, if available (otherwise assume HFS)
rot = [1,1,1];
if isfield(varargin{3}, 'position')

    % Set rotation vector based on patient position
    if strcmpi(varargin{3}.position, 'HFS')
        rot = [1,1,1];
    elseif strcmpi(varargin{3}.position, 'HFP')
        rot = [-1,-1,1];
    elseif strcmpi(varargin{3}.position, 'FFS')
        rot = [-1,1,-1];
    elseif strcmpi(varargin{3}.position, 'FFP')
        rot = [1,-1,-1];
    end
end

% Loop through structures cell array
for i = 1:length(varargin{1})

    % Log structure
    if exist('Event', 'file') == 2
        Event(sprintf('Writing %s as structure %i', ...
            varargin{1}{i}.name, i));
    end

    % Create structure ROI sequence entry
    info.StructureSetROISequence.(sprintf('Item_%i', i)).ROINumber = i;
    info.StructureSetROISequence.(sprintf('Item_%i', i))...
        .ReferencedFrameOfReferenceUID = ...
        info.ReferencedFrameOfReferenceSequence.Item_1.FrameOfReferenceUID;
    info.StructureSetROISequence.(sprintf('Item_%i', i)).ROIName = ...
        varargin{1}{i}.name;

    % Create structure ROI contour sequence entry
    info.ROIContourSequence.(sprintf('Item_%i', i)).ROIDisplayColor = ...
        varargin{1}{i}.color';
    info.ROIContourSequence.(sprintf('Item_%i', i))...
        .ReferencedROINumber = i;
    
    % Loop through points cell array
    for j = 1:length(varargin{1}{i}.points)
        
        % Specify sequence contour geometric type
        info.ROIContourSequence.(sprintf('Item_%i', i))...
            .ContourSequence.(sprintf('Item_%i', j)).ContourGeometricType = ...
            'CLOSED_PLANAR';
        
        % Specify slice thickness
        if nargin == 3 && isfield(varargin{3}, 'width')
            info.ROIContourSequence.(sprintf('Item_%i', i))...
                .ContourSequence.(sprintf('Item_%i', j))...
                .ContourSlabThickness = varargin{3}.width(3) * 10;
        end
        
        % Specify offset vector
        info.ROIContourSequence.(sprintf('Item_%i', i))...
            .ContourSequence.(sprintf('Item_%i', j)).ContourOffsetVector = ...
            [0;0;0];
        
        % Specify number of points
        info.ROIContourSequence.(sprintf('Item_%i', i))...
            .ContourSequence.(sprintf('Item_%i', j)).NumberOfContourPoints = ...
            size(varargin{1}{i}.points{j}, 1);
        
        % Specify points
        if size(varargin{1}{i}.points{j}, 1) > 0
            info.ROIContourSequence.(sprintf('Item_%i', i))...
                .ContourSequence.(sprintf('Item_%i', j)).ContourData = ...
                reshape(varargin{1}{i}.points{j}' .* repmat(rot', 1, ...
                size(varargin{1}{i}.points{j},1)) * 10, 1, [])';
        end
    end
    
    % Create ROI observations sequence
    info.RTROIObservationsSequence.(sprintf('Item_%i', i))...
        .ObservationNumber = i;
    info.RTROIObservationsSequence.(sprintf('Item_%i', i))...
        .ReferencedROINumber = i;
    info.RTROIObservationsSequence.(sprintf('Item_%i', i))...
        .RTROIInterpretedType = 'ORGAN';
end

% Log structure
if exist('Event', 'file') == 2
    Event('Saving DICOM RTSS file');
end

% Write DICOM file using dicomwrite()
status = dicomwrite([], varargin{2}, info, 'CompressionMode', 'None', ...
    'CreateMode', 'Copy', 'Endian', 'ieee-le');

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
        Event(sprintf(['DICOM RTSS export completed successfully in ', ...
            '%0.3f seconds'], toc));
    end
    
% If not empty, warn user of any errors
else
    
    % Log completion of function
    if exist('Event', 'file') == 2
        Event(sprintf(['DICOM RTSS export completed with one or more ', ...
            'warnings in %0.3f seconds'], toc), 'WARN');
    else
        warning('DICOM RTSS export completed with one or more warnings');
    end
end

% Clear temporary variables
clear info t i j n status;

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end
