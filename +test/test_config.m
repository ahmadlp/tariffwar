function test_config()
%TARIFFWAR.TEST.TEST_CONFIG  Test defaults.

    fprintf('\n    Testing defaults... ');
    cfg = tariffwar.defaults();
    assert(cfg.solver.TolFun == 1e-12, 'Default TolFun should be 1e-12');
    assert(cfg.solver.TolX == 1e-14, 'Default TolX should be 1e-14');
    assert(strcmp(cfg.solver.algorithm, 'trust-region-dogleg'), 'Default algorithm');
    assert(~isempty(cfg.mat_dir), 'mat_dir should be set');
    assert(~isempty(cfg.data_root), 'data_root should be set');
    fprintf('OK\n');

    fprintf('    ');
end
