function C = gyy19_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.GYY19_TO_WIOD  Map Giri-Yi-Yilmazkuday 19 sectors to WIOD 16.
%
%   C = tariffwar.concordance.gyy19_to_wiod()
%
%   Returns a 16 x 19 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_gyy
%
%   Maps GYY (2021, JIE) 19-sector ISIC Rev 2 manufacturing classification
%   to WIOD 16 sectors.
%
%   Source sectors (GYY Table 2, SMM-PPML):
%     1  Food products (311)          11 Rubber products (355)
%     2  Beverages & Tobacco (313-4)  12 Plastic products (356)
%     3  Textiles (321)               13 Pottery (361)
%     4  Wearing apparel (322)        14 Glass products (362)
%     5  Leather products (323)       15 Other non-metallic minerals (369)
%     6  Footwear (324)               16 Iron and steel (371)
%     7  Wood products (331)          17 Fabricated metal products (381)
%     8  Furniture (332)              18 Machinery, electric (383)
%     9  Paper & printing (341-2)     19 Transport equipment (384)
%     10 Other chemicals (352)
%
%   IMPORTANT: GYY covers manufacturing only.  WIOD sectors 1 (Agriculture),
%   2 (Mining), 6 (Petroleum), 11 (Electronics), and 13 (Machinery n.e.c.)
%   are NOT covered.  These rows are all-zero; build_sigma.m fills them
%   with the fallback epsilon = 4 (Simonovska-Waugh).
%
%   See also: tariffwar.elasticity.sources.giri_yi_yilmazkuday_2021

    C = zeros(16, 19);

    % --- WIOD 1 (Agriculture): not covered → row stays zero ---
    % --- WIOD 2 (Mining):       not covered → row stays zero ---

    % WIOD 3  Food/bev/tobacco <- G1 (Food) + G2 (Beverages & Tobacco)
    C(3, [1 2]) = 1/2;

    % WIOD 4  Textiles <- G3 (Textiles) + G4 (Apparel) + G5 (Leather) + G6 (Footwear)
    C(4, [3 4 5 6]) = 1/4;

    % WIOD 5  Wood/paper <- G7 (Wood) + G9 (Paper & printing)
    C(5, [7 9]) = 1/2;

    % --- WIOD 6 (Petroleum): not covered → row stays zero ---

    % WIOD 7  Chemicals <- G10 (Other chemicals)
    C(7, 10) = 1;

    % WIOD 8  Rubber/plastics/minerals <- G11 + G12 + G13 + G14 + G15
    C(8, [11 12 13 14 15]) = 1/5;

    % WIOD 9  Basic metals <- G16 (Iron and steel)
    C(9, 16) = 1;

    % WIOD 10 Fabricated metals <- G17 (Fabricated metal products)
    C(10, 17) = 1;

    % --- WIOD 11 (Electronics): not covered → row stays zero ---

    % WIOD 12 Electrical equipment <- G18 (Machinery, electric)
    C(12, 18) = 1;

    % --- WIOD 13 (Machinery n.e.c.): not covered → row stays zero ---

    % WIOD 14 Transport equipment <- G19
    C(14, 19) = 1;

    % WIOD 15 Other mfg <- G8 (Furniture)
    C(15, 8) = 1;

    % --- WIOD 16 (Services): not covered → row stays zero ---
end
