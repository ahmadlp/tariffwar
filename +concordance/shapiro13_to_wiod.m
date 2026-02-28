function C = shapiro13_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.SHAPIRO13_TO_WIOD  Map Shapiro 13 sectors to WIOD 16.
%
%   C = tariffwar.concordance.shapiro13_to_wiod()
%
%   Returns a 16 x 13 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_shapiro
%
%   Maps Shapiro (2016) 13-sector custom classification to WIOD 16 sectors.
%
%   Source sectors (Shapiro Table 2):
%     1  Agriculture, forestry      8  Petroleum, coal, minerals
%     2  Mining                     9  Chemicals, rubber, plastics
%     3  Food, beverages, tobacco   10 Metals
%     4  Textiles                   11 Machinery, electrical
%     5  Apparel, leather           12 Transport equipment
%     6  Wood                       13 Other
%     7  Paper, printing
%
%   Sectors S8, S9, S10, S11 each span multiple WIOD sectors.  With flat
%   assignment, the same source value is assigned to each receiving target.
%
%   See also: tariffwar.elasticity.sources.shapiro_2016

    C = zeros(16, 13);

    % --- Direct one-to-one mappings ---
    C(1, 1)  = 1;     % WIOD 1  Agriculture       <- S1  Agriculture, forestry
    C(2, 2)  = 1;     % WIOD 2  Mining             <- S2  Mining
    C(3, 3)  = 1;     % WIOD 3  Food/bev/tobacco   <- S3  Food, beverages, tobacco
    C(14, 12) = 1;    % WIOD 14 Transport equip    <- S12 Transport equipment
    C(15, 13) = 1;    % WIOD 15 Other mfg          <- S13 Other

    % --- Average mappings ---
    C(4, [4 5])  = 1/2;  % WIOD 4  Textiles    <- S4 (Textiles) + S5 (Apparel, leather)
    C(5, [6 7])  = 1/2;  % WIOD 5  Wood/paper  <- S6 (Wood) + S7 (Paper, printing)
    C(8, [8 9])  = 1/2;  % WIOD 8  Rubber/min  <- S8 (Petroleum/minerals) + S9 (Chem/rubber/plastics)

    % --- Flat split: one source → multiple targets (same value) ---
    C(6, 8)  = 1;     % WIOD 6  Petroleum   <- S8  (petroleum part)
    C(7, 9)  = 1;     % WIOD 7  Chemicals   <- S9  (chemicals part)
    C(9, 10) = 1;     % WIOD 9  Basic metals <- S10 (metals)
    C(10, 10) = 1;    % WIOD 10 Fab metals   <- S10 (metals)
    C(11, 11) = 1;    % WIOD 11 Electronics  <- S11 (machinery, electrical)
    C(12, 11) = 1;    % WIOD 12 Electrical   <- S11
    C(13, 11) = 1;    % WIOD 13 Machinery    <- S11

    % WIOD 16 (Services): no Shapiro tradable sectors → row stays zero
end
