function filenames = generatefilenames(srcDir)

% list the mat files under this root directory (go down)
% srcDir = '/Volumes/ting/ting-data/neuromechanics-lab/ProcessedMatlabData/K25'
filenames = listMatFiles(srcDir);

% isolate vicon id and session names for each .mat file (for each mat file
% go back up)
sessionname = "";
viconid = "";
for f = filenames.filename'
	sessionname = [sessionname;enclosingFolderNames(char(f),1)];
	viconid = [viconid;enclosingFolderNames(char(f),2)];
end
sessionname(1) = [];
viconid(1) = [];

filenames.sessionname = sessionname;
filenames.viconid = viconid;

end