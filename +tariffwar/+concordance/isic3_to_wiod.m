function C = isic3_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.ISIC3_TO_WIOD  Map Caliendo-Parro 20 ISIC3 sectors to WIOD 16.
%
%   C = tariffwar.concordance.isic3_to_wiod()
%
%   Returns a 16 x 20 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_cp
%
%   Maps Caliendo & Parro (2015, ReStud) 20-sector ISIC Rev 3 classification
%   to WIOD 16-sector classification.
%
%   Source sectors (CP Table 1):
%     1  Agriculture (ISIC 01-05)    11 Basic metals (27)
%     2  Mining (10-14)              12 Metal products (28)
%     3  Food (15-16)                13 Machinery n.e.c. (29)
%     4  Textiles (17-19)            14 Office (30)
%     5  Wood (20)                   15 Electrical (31)
%     6  Paper (21-22)               16 Communication (32)
%     7  Petroleum (23)              17 Medical (33)
%     8  Chemicals (24)              18 Auto (34)
%     9  Plastics (25)               19 Other transport (35)
%     10 Minerals (26)               20 Other mfg (36-37)
%
%   CP 17 (Medical, ISIC 33) spans WIOD 11 (electronics/optical) and
%   WIOD 15 (other mfg) via ISIC3→ISIC4 correspondence.  With flat
%   assignment, CP 17 contributes as a full source to both target sectors.
%
%   See also: tariffwar.elasticity.sources.caliendo_parro_2015

    C = zeros(16, 20);

    % --- Direct one-to-one mappings ---
    C(1, 1)   = 1;      % WIOD 1  Agriculture       <- CP 1  (ISIC 01-05)
    C(2, 2)   = 1;      % WIOD 2  Mining             <- CP 2  (ISIC 10-14)
    C(3, 3)   = 1;      % WIOD 3  Food/bev/tobacco   <- CP 3  (ISIC 15-16)
    C(4, 4)   = 1;      % WIOD 4  Textiles           <- CP 4  (ISIC 17-19)
    C(6, 7)   = 1;      % WIOD 6  Petroleum          <- CP 7  (ISIC 23)
    C(7, 8)   = 1;      % WIOD 7  Chemicals/pharma   <- CP 8  (ISIC 24)
    C(9, 11)  = 1;      % WIOD 9  Basic metals       <- CP 11 (ISIC 27)
    C(10, 12) = 1;      % WIOD 10 Fabricated metals   <- CP 12 (ISIC 28)
    C(12, 15) = 1;      % WIOD 12 Electrical equip    <- CP 15 (ISIC 31)
    C(13, 13) = 1;      % WIOD 13 Machinery n.e.c.    <- CP 13 (ISIC 29)

    % --- Average mappings (multiple source → one target, equal weights) ---
    C(5, [5 6])    = 1/2;   % WIOD 5  Wood/paper     <- CP 5 (Wood) + CP 6 (Paper)
    C(8, [9 10])   = 1/2;   % WIOD 8  Rubber/minerals <- CP 9 (Plastics) + CP 10 (Minerals)
    C(14, [18 19]) = 1/2;   % WIOD 14 Transport       <- CP 18 (Auto) + CP 19 (Other transport)

    % --- Split sector: CP 17 (Medical, ISIC 33) → WIOD 11 + WIOD 15 ---
    % ISIC3.33 maps to ISIC4.26 (optical/electronics → WIOD 11) and
    % ISIC4.32-33 (other mfg/repair → WIOD 15).  Flat assignment: CP 17
    % is a full contributor to each receiving WIOD sector.
    C(11, [14 16 17]) = 1/3;  % WIOD 11 Electronics  <- CP 14 + CP 16 + CP 17
    C(15, [17 20])    = 1/2;  % WIOD 15 Other mfg    <- CP 17 + CP 20

    % WIOD 16 (Services): no CP tradable sectors → row stays zero
    % services_sigma override applied at load time
end
