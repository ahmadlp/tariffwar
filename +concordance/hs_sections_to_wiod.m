function C = hs_sections_to_wiod(S_source, S_target)
%TARIFFWAR.CONCORDANCE.HS_SECTIONS_TO_WIOD  Map HS sections to WIOD 16 sectors.
%
%   C = tariffwar.concordance.hs_sections_to_wiod(S_source, S_target)
%
%   Returns an S_target x S_source concordance matrix.
%   Chain: HS sections → ISIC Rev 4 → WIOD 16.
%
%   Used for Shapiro (2016) elasticities.
%
%   See also: tariffwar.concordance.hs_to_isic4, tariffwar.concordance.wiod16_to_isic4

    % Get HS → ISIC Rev 4 mapping
    [~, ~, hs_isic4] = tariffwar.concordance.hs_to_isic4();

    % Get WIOD → ISIC Rev 4 mapping
    [wiod_map, ~] = tariffwar.concordance.wiod16_to_isic4();

    C = zeros(S_target, S_source);

    for hs = 1:S_source
        hs_codes = hs_isic4{hs};
        for w = 1:S_target
            wiod_codes = wiod_map{w};
            overlap = intersect(hs_codes, wiod_codes);
            if ~isempty(overlap)
                C(w, hs) = numel(overlap) / numel(hs_codes);
            end
        end
    end

    % Normalize columns to sum to 1
    col_sums = sum(C, 1);
    col_sums(col_sums == 0) = 1;
    C = C ./ repmat(col_sums, [S_target, 1]);
end
