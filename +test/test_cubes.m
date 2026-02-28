function test_cubes()
%TARIFFWAR.TEST.TEST_CUBES  Test cube computation.

    fprintf('\n    Testing cube construction from prebuilt data... ');
    d = tariffwar.io.load_data('wiod', 2014);
    N = d.N;  S = d.S;
    Xjik_3D = d.Xjik_3D;

    % Compute derived cubes
    [lambda, Yi3D, Ri3D, e_ik3D] = ...
        tariffwar.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);

    % Check lambda is valid trade shares
    lambda_sums = squeeze(sum(lambda, 1));
    assert(all(abs(lambda_sums(:) - 1) < 1e-10 | lambda_sums(:) == 0), ...
        'Lambda column sums should be 1');
    fprintf('OK\n');

    fprintf('    Testing expenditure shares... ');
    e_sums = squeeze(sum(e_ik3D(1,:,:), 3));
    assert(all(abs(e_sums - 1) < 1e-10), 'Expenditure shares should sum to 1');
    fprintf('OK\n');

    fprintf('    Testing sigma cube... ');
    sigma = tariffwar.elasticity.get_sigma_cube('lashkaripour_2021', 'wiod', N, S);
    assert(all(sigma(:) > 0), 'All sigma should be positive');
    fprintf('OK\n');
end
