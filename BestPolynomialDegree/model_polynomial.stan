data {
  int ndegree;
  int nt;
  real t[nt];
  real yobs[nt];
}
transformed data{
}

parameters {
  real p[ndegree+1];
  real<lower=0> sigma;
}


model {
  real y[nt];
  for (i in 1:nt) {
      y[i]=0;
          for (j in 1:ndegree+1){
               y[i] = y[i] + p[j]*pow(t[i],j-1); 
              }
   }
           

  
  yobs ~ normal(y, sigma);
}

generated quantities {

  vector[nt] log_lik;
  real y[nt];



  for (i in 1:nt) {
      y[i]=0;
          for (j in 1:ndegree+1){
               y[i] = y[i] + p[j]*pow(t[i],j-1); 
              }
   }

  for (i in 1:nt){
  log_lik[i] = normal_lpdf(yobs[i] | y[i], sigma);
  }
}