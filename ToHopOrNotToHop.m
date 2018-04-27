clc; clear; close all;
load('PowerCircle.mat');

% Rounds to run for completing a marathon
a=200; % horizontal radius of ellipse shaped race track
b=40;  % vertical radius
x0=0;  % x0,y0 ellipse centre coordinates
y0=0;
circumference = 2*pi*sqrt((1/2)*(a^(2)+b.^(2))); %906.1739m
Marathon = 42195; %meters
Rounds   = round(Marathon/circumference); %47

% 12km/h = 3.333m/s
% 4 packages/sec => 0.833m/package
% 897.4624m / 0.417m = 1.077*10^3 packages
% 2pi / 1.077*10^3 = 5.834*10^-3
% Interval giving a package signal strength measurement at each package
t=-pi:0.005778:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);

P_TrackSignal_All_Rounds_Base = zeros(length(t), Rounds);
P_TrackSignal_All_Rounds_Combined = zeros(length(t), Rounds);
%% Fading FF=Fast fading, SF= slow fading  
%Fast Fading 250ms fast fading effect
for r=1:Rounds
mu = 35+30; %+30 from dBW to dBmW
sigma = 2.22;
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

x1 = [x_ellipse+N];
P_TrackSignal_temp_Base = PAir_f(round(x_ellipse+N),round(y_ellipse+N));
P_TrackSignal_Base      = diag(P_TrackSignal_temp_Base)';
P_TrackSignal_Base      = [P_TrackSignal_Base(272:length(P_TrackSignal_Base-1)) P_TrackSignal_Base(1:271)]; 
P_TrackSignal_All_Rounds_Base(:,r) = P_TrackSignal_Base; 

P_TrackSignal_temp_Combined = PAirCombined_sf(round(x_ellipse+N),round(y_ellipse+N));
P_TrackSignal_Combined      = diag(P_TrackSignal_temp_Combined)';
P_TrackSignal_Combined      = [P_TrackSignal_Combined(272:length(P_TrackSignal_Combined-1)) P_TrackSignal_Combined(1:271)]; 
P_TrackSignal_All_Rounds_Combined(:,r) = P_TrackSignal_Combined; 
end

filename = 'ToHopOrNotToHop.mat';
save(filename);

%% Plotting Signal Range in AIR for 0dBm
Samples = linspace(1,length(t),length(t)); %Helpers
RoundsC = linspace(1,Rounds,Rounds);       %Helpers

figure(1)
hold on
plot(Samples,P_TrackSignal_Base)
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Number of Samples for ONE track lab')
ylabel('Signal Strength in dBm')
legend('RSSI at each package along ONE track round','Location','southwest');
hold off

figure(2)
hold on
surf(Samples,RoundsC,P_TrackSignal_All_Rounds_Base')
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;
legend('RSSI at each package along 47 track rounds','Location','southwest');
hold off

figure(3)
hold on
surf(Samples,RoundsC,P_TrackSignal_All_Rounds_Combined')
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'COMBINED-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;
legend('RSSI at each package along 47 track rounds','Location','southwest');
hold off