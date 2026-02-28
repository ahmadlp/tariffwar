function C = wiod16_to_itpd(S_target)
%TARIFFWAR.CONCORDANCE.WIOD16_TO_ITPD  Map WIOD 16 sectors to ITPD-S sectors.
%
%   C = tariffwar.concordance.wiod16_to_itpd(S_target)
%
%   Returns an S_target x 16 concordance matrix mapping WIOD 16 sectors
%   to USITC ITPD-S native sectors (with services collapsed).
%
%   Uses flat assignment: all ITPD-S sub-sectors within a WIOD sector
%   inherit the same elasticity value.
%
%   S_target should be 154 (153 goods + 1 services).
%
%   See also: tariffwar.concordance.get_sector_map

    % ITPD-S has 170 industries:
    %   1-26:    Agriculture (maps to WIOD sector 1)
    %   27-33:   Mining & Energy (maps to WIOD sector 2)
    %   34-153:  Manufacturing (maps to WIOD sectors 3-15)
    %   154-170: Services (collapsed to 1 → maps to WIOD sector 16)

    % After services collapse: S_target = 154 (153 goods + 1 services)
    if S_target ~= 154
        error('tariffwar:concordance:itpdSizeMismatch', ...
            'Expected S_target = 154 for ITPD-S, got %d.', S_target);
    end

    C = zeros(S_target, 16);

    % Agriculture: ITPD industries 1-26 → WIOD sector 1
    for s = 1:26
        C(s, 1) = 1;
    end

    % Mining: ITPD industries 27-33 → WIOD sector 2
    for s = 27:33
        C(s, 2) = 1;
    end

    % Manufacturing: ITPD industries 34-153 → WIOD sectors 3-15
    % This is a coarse-to-fine mapping. We need the ITPD-S ISIC classification
    % to properly assign each of the 120 manufacturing industries to the
    % correct WIOD goods sector. For now, use a rough mapping based on
    % ISIC Rev 4 division ranges:
    %
    % WIOD 3  (Food):         ISIC 10-12 → approx ITPD 34-56
    % WIOD 4  (Textiles):     ISIC 13-15 → approx ITPD 57-68
    % WIOD 5  (Wood/paper):   ISIC 16-18 → approx ITPD 69-77
    % WIOD 6  (Petroleum):    ISIC 19    → approx ITPD 78-79
    % WIOD 7  (Chemicals):    ISIC 20-21 → approx ITPD 80-95
    % WIOD 8  (Rubber/min):   ISIC 22-23 → approx ITPD 96-103
    % WIOD 9  (Basic metals): ISIC 24    → approx ITPD 104-108
    % WIOD 10 (Fab metals):   ISIC 25    → approx ITPD 109-114
    % WIOD 11 (Electronics):  ISIC 26    → approx ITPD 115-122
    % WIOD 12 (Electrical):   ISIC 27    → approx ITPD 123-127
    % WIOD 13 (Machinery):    ISIC 28    → approx ITPD 128-135
    % WIOD 14 (Transport):    ISIC 29-30 → approx ITPD 136-142
    % WIOD 15 (Other mfg):    ISIC 31-33 → approx ITPD 143-153
    %
    % NOTE: These ranges are approximate. Exact mapping requires the ITPD-S
    % industry classification table. Will be refined when ITPD-S data is loaded.

    mfg_ranges = { ...
        34:56,   ... % WIOD 3:  Food
        57:68,   ... % WIOD 4:  Textiles
        69:77,   ... % WIOD 5:  Wood/paper
        78:79,   ... % WIOD 6:  Petroleum
        80:95,   ... % WIOD 7:  Chemicals
        96:103,  ... % WIOD 8:  Rubber/minerals
        104:108, ... % WIOD 9:  Basic metals
        109:114, ... % WIOD 10: Fabricated metals
        115:122, ... % WIOD 11: Electronics
        123:127, ... % WIOD 12: Electrical
        128:135, ... % WIOD 13: Machinery
        136:142, ... % WIOD 14: Transport
        143:153  ... % WIOD 15: Other manufacturing
    };

    for w = 1:13  % WIOD goods sectors 3-15
        wiod_sector = w + 2;
        for s = mfg_ranges{w}
            C(s, wiod_sector) = 1;
        end
    end

    % Services: ITPD collapsed services (sector 154) → WIOD sector 16
    C(154, 16) = 1;
end
