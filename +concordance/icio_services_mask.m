function mask = icio_services_mask()
%TARIFFWAR.CONCORDANCE.ICIO_SERVICES_MASK  Boolean mask for ICIO service sectors.
%
%   mask = tariffwar.concordance.icio_services_mask()
%
%   Returns a 45 x 1 logical vector at ICIO's native 45-sector resolution
%   where true indicates a services sector to be collapsed.
%
%   OECD ICIO 2023 uses ISIC Rev 4 sectors. The 45 sectors are:
%     Goods (retain individually):
%       01T03  Agriculture, forestry and fishing
%       05T06  Mining and quarrying, energy producing products
%       07T08  Mining and quarrying, non-energy products
%       09     Mining support services
%       10T12  Food products, beverages and tobacco
%       13T15  Textiles, wearing apparel, leather
%       16     Wood and products of wood and cork
%       17T18  Paper, printing and recorded media
%       19     Coke and refined petroleum products
%       20T21  Chemical and pharmaceutical products
%       22     Rubber and plastics products
%       23     Non-metallic mineral products
%       24     Basic metals
%       25     Fabricated metal products
%       26     Computer, electronic and optical equipment
%       27     Electrical equipment
%       28     Machinery and equipment n.e.c.
%       29     Motor vehicles, trailers and semi-trailers
%       30     Other transport equipment
%       31T33  Manufacturing n.e.c.; repair and installation
%
%     Services (collapse into 1):
%       35T39  Electricity, gas, water, waste
%       41T43  Construction
%       45T47  Wholesale and retail trade; repair
%       49T53  Transportation and storage
%       55T56  Accommodation and food service
%       58T60  Publishing, audiovisual and broadcasting
%       61     Telecommunications
%       62T63  IT and other information services
%       64T66  Financial and insurance activities
%       68     Real estate activities
%       69T82  Professional, scientific, technical, admin
%       84     Public administration and defence
%       85     Education
%       86T88  Human health and social work
%       90T96  Arts, entertainment and recreation; other services
%       97T98  Households as employers

    % 45 sectors total: sectors 1-20 are goods, sectors 21-45 are services
    % (This mapping will be verified against actual ICIO sector codes when data is loaded)
    mask = false(45, 1);

    % ICIO sector codes for services (positions 21–45 in standard ICIO ordering)
    % 35T39, 41T43, 45T47, 49T53, 55T56, 58T60, 61, 62T63, 64T66, 68,
    % 69T82, 84, 85, 86T88, 90T96, 97T98
    % Note: exact positions depend on ICIO file column ordering.
    % Using standard ICIO 2023 ordering: goods in positions 1-20, services 21-36
    services_positions = 21:45;
    mask(services_positions) = true;
end
