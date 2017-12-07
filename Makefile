bfs: bfs.cu
	nvcc bfs.cu -c -O3 -std=c++11 -arch compute_60
	g++ -o bfs bfs.o -O3 -lcuda -lcudart -L/usr/local/cuda/lib64/ -fpermissive
clean:
	rm -f bfs *.o
