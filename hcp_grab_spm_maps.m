function files = hcp_grab_spm_maps(path_data,opt)
% Grab the outputs of HCP_PIPELINE_ACTIVATION_MAPS
%
% SYNTAX:
% FILES_OUT = HCP_GRAB_SPM_MAPS( PATH_DATA, OPT )
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of
%   NIAK_CONNECTOME
%
% OPT
%   (structure) with the following fields :
%
%   RUN_NAME
%      (string, Default "all_runs" ) The run name to be grabed
%       WARNING: 'run_name' is the folder name containing the run to be grabbed
%
%  LIST_TRIAL
%      (string, Default "" ) The trial names to be grabed
%      If empty all trial will be grabbed
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

%% option
opt = psom_struct_defaults( opt , ...
    { 'run_name' ,'list_trial'}, ...
    {  'all_runs',''          });

if (nargin<2) && isempty(path_data)
    path_data = [pwd filesep];
end

if nargin<=2
    files = struct();
end

path_data = niak_full_path(path_data);
run_name = opt.run_name;

%% Initialize the files
list_subject = dir([path_data 'spm_maps']);
list_subject = {list_subject.name};
list_subject = list_subject(~ismember(list_subject,{'.','..','logs_conversion'}));

%% Grab SPM-maps
path_spm = [path_data 'spm_maps'];
if psom_exist(path_spm)
    % Parse trial IDs
    if isempty(opt.list_trial)
        list_trial = dir([path_spm filesep  list_subject{1} filesep run_name]);
        list_trial = {list_trial.name};
        list_trial = list_trial(~ismember(list_trial,{'.','..','logs_conversion'}));
    else
      list_trial = opt.list_trial;
    end
    for ff = 1:length(list_trial)
        [~,name_trial,ext_trial] = niak_fileparts(list_trial{ff});
        name_trial = name_trial(5:end);
        for ss = 1:length(list_subject)
            subject = list_subject{ss};
            spm_file_name = [path_spm filesep subject filesep  run_name filesep 'spm_' name_trial ext_trial];
            if exist(spm_file_name)
               files.spm_map.(name_trial).(subject) = [path_spm filesep subject filesep run_name filesep 'spm_' name_trial ext_trial];
            else
               fprintf('warning : Subject %s has no data for trial %s \n',subject,name_trial)
               continue
            end
        end
    end
else
    warning ('I could not find the spm_maps subfolder')
end

% Grab the roi mask
files.roi_mask = [GB_NIAK.path_template filesep 'roi_aal' ext_trial];
