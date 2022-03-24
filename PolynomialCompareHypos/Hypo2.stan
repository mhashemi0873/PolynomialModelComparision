data {
  int nt;
  real t[nt];
  real yobs[nt];
}

parameters {
  real p2;
  real p1;
  real p0;
  real<lower=0> sigma;
}


model {

  real y[nt];
  p2~normal(5, 2);
  p1~normal(5, 2);
  p0~normal(5, 2);

  for (i in 1:nt) {
    y[i] = p2*pow(t[i],2)+p1*pow(t[i],1)+p0*pow(t[i],0) ;
  }
  
  yobs ~ normal(y, sigma);

}

generated quantities {
  vector[nt] log_lik;
  real y[nt];

  for (i in 1:nt) {
    y[i] = p2*pow(t[i],2)+p1*pow(t[i],1)+p0*pow(t[i],0) ;
  }
  for (i in 1:nt){
  log_lik[i] = normal_lpdf(yobs[i]| y[i], sigma);
  }
}