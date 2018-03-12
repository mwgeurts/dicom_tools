function dose = LoadDICOMDose(path, name)
% LoadDICOMDose loads a DICOM RTDose object into a MATLAB structure that
% can be used for manipulation with other functions in this library. This
% function has been tested with Pinnacle, TomoTherapy, Oncentra, and
% ViewRay dose volumes in each standard orientation (HFS, HFP, FFS, FFP).
%
% The following variables are required for proper execution: 
%   path: string containing the path to the DICOM files
%   name: string containing the file name
%
% The following variables are returned upon succesful completion:
%   dose: structure containing the image data, dimensions, width, start 
%       coordinates, and key DICOM header values. The data is a three 
%       dimensional array of dose values in the units specified in the 
%       DICOM header, while the dimensions, width, and start fields are 
%       three element vectors. The DICOM header values are returned as 
%       strings.
%
% Below is an example of how this function is used:
%
%   path = '/path/to/files/';
%   name = '1.2.826.0.1.3680043.2.200.1679117636.903.83681.339.dcm';
%   dose = LoadDICOMDose(path, name);
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

% Check if MATLAB can find dicominfo (Image Processing Toolbox)
if exist('dicominfo', 'file') ~= 2
    
    % If not, throw an error
    if exist('Event', 'file') == 2
        Event(['The Image Processing Toolbox cannot be found and is ', ...
            'required by this function.'], 'ERROR');
    else
        error(['The Image Processing Toolbox cannot be found and is ', ...
            'required by this function.']);
    end
end

% Attempt to load file using dicominfo
try

    % Start timer
    tic;
    
    % Log file
    if exist('Event', 'file') == 2
        Event(['Parsing header data for ', name]);
    end
    
    % If dicominfo is successful, store the header information
    info = dicominfo(fullfile(path, name));

catch

    % Otherwise, the file is either corrupt or not a real DICOM
    % file, so throw an error
    if exist('Event', 'file') == 2
        Event(['File ', name, ' is not a valid DICOM object'], 'ERROR');
    else
        error(['File ', name, ' is not a valid DICOM object']);
    end
end 
         
% Store the UIDs and patient demographics
dose.classUID = info.SOPClassUID;
dose.studyUID = info.StudyInstanceUID;
dose.seriesUID = info.SeriesInstanceUID;
dose.frameRefUID = info.FrameOfReferenceUID;
if isfield(info, 'PatientName')
    dose.patientName = info.PatientName;
end
if isfield(info, 'PatientID')
    dose.patientID = info.PatientID;
end
if isfield(info, 'PatientBirthDate')
    dose.patientBirthDate = info.PatientBirthDate;
end
if isfield(info, 'PatientSex')
    dose.patientSex = info.PatientSex;
end
if isfield(info, 'PatientAge')
    dose.patientAge = info.PatientAge;
end

% Store dose dimensions
dose.width = info.PixelSpacing / 10;

% Compute grid offset differences
widths = diff(info.GridFrameOffsetVector);

% Verify that slice locations do not differ significantly (1%)
if abs(max(widths) - min(widths))/mean(widths) > 0.01
    if exist('Event', 'file') == 2
            Event(['Vector positions differ by more than 1%, suggesting ', ...
                'variable dose grid spacing. This is not supported.'], ...
                'ERROR');
        else
            error(['Vector positions differ by more than 1%, suggesting ', ...
                'variable dose grid spacing. This is not supported.']);
    end
end

% Store mean slice position difference as IEC-Y width, in cm
dose.width(3) = abs(mean(widths)) / 10;
if exist('Event', 'file') == 2
    Event(sprintf('IEC-Y resolution computed as %g (range %g to %g)', ...
        dose.width(3), min(abs(widths))/10, max(abs(widths))/10));
end

% If image orientation is missing, assume it to be HFS
if ~isfield(info, 'ImageOrientationPatient')
    info.ImageOrientationPatient = [1;0;0;0;1;0];
end

% Retrieve start voxel coordinate from DICOM header, in cm
dose.start(1) = info.ImagePositionPatient(1) / 10 * ...
    info.ImageOrientationPatient(1);

% If GridFrameOffsetVector is descending
if info.GridFrameOffsetVector(end) < info.GridFrameOffsetVector(1)

    % Read in dose data, converting to double
    dose.data = flip(rot90(double(squeeze(dicomread(info))))) * ...
        info.DoseGridScaling;
    
% Otherwise, if GridFrameOffsetVector is ascending
else
    
    % Read in dose data, converting to double
    dose.data = flip(flip(rot90(double(squeeze(dicomread(info))))), 3) * ...
        info.DoseGridScaling;
end

% Create dimensions structure field based on the daily image size
dose.dimensions = size(dose.data);

% Adjust IEC-Z to inverted value, in cm
dose.start(2) = -(info.ImagePositionPatient(2) / 10 * ...
    info.ImageOrientationPatient(5) + dose.width(2) * ...
    (dose.dimensions(2) - 1));

% Determine IEC-Y start value based on patient position
if isequal(info.ImageOrientationPatient, [1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [-1;0;0;0;-1;0]) 
    dose.start(3) = -max(info.ImagePositionPatient(3) + ...
        info.GridFrameOffsetVector) / 10;
else
    dose.start(3) = max(info.ImagePositionPatient(3) + ...
        info.GridFrameOffsetVector) / 10;
end

% Clear temporary variables
clear info widths;

% Log completion and image size
if exist('Event', 'file') == 2
    Event(sprintf(['DICOM dose loaded successfully with dimensions ', ...
        '(%i, %i, %i) in %0.3f seconds'], dose.dimensions, toc));
end
