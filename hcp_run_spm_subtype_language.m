% Template to write a script for the NIAK subtyping pipeline
%
% To run a demo of the subtyping, please see
% NIAK_DEMO_SUBTYPE.
%
% Copyright (c) Pierre Bellec, Sebastian Urchs, Angela Tam
%   Montreal Neurological Institute, McGill University, 2008-2016.
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Qubec, Canada, 2010-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, clustering, pipeline

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

%% Setting input/output server
[status,cmdout] = system ('uname -n');
server          = strtrim(cmdout);
if strfind(server,'lg-1r') % This is guillimin
    path_root = '/gs/project/gsf-624-aa/HCP/';#guillimin
    fprintf ('server: %s (Guillimin) \n ',server)
    my_user_name = getenv('USER');
elseif strfind(server,'stark') % this is stark
    path_root = '/home/yassinebha/data/HCP/';#stark
    fprintf ('server: %s \n',server)
    my_user_name = getenv('USER');
else
    switch server
        case 'magma' % this is magma
        path_root = '/home/yassinebha/data/HCP/'
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');

        case 'noisetier' % this is noisetier
        path_root ='/media/yassinebha/database26/Drive/HCP/';
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');
    end
end


##### BUILD PHENO FILE #####

### Clean Pheno file ###

file_pheno = [path_root 'pheno/hcp_all_pheno.csv'];
pheno_raw  = niak_read_csv_cell (file_pheno);

## Select pheno
list_pheno  = {'Age_in_Yrs','Twin_Stat','Zygosity','Mother_ID','Father_ID','Handedness','Gender','ReadEng_Unadj','PicVocab_Unadj','ListSort_Unadj','BMI'};
mask_pheno  = ismember(pheno_raw(1,:),list_pheno);
pheno_clean = pheno_raw(:,mask_pheno);
# Add the Subject IDs colomn
pheno_clean = [pheno_raw(:,ismember(pheno_raw(1,:),'Subject'))(:,1) pheno_clean];

## Grab spm maps
path_spm = [path_root 'hcp_language_story_activation_maps_22-Feb-2017'];
opt_spm.run_name = 'all_runs';
files_spm = hcp_grab_spm_maps(path_spm,opt_spm);
files_in.data = files_spm.spm_map;

## Clean pheno according to files_in
list_subject = fieldnames(files_in.data.(fieldnames(files_in.data){1}));
mask_id_stack = zeros(length(pheno_clean)-1,1);
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    mask_id = ismember(pheno_clean(2:end,1),subject(4:end));
    if sum(mask_id) == 0
       warning(sprintf('subject %s has no entry in the csv model',subject))
       continue
    elseif  sum(mask_id) == 1
       mask_id_stack = mask_id_stack + mask_id;
    else
       error('subject %s has more than one entry',subject)
    end
end
mask_id_stack= [1;mask_id_stack]; # Put header on the mask

# extract correspondind subjects only
pheno_clean_final = pheno_clean(logical(mask_id_stack),:);


##### MERGE PHENO FILE WITH SCRUBBING #####

## Merge the scrubbing to pheno_clean_final
file_scrub = [path_root 'fmri_preprocess_all_tasks_niak-fix-scrub_900R/quality_control/group_motion/qc_scrubbing_group_language.csv'];
scrub_raw = niak_read_csv_cell (file_scrub);

# Select IDs, FD and FD scrubbed for a specific run
list_scrub = {'','FD_mean','FD_scrubbed_mean'};
mask_scrub  = ismember(scrub_raw(1,:),list_scrub);
scrub_clean = scrub_raw(:,mask_scrub);

# keep only matching task name
for ii = 2:length(scrub_clean)
    scrub_clean(ii,1)=scrub_clean{ii,1}(4:end);
end

# Merge
merge_pheno_scrub = merge_cell_tab(pheno_clean_final,scrub_clean);

# remove extra subject id colomn
merge_pheno_scrub = merge_pheno_scrub(:,~ismember(merge_pheno_scrub(1,:),''));

# add HCP prefix to the subejects ID
merge_pheno_scrub(2:end,1) = strcat('HCP',merge_pheno_scrub(2:end,1));

# Save pheno_scrub_raw
niak_write_csv_cell([path_root 'pheno/spm_language_pheno_scrub_raw_' date '.csv'],merge_pheno_scrub);

##### PREPARE MODEL FILE #####
# recode gender to M=1 F=2
index = strfind(merge_pheno_scrub(1,:),'Gender');
index = find(~cellfun(@isempty,index));
merge_pheno_scrub(:,index) = strrep (merge_pheno_scrub(:,index),'M','1');
merge_pheno_scrub(:,index) = strrep (merge_pheno_scrub(:,index),'F','2');

# convert the values into a series of numerical covariates
list_id = merge_pheno_scrub(2:end,1);
labels_y = {'Subject','Age_in_Yrs','Handedness','Gender','ReadEng_Unadj','PicVocab_Unadj','ListSort_Unadj','BMI','FD_scrubbed_mean'};
mask_model  = ismember(merge_pheno_scrub(1,:),labels_y);
model_clean = merge_pheno_scrub(:,mask_model);
tab_model_clean = str2double(model_clean(2:end,2:end));

# save final model file
opt_csv.labels_x = list_id; # Labels for the rows
opt_csv.labels_y = model_clean(1,2:end);
path_model_final = [path_root 'pheno/model_spm_language_' date '.csv'];
niak_write_csv(path_model_final,tab_model_clean,opt_csv);

##### PIPELINE OPTIONS ######

# Brain mask
## Resample the mask
in_mask.source = files_spm.roi_mask;
trial_tmp = fieldnames(files_spm.spm_map){1};
subj_tmp = fieldnames(files_spm.spm_map.(trial_tmp)){1};
in_mask.target = files_spm.spm_map.(trial_tmp).(subj_tmp);
out_mask = [path_spm filesep 'mask_roi_resample.mnc.gz'];
opt_mask.interpolation = 'nearest_neighbour';
niak_brick_resample_vol(in_mask,out_mask,opt_mask);
files_in.mask = out_mask;

# Model
files_in.model = path_model_final;

# Confound regression
opt.stack.regress_conf = {'FD_scrubbed_mean'};     % a list of varaible names to be regressed out

# Subtyping
list_subtype = {5};
for ll = 1: length(list_subtype)
    opt.subtype.nb_subtype = list_subtype{ll};       % the number of subtypes to extract
    opt.subtype.sub_map_type = 'mean';        % the model for the subtype maps (options are 'mean' or 'median')

    # General
    opt.folder_out = [path_root 'subtype_' num2str(opt.subtype.nb_subtype) '_spm_LANGUAGE_' date];


    ## ReadEng_Unadj Association test
    # GLM options
    opt.association.ReadEng_Unadj.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
    opt.association.ReadEng_Unadj.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
    opt.association.ReadEng_Unadj.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
    opt.association.ReadEng_Unadj.flag_intercept = true;                % turn on/off adding a constant covariate to the model

    # Test a main effect of  ReadEng_Unadjfactors
    opt.association.ReadEng_Unadj.contrast.ReadEng_Unadj = 1;    % scalar number for the weight of the variable in the contrast
    opt.association.ReadEng_Unadj.contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ReadEng_Unadj.contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ReadEng_Unadj.contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ReadEng_Unadj.contrast.Handedness = 0;               % scalar number for the weight of the variable in the contrast

    # Visualization
    opt.association.ReadEng_Unadj.type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')


    ## PicVocab_Unadj Association test
    # GLM options
    opt.association.PicVocab_Unadj.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
    opt.association.PicVocab_Unadj.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
    opt.association.PicVocab_Unadj.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
    opt.association.PicVocab_Unadj.flag_intercept = true;                % turn on/off adding a constant covariate to the model

    # Test a main effect of  PicVocab_Unadjfactors
    opt.association.PicVocab_Unadj.contrast.PicVocab_Unadj = 1;    % scalar number for the weight of the variable in the contrast
    opt.association.PicVocab_Unadj.contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.PicVocab_Unadj.contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.PicVocab_Unadj.contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.PicVocab_Unadj.contrast.Handedness = 0;               % scalar number for the weight of the variable in the contrast

    # Visualization
    opt.association.PicVocab_Unadj.type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')


    ## ListSort_Unadj Association test
    # GLM options
    opt.association.ListSort_Unadj.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
    opt.association.ListSort_Unadj.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
    opt.association.ListSort_Unadj.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
    opt.association.ListSort_Unadj.flag_intercept = true;                % turn on/off adding a constant covariate to the model

    # Test a main effect of  ListSort_Unadjfactors
    opt.association.ListSort_Unadj.contrast.ListSort_Unadj = 1;    % scalar number for the weight of the variable in the contrast
    opt.association.ListSort_Unadj.contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ListSort_Unadj.contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ListSort_Unadj.contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.ListSort_Unadj.contrast.Handedness = 0;               % scalar number for the weight of the variable in the contrast

    # Visualization
    opt.association.ListSort_Unadj.type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')


    ## BMI Association test
    # GLM options
    opt.association.BMI.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
    opt.association.BMI.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
    opt.association.BMI.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
    opt.association.BMI.flag_intercept = true;                % turn on/off adding a constant covariate to the model

    # Test a main effect of  BMIfactors
    opt.association.BMI.contrast.BMI = 1;    % scalar number for the weight of the variable in the contrast
    opt.association.BMI.contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.BMI.contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.BMI.contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.BMI.contrast.Handedness = 0;               % scalar number for the weight of the variable in the contrast

    # Visualization
    opt.association.BMI.type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')


    ## Handedness Association test
    # GLM options
    opt.association.Handedness.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
    opt.association.Handedness.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
    opt.association.Handedness.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
    opt.association.Handedness.flag_intercept = true;                % turn on/off adding a constant covariate to the model

    # Test a main effect of  Handednessfactors
    opt.association.Handedness.contrast.Handedness = 1;    % scalar number for the weight of the variable in the contrast
    opt.association.Handedness.contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.Handedness.contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
    opt.association.Handedness.contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast

    # Visualization
    opt.association.Handedness.type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')


    ##### Run the pipeline  #####
    opt.flag_test =false ;  % Put this flag to true to just generate the pipeline without running it.
    pipeline = niak_pipeline_subtype(files_in,opt);

    ## Extra
    % make a copy of this script to output folder
    system(['cp ' mfilename('fullpath') '.m ' opt.folder_out '/.']);
end
