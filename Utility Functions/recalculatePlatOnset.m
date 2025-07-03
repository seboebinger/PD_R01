function platonset = recalculatePlatOnset(Accels,atime,varargin)

p = inputParser;
p.addOptional('PLOTFLAG',false);
p.addOptional('bkgdend',0.4);
p.addOptional('numsd',12);
p.parse(varargin{:});

% load the data
%load(fname)

if exist('platonset') == 1
	platonset_orig = platonset;
	platonset = nan;
else
	[platonset_orig,platonset] = deal(nan);
end

% calculate acceleration magnitude and smooth with savitsky-golay (4th
% order, 301-sample window)
A = (Accels(:,1).^2 + Accels(:,2).^2);

% [a adot adot] = sgolaydiff(A,4,301);
% 
% bkgdwin = atime<p.Results.bkgdend;
% 
% bkgdmn = nanmean(A(bkgdwin));
% bkgdsd = nanstd(A(bkgdwin));
% 
% % standardize acceleration magnitude
% A = (A - bkgdmn)./bkgdsd;
% 
% NUMSD = p.Results.numsd;
% 
% onsetind = find(A>NUMSD,1,'first');
%platonset = atime(onsetind);
%platonset = atime(findchangepts(A,'Statistic','rms'));
% a(isnan(a))=0;
% platonset = atime(findchangepts(a));
[pks locs]= findpeaks(A/max(A),'MinPeakProminence',0.6,'NPeaks',1);
platonset = atime(find(A(1:locs)<=.001,1,'last'));
% plot(a)
% hold on
% xline(find(islocalmin(a(1:locs)),1,'last'))


if isempty(platonset)
    platonset=nan; 
end

if p.Results.PLOTFLAG
	XL = [0 2];
	figure
	subplot(2,1,1)
	plot(atime,Accels)
	xline(platonset)
% 	xlim(XL)

	subplot(2,1,2)
	plot(atime,A)
	xline(platonset)
% 	xlim(XL)

end

end
