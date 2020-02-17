function [x,f] = spm_dcm_x_neural(P,model)
% Returns the state and equation of neural mass models
% FORMAT [x,f] = spm_dcm_x_neural(P,'model')
%
%  P      - parameter structure
% 'model'   - 'ERP','SEP','CMC','LFP','CMM','NNM', 'MFM' or 'CMM NMDA'
%
% x   - initial states
% f   - state euquation
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_x_neural.m 5732 2013-11-06 14:03:56Z rosalyn $



% initial state and equation
%--------------------------------------------------------------------------
switch lower(model)
    
    % linear David et al model (linear in states)
    %======================================================================
    case{'erp'}
        
        % inital states and equations of motion
        %------------------------------------------------------------------
        n  = length(P.A{1});                          % number of sources
        m  = 9;                                       % number of states
        x  = sparse(n,m);
        
        f  = 'spm_fx_erp';
        
        
    % linear David et al model (linear in states) - fast version for SEPs
    %======================================================================
    case{'sep'}
        
        % inital states
        %------------------------------------------------------------------
        n  = length(P.A{1});                          % number of sources
        m  = 9;                                       % number of states
        x  = sparse(n,m);
        
        f  = 'spm_fx_sep';
        
    % Linear in states � canonical microcircuit
    %======================================================================
    case{'cmc'}
        
        % inital states
        %------------------------------------------------------------------
        n  = length(P.A{1});                          % number of sources
        m  = 8;                                       % number of states
        x  = sparse(n,m);
        
        f  = 'spm_fx_cmc';
        
    % linear David et al model (linear in states) - with self-inhibition
    %======================================================================
    case{'lfp'}
        
        % inital states
        %------------------------------------------------------------------
        n  = length(P.A{1});                          % number of sources
        m  = 13;                                      % number of states
        x  = sparse(n,m);
        
        f  = 'spm_fx_lfp';
        
        
    % Neural mass model (nonlinear in states)
    %======================================================================
    case{'nmm'}
        
   
        % get initialisation from full mean-field model
        %------------------------------------------------------------------
        x  = spm_x_mfm(P);
        
        % remove dispersion and fix the covariance of the states (Cx)
        %--------------------------------------------------------------------------
        x  = x{1};
        f  = 'spm_fx_mfm';
        
            % Neural mass model (nonlinear in states)
    %======================================================================
    case{'nmda'}
        
   
        % get initialisation from full mean-field model
        %------------------------------------------------------------------
        x  = spm_x_nmda(P);
        
        % remove dispersion and fix the covariance of the states (Cx)
        %--------------------------------------------------------------------------
        x  = x{1};
        f  = 'spm_fx_nmda';
        
    % Canonical mass model (nonlinear in states)
    %======================================================================
    case{'cmm'}
        
        % inital states and model
        %------------------------------------------------------------------
        x  = spm_x_cmm(P);
        f  = 'spm_fx_cmm';
        
  % Canonical mass model with NMDA (nonlinear in states)
    %======================================================================
    case{'cmm_nmda'}
        
        % inital states and model
        %------------------------------------------------------------------
        x  = spm_x_cmm_NMDA(P);
        f  = 'spm_fx_cmm_NMDA';
        
        
    % Mean field model (nonlinear in states) - with covariance
    %======================================================================
    case{'mfm'}
        
        % inital states and model
        %------------------------------------------------------------------
        x  = spm_x_mfm(P);
        f  = 'spm_fx_mfm';
        
        
    otherwise
        warndlg('Unknown model')
end