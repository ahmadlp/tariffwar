function C = isic3_to_icio(S_source, S_target)
%TARIFFWAR.CONCORDANCE.ISIC3_TO_ICIO  Map ISIC Rev 3 sectors to ICIO sectors.
%
%   C = tariffwar.concordance.isic3_to_icio(S_source, S_target)
%
%   Returns an S_target x S_source concordance matrix.
%   ICIO uses ISIC Rev 4, so the chain is: ISIC Rev 3 → ISIC Rev 4 → ICIO.
%
%   See also: tariffwar.concordance.isic3_to_isic4

    error('tariffwar:concordance:notImplemented', ...
        'isic3_to_icio concordance not yet implemented. Requires ICIO sector definitions.');
end
