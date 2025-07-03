function displayTag(src,~)
    tag = src.UserData.Tag;

    if src.UserData.DisplayTag
        % Toggle OFF: delete label and remove ONE instance from ind_selected
        if isgraphics(src.UserData.TagHandle)
            delete(src.UserData.TagHandle);
        end
        src.UserData.DisplayTag = false;

        try
            ind_selected = evalin('base', 'ind_selected');
            idx = find(strcmp(ind_selected, tag), 1); % only remove ONE
            if ~isempty(idx)
                ind_selected(idx) = [];
            end
            assignin('base', 'ind_selected', ind_selected);
        catch
            % no action needed
        end
        return
    end

    % Toggle ON: add tag and display label
    src.UserData.DisplayTag = true;

    ax = ancestor(src, 'axes');
    cp = ax.CurrentPoint(1,1:2);

    t = text(cp(1), cp(2), char(tag), ...
        'Color', src.Color, ...
        'FontSize', 12, ...
        'UserData', struct('side', 'right', 'tag', tag), ...
        'ButtonDownFcn', @deleteTag);

    src.UserData.TagHandle = t;

    try
        ind_selected = evalin('base', 'ind_selected');
    catch
        ind_selected = {};
    end

    ind_selected{end+1} = tag;
    assignin('base', 'ind_selected', ind_selected);
end
