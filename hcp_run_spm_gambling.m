% Script to run spm maps for gamb task

% Grab fmri files
root_path = '/gs/project/gsf-624-aa/HCP/';
opt_grab.type_files = 'roi';
opt_grab.exclude_subject = {'HCP142626'};
opt_grab.filter.run = {'gambRL','gambLR'};
opt_grab.min_nb_vol = 100;
files_grab = niak_grab_fmri_preprocess([root_path 'fmri_preprocess_all_tasks_niak-fix-scrub_900R'], opt_grab);
files_in.fmri =  files_grab.fmri;
files_in.mask = '/gs/project/gsf-624-aa/HCP/fmri_preprocess_all_tasks_niak-fix-scrub_900R/quality_control/group_coregistration/func_mask_group_stereonl.mnc.gz';
% grab individul onset files
list_subj=fieldnames(files_in.fmri);
for ss=1:length(list_subj)
    subject = list_subj{ss};
    list_run = fieldnames(files_in.fmri.(subject).sess1);
    for rr=1:length(list_run)
        subj_run = list_run{rr};
        switch subj_run
               case 'gambLR'
                   subj_onset = [root_path filesep 'fmri_preprocess_all_tasks_niak-fix-scrub_900R/EVs' filesep subject filesep 'GAMBLING_LR/GAMBLING_LR_spm_onset.csv' ];
               case 'gambRL'
                   subj_onset = [root_path filesep 'fmri_preprocess_all_tasks_niak-fix-scrub_900R/EVs' filesep subject filesep 'GAMBLING_RL/GAMBLING_RL_spm_onset.csv' ];
        end
        if ~exist(subj_onset)
           warning('Subject %s run %s has no Onset file, this run will be discarded',subject,subj_run)
           files_in.fmri.(subject).sess1 = rmfield(files_in.fmri.(subject).sess1,subj_run);
        else
        files_in.onset.(subject).sess1.(subj_run) = subj_onset;
        end
    end
    if ~isfield( files_in.fmri.(subject).sess1,'gambLR') && ~isfield( files_in.fmri.(subject).sess1,'gambRL')
       warning('Subject %s is discarded, has no onset for both runs',subject)
       files_in.fmri = rmfield(files_in.fmri,subject);
    end
end
% set pipeline options
list_event = {['all_bk_cor','2bk_faces','0bk_body','0bk_faces','2bk_places','0bk_places','2bk_body','0bk_tools','2bk_tools']};
opt.folder_out = [root_path 'hcp_gamb_activation_maps_' date];
for ee = 1: length(list_event)
  opt.fmridesign.list_event = list_event(ee);
  [pipeline,opt] = hcp_pipeline_activation_maps(files_in,opt);
end
