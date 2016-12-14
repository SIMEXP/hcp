function files = hcp_grab_spm_maps(path_data)
% Grab the outputs of HCP_PIPELINE_ACTIVATION_MAPS
%
% SYNTAX:
% FILES_OUT = HCP_GRAB_SPM_MAPS( PATH_DATA )
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of
%   NIAK_CONNECTOME
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT
%   (structure) the list of outputs of the CONNECTOME pipeline
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Griatrie de Montral,
%               Dpartement d'informatique et de recherche oprationnelle,
%               Universit de Montral, 2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : grabber

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Default path
niak_gb_vars
if (nargin<1)||isempty(path_data)
    path_data = [pwd filesep];
end

if nargin<2
    files_in = struct();
end

path_data = niak_full_path(path_data);

%% Initialize the files
list_subject = dir([path_data 'spm_maps']);
list_subject = {list_subject.name};
list_subject = list_subject(~ismember(list_subject,{'.','..','logs_conversion'}));
files = struct;

%% Grab SPM-maps
path_spm = [path_data 'spm_maps'];
if psom_exist(path_spm)
    % Parse trial IDs
    list_trial = dir([path_spm filesep file_trial_tmp(1).name ]);
    list_trial = {list_trial.name};
    list_trial = list_trial(~ismember(list_trial,{'.','..','logs_conversion'}));
    for ff = 1:length(list_trial)
        [~,name_trial,ext_trial] = niak_fileparts(list_trial{ff});
        name_trial = name_trial(5:end);
        for ss = 1:length(list_subject)
            files.spm_map.(name_trial).(list_subject{ss}) = [path_spm filesep list_subject{ss} filesep 'spm_' name_trial ext_trial];
        end
        files.mask.(name_trial) = [gb_niak_path_template filesep 'roi_aal' ext_trial];
    end
else
    warning ('I could not find the spm_maps subfolder')
end
