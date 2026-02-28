function C = isic3_to_itpd(S_source, S_target)
%TARIFFWAR.CONCORDANCE.ISIC3_TO_ITPD  Map ISIC Rev 3 sectors to ITPD-S sectors.
%
%   C = tariffwar.concordance.isic3_to_itpd(S_source, S_target)
%
%   Returns an S_target x S_source concordance matrix.
%   Chain: ISIC Rev 3 → ISIC Rev 4 → ITPD-S.
%
%   See also: tariffwar.concordance.isic3_to_isic4

    error('tariffwar:concordance:notImplemented', ...
        'isic3_to_itpd concordance not yet implemented. Requires ITPD-S sector definitions.');
end
