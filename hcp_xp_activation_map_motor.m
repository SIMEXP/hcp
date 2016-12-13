clear

%% Red the onset file
file_onset = 'subj100307_hcp_motor_RL_onset.csv';
[tab,lx,ly] = niak_read_csv(file_onset);

%% Reorganize the onsets using numerical IDs for the conditions
[list_event,tmp,all_event]  = unique(lx); 
opt_m.events = [all_event(:) tab];
    
%% Now read an fMRI dataset
[hdr,vol] = niak_read_vol('fmri_HCP100307_sess1_motRL.mnc.gz');
mask = niak_mask_brain(vol);
glm.y = niak_vol2tseries(vol,mask);
glm.y = glm.y(~hdr.extra.mask_scrubbing,:);
glm.y = niak_normalize_tseries(glm.y,'perc');

%% Build the model
opt_m.frame_times = hdr.extra.time_frames;
x_cache =  niak_fmridesign(opt_m); 
glm.x = ones(size(vol,4),1);
for ee = 1:length(list_event)
    glm.x = [glm.x x_cache.x(:,ee,1) x_cache.x(:,ee,2)];
end
glm.x = glm.x(~hdr.extra.mask_scrubbing,:);

%% Loop on the maps
opt_glm = struct;
opt_glm.test = 'ttest';
opt_glm.flag_rsquare = true;
    
for ee = 1:length(list_event)
    glm.c = zeros(1,size(glm.x,2));
    glm.c(2+(ee-1)*2) = 1;
    glm.c(3+(ee-1)*2) = 0;
    
    %% Run the GLM 
    res = niak_glm(glm,opt_glm);
    %niak_montage (niak_tseries2vol(res.ftest(:)',mask),opt_v)
    hdr.file_name = ['spm_' list_event{ee} '.mnc.gz'];
    niak_write_vol(hdr,niak_tseries2vol(res.eff(:)',mask));
end
