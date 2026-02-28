function test_elasticity()
%TARIFFWAR.TEST.TEST_ELASTICITY  Test elasticity module.

    fprintf('\n    Testing registry... ');
    reg = tariffwar.elasticity.registry();
    assert(numel(reg) >= 8, 'Registry should have at least 8 sources');
    names = {reg.name};
    assert(ismember('lashkaripour_2021', names), 'lashkaripour_2021 should be in registry');
    assert(ismember('uniform_4', names), 'uniform_4 should be in registry');
    fprintf('OK\n');

    fprintf('    Testing lashkaripour_2021 source... ');
    raw = tariffwar.elasticity.sources.lashkaripour_2021();
    assert(numel(raw.epsilon) == 16, 'Should have 16 epsilon values');
    assert(raw.epsilon(1) == 0.67, 'First epsilon should be 0.67');
    assert(raw.epsilon(16) == 5.00, 'Last epsilon (services) should be 5.00');
    assert(all(raw.epsilon > 0), 'All epsilon should be positive');
    fprintf('OK\n');

    fprintf('    Testing uniform source... ');
    raw = tariffwar.elasticity.sources.uniform_simonovska_waugh();
    assert(raw.value == 4, 'Uniform value should be 4');
    fprintf('OK\n');

    fprintf('    Testing get() for lashkaripour → wiod... ');
    epsilon = tariffwar.elasticity.get('lashkaripour_2021', 'wiod', 16);
    assert(numel(epsilon) == 16, 'Should return 16 values');
    assert(epsilon(1) == 0.67, 'First epsilon should be 0.67');
    fprintf('OK\n');

    fprintf('    Testing get() for uniform → wiod... ');
    epsilon = tariffwar.elasticity.get('uniform_4', 'wiod', 16);
    assert(numel(epsilon) == 16, 'Should return 16 values');
    assert(all(epsilon == 4), 'All values should be 4');
    fprintf('OK\n');

    fprintf('    Testing get_sigma_cube... ');
    sigma = tariffwar.elasticity.get_sigma_cube('lashkaripour_2021', 'wiod', 44, 16);
    assert(isequal(size(sigma), [44, 44, 16]), 'Sigma cube should be 44x44x16');
    assert(sigma(1,1,16) == 5.00 + 1, 'Services sigma should be epsilon+1');
    assert(sigma(1,1,1) == 0.67 + 1, 'First goods sigma should be epsilon+1');
    fprintf('OK\n');

    fprintf('    Testing validate... ');
    tariffwar.elasticity.validate(ones(16,1), 16, 16);
    fprintf('OK\n');

    fprintf('    Testing validate rejects wrong size... ');
    try
        tariffwar.elasticity.validate(ones(10,1), 16, 16);
        error('Should have thrown');
    catch ME
        assert(contains(ME.identifier, 'wrongSize'));
    end
    fprintf('OK\n');

    fprintf('    Testing validate rejects non-positive... ');
    v = ones(16,1); v(5) = -1;
    try
        tariffwar.elasticity.validate(v, 16, 16);
        error('Should have thrown');
    catch ME
        assert(contains(ME.identifier, 'nonPositive'));
    end
    fprintf('OK\n');
end
