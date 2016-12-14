% Script to run spm maps for motor task

% Grab fmri files
root_path = '/gs/project/gsf-624-aa/HCP/';
opt_grab.type_files = 'roi';
opt_grab.exclude_subject = {'HCP142626','HCP12802'};
opt_grab.filter.run = {'motRL'};
opt_grab.min_nb_vol = 100;
files_grab = niak_grab_fmri_preprocess([root_path 'fmri_preprocess_all_tasks_niak-fix-scrub_900R'], opt_grab);
files_in.fmri =  files_grab.fmri;
files_in.onset = '/sb/home/yassinebha/hcp_motor_RL_onset.csv'
% set pipeline options
opt.folder_out = [root_path 'activation_maps'];
[pipeline,opt] = hcp_pipeline_activation_maps(files_in,opt);
