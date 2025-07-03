function out = table2workspace(tab,varargin)
% function out = table2workspace(table)
% function out = table2workspace(table,names)
% unpack table into workspace (or function space) variables.

if nargin<2
	varNames = tab.Properties.VariableNames;
else
	varNames = varargin{1};
end

	
inputTableName = string(inputname(1));
for v = varNames
	evalstr = join([string(v) " = " inputTableName "." string(v) ";"],"");
	evalin('caller',evalstr);
end
	
if nargout
	out = varNames;
end
end