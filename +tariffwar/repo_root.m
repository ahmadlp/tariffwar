function root = repo_root()
%TARIFFWAR.REPO_ROOT  Absolute path to the repository root.
%
%   root = tariffwar.repo_root()

    root = fileparts(fileparts(mfilename('fullpath')));
end
