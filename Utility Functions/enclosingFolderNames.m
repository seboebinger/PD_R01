function out = enclosingFolderNames(inpath,varargin)
% function out = enclosingFolderNames(in)
%
% recursively identify enclosing folder names
% useful for .mat files with metadata implemented as a directory map
%
% recursion is performed using fileparts.m, rather than with regular
% expressions; compliance with symbolic links, etc. has not been tested
%
% note trailing file separators will cause an error
%
% usage:
%
% in = '/Volumes/ting/ting-data/neuromechanics-lab/ProcessedMatlabData/K25/PDF007/Session 1/Trial06.mat'
%
% out = enclosingFolderNames(in)
%
% out =
%   9×1 string array
%     "Volumes"
%     "ting"
%     "ting-data"
%     "neuromechanics-lab"
%     "ProcessedMatlabData"
%     "K25"
%     "PDF007"
%     "Session 1"
%     "Trial06"
%
% function out = enclosingFolderNames(in,0)
% out =
%     "Trial06"
%
% function out = enclosingFolderNames(in,1)
% out =
%     "Session 1"
%
% function out = enclosingFolderNames(in,2)
% out =
%     "PDF007"
%
%
% JLM 2018 01 29

pathmap = "";
[~,inname,~] = fileparts(inpath);
while ~isempty(inname)
	[inpath,inname,inext] = fileparts(inpath);
	pathmap = [pathmap; inname];
end

pathmap(1) = []; pathmap(end) = []; pathmap = flipud(pathmap);

if nargin>1
	pathmap = pathmap(end-varargin{1});
end

if nargout
	out = pathmap;
else
	disp(pathmap)
end

end