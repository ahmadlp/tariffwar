function C = ll14_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.LL14_TO_WIOD  Map Lashkaripour-Lugovskyy 14 sectors to WIOD 16.
%
%   C = tariffwar.concordance.ll14_to_wiod()
%
%   Returns a 16 x 14 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_ll
%
%   Maps Lashkaripour & Lugovskyy (2023, AER) 14-sector ISIC Rev 4
%   traded-industry classification to WIOD 16 sectors.
%
%   Source sectors (LL Table 3, sigma_k - 1):
%     1  Agriculture and Mining       8  Rubber and Plastic
%     2  Food                         9  Minerals
%     3  Textiles, Leather, Footwear  10 Basic and Fabricated Metals
%     4  Wood                         11 Machinery
%     5  Paper                        12 Electrical and Optical Equipment
%     6  Petroleum                    13 Transport Equipment
%     7  Chemicals                    14 N.E.C. and Recycling
%
%   Three LL sectors combine WIOD pairs (flat assignment — same value to each):
%     LL1  "Agriculture and Mining"       → WIOD 1 + WIOD 2
%     LL10 "Basic and Fabricated Metals"  → WIOD 9 + WIOD 10
%     LL12 "Electrical and Optical"       → WIOD 11 + WIOD 12
%
%   See also: tariffwar.elasticity.sources.lashkaripour_lugovskyy_2023

    C = zeros(16, 14);

    % --- Flat split: one source → two targets (same value assigned) ---
    C(1, 1)  = 1;     % WIOD 1  Agriculture   <- LL1  (Agri & Mining)
    C(2, 1)  = 1;     % WIOD 2  Mining         <- LL1  (Agri & Mining)
    C(9, 10) = 1;     % WIOD 9  Basic metals   <- LL10 (Basic & Fab Metals)
    C(10, 10) = 1;    % WIOD 10 Fab metals     <- LL10 (Basic & Fab Metals)
    C(11, 12) = 1;    % WIOD 11 Electronics    <- LL12 (Elec & Optical)
    C(12, 12) = 1;    % WIOD 12 Electrical     <- LL12 (Elec & Optical)

    % --- Direct one-to-one mappings ---
    C(3, 2)  = 1;     % WIOD 3  Food/bev/tobacco <- LL2  Food
    C(4, 3)  = 1;     % WIOD 4  Textiles         <- LL3  Textiles/Leather/Footwear
    C(6, 6)  = 1;     % WIOD 6  Petroleum        <- LL6  Petroleum
    C(7, 7)  = 1;     % WIOD 7  Chemicals        <- LL7  Chemicals
    C(13, 11) = 1;    % WIOD 13 Machinery n.e.c. <- LL11 Machinery
    C(14, 13) = 1;    % WIOD 14 Transport equip  <- LL13 Transport Equipment
    C(15, 14) = 1;    % WIOD 15 Other mfg        <- LL14 N.E.C. and Recycling

    % --- Average mappings ---
    C(5, [4 5])  = 1/2;  % WIOD 5  Wood/paper  <- LL4 (Wood) + LL5 (Paper)
    C(8, [8 9])  = 1/2;  % WIOD 8  Rubber/min  <- LL8 (Rubber) + LL9 (Minerals)

    % WIOD 16 (Services): no LL tradable sectors → row stays zero
end
