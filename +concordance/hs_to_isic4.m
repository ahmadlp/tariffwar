function [map, hs_sections, isic4_divisions] = hs_to_isic4()
%TARIFFWAR.CONCORDANCE.HS_TO_ISIC4  HS sections to ISIC Rev 4 correspondence.
%
%   [map, hs_sections, isic4_divisions] = tariffwar.concordance.hs_to_isic4()
%
%   Returns the mapping from HS (Harmonized System) sections to ISIC Rev 4
%   divisions (2-digit). Used for Shapiro (2016) and Fontagne (2022) elasticities.
%
%   Output:
%     map              - struct array with hs_section, description, and isic4 divisions
%     hs_sections      - 21 x 1 vector of HS section numbers (I–XXI)
%     isic4_divisions  - cell array of ISIC Rev 4 division codes per HS section
%
%   Based on: WCO/UN HS↔ISIC correspondence tables
%
%   See also: tariffwar.concordance.isic3_to_isic4

    % HS has 21 sections (I through XXI), each mapping to ISIC Rev 4 divisions
    hs_sections = (1:21)';

    isic4_divisions = cell(21, 1);
    descriptions = cell(21, 1);

    % Section I: Live animals, animal products → ISIC 01, 03, 10
    isic4_divisions{1}  = [1, 3, 10];
    descriptions{1} = 'Live animals; animal products';

    % Section II: Vegetable products → ISIC 01, 02
    isic4_divisions{2}  = [1, 2];
    descriptions{2} = 'Vegetable products';

    % Section III: Fats and oils → ISIC 10
    isic4_divisions{3}  = [10];
    descriptions{3} = 'Animal or vegetable fats and oils';

    % Section IV: Food, beverages, tobacco → ISIC 10, 11, 12
    isic4_divisions{4}  = [10, 11, 12];
    descriptions{4} = 'Prepared foodstuffs; beverages, spirits; tobacco';

    % Section V: Mineral products → ISIC 05, 06, 07, 08, 19, 23
    isic4_divisions{5}  = [5, 6, 7, 8, 19, 23];
    descriptions{5} = 'Mineral products';

    % Section VI: Chemical products → ISIC 20, 21
    isic4_divisions{6}  = [20, 21];
    descriptions{6} = 'Products of the chemical or allied industries';

    % Section VII: Plastics and rubber → ISIC 22
    isic4_divisions{7}  = [22];
    descriptions{7} = 'Plastics and articles thereof; rubber';

    % Section VIII: Hides, skins, leather → ISIC 15
    isic4_divisions{8}  = [15];
    descriptions{8} = 'Raw hides and skins, leather';

    % Section IX: Wood and articles → ISIC 16
    isic4_divisions{9}  = [16];
    descriptions{9} = 'Wood and articles of wood';

    % Section X: Pulp, paper → ISIC 17
    isic4_divisions{10} = [17];
    descriptions{10} = 'Pulp of wood; paper and paperboard';

    % Section XI: Textiles and articles → ISIC 13, 14
    isic4_divisions{11} = [13, 14];
    descriptions{11} = 'Textiles and textile articles';

    % Section XII: Footwear, headgear → ISIC 15
    isic4_divisions{12} = [15];
    descriptions{12} = 'Footwear, headgear, umbrellas';

    % Section XIII: Stone, plaster, cement, ceramic, glass → ISIC 23
    isic4_divisions{13} = [23];
    descriptions{13} = 'Articles of stone, plaster, cement; ceramic; glass';

    % Section XIV: Precious metals, stones, jewelry → ISIC 32
    isic4_divisions{14} = [32];
    descriptions{14} = 'Natural or cultured pearls; precious stones; metals';

    % Section XV: Base metals → ISIC 24, 25
    isic4_divisions{15} = [24, 25];
    descriptions{15} = 'Base metals and articles of base metal';

    % Section XVI: Machinery, electrical equipment → ISIC 26, 27, 28
    isic4_divisions{16} = [26, 27, 28];
    descriptions{16} = 'Machinery; electrical equipment';

    % Section XVII: Vehicles, aircraft, vessels → ISIC 29, 30
    isic4_divisions{17} = [29, 30];
    descriptions{17} = 'Vehicles, aircraft, vessels';

    % Section XVIII: Optical, photographic, medical instruments → ISIC 26, 32
    isic4_divisions{18} = [26, 32];
    descriptions{18} = 'Optical, photographic, medical instruments; clocks';

    % Section XIX: Arms and ammunition → ISIC 25
    isic4_divisions{19} = [25];
    descriptions{19} = 'Arms and ammunition';

    % Section XX: Miscellaneous manufactured articles → ISIC 31, 32
    isic4_divisions{20} = [31, 32];
    descriptions{20} = 'Miscellaneous manufactured articles';

    % Section XXI: Works of art → ISIC 32
    isic4_divisions{21} = [32];
    descriptions{21} = 'Works of art, collectors pieces, antiques';

    % Build struct array
    map = struct();
    for i = 1:21
        map(i).hs_section = i;
        map(i).description = descriptions{i};
        map(i).isic4_divisions = isic4_divisions{i};
    end
end
