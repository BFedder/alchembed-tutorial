#! /bin/bash

# Make sure the gromacs binaries `gmx` and `gmx_d` are in your $PATH. Check via
# $ gmx -h
# and
# $ gmx_d -h
# you may only have one version on your machine, or you may use a modules environment
# Source the required GMXRC files where necessary.

# this script takes two arguments
# the first is the name of the protein (from pla2, nbar, cox1, kcsa, ompf)
protein=$1

# the second is whether it is atomistic (at) or coarse-grained (cg)
ff=$2

# create the output directory if it doesn't exist (e.g. nbar/cg/)
if [ ! -d "$protein" ]; then
	mkdir $protein
fi

if [ ! -d "$protein/$ff" ]; then
	mkdir $protein/$ff
fi

# First, prepare a TPR file for energy minimisation
gmx grompp 	 -f common-files/em-$ff.mdp\
		 -c common-files/$protein-$ff.pdb\
		 -p common-files/$protein-$ff.top\
		 -n common-files/$protein-$ff.ndx\
	     -po $protein/$ff/$protein-$ff-em.mdp\
		 -o $protein/$ff/$protein-$ff-em\
	     -maxwarn 1

# ..now run using double precision (you may need to compile this as only single precision is compiled by default)
#  (or just try single precision...)
# This should only take a few seconds
gmx_d mdrun -v -deffnm $protein/$ff/$protein-$ff-em\
		 -ntmpi 1


# Now, prepare the ALCHEMBED TPR file
gmx grompp 	 -f common-files/alchembed-$ff.mdp\
		 -c $protein/$ff/$protein-$ff-em.gro\
		 -r $protein/$ff/$protein-$ff-em.gro\
		 -p common-files/$protein-$ff.top\
		 -n common-files/$protein-$ff.ndx\
	     -po $protein/$ff/$protein-$ff-alchembed.mdp\
		 -o $protein/$ff/$protein-$ff-alchembed\
         -maxwarn 2

# ..and run on a single core. 
gmx mdrun -v -deffnm $protein/$ff/$protein-$ff-alchembed\
	     -ntmpi 1 -ntomp 1