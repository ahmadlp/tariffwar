function test_concordance()
%TARIFFWAR.TEST.TEST_CONCORDANCE  Test concordance infrastructure.

    fprintf('\n    Testing wiod_services_mask... ');
    mask = tariffwar.concordance.wiod_services_mask();
    assert(numel(mask) == 16, 'WIOD mask should have 16 elements');
    assert(sum(mask) == 1, 'Only one services sector');
    assert(mask(16) == true, 'Sector 16 should be services');
    fprintf('OK\n');

    fprintf('    Testing icio_services_mask... ');
    mask = tariffwar.concordance.icio_services_mask();
    assert(numel(mask) == 45, 'ICIO mask should have 45 elements');
    assert(sum(mask) > 0, 'Should have some services');
    fprintf('OK\n');

    fprintf('    Testing itpd_services_mask... ');
    mask = tariffwar.concordance.itpd_services_mask();
    assert(numel(mask) == 170, 'ITPD mask should have 170 elements');
    assert(sum(mask) == 17, 'Should have 17 service industries');
    assert(mask(154) == true, 'Industry 154 should be services');
    assert(mask(170) == true, 'Industry 170 should be services');
    fprintf('OK\n');

    fprintf('    Testing wiod16_to_isic4 mapping... ');
    [map, labels] = tariffwar.concordance.wiod16_to_isic4();
    assert(numel(map) == 16, 'Should have 16 WIOD sectors');
    assert(numel(labels) == 16, 'Should have 16 labels');
    % Check agriculture maps to ISIC 01-03
    assert(isequal(map{1}, [1, 2, 3]), 'Agriculture should map to ISIC 01-03');
    % Check services covers ISIC 35+
    assert(all(map{16} >= 35), 'Services should be ISIC 35+');
    fprintf('OK\n');

    fprintf('    Testing get_sector_map for wiod_16 → wiod... ');
    C = tariffwar.concordance.get_sector_map('lashkaripour_2021', 'wiod', 16);
    assert(isequal(size(C), [16, 16]), 'Should be 16x16');
    assert(isequal(C, eye(16)), 'Should be identity for wiod→wiod');
    fprintf('OK\n');

    fprintf('    Testing isic3_to_isic4 correspondence... ');
    [C, codes3, codes4] = tariffwar.concordance.isic3_to_isic4();
    assert(size(C, 1) == numel(codes4), 'Rows should match ISIC4 codes');
    assert(size(C, 2) == numel(codes3), 'Cols should match ISIC3 codes');
    % Each column should roughly sum to 1
    col_sums = sum(C, 1);
    assert(all(abs(col_sums - 1) < 0.01 | col_sums == 0), ...
        'Column sums should be ~1 or 0');
    fprintf('OK\n');
end
