data {
  int nt;
  real sd_value;
  real mu_value;
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

  p2~normal(mu_value, sd_value);
  p1~normal(mu_value, sd_value);
  p0~normal(mu_value, sd_value);

  for (i in 1:nt) {
    y[i] <- p2*pow(t[i],2)+p1*pow(t[i],1)+p0*pow(t[i],0) ;
  }
  
  yobs ~ normal(y, sigma);
}

generated quantities {
  vector[nt] log_lik;
  real y[nt];

  for (i in 1:nt) {
    y[i] <- p2*pow(t[i],2)+p1*pow(t[i],1)+p0*pow(t[i],0) ;
  }
  for (i in 1:nt){
  log_lik[i] <- normal_log(yobs[i], y[i], sigma);
  }
}