function data = tifread(filepath)
% fastest tif reading possible, super stripped down and optimized for speed
% only works for grayscale with same width and height for each frame
% 
% filepath can be a local file in current directory or full filename
% Andrew Landau, January 2019; Edited from Darcy Peterka's "bigread"

fid = fopen(filepath, 'rb');
tifname = fopen(fid); % get full filepath
info = matlab.io.internal.imagesci.tifftagsread(tifname,0,0,0); % get image info - internal mex function
numFrames = numel(info); % number of frames (directories)

% Can handle multiple data types
bd=info(1).BitDepth;
he=info(1).ByteOrder;
bo=strcmp(he,'big-endian');
if (bd==64)
	form='double';
elseif(bd==32)
    form='single';
elseif (bd==16)
    form='uint16';
elseif (bd==8)
    form='uint8';
end
if bo
    machinefmt = 'ieee-be';
else
    machinefmt = 'ieee-le';
end

% Strip offsets give position of data within each strip
% If multiple strips per frame, each bit is concatenated directly
ofds=zeros(1,numFrames);
for i=1:numFrames
    ofds(i)=info(i).StripOffsets(1);
end

% Get dimensions of tiff and preallocate array
cols = info(1).Width;
rows = info(1).Height;
data = zeros(rows,cols,numFrames,form);

% Depending on file type, read out binary data directly
% Within each- go to start of data for each frame
% Read in binary data and transpose to expected matlab ordering
if strcmpi(form,'uint16') || strcmpi(form,'uint8')
    for frame = 1:numFrames
            fseek(fid,ofds(frame),'bof');
            data(:,:,frame) = fread(fid, [cols rows], form, 0, machinefmt)';
    end
elseif strcmpi(form,'single')
    for frame = 1:numFrames
        fseek(fid,ofds(frame),'bof');
        data(:,:,frame) = fread(fid, [cols rows], form, 0, machinefmt)';
    end
elseif strcmpi(form,'double')
    for frame = 1:numFrames
        fseek(fid,ofds(frame),'bof');
        data(:,:,frame) = fread(fid, [cols rows], form, 0, strcat(machinefmt,'l64'))';
    end
else
    fprintf(2,'form not recognized\n');
end

fclose(fid); % bye

