function cma=commonModeAverage(data)
    cma = data(1,:);
    for i=2:size(data,1)
        cma = mean([cma;data(i,:)]);
    end
end