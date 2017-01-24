function [pipeline,opt] = hcp_pipeline_activation_maps(files_in,opt)
% Generation of generate activation maps from HCP fMRI dataset
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_ACTIVATION_MAPS(FILES_IN,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN
%   (structure) with the following fields :
%
%   FMRI.<SUBJECT>.<SESSION>.<RUN>
%      (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> and <RUN> can be
%      any arbitrary string.
%
%   MASK
%       (string) path to mask of the voxels that will be included in the
%       time*space array
%
%   ONSET.<SUBJECT>.<SESSION>.<RUN>
%      (string, default 'gb_niak_omitted') a .csv file coding for the time of events.
%        onset. Exemple:
%
%                     , start , duration , repetition
%        'TRIAL_1'    , 12    , 7        , 1
%        'TRIAL_2'    , 45    , 3        , 2
% OPT
%   (structure) with the following fields :
%
%   FMRIDESIGN
%      (structure) see the OPT argument of NIAK_BRICK_FMRIDESIGN.
%
%   FOLDER_OUT
%      (string) where to write the results of the pipeline.
%
%   PSOM
%      (structure, optional) the options of the pipeline manager. See the
%      OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%      (boolean, default false) If FLAG_TEST is true, the pipeline will
%      just produce a pipeline structure, and will not actually process
%      the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%      data.
%
% _________________________________________________________________________
% OUTPUTS :
%
% PIPELINE
%   (structure) describe all jobs that need to be performed in the
%   pipeline. This structure is meant to be use in the function
%   PSOM_RUN_PIPELINE.
%
% OPT
%   (structure) same as input, but updated for default values.
%
% _________________________________________________________________________
%
%
%% Checking that FILES_IN is in the correct format
list_fields   = { 'fmri' , 'onset'  ,'mask'};
list_defaults = { NaN       , NaN   , NaN  };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
list_fields   = {  'fmridesign' , 'psom'   , 'folder_out' ,  'flag_test' };
list_defaults = {  struct()     , struct() , NaN          ,  false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

% list subject
list_subject = fieldnames(files_in.fmri);
%loop over subject and create spm maps jobs
pipeline = struct();
for num_s = 1:length(list_subject)
    clear in out jopt
    subject = list_subject{num_s};
    list_session = fieldnames(files_in.fmri.(subject));
    % Session
    session_name = list_session{1};
    list_run = fieldnames(files_in.fmri.(subject).(session_name));
    if length(list_run) > 1
        % spm maps for all runs
        name_job = sprintf('spm_%s_all_runs',subject);
        in.fmri  = struct2cell(files_in.fmri.(subject).(session_name));
        in.onset = struct2cell(files_in.onset.(subject).(session_name));
        jopt.folder_out = [folder_out 'spm_maps' filesep subject filesep 'all_runs' ];
        pipeline = psom_add_job(pipeline,name_job,'hcp_brick_fmridesign',in,struct,jopt);
        flag_multirun.(subject) = true;
    elseif length(list_run)== 1
        flag_multirun.(subject) = false;
    end
    % spm maps for each Run
    for num_run=1:length(list_run)
        clear in out jopt
        run_name = list_run{num_run};
        name_job = sprintf('spm_%s_%s',subject,run_name);
        in.fmri  = files_in.fmri.(subject).(session_name).(run_name);
        in.onset = files_in.onset.(subject).(session_name).(run_name);
        jopt.folder_out = [folder_out 'spm_maps' filesep subject filesep run_name ];
        pipeline = psom_add_job(pipeline,name_job,'hcp_brick_fmridesign',in,struct,jopt);
    end
end

% Mean t-maps for each trial
trial_list = fieldnames(pipeline.(sprintf('spm_%s_%s',list_subject{1},list_run{1})).files_out);
for num_trial = 1:length(trial_list)
    trial = trial_list{num_trial};
    clear in out jopt
    name_job = sprintf('spm_%s_all_runs',trial);
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        list_session = fieldnames(files_in.fmri.(subject));
        session_name = list_session{1};
        if flag_multirun.(subject)
           name_job_in = sprintf('spm_%s_all_runs',subject);
        else
           list_run = fieldnames(files_in.fmri.(subject).(session_name));
           name_job_in = sprintf('spm_%s_%s',subject,list_run{1});
        end
        in.spm.(subject)  = pipeline.(name_job_in).files_out.(trial);
    end
    in.mask = files_in.mask;
    out = [folder_out 'spm_maps' filesep 'mean_maps' filesep trial '.mnc.gz' ];
    jopt.flag_verbose = true;
    pipeline = psom_add_job(pipeline,name_job,'hcp_brick_mean_spm',in,struct,jopt);
end

%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
