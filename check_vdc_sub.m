try
    model = 'ETS_Model';
    load_system(model);
    blocks = find_system([model '/V_DC'], 'SearchDepth', 1);
    for i=1:length(blocks)
        fprintf('%s\n', blocks{i});
    end
catch e
    disp(e.message);
end
exit;
