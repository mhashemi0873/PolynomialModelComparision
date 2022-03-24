import os
import sys
import json
import pickle
import numpy as np
import pystan

model_code = open(sys.argv[2]).read()


print ('..............................................')

print ('creating model ...')

try:
	model = pickle.load(open(sys.argv[2] + '.pkl', 'rb'))

except (IOError, EOFError):

	model = pystan.StanModel(model_code=model_code,  verbose=True)

	with open(sys.argv[2] + '.pkl', 'wb') as f:
		pickle.dump(model, f)


print ('creating model done.')

print ('loading data ...')

data = dict(np.load(sys.argv[1]))

if sys.argv[3] == "hmc":

	print ('...sampling hmc...')

	fit = model.sampling(data=data, algorithm='NUTS', iter=int(sys.argv[4]),  warmup=int(int(sys.argv[4])/4), 
		                            control=dict(adapt_delta=0.85), chains=1, n_jobs=-1, verbose=True, refresh=500)

if sys.argv[3] == "advi":

	print ('sampling advi ...')

	fit = model.vb(data=data, algorithm='meanfield',  iter=int(sys.argv[4]),  tol_rel_obj=1e-5, 
		                      elbo_samples=1000 , output_samples=1000, verbose=False)


output = fit.extract(permuted=True)

print ('..saving...')

np.savez(sys.argv[5], **output)

print ('..............................................')