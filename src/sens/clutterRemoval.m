function h = clutterRemoval(h, varargin)
% CLUTTERREMOVAL Remove low frequency components of slow time signal
%   
%   h = clutterRemoval(h) remove the clutters from the MxN input slow time
%   signals being M the lenght of the slow time signal and N the number of 
%   slow time signals and return the MxN filtered signal. 
%   Defualt method is DC blocker (remove the dc component of the signal)

%   2024 NIST/CTL Steve Blandino, Neeraj Varshney

%   This file is available under the terms of the NIST License.

%% Varargin processing 
p = inputParser;

defaultMethod = 'remove_static_component';
validMethod = {'remove_static_component','recursive_first_order_hp', 'none'};
checkMethod = @(x) any(validatestring(x,validMethod));
defaultAlpha = 0.85;

addOptional(p,'method',defaultMethod,checkMethod)
addOptional(p,'alpha',defaultAlpha,@isnumeric)

parse(p,varargin{:});

%% Clutter removal
switch p.Results.method
    case 'remove_static_component'
        hclutter = mean(h);
        %% Remove static channel
        h = h- hclutter;
    case 'recursive_first_order_hp'
        y(1,:) = h(1,:);
        for i = 2:size(h,1)
            y(i,:) = h(i,:) - h(i-1,:) + p.Results.alpha * y(i-1,:);
        end
        h = y;
     
end
end