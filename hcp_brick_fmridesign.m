function [in,out,opt] = hcp_brick_fmridesign(in,out,opt)
% Generate activation map form fmri data
%
% SYNTAX: [IN,OUT,OPT] = HCP_BRICK_FMRIDESIGN(IN,OUT,OPT)
%
% IN.FMRI (string) the file name of a 4D volume

% IN.ONSET (string, default '') a csv onset file
%
% OUT (string, default [pwd]) The full path for output file map.
%
% OPT.GLM_TEST (string, default 'ttest') The type of glm test to implement.
%
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but
%    update IN, OUT and OPT.
%
% Copyright (c) Pierre Bellec, Yassine Benhajalil
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization, montage, 3D brain volumes

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

%% Defaults
in = psom_struct_defaults( in , ...
    { 'fmri' , 'onset'}, ...
    {  NaN    , NaN });

% Outputs
if (nargin < 2) || isempty(out)
    out = pwd;
end
folder_out = niak_full_path(out);

opt = psom_struct_defaults ( opt , ...
  {  'glm_test' , 'flag_test' }, ...
  {  'ttest'    , false         });

if opt.flag_test
    return
end


%% Red the onset file
file_onset = in.onset;
[tab,lx,ly] = niak_read_csv(file_onset);

%% Reorganize the onsets using numerical IDs for the conditions
[list_event,tmp,all_event]  = unique(lx);
opt_m.events = [all_event(:) tab];

%% Now read an fMRI dataset
[hdr,vol] = niak_read_vol(in.fmri);
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
opt_glm.test = opt.glm_test;
opt_glm.flag_rsquare = true;

for ee = 1:length(list_event)
    glm.c = zeros(1,size(glm.x,2));
    glm.c(2+(ee-1)*2) = 1;
    glm.c(3+(ee-1)*2) = 0;

    %% Run the GLM
    res = niak_glm(glm,opt_glm);
    %niak_montage (niak_tseries2vol(res.ftest(:)',mask),opt_v)
    hdr.file_name = [folder_out filesep 'spm_' list_event{ee} '.mnc.gz'];
    niak_write_vol(hdr,niak_tseries2vol(res.eff(:)',mask));
end
