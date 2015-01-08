function locs=absPeakDetection(data)

    figure;
    plot(data(1:10000));
    [x,y] = ginput;
    close;

    if(y>0)
        multiplier = 1;
    else
        multiplier = -1;
    end

    [~,locs] = findpeaks(data.*multiplier,'minpeakheight',abs(y),'minpeakdistance',60,'threshold',5);

    figure;
    plot(data);
    hold on;
    
    for i=1:length(locs);
        plot(locs(i),data(locs(i)),'o','color','r');
    end
    % plot all the spikes as sanity check
    figure;
    all = [];
    for i=1:length(locs)
        hold on;
        plot(data(1,locs(i)-20:locs(i)+20));
        all(i,:) = data(1,locs(i)-20:locs(i)+20);
    end

    disp(strcat('spikes: ',int2str(length(locs))));
end