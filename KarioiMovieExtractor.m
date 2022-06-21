files=dir('G:\Shared drives\Karioi Video Feed\WainuiStream\WS080\*\*\VID*.avi');
fileCount=size(files,1);
filterPct=99.5;
for fileNo=1:fileCount
    folderName=files(fileNo).folder;
    fileName=files(fileNo).name;
    fullFilePath=sprintf('%s\\%s',folderName,fileName);
    diffFileName=sprintf('diff_heatmap_%s,',fileName);
    diffFilePath=sprintf('%s\\%s',folderName,diffFileName);
    vid=VideoReader(fullFilePath);
    try
        
        bufferDelay=3;
        vid.set('CurrentTime',0)
        buffer=zeros(vid.Height,vid.Width,bufferDelay);
        out=VideoWriter(diffFilePath,'Motion JPEG AVI')
        open(out)
        oldFrame=zeros(vid.Height,vid.Width);
        olddiff=oldFrame;
        for i=1:vid.NumFrames
            frame=vid.readFrame();
            grayFrame=rgb2gray(frame);
            diff=uint8(abs(uint8(oldFrame)-grayFrame));
            filterVal=prctile(prctile(diff,filterPct),filterPct);
            diff(diff(:,:)<filterVal)=0;
            stack=double(double(diff)+olddiff*1);
            out.writeVideo(diff);
            oldFrame=buffer(:,:,1);
            buffer(:,:,1)=[];
            buffer(:,:,bufferDelay)=grayFrame;
            olddiff=stack;
        end
    catch
       
    end
    close(out)
end


detector = vision.ForegroundDetector(...
       'NumTrainingFrames', 50, ...
       'InitialVariance', 30*30);