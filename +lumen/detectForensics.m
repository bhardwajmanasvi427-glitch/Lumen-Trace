function out = detectForensics(im)
% Heuristic forensic responses, normalized per map. No map proves manipulation.
s=lumen.analyzeImage(im); g=s.gray; [h,w]=size(g); maps=struct(); det=struct();
% Copy-move: exact/near duplicate 16x16 blocks compared at distinct locations.
bs=16; if min(h,w)>=bs, step=max(8,ceil(sqrt(h*w/1200)/8)*8); signatures=[]; loc=[]; for y=1:step:h-bs+1, for x=1:step:w-bs+1, q=g(y:y+bs-1,x:x+bs-1); signatures(end+1,:)=reshape(imresize(q,[4 4]),1,[]); loc(end+1,:)=[y x]; end,end
 response=zeros(h,w); for i=1:size(signatures,1), ds=sum((signatures-signatures(i,:)).^2,2); ds(max(1,i-3):min(end,i+3))=inf; [v,j]=min(ds); dy=abs(loc(i,1)-loc(j,1)); dx=abs(loc(i,2)-loc(j,2)); if v<0.025 && max(dy,dx)>bs, response(loc(i,1):loc(i,1)+bs-1,loc(i,2):loc(i,2)+bs-1)=max(response(loc(i,1):loc(i,1)+bs-1,loc(i,2):loc(i,2)+bs-1),1-v/0.025); end,end
 maps.copyMove=response; det.copyMove=struct('available',min(h,w)>=bs,'message','Overlapping block similarity heuristic; repeated natural textures can trigger it.');
else, maps.copyMove=zeros(h,w); det.copyMove=struct('available',false,'message','Image smaller than 16×16; detector unavailable.'); end
% Local high-frequency residual variance outliers.
res=g-imgaussfilt(g,1); rv=conv2(res.^2,ones(9)/81,'same'); med=median(rv(:)); sig=1.4826*median(abs(rv(:)-med))+eps; maps.noiseInconsistency=min(max((rv-med)/(5*sig),0),1); det.noiseInconsistency=struct('available',true,'message','Local residual variance outliers; scene texture and denoising also affect response.');
% 8-pixel grid discontinuities (compression-like blockiness; not codec proof).
dx=abs(diff(g,1,2)); dy=abs(diff(g,1,1)); bx=zeros(h,w); by=bx; for xx=8:8:w, ii=min(xx-1,size(dx,2)); if ii>0, bx(:,xx)=dx(:,ii); end, end; for yy=8:8:h, ii=min(yy-1,size(dy,1)); if ii>0, by(yy,:)=dy(ii,:); end, end; maps.compressionArtifacts=min((bx+by)/(median([dx(:);dy(:)])*5+eps),1); det.compressionArtifacts=struct('available',true,'message','Periodic 8-pixel boundary discontinuities; not a JPEG decoder or proof of recompression.');
% Resampling proxy: unusual periodicity in interpolation-like first differences.
tile=64; response=zeros(h,w); for y0=1:tile:h, for x0=1:tile:w, yy=y0:min(y0+tile-1,h); xx=x0:min(x0+tile-1,w); patch=g(yy,xx); d=abs(diff(patch,1,2)); if size(d,2)>=5, period=zeros(1,4); for kk=2:5, sample=d(:,kk:5:end); period(kk-1)=mean(sample(:)); end; strength=std(period)/(mean(period)+eps); response(yy,xx)=min(strength*3,1); end, end, end; maps.resamplingAnomaly=response; det.resamplingAnomaly=struct('available',true,'message','Local 5-phase gradient-periodicity proxy on 64-pixel tiles; weak and scene-sensitive.');
% Edge concentration near image frame.
e=edge(g,'sobel'); band=max(1,round(min(h,w)*0.03)); frame=false(h,w); frame(1:band,:)=1; frame(end-band+1:end,:)=1; frame(:,1:band)=1; frame(:,end-band+1:end)=1; interior=~frame; if any(interior(:)), ratio=mean(e(frame))/(mean(e(interior))+eps); else, ratio=0; end; maps.edgeBoundary=zeros(h,w); maps.edgeBoundary(frame)=min(ratio/4,1); det.edgeBoundary=struct('available',true,'message','Frame-edge concentration heuristic; natural borders and crops affect it.');
out=struct('maps',maps,'detectors',det);
end




