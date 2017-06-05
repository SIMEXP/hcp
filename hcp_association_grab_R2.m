# Grab R-squared from assosiation
clear all
root_path = '/home/yassinebha/Drive/HCP/subtypes_scores/26-10-2016/';
path_association = [root_path 'subtype_5_spm_SOCIAL_mental_23-May-2017/associations/'];
path_networks = [root_path 'subtype_5_spm_SOCIAL_mental_23-May-2017/networks/'];

list_pheno = dir(path_association);
list_pheno = {list_pheno.name};
list_pheno = list_pheno(~ismember(list_pheno,{'.','..'}));

list_trial = dir(path_networks);
list_trial = {list_trial.name};
list_trial = list_trial(~ismember(list_trial,{'.','..'}));

list_subt = {'pheno','sub1','sub2','sub3','sub4','sub5'};
for ii = 1:length(list_trial)
    trial_name = list_trial{ii};
    # build R2 table for radar plot
    pheno_r2_final = {};
    for ff = 1:length(list_pheno)
        pheno_name = list_pheno{ff};
        load([path_association pheno_name filesep 'association_stats_' pheno_name '.mat']);
        pheno_r2 = glm_results.(trial_name).rsquare;
        pheno_r2 = [cellstr(pheno_name) , num2cell(pheno_r2)];
        pheno_r2_final = [ pheno_r2_final ; pheno_r2 ];
    end
    # Header and save first table
    pheno_r2_final = [ list_subt ; pheno_r2_final];
    niak_write_csv_cell([path_association trial_name '_r2.csv' ],pheno_r2_final);

    # build pheno-subtype table for corelation graph
    list_subt_raw = {'ID','sub1','sub2','sub3','sub4','sub5'};
    subtype_id = [model_raw.labels_x , num2cell(model_raw.y)];
    subtype_raw_id = [list_subt_raw ; subtype_id];
    model_raw_final = [model_raw.labels_y' ; num2cell(model_raw.x)];
    combine_pheno_subt = [subtype_raw_id , model_raw_final];
    # Save pheno
    niak_write_csv_cell([path_association trial_name '_pheno_subtype.csv' ],combine_pheno_subt);
end
