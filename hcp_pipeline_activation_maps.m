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
%   FMRI.(SUBJECT).(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> and <RUN> can be
%      any arbitrary string.
%
%   ONSET
%      (string, default 'gb_niak_omitted') the name of a .csv file with a list of
%        onset. % The .csv FILES_IN.SEEDS should take this forms:
%
%                   ,   start ,  duration ,  repetition
%        TRIAL_1    ,  12 ,  7 , 1
%        TRIAL_2    ,  45 , 3 , 2
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
list_fields   = { 'fmri' , 'onset'  };
list_defaults = { NaN       , NaN   };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
list_fields   = {  'fmridesign' , 'psom'   , 'folder_out' ,  'flag_test' };
list_defaults = {  struct()     , struct() , NaN          ,  false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

% Re-organize inputs
[files_tseries,list_subject] = sub_input(files_in);

for num_s = 1:length(list_subject)
    clear in out jopt
    subject = list_subject{num_s};
    name_job = sprintf('connectome_%s',subject);
    in.fmri = files_tseries.(subject);
    in.mask = pipeline.(['mask_' network]).files_out;
    out = [folder_out 'connectomes' filesep 'connectome_' network '_' subject '.mat'];
    jopt = opt.connectome;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_connectome',in,out,jopt);
end

%% Compute the average map for each seed
for num_seed = 1:length(labels_seed)
    seed = labels_seed{num_seed};
    clear in out jopt
    in = list_maps(:,num_seed);
    out = [folder_out 'rmap_seeds' filesep 'average_rmap_' seed ext_f];
    jopt.operation = 'vol = zeros(size(vol_in{1})); for num_m = 1:length(vol_in), vol = vol + vol_in{num_m}; end, vol = vol / length(vol_in);';
    pipeline = psom_add_job(pipeline,['average_rmap_' seed],'niak_brick_math_vol',in,out,jopt);
end




%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end


%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%
function [files_tseries,list_subject] = sub_input(files_in);
files_tseries = files_in.fmri;
list_subject = fieldnames(files_tseries);
for num_s = 1:length(list_subject)
    subject  = list_subject{num_s};
    files_subject = files_tseries.(subject);
    list_session = fieldnames(files_subject);
    nb_data = 1;
    for num_sess = 1:length(list_session)
        list_run = fieldnames(files_subject.(list_session{num_sess}));
        for num_r = 1:length(list_run)
             files_tmp{nb_data} = files_subject.(list_session{num_sess}).(list_run{num_r});
             nb_data = nb_data + 1;
        end
    end
    files_tseries.(subject) = files_tmp;
end
