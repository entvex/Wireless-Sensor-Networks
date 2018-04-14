clc; clear;

max_datarate   = 250*1000*8;                 %250k-byte Telos_B datasheet
packagesize    = 128*1000*8;                 %128k-byte WSN Problem Description
TransmitPeriod = packagesize/max_datarate;   %Second

time       = 1;                              %Second
latency    = 6*10^(-3);                      %Seconds
sleep_duty = time-TransmitPeriod*time;       %Sleep period for one package every second
R = 1;                                       %Measurement Shunt-Resistance

I_tx_max  = 18.3*10.^(-3);                   %Transmit current
I_tx_min  = I_tx_max-4*10.^(-6);             %I_tx_max - 24dBm
I_rx      = 23.0*10.^(-3);                   %Receive Current
I_sleep   = 1*10.^(-6);                      %Sleep current

Ptx_max   = I_tx_max*R^(2) * TransmitPeriod; %Transmit Power
Ptx_min   = I_tx_min*R^(2) * TransmitPeriod; %Transmit Power
Prx       = I_rx*R^(2) * TransmitPeriod;     %Receive Power 
Ptsleep   = I_sleep*R^(2) * TransmitPeriod;  %Sleep Power
Ptx_Total_max = Ptx_max + Ptsleep;           %Power without the sleep overshoot power
Ptx_Total_min = Ptx_min + Ptsleep;
P_Total_max   = Ptx_Total_max + Prx;         %Total receive and transmitting power
P_Total_min   = Ptx_Total_min + Prx;         %Total receive and transmitting power

%% LIFETIME CALCULATIONS Overshoot -os = overshoot
os_time       = 0.05; %sec 
os_Persentage = 0.4;
os_Top        = Ptx_max * os_Persentage;
os_center     = os_time/2; %sec

x = [0:.001:os_time];
f = os_Top * exp(-((x-os_center).^(2)/0.0001));
fun = @(x) os_Top * exp(-((x-os_center).^(2)/0.0001));
OS_power = integral(fun,0,os_time);

figure(1)
plot(x,f);
title('Gaussian distribution of a voltage peak after node wakeup')
xlabel('time(sec)') % x-axis label
ylabel('Voltage over 1 Ohm ') % y-axis label

% AA Battery https://en.wikipedia.org/wiki/AA_battery "RAM"
V  = 1.5;
Ah = 2*2600*10^(-3); %mAh for two batteries
BatteryPower = V*Ah;

%Lifetime results
powerTime_nosleep     = BatteryPower/(I_tx_max*R^(2))         %Lifetime in hours //Only Transmitting
powerTime_noOvershoot = BatteryPower/Ptx_Total_max            %Lifetime in hours //Transmitting and sleeping
powerTime_Overshoot   = BatteryPower/(Ptx_Total_max+OS_power) %Lifetime in hours //Transmitting and sleeping with overshoot!
powerTimeTotal        = BatteryPower/(P_Total_max+OS_power)   %Lifetime in hours //Transmitting and sleeping with overshoot!

