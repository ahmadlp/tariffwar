function main()
%TARIFFWAR.MAIN  Run the full pipeline with one click.
%
%   tariffwar.main
%
%   Step 1: Data construction (commented out — already built)
%   Step 2: Analysis — all datasets x years x elasticities
%
%   Output: +tariffwar/results/results.csv (one master file)
%
%   Year coverage (from prebuilt .mat files):
%     WIOD:  2000-2014  (44 countries, 16 sectors)
%     ICIO:  2011-2022  (85 countries, 28 sectors)
%     ITPD:  2000-2019  (135 countries, 154 sectors)
%   Years outside these ranges are silently skipped.
%
%   See also: tariffwar.run, tariffwar.build_all

    % ===================== Step 1: Data Construction =====================
    % Uncomment to rebuild .mat files from raw data (takes ~30 min):
    % tariffwar.build_all('dataset', 'all', 'verbose', true);

    % ===================== Step 2: Analysis ==============================
    datasets     = {'wiod', 'icio', 'itpd'};
    years        = 2000:2022;   % run.m skips years without a .mat file
    elasticities = {'L21', 'U4', 'CP', 'BSY', 'GYY', 'Shap', 'FGO', 'LL'};

    tariffwar.run(datasets, years, elasticities, ...
        'MaxIter', 100);
end
