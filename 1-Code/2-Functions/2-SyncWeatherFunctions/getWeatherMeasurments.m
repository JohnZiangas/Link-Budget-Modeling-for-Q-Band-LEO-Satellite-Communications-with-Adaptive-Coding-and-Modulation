function processedDataTable = getWeatherMeasurments(dataFolder)
%GETWEATHERMEASURMENTS  Import and organize raw weather station data from Excel files.
%
% This function:
%   1. Verifies that the given data folder exists.
%   2. Reads all matching Excel files (e.g., NOAAN*.xlsx) and processes all sheets.
%   3. Handles two-row column headers by merging them into single descriptive names.
%   4. Creates MATLAB-valid variable names while keeping original meaning.
%   5. Organizes all measurements by date for easy access later.
%
% INPUT:
%   dataFolder : Path to folder containing the raw weather station Excel files.
%
% OUTPUT:
%   processedDataTable : Table with columns:
%       - File        : Name of the source Excel file
%       - Sheet       : Sheet name inside the Excel file
%       - DataByDate  : Table for each sheet, with 'Date' and 'AllMeasurements'
%
% NOTES:
%   The Excel files are expected to have two header rows that define column names.
%
% Excel file column definitions:
%
%  1. Date          - Calendar date of the measurement (typically dd/MM/yyyy or similar format)
%  2. Time          - Time of day for the measurement (hh:mm or hh:mm:ss)
%  3. Temp Out      - Outdoor air temperature (°C or °F, depending on station settings)
%  4. Hi Temp       - Highest recorded outdoor temperature for the period
%  5. Low Temp      - Lowest recorded outdoor temperature for the period
%  6. Out Hum       - Outdoor relative humidity (%)
%  7. Dew Pt.       - Dew point temperature (°C or °F)
%  8. Wind Speed    - Instantaneous wind speed at the time of measurement
%  9. Wind Dir      - Wind direction (degrees from north or compass points)
% 10. Wind Run      - Cumulative wind run (distance air has moved past the station, e.g., in km or miles)
% 11. Hi Speed      - Highest wind speed recorded for the period
% 12. Hi Dir        - Wind direction corresponding to highest recorded wind speed
% 13. Wind Chill    - Wind chill temperature (°C or °F)
% 14. Heat Index    - Heat index value (°C or °F)
% 15. THW Index     - Temperature-Humidity-Wind index
% 16. THSW Index    - Temperature-Humidity-Sun-Wind index
% 17. Bar           - Barometric pressure (hPa, mbar, or inHg)
% 18. Rain          - Rainfall amount for the current period
% 19. Rain Rate     - Instantaneous rainfall rate
% 20. Solar Rad.    - Solar radiation (W/m²)
% 21. Solar Energy  - Solar energy (often in MJ/m² or similar unit)
% 22. Hi Solar Rad. - Highest solar radiation recorded for the period
%
% Author:
%   Ioannis Ziangas (Undergraduate Student)
%
% Supervisor: 
%   Panagiotis Zervas (Associate Professor)
%
% Affiliation:
%   University of the Peloponnese
%   Department of Electrical & Computer Engineering
%
% Course:
%   ECE_TEL851 – Information Theory (Academic Period 2025)
%
% GitHub Link of the Project:
%   https://github.com/JohnZiangas/Link-Budget-Modeling-for-Q-Band-LEO-Satellite-Communications-with-Adaptive-Coding-and-Modulation
%
% MIT License
% 
% Copyright (c) 2025 Ioannis Ziangas
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
% =============================================================================

    disp('    --- Running getWeatherMeasurments.m ---')
    disp('    [1/3] Checking for the raw data folder location...')

    % --- STEP 1: VERIFY DATA DIRECTORY

    % Check if the provided folder exists. If not, prompt the user to select one.
    if ~isfolder(dataFolder)
        errorMessage = sprintf(['Error: The following folder does not exist:\n%s\n', ...
                                'Please select a valid folder.'], dataFolder);
        uiwait(warndlg(errorMessage));
        dataFolder = uigetdir();
        if dataFolder == 0, return; end
    end


    % Look for Excel files matching the naming pattern (e.g., NOAANxxxx.xlsx)
    fileName   = 'NOAAN*.xlsx';
    filePattern = fullfile(dataFolder, fileName);
    theFiles    = dir(filePattern);

    % Stop execution if no matching files are found
    if isempty(theFiles)
        error('FileNotFound:DataFolder', ...
              ['Error: No Excel files matching "%s" were found in folder:\n%s\n' ...
               'Please choose the folder containing the "%s" file.'], ...
               fileName, dataFolder, fileName);
    end

    % Initialize a master table to store:
    %   File name, Sheet name, and raw Data table for each sheet.
    allData = table( ...
        'Size'         , [0 3], ...
        'VariableTypes', {'string','string','cell'}, ...
        'VariableNames', {'File','Sheet','Data'} ...
    );

    disp('        ✓ Data folder verified.')
    disp('    [2/3] Importing Excel file(s)...')

    % --- STEP 2: READ ALL EXCEL FILES AND SHEETS
    for k = 1:numel(theFiles)
        baseFileName = theFiles(k).name;
        fullFileName = fullfile(theFiles(k).folder, baseFileName);
        fprintf('\t\t\tReading file %d of %d: "%s"\n', k, numel(theFiles), baseFileName);

        % Get all sheet names in the file
        sheets = sheetnames(fullFileName);
        sheetData = cell(numel(sheets),1);

        % Process each sheet in the current file
        for j = 1:numel(sheets)
            % Read the first TWO rows of headers as raw cell data 
            % (A1:AA2 is the range of the excel file to search)
            hdr = readcell(fullFileName, 'Sheet', sheets{j}, 'Range', 'A1:AA2');

            % Ensure there are exactly 2 rows of headers
            if size(hdr,1) == 1
                hdr(2,1:size(hdr,2)) = {''};
            end

            % Detect number of columns with actual header content
            nColsGuess = find(all(cellfun(@(x) isempty(x) || (isstring(x)&&strlength(x)==0) ...
                                  || (ischar(x) && isempty(strtrim(x))), hdr),1), 1)-1;
            if isempty(nColsGuess), nColsGuess = size(hdr,2); end

            % Merge header rows into a single descriptive name for each column
            colNamesHuman = strings(1, nColsGuess);
            for c = 1:nColsGuess
                parts = string([hdr(1,c), hdr(2,c)]);
                parts = parts(strlength(strtrim(parts))>0); % Remove blanks
                if isempty(parts)
                    colNamesHuman(c) = ""; % Will become VarN later
                else
                    colNamesHuman(c) = strtrim(join(parts, " "));
                end
            end

            % Convert to MATLAB-valid and unique variable names
            validNames = matlab.lang.makeValidName(colNamesHuman, 'ReplacementStyle','delete');
            validNames = matlab.lang.makeUniqueStrings(validNames);

            % Read the actual data body (skip the first two header rows)
            body = readtable(fullFileName, ...
                'Sheet', sheets{j}, ...
                'NumHeaderLines', 2, ...
                'ReadVariableNames', false, ...
                'PreserveVariableNames', true, ...
                'TextType', 'string', ...
                'VariableNamingRule', 'preserve');
            
            % Ensure number of names matches number of data columns
            nColsBody = width(body);
            if numel(validNames) < nColsBody
                extra = arrayfun(@(x) sprintf('Var%d', x), (numel(validNames)+1):nColsBody, 'UniformOutput', false);
                validNames = [validNames, extra];
            elseif numel(validNames) > nColsBody
                validNames = validNames(1:nColsBody);
            end
            body.Properties.VariableNames = validNames;
            
            % Keep "Time" column in HH:mm string format if present
            timeColIdx = find(strcmpi(validNames, 'Time'));
            if ~isempty(timeColIdx)
                if isnumeric(body.(timeColIdx))
                    body.(timeColIdx) = string( datestr(body.(timeColIdx), 'HH:MM') );
                end
            end

            % Store processed sheet data
            sheetData{j} = body;
        end

        % Append results for all sheets in this file to master list
        allData = [allData; table( ...
            repmat(string(baseFileName), numel(sheets),1), ...
            string(sheets), ...
            sheetData, ...
            'VariableNames', {'File','Sheet','Data'} )];
    end

    disp('        ✓ Raw data import complete.')

    % --- STEP 2: ORGANIZE DATA BY DATE
    disp('    [3/3] Organizing the raw data into a table...')

    numSheets = height(allData);
    
    % Define expected standard column names (master list)
    masterNames = { ...
        'Date','Time','TempOut','HiTemp','LowTemp','OutHum','DewPt', ...
        'WindSpeed','WindDir','WindRun','HiSpeed','HiDir','WindChill', ...
        'HeatIndex','THWIndex','THSWIndex','Bar','Rain','RainRate', ...
        'SolarRad','SolarEnergy','HiSolarRad'};
    
    % Create final processed table structure
    processedDataTable = table( ...
        allData.File, ...
        allData.Sheet, ...
        repmat({table([],[], 'VariableNames',{'Date','AllMeasurements'})}, numSheets, 1), ...
        'VariableNames', {'File', 'Sheet', 'DataByDate'} ...
    );
    
    % Process each sheet's data
    for i = 1:numSheets
        % Get the current sheet's table
        sheetTable = allData.Data{i};
        currentNames = sheetTable.Properties.VariableNames;
        newVarNames  = currentNames; % Start with original names
    
        % Replace matching names with standardized master list names
        for m = 1:numel(masterNames)
            % Find column with same name (case-insensitive)
            matchIdx = find(strcmpi(currentNames, masterNames{m}), 1);
            if ~isempty(matchIdx)
                % Ensure MATLAB-valid name but keep match
                newVarNames{matchIdx} = masterNames{m};
            end
        end
    
        % Apply the updated names (preserving columns that aren't in master list)
        sheetTable.Properties.VariableNames = newVarNames;
    
        % Group all rows by Date 
        if ismember('Date', newVarNames)
            dates = unique(sheetTable.Date);
        else
            error('No "Date" column found in sheet %s of file %s.', ...
                  allData.Sheet{i}, allData.File{i});
        end
    
        % Create one subtable per unique date
        sub = cell(numel(dates),1);
        for d = 1:numel(dates)
            if isdatetime(sheetTable.Date)
                mask = (sheetTable.Date == dates(d));
            else
                mask = ismember(sheetTable.Date, dates(d));
            end
            sub{d} = sheetTable(mask, :);
        end
    
        % Store as "Date + AllMeasurements" in final output
        miniTable = table(dates, sub, 'VariableNames', {'Date','AllMeasurements'});
        processedDataTable.DataByDate{i} = miniTable;
    end

    disp('        ✓ Organised raw data.');
    disp('    --- Finished getWeatherMeasurments.m ---');
    disp(' ');
end