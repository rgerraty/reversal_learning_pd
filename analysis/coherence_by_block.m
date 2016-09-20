function conn_cells=coherence_by_block(filename,block_size,Fs,minhz,maxhz)



tss=dlmread(filename);  
ts_length=size(tss,1);
remove_trs=mod(ts_length,block_size);
tss=tss(1:end-remove_trs:);
k=1;
for i=1:size(tss,1)/block_size
	conn_mat(:,:,i)=...
	mul_coher(tss(k:k+block_size-1,:),Fs,minhz,maxhz);
	k=k+block_size;
end

conn_cells=mat2cell(conn_mat,size(tss,2),size(tss,2),[ones(1,size(conn_mat,3))]);
end
