function writePhaseChords(phaseCorrMatrix,tetrodeNames)
    fid = fopen( 'phaseChords.txt','wt' );

    fprintf(fid,'var names = [');
    for i=1:length(tetrodeNames)
        if(i>1)
            fprintf(fid,',');
        end
        fprintf(fid,'''%s''',tetrodeNames{i});
    end
    fprintf(fid,'];');

    fprintf(fid,'\n\n');

    fprintf(fid,'var matrix = [\n');
    for i=1:size(phaseCorrMatrix,1)
        fprintf(fid,'[');
        for j=1:size(phaseCorrMatrix,2)
            if(j>1)
                fprintf(fid,',');
            end
            fprintf(fid,'%3.0f',phaseCorrMatrix(i,j));
        end
        fprintf(fid,']');
        if(i<size(phaseCorrMatrix,1))
            fprintf(fid,',\n');
        end
    end
    fprintf(fid,'\n];');

    % for image = 1:N
    %   [a1,a2,a3,a4] = ProcessMyImage( image );
    %   fprintf(fid, '%f,%f,%f,%f\n', a1, a2, a3, a4);
    % end
    fclose(fid);
    disp('Chord file written.')
end