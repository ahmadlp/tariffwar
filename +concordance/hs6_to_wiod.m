function C = hs6_to_wiod(S_source, S_target)
%TARIFFWAR.CONCORDANCE.HS6_TO_WIOD  Map HS6 sectors to WIOD 16 sectors.
%
%   C = tariffwar.concordance.hs6_to_wiod(S_source, S_target)
%
%   For Fontagne (2022) elasticities. Requires HS6→ISIC Rev 4 mapping
%   and pre-aggregation of ~5000 HS6 products to sector-level averages.
%
%   See also: tariffwar.concordance.hs_to_isic4

    error('tariffwar:concordance:notImplemented', ...
        'hs6_to_wiod concordance not yet implemented. Download HS6 classification first.');
end
