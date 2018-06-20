all:
	nvcc -gencode=arch=compute_60,code=sm_60 -rdc=true main.cu
clean:
	rm *.out
