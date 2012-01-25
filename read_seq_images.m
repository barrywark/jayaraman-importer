function seq_image = read_seq_images(seq_info, fid, frames)
% seq_im = read_seq_images(seq_info, fid, frames)
% reads the frames specified by frames, either a range, or -1 for all of
% them, and returns in the seq_im structure

if frames == -1  % if -1, then set frames to entire sequence
    frames = 1:seq_info.NumberFrames;
end

seq_image = zeros(length(frames), seq_info.Height, seq_info.Width);

if length(frames) == 1 % if just one frame, do not return a structure
    image_address = 1024 + (frames-1)*seq_info.TrueImageSize;
    status = fseek(fid, image_address, 'bof');
    seq_image = fread(fid, [seq_info.Width, seq_info.Height], 'uint8')';
else
    for j = 1:length(frames)
        image_address = 1024 + (frames(j)-1)*seq_info.TrueImageSize;
        status = fseek(fid, image_address, 'bof');
        seq_image(j,:,:) = fread(fid, [seq_info.Width, seq_info.Height], 'uint8')';
    end    
end

