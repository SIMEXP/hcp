clear all
%set path
path_root = '/home/yassinebha/Google_Drive/HCP/Solar_heritability/twins_permute_exp/';
cd(path_root);
%load pdigree and pheno
%system(sprintf('solar <<INTERNAL_SOLAR_SCRIPT \nload pedi %spedigree_clean.csv \nINTERNAL_SOLAR_SCRIPT',path_root))
pheno = niak_read_csv_cell([path_root '/../phenotypes.csv' ]);

%Generate ID permutaion table (1000 permatation)
IDs = pheno(2:end,1);
perm_IDs = {};
for pp = 1:1000
    rand('state',pp);
    order = randperm(length(IDs));
    perm_IDs_tmp = IDs(order',:);
    pheno(2:end,1)= perm_IDs_tmp;
    pheno_tmp = [ pheno(:,1:6)   pheno(:,32:36)];
    niak_write_csv_cell([path_root 'phenotypes.csv'],pheno_tmp);
    system(sprintf('solar <<INTERNAL_SOLAR_SCRIPT \nload pedi %spedigree_clean.csv \nINTERNAL_SOLAR_SCRIPT',path_root))
    system(sprintf('solar <<INTERNAL_SOLAR_SCRIPT \nload pheno %sphenotypes.csv \nINTERNAL_SOLAR_SCRIPT',path_root));
    system(['bash fcd_solar_h2r.sh trait_file perm_test' num2str(pp)]);
    system(['for i in perm_test' num2str(pp) '/Set-*; do bash $i/run_all.sh ; done']);
    system(['mv ' path_root 'perm_test' num2str(pp) '/se_out.out ' path_root 'se_out' num2str(pp) '.out']);
end

pheno_raw = pheno(2:end,32);
pheno_perm = {};
header_stack = {};
for hh = 1:10
      rand('state',hh);
      order = randperm(length(pheno_raw));
      pheno_perm_tmp = pheno_raw (order',:);
      pheno_perm = [ pheno_perm pheno_perm_tmp];
      header_name = ['trait_' num2str(hh)];
      header_stack = [header_stack  header_name];
end

pheno_final = [header_stack ; pheno_perm];
pheno_final = [ pheno(:,1)  pheno_final ];


      
      niak_write_csv_cell([path_root 'phenotypes.csv'],pheno_tmp);  



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
                      

    