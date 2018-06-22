all:
	nvcc -std=c++11 -gencode=arch=compute_60,code=sm_60 -rdc=true main_barrier.cu -o barrier.out
	nvcc -std=c++11 main_atomic.cu -o atomic.out
clean:
	rm *.out
