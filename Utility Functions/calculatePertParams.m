function pertparams = calculatePertParams(LVDT,Accels,atime,platonset,Velocity,varargin)
% function pertparams = calculatePertParams(filename)
% 
% edited 2018 06 21 to estimate perturbation direction from accels rather
% than LVDT.

p = inputParser;
p.addOptional('pertDirDataSource',"LVDT");
p.parse(varargin{:});
pertDirDataSource = p.Results.pertDirDataSource;

% Load data.
% load(filename)

% Calculate perturbation direction from recorded data.
switch(string(pertDirDataSource))
	case "LVDT"
		Displacement = LVDT - repmat(LVDT(1,:),size(LVDT,1),1);
		
		% Determine maximum absolute displacement to calculate perturbation
		% direction. Note that this is required because the platform may be
		% returning at the end of the trial.
		[DisplacementTH,DisplacementR] = cart2pol(Displacement(:,1),Displacement(:,2));
		DisplacementTH = DisplacementTH*180/pi;
		[peakdisp, temp] = max(DisplacementR);
		pertdir_calc_deg = DisplacementTH(temp); % ****!!!! Need to modify to only calculate angle of second pert?
	case "Accels"
		pertdir_calc_deg = estimatePertDirFromAccel(Accels(:,1),Accels(:,2),atime-platonset);
	case "Markers"
		Heels = nanmean(Markers(:,ismember(deblank(string(MarkerID)),["LHEE" "RHEE"]),1:2),3);
		HeelDisplacement = Heels - repmat(nanmean(Heels(mtime<0.4,:),1),size(Heels,1),1);
		[DisplacementTH,DisplacementR] = cart2pol(HeelDisplacement(:,1),HeelDisplacement(:,2));
		DisplacementTH = DisplacementTH*180/pi;
		[peakdisp, temp] = max(DisplacementR);
		pertdir_calc_deg = DisplacementTH(temp);
		disp(string(filename)+": calculating perturbation direction based on heel marker displacement")
end

% Calculate peak perturbation displacement, velocity, and acceleration from recorded data.
try
	% Calculate displacement in direction of perturbation. For ease of reading,
	% the zeroing procedure is included again.
	Displacement = LVDT - repmat(LVDT(1,:),size(LVDT,1),1);
	DisplacementPD = Displacement(:,1)*cosd(pertdir_calc_deg) + Displacement(:,2)*sind(pertdir_calc_deg);
	pertdisp_calc_cm = max(DisplacementPD);
catch
	pertdisp_calc_cm = nan;
end

try
	% Calculate velocity in direction of perturbation.
	Velocity = Velocity - repmat(Velocity(1,:),size(Velocity,1),1);
	VelocityPD = Velocity(:,1)*cosd(pertdir_calc_deg) + Velocity(:,2)*sind(pertdir_calc_deg);
	pertvel_calc_cm_s = max(VelocityPD);
catch
	pertvel_calc_cm_s = nan;
end

try
	% Calculate acceleration in direction of perturbation.
	Acceleration = Accels - repmat(Accels(1,:),size(Accels,1),1);
	AccelerationPD = Acceleration(:,1)*cosd(pertdir_calc_deg) + Acceleration(:,2)*sind(pertdir_calc_deg);
	pertacc_calc_g = max(AccelerationPD);
catch
	pertacc_calc_g = nan;
end

pertdir_calc_round_deg = round(findnearestpertdir(pertdir_calc_deg));
pertparams = table(pertdir_calc_deg,pertdir_calc_round_deg,pertdisp_calc_cm,pertvel_calc_cm_s,pertacc_calc_g);

end


function estimatedPertDir = estimatePertDirFromAccel(Accels_X,Accels_Y,atime)

Accels_X = Accels_X(:)';
Accels_Y = Accels_Y(:)';
atime = atime(:)';

Accels_X = Accels_X - nanmean(Accels_X(atime<0));
Accels_Y = Accels_Y - nanmean(Accels_Y(atime<0));

[Accels_Rad,Accels_R] = cart2pol(Accels_X,Accels_Y);
Accels_Deg = Accels_Rad * 180/pi;

% get rid of deceleration phase
Accels_Deg(atime>0.300) = [];
Accels_R(atime>0.300) = [];

estimatedPertDir = Accels_Deg(Accels_R==max(Accels_R));

end
