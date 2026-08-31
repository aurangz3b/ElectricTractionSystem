try
    load_system('powerlib');
    blocks = find_system('powerlib/Elements');
    for i=1:length(blocks)
        disp(blocks{i});
    end
catch e
    disp(e.message);
end
exit;
