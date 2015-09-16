function rtplan = LoadJSONPlan(json)
% LoadJSONPlan parses relevant tags from a Conventional IMRT/VMAT DICOM RT 
% Plan structure that has been stored in JSON format (see QueryMobius for a
% description of this format). This function returns a DICOM-compatible 
% structure similar to the format had the RT plan been loaded using
% dicominfo().
%
% The following variables are required for proper execution: 
%   json: structure containing DICOM RT Plan header tags, where the keys
%       correspond to the header group/element hex codes in the format
%       GXXX/EXXX.
%
% The following variables are returned upon succesful completion:
%   rtplan: structure containing patient demographics, beam information,
%       and prescription details.
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

% Store patient and plan fields
if isfield(json, 'G0008E0005')
    rtplan.SpecificCharacterSet = json.G0008E0005;
end
if isfield(json, 'G0008E0016')
    rtplan.SOPClassUID = json.G0008E0016;
end
if isfield(json, 'G0008E0018')
    rtplan.SOPInstanceUID = json.G0008E0018;
end
if isfield(json, 'G0008E0020')
    rtplan.StudyDate = json.G0008E0020;
end
if isfield(json, 'G0008E0030')
    rtplan.StudyTime = json.G0008E0030;
end
if isfield(json, 'G0008E0050')
    rtplan.AccessionNumber = json.G0008E0050;
end
if isfield(json, 'G0008E0060')
    rtplan.Modality = json.G0008E0060;
end
if isfield(json, 'G0008E0070')
    rtplan.Manufacturer = json.G0008E0070;
end
if isfield(json, 'G0008E0090')
    rtplan.ReferringPhysicianName = json.G0008E0090;
end
if isfield(json, 'G0008E1010')
    rtplan.StationName = json.G0008E1010;
end
if isfield(json, 'G0008E1030')
    rtplan.StudyDescription = json.G0008E1030;
end
if isfield(json, 'G0008E1070')
    rtplan.OperatorName = json.G0008E1070;
end
if isfield(json, 'G0008E1090')
    rtplan.ManufacturerModelName = json.G0008E1090;
end
if isfield(json, 'G0010E0010')
    rtplan.PatientName = json.G0010E0010;
end
if isfield(json, 'G0010E0020')
    rtplan.PatientID = json.G0010E0020;
end
if isfield(json, 'G0010E0030')
    rtplan.PatientBirthDate = json.G0010E0030;
end
if isfield(json, 'G0010E0040')
    rtplan.PatientSex = json.G0010E0040;
end
if isfield(json, 'G0018E1020')
    rtplan.SoftwareVersion = json.G0018E1020;
end
if isfield(json, 'G0020E000d')
    rtplan.StudyInstanceUID = json.G0020E000d;
end
if isfield(json, 'G0020E000e')
    rtplan.SeriesInstanceUID = json.G0020E000e;
end
if isfield(json, 'G0020E0010')
    rtplan.StudyID = json.G0020E0010;
end
if isfield(json, 'G0020E0011')
    rtplan.SeriesNumber = json.G0020E0011;
end

% Store RT Plan fields
if isfield(json, 'G300aE0002')
    rtplan.RTPlanLabel = json.G300aE0002;
end
if isfield(json, 'G300aE0003')
    rtplan.RTPlanName = json.G300aE0003;
end
if isfield(json, 'G300aE0004')
    rtplan.RTPlanDescription = json.G300aE0004;
end
if isfield(json, 'G300aE0006')
    rtplan.RTPlanDate = json.G300aE0006;
end
if isfield(json, 'G300aE0007')
    rtplan.RTPlanTime = json.G300aE0007;
end
if isfield(json, 'G300aE000c')
    rtplan.RTPlanGeometry = json.G300aE000c;
end

% Store Fraction group sequence
if isfield(json, 'G300aE0070')
    for i = 1:length(json.G300aE0070)

        if isfield(json.G300aE0070{i}, 'G300aE0071')
            rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                .FractionGroupNumber = json.G300aE0070{i}.G300aE0071;
        end
        if isfield(json.G300aE0070{i}, 'G300aE0078')
            rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                .NumberOfFractionsPlanned = json.G300aE0070{i}.G300aE0078;
        end
        if isfield(json.G300aE0070{i}, 'G300aE0080')
            rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                .NumberOfBeams = json.G300aE0070{i}.G300aE0080;
        end
        if isfield(json.G300aE0070{i}, 'G300aE00a0')
            rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                .NumberOfBrachyApplicationSetups = ...
                json.G300aE0070{i}.G300aE00a0;
        end

        % Store referenced beam sequences
        if isfield(json.G300aE0070{i}, 'G300cE0004')
            for j = 1:length(json.G300aE0070{i}.G300cE0004)

                if isfield(json.G300aE0070{i}.G300cE0004{j}, 'G300aE0082')
                    rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                        .ReferencedBeamSequence.(sprintf('Item_%i', j))...
                        .BeamDoseSpecificationPoint ...
                        = json.G300aE0070{i}.G300cE0004{j}.G300aE0082;
                end
                if isfield(json.G300aE0070{i}.G300cE0004{j}, 'G300aE0084')
                    rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                        .ReferencedBeamSequence.(sprintf('Item_%i', j))...
                        .BeamDose ...
                        = json.G300aE0070{i}.G300cE0004{j}.G300aE0084;
                end
                if isfield(json.G300aE0070{i}.G300cE0004{j}, 'G300aE0086')
                    rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                        .ReferencedBeamSequence.(sprintf('Item_%i', j))...
                        .BeamMeterset = json.G300aE0070{i}.G300cE0004{j}...
                        .G300aE0086;
                end
                if isfield(json.G300aE0070{i}.G300cE0004{j}, 'G300cE0006')
                    rtplan.FractionGroupSequence.(sprintf('Item_%i', i))...
                        .ReferencedBeamSequence.(sprintf('Item_%i', j))...
                        .ReferencedBeamNumber ...
                        = json.G300aE0070{i}.G300cE0004{j}.G300cE0006;
                end
            end
        end
    end
end

% Initialize control point counter
cp = 0;

% Store beam sequences
if isfield(json, 'G300aE00b0')
    for i = 1:length(json.G300aE00b0)

        if isfield(json.G300aE00b0{i}, 'G0008E0070')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).Manufacturer = ...
                json.G300aE00b0{i}.G0008E0070;
        end
        if isfield(json.G300aE00b0{i}, 'G0008E0080')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).InstitutionName = ...
                json.G300aE00b0{i}.G0008E0080;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00b2')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).TreatmentMachineName = ...
                json.G300aE00b0{i}.G300aE00b2;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00b3')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).PrimaryDosimeterUnit = ...
                json.G300aE00b0{i}.G300aE00b3;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00b4')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).SourceAxisDistance = ...
                json.G300aE00b0{i}.G300aE00b4;
        end

        % Store beam limiting device sequences
        if isfield(json.G300aE00b0{i}, 'G300aE00b6')
            for j = 1:length(json.G300aE00b0{i}.G300aE00b6)

                if isfield(json.G300aE00b0{i}.G300aE00b6{j}, 'G300aE00b8')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .BeamLimitingDeviceSequence.(sprintf('Item_%i', j))...
                        .RTBeamLimitingDeviceType = ...
                        json.G300aE00b0{i}.G300aE00b6{j}.G300aE00b8;
                end
                if isfield(json.G300aE00b0{i}.G300aE00b6{j}, 'G300aE00ba')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .BeamLimitingDeviceSequence.(sprintf('Item_%i', j))...
                        .SourceToBeamLimitingDeviceDistance = ...
                        json.G300aE00b0{i}.G300aE00b6{j}.G300aE00ba;
                end
                if isfield(json.G300aE00b0{i}.G300aE00b6{j}, 'G300aE00bc')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .BeamLimitingDeviceSequence.(sprintf('Item_%i', j))...
                        .NumberOfLeafJawPairs = ...
                        json.G300aE00b0{i}.G300aE00b6{j}.G300aE00bc;
                end
            end
        end

        if isfield(json.G300aE00b0{i}, 'G300aE00c0')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).BeamNumber = ...
                json.G300aE00b0{i}.G300aE00c0;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00c2')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).BeamName = ...
                json.G300aE00b0{i}.G300aE00c2;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00c4')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).BeamType = ...
                json.G300aE00b0{i}.G300aE00c4;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00c6')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).RadiationType = ...
                json.G300aE00b0{i}.G300aE00c6;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00ce')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).TreatmentDeliveryType = ...
                json.G300aE00b0{i}.G300aE00ce;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00d0')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).NumberOfWedges = ...
                json.G300aE00b0{i}.G300aE00d0;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00e0')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).NumberOfCompensators = ...
                json.G300aE00b0{i}.G300aE00e0;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00ed')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).NumberOfBoli = ...
                json.G300aE00b0{i}.G300aE00ed;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE00f0')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).NumberOfBlocks = ...
                json.G300aE00b0{i}.G300aE00f0;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE010e')
            rtplan.BeamSequence.(sprintf('Item_%i', i))...
                .FinalCumulativeMetersetWeight = json.G300aE00b0{i}.G300aE010e;
        end
        if isfield(json.G300aE00b0{i}, 'G300aE0110')
            rtplan.BeamSequence.(sprintf('Item_%i', i)).NumberOfControlPoints = ...
                json.G300aE00b0{i}.G300aE0110;
        end

        % Add number of control points to counter
        if isfield(json.G300aE00b0{i}, 'G300aE0111')
            cp = cp + length(json.G300aE00b0{i}.G300aE0111);
        end

        % Store control point sequences
        if isfield(json.G300aE00b0{i}, 'G300aE0111')
            for j = 1:length(json.G300aE00b0{i}.G300aE0111)

                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0112')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .ControlPointIndex = json.G300aE00b0{i}...
                        .G300aE0111{j}.G300aE0112;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0114')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .NominalBeamEnergy = json.G300aE00b0{i}...
                        .G300aE0111{j}.G300aE0114;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0115')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .DoseRateSet = json.G300aE00b0{i}...
                        .G300aE0111{j}.G300aE0115;
                end

                % Store beam limiting device sequences
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE011a')
                    for k = 1:length(json.G300aE00b0{i}.G300aE0111{j}...
                            .G300aE011a)

                        if isfield(json.G300aE00b0{i}.G300aE0111{j}...
                                .G300aE011a{k}, 'G300aE00b8')
                            rtplan.BeamSequence.(sprintf('Item_%i', i))...
                                .ControlPointSequence.(sprintf('Item_%i', j))...
                                .BeamLimitingDevicePositionSequence...
                                .(sprintf('Item_%i', k))...
                                .RTBeamLimitingDeviceType = ...
                                json.G300aE00b0{i}.G300aE0111{j}...
                                .G300aE011a{k}.G300aE00b8;
                        end
                        if isfield(json.G300aE00b0{i}.G300aE0111{j}...
                                .G300aE011a{k}, 'G300aE011c')
                            rtplan.BeamSequence.(sprintf('Item_%i', i))...
                                .ControlPointSequence...
                                .(sprintf('Item_%i', j))...
                                .BeamLimitingDevicePositionSequence...
                                .(sprintf('Item_%i', k)).LeafJawPositions = ...
                                json.G300aE00b0{i}.G300aE0111{j}...
                                .G300aE011a{k}.G300aE011c;
                        end
                    end
                end

                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE011e')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .GantryAngle = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE011e;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE011f')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .GantryRotationDirection = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE011f;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0120')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .BeamLimitingDeviceAngle = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0120;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0121')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .BeamLimitingDeviceRotationDirection = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0121;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0122')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .PatientSupportAngle = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0122;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0123')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .PatientSupportRotationDirection = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0123;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0125')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .TableTopEccentricAngle = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0125;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0126')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .TableTopEccentricRotationDirection = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0126;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0128')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .TableTopVerticalPosition = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0128;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0129')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .TableTopLongitudinalPosition = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0129;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE012a')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .TableTopLateralPosition = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE012a;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE012c')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .IsocenterPosition = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE012c;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0130')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .SourceToSurfaceDistance = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0130;
                end
                if isfield(json.G300aE00b0{i}.G300aE0111{j}, 'G300aE0134')
                    rtplan.BeamSequence.(sprintf('Item_%i', i))...
                        .ControlPointSequence.(sprintf('Item_%i', j))...
                        .CumulativeMetersetWeight = ...
                        json.G300aE00b0{i}.G300aE0111{j}.G300aE0134;
                end
            end
        end

        if isfield(json.G300aE00b0{i}, 'G300cE006a')
            rtplan.BeamSequence.(sprintf('Item_%i', i))...
                .ReferencedPatientSetupNumber = ...
                json.G300aE00b0{i}.G300cE006a;
        end
    end
end
    
% Store patient setup sequences
if isfield(json, 'G300aE0180')
    for i = 1:length(json.G300aE0180)
        if isfield(json.G300aE0180{i}, 'G300aE0182')
            rtplan.PatientSetupSequence.(sprintf('Item_%i', i))...
                .PatientPosition = json.G300aE0180{i}.G300aE0182;
        end
        if isfield(json.G300aE0180{i}, 'G0018E5100')
            rtplan.PatientSetupSequence.(sprintf('Item_%i', i))...
                .PatientSetupNumber = json.G300aE0180{i}.G0018E5100;
        end
    end
end

% Store referenced structure set sequences
if isfield(json, 'G300aE0180')
    for i = 1:length(json.G300cE0060)    
        if isfield(json.G300cE0060{i}, 'G0008E1150')
            rtplan.ReferencedStructureSetSequence.(sprintf('Item_%i', i))...
                .ReferencedSOPClassUID = json.G300cE0060{i}.G0008E1150;
        end
        if isfield(json.G300cE0060{i}, 'G0008E1155')
            rtplan.ReferencedStructureSetSequence.(sprintf('Item_%i', i))...
                .ReferencedSOPInstanceUID = json.G300cE0060{i}.G0008E1155;
        end
    end
end

% Store approval status
if isfield(json, 'G300eE0002')
    rtplan.ApprovalStatus = json.G300eE0002;
end

%% Finish up
% Report success
if exist('Event', 'file') == 2
    Event(sprintf(['Plan data loaded successfully with %i beams and %i', ...
        ' control points in %0.3f seconds'], length(json.G300aE00b0), ...
        cp, toc));
end

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end
