function sigma_k3D = get_sigma_cube(source_name, dataset_name, N, S, varargin)
%TARIFFWAR.ELASTICITY.GET_SIGMA_CUBE  Build NxNxS sigma cube for a named source.
%
%   sigma_k3D = tariffwar.elasticity.get_sigma_cube(source_name, dataset_name, N, S)
%
%   Returns an N x N x S array of CES parameters sigma_k = epsilon_k + 1.
%
%   See also: tariffwar.elasticity.get

    % Get epsilon vector at dataset's sector resolution
    epsilon_S = tariffwar.elasticity.get(source_name, dataset_name, S);

    % Transform: sigma = epsilon + 1
    sigma_S = epsilon_S + 1;

    % Expand to N x N x S cube
    sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);
end
