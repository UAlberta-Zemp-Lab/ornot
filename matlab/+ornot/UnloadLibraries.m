function UnloadLibraries()
warning('on','MATLAB:structOnObject');
warning('on','MATLAB:loadlibrary:TypeNotFoundForStructure');
if (libisloaded('ogl_beamformer_lib'))
    unloadlibrary('ogl_beamformer_lib');
end
if (libisloaded('ornot'))
    unloadlibrary('ornot');
end
end