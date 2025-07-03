function out = workspace2table(names)
% function out = workspace2table(names)
% 
% creates a table out of workspace variables when names are stored as a
% cell array
% 
% names = {'tom' 'dick' 'harry'}
% tab = workspace2table(names)

out = evalin('caller',join(["table(" join(string(names),',') ")"],""));
end