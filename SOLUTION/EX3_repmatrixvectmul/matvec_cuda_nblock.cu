#include <stdio.h>
#include<iostream>
#include <cuda.h>
#include <time.h>
# include <omp.h>
#include <sys/time.h>

using namespace std;
__global__ void matvec(float *vec, float *mat, float *out, const int N, const int M){
    int tid=threadIdx.x + blockIdx.x*blockDim.x;
        float sum = 0;
    
        for(int i = 0; i < N; i++)
            sum += vec[i]*mat[(tid*M) + i];
        out[tid] = sum;
    
}

extern double mysecond();
void init_array(float *a, const int N);
void init_mat(float *a, const int N, const int M);
void print_array(float *a, const int N, char *d);
void print_mat(float *a, const int N, const int M, char *d);

int main (void) {

    float *a, *b, *c, *d;
    float *dev_a, *dev_b, *dev_c;
    double t;
    
    int N= 32768;
    int M=N;
    
    // Allocate host memory
    a = (float*)malloc(sizeof(float)*N);
    b = (float*)malloc(sizeof(float)*N*M);
    c = (float*)malloc(sizeof(float)*M);
    d = (float*)malloc(sizeof(float)*M);
    
    init_array(a, N);
    init_mat(b, N, M);
    init_array(c, M);

    // Allocate device memory
    cudaMalloc((void**)&dev_a, sizeof(float)*N);
    cudaMalloc((void**)&dev_b, sizeof(float)*N*M);
    cudaMalloc((void**)&dev_c, sizeof(float)*M);

    int blocksize = 256; // value usually chosen by tuning and hardware constraints
    int nblocks = N / blocksize;
    
    printf("\n\nRunning Kernel...\n\n");
    
    t = mysecond();  
    // Transfer data from host to device memory  
    cudaMemcpy(dev_b, b, sizeof(float)*N*M, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_a, a, sizeof(float)*N,   cudaMemcpyHostToDevice);
    t = (mysecond() - t);
    printf ("\nElapsed seconds for data transfer from Host to Device = %g\n", t);
        
    t = mysecond();     
    // matrix vector product for 100 iterations   
    int iter; int niter; niter = 500;
    for (iter = 0; iter < niter; iter++)
            {  
            // matrix vector product  	    	    
	    matvec<<<nblocks, blocksize>>>(dev_a, dev_b, dev_c, N, M);
	    cudaDeviceSynchronize();
	    }
    t = (mysecond() - t);
    printf ("\nElapsed seconds for executing kernel = %g\n", t);
  
    
    t = mysecond();
    // Transfer data from device to host memory     
    cudaMemcpy(c, dev_c, sizeof(float)*M, cudaMemcpyDeviceToHost);    
    t = (mysecond() - t);
    printf ("\nElapsed seconds for data transfer from Device to Host = %g\n", t); 
    
    // Deallocate device memory           
    cudaFree(dev_a);
    cudaFree(dev_b);
    cudaFree(dev_c);

       
    float sum = 0;
    for(int row = 0; row < N; row++)
	    {
		sum = 0;
		for(int col = 0; col < N; col++)
		{
		      sum=sum + b[row*N + col]*a[col];  
		    
		}
	      d[row] = sum;
	    } 
	    
    float error = 0;
    for(int i = 0; i < N; i++)
        error += d[i] - c[i];
     
    printf ("\nError   = %g\n", error );    
     
    // Deallocate host memory
    free(a); 
    free(b); 
    free(c);
    free(d); 
    return 0;
};

void init_array(float *a, const int N) {
        int i;
        for(i=0; i<N; i++)
                a[i] = 1.0;
}
void init_mat(float *a, const int N, const int M) {
        int i, j;
        for(i=0; i<N; i++)
            for(j=0; j<M; j++)
                    a[i*M+j] = 2.0;
}
void print_array(float *a, const int N, char *d) {
        int i;
        for(i=0; i<N; i++)
                printf("\n%s[%d]: %f",d, i, a[i]);
    printf("\n");
}
void print_mat(float *a, const int N, const int M, char *d) {
        int i, j;
        for(i=0; i<N; i++){
        printf("\n%s[%d]:", d, i);
        for (j=0; j<M; j++)
                    printf("\t%6.4f", a[i*M+j]);
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
