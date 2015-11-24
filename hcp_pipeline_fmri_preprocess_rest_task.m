%%% HCP preprocessing pipeline
% Script to run a preprocessing pipeline analysis on the HCP database.
%
% Copyright (c) Pierre Bellec, Yassine Benhajali
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2010-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI, FIR, clustering, BASC
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

clear all
%% Setting input/output files 
[status,cmdout] = system ('uname -n');
server          = strtrim(cmdout);
if strfind(server,'lg-1r') % This is guillimin
    root_path = '/gs/project/gsf-624-aa/HCP/';
    path_raw  = [ root_path '/HCP_raw_mnc/'];
    fprintf ('server: %s (Guillimin) \n ',server)
    my_user_name = getenv('USER');
elseif strfind(server,'ip05') % this is mammouth
    root_path = '/mnt/parallel_scratch_ms2_wipe_on_april_2015/pbellec/benhajal/HCP/';
    path_raw = [root_path 'HCP_unproc_tmp/'];
    fprintf ('server: %s (Mammouth) \n',server)
    my_user_name = getenv('USER');
else
    switch server
        case 'peuplier' % this is peuplier
        root_path = '/media/scratch2/HCP_unproc_tmp/';
        path_raw = [root_path 'HCP_unproc_tmp/'];
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');
        
        case 'noisetier' % this is noisetier
        root_path = '/media/database1/';
        path_raw = [root_path 'HCP_unproc_tmp/'];
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% WARNING: Do not use underscores '_' in the IDs of subject, sessions or runs. This may cause bugs in subsequent pipelines.

%% Grab the raw data


list_subject = dir(path_raw);
list_subject = {list_subject.name};
list_subject = list_subject(~ismember(list_subject,{'.','..','logs_conversion'}));
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    id = ['HCP' subject];
    files_in.(id).anat = [ path_raw subject '/MPR_1/anat_' subject '_MPR1.mnc.gz']; % Structural scan
    files_in.(id).fmri.sess1.rest1RL = [ path_raw subject '/REST1/func_' subject '_REST1_rl.mnc.gz']; 
    files_in.(id).fmri.sess1.rest1LR = [ path_raw subject '/REST1/func_' subject '_REST1_lr.mnc.gz']; 
    files_in.(id).fmri.sess1.wmRL = [ path_raw subject '/WM/func_' subject '_WM_rl.mnc.gz']; 
    files_in.(id).fmri.sess1.wmLR = [ path_raw subject '/WM/func_' subject '_WM_lr.mnc.gz']; 
    files_in.(id).fmri.sess1.gambRL = [ path_raw subject '/GAMBLING/func_' subject '_GAMBLING_rl.mnc.gz']; 
    files_in.(id).fmri.sess1.gambLR = [ path_raw subject '/GAMBLING/func_' subject '_GAMBLING_lr.mnc.gz'];
    files_in.(id).fmri.sess1.motRL = [ path_raw subject '/MOTOR/func_' subject '_MOTOR_rl.mnc.gz']; 
    files_in.(id).fmri.sess1.motLR = [ path_raw subject '/MOTOR/func_' subject '_MOTOR_rl.mnc.gz']; 

    files_in.(id).fmri.sess2.rest2LR = [ path_raw subject '/REST2/func_' subject '_REST2_lr.mnc.gz']; 
    files_in.(id).fmri.sess2.rest2RL = [ path_raw subject '/REST2/func_' subject '_REST2_rl.mnc.gz'];
    files_in.(id).fmri.sess2.langRL = [ path_raw subject '/LANGUAGE/func_' subject '_LANGUAGE_rl.mnc.gz'];   
    files_in.(id).fmri.sess2.langLR = [ path_raw subject '/LANGUAGE/func_' subject '_LANGUAGE_lr.mnc.gz'];
    files_in.(id).fmri.sess2.socRL = [ path_raw subject '/SOCIAL/func_' subject '_SOCIAL_rl.mnc.gz'];  
    files_in.(id).fmri.sess2.socLR = [ path_raw subject '/SOCIAL/func_' subject '_SOCIAL_lr.mnc.gz'];
    files_in.(id).fmri.sess2.relRL = [ path_raw subject '/RELATIONAL/func_' subject '_RELATIONAL_rl.mnc.gz'];   
    files_in.(id).fmri.sess2.relLR = [ path_raw subject '/RELATIONAL/func_' subject '_RELATIONAL_lr.mnc.gz'];
    files_in.(id).fmri.sess2.emRL = [ path_raw subject '/EMOTION/func_' subject '_EMOTION_rl.mnc.gz'];      
    files_in.(id).fmri.sess2.emLR = [ path_raw subject '/EMOTION/func_' subject '_EMOTION_lr.mnc.gz'];
   
    
    list_session = fieldnames(files_in.(id).fmri);
    flag_ok_stack = [];
    for num_sess = 1:length(list_session) % Sessions
        session = list_session{num_sess};
        list_run = fieldnames(files_in.(id).fmri.(session));
        eval( [ 'flag_ok_' session ' = true(length( list_run ),1);']);
        for num_f = 1:length(list_run) % Runs
            run = list_run{num_f};
            if ~psom_exist(files_in.(id).fmri.(session).(run))
               eval( [ 'flag_ok_' session '(num_f ) = false;' ]);
            end        
        end
        flag_ok_stack = [flag_ok_stack ; eval( [ 'flag_ok_' session ])];
    end
    flag_ok = flag_ok_stack;
    if ~any(flag_ok)||~psom_exist(files_in.(id).anat)
       if ~any(flag_ok)
          warning('No functional data for subject %s, I suppressed it',subject);
       else
          warning ('The anat file %s does not exist, I suppressed that subject %s',files_in.(id).anat,subject);
       end
       files_in = rmfield(files_in,id);
    elseif any(~flag_ok)
       for num_sess = 1:length(list_session) 
           session = list_session{num_sess};
           flag_ok_tmp = eval( [ 'flag_ok_' session ';']);
           list_run = fieldnames(files_in.(id).fmri.(session));
           if ~any(~flag_ok_tmp)
              continue
           else    
              list_run = fieldnames(files_in.(id).fmri.(session));
              files_in.(id).fmri.(session) = rmfield(files_in.(id).fmri.(session),list_run(~flag_ok_tmp));
              warning ('I suppressed the following runs for subject %s because the files were missing:',id);
              list_not_ok = find(~flag_ok_tmp);
              for ind_not_ok = list_not_ok(:)'
                  fprintf(' %s',list_run{ind_not_ok});
              end
              fprintf('\n')
           end    
       end
    end    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/116120/unprocessed/3T/tfMRI_MOTOR_RL/116120_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 116120
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/126931/unprocessed/3T/tfMRI_MOTOR_RL/126931_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 126931
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/128329/unprocessed/3T/tfMRI_MOTOR_LR/128329_3T_tfMRI_MOTOR_LR.mnc.gz does not exist, I suppressed subject 128329
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/129432/unprocessed/3T/tfMRI_MOTOR_RL/129432_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 129432
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/129533/unprocessed/3T/tfMRI_MOTOR_RL/129533_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 129533
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/131621/unprocessed/3T/tfMRI_MOTOR_RL/131621_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 131621
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/140420/unprocessed/3T/tfMRI_MOTOR_RL/140420_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 140420
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/143527/unprocessed/3T/tfMRI_MOTOR_RL/143527_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 143527
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/197449/unprocessed/3T/tfMRI_MOTOR_RL/197449_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 197449                                                                                                        
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/197651/unprocessed/3T/tfMRI_MOTOR_RL/197651_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 197651                                                                                                        
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/207628/unprocessed/3T/tfMRI_MOTOR_RL/207628_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 207628                                                                                                        
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/208428/unprocessed/3T/tfMRI_MOTOR_RL/208428_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 208428
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/650746/unprocessed/3T/tfMRI_MOTOR_RL/650746_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 650746
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/745555/unprocessed/3T/tfMRI_MOTOR_RL/745555_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 745555
%  warning: The file /sb/project/gsf-624-aa/database/HCP/HCP_task_unproc_mnc/782157/unprocessed/3T/tfMRI_MOTOR_RL/782157_3T_tfMRI_MOTOR_RL.mnc.gz does not exist, I suppressed subject 782157
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

%% General
opt.folder_out  = [root_path 'fmri_preprocess_all_task_rest'];    % Where to store the results
opt.size_output = 'quality_control';                             % The amount of outputs that are generated by the pipeline. 'all' will keep intermediate outputs, 'quality_control' will only keep the quality control outputs.


%% Slice timing correction (niak_brick_slice_timing)
opt.slice_timing.type_acquisition = 'interleaved ascending'; % Slice timing order (available options : 'sequential ascending', 'sequential descending', 'interleaved ascending', 'interleaved descending')
opt.slice_timing.type_scanner     = 'Siemens';                % Scanner manufacturer. Only the value 'Siemens' will actually have an impact
opt.slice_timing.delay_in_tr      = 0;                       % The delay in TR ("blank" time between two volumes)
opt.slice_timing.suppress_vol     = 0;                       % Number of dummy scans to suppress.
opt.slice_timing.flag_nu_correct  = 1;                       % Apply a correction for non-uniformities on the EPI volumes (1: on, 0: of). This is particularly important for 32-channels coil.
opt.slice_timing.arg_nu_correct   = '-distance 200';         % The distance between control points for non-uniformity correction (in mm, lower values can capture faster varying slow spatial drifts).
opt.slice_timing.flag_center      = 0;                       % Set the origin of the volume at the center of mass of a brain mask. This is useful only if the voxel-to-world transformation from the DICOM header has somehow been damaged. This needs to be assessed on the raw images.
opt.slice_timing.flag_skip        = 0;                       % Skip the slice timing (0: don't skip, 1 : skip). Note that only the slice timing corretion portion is skipped, not all other effects such as FLAG_CENTER or FLAG_NU_CORRECT
 
% Motion estimation (niak_pipeline_motion)
opt.motion.session_ref  = 'sess1'; % The session that is used as a reference. In general, use the session including the acqusition of the T1 scan.

% resampling in stereotaxic space
opt.resample_vol.interpolation = 'trilinear'; % The resampling scheme. The fastest and most robust method is trilinear. 
opt.resample_vol.voxel_size    = [3 3 3];     % The voxel size to use in the stereotaxic space
opt.resample_vol.flag_skip     = 0;           % Skip resampling (data will stay in native functional space after slice timing/motion correction) (0: don't skip, 1 : skip)

% Linear and non-linear fit of the anatomical image in the stereotaxic
% space (niak_brick_t1_preprocess)
opt.t1_preprocess.nu_correct.arg = '-distance 75'; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 75 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% Temporal filtering (niak_brick_time_filter)
opt.time_filter.hp = 0.01; % Cut-off frequency for high-pass filtering, or removal of low frequencies (in Hz). A cut-off of -Inf will result in no high-pass filtering.
opt.time_filter.lp = Inf;  % Cut-off frequency for low-pass filtering, or removal of high frequencies (in Hz). A cut-off of Inf will result in no low-pass filtering.

% Regression of confounds and scrubbing (niak_brick_regress_confounds)
opt.regress_confounds.flag_wm            = true;            % Turn on/off the regression of the average white matter signal (true: apply / false : don't apply)
opt.regress_confounds.flag_vent          = true;          % Turn on/off the regression of the average of the ventricles (true: apply / false : don't apply)
opt.regress_confounds.flag_motion_params = true; % Turn on/off the regression of the motion parameters (true: apply / false : don't apply)
opt.regress_confounds.flag_gsc           = false;          % Turn on/off the regression of the PCA-based estimation of the global signal (true: apply / false : don't apply)
opt.regress_confounds.flag_scrubbing     = true;     % Turn on/off the scrubbing of time frames with excessive motion (true: apply / false : don't apply)
opt.regress_confounds.thre_fd            = 0.5;             % The threshold on frame displacement that is used to determine frames with excessive motion in the scrubbing procedure

% Correction of physiological noise (niak_pipeline_corsica)
opt.corsica.sica.nb_comp = 60;    % Number of components estimated during the ICA. 20 is a minimal number, 60 was used in the validation of CORSICA.
opt.corsica.threshold    = 0.15;  % This threshold has been calibrated on a validation database as providing good sensitivity with excellent specificity.
opt.corsica.flag_skip    = 1;     % Skip CORSICA (0: don't skip, 1 : skip). Even if it is skipped, ICA results will be generated for quality-control purposes. The method is not currently considered to be stable enough for production unless it is manually supervised.

% Spatial smoothing (niak_brick_smooth_vol)
opt.smooth_vol.fwhm      = 6;  % Full-width at maximum (FWHM) of the Gaussian blurring kernel, in mm.
opt.smooth_vol.flag_skip = 0;  % Skip spatial smoothing (0: don't skip, 1 : skip)

% how to specify a different parameter for two subjects (here subject1 and subject2)
  opt.tune(1).subject = 'HCP165840';
  opt.tune(1).param.t1_preprocess.nu_correct.arg ='-distance 50' ; % Anything that usually goes in opt can go in param. What's specified in opt applies by default, but is overridden by tune.param
%  
%  opt.tune(2).subject = 'subject2';
%  opt.tune(2).param.slice_timing.flag_center = false; % Anything that usually goes in opt can go in param. What's specified in opt applies by default, but is overridden by tune.param

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess pipeline  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false;
[pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt);

%% extra
%copy Eprime varaibles for each subject to the preprocessing output folder
%%%for num_e = 1:length(list_subject)
%%%    subject = list_subject{num_e};
%%%    id = ['HCP' subject];
%%%    system([' mkdir -p ' opt.folder_out filesep 'EVs' filesep id filesep 'lr']);
%%%    system([' mkdir -p ' opt.folder_out filesep 'EVs' filesep id filesep 'rl']);
%%%    system(['rsync -a ' path_raw subject '/unprocessed/3T/tfMRI_' task '_LR/LINKED_DATA/EPRIME/EVs/ ' opt.folder_out filesep 'EVs' filesep id filesep 'lr/']); 
%%%    system(['rsync -a ' path_raw subject '/unprocessed/3T/tfMRI_' task '_RL/LINKED_DATA/EPRIME/EVs/ ' opt.folder_out filesep 'EVs' filesep id filesep 'rl/']); 
%%%end
% make a copy of this script to output folder
system(['cp ' mfilename('fullpath') '.m ' opt.folder_out '.']);
