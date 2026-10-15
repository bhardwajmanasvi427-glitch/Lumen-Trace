function out = evidenceMap(im, forensic)
% Fuse localized detector maps; keep frame-edge concentration as context.
s=lumen.analyzeImage(im); names=fieldnames(forensic.maps); component=struct(); use={}; acc=zeros(size(s.gray)); n=0;
for i=1:numel(names)
 d=forensic.detectors.(names{i}); m=forensic.maps.(names{i});
 % Edge/boundary response describes the image frame globally. Mixing that
 % band into a localized edit-candidate map paints the border, not an edit.
 if strcmp(names{i},'edgeBoundary'), continue; end
 if d.available && all(isfinite(m(:))) && max(m(:))-min(m(:))>eps
  m=(m-min(m(:)))/(max(m(:))-min(m(:))+eps); component.(names{i})=m; acc=acc+m; n=n+1; use{end+1}=names{i}; %#ok<AGROW>
 end
end
if n, heat=acc/n; else, heat=zeros(size(s.gray)); end
threshold=mean(heat(:))+2*std(heat(:)); mask=heat>threshold; contribution=struct(); weights=zeros(1,numel(use));
for i=1:numel(use)
 m=component.(use{i}); if any(mask(:)), weights(i)=sum(m(mask)); else, weights(i)=sum(m(:)); end
end
if sum(weights)>0, weights=100*weights/sum(weights); end
for i=1:numel(use), contribution.(use{i})=weights(i); end
base=im2double(im); if ndims(base)==2, base=repmat(base,1,1,3); elseif size(base,3)>3, base=base(:,:,1:3); end
% Keep low-level heat response subtle as context, then mark thresholded
% candidate pixels with a strong red blend so they are visible in the GUI.
red=cat(3,ones(size(heat)),zeros(size(heat)),zeros(size(heat)));
alpha=0.12*heat; overlay=base.*(1-alpha)+red.*alpha;
if any(mask(:))
 candidateAlpha=0.72;
 for c=1:3
  plane=overlay(:,:,c); redPlane=red(:,:,c);
  plane(mask)=(1-candidateAlpha)*plane(mask)+candidateAlpha*redPlane(mask);
  overlay(:,:,c)=plane;
 end
end
out=struct('heatmap',heat,'mask',mask,'overlay',overlay,'threshold',threshold,'contributors',{use},'contributions',contribution,'componentMaps',component,'contextDetectors',{{'edgeBoundary'}},'hasCandidates',any(mask(:)));
end

