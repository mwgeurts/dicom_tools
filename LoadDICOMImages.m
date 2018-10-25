function image = LoadDICOMImages(path, names)
% LoadDICOMImages loads a series of single-frame DICOM CT or MR images and 
% returns a formatted structure for dose calculation. See below for more 
% information on the structure format. This function will display a
% progress bar while it loads (unless MATLAB was executed with the 
% -nodisplay, -nodesktop, or -noFigureWindows flags).
%
% Standard radiotherapy (HFS, FFS, HFP, and FFP) orientations have been
% tested using data exported from Siemens and GE CT/MR scanners.
%
% The following variables are required for proper execution: 
%   path: string containing the path to the DICOM files
%   names: cell array of strings containing all files to be loaded
%
% The following variables are returned upon succesful completion:
%   image: structure containing the image data, dimensions, width, type,
%       start coordinates, and key DICOM header values. The data is a three 
%       dimensional array of image values, while the dimensions, width, and 
%       start fields are three element vectors.  The DICOM header values 
%       are returned as a strings.
%
% Below is an example of how this function is used:
%
%   path = '/path/to/files/';
%   names = {
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'
%   };
%   image = LoadDICOMImages(path, names);
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

% Execute in try/catch statement
try
    
% Log start of image load and start timer
if exist('Event', 'file') == 2
    Event(sprintf('Reading images from %s', path));
    tic;
end

% If a valid screen size is returned (MATLAB was run without -nodisplay)
if usejava('jvm') && feature('ShowFigureWindows')
    
    % Start waitbar
    progress = waitbar(0, 'Loading DICOM images');
end

% Initialize empty variables for the UIDs, patient demographics, and image 
% dimensions
image.classUID = '';
image.studyUID = '';
image.seriesUID = '';
image.frameRefUID = '';
image.instanceUIDs = cell(0);
image.patientName = '';
image.patientID = '';
image.patientBirthDate = '';
image.patientSex = '';
image.patientAge = '';

% Initialize empty 3D array for images and vector of slice locations
% (the data may not be loaded in correct order; these will be used to
% re-sort the slices later)
images = [];
sliceLocations = [];

% Loop through each file in names list
for i = 1:length(names)
    
    % Update waitbar
    if exist('progress', 'var') && ishandle(progress)
        waitbar(i/(length(names)+2), progress, ...
            sprintf('Loading DICOM images (%i/%i)', i, length(names)));
    end
    
    % Attempt to load each file using dicominfo
    try
        
        % If dicominfo is successful, store the header information
        info = dicominfo(fullfile(path, names{i}));
        
    catch
        
        % Otherwise, the file is either corrupt or not a real DICOM
        % file, so warn user
        if exist('Event', 'file') == 2
            Event(['File ', names{i}, ' is not a valid DICOM ', ...
                'image and was skipped'], 'WARN');
        end

        % Then, automatically skip to next file in directory 
        continue
    end 
    
    % If this is the first DICOM image (and the class UID
    % have not yet been set
    if strcmp(image.classUID,'') 
        
        % Store the UIDs, patient demographics
        image.classUID = info.SOPClassUID;
        image.studyUID = info.StudyInstanceUID;
        image.seriesUID = info.SeriesInstanceUID;
        image.frameRefUID = info.FrameOfReferenceUID;
        if isfield(info, 'PatientName')
            image.patientName = info.PatientName;
        end
        if isfield(info, 'PatientID')
            image.patientID = info.PatientID;
        end
        if isfield(info, 'PatientBirthDate')
            image.patientBirthDate = info.PatientBirthDate;
        end
        if isfield(info, 'PatientSex')
            image.patientSex = info.PatientSex;
        end
        if isfield(info, 'PatientAge')
            image.patientAge = info.PatientAge;
        end
        
    % Otherwise, if this file's study UID does not match the others,
    % multiple DICOM studies may be present in the same folder (not
    % currently supported)
    elseif ~strcmp(image.studyUID, info.StudyInstanceUID)
        error(['Multiple DICOM Study Instance UIDs were found in ', ...
            'this list.  Please select only one study.']);
        
    % Otherwise, if this file's series UID does not match the others,
    % multiple DICOM series may be present in the same folder (not
    % currently supported)
    elseif ~strcmp(image.seriesUID,info.SeriesInstanceUID) 
        error(['Multiple DICOM Series Instance UIDs were found in ', ...
            'this list.  Please select only one series.']);
    end
    
    % Append this slice's instance UID
    image.instanceUIDs{length(image.instanceUIDs)+1} = info.SOPInstanceUID;
    
    % Append this slice's location to the sliceLocations vector
    sliceLocations(length(sliceLocations)+1) = ...
        info.ImagePositionPatient(3); %#ok<*AGROW>
    
    % Append this slice's image data to the images array
    images(size(images,1)+1,:,:) = dicomread(info); %#ok<*AGROW>
    
    % Log file
    if exist('Event', 'file') == 2
        Event(['Reading file ', names{i}]);
    end
end

% Update waitbar
if exist('progress', 'var') && ishandle(progress)
    waitbar((length(names)+1)/(length(names)+2), progress, ...
        'Processing images');
end

% Verify info is set (if not no valid DICOM files were found)
if ~exist('info','var')
    error(['No valid DICOM images were found in the provided directory.', ...
        'Try running dicominfo() on the target file to see what error ', ...
        'occurred.']);
end

% Set image type based on series description (for MVCTs) or DICOM
% header modality tag (for everything else)
if isfield(info, 'SeriesDescription') && ...
        strcmp(info.SeriesDescription, 'CTrue Image Set')
    image.type = 'MVCT';
else
    image.type = info.Modality;
end

% Log image type
if exist('Event', 'file') == 2
    Event(['DICOM image type identified as ', image.type]);
end

% Retrieve start voxel IEC-X coordinate from DICOM header, in cm
image.start(1) = info.ImagePositionPatient(1) / 10 * ...
    info.ImageOrientationPatient(1);

% Adjust IEC-Z to inverted value, in cm
image.start(2) = -(info.ImagePositionPatient(2) * ...
    info.ImageOrientationPatient(5) + info.PixelSpacing(2) * ...
    (size(images, 2) - 1)) / 10; 

% Retrieve X/Z voxel widths from DICOM header, in cm
image.width(1) = info.PixelSpacing(1) / 10;
image.width(2) = info.PixelSpacing(2) / 10;

% If patient is Head First
if isequal(info.ImageOrientationPatient, [1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [-1;0;0;0;-1;0]) 
    
    % Store patient position
    if info.ImageOrientationPatient(5) == 1
        image.position = 'HFS';

    elseif info.ImageOrientationPatient(5) == -1
        image.position = 'HFP';
    end

    % Sort sliceLocations vector in descending order
    [~, indices] = sort(sliceLocations, 'descend');
    
    % Store start voxel IEC-Y coordinate, in cm
    image.start(3) = -max(sliceLocations) / 10;
    
% Otherwise, if the patient is Feet First
elseif isequal(info.ImageOrientationPatient, [-1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [1;0;0;0;-1;0]) 
    
    % Store patient position
    if info.ImageOrientationPatient(5) == 1
        image.position = 'FFS';
        
    elseif info.ImageOrientationPatient(5) == -1
        image.position = 'FFP';
    end
    
    % % Sort sliceLocations vector in ascending order
    [~,indices] = sort(sliceLocations, 'ascend');

    % Store start voxel IEC-Y coordinate, in cm
    image.start(3) = min(sliceLocations) / 10;
end 

% If the position wasn't identified, error
if ~isfield(image, 'position')
    error('The patient position could not be determined');
elseif exist('Event', 'file') == 2
    Event(['Patient position identified as ', image.position]);
end

% Compute slice location differences
widths = diff(sliceLocations(indices));

% Verify that slice locations do not differ significantly (1%)
if abs(max(widths) - min(widths))/mean(widths) > 0.01
    error(['Slice positions differ by more than 1%, suggesting ', ...
        'variable slice spacing. This is not supported.']);
end

% Store mean slice position difference as IEC-Y width, in cm
image.width(3) = abs(mean(widths)) / 10;
if exist('Event', 'file') == 2
    Event(sprintf('IEC-Y resolution computed as %g (range %g to %g)', ...
        image.width(3), min(abs(widths))/10, max(abs(widths))/10));
end

% Initialize daily image data array as single type
image.data = single(zeros(size(images, 3), size(images, 2), ...
    size(images, 1)));

% Re-order images based on sliceLocation sort indices
if exist('Event', 'file') == 2
    Event('Sorting DICOM images');
end

% Loop through each slice
for i = 1:length(sliceLocations)
    
    % Set the image data based on the index value
    image.data(:, :, i) = ...
        single(rot90(permute(images(indices(i), :, :), [2 3 1])));
end

% Remove values less than zero (some DICOM images place voxels outside the
% field of view to negative values)
image.data = max(image.data, 0);

% Flip images in IEC-X direction
image.data = flip(image.data, 1);

% Create dimensions structure field based on the daily image size
image.dimensions = size(image.data);

% Update waitbar
if exist('progress', 'var') && ishandle(progress)
    waitbar(1.0, progress, 'Image loading completed');
end

% If an image was successfully loaded
if isfield(image, 'dimensions')
    
    % Log completion and image size
    if exist('Event', 'file') == 2
        Event(sprintf(['DICOM images loaded successfully with dimensions ', ...
            '(%i, %i, %i) in %0.3f seconds'], image.dimensions, toc));
    end

% Otherwise, warn user
else
    error('DICOM image data could not be parsed');
end

% Close waitbar
if exist('progress', 'var') && ishandle(progress)
    close(progress);
end

% Clear temporary variables
clear i images info sliceLocations indices progress widths;

% Catch errors, log, and rethrow
catch err
    
    % Delete progress handle if it exists
    if exist('progress', 'var') && ishandle(progress), delete(progress); end
    
    % Log error
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end
