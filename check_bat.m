try
    model = 'ETS_Model';
    load_system(model);
    b = get_param([model '/Battery'], 'DialogParameters');
    v = get_param([model '/Battery'], 'Amplitude');
    fprintf('Battery Amplitude: %s\n', v);
catch e
    disp(e.message);
end
exit;
