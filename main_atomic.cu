#include <stdio.h>
#include <cooperative_groups.h>

using namespace cooperative_groups;

__device__ int monitor;
__device__ int signal;

__device__ int threadNum;

__global__ void vecAdd(int m, int n, float* A, float* B, float* C ){
	int j = blockIdx.x * blockDim.x + threadIdx.x;
	int i = blockIdx.y * blockDim.y + threadIdx.y;

	int jj = threadIdx.x;
	int ii = threadIdx.y;

	int blockNum = gridDim.x * gridDim.y * gridDim.z;

	if ((i==0)&&(j==0)){
		printf("blockNum = %d\n", blockNum);
	}
	
	atomicAdd(&threadNum, 1);
	printf("jj= %d, ii= %d, threadNum = %d, blockNum = %d\n", jj, ii, threadNum, blockNum);

	int count = 0;

	while (count<1){
		count++;
	//	printf("A[%d][%d]\n",i,j);

		// barrier
		if ((ii==0)&&(jj==0)){
			atomicAdd(&monitor, 1);

			printf("monitor = %d\n", monitor);

			if (atomicCAS(&monitor, blockNum, 0)==blockNum){
				atomicCAS(&signal, 0, 1);
				printf("now signal is %d and monitor is %d\n", signal, monitor);	
			}			
			while(atomicCAS(&signal,0,0)==0);
		}

		__syncthreads();
	
		if ((ii==0)&&(jj==0)){
			atomicAdd(&monitor, 1);
			if (atomicCAS(&monitor, blockNum, 0)==blockNum){
				atomicCAS(&signal, 1, 0);
				printf("@@@ now signal is %d and monitor is %d\n", signal, monitor);
			}
			while(atomicCAS(&signal,1,1)==1);
		}

		__syncthreads();


		if ((i<m)&&(j<n)) {
			C[i*n+j] = A[i*n+j]+B[i*n+j];
	//		printf("A[%d][%d]=%f\n",i,j,A[i*n+j]);
		}
		

	}
	

}

int main(){
	int m = 32;
	int n = 32;
	float* h_a = NULL;
	float* h_b = NULL;
	float* h_c = NULL;
	float* d_a = NULL;
	float* d_b = NULL;
	float* d_c = NULL;
	h_a = (float*)malloc(m*n*sizeof(float));
	h_b = (float*)malloc(m*n*sizeof(float));
	h_c = (float*)malloc(m*n*sizeof(float));

	cudaMalloc((void**)&d_a, m*n*sizeof(float));
	cudaMalloc((void**)&d_b, m*n*sizeof(float));
	cudaMalloc((void**)&d_c, m*n*sizeof(float));

	if ((h_a==NULL)||(h_b==NULL)||(h_c==NULL)||(d_a==NULL)||(d_b==NULL)||(d_c==NULL)){
		printf("cannot allocate memory.\n");
	}
	
	//memset(h_c,0,m*n*sizeof(float));
	for (int i=0; i<m; i++){
		for (int j=0; j<n; j++){
			h_a[i*n+j]=i+j;
			h_b[i*n+j]=i+j;
			h_c[i*n+j]=0;
			//printf("%f,%f,%f\n",h_a[i*n+j],h_b[i*n+j],h_c[i*n+j]);
		}
	}
	
	cudaMemcpy(d_a, h_a, m*n*sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, h_b, m*n*sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_c, h_c, m*n*sizeof(float), cudaMemcpyHostToDevice);
	dim3 grid((n+15)/16, (m+15)/16,1);
	dim3 block(16, 16,1);
	//vecAdd<<<grid, block>>>	(m, n, d_a, d_b, d_c);
	vecAdd<<<8, 4>>> (m, n, d_a, d_b, d_c);
	cudaMemcpy(h_c, d_c, m*n*sizeof(float), cudaMemcpyDeviceToHost);
	for (int i=0; i<m; i++){
		for (int j=0; j<n; j++){
			//printf("C[%d][%d]=%f\n",i,j,h_c[i*n+j]);
		}
	}	
	return 0;	
	
}
