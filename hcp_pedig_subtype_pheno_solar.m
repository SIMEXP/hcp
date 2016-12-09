% A non generic script to prepare pedigree and pheno variable for solar eclipse

% load variables 
path_root = '/home/yassinebha/Drive/HCP/subtypes_scores/26-10-2016/';
path_subtype = [path_root 'subtype_MOTOR_RL_20161202/'];
subt_weight = load([path_subtype 'subtype_weights.mat']);
pheno_mot_rl  = niak_read_csv_cell([path_root 'pheno/motor_RL_pheno_scrub_raw.csv']);

##################################
####### Build pheno file #########
##################################

%% Select a subset variable of interest including subject ID's
list_pheno  = {'Subject','Age_in_Yrs','Gender','Handedness','BMI','FD','FD_scrubbed'};
mask_pheno  = ismember(pheno_mot_rl(1,:),list_pheno);
pheno_mot_rl_subset = pheno_mot_rl(:,mask_pheno);

%% Merge pheno with weight_mat 
cell_subt_weight = num2cell(subt_weight.weight_mat);
% Reshape 3d weigth to 2D
cell_subt_weight_2d = reshape(cell_subt_weight,length(cell_subt_weight),size(cell_subt_weight)(2)*size(cell_subt_weight)(3));
% Concatenate ID'S with Weight
cell_subt_weight_ID_2d = [ subt_weight.list_subject cell_subt_weight_2d ];
% Merge weight with pheno cell 
pheno_weight_merge = merge_cell_tab(cell_subt_weight_ID_2d,pheno_mot_rl_subset);

#################################
######Build pedigree table#######
#################################


% Build pedigree table
pedigree = [concat_weight_sex_FD(:,1) concat_weight_sex_FD(:,4) concat_weight_sex_FD(:,4) concat_weight_sex_FD(:,43) concat_weight_sex_FD(:,2) concat_weight_sex_FD(:,4)];
pedigree_header = {'ID','fa','mo','sex','mztwin','hhID'};
pedigree_tab = pedigree(2:end,:);
for pp = 1:length(pedigree_tab)
    pedigree_tab(pp,2)=['fa_' pedigree_tab{pp,2}];%add prefix "fa" for father ID
    pedigree_tab(pp,3)=['mo_' pedigree_tab{pp,3}];%add prefix "mo" for mother ID
    if strcmp(pedigree_tab{pp,5}, 'MZ') 
       pedigree_tab(pp,5)=['pair_' pedigree_tab{pp,6}];%add prefix "pair" if MZ twins, and empty if not
    else
       pedigree_tab(pp,5)={''};
    end
    pedigree_tab(pp,6)=['hh_' pedigree_tab{pp,6}];%add prefix "hh" household ID
end
pedegree_clean = [pedigree_header ;  pedigree_tab];
niak_write_csv_cell('/home/yassinebha/Google_Drive/HCP/Solar_heritability/pedegree.csv',pedegree_clean);
