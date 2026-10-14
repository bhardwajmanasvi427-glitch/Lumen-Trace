function out = evidenceMap(im, forensic)
% Fuse available spatial detector maps and quantify each contribution.
s=lumen.analyzeImage(im); names=fieldnames(forensic.maps); component=struct(); use={}; acc=zeros(size(s.gray)); n=0;
for i=1:numel(names)
 d=forensic.detectors.(names{i}); m=forensic.maps.(names{i});
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
red=cat(3,ones(size(heat)),zeros(size(heat)),zeros(size(heat))); alpha=0.45*heat; overlay=base.*(1-alpha)+red.*alpha;
out=struct('heatmap',heat,'mask',mask,'overlay',overlay,'contributors',{use},'contributions',contribution,'componentMaps',component,'hasCandidates',any(mask(:)));
end

