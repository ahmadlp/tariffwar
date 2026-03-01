function C = wiod16_to_icio(S_target)
%TARIFFWAR.CONCORDANCE.WIOD16_TO_ICIO  Map WIOD 16 sectors to ICIO Extended sectors.
%
%   C = tariffwar.concordance.wiod16_to_icio(S_target)
%
%   Returns an S_target x 16 concordance matrix mapping WIOD 16 sectors
%   to OECD ICIO Extended (2016-2022) sectors after services collapse.
%
%   ICIO Extended has 50 raw sectors (27 goods + 23 services).
%   After services collapse: 27 goods + 1 services = 28 sectors.
%
%   Uses flat assignment: each ICIO sub-sector inherits its parent
%   WIOD sector's elasticity value.
%
%   See also: tariffwar.build_all

    % ICIO Extended 2016-2022 goods sectors (27 total) in data order:
    %  1. A01       -> WIOD 1  (Agriculture)
    %  2. A02       -> WIOD 1
    %  3. A03       -> WIOD 1
    %  4. B05       -> WIOD 2  (Mining)
    %  5. B06       -> WIOD 2
    %  6. B07       -> WIOD 2
    %  7. B08       -> WIOD 2
    %  8. B09       -> WIOD 2
    %  9. C10T12    -> WIOD 3  (Food, beverages, tobacco)
    % 10. C13T15    -> WIOD 4  (Textiles, apparel, leather)
    % 11. C16       -> WIOD 5  (Wood, paper, printing)
    % 12. C17_18    -> WIOD 5
    % 13. C19       -> WIOD 6  (Petroleum, coke)
    % 14. C20       -> WIOD 7  (Chemicals, pharma)
    % 15. C21       -> WIOD 7
    % 16. C22       -> WIOD 8  (Rubber, plastics, non-metallic minerals)
    % 17. C23       -> WIOD 8
    % 18. C24A      -> WIOD 9  (Basic metals)
    % 19. C24B      -> WIOD 9
    % 20. C25       -> WIOD 10 (Fabricated metals)
    % 21. C26       -> WIOD 11 (Computer, electronic, optical)
    % 22. C27       -> WIOD 12 (Electrical equipment)
    % 23. C28       -> WIOD 13 (Machinery & equipment)
    % 24. C29       -> WIOD 14 (Transport equipment)
    % 25. C301      -> WIOD 14
    % 26. C302T309  -> WIOD 14
    % 27. C31T33    -> WIOD 15 (Other manufacturing, repair)
    % 28. Services  -> WIOD 16 (All services collapsed)

    n_goods_expected = 27;
    if S_target ~= n_goods_expected + 1
        % Handle SML ICIO format (22 goods + 1 services = 23)
        if S_target == 23
            C = wiod16_to_icio_sml(S_target);
            return;
        end
        % Handle standard ICIO format (21 goods + 1 services = 22)
        if S_target == 22
            C = wiod16_to_icio_standard(S_target);
            return;
        end
        error('tariffwar:concordance:icioSizeMismatch', ...
            'Expected S_target = %d (ICIO Extended), 23 (SML), or 22 (standard), got %d.', ...
            n_goods_expected + 1, S_target);
    end

    % WIOD-16 to ICIO Extended mapping (each ICIO goods sector -> one WIOD sector)
    wiod_assignment = [ ...
        1;  % A01
        1;  % A02
        1;  % A03
        2;  % B05
        2;  % B06
        2;  % B07
        2;  % B08
        2;  % B09
        3;  % C10T12
        4;  % C13T15
        5;  % C16
        5;  % C17_18
        6;  % C19
        7;  % C20
        7;  % C21
        8;  % C22
        8;  % C23
        9;  % C24A
        9;  % C24B
        10; % C25
        11; % C26
        12; % C27
        13; % C28
        14; % C29
        14; % C301
        14; % C302T309
        15; % C31T33
    ];

    C = zeros(S_target, 16);
    for s = 1:n_goods_expected
        C(s, wiod_assignment(s)) = 1;
    end
    % Services aggregate -> WIOD sector 16
    C(S_target, 16) = 1;
end


function C = wiod16_to_icio_standard(S_target)
%WIOD16_TO_ICIO_STANDARD  Map for standard OECD ICIO (21 goods + 1 services).

    % Standard ICIO has 21 goods sectors (ISIC Rev 4 2-digit groups):
    %  1. 01T03  -> WIOD 1    6. 13T15 -> WIOD 4   11. 22    -> WIOD 8   16. 27   -> WIOD 12
    %  2. 05T06  -> WIOD 2    7. 16    -> WIOD 5   12. 23    -> WIOD 8   17. 28   -> WIOD 13
    %  3. 07T08  -> WIOD 2    8. 17T18 -> WIOD 5   13. 24    -> WIOD 9   18. 29   -> WIOD 14
    %  4. 09     -> WIOD 2    9. 19    -> WIOD 6   14. 25    -> WIOD 10  19. 30   -> WIOD 14
    %  5. 10T12  -> WIOD 3   10. 20T21 -> WIOD 7   15. 26    -> WIOD 11  20. 31T33-> WIOD 15
    %                                                                     21. services -> WIOD 16

    wiod_assignment = [1; 2; 2; 2; 3; 4; 5; 5; 6; 7; 8; 8; 9; 10; 11; 12; 13; 14; 14; 15];

    C = zeros(S_target, 16);
    for s = 1:numel(wiod_assignment)
        C(s, wiod_assignment(s)) = 1;
    end
    C(S_target, 16) = 1;
end


function C = wiod16_to_icio_sml(S_target)
%WIOD16_TO_ICIO_SML  Map for SML OECD ICIO 2011-2015 (22 goods + 1 services).
%
%   SML format sector codes in data order:
%    1. A01_02  -> WIOD 1  (Agriculture)   12. C21    -> WIOD 7
%    2. A03     -> WIOD 1                  13. C22    -> WIOD 8
%    3. B05_06  -> WIOD 2  (Mining)        14. C23    -> WIOD 8
%    4. B07_08  -> WIOD 2                  15. C24    -> WIOD 9
%    5. B09     -> WIOD 2                  16. C25    -> WIOD 10
%    6. C10T12  -> WIOD 3  (Food)          17. C26    -> WIOD 11
%    7. C13T15  -> WIOD 4  (Textiles)      18. C27    -> WIOD 12
%    8. C16     -> WIOD 5  (Wood)          19. C28    -> WIOD 13
%    9. C17_18  -> WIOD 5                  20. C29    -> WIOD 14
%   10. C19     -> WIOD 6  (Petroleum)     21. C30    -> WIOD 14
%   11. C20     -> WIOD 7  (Chemicals)     22. C31T33 -> WIOD 15
%                                          23. Services -> WIOD 16

    wiod_assignment = [ ...
        1; 1;               % A01_02, A03
        2; 2; 2;            % B05_06, B07_08, B09
        3;                  % C10T12
        4;                  % C13T15
        5; 5;               % C16, C17_18
        6;                  % C19
        7; 7;               % C20, C21
        8; 8;               % C22, C23
        9;                  % C24
        10;                 % C25
        11;                 % C26
        12;                 % C27
        13;                 % C28
        14; 14;             % C29, C30
        15;                 % C31T33
    ];

    C = zeros(S_target, 16);
    for s = 1:numel(wiod_assignment)
        C(s, wiod_assignment(s)) = 1;
    end
    C(S_target, 16) = 1;
end
