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
path_root = '/home/yassinebha/database/HCP/';
file_pheno = [path_root 'pheno/hcp_pheno_emotion.csv'];
[TAB,LABELS_X,LABELS_Y,LABELS_ID] = niak_read_csv(file_pheno);


## Grab spm maps
path_spm = [path_root 'hcp_emotion_activation_maps_17-Jun-2017'];
opt_spm.run_name = 'all_runs';
files_spm = hcp_grab_spm_maps(path_spm,opt_spm);
files_in.data = files_spm.spm_map;

## Clean pheno according to files_in
list_subject = fieldnames(files_in.data.(fieldnames(files_in.data){1}));
mask_id_stack = zeros(length(LABELS_X),1);
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    mask_id = ismember(LABELS_X,subject);
    if sum(mask_id) == 0
       warning(sprintf('subject %s has no entry in the csv model',subject))
       continue
    elseif  sum(mask_id) == 1
       mask_id_stack = mask_id_stack + mask_id;
    else
       error('subject %s has more than one entry',subject)
    end
end

# extract correspondind subjects only
TAB_clean = TAB(logical(mask_id_stack),:);
LABELS_X_clean = LABELS_X(logical(mask_id_stack),:);

# save the clean model to file
opt_csv.labels_x = LABELS_X_clean;
opt_csv.labels_y = LABELS_Y;
opt_csv.labels_id = LABELS_ID;
path_model_clean = [path_root 'pheno/model_spm_emotion_' date '.csv'];
niak_write_csv(path_model_clean,TAB_clean,opt_csv);

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
files_in.model = path_model_clean;

# Confound regression
opt.stack.regress_conf = {'FD_scrubbed_mean','BPSystolic','BPDiastolic','BMI'};     % a list of varaible names to be regressed out

# Subtyping
list_subtype = {5};
# number of phenotypic clusters
clust_match = regexp(LABELS_Y,'Cluster_*');
count = 0 ;
for ii=1:length (clust_match)
  if isempty (clust_match{ii})
    continue
  else
    count = count +1;
  end
end
num_cluster = count;

for ll = 1: length(list_subtype)
    opt.subtype.nb_subtype = list_subtype{ll};       % the number of subtypes to extract
    opt.subtype.sub_map_type = 'mean';        % the model for the subtype maps (options are 'mean' or 'median')

    # General
    opt.folder_out = [path_root 'subtype_' num2str(opt.subtype.nb_subtype) '_spm_EMOTION_' date];

    ## clusters Association test
    for cc = 1:num_cluster
        cluster = sprintf('Cluster_%s',num2str(cc));
        # GLM options
        opt.association.(cluster).fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
        opt.association.(cluster).normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
        opt.association.(cluster).normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
        opt.association.(cluster).flag_intercept = true;                % turn on/off adding a constant covariate to the model

        # Test a main effect of (cluster) factors
        opt.association.(cluster).contrast.(cluster) = 1;    % scalar number for the weight of the variable in the contrast
        opt.association.(cluster).contrast.FD_scrubbed_mean = 0;               % scalar number for the weight of the variable in the contrast
        opt.association.(cluster).contrast.Age_in_Yrs = 0;               % scalar number for the weight of the variable in the contrast
        opt.association.(cluster).contrast.Gender = 0;               % scalar number for the weight of the variable in the contrast

        # Visualization
        opt.association.(cluster).type_visu = 'continuous';  % type of data for visulization (options are 'continuous' or 'categorical')
    end
    ##### Run the pipeline  #####
    opt.flag_test =false ;  % Put this flag to true to just generate the pipeline without running it.
    pipeline = niak_pipeline_subtype(files_in,opt);
end
## Extra
% make a copy of this script to output folder
system(['cp ' mfilename('fullpath') '.m ' opt.folder_out '/.']);
