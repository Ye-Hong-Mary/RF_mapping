%
% fuzz.m
% Returns a non-negative timing with Gaussian or uniform randomness added
% Constants will only be clamped at zero
% Uniform fuzz will have Gaussian set to false, and use Min, Max
% Gaussian fuzz with have Gaussian set to true, and use Mean, Stdev, Cutoff (i.e., how many standard deviations is the furthest before clamping)
% Gaussian fuzz with have Gaussian set to true, and use Mean, minscale, maxscale
% If a curve is specified, the reaction argument will determine the timing returned according to Min, Max, Window, and Exponent
%
function out = fuzz(timing)
    if ~isstruct(timing)
        out = timing;
    elseif isfield(timing, 'Exponential') && timing.Exponential
        % extent = timing.Cutoff * timing.Stdev;
        pd = makedist('Exponential','mu',timing.Mean);
        out = random(truncate(pd,timing.Mean * timing.Minscale,timing.Mean * timing.Maxscale));
        % out = randn() * timing.Stdev + timing.Mean;
        % out = min(max(out, timing.Mean - extent), timing.Mean + extent);
    % elseif isfield(timing, 'Curve') && timing.Curve
    %     if ~(exist('reaction', 'var') && exist('response_window', 'var'))
    %         out = timing.Max;
    %     else
    %         x = reaction / response_window;
    %         y = 1 - x .^ timing.Exponent;
    %         out = y * (timing.Max - timing.Min) + timing.Min;
    %     end
    else % Range
        out = (timing.Max - timing.Min) * rand() + timing.Min;
    end

    if out < 0
        out = 0;
    end
end
