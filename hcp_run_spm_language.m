% Script to run spm maps for motor task

% Grab fmri files
root_path = '/gs/project/gsf-624-aa/HCP/';
opt_grab.type_files = 'roi';
opt_grab.exclude_subject = {'HCP142626'};
opt_grab.filter.run = {'langRL','langLR'};
opt_grab.min_nb_vol = 100;
files_grab = niak_grab_fmri_preprocess([root_path 'fmri_preprocess_all_tasks_niak-fix-scrub_900R'], opt_grab);
files_in.fmri =  files_grab.fmri;

% grab individul onset files
list_subj=fieldnames(files_in.fmri);
for ss=1:length(list_subj)
    subject = list_subj{ss};
    list_run = fieldnames(files_in.fmri.(subject).sess2);
    for rr=1:length(list_run)
        subj_run = list_run{rr};
        switch subj_run
               case 'langLR'
                   subj_onset = [root_path filesep 'fmri_preprocess_all_tasks_niak-fix-scrub_900R/EVs' filesep subject filesep 'LANGUAGE_LR/LANGUAGE_LR_spm_onset.csv' ];
               case 'langRL'
                   subj_onset = [root_path filesep 'fmri_preprocess_all_tasks_niak-fix-scrub_900R/EVs' filesep subject filesep 'LANGUAGE_RL/LANGUAGE_RL_spm_onset.csv' ];
        end
        if ~exist(subj_onset)
           warning('Subject %s run %s has no Onset file, this run will be discarded',subject,subj_run)
           files_in.fmri.(subject).sess2 = rmfield(files_in.fmri.(subject).sess2,subj_run);
        else
        files_in.onset.(subject).sess2.(subj_run) = subj_onset;
        end
    end 
    if ~isfield( files_in.fmri.(subject).sess2,'langLR') && ~isfield( files_in.fmri.(subject).sess2,'langRL')
       warning('Subject %s is discarded, has no onset for both runs',subject)
       files_in.fmri = rmfield(files_in.fmri,subject);
    end
end
% set pipeline options
opt.folder_out = [root_path 'hcp_language_activation_maps_' date];
[pipeline,opt] = hcp_pipeline_activation_maps(files_in,opt);