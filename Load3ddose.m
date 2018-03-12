function dose = Load3ddose(path, name)
% Load3ddose loads a DOSEXYZnrc .3ddose file into a MATLAB structure that
% can be used for manipulation with other functions in this library. The
% file format was obtained from the DOSEXYZnrc user manual for version 
% PIRS-794revB, https://nrc-cnrc.github.io/EGSnrc/doc/pirs794-dosxyznrc.pdf
%
% The following variables are required for proper execution: 
%   path: string containing the path to the DICOM files
%   name: string containing the file name
%
% The following variables are returned upon succesful completion:
%   dose: structure containing the image data, error, dimensions, width, 
%       and start coordinates. The data and error fields is a three 
%       dimensional array of dose values, while the dimensions, width, and 
%       start fields are three element vectors.
%
% Below is an example of how this function is used:
%
%   path = '/path/to/files/';
%   name = 'example.3ddose';
%   dose = Load3ddose(path, name);
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017-2018 University of Wisconsin Board of Regents
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

% Open file handle to dose file
fid = fopen(fullfile(path, name), 'r');

% Read voxel dimensions
d = textscan(fid, '%d', 3);
dose.dimensions = d{1}';

% Read voxel boundaries
x = textscan(fid, '%f', dose.dimensions(1)+1);
y = textscan(fid, '%f', dose.dimensions(2)+1);
z = textscan(fid, '%f', dose.dimensions(3)+1);

% Flip y and z coordinates
y{1} = -y{1};
z{1} = -z{1};

% Read in dose and error volumes
dos = textscan(fid, '%f', prod(dose.dimensions));
err = textscan(fid, '%f', prod(dose.dimensions));

% Compute voxel widths
wx = diff(x{1});
wy = diff(y{1});
wz = diff(z{1});

% If voxels are non-uniformly spaced (>1% difference in boundary positions)
if abs(max(wx) - min(wx))/mean(wx) > 0.01 || ...
        abs(max(wy) - min(wy))/mean(wy) > 0.01 || ...
        abs(max(wz) - min(wz))/mean(wz) > 0.01
    
    % Log action
    if exist('Event', 'file') == 2
            Event(['Variable dose grid spacing found, which is not ', ...
                'supported at this time.'], 'ERROR');
        else
            error(['Variable dose grid spacing found, which is not ', ...
                'supported at this time.']);
    end
else

    % Store mean values
    dose.width = abs([mean(wx) mean(wy) mean(wz)]);

    % Store the start coordinate as the center of the first voxel
    dose.start = [min(x{1}) + dose.width(1)/2 min(y{1}) + dose.width(2)/2 ...
        min(z{1}) + dose.width(3)/2];

    % Re-shape the dose and error data
    dose.data = flip(reshape(dos{1}, dose.dimensions), 3);
    dose.error = flip(reshape(err{1}, dose.dimensions), 3);
end

% Close file handle
fclose(fid);

% Clear temporary variables
clear d x y z wx wy wz dos err fid;