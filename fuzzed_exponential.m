function timing = fuzzed_exponential(mean_ms, minscale,maxscale)
    timing = struct('Exponential', true, 'Mean', mean_ms, 'Minscale', minscale, 'Maxscale', maxscale);
end