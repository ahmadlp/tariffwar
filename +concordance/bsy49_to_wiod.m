function C = bsy49_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.BSY49_TO_WIOD  Map BSY 49 SITC sectors to WIOD 16.
%
%   C = tariffwar.concordance.bsy49_to_wiod()
%
%   Returns a 16 x 49 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_bsy
%
%   Maps Bagwell, Staiger & Yurukoglu (2021, Econometrica) 49-sector
%   SITC Rev 2 classification to WIOD 16 sectors.
%
%   BSY sectors are ordered by descending theta (sector 1 = highest).
%   See tariffwar.elasticity.sources.bagwell_staiger_yurukoglu_2021 for
%   the full sector list and SITC codes.
%
%   BSY 18 (Petroleum, SITC 33-34) maps to both WIOD 2 (Mining) and
%   WIOD 6 (Petroleum) via flat assignment.
%
%   See also: tariffwar.elasticity.sources.bagwell_staiger_yurukoglu_2021

    C = zeros(16, 49);

    % BSY sector indices (ordered by descending theta in source file):
    %  1=Feeding stuff         18=Petroleum           35=Specialized machinery
    %  2=Plumbing/heating      19=Paper manufactures  36=Organic chemicals
    %  3=Travel goods/bags     20=Cork and wood       37=Hides and skins
    %  4=Live animals          21=Resins              38=All others
    %  5=Other transport       22=Beverages           39=Inorganic chemicals
    %  6=Meat                  23=Wood manufactures   40=Vegetables and fruit
    %  7=Electrical machinery  24=Crude materials     41=Textile fibers
    %  8=Nonferrous metals     25=Animal oils/fats    42=Chemical
    %  9=Pulp/waste paper      26=Nonmetallic mineral 43=Dyeing and tanning
    % 10=Sugar                 27=Seafood             44=Rubber manufactures
    % 11=Misc. edible          28=Scientific instr.   45=Fertilizers
    % 12=Furniture/parts       29=Power gen machinery 46=Coffee, tea, spices
    % 13=Dairy                 30=Footwear            47=Crude rubber
    % 14=Cereals               31=Office machines     48=Fabrics
    % 15=Coal                  32=Misc manufactures   49=Metal ores
    % 16=Road vehicles         33=Pharmaceutical
    % 17=Tobacco               34=Iron and steel

    % --- WIOD 1  Agriculture (11 sectors) ---
    agri = [1, 4, 6, 10, 11, 13, 14, 25, 27, 40, 46];
    C(1, agri) = 1 / numel(agri);

    % --- WIOD 2  Mining (5 sectors) ---
    mining = [15, 18, 24, 47, 49];
    C(2, mining) = 1 / numel(mining);

    % --- WIOD 3  Food/bev/tobacco (2 sectors) ---
    food = [17, 22];
    C(3, food) = 1 / numel(food);

    % --- WIOD 4  Textiles/apparel/leather (5 sectors) ---
    textiles = [3, 30, 37, 41, 48];
    C(4, textiles) = 1 / numel(textiles);

    % --- WIOD 5  Wood/paper/printing (4 sectors) ---
    woodpaper = [9, 19, 20, 23];
    C(5, woodpaper) = 1 / numel(woodpaper);

    % --- WIOD 6  Petroleum (1 sector, flat split from Mining) ---
    C(6, 18) = 1;   % BSY 18 = Petroleum (also in WIOD 2)

    % --- WIOD 7  Chemicals/pharma (7 sectors) ---
    chemicals = [21, 33, 36, 39, 42, 43, 45];
    C(7, chemicals) = 1 / numel(chemicals);

    % --- WIOD 8  Rubber/plastics/minerals (2 sectors) ---
    rubber_min = [26, 44];
    C(8, rubber_min) = 1 / numel(rubber_min);

    % --- WIOD 9  Basic metals (2 sectors) ---
    basic_metals = [8, 34];
    C(9, basic_metals) = 1 / numel(basic_metals);

    % --- WIOD 10 Fabricated metals (1 sector) ---
    C(10, 2) = 1;   % BSY 2 = Plumbing, heating, lighting

    % --- WIOD 11 Electronics/optical (2 sectors) ---
    electronics = [28, 31];
    C(11, electronics) = 1 / numel(electronics);

    % --- WIOD 12 Electrical equipment (1 sector) ---
    C(12, 7) = 1;   % BSY 7 = Electrical machinery

    % --- WIOD 13 Machinery n.e.c. (2 sectors) ---
    machinery = [29, 35];
    C(13, machinery) = 1 / numel(machinery);

    % --- WIOD 14 Transport equipment (2 sectors) ---
    transport = [5, 16];
    C(14, transport) = 1 / numel(transport);

    % --- WIOD 15 Other mfg/repair (3 sectors) ---
    other_mfg = [12, 32, 38];
    C(15, other_mfg) = 1 / numel(other_mfg);

    % --- WIOD 16 Services: no BSY sectors → row stays zero ---
end
