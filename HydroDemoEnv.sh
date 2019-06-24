#!/bin/bash
# For use on Boise State's R2 computing cluster 

module purge
module load intel/mkl
module load intel/mpi
module load intel/compiler
module load R/3.5.2
module load slurm/17.11.8

# source the .Renviron file
# the .Renviron file exports the location of the localling installed 
# libraries 
source ~/.Renviron
