function mask = itpd_services_mask()
%TARIFFWAR.CONCORDANCE.ITPD_SERVICES_MASK  Boolean mask for ITPD-S service sectors.
%
%   mask = tariffwar.concordance.itpd_services_mask()
%
%   Returns a 170 x 1 logical vector at ITPD-S native resolution
%   where true indicates a services sector to be collapsed.
%
%   USITC ITPD-S R01 has 170 industries:
%     1–26:    Agriculture (26 industries)
%     27–33:   Mining & Energy (7 industries)
%     34–153:  Manufacturing (120 industries)
%     154–170: Services (17 industries) → collapse into 1
%
%   See also: tariffwar.concordance.wiod_services_mask

    mask = false(170, 1);
    mask(154:170) = true;
end
