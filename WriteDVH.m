function varargout = WriteDVH(varargin)
% WriteDVH computes the DVH for each structure included in the image input
% variable given the dose input variable and writes the resulting DVHs to 
% a comma-separated value file. The DVHs can also be optionally returned as
% an array. Note, if a DVH filename is not provided in the third input
% argument, WriteDVH will simply compute the DVH from the image,
% structures, and dose and optionally return the array.
%
% The first row contains the file name, the second row contains column 
% headers for each structure set (including the volume in cc in 
% parentheses), with each subsequent row containing the percent volume of 
% each structure at or above the dose specified in the first column (in 
% Gy).  The resolution is determined by dividing the maximum dose by 1001,
% or nbins + 1;
%
% The following variables are required for proper execution: 
%   varargin{1}: structure containing the CT image data and structure set 
%       data. See LoadDICOMImages and LoadDICOMStructures for more
%       information on the format of this object.
%   varargin{2}: structure containing the calculated dose. Must contain
%       start, width, and data fields. See CalcDose for more information on 
%       the format of this object. Start and widths are in cm.
%   varargin{3} (optional): string containing the path and name to write 
%       the DVH .csv file to. MATLAB must have write access to this 
%       location to execute. If not provided, a DVH file will not be saved.
%
% The following variables are returned upon succesful completion:
%   varargout{1} (optional): a 1001 by n+1 array of cumulative DVH values 
%       for n structures where n+1 is the x-axis value (separated into 1001 
%       bins).
%
% Below are examples of how this function is used:
%
%   % Load DICOM images
%   path = '/path/to/files/';
%   names = {
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'
%   };
%   image = LoadDICOMImages(path, names);
%
%   % Load DICOM structure set into image structure
%   name = '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641579.747.dcm';
%   image.structures = LoadDICOMStructures(path, name, image);
%
%   % Create dose array with same dimensions and coordinates as image
%   dose.data = rand(size(image.data));
%   dose.width = image.width;
%   dose.start = image.start;
%
%   % Declare file name and path to write DVH to
%   dest = '/path_to_file/dvh.csv';
%
%   % Execute WriteDVH
%   WriteDVH(image, dose, dest);
%
%   % Execute WriteDVH again, this time returning the DVH as an array
%   dvh = WriteDVH(image, dose, dest);
%
%   % Compute but do not save the DVH to a file
%   dvh = WriteDVH(image, dose);
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

% Specify number of bins
nbins = 1000;

% Execute in try/catch statement
try
    
% Log start of DVH computation and start timer
if exist('Event', 'file') == 2
    Event('Computing dose volume histograms');
    tic;
end

% If the dose variable contains a valid data array
if isfield(varargin{2}, 'data') && size(varargin{2}.data, 1) > 0
    
    % If the image size, pixel size, or start differs between datasets
    if size(varargin{2}.data,1) ~= size(varargin{1}.data,1) ...
            || size(varargin{2}.data,2) ~= size(varargin{1}.data,2) ...
            || size(varargin{2}.data,3) ~= size(varargin{1}.data,3) ...
            || isequal(varargin{2}.width, varargin{1}.width) == 0 ...
            || isequal(varargin{2}.start, varargin{1}.start) == 0

        % Create 3D mesh for reference image
        [refX, refY, refZ] = meshgrid(single(varargin{1}.start(2) + ...
            varargin{1}.width(2) * (size(varargin{1}.data,2) - 1): ...
            -varargin{1}.width(2):varargin{1}.start(2)), single(varargin{1}.start(1): ...
            varargin{1}.width(1):varargin{1}.start(1) + varargin{1}.width(1)...
            * (size(varargin{1}.data,1) - 1)), single(varargin{1}.start(3):...
            varargin{1}.width(3):varargin{1}.start(3) + varargin{1}.width(3)...
            * (size(varargin{1}.data,3) - 1)));

        % Create GPU 3D mesh for secondary dataset
        [secX, secY, secZ] = meshgrid(single(varargin{2}.start(2) + ...
            varargin{2}.width(2) * (size(varargin{2}.data,2) - 1):...
            -varargin{2}.width(2):varargin{2}.start(2)), single(varargin{2}.start(1): ...
            varargin{2}.width(1):varargin{2}.start(1) + varargin{2}.width(1) ...
            * (size(varargin{2}.data,1) - 1)), single(varargin{2}.start(3):...
            varargin{2}.width(3):varargin{2}.start(3) + varargin{2}.width(3) ...
            * (size(varargin{2}.data,3) - 1)));
   
        % Attempt to use GPU to interpolate dose to image/structure
        % coordinate system.  If a GPU compatible device is not
        % available, any errors will be caught and CPU interpolation
        % will be used instead.
        try
            % Initialize and clear GPU memory
            gpuDevice(1);

            % Interpolate the dose to the reference coordinates using
            % GPU linear interpolation, and store back to 
            % varargin{2}.data
            varargin{2}.data = gather(interp3(gpuArray(secX), ...
                gpuArray(secY), gpuArray(secZ), ...
                gpuArray(varargin{2}.data), gpuArray(refX), ...
                gpuArray(refY), gpuArray(refZ), 'linear', 0));

            % Clear GPU memory
            gpuDevice(1);

        % Catch any errors that occured and attempt CPU interpolation
        % instead
        catch
            % Interpolate the dose to the reference coordinates using
            % linear interpolation, and store back to varargin{2}.data
            varargin{2}.data = interp3(secX, secY, secZ, ...
                varargin{2}.data, refX, refY, refZ, '*linear', 0);
        end

        % Clear temporary variables
        clear refX refY refZ secX secY secZ;
    end

    % Store the maximum value in the reference dose
    maxdose = max(max(max(varargin{2}.data)));

    % If max dose is zero, throw an error
    if maxdose == 0
        if exist('Event', 'file') == 2
            Event('The dose array is empty', 'ERROR');
        else
            error('The dose array is empty');
        end
    end
    
    % Initialize array for reference DVH values with 1001 bins
    dvh = zeros(nbins + 1, length(varargin{1}.structures) + 1);

    % Defined the last column to be the x-axis, ranging from 0 to the
    % maximum dose
    dvh(:, length(varargin{1}.structures) + 1) = 0:maxdose/nbins:maxdose;

    % Loop through each reference structure
    for i = 1:length(varargin{1}.structures)

        % If valid reference dose data was passed
        if isfield(varargin{2}, 'data') && ...
                size(varargin{2}.data,1) > 0

            % Multiply the dose by the structure mask and reshape into
            % a vector (adding 1e-6 is necessary to retain zero dose
            % values inside the structure mask)
            data = reshape((varargin{2}.data + 1e-6) .* ...
                varargin{1}.structures{i}.mask, 1, []);

            % Remove all zero values (basically, voxels outside of the
            % structure mask
            data(data==0) = [];
            
            % Compute cumulative histogram
            dvh(1:nbins,i) = 1 - histcounts(data, dvh(:, ...
                length(varargin{1}.structures) + 1), ...
                'Normalization', 'cdf')';

            % Normalize histogram to relative volume
            dvh(:,i) = dvh(:,i) / max(dvh(:,i)) * 100;

            % Clear temporary variable
            clear data;
        end
    end
    
    % Set varargout, if needed
    if nargout == 1
        varargout{1} = dvh;
    elseif nargout > 1
        if exist('Event', 'file') == 2
            Event('Too many output variables requested', 'ERROR');
        else
            error('Too many output variables requested');
        end
    end
    
    % Clear temporary variable
    clear i maxdose;

% Otherwise, the dose array is invalid
else
    % Throw an error
    if exist('Event', 'file') == 2
        Event('The dose array is invalid', 'ERROR');
    else
        error('The dose array is invalid');
    end
end

% If a filename was provided
if nargin == 3
    
    % Extract file name
    [~, file, ext] = fileparts(varargin{3});
    
    % Log event
    if exist('Event', 'file') == 2
        Event(sprintf('Writing dose volume histogram to %s', ...
            strcat(file, ext)));
    end
    
    % Open a write file handle to the file
    fid = fopen(varargin{3}, 'w');
    
    % If a valid file handle was returned
    if fid > 0
        
        % Write the file name in the first row, starting with a hash
        fprintf(fid, '#,%s\n', strcat(file, ext));
        
        % Write the structure names and volumes in the second row
        for i = 1:length(varargin{1}.structures)
            fprintf(fid, ',%s (%i)(volume: %0.2f)', ...
                varargin{1}.structures{i}.name, i, ...
                varargin{1}.structures{i}.volume); 
        end
        fprintf(fid, '\n');
        
        % Circshift dvh to place dose in first column
        dvh = circshift(dvh, [0 1])';
        
        % Write dvh contents to file
        fprintf(fid, [repmat('%g,', 1, size(dvh,1)), '\n'], dvh);
        
        % Close file handle
        fclose(fid);
        
    % Otherwise MATLAB couldn't open a write handle
    else
        
        % Throw an error
        if exist('Event', 'file') == 2
            Event(sprintf('A file handle could not be opened to %s', ...
                varargin{3}), 'ERROR');
        else
            error('A file handle could not be opened to %s', varargin{3});
        end
    end
end

% Log completion of function
if exist('Event', 'file') == 2
    Event(sprintf(['Dose volume histograms completed successfully in ', ...
        '%0.3f seconds'], toc));
end

% Clear temporary variables
clear i dvh fid file ext;

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end
