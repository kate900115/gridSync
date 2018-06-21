all:
	nvcc -gencode=arch=compute_60,code=sm_60 -rdc=true main_barrier.cu -o barrier.out
	nvcc main_atomic.cu -o atomic.out
clean:
	rm *.out
