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
list_fields   = { 'contrast_trial' , 'fmridesign' , 'psom'   , 'folder_out' ,  'flag_test' };
list_defaults = { {}               , struct()     , struct() , NaN          ,  false       };
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
	      jopt = opt.fmridesign;
        jopt.folder_out = [folder_out 'spm_maps' filesep subject filesep 'all_runs' ];
        pipeline = psom_add_job(pipeline,name_job,'hcp_brick_fmridesign',in,struct,jopt);
        flag_multirun.(subject) = true;
        % contrast trials
        if ~isempty(opt.contrast_trial)
          list_event =  fieldnames(pipeline.(['spm_' subject '_all_runs']).files_out);
          if any(~prod(ismember(opt.contrast_trial,list_event)))
             list_wrong_contrast = opt.contrast_trial(~ismember(opt.contrast_trial,opt.fmridesign.list_event))
             error('wrong contrast name %s\n',list_wrong_contrast{})
          end

          for cc  = 1:size(opt.contrast_trial)(1)
              trial1 = opt.contrast_trial{cc,1};
              trial2 = opt.contrast_trial{cc,2};
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_all_runs']).files_in.vol1 = ...
              pipeline.(['spm_' subject '_all_runs']).files_out.(trial1);
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_all_runs']).files_in.vol2 = ...
              pipeline.(['spm_' subject '_all_runs']).files_out.(trial2);
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_all_runs']).files_out = ...
              [folder_out 'spm_maps' filesep subject filesep 'all_runs' filesep ...
              'spm_contrast_' trial1 '_vs_' trial2 '.nii.gz'];
              command =  '[hdr,vol1] = niak_read_vol(files_in.vol1);[hdr,vol2] = niak_read_vol(files_in.vol2);hdr.file_name = files_out ; niak_write_vol(hdr,vol1-vol2);';
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_all_runs']).command = command;
          end
        end
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
        jopt = opt.fmridesign;
	      jopt.folder_out = [folder_out 'spm_maps' filesep subject filesep run_name ];
        pipeline = psom_add_job(pipeline,name_job,'hcp_brick_fmridesign',in,struct,jopt);

        % contrast trials
        if ~isempty(opt.contrast_trial)
          list_event =  fieldnames(pipeline.(['spm_' subject '_' run_name]).files_out);
          if any(~prod(ismember(opt.contrast_trial,list_event)))
             list_wrong_contrast = opt.contrast_trial(~ismember(opt.contrast_trial,opt.fmridesign.list_event))
             error('wrong contrast name %s\n',list_wrong_contrast{})
          end
          for cc = 1:size(opt.contrast_trial)(1)
              trial1 = opt.contrast_trial{cc,1};
              trial2 = opt.contrast_trial{cc,2};
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_' run_name]).files_in.vol1 = ...
              pipeline.(['spm_' subject '_' run_name]).files_out.(trial1);
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_' run_name]).files_in.vol2 = ...
              pipeline.(['spm_' subject '_' run_name]).files_out.(trial2);
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_' run_name]).files_out = ...
              [folder_out 'spm_maps' filesep subject filesep run_name filesep ...
              'spm_contrast_' trial1 '_vs_' trial2 '_' run_name '.nii.gz'];
              command =  '[hdr,vol1] = niak_read_vol(files_in.vol1);[hdr,vol2] = niak_read_vol(files_in.vol2);hdr.file_name = files_out ; niak_write_vol(hdr,vol1-vol2);';
              pipeline.(['contrast_' subject '_' trial1 '_vs_' trial2 '_' run_name]).command = command;
          end
        end
    end
end

% group t-maps for each trial
trial_list = fieldnames(pipeline.(sprintf('spm_%s_%s',list_subject{1},list_run{1})).files_out);
for num_trial = 1:length(trial_list)
    trial = trial_list{num_trial};
    clear in out jopt
    name_job = sprintf('spm_%s_group_map',trial);
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
    out = [folder_out filesep 'group_maps' filesep trial '.nii.gz' ];
    jopt.flag_verbose = true;
    pipeline = psom_add_job(pipeline,name_job,'hcp_brick_group_spm',in,out,jopt);
end


% group t-maps for contrast maps
for tt = 1:size(opt.contrast_trial)(1)
    trial1 = opt.contrast_trial{tt,1};
    trial2 = opt.contrast_trial{tt,2};
    trial = [trial1 '_vs_' trial2];
    clear in out jopt
    name_job = sprintf('spm_%s_group_map',trial);
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        list_session = fieldnames(files_in.fmri.(subject));
        session_name = list_session{1};
        if flag_multirun.(subject)
           name_job_in =['contrast_' subject '_' trial1 '_vs_' trial2 '_all_runs'];
        else
           list_run = fieldnames(files_in.fmri.(subject).(session_name));
           name_job_in = ['contrast_' subject '_' trial1 '_vs_' trial2 '_' list_run{1}];
        end
        in.spm.(subject)  = pipeline.(name_job_in).files_out;
    end
    in.mask = files_in.mask;
    out = [folder_out filesep 'group_maps' filesep trial '.nii.gz' ];
    jopt.flag_verbose = true;
    pipeline = psom_add_job(pipeline,name_job,'hcp_brick_group_spm',in,out,jopt);
end


%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
