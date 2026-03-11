function LoadLibraries()
ornotFolderPath = fileparts(mfilename("fullpath"));
addpath(fullfile(ornotFolderPath, "../"));
addpath(fullfile(ornotFolderPath, "../../out/"));
addpath(fullfile(ornotFolderPath, "../../submodules/ogl_beamforming/out/"));
addpath(fullfile(ornotFolderPath, "../../submodules/ogl_beamforming/out/matlab"));
% NOTE: these warnings do not provide useful information and are not at
% all relevant to the functioning of the library.
warning('off','MATLAB:structOnObject');
warning('off','MATLAB:loadlibrary:TypeNotFoundForStructure');
if (~libisloaded('ogl_beamformer_lib'))
    [~, ~] = loadlibrary('ogl_beamformer_lib');
    api = calllib('ogl_beamformer_lib', 'beamformer_get_api_version');
    fprintf("Loading Ogl Beamformer Library Version %d \n", api);
    calllib('ogl_beamformer_lib', 'beamformer_set_global_timeout', 1000);
    % TODO: attempt to open the shared memory region,
    % and if it fails reload the library and try again
end
if (~libisloaded('ornot'))
    [~, ~] = loadlibrary('ornot', 'ornot.h');
end
end