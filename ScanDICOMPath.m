function array = ScanDICOMPath(path, varargin)
% ScanDICOMPath recursively searches a provided path for DICOM data 
% and returns a cell array of DICOM images, RT structure sets, RT plan, and 
% RT dose files along with basic header information found within the 
% directory. DICOM files must contain the following minimum tags: 
% SOPInstanceUID, MediaStorageSOPClassUID, Modality, PatientName, and 
% PatientID.
% 
% This function will display a progress bar while it loads unless MATLAB 
% was executed with the -nodisplay, -nodesktop, or -noFigureWindows flags 
% or if a 'Progress' input option is set to false. If the 'DOSEXYZnrc' 
% input option is set to true, this function will also identify DOSEXYZnrc 
% Monte Carlo calculated dose files with a .3ddose extension and add them 
% as RTDOSE options.
%
% The following variables are required for proper execution: 
%   path: string containing the path to the DICOM files, structure of 
%       files (see dir command for format), or path to a single file
%
% Upon successful completion, the function will return an n x 11 cell
% array, where n is the number of files returned and the columns correspond
% to the following values:
%   Column 1: string containing the file name
%   Column 2: string containing the full path to the file
%   Column 3: string containing the file modality ('CT', 'MR', 'RTDOSE',
%       'RTPLAN', or 'RTSTRUCT')
%   Column 4: string containing the DICOM instance UID
%   Column 5: string containing the patient name, starting with the last 
%       name separated by commas
%   Column 6: string containing the patient's ID
%   Column 7: string containing the frame of reference UID
%   Column 8: string containing the study or referenced study UID
%   Column 9: if RTPLAN or RTDOSE with a corresponding RTPLAN in the list, 
%       a string containing the plan name
%   Column 10: if RTDOSE, the dose type ('PLAN' or 'BEAM')
%   Column 11: if RTPLAN, a cell array of beam names, or if a BEAM RTDOSE,
%       the corresponding beam name
%   Column 12: if RTPLAN, a cell array of machine names, or if RTDOSE, the
%       corresponding machine name
%   Column 13: if RTPLAN, a cell array of beam energies, or if RTDOSE, the
%       corresponding energy
%   Column 14: if RTPLAN, and a PatientSetupSequence exists, an array of 
%       corresponding SetupDeviceParameter values (for Tomo, these are the 
%       red laser positions)
% 
% Below are examples of how this function is used:
%
%   % Scan test_directory for DICOM files
%   list = ScanDICOMPath('../test_directory');
%
%   % Re-scan, hiding the progress bar and including DOSEXYZnrc files
%   list = ScanDICOMPath('../test_directory', 'Progress', false, ...
%       'DOSEXYZnrc', true);
%
%   % List all CT file names found within the list
%   list(ismember(t(:,3), 'CT'))
%
%   % List all unique Frame of Reference UIDs in the list
%   unique(list(:,7))
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2018 University of Wisconsin Board of Regents
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

% Set default options
opt.Progress = true;
opt.DOSEXYZnrc = false;

% Parse provided options
for i = 2:2:nargin
    opt.(varargin{i-1}) = varargin{i};
end

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

% If a valid screen size is returned (MATLAB was run without -nodisplay)
if usejava('jvm') && feature('ShowFigureWindows') && opt.Progress
    progress = waitbar(0, 'Scanning path for DICOM files');
end

% Scan the directory for DICOM files
if exist('Event', 'file') == 2
    Event('Scanning path for DICOM files');
    t = tic;
end

% Set list based on format of provided files
if isstruct(path)
    list = path;
elseif isfolder(path)
    list = dir(fullfile(path, '**'));

% If not, throw an error
else
    if exist('Event', 'file') == 2
        Event('The provided input is not a folder', 'ERROR');
    else
        error('The provided input is not a folder');
    end
end

% Initialize return array of DICOM files
array = cell(0,14);

% Loop through each folder, subfolder
for i = 1:length(list)

    % Update waitbar
    if exist('progress', 'var') && ishandle(progress) && opt.Progress
        waitbar(i/length(list), progress);
    end
   
    % If the folder content is . or .., skip to next folder in list
    if strcmp(list(i).name, '.') || strcmp(list(i).name, '..')
        continue

    % Otherwise, if the folder content is a subfolder    
    elseif list(i).isdir == 1
        continue;

    % See if this is a .3ddose file
    elseif opt.DOSEXYZnrc && endsWith(list(i).name, '.3ddose', ...
            'IgnoreCase', true)
        
        % Separate file path, name
        [p, n, e] = fileparts(fullfile(list(i).folder, list(i).name));
        
        % Add file as an RTDOSE image with unique DICOM UID
        array = [array; horzcat([n e], p, 'RTDOSE', dicomuid, cell(1,10))]; %#ok<*AGROW>
        
    % Otherwise, see if the file is a DICOM file
    else

        % Separate file path, name
        [p, n, e] = fileparts(fullfile(list(i).folder, list(i).name));
        
        % Attempt to parse the DICOM header
        try
            % Execute dicominfo
            info = dicominfo(fullfile(list(i).folder, list(i).name));

            % Verify storage class field exists
            if ~isfield(info, 'MediaStorageSOPClassUID')
                continue
            end
            
            % Store basic contents
            new = horzcat([n e], p, info.Modality, info.SOPInstanceUID, ...
                    strjoin(struct2cell(info.PatientName), ', '), ...
                    info.PatientID, cell(1,8));

            % If CT
            if strcmp(info.MediaStorageSOPClassUID, ...
                    '1.2.840.10008.5.1.4.1.1.2') || ...
                    strcmp(info.MediaStorageSOPClassUID, ...
                    '1.2.840.10008.5.1.4.1.1.4')
                
                % Verify that enhanced contents exist
                if isfield(info, 'FrameOfReferenceUID')
                    new{7} = info.FrameOfReferenceUID;
                end
                if isfield(info, 'StudyInstanceUID')
                    new{8} = info.StudyInstanceUID;
                end
                 
                % Append to table array
                array = [array; new]; 
                
            % Otherwise, if structure
            elseif strcmp(info.MediaStorageSOPClassUID, ...
                    '1.2.840.10008.5.1.4.1.1.481.3')
                
                % Verify that enhanced contents exist
                if isfield(info, 'ReferencedFrameOfReferenceSequence')
                    new{7} = info.ReferencedFrameOfReferenceSequence.Item_1...
                        .FrameOfReferenceUID;
                end
                if isfield(info, 'ReferencedStudySequence')
                    new{8} = info.ReferencedStudySequence...
                        .Item_1.ReferencedSOPInstanceUID;
                end
                 
                % Append to table array
                array = [array; new]; 
                
            % Otherwise, if dose
            elseif strcmp(info.MediaStorageSOPClassUID, ...
                    '1.2.840.10008.5.1.4.1.1.481.2')
                
                % Verify that enhanced contents exist
                if isfield(info, 'FrameOfReferenceUID')
                    new{7} = info.FrameOfReferenceUID;
                end
                if isfield(info, 'ReferencedStudySequence')
                    new{8} = info.ReferencedStudySequence.Item_1...
                        .ReferencedSOPInstanceUID;
                end
                if isfield(info, 'ReferencedRTPlanSequence')
                    new{9} = info.ReferencedRTPlanSequence...
                        .Item_1.ReferencedSOPInstanceUID;
                    if isfield(info.ReferencedRTPlanSequence...
                            .Item_1, 'ReferencedFractionGroupSequence') && ...
                            isfield(info.ReferencedRTPlanSequence...
                            .Item_1.ReferencedFractionGroupSequence.Item_1, ...
                            'ReferencedBeamSequence')
                        new{11} = {info.ReferencedRTPlanSequence...
                            .Item_1.ReferencedFractionGroupSequence.Item_1...
                            .ReferencedFractionGroupNumber 
                            info.ReferencedRTPlanSequence...
                            .Item_1.ReferencedFractionGroupSequence.Item_1...
                            .ReferencedBeamSequence.Item_1...
                            .ReferencedBeamNumber};
                    end
                end
                if isfield(info, 'DoseSummationType')
                    new{10} = info.DoseSummationType;
                end
                 
                % Append to table array
                array = [array; new]; 
                
            % Otherwise, if RT plan
            elseif strcmp(info.MediaStorageSOPClassUID, ...
                    '1.2.840.10008.5.1.4.1.1.481.5')
                
                % Verify that enhanced contents exist
                if isfield(info, 'FrameOfReferenceUID')
                    new{7} = info.FrameOfReferenceUID;
                end
                if isfield(info, 'ReferencedStudySequence')
                    new{8} = info.ReferencedStudySequence...
                        .Item_1.ReferencedSOPInstanceUID;
                end
                if isfield(info, 'RTPlanLabel')
                    new{9} = info.RTPlanLabel;
                end
                if isfield(info, 'FractionGroupSequence') && ...
                        isfield(info, 'BeamSequence')
                    
                    % Store referenced beam numbers as 2D cell array of 
                    % fraction group and beam numbers
                    new{11} = cell(0);
                    groups = fieldnames(info.FractionGroupSequence);
                    for j = 1:length(groups)
                        beams = fieldnames(info.FractionGroupSequence...
                            .(groups{j}).ReferencedBeamSequence);
                        for k = 1:length(beams)
                            new{11}{info.FractionGroupSequence.(groups{j})...
                                .FractionGroupNumber, k} = info...
                                .FractionGroupSequence...
                                .(groups{j}).ReferencedBeamSequence...
                                .(beams{k}).ReferencedBeamNumber;
                        end
                    end
                    
                    % Now go replace beam numbers with names and add
                    % machine/energy
                    new{12} = cell(size(new{11}));
                    new{13} = cell(size(new{11}));
                    beams = fieldnames(info.BeamSequence);
                    for j = 1:length(beams)
                        for k = 1:size(new{11},1)
                            for l = 1:size(new{11},2)
                                if isnumeric(new{11}{k,l}) && ...
                                        new{11}{k,l} == info.BeamSequence...
                                        .(beams{j}).BeamNumber
                                    new{11}{k,l} = info.BeamSequence...
                                        .(beams{j}).BeamName;
                                    new{12}{k,l} = info.BeamSequence...
                                        .(beams{j}).TreatmentMachineName;
                                    new{13}{k,l} = num2str(info.BeamSequence...
                                        .(beams{j}).ControlPointSequence...
                                        .Item_1.NominalBeamEnergy);
                                    
                                    % Add non-standard identifier
                                    if isfield(info.BeamSequence...
                                            .(beams{j}), 'FluenceMode') && ...
                                            isfield(info.BeamSequence...
                                            .(beams{j}), 'FluenceModeID')&& ...
                                            strcmp(info.BeamSequence.(beams{j})...
                                            .FluenceMode, 'NON_STANDARD')
                                        new{13}{k,l} = [new{13}{k,l}, ...
                                            info.BeamSequence.(beams{j})...
                                            .FluenceModeID];
                                    end
                                end
                            end
                        end    
                    end
                end
                
                % Add PatientSetupSequence
                if isfield(info, 'PatientSetupSequence') && ...
                        isfield(info.PatientSetupSequence, 'Item_1') && ...
                        isfield(info.PatientSetupSequence.Item_1, ...
                        'SetupDeviceSequence')
                    items = fieldnames(info.PatientSetupSequence.Item_1...
                        .SetupDeviceSequence);
                    
                    new{14} = zeros(length(items), 1);
                    for j = 1:length(items)
                        new{14}(j) = info.PatientSetupSequence.Item_1...
                            .SetupDeviceSequence.(items{j})...
                            .SetupDeviceParameter;
                    end
                end
                 
                % Append to table array
                array = [array; new]; 
            end

        % If an exception occurs, the file is not a DICOM file so skip
        catch
            continue
        end
    end
end

% Loop through list, matching RT DOSE volumes to RT PlANs
for i = 1:size(array,1)
    
    % Match plan UID to UID of other DICOM files
    if ~isempty(array{i,9})
        [m,idx] = ismember(array{i,9}, array(:,4));

        % If RTDOSE is BEAM, match beam name, machine, and energy
        if m && strcmp(array{i,3}, 'RTDOSE') && ...
                strcmp(array{i,10}, 'BEAM') && ~isempty(array{i,11})
            array{i,13} = array{idx,13}{array{i,11}{1}, array{i,11}{2}};
            array{i,12} = array{idx,12}{array{i,11}{1}, array{i,11}{2}};
            array{i,11} = array{idx,11}{array{i,11}{1}, array{i,11}{2}};
        end
        
        % If RTDOSE is PLAN, duplicate PLAN cell arrays
        if m && strcmp(array{i,3}, 'RTDOSE') && strcmp(array{i,10}, 'PLAN')
            array{i,14} = array{idx,14};
            array{i,13} = array{idx,13};
            array{i,12} = array{idx,12};
            array{i,11} = array{idx,11};
        end
        
        % If RTDOSE
        if m && strcmp(array{i,3}, 'RTDOSE')
            array{i,9} = array{idx,9};
        end
    end
end

% Close waitbar
if exist('progress', 'var') == 1 && ishandle(progress)
    close(progress);
end

% Log completion
if exist('Event', 'file') == 2
    Event(sprintf(['Scan completed, finding %i image, %i structure ', ...
        'sets, %i plan and %i dose files in %0.3f seconds'], ...
        sum(ismember(array(:,3), 'CT')) + sum(ismember(array(:,3), 'MR')), ...
        sum(ismember(array(:,3), 'RTSTRUCT')), ...
        sum(ismember(array(:,3), 'RTPLAN')), ...
        sum(ismember(array(:,3), 'RTDOSE')), toc(t)));
end

% Clear temporary variables
clear i j k l p n e t list new info progress;

