# Towards Diversity-Tolerant RDF-Stores
Welcome! This is the codebase related to the SPQ conjecture.


# How to play with
1) The `structuredness.run` is a binary file to play with the levels of structuredness of a dataset. For example, `./structuredness.run -i /path_to/inputfilename -o 0` will retuern the structuredness of a dataset. Similarly, `./structuredness.run -i /path_to/inputfilename -w /path_to/outputfilename -o 1 -c 0.8 -s 0.25 -r 0.0` will retuern a dataset whose structuredness and size are 80% and 25% of the original file, respectively.

2) Run `run.sh` to execute queries against RDF-stores. For example, `./run.sh --dataset SP2B100m  --system Jena --result /home/ubuntu/results/jena/sp2/100m/ --times 5 --wait 0 --timeout 5` will run each query of SP2Bench, 5 times against the dataset with 100M triples with no wait in between and setting 5 seconds as the timeout.

# How to build
1) Set `LD LIBRARY PATH` variable properly referring to the project folder (You may like to take a look at here as well: http://lpsolve.sourceforge.net/5.5/)
2) We used the following flags: `gcc -L. -I. -Werror=vla -Wextra -Wall -Wshadow -Wswitch-default  -fsanitize=address -g -DDEBUG=2 -o ./structuredness.run ./structuredness.c -llpsolve55 -lm

# Benchmark Datasets

| Dataset  | Link |
| ------------- | ------------- |
| WatDiv                |  https://zenodo.org/record/4008322/files/watdiv.tar.gz?download=1 |
| SP2Bench            |  https://zenodo.org/record/4008322/files/sp2bench.tar.gz?download=1 |
| LUBM-Part1             | https://zenodo.org/record/4008322/files/lubm.tar.gz?download=1 |
| LUBM-Part2       | https://zenodo.org/record/4008322/files/lubm1b.tar.gz?download=1 |



                 

