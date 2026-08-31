try
    model = 'ETS_Model';
    load_system(model);
    % Try to arrange
    Simulink.BlockDiagram.arrangeSystem([model '/PMSM_Motor']);
    disp('Arrange System worked');
catch e
    disp(e.message);
end
exit;
