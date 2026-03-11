function C = fontagne19_to_wiod(~, ~)
%TARIFFWAR.CONCORDANCE.FONTAGNE19_TO_WIOD  Map Fontagne TiVA 19 sectors to WIOD 16.
%
%   C = tariffwar.concordance.fontagne19_to_wiod()
%
%   Returns a 16 x 19 concordance matrix C such that:
%     epsilon_wiod = C * epsilon_fontagne
%
%   Maps Fontagne, Guimbard & Orefice (2022, JIE) 19-sector TiVA
%   classification to WIOD 16 sectors.  Near one-to-one correspondence.
%
%   Source sectors (Fontagne Table 8, TiVA 2016):
%     1  C01T05  Agriculture           11 C27    Basic metals
%     2  C10T14  Mining                12 C28    Fabricated metals
%     3  C15T16  Food/bev/tobacco      13 C29    Machinery n.e.c.
%     4  C17T19  Textiles/leather      14 C30T33X Computer/electronic/optical
%     5  C20     Wood                  15 C31    Electrical machinery
%     6  C21T22  Paper/printing        16 C34    Motor vehicles
%     7  C23     Petroleum/coke        17 C35    Other transport
%     8  C24     Chemicals             18 C36T37 Mfg n.e.c./recycling
%     9  C25     Rubber/plastics       19 C90T93 Community/social/personal svcs
%     10 C26     Non-metallic minerals
%
%   See also: tariffwar.elasticity.sources.fontagne_2022

    C = zeros(16, 19);

    % --- Direct one-to-one mappings ---
    C(1, 1)   = 1;    % WIOD 1  Agriculture   <- F1  C01T05
    C(2, 2)   = 1;    % WIOD 2  Mining        <- F2  C10T14
    C(3, 3)   = 1;    % WIOD 3  Food          <- F3  C15T16
    C(4, 4)   = 1;    % WIOD 4  Textiles      <- F4  C17T19
    C(6, 7)   = 1;    % WIOD 6  Petroleum     <- F7  C23
    C(7, 8)   = 1;    % WIOD 7  Chemicals     <- F8  C24
    C(9, 11)  = 1;    % WIOD 9  Basic metals  <- F11 C27
    C(10, 12) = 1;    % WIOD 10 Fab metals    <- F12 C28
    C(11, 14) = 1;    % WIOD 11 Electronics   <- F14 C30T33X
    C(12, 15) = 1;    % WIOD 12 Electrical    <- F15 C31
    C(13, 13) = 1;    % WIOD 13 Machinery     <- F13 C29
    C(15, 18) = 1;    % WIOD 15 Other mfg     <- F18 C36T37
    C(16, 19) = 1;    % WIOD 16 Services      <- F19 C90T93

    % --- Average mappings ---
    C(5, [5 6])    = 1/2;  % WIOD 5  Wood/paper  <- F5 (Wood) + F6 (Paper)
    C(8, [9 10])   = 1/2;  % WIOD 8  Rubber/min  <- F9 (Rubber) + F10 (Minerals)
    C(14, [16 17]) = 1/2;  % WIOD 14 Transport   <- F16 (Motor vehicles) + F17 (Other transport)
end
