function pd_out = findnearestpertdir(pd_in,pd_list)
% function pd_out = findnearestpertdir(pd_in)
% 
% finds nearest perturbation direction from an optional list of
% perturbation directions. e.g., 359.2° is mapped to 0°. The default
% pd_list is 0:30:330.
% 
% function pd_out = findnearestpertdir(pd_in,pd_list)
% also works with a user-supplied list of perturbation directions.
% JLM Nov 3 2014

if nargin<2
    pd_list = 0:30:330;
end

% ensure conformable matrices, in radians.
pd_in = pd_in(:)*pi/180;
pd_list = pd_list(:)*pi/180;

% calculate cartesian coordinates
[x_in, y_in] = pol2cart(pd_in(:),1);
[x_list, y_list] = pol2cart(pd_list(:),1);

% calculate distance between each input direction and each actual
% direction.
pd_out = nan(length(pd_in),1);
for i = 1:length(pd_in)

    distmetric = nan(length(pd_list),1);
    for j = 1:length(pd_list)
        distmetric(j) = ((x_in(i)-x_list(j))^2+(y_in(i)-y_list(j))^2)^0.5;
    end

    [~,minind] = min(distmetric);
    
    pd_out(i) = pd_list(minind);
end

% make sure missing values are perpetuated through to output
pd_out(isnan(pd_in)) = nan;

% convert output values to degrees
pd_out = pd_out*180/pi;

% get rid of nan values
pd_out(isnan(pd_in)) = nan;

end
