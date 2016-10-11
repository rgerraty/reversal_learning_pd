function [q,q_tmp,mean_flex,mean_flex_tmp,std_flex,std_flex_tmp]=Q_grid(conn_cell,nsim,res_pars,c_pars)

q=zeros(size(res_pars,1),size(c_pars,1),nsim);
q_tmp=zeros(size(res_pars,1),size(c_pars,1),nsim);
	for s=1:nsim
	%grid search paramater optimization based on Q-Qnull difference
			r=1;
			for res = res_pars
			o=1;
  			for c = c_pars
    			[c,q(r,o,s)]=multiord_res_norm(conn_cell,c, res);
    			[c_tmp,q_tmp(r,o,s)]=multiord_res_norm_temporal(conn_cell,c, res);
          flex=flexibility(c');
          flex_tmp=flexibility(c_tmp');

          mean_flex(r,o,s)=mean(flex);
          std_flex(r,o,s)=std(flex);

          mean_flex_tmp(r,o,s)=mean(flex_tmp);

          std_flex_tmp(r,o,s)=std(flex_tmp);
    			o=o+1;
  			end
  			r=r+1;
  		end
  	end
    q=mean(q,3);
    q_tmp=mean(q_tmp,3);
    mean_flex=mean(mean_flex,3);
    std_flex=mean(std_flex,3);
    mean_flex_tmp=mean(mean_flex_tmp,3);
    std_flex_tmp=mean(std_flex_tmp,3);