clear all
%set path
path_root = '/home/yassinebha/Google_Drive/HCP/Solar_heritability/twins_permute_exp/';
cd(path_root);
%load pdigree and pheno
system(sprintf('solar <<INTERNAL_SOLAR_SCRIPT \nload pedi %spedigree_clean.csv \nINTERNAL_SOLAR_SCRIPT',path_root))
pheno = niak_read_csv_cell([path_root 'phenotypes.csv' ]);

%Generate ID permutaion table (1000 permatation)
IDs = pheno(2:end,1);
perm_IDs = {};
for pp = 1:3
    rand('state',pp);
    order = randperm(length(IDs));
    perm_IDs_tmp = IDs(order',:);
    pheno(2:end,1)= perm_IDs_tmp;
    niak_write_csv_cell([path_root 'phenotypes.csv'],pheno);
    system(['bash fcd_solar_h2r.sh trait_file perm_test' num2str(pp)]);
    system(['for i in perm_test' num2str(pp) '/Set-*; do bash $i/run_all.sh ; done']);
    system(['cp -r ' path_root 'perm_test' num2str(pp) '/se_out.out ' path_root 'se_out' num2str(pp) '.out']);
end

    %loop over permuted ID
          %select random non significant pheno from (sub2_net3)
          %build pheno_tmp(i)
          %build pedig_tmp(i)
          % in solar:
                          %read pedig_tmp(i)
                          %read pheno_tmp(i)
                          %run solar for output_tmp(i)
          %grab output_tmp(i)
          %cocncat result in a varable   
    %end loop

%save resuts in csv file 
                      

    