% Kaiser window
fpass = 0.2;
fstop = 0.23;
fcuts = [fpass fstop];
mags = [1 0];
devpass = 0.01;
devstop = 10^(-80/20);
devs = [devpass devstop];

[n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs);

% Fir Filter Taps
h = fir1(n, Wn, kaiser(n+1, beta));
h_q = fi(h, 1, 19, 18); % Quantized Coefficients

% Visualization
fvtool(h);
fvtool(double(h_q));

h_int = h_q.int;

fid = fopen('taps.vh','w');
fprintf(fid, 'reg signed [19:0]   taps [%d:0];\n', n);
fprintf(fid, 'initial begin\n');
for i = 1:(n+1)
    fprintf(fid, '    taps[%d] = 19''sd%d;\n', i-1, h_int(i));
end
fprintf(fid, 'end');
fclose(fid);