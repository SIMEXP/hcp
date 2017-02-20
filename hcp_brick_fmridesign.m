function [in,out,opt] = hcp_brick_fmridesign(in,out,opt)
% Generate activation map form fmri data
%
% SYNTAX: [IN,OUT,OPT] = HCP_BRICK_FMRIDESIGN(IN,OUT,OPT)
%
% IN.FMRI (string or cell of strings) the file name of a 4D volume
% IN.ONSET (string or cell of strings, default '') a csv onset file
%
% OUT (string, default [pwd]) The full path for output file map.
%
% OPT.LIST_EVENT (string, default '') The list of conditions to include in the
%    model. By default, include them all. 
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

if ischar(in.fmri)
    in.fmri = {in.fmri};
end

if ischar(in.onset) 
    in.onset = {in.onset};
end

if length(in.onset)==1
    in.onset = repmat(in.onset,[length(in.fmri) 1]);
end

if length(in.fmri)~=length(in.onset)
    error('IN.FMRI should have as many entries as IN.ONSET')
end

%% Options
opt = psom_struct_defaults ( opt , ...
  {  'folder_out' , 'list_event' , 'glm_test' , 'flag_verbose' , 'flag_test' }, ...
  {  pwd          , {}           , 'ttest'    , true           , false         });
folder_out = niak_full_path(opt.folder_out);

%% Read the onset file
file_onset = in.onset{1};
[tab,lx,ly] = niak_read_csv(file_onset);

%% Reorganize the onsets using numerical IDs for the conditions
[list_event_all,tmp,all_event]  = unique(lx);
if isempty(opt.list_event)
    list_event = list_event_all;
else
    if any(~ismember(opt.list_event,list_event_all))
        error('Some of the listed events are not found in the event file');
    end
    list_event = opt.list_event;
end

opt_m.events = [all_event(:) tab];

%% Outputs
if (nargin < 2) || isempty(out) || isempty(fieldnames(out))
    out = struct;
    for ee = 1:length(list_event)
        out.(list_event{ee}) = [folder_out filesep 'spm_' list_event{ee} '.mnc.gz'];
    end
end

%% If it's a test, just finish here
if opt.flag_test
    return
end

%% Loop over runs
for rr = 1:length(in.fmri)
    if (rr>1)
        if opt.flag_verbose
            fprintf('Read the onset file %s ...\n',in.onset{rr});
        end
        [tab,lx,ly] = niak_read_csv(in.onset{rr});
        %% Reorganize the onsets using numerical IDs for the conditions
        [list_event_all,tmp,all_event]  = unique(lx);
        opt_m.events = [all_event(:) tab];
    end
    
    %% Now read an fMRI dataset
    if opt.flag_verbose
        fprintf('Read an fMRI volume %s...\n',in.fmri{rr})
    end
    [hdr,vol] = niak_read_vol(in.fmri{rr});
    if rr == 1
        mask = niak_mask_brain(vol);
    end
    tseries = niak_vol2tseries(vol,mask);
    tseries = tseries(~hdr.extra.mask_scrubbing,:);
    tseries = niak_normalize_tseries(tseries,'perc');
    if rr == 1
        glm.y = tseries;
    else
        glm.y = [glm.y ; tseries];
    end
    
    %% Build the model
    if opt.flag_verbose
        fprintf('Generate the model...\n')
    end
    opt_m.frame_times = hdr.extra.time_frames;
    x_cache =  niak_fmridesign(opt_m);
    reg = ones(size(vol,4),1);
    for ee = 1:length(list_event)
        reg = [reg x_cache.x(:,ee,1) x_cache.x(:,ee,2)];
    end
    reg = reg(~hdr.extra.mask_scrubbing,:);
    if rr == 1
        glm.x = reg;
    else 
        glm.x = [glm.x ; reg];
    end
end

%% Loop on the maps
if opt.flag_verbose
    fprintf('Estimate the model and save the maps...\n')
end
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
    hdr.file_name = out.(list_event{ee});
    if opt.flag_verbose
       fprintf('    %s\n',out.(list_event{ee}))
    end
    niak_write_vol(hdr,niak_tseries2vol(res.eff(:)',mask));
end
