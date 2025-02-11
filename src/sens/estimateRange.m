function [rEst,timeShift,idR] =  estimateRange(discreteMicroDopplerTime,slowTimeGrid,...
    fastTimeGrid, syncPoint, t0, varargin)
%%ESTIMATERANGE Target estiamated velocity
%
%   R = ESTIMATERANGE(D,STGRID,FTGRID, T0, TOF) return the range R of the 
%   target over time (T x 1), given the micro doppler mask over time D 
%   (FFT x FastTime x T) the slowtime sampling points STGRID (Tx1) the fast
%   time samples FTGRID (FFT x 1) PHY sync point T0 and time of flight TOF 
%   obtained from FTM.
%
%   R = ESTIMATERANGE(..., 'method', value) specifies the estimation method
%   as 'max' (default), 'mean' or 'max+filter'.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Varargin processing
p = inputParser;

defaultMethod = 'max';
validMethod = {'max','mean', 'max+filter'};
checkMethod = @(x) any(validatestring(x,validMethod));

addOptional(p,'method',defaultMethod,checkMethod)

parse(p,varargin{:});
fastTimeGrid = fastTimeGrid(:).';
slowTimeGrid = slowTimeGrid(:).';

assert(size(discreteMicroDopplerTime,2) == length(fastTimeGrid), 'Input must be the same length')
assert(size(discreteMicroDopplerTime,3) == length(slowTimeGrid), 'Input must be the same length')

c = getConst('lightSpeed');
%%
timeShift = fastTimeGrid(syncPoint+1)-t0{2}(1); % Hardcoded : no multi STA, STA not moving
fastTimeAbs = fastTimeGrid-timeShift; 
[~, t] = meshgrid(slowTimeGrid,fastTimeAbs);
rangeTime = permute(sum(discreteMicroDopplerTime,1), [2 3 1]);

switch p.Results.method
    case 'mean'
        t(rangeTime==0) = 0;
        rEst = sum(t)./(length(fastTimeGrid)-sum(t==0))*c;

    case 'max'
        [~, mt] = max(rangeTime,[], 1);
        rEst =fastTimeAbs(mt)*c;
        
    case 'max+filter'
		[~, mt] = max(rangeTime,[], 1);
        rEst = fastTimeAbs(mt)*c;
        filtLen = 3;
        sigLen = length(rEst);
        % Add samples to compensate for ramp and tail
        rEst = [rEst(1)*ones(1, filtLen-1), rEst, rEst(end)*ones(1, filtLen-1)];
        % Filter
        rEst = conv(rEst, getSmoothingFilter('movingAverage', [filtLen,1],1));
        % Remove initial ramp and tail
        rEst = rEst(filtLen: filtLen+sigLen-1);
end
idR = any(rangeTime);
rEst(~idR) = NaN;
end