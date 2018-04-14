clc; clear; close all;

%-94dBm is antenna receiver sensitivity
%-84dBm is chosen to give room for unexpected noise sources!
acc_dBm = -84;            %Accepted received power

R = 1;                    %Measurement Shunt-Resistance
I_tx_max = 1*10.^(-3);    %Transmit current
I_tx_min = 4*10.^(-6);    %I_tx_max - 24dBm
Ptx_max = I_tx_max*R^(2); %Transmit Power
Ptx_min = I_tx_min*R^(2); %Transmit Power

% Antennasize = 2.7cm and freq = 2.4GHz
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator  
d0     = 0.01167;    %(meter) estimation of the Far Field distance for the TelosB antenna

N = 200; %meter from the base station "half of a racetrack width"
x = linspace(-N,N,N*2+1);  
y = linspace(-N,N,N*2+1);  
[X,Y] = meshgrid(x,y);
%% 0dBm = max power, -24dBm = min power, Runner running at 12km/h ? 1m/333ms
%  AIR = 2
gammaAIR = 2;
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice = (2*94+5.5*6)/100; %2.21

%BaseStation
d = sqrt(X.^(2)+Y.^(2));    %euclidean distance
d((N*2)/2+1,(N*2)/2+1) = 1; %to avoid inf number in the center!

PAir_W = Ptx_max.*((d0./d).^gammaAIR); %Watt
PAir   = 10*log10(PAir_W/0.001);       %dBm

%NorthSation
dNorth = sqrt((X-40).^(2)+Y.^(2)); %euclidean distance     
dNorth((N*2)/2+1,(N*2)/2+41) = 1;  %to avoid inf number in the center!  

PAirNorth_W = Ptx_max.*((d0./dNorth).^gammaAIR); %Watt
PAirNorth   = 10*log10(PAirNorth_W./0.001);      %dBm

%SouthStation
dSouth = sqrt((X+40).^(2)+Y.^(2));  %euclidean distance
dSouth((N*2)/2+1,(N*2)/2-39) = 1;   %to avoid inf number in the center!

PAirSouth_W = Ptx_max.*((d0./dSouth).^gammaAIR); %dBm
PAirSouth   = 10*log10(PAirSouth_W./0.001);      %Watt         
                         
%Combination of stations
PAirCombined = 10*log10((PAir_W + PAirNorth_W + PAirSouth_W)./0.001); %dBm

% Rounds to run for completing a marathon
a=198; % horizontal radius of ellipse shaped race track
b=40;  % vertical radius
x0=0;  % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.021:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);

circumference = 2*pi*sqrt((1/2)*(a^(2)+b.^(2))); %897.4624m
Marathon = 42195; %meters
Rounds   = round(Marathon/circumference); %47
P_TrackSignal_All_Rounds_Base = zeros(length(t), Rounds);
P_TrackSignal_All_Rounds_Combined = zeros(length(t), Rounds);
%% Fading FF=Fast fading, SF= slow fading  
%Fast Fading 250ms fast fading effect
for r=1:Rounds
mu = 35+30; %+30 from dBW to dBm
sigma = 5;
X_ff = normrnd(mu,sigma,[length(x),length(y)]);
X_randff = rand(length(x),length(y)) < 0.1;
ff = -(X_randff.*X_ff);

%North
X_ff_north = normrnd(mu,sigma,[length(x),length(y)]);
X_randff_north = rand(length(x),length(y)) < 0.1;
ff_north = -(X_randff_north.*X_ff);

%South
X_ff_south = normrnd(mu,sigma,[length(x),length(y)]);
X_randff_south = rand(length(x),length(y)) < 0.1;
ff_south = -(X_randff_south.*X_ff);

%Slow Fading 10sec effect
X_sf = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf = rand(length(x),length(y)) < 0.1;
X_Coor = find(X_randsf > 0.5);

for i=1:length(X_Coor)
   if X_Coor(i) < 22
      X_Coor(i) = 22;
   end
end

X_randsf(X_Coor-21:X_Coor+21)=1; %10sec slow fading effect
sf = -(X_randsf.*X_sf);

%NORTH
X_sf_north = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf_north = rand(length(x),length(y)) < 0.1;
X_Coor_north = find(X_randsf_north > 0.5);

for i=1:length(X_Coor_north)
   if X_Coor_north(i) < 22
      X_Coor_north(i) = 22;
   end
end

X_sf_north(X_Coor_north-21:X_Coor_north+21)=1; %10sec slow fading effect
sf_north = -(X_sf_north.*X_sf_north);

%SOUTH
X_sf_south = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf_south = rand(length(x),length(y)) < 0.1;
X_Coor_south = find(X_randsf_south > 0.5);

for i=1:length(X_Coor_south)
   if X_Coor_south(i) < 22
      X_Coor_south(i) = 22;
   end
end

X_sf_south(X_Coor_south-21:X_Coor_south+21)=1; %10sec slow fading effect
sf_south = -(X_sf_south.*X_sf_south);

PAir_f = PAir + sf + ff;
PAirNorth_f = PAirNorth + sf_north + ff_north;
PAirSouth_f = PAirSouth + sf_south + ff_south;
PAir_W_f      = 10.^(PAir_f./10);
PAirNorth_W_f = 10.^(PAirNorth_f./10);
PAirSouth_W_f = 10.^(PAirSouth_f./10);

PAirCombined_sf = 10*log10((PAir_W_f + PAirNorth_W + PAirSouth_W)./0.001); %dBm
PAirCombined_sf_All_Noisy = 10*log10((PAir_W_f + PAirNorth_W_f + PAirSouth_W_f)./0.001); %dBm

P_TrackSignal_temp_Base = PAir_f(round(x_ellipse+200),round(y_ellipse+200));
P_TrackSignal_Base      = diag(P_TrackSignal_temp_Base)';
P_TrackSignal_All_Rounds_Base(:,r) = P_TrackSignal_Base; 

P_TrackSignal_temp_Combined = PAirCombined_sf(round(x_ellipse+200),round(y_ellipse+200));
P_TrackSignal_Combined     = diag(P_TrackSignal_temp_Combined)';
P_TrackSignal_All_Rounds_Combined(:,r) = P_TrackSignal_Combined; 
end

filename = 'ToHopOrNotToHop.mat';
save(filename);

%% Plotting Signal Range in AIR for 0dBm
Samples = linspace(1,length(t),length(t)); %Helpers
RoundsC = linspace(1,Rounds,Rounds);       %Helpers

figure(1)
hold on
pcolor(x,y,PAir_f)
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(2)
hold on
plot(Samples,P_TrackSignal_Base)
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Number of Samples for ONE track lab')
ylabel('Signal Strength in dBm')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(3)
hold on
surf(Samples,RoundsC,P_TrackSignal_All_Rounds_Base')
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(4)
hold on
surf(Samples,RoundsC,P_TrackSignal_All_Rounds_Combined')
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'COMBINED-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off
