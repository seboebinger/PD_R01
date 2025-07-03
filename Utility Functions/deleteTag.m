function deleteTag(src, ~)
% deleteTag - deletes the tag label, updates the associated line's display flag,
% and removes one instance of the tag from ind_selected in base workspace

    tag = src.String;  % the trial name string

    % Delete the text label from the figure
    delete(src);

    % Identify the axes this label was in
    ax = ancestor(src, 'axes');

    % Find the corresponding line that owns this label
    allLines = findobj(ax, 'Type', 'line');
    for i = 1:length(allLines)
        line = allLines(i);
        if isfield(line.UserData, 'TagHandle') && isequal(line.UserData.TagHandle, src)
            line.UserData.DisplayTag = false;
            line.UserData.TagHandle = [];
            break
        end
    end

    % Remove ONE instance of the tag from ind_selected in the base workspace
    try
        ind_selected = evalin('base', 'ind_selected');
        idx = find(strcmp(ind_selected, tag), 1);
        if ~isempty(idx)
            ind_selected(idx) = [];
            assignin('base', 'ind_selected', ind_selected);
        end
    catch
        % Variable does not exist or not accessible — ignore
    end
end
