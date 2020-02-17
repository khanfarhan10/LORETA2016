function D = spm_eeg_correct_sensor_data(S)
% Function for removing artefacts from the data based on their topography
% FORMAT D = spm_eeg_correct_sensor_data(S)
%
% S                    - input structure (optional)
% (optional) fields of S:
%   S.D                - MEEG object or filename of M/EEG mat-file
%   S.method           - 'SSP' - simple projection
%                      - 'Berg' - the method of Berg (see the reference below)
% Output:
% D                   - MEEG object (also written on disk)
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
%
% Disclaimer: this code is provided as an example and is not guaranteed to work
% with data on which it was not tested. If it does not work for you, feel
% free to improve it and contribute your improvements to the MEEGtools toolbox
% in SPM (http://www.fil.ion.ucl.ac.uk/spm)
%
% Implements:
%   Berg P, Scherg M.
%   A multiple source approach to the correction of eye artifacts.
%   Electroencephalogr Clin Neurophysiol. 1994 Mar;90(3):229-41.
%
% Vladimir Litvak
% $Id: spm_eeg_correct_sensor_data.m 5640 2013-09-18 12:02:29Z vladimir $

SVNrev = '$Rev: 5640 $';

%-Startup
%--------------------------------------------------------------------------
spm('FnBanner', mfilename, SVNrev);
spm('FigName','Correct sensor data');

%-Get MEEG object
%--------------------------------------------------------------------------
try
    D = S.D;
catch
    [D, sts] = spm_select(1, 'mat', 'Select M/EEG mat file');
    if ~sts, D = []; return; end
    S.D = D;
end

D = spm_eeg_load(D);

if ~any(D.sconfounds)
    D = spm_eeg_spatial_confounds(S);
    if ~any(D.sconfounds)
        return;
    end
end

if ~isfield(S, 'correction')
    S.correction = spm_input('Correction method','+1', 'SSP|Berg', strvcat('SSP', 'Berg'));
end

[mod, list] = modality(D, 1, 1);

A = {};
if isequal(mod, 'Multimodal')
    sconf = getfield(D, 'sconfounds');
    
    for i = 1:numel(list)
        chanind = indchantype(D, list{i}, 'GOOD');
        [sel1, sel2] = spm_match_str(chanlabels(D, chanind), sconf.label);
        
        if any(sconf.bad(sel2))
            error(['Channels ' sprintf('%s ', sconf.label{sel2}) ' should be set to bad.']);
        end
        
        A{i} = sconf.coeff(sel2, :);
    end
else
    A = {D.sconfounds};
    list = {mod};
end

Dorig = D;

for i = 1:numel(A)
    label = D.chanlabels(indchantype(D, list{i}, 'GOOD'));
    
    montage = [];
    montage.labelorg = label;
    montage.labelnew = label;
    
    if size(A{i}, 1)~=numel(label)
        error('Spatial confound vector does not match the channels');
    end
    
    if isequal(lower(S.correction), 'berg')
        [D, ok] = check(D, 'sensfid');
        
        if ~ok
            if check(D, 'basic')
                errordlg(['The requested file is not ready for source reconstruction.'...
                    'Use prep to specify sensors and fiducials.']);
            else
                errordlg('The meeg file is corrupt or incomplete');
            end
            return
        end
        
        %% ============ Find or prepare head model
        
        if ~isfield(D, 'val')
            D.val = 1;
        end
        
        if ~isfield(D, 'inv') || ~iscell(D.inv) ||...
                ~(isfield(D.inv{D.val}, 'forward') && isfield(D.inv{D.val}, 'datareg')) ||...
                ~isa(D.inv{D.val}.mesh.tess_ctx, 'char') % detects old version of the struct
            D = spm_eeg_inv_mesh_ui(D, D.val);
            D = spm_eeg_inv_datareg_ui(D, D.val);
            D = spm_eeg_inv_forward_ui(D, D.val);
            
            save(D);
        end
        
        [L, D] = spm_eeg_lgainmat(D, [], label);
        
        B = spm_svd(L*L', 0.1);
        
        lim = min(0.5*size(L, 1), 45); % 45 is the number of dipoles BESA would use.
        
        if size(B, 2) > lim;
            B = B(:, 1:lim);
        end
        
        SX = full([A{i} B]);
        
        SXi = pinv(SX);
        SXi = SXi(1:size(A{i}, 2), :);
        
        montage.tra = eye(size(A{i}, 1)) - A{i}*SXi;
    else
        montage.tra = eye(size(A{i}, 1)) - A{i}*pinv(A{i});
    end    
    
    %% ============  Use the montage functionality to compute source activity.
    S1   = [];
    S1.D = D;
    S1.montage = montage;
    S1.keepothers = 1;
    S1.updatehistory  = 0;
    
    Dnew = spm_eeg_montage(S1); 
    
    if isfield(D,'inv')
        Dnew.inv = D.inv;
    end
    
    if i>1
        delete(D);
    end
    
    D = Dnew;
end

%% ============  Change the channel order to the original order
tra = eye(D.nchannels);
montage = [];
montage.labelorg = D.chanlabels;
montage.labelnew = Dorig.chanlabels;

[sel1, sel2]  = spm_match_str(montage.labelnew, montage.labelorg);

montage.tra = tra(sel2, :);

S1   = [];
S1.D = D;
S1.montage = montage;
S1.keepothers = 0;
S1.updatehistory  = 0;

Dnew = spm_eeg_montage(S1);
delete(D);
D = Dnew;

if ~isempty(badchannels(Dorig))
    D = badchannels(D, badchannels(Dorig), 1);
end

D = D.history(mfilename, S);
save(D);

%-Cleanup
%--------------------------------------------------------------------------
spm('FigName', 'Correct sensor data: done');

