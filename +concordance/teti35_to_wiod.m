function [C, teti_codes] = teti35_to_wiod()
%TARIFFWAR.CONCORDANCE.TETI35_TO_WIOD  Concordance from Teti GTD 35 ISIC Rev 3 sectors to WIOD-16.
%
%   [C, teti_codes] = tariffwar.concordance.teti35_to_wiod()
%
%   Returns:
%     C          - 16 x 35 concordance matrix (rows sum to 1, averaging)
%     teti_codes - 35 x 1 vector of ISIC Rev 3 2-digit codes
%
%   Teti sector ordering (columns 1–35):
%     1,2,5, 10–14, 15–36, 40,74,92,93,99
%
%   WIOD-16 sector ordering (rows 1–16):
%     1  Agriculture          6  Petroleum        11 Electronics/optical
%     2  Mining               7  Chemicals        12 Electrical equipment
%     3  Food/bev/tobacco     8  Rubber/minerals  13 Machinery n.e.c.
%     4  Textiles             9  Basic metals     14 Transport equipment
%     5  Wood/paper/printing 10  Fab. metals      15 Other manufacturing
%                                                 16 Services
%
%   See also: tariffwar.tariff.build_tariffs

    % ISIC Rev 3 codes in Teti order (column index = position in this vector)
    teti_codes = [1, 2, 5, 10, 11, 12, 13, 14, ...
                  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, ...
                  27, 28, 29, 30, 31, 32, 33, 34, 35, 36, ...
                  40, 74, 92, 93, 99]';

    C = zeros(16, 35);

    %  WIOD 1: Agriculture  <- ISIC 1,2,5 (cols 1,2,3)
    C(1, [1 2 3]) = 1/3;

    %  WIOD 2: Mining <- ISIC 10,11,12,13,14 (cols 4,5,6,7,8)
    C(2, [4 5 6 7 8]) = 1/5;

    %  WIOD 3: Food/bev/tobacco <- ISIC 15,16 (cols 9,10)
    C(3, [9 10]) = 1/2;

    %  WIOD 4: Textiles <- ISIC 17,18,19 (cols 11,12,13)
    C(4, [11 12 13]) = 1/3;

    %  WIOD 5: Wood/paper/printing <- ISIC 20,21,22 (cols 14,15,16)
    C(5, [14 15 16]) = 1/3;

    %  WIOD 6: Petroleum <- ISIC 23 (col 17)
    C(6, 17) = 1;

    %  WIOD 7: Chemicals <- ISIC 24 (col 18)
    C(7, 18) = 1;

    %  WIOD 8: Rubber/plastics/minerals <- ISIC 25,26 (cols 19,20)
    C(8, [19 20]) = 1/2;

    %  WIOD 9: Basic metals <- ISIC 27 (col 21)
    C(9, 21) = 1;

    %  WIOD 10: Fabricated metals <- ISIC 28 (col 22)
    C(10, 22) = 1;

    %  WIOD 11: Electronics/optical <- ISIC 30,32,33 (cols 24,26,27)
    C(11, [24 26 27]) = 1/3;

    %  WIOD 12: Electrical equipment <- ISIC 31 (col 25)
    C(12, 25) = 1;

    %  WIOD 13: Machinery n.e.c. <- ISIC 29 (col 23)
    C(13, 23) = 1;

    %  WIOD 14: Transport equipment <- ISIC 34,35 (cols 28,29)
    C(14, [28 29]) = 1/2;

    %  WIOD 15: Other manufacturing <- ISIC 36 (col 30)
    C(15, 30) = 1;

    %  WIOD 16: Services <- ISIC 40,74,92,93,99 (cols 31,32,33,34,35)
    C(16, [31 32 33 34 35]) = 1/5;
end
