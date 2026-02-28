function list_sources()
%TARIFFWAR.ELASTICITY.LIST_SOURCES  Print available elasticity sources.
%
%   tariffwar.elasticity.list_sources()

    reg = tariffwar.elasticity.registry();

    fprintf('\nAvailable elasticity sources:\n');
    fprintf('%-40s  %-12s  %-8s  %s\n', 'Name', 'Classification', 'Ready', 'Label');
    fprintf('%s\n', repmat('-', 1, 100));
    for i = 1:numel(reg)
        if reg(i).implemented
            status = 'YES';
        else
            status = 'stub';
        end
        fprintf('%-40s  %-12s  %-8s  %s\n', ...
            reg(i).name, reg(i).classification, status, reg(i).label);
    end
    fprintf('\n');
end
