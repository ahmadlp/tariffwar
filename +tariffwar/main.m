function main()
%TARIFFWAR.MAIN  Template for full rebuild-and-batch runs.
%
%   tariffwar.main
%
%   This helper is intended for full project rebuilds, not the public
%   quickstart. For a fast first run with bundled data, use:
%
%     tariffwar.pipeline.run('wiod', 2014, 'IS')
%
%   Batch workflow:
%     Step 0: Download raw data (skips if already present)
%     Step 1: Build .mat files from raw CSVs
%     Step 2: Run a full dataset x year x elasticity grid
%
%   Output: results/results.csv (one master file)
%
%   Year coverage:
%     WIOD:  2000-2014  (44 countries, 16 sectors)
%     ICIO:  2011-2022  (81 countries, 28 sectors)
%     ITPD:  2000-2019  (135 countries, 154 sectors)
%   Years outside these ranges are silently skipped.
%
%   See also: tariffwar.pipeline.run, tariffwar.pipeline.build_all,
%             tariffwar.io.download_all, tariffwar.defaults

    % ===================== Step 0: Download Raw Data =====================
    tariffwar.io.download_all();

    % ===================== Step 1: Data Construction =====================
    % Uncomment to rebuild .mat data files from raw CSVs (slow, ~30 min).
    % Only needed once, or after updating raw data files.
    %tariffwar.pipeline.build_all('dataset', 'all', 'verbose', true);

    % ===================== Step 2: Analysis ==============================
    datasets     = {'wiod', 'icio', 'itpd'};
    years        = 2000:2022;   % run.m skips years without a .mat file
    elasticities = {'IS', 'U4', 'CP', 'BSY', 'GYY', 'Shap', 'FGO', 'LL'};

    % Uncomment to run the analysis (requires .mat files from Step 1).
    % tariffwar.pipeline.run(datasets, years, elasticities);
end
