function mask = wiod_services_mask()
%TARIFFWAR.CONCORDANCE.WIOD_SERVICES_MASK  Boolean mask for WIOD service sectors.
%
%   mask = tariffwar.concordance.wiod_services_mask()
%
%   Returns a 16 x 1 logical vector where true indicates a services sector.
%   In the WIOD 16-sector aggregation:
%     Sectors 1–15: goods (agriculture, mining, manufacturing)
%     Sector 16: services (aggregate of NACE Rev 2 sectors 36–98)
%
%   See also: tariffwar.concordance.icio_services_mask

    mask = false(16, 1);
    mask(16) = true;
end
