%%

[y, Fs] = audioread('bgm1.mp3');
[p,q] = rat(24e2/Fs,0.0001);
y_24k = resample(y,p,q);
% y_24k_selected = y_24k(1:44*24e2);

% y_24k_selected = int32(y_24k_selected*(10000));
%y_24k = double(y_24k)/10000.0;
% y_24k_selected = y_24k_selected + 10000;
%sound(y_24k_selected,2400);
sound(y, Fs);

% %%
% % sample1 = y(17*Fs:50*Fs);
% sample2 = [] ;
% for i = 1:65530
%     sample2 = [sample2 y_24k_selected(i*10)];
% end
% 
% sample2 = int32(sample2*(2^31-1));


%%
word_size = 15;
ram_size = 105600;
%%

fileID = fopen('bgm2.mif', 'wt');
fprintf( fileID, '%s%d%s\n\r', 'WIDTH=', word_size, ';');
fprintf( fileID, '%s%d%s\n\n\r', 'DEPTH=', ram_size, ';');
fprintf( fileID, '%s\n\r', 'ADDRESS_RADIX=UNS;');
fprintf( fileID, '%s\n\n\r', 'DATA_RADIX=UNS;');
fprintf( fileID, '%s\n\r', 'CONTENT BEGIN');


% write values to file
idx = 0;

for i=1:105600
        fprintf( fileID, '%d : %d; %s\r\n', idx, y_24k_selected(i));
        fprintf(fileID, '%s\r\n', '');
        idx = idx+1;
end

fprintf( fileID, '%s\n\r', 'END;');

fclose( fileID);