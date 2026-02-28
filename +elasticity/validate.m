function validate(epsilon, S, services_sector)
%TARIFFWAR.ELASTICITY.VALIDATE  Validate an elasticity vector.
%
%   tariffwar.elasticity.validate(epsilon, S, services_sector)
%
%   Checks that epsilon is an S x 1 vector with all positive values.

    if ~isnumeric(epsilon) || ~isvector(epsilon)
        error('tariffwar:elasticity:notVector', 'Elasticity must be a numeric vector.');
    end
    if numel(epsilon) ~= S
        error('tariffwar:elasticity:wrongSize', ...
            'Elasticity vector has %d elements, expected %d (S).', numel(epsilon), S);
    end
    if any(epsilon <= 0)
        error('tariffwar:elasticity:nonPositive', 'All elasticity values must be positive.');
    end
    if nargin >= 3 && ~isempty(services_sector)
        if services_sector < 1 || services_sector > S
            error('tariffwar:elasticity:invalidServicesSector', ...
                'services_sector (%d) must be between 1 and S (%d).', services_sector, S);
        end
    end
end
