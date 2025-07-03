function out = names2table(names)
% function out = names2table(names)
% 
% names = {'tom' 'dick' 'harry'}
% create a blank table, e.g., names2table(names)

out = cell2table(cell(0,length(names)));
out.Properties.VariableNames = names;
end