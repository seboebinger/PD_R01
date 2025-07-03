function h = plot_tag(x,y,tag,varargin)
% function h = plot_tag(x,y,tag)
%
% plots x and y values, includes functionality for a tag that toggles on and off when
% the plot is clicked. useful for identifying outlier traces. requires displayTag.m
% 
% usage:
% x = linspace(0,2*pi,100);
% y = [cos(x); sin(x)];
% labels = strvcat('cos x','sin x');
% for i = 1:2
% 	plot_tag(x,y(i,:),labels(i,:))
% end
% 
%
% JLM 2017 09 05
p = plot(x,y,varargin{:});
p.UserData.Tag = deblank(char(tag));
p.UserData.DisplayTag = false;
p.UserData.TagHandle = [];
p.ButtonDownFcn = @displayTag;
if nargout
	h = p;
end
end