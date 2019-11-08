function baselineState = algorithm_baselineState(cursor, baselineCursorThreshold)
if cursor < baselineCursorThreshold
    baselineState = 1;
else baselineState = 0;
end

end