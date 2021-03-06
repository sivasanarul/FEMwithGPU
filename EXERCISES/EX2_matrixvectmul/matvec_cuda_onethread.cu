#include <stdio.h>
#include<iostream>
#include <cuda.h>
#include <time.h>
#include <sys/time.h>

using namespace std;

//## KERNEL FOR VECTOR ADDITION IN 1 THREAD ##//

extern double mysecond();
void init_array(float *a, const int N);
void init_mat(float *a, const int N, const int M);
void print_array(float *a, const int N, char *d);
void print_mat(float *a, const int N, const int M, char *d);

int main (void) {

    float *a, *b, *c, *d;
    float *dev_a, *dev_b, *dev_c;

    double t;
    int N = 32768;
    int M = N;
    
    // Allocate host memory
    a = (float*)malloc(sizeof(float)*N);
    b = (float*)malloc(sizeof(float)*N*M);
    c = (float*)malloc(sizeof(float)*M);
    d = (float*)malloc(sizeof(float)*M);
    
    // Initialize matrices    
    init_array(a, N);
    init_mat(b, N, M);
    init_array(c, M);
    
    //## ALLOCATE MEMORY FOR VARIABLES IN DEVICE ##//    
    
    t = mysecond();
    
    //## TRANSFER DATA FROM HOST TO DEVICE ##//
    
    t = (mysecond() - t);
    printf ("\nElapsed time for copy from host to device   = %g\n", t );
    
    t = mysecond();
    // matrix vector product    
    matvec<<<1, 1>>>(dev_a, dev_b, dev_c, N, M);
    cudaDeviceSynchronize();
    t = (mysecond() - t);
    printf ("\nElapsed time for matrix vector product in 1 thread = %g\n", t );

    t = mysecond();
    // Transfer data from device to host memory    
    cudaMemcpy(c, dev_c, sizeof(float)*M, cudaMemcpyDeviceToHost);
    t = (mysecond() - t);
    printf ("\nElapsed time for copy from device to host   = %g\n", t );



    // verify the kernel implementation 
    float sum = 0;
    for(int row = 0; row < N; row++)
	    {
		sum = 0;
		for(int col = 0; col < N; col++)
		{
		      sum = sum + b[row*N + col]*a[col];  
		    
		}
	      d[row] = sum;
	    } 
	    
    float error = 0;
    for(int i = 0; i < N; i++)
        error += d[i] - c[i];
       
    printf ("\nError   = %g\n", error );
    
    //## DEALLOCATE HOST AND DEVICE MEMORY ##//
    
    return 0;
};

void init_array(float *a, const int N) {
        int i;
        for(i = 0; i < N; i++)
                a[i] = 1.0;
}
void init_mat(float *a, const int N, const int M) {
        int i, j;
        for(i = 0; i < N; i++)
            for(j = 0; j < M; j++)
                    a[i*M + j] = 2.0;
}
void print_array(float *a, const int N, char *d) {
        int i;
        for(i = 0; i < N; i++)
                printf("\n%s[%d]: %f",d, i, a[i]);
    printf("\n");
}
void print_mat(float *a, const int N, const int M, char *d) {
        int i, j;
        for(i = 0; i < N; i++){
        printf("\n%s[%d]:", d, i);
        for (j = 0; j < M; j++)
                    printf("\t%6.4f", a[i*M + j]);
    }
    printf("\n");
}

double mysecond()
{
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp,&tzp);
    return ( (double) tp.tv_sec + (double) tp.tv_usec  * 1.e-6);
}
