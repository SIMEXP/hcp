function [in,out,opt] = hcp_brick_mean_spm(in,out,opt)
% Generate mean activation map form t-maps
%
% SYNTAX: [IN,OUT,OPT] = HCP_BRICK_FMRIDESIGN(IN,OUT,OPT)
%
% IN.SPM.(SUBJECT) (string or cell of strings) the file name of a 3D tmaps
% IN.MASK (string or cell of strings) the file name of a 3D mask
%
% OUT (string, default [pwd]) The full path and name for output file map.
%
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but
%    update IN, OUT and OPT.
%
% OPT.FLAG_VERBOSE
%      (boolean, default true) Print some advancement infos.
%
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
% FILES IN
in = psom_struct_defaults( in , ...
    { 'spm' , 'mask'}, ...
    {  NaN    , NaN });

% FILES OUT
if ~ischar(out)
    error('OUT should be a string')
end

% OPTIONS
list_fields      = { 'flag_test'    , 'flag_verbose' };
list_defaults    = { false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% If it's a test, just finish here
if opt.flag_test == 1
    return
end

% The brick starts here
% Read the mask
[~,mask]= niak_read_vol(in.mask);
list_subject = fieldnames(in.spm);
if opt.flag_verbose
   fprintf('Read and stack volumes of %i subjects ...\n',length(list_subject));
end
x = zeros(length(list_subject),size(mask(mask(:) > 0)));

% Read and stack all volumes
for ss = 1 : length(list_subject)
    subject = list_subject{ss};
    if opt.flag_verbose
        fprintf('Read an fMRI volume %s...\n',subject);
    end
    [hdr,vol]= niak_read_vol(in.spm.(subject));
    x(ss,:) = vol(mask > 0)';
end
ttest_x = niak_ttest(x);

% Save final tmap
if opt.flag_verbose
   fprintf('Save ttest maps %s ...\n',out);
end
hdr.file_name = out;
niak_write_vol(hdr,niak_tseries2vol(ttest_x(:)',mask));
