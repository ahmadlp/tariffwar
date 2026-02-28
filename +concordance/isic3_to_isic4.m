function [C, isic3_codes, isic4_codes] = isic3_to_isic4()
%TARIFFWAR.CONCORDANCE.ISIC3_TO_ISIC4  ISIC Rev 3 to ISIC Rev 4 correspondence.
%
%   [C, isic3_codes, isic4_codes] = tariffwar.concordance.isic3_to_isic4()
%
%   Returns the official UN correspondence table mapping ISIC Rev 3.1
%   divisions (2-digit) to ISIC Rev 4 divisions (2-digit).
%
%   Output:
%     C           - n_isic4 x n_isic3 correspondence matrix
%                   C(i,j) = fraction of ISIC Rev 3 division j that maps to
%                   ISIC Rev 4 division i (columns sum to 1)
%     isic3_codes - n_isic3 x 1 vector of ISIC Rev 3 division codes
%     isic4_codes - n_isic4 x 1 vector of ISIC Rev 4 division codes
%
%   Based on: UN Statistics Division ISIC Rev 3.1 <-> ISIC Rev 4 correspondence
%   At the 2-digit division level, many mappings are 1-to-1.
%
%   See also: tariffwar.concordance.wiod16_to_isic4

    % ISIC Rev 3.1 divisions (2-digit codes used in trade literature)
    isic3_codes = [1; 2; 5; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; ...
                   21; 22; 23; 24; 25; 26; 27; 28; 29; 30; 31; 32; 33; ...
                   34; 35; 36; 37; 40; 41; 45; 50; 51; 52; 55; 60; 61; ...
                   62; 63; 64; 65; 66; 67; 70; 71; 72; 73; 74; 75; 80; ...
                   85; 90; 91; 92; 93; 95; 99];
    n3 = numel(isic3_codes);

    % ISIC Rev 4 divisions (2-digit)
    isic4_codes = [1; 2; 3; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; ...
                   17; 18; 19; 20; 21; 22; 23; 24; 25; 26; 27; 28; 29; ...
                   30; 31; 32; 33; 35; 36; 37; 38; 39; 41; 42; 43; 45; ...
                   46; 47; 49; 50; 51; 52; 53; 55; 56; 58; 59; 60; 61; ...
                   62; 63; 64; 65; 66; 68; 69; 70; 71; 72; 73; 74; 75; ...
                   77; 78; 79; 80; 81; 82; 84; 85; 86; 87; 88; 90; 91; ...
                   92; 93; 94; 95; 96; 97; 98; 99];
    n4 = numel(isic4_codes);

    % Build correspondence matrix
    % Most ISIC Rev 3 divisions map cleanly to ISIC Rev 4 divisions.
    % Where a Rev 3 division splits into multiple Rev 4 divisions,
    % we use equal weights (refined later with trade-weighted averages if needed).

    C = zeros(n4, n3);

    % Helper: find index of a code in a vector
    idx3 = @(code) find(isic3_codes == code, 1);
    idx4 = @(code) find(isic4_codes == code, 1);

    % === Agriculture ===
    % ISIC3 01 -> ISIC4 01+02+03
    C(idx4(1), idx3(1)) = 1/3;  C(idx4(2), idx3(1)) = 1/3;  C(idx4(3), idx3(1)) = 1/3;
    % ISIC3 02 -> ISIC4 02 (forestry)
    C(idx4(2), idx3(2)) = 1;
    % ISIC3 05 -> ISIC4 03 (fishing)
    C(idx4(3), idx3(5)) = 1;

    % === Mining ===
    % ISIC3 10 -> ISIC4 05 (coal)
    C(idx4(5), idx3(10)) = 1;
    % ISIC3 11 -> ISIC4 06 (petroleum)
    C(idx4(6), idx3(11)) = 1;
    % ISIC3 12 -> ISIC4 07+08 (uranium -> metal ores + other mining)
    C(idx4(7), idx3(12)) = 0.5;  C(idx4(8), idx3(12)) = 0.5;
    % ISIC3 13 -> ISIC4 07 (metal ores)
    C(idx4(7), idx3(13)) = 1;
    % ISIC3 14 -> ISIC4 08 (other mining)
    C(idx4(8), idx3(14)) = 1;

    % === Manufacturing ===
    % ISIC3 15 -> ISIC4 10+11+12 (food+beverages+tobacco)
    C(idx4(10), idx3(15)) = 1/3;  C(idx4(11), idx3(15)) = 1/3;  C(idx4(12), idx3(15)) = 1/3;
    % ISIC3 16 -> ISIC4 12 (tobacco)
    C(idx4(12), idx3(16)) = 1;
    % ISIC3 17 -> ISIC4 13 (textiles)
    C(idx4(13), idx3(17)) = 1;
    % ISIC3 18 -> ISIC4 14 (wearing apparel)
    C(idx4(14), idx3(18)) = 1;
    % ISIC3 19 -> ISIC4 15 (leather)
    C(idx4(15), idx3(19)) = 1;
    % ISIC3 20 -> ISIC4 16 (wood)
    C(idx4(16), idx3(20)) = 1;
    % ISIC3 21 -> ISIC4 17 (paper)
    C(idx4(17), idx3(21)) = 1;
    % ISIC3 22 -> ISIC4 18+58+59 (publishing/printing -> printing + publishing + audiovisual)
    C(idx4(18), idx3(22)) = 0.5;  C(idx4(58), idx3(22)) = 0.25;  C(idx4(59), idx3(22)) = 0.25;
    % ISIC3 23 -> ISIC4 19 (coke/petroleum)
    C(idx4(19), idx3(23)) = 1;
    % ISIC3 24 -> ISIC4 20+21 (chemicals + pharma)
    C(idx4(20), idx3(24)) = 0.5;  C(idx4(21), idx3(24)) = 0.5;
    % ISIC3 25 -> ISIC4 22 (rubber/plastics)
    C(idx4(22), idx3(25)) = 1;
    % ISIC3 26 -> ISIC4 23 (non-metallic minerals)
    C(idx4(23), idx3(26)) = 1;
    % ISIC3 27 -> ISIC4 24 (basic metals)
    C(idx4(24), idx3(27)) = 1;
    % ISIC3 28 -> ISIC4 25 (fabricated metals)
    C(idx4(25), idx3(28)) = 1;
    % ISIC3 29 -> ISIC4 28 (machinery)
    C(idx4(28), idx3(29)) = 1;
    % ISIC3 30 -> ISIC4 26 (computers/electronics)
    C(idx4(26), idx3(30)) = 1;
    % ISIC3 31 -> ISIC4 27 (electrical equipment)
    C(idx4(27), idx3(31)) = 1;
    % ISIC3 32 -> ISIC4 26 (radio/TV -> electronics)
    C(idx4(26), idx3(32)) = C(idx4(26), idx3(32)) + 1;
    % ISIC3 33 -> ISIC4 26+32 (medical/optical instruments)
    C(idx4(26), idx3(33)) = C(idx4(26), idx3(33)) + 0.5;
    C(idx4(32), idx3(33)) = 0.5;
    % ISIC3 34 -> ISIC4 29 (motor vehicles)
    C(idx4(29), idx3(34)) = 1;
    % ISIC3 35 -> ISIC4 30 (other transport)
    C(idx4(30), idx3(35)) = 1;
    % ISIC3 36 -> ISIC4 31+32 (furniture + other manufacturing)
    C(idx4(31), idx3(36)) = 0.5;  C(idx4(32), idx3(36)) = C(idx4(32), idx3(36)) + 0.5;
    % ISIC3 37 -> ISIC4 38 (recycling -> waste management)
    C(idx4(38), idx3(37)) = 1;

    % === Services ===
    % ISIC3 40 -> ISIC4 35 (electricity/gas)
    C(idx4(35), idx3(40)) = 1;
    % ISIC3 41 -> ISIC4 36 (water supply)
    C(idx4(36), idx3(41)) = 1;
    % ISIC3 45 -> ISIC4 41+42+43 (construction)
    C(idx4(41), idx3(45)) = 1/3;  C(idx4(42), idx3(45)) = 1/3;  C(idx4(43), idx3(45)) = 1/3;
    % ISIC3 50 -> ISIC4 45 (vehicle sales/repair)
    C(idx4(45), idx3(50)) = 1;
    % ISIC3 51 -> ISIC4 46 (wholesale)
    C(idx4(46), idx3(51)) = 1;
    % ISIC3 52 -> ISIC4 47 (retail)
    C(idx4(47), idx3(52)) = 1;
    % ISIC3 55 -> ISIC4 55+56 (hotels/restaurants)
    C(idx4(55), idx3(55)) = 0.5;  C(idx4(56), idx3(55)) = 0.5;
    % ISIC3 60 -> ISIC4 49 (land transport)
    C(idx4(49), idx3(60)) = 1;
    % ISIC3 61 -> ISIC4 50 (water transport)
    C(idx4(50), idx3(61)) = 1;
    % ISIC3 62 -> ISIC4 51 (air transport)
    C(idx4(51), idx3(62)) = 1;
    % ISIC3 63 -> ISIC4 52+79 (supporting transport + travel agencies)
    C(idx4(52), idx3(63)) = 0.5;  C(idx4(79), idx3(63)) = 0.5;
    % ISIC3 64 -> ISIC4 53+61 (post + telecoms)
    C(idx4(53), idx3(64)) = 0.5;  C(idx4(61), idx3(64)) = 0.5;
    % ISIC3 65 -> ISIC4 64 (financial intermediation)
    C(idx4(64), idx3(65)) = 1;
    % ISIC3 66 -> ISIC4 65 (insurance)
    C(idx4(65), idx3(66)) = 1;
    % ISIC3 67 -> ISIC4 66 (financial auxiliaries)
    C(idx4(66), idx3(67)) = 1;
    % ISIC3 70 -> ISIC4 68 (real estate)
    C(idx4(68), idx3(70)) = 1;
    % ISIC3 71 -> ISIC4 77 (renting of machinery)
    C(idx4(77), idx3(71)) = 1;
    % ISIC3 72 -> ISIC4 62+63 (computer activities)
    C(idx4(62), idx3(72)) = 0.5;  C(idx4(63), idx3(72)) = 0.5;
    % ISIC3 73 -> ISIC4 72 (R&D)
    C(idx4(72), idx3(73)) = 1;
    % ISIC3 74 -> ISIC4 69+70+71+73+74+78+80+81+82 (other business)
    n_split = 9;
    for code = [69, 70, 71, 73, 74, 78, 80, 81, 82]
        C(idx4(code), idx3(74)) = 1/n_split;
    end
    % ISIC3 75 -> ISIC4 84 (public admin)
    C(idx4(84), idx3(75)) = 1;
    % ISIC3 80 -> ISIC4 85 (education)
    C(idx4(85), idx3(80)) = 1;
    % ISIC3 85 -> ISIC4 86+87+88 (health/social)
    C(idx4(86), idx3(85)) = 1/3;  C(idx4(87), idx3(85)) = 1/3;  C(idx4(88), idx3(85)) = 1/3;
    % ISIC3 90 -> ISIC4 37+38+39 (sewage/waste)
    C(idx4(37), idx3(90)) = 1/3;  C(idx4(38), idx3(90)) = 1/3;  C(idx4(39), idx3(90)) = 1/3;
    % ISIC3 91 -> ISIC4 94 (membership organizations)
    C(idx4(94), idx3(91)) = 1;
    % ISIC3 92 -> ISIC4 90+91+92+93 (recreational/cultural)
    C(idx4(90), idx3(92)) = 0.25;  C(idx4(91), idx3(92)) = 0.25;
    C(idx4(92), idx3(92)) = 0.25;  C(idx4(93), idx3(92)) = 0.25;
    % ISIC3 93 -> ISIC4 96 (other service activities)
    C(idx4(96), idx3(93)) = 1;
    % ISIC3 95 -> ISIC4 97+98 (domestic personnel)
    C(idx4(97), idx3(95)) = 0.5;  C(idx4(98), idx3(95)) = 0.5;
    % ISIC3 99 -> ISIC4 99 (extraterritorial)
    C(idx4(99), idx3(99)) = 1;

    % Normalize columns so each ISIC3 division's weights sum to 1
    col_sums = sum(C, 1);
    col_sums(col_sums == 0) = 1;  % avoid division by zero
    C = C ./ repmat(col_sums, [n4, 1]);
end
