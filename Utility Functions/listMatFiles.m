function filenames = listMatFiles(srcDir)
% function filenames = listMatFiles(srcDir)
% JLM 2018 01 29

pathname = "";
filename = "";
trialname = "";

recurseDirectory(srcDir, @catstr);

filenames = table(trialname,pathname,filename);
filenames(1,:) = [];

	function catstr(matfile)
		[pathstr,name,ext] = fileparts(matfile);
		filename = [filename; matfile];
		trialname = [trialname; name];
		pathname = [pathname; pathstr];
	end

	function recurseDirectory(name, callback)
		directory = dir(name);
		for i = 1:length(directory)
			if(~strcmp(directory(i).name,'.') && ~strcmp(directory(i).name,'..') && ~strcmp(directory(i).name,'.DS_Store'))
				if(directory(i).isdir)
					recurseDirectory([name filesep directory(i).name], callback);
				else
					callback([name filesep directory(i).name]);
				end
			end
		end
	end
end

