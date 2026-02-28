function test_data_loading()
%TARIFFWAR.TEST.TEST_DATA_LOADING  Test data loading functions.

    cfg = tariffwar.defaults();
    cfg.verbose = false;
    cfg.dataset = 'wiod';

    fprintf('\n    Testing load_country_list (WIOD)... ');
    countries = tariffwar.io.load_country_list(cfg);
    assert(numel(countries) == 44, 'WIOD should have 44 countries');
    fprintf('OK\n');

    fprintf('    Testing load_data (WIOD prebuilt, 2014)... ');
    data = tariffwar.io.load_data('wiod', 2014);
    assert(data.N == 44, 'N should be 44');
    assert(data.S == 16, 'S should be 16');
    assert(isequal(size(data.Xjik_3D), [44, 44, 16]), 'Xjik_3D should be 44x44x16');
    assert(isequal(size(data.tjik_3D), [44, 44, 16]), 'tjik_3D should be 44x44x16');
    assert(data.services_sector == 16, 'Services sector should be 16');
    fprintf('OK\n');

    fprintf('    Testing load_gdp (WIOD, 2014)... ');
    gdp = tariffwar.io.load_gdp(cfg, 2014);
    assert(numel(gdp) == 44, 'GDP should have 44 values');
    assert(all(gdp > 0), 'All GDP values should be positive');
    fprintf('OK\n');

    fprintf('    Testing load_tariffs (TRAINS, 2014)... ');
    cfg.tariff_source = 'trains';
    tjik = tariffwar.io.load_tariffs(cfg, 2014, 44, 16);
    assert(isequal(size(tjik), [44, 44, 16]), 'Tariffs should be 44x44x16');
    assert(all(tjik(:) >= 0), 'All tariffs should be non-negative');
    fprintf('OK\n');
end
