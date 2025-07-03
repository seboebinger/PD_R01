function outputhandle = plotij(m,n,i,j)
% function h = plotij(m,n,i,j)
% Makes the (i,j)th subplot of an (m,n) subplot figure active.  I have no idea
% why Matlab orders the subplots this way by default.

p = [];
for i_ind = i
    for j_ind = j
        p(end+1) = sub2ind([n,m],j_ind,i_ind);
    end
end

% p = sub2ind([n,m],j,i);
subplot(m,n,p);
h = gca;

if nargout>0
    outputhandle = h;
end
end