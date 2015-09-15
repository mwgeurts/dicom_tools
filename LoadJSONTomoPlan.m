function planData = LoadJSONTomoPlan(json)
% LoadJSONTomoPlan parses relevant tags from a TomoTherapy DICOM RT Plan
% structure that has been stored in JSON format (see QueryMobius for a
% description of this format). This function returns a TomoTherapy delivery
% plan structure (see tomo_extract/LoadPlan for a description of this 
% format).
%
% The following variables are required for proper execution: 
%   json: structure containing DICOM RT Plan header tags, where the keys
%       correspond to the header group/element hex codes in the format
%       GXXX/EXXX.
%
% The following variables are returned upon succesful completion:
%   planData: structure containing delivery plan data, including patient
%       demographics, plan name/date, presciption, and plan parameters
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

% Execute in try/catch statement
try
    
% Log start of plan load and start timer
if exist('Event', 'file') == 2
    Event('Extracting plan info from JSON structure');
    tic;
end

% Set patient name
planData.patientName = json.G0010E0010;

% Set patient ID
planData.patientID = json.G0010E0020;

% Set patient birth date
planData.patientBirthDate = json.G0010E0030;

% Set patient sex
planData.patientSex = json.G0010E0040;

% Store the plan label
planData.planLabel = json.G300aE0003;

% Store patient position
planData.position = json.G300aE0180{1}.G0018E5100;

% Store the date and time as a timestamp
planData.timestamp = datetime([json.G300aE0006, '-', json.G300aE0007], ...
    'InputFormat', 'yyyyMMdd-HHmmss');

% Store the plan delivery type, removing 'TomoTherapy Beam'
planData.planType = strrep(json.G300aE00b0{1}.G300aE00c2, ...
    ' TomoTherapy Beam', '');

% Store the approving user name
planData.approver = json.G0008E1070;

% Store the pitch, field width, front and back fields
[tokens, ~] = regexp(json.G300aE00b0{1}.G300aE00c3, ...
    'Beam pitch ([0-9\.]+), Field size ([0-9\.]+) mm', 'tokens');
if ~isempty(tokens)
    planData.pitch = str2double(tokens{1}{1});
    planData.fieldWidth = str2double(tokens{1}{1});
    planData.frontField = -planData.fieldWidth / 2;
    planData.backField = planData.fieldWidth / 2;
end
clear tokens;

% Store the fractions
planData.fractions = json.G300aE0070{1}.G300aE0078;

% Store the laser positions
planData.movableLaser(1) = json.G300aE0180{1}.G300aE01b4{1}.G300aE01bc;
planData.movableLaser(2) = json.G300aE0180{1}.G300aE01b4{2}.G300aE01bc;
planData.movableLaser(3) = json.G300aE0180{1}.G300aE01b4{3}.G300aE01bc;

% Store the prescription information
[tokens, ~] = regexp(json.G300aE000e, ['([0-9\.]+)\% of the (.+) ', ...
    '(volume|mean|median) receives at least ([0-9\.]+) Gy'], 'tokens');
if ~isempty(tokens)
    planData.rtType = tokens{1}{3};
    planData.rxDose = str2double(tokens{1}{4});
    planData.rxVolume = str2double(tokens{1}{1});
    planData.rxStructure = tokens{1}{2};
end
clear tokens;

% Store the machine name
planData.machine = json.G0008E1010;

% Store the jaw type
planData.jawType = json.G300aE00b0{1}.G300aE00c4;

% Store the number of projections
planData.totalTau = json.G300aE00b0{1}.G300aE0110;
planData.numberOfProjections = planData.totalTau;

% Store the total treatment time (minutes)
planData.txTime = json.G300aE0070{1}.G300cE0004{1}.G300aE0086;

% Compute scale using treatment time and projections
planData.scale = planData.txTime * 60 / planData.totalTau;

% Store the gantry start angle to the events cell array.  The
% first cell is tau, the second is type, and the third is the
% value.
planData.events{1,1} = 0;
planData.events{1,2} = 'gantryAngle';
planData.events{1,3} = json.G300aE00b0{1}.G300aE0111{1}.G300aE011e;

% Store the isocenter positions to the events cell array. 
planData.events{2,1} = 0;
planData.events{2,2} = 'isoX';
planData.events{2,3} = json.G300aE00b0{1}.G300aE0111{1}.G300aE012c(1);
planData.events{3,1} = 0;
planData.events{3,2} = 'isoY';
planData.events{3,3} = json.G300aE00b0{1}.G300aE0111{1}.G300aE012c(2);
planData.events{4,1} = 0;
planData.events{4,2} = 'isoZ';
planData.events{4,3} = json.G300aE00b0{1}.G300aE0111{1}.G300aE012c(3);

% Store the gantry rate
planData.events{5,1} = 0;
planData.events{5,2} = 'gantryRate';
planData.events{5,3} = json.G300aE00b0{1}.G300aE0111{2}.G300aE011e - ...
    json.G300aE00b0{1}.G300aE0111{1}.G300aE011e;
        
% Store the couch velocity
planData.events{6,1} = 0;
planData.events{6,2} = 'isoZRate';
planData.events{6,3} = json.G300aE00b0{1}.G300aE0111{2}.G300aE012c(3) - ...
    json.G300aE00b0{1}.G300aE0111{1}.G300aE012c(3);

% Finalize Events array
% Add a sync event at tau = 0.   Events that do not have a value
% are given the placeholder value 1.7976931348623157E308 
planData.events{7,1} = 0;
planData.events{7,2} = 'sync';
planData.events{7,3} = 1.7976931348623157E308;

% Add a projection width event at tau = 0
planData.events{8,1} = 0;
planData.events{8,2} = 'projWidth';
planData.events{8,3} = 1;

% Add an eop event at the final tau value (stored in fluence.totalTau).
%  Again, this event does not have a value, so use the placeholder
planData.events{9,1} = planData.totalTau;
planData.events{9,2} = 'eop';
planData.events{9,3} = 1.7976931348623157E308;

%% Finish up
% Report success
if exist('Event', 'file') == 2
    Event(sprintf(['Plan data loaded successfully with %i events and %i', ...
        ' projections in %0.3f seconds'], size(planData.events, 1), ...
        planData.numberOfProjections, toc));
end

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end
