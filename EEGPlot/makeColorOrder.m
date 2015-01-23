function colorOrder=makeColorOrder(channelClass,allCh)
    colorOrder = [];
    for i=1:length(channelClass)
        idx = find(allCh==i);
        if(channelClass(i,2) && channelClass(i,3)) %good, blue
            colorOrder(idx,:) = [.25 0 1];
        elseif(channelClass(i,2)==1 && channelClass(i,3)==0) %not plated, red
            colorOrder(idx,:) = [1 .5 .5];
        else %not connected, gray
            colorOrder(idx,:) = [.7 .7 .7];
        end
    end
end