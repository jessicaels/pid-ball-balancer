function pid_realtime_monitor()
    % Bersihkan workspace dan tutup semua figure
    clear all;
    close all;
    clc;
    
    % Inisialisasi koneksi serial
    port = 'COM12'; % Ganti dengan port Arduino Anda
    baudrate = 9600;
    
    try
        arduinoObj = serialport(port, baudrate);
        configureTerminator(arduinoObj, "LF");
        flush(arduinoObj);
        disp(['Berhasil terhubung ke port ' port]);
    catch ME
        error('Gagal terhubung: %s', ME.message);
    end
    
    % Setup figure untuk plotting
    fig = figure('Name', 'PID Controller Monitoring', ...
                 'NumberTitle', 'off', ...
                 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    hDist = animatedline('Color', 'b', 'LineWidth', 1.5);
    title('Pembacaan Sensor Ultrasonik (cm)');
    xlabel('Waktu (detik)');
    ylabel('Jarak (cm)');
    grid on;
    ylim([0 35]);
    xlim([0 10]);
    
    subplot(2,1,2);
    hServo = animatedline('Color', 'r', 'LineWidth', 1.5);
    title('Posisi Servo');
    xlabel('Waktu (detik)');
    ylabel('Sudut (derajat)');
    grid on;
    ylim([0 180]);
    xlim([0 10]);
    
    % Variabel data
    maxPoints = 1000;
    timeData = zeros(maxPoints, 1);
    distData = zeros(maxPoints, 1);
    servoData = zeros(maxPoints, 1);
    dataCount = 0;
    
    % Untuk smoothing opsional
    windowSize = 5;
    
    startTime = tic;
    running = true;
    fig.CloseRequestFcn = @(,) stopMonitoring();
    
    while running
        if arduinoObj.NumBytesAvailable > 0
            try
                data = readline(arduinoObj);
                values = sscanf(data, '%f,%f');
                
                if numel(values) == 2
                    dataCount = dataCount + 1;
                    currentTime = toc(startTime);
                    
                    idx = mod(dataCount-1, maxPoints) + 1;
                    timeData(idx) = currentTime;
                    distData(idx) = values(1);
                    servoData(idx) = values(2);
                    
                    % Smoothing di MATLAB (opsional)
                    if dataCount > windowSize
                        smoothDist = mean(distData(max(1, idx - windowSize + 1):idx));
                        smoothServo = mean(servoData(max(1, idx - windowSize + 1):idx));
                    else
                        smoothDist = values(1);
                        smoothServo = values(2);
                    end
                    
                    % Update plots
                    addpoints(hDist, currentTime, smoothDist);
                    addpoints(hServo, currentTime, smoothServo);
                    
                    % Scrolling plot
                    if currentTime > 10
                        subplot(2,1,1);
                        xlim([currentTime-10 currentTime]);
                        subplot(2,1,2);
                        xlim([currentTime-10 currentTime]);
                    end
                    
                    drawnow limitrate;
                end
            catch
                continue;
            end
        end
        
        running = ishandle(fig);
    end
    
    function stopMonitoring()
        disp('Menghentikan monitoring...');
        clear arduinoObj;
        delete(fig);
        running = false;
    end
end

