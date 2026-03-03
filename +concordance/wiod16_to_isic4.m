function [map, sector_labels] = wiod16_to_isic4()
%TARIFFWAR.CONCORDANCE.WIOD16_TO_ISIC4  Map WIOD 16 aggregated sectors to ISIC Rev 4.
%
%   [map, sector_labels] = tariffwar.concordance.wiod16_to_isic4()
%
%   Returns:
%     map           - 16 x 1 cell array, each cell contains a list of ISIC Rev 4
%                     2-digit division codes covered by that WIOD sector
%     sector_labels - 16 x 1 cell array of WIOD sector names
%
%   The WIOD 16-sector aggregation maps NACE Rev 2 divisions (which are
%   identical to ISIC Rev 4 at 2-digit level) as follows.
%
%   See also: tariffwar.pipeline.build_all

    % WIOD sector → ISIC Rev 4 / NACE Rev 2 divisions
    % Based on WIOD documentation and AGG_S_16.csv aggregation matrix.
    % NACE Rev 2 = ISIC Rev 4 at 2-digit level for EU countries.

    map = cell(16, 1);
    sector_labels = cell(16, 1);

    % Sector 1: Agriculture, forestry, fishing (NACE A = ISIC 01-03)
    map{1} = [1, 2, 3];
    sector_labels{1} = 'Agriculture, forestry, fishing';

    % Sector 2: Mining and quarrying (NACE B = ISIC 05-09)
    map{2} = [5, 6, 7, 8, 9];
    sector_labels{2} = 'Mining and quarrying';

    % Sector 3: Food, beverages, tobacco (NACE C10-C12 = ISIC 10-12)
    map{3} = [10, 11, 12];
    sector_labels{3} = 'Food, beverages, tobacco';

    % Sector 4: Textiles, apparel, leather (NACE C13-C15 = ISIC 13-15)
    map{4} = [13, 14, 15];
    sector_labels{4} = 'Textiles, apparel, leather';

    % Sector 5: Wood, paper, printing (NACE C16-C18 = ISIC 16-18)
    map{5} = [16, 17, 18];
    sector_labels{5} = 'Wood, paper, printing';

    % Sector 6: Coke, refined petroleum (NACE C19 = ISIC 19)
    map{6} = [19];
    sector_labels{6} = 'Coke and refined petroleum';

    % Sector 7: Chemicals, pharmaceuticals (NACE C20-C21 = ISIC 20-21)
    map{7} = [20, 21];
    sector_labels{7} = 'Chemicals, pharmaceuticals';

    % Sector 8: Rubber, plastics, non-metallic minerals (NACE C22-C23 = ISIC 22-23)
    map{8} = [22, 23];
    sector_labels{8} = 'Rubber, plastics, non-metallic minerals';

    % Sector 9: Basic metals (NACE C24 = ISIC 24)
    map{9} = [24];
    sector_labels{9} = 'Basic metals';

    % Sector 10: Fabricated metals (NACE C25 = ISIC 25)
    map{10} = [25];
    sector_labels{10} = 'Fabricated metals';

    % Sector 11: Computer, electronic, optical (NACE C26 = ISIC 26)
    map{11} = [26];
    sector_labels{11} = 'Computer, electronic, optical';

    % Sector 12: Electrical equipment (NACE C27 = ISIC 27)
    map{12} = [27];
    sector_labels{12} = 'Electrical equipment';

    % Sector 13: Machinery and equipment n.e.c. (NACE C28 = ISIC 28)
    map{13} = [28];
    sector_labels{13} = 'Machinery and equipment n.e.c.';

    % Sector 14: Transport equipment (NACE C29-C30 = ISIC 29-30)
    map{14} = [29, 30];
    sector_labels{14} = 'Transport equipment';

    % Sector 15: Other manufacturing; repair (NACE C31-C33 = ISIC 31-33)
    map{15} = [31, 32, 33];
    sector_labels{15} = 'Other manufacturing; repair';

    % Sector 16: Services (NACE D-U = ISIC 35-99)
    map{16} = [35, 36, 37, 38, 39, 41, 42, 43, 45, 46, 47, 49, 50, 51, 52, 53, ...
               55, 56, 58, 59, 60, 61, 62, 63, 64, 65, 66, 68, 69, 70, 71, 72, ...
               73, 74, 75, 77, 78, 79, 80, 81, 82, 84, 85, 86, 87, 88, 90, 91, ...
               92, 93, 94, 95, 96, 97, 98, 99];
    sector_labels{16} = 'Services (aggregate)';
end
