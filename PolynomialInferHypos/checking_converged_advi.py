import os
import sys
import re

from numpy import *


def converged_advi(filename):
    pass_advi=0
    if 'COMPLETED.' in open(filename).read():
        pass_advi+=1
    return pass_advi


if __name__ == "__main__":
  
    out_pass=converged_advi(sys.argv[1])

    if out_pass==1:
       print('advi converged')   
    sys.exit(0)



# def converged_advi(filename):
#     with open(filename , 'r') as fd:
#         started = False
#         pass_advi=0      
#         for line in fd.readlines():
#             if 'Success!' in line:
#                 started = True
#                 continue
#             if started and 'COMPLETED.' in line:
#                 #print('Completed advi! :) ')
#                 pass_advi+=1
#                 break
          
#         #if pass_advi==0:
#            #print('Did not Completed advi! :( ')  

#     return pass_advi