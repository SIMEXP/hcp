###### transfert and build hcp task onset ####
## Build files_in

root_path = '/gs/project/gsf-624-aa/HCP/';
path_raw  = [ root_path '/HCP_raw_mnc/'];
folder_out  = [root_path 'fmri_preprocess_all_tasks_niak-fix-scrub_900R'];

list_subject = dir(path_raw);
list_subject = {list_subject.name};
list_subject = list_subject(~ismember(list_subject,{'.','..','logs_conversion'}));
%list_subject = list_subject(1); %preprocess by batches
for num_s = 1:2 %length(list_subject)
    subject = list_subject{num_s};
    id = ['HCP' subject];
    files_in.(id).anat = [ path_raw subject '/MPR_1/anat_' subject '_MPR1.mnc.gz']; % Structural scan
    files_in.(id).fmri.sess1.wmRL = [ path_raw subject '/WM/func_' subject '_WM_rl.mnc.gz']; 
    files_in.(id).fmri.sess1.wmLR = [ path_raw subject '/WM/func_' subject '_WM_lr.mnc.gz'];
    files_in.(id).fmri.sess1.gambRL = [ path_raw subject '/GAMBLING/func_' subject '_GAMBLING_rl.mnc.gz'];
    files_in.(id).fmri.sess1.gambLR = [ path_raw subject '/GAMBLING/func_' subject '_GAMBLING_lr.mnc.gz'];
    files_in.(id).fmri.sess1.motRL = [ path_raw subject '/MOTOR/func_' subject '_MOTOR_rl.mnc.gz'];
    files_in.(id).fmri.sess1.motLR = [ path_raw subject '/MOTOR/func_' subject '_MOTOR_lr.mnc.gz'];

    files_in.(id).fmri.sess2.langRL = [ path_raw subject '/LANGUAGE/func_' subject '_LANGUAGE_rl.mnc.gz'];
    files_in.(id).fmri.sess2.langLR = [ path_raw subject '/LANGUAGE/func_' subject '_LANGUAGE_lr.mnc.gz'];
    files_in.(id).fmri.sess2.socRL = [ path_raw subject '/SOCIAL/func_' subject '_SOCIAL_rl.mnc.gz'];
    files_in.(id).fmri.sess2.socLR = [ path_raw subject '/SOCIAL/func_' subject '_SOCIAL_lr.mnc.gz'];
    files_in.(id).fmri.sess2.relRL = [ path_raw subject '/RELATIONAL/func_' subject '_RELATIONAL_rl.mnc.gz'];
    files_in.(id).fmri.sess2.relLR = [ path_raw subject '/RELATIONAL/func_' subject '_RELATIONAL_lr.mnc.gz'];
    files_in.(id).fmri.sess2.emRL = [ path_raw subject '/EMOTION/func_' subject '_EMOTION_rl.mnc.gz'];
    files_in.(id).fmri.sess2.emLR = [ path_raw subject '/EMOTION/func_' subject '_EMOTION_lr.mnc.gz'];
end
files_in = niak_prune_files_in(files_in);

## copy Eprime onset to fmri preprocess output

for num_e = 1:length(list_subject)
    subject = list_subject{num_e};
    id = ['HCP' subject];
    system(['mkdir -p ' folder_out filesep 'EVs' filesep id filesep 'lr']);
    system(['mkdir -p ' folder_out filesep 'EVs' filesep id filesep 'rl']);
    system(['rsync -a ' path_raw subject '/unprocessed/3T/tfMRI_' task '_LR/LINKED_DATA/EPRIME/EVs/ ' opt.folder_out filesep 'EVs' filesep id filesep 'lr/']);
    system(['rsync -a ' path_raw subject '/unprocessed/3T/tfMRI_' task '_RL/LINKED_DATA/EPRIME/EVs/ ' opt.folder_out filesep 'EVs' filesep id filesep 'rl/']);
end
