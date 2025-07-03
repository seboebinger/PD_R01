function out = expandNames3D(in)
% function out = expandNames3D(in)
% 
% append _X _Y _Z to a list of strings

in = in(:)';
out = [in' + "_X" in' + "_Y" in' + "_Z" ];
out = out';
out = out(:)';

end
