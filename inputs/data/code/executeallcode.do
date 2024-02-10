******
* This shell file executes all code for the replication of our study
******

***
* Set working directory - user will need to set to the current directory to the replicationdir folder
***
*For example,
*cd "/Users/franceslu/replicationdir"

* Packages needed (install if needed)
ssc install tabout
ssc install estout


*******
* 1 - Cleanraw data
*******
display "Clean raw data"
run "code/dofiles/01 clean raw data.do" //use this if you want the code to run quietly
* do "code/dofiles/01 clean raw data.do" //use this if you want to see the code run; commented out for now
cd ../..

*******
* 2 - Process intermediate data for analysis
*******
display "Process intermediate data for analysis"
run "code/dofiles/02 process intermediate data.do" //use this if you want the code to run quietly
* do  "code/dofiles/02 process intermediate data.do" //use this if you want to see the code run; commented out for now


*******
* 3 - Run analysis code
*******
display "Run analysis code"
do "code/dofiles/03 analysis code.do" //use this if you want to see the code run
* run "code/dofiles/03 analysis code.do" //use this if you want the code to run quietly; commented out for now
