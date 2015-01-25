function [ ] = makeWireHeaderForArrayRecording( hsdfilename )

hd = getHSDHeader(hsdfilename);
hd.channel.channel_type(1:66) = 3;
writeHSDheader_ver2( hsdfilename, hd);
disp(['Changed header in ' hsdfilename]);
end

