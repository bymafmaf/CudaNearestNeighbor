#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <cmath>
#include <climits>

#include <fstream>

//const int N = 512;
using namespace::std;

const int BLOCKS = 19000;
const int DIMENSIONS = 16;
const int TESTLINES = 1000;

unsigned short int testLines[TESTLINES*DIMENSIONS];
unsigned short int trainLines[BLOCKS*DIMENSIONS];

string testFilename = "test.txt";
string trainFilename = "train.txt";
string outputFilename = "myout.txt";

void parseLine(string line, int startIndex, unsigned short int* arr) {
  int start=0;
  int numIndex = startIndex;
  for (size_t i = 0; i < line.length(); i++) {
    if (line[i] == ',') {
      arr[numIndex] = stoi(line.substr(start, i-start));
      numIndex++;
      start = i+1;
    }
  }
  arr[numIndex] = stoi(line.substr(start, line.length()-start));
}

void readFile(string filename, unsigned short int* arr){
  ifstream inputFile;
  inputFile.open(filename.c_str());
  int ind = 0;
  string line;
  while (getline(inputFile, line)) {
    parseLine(line, ind*DIMENSIONS, arr);
    ind++;
  }
}

__global__
void calculateDifference(short int *trainLines, unsigned int *d_totals, unsigned int *d_min, short int *testLines, short int id){
  __shared__ unsigned int s_total;
  s_total = 0;
  __syncthreads();
  short int other = testLines[id*DIMENSIONS + threadIdx.x];
  short int self = trainLines[blockIdx.x*DIMENSIONS + threadIdx.x];

  int result = other - self;

  atomicAdd(&s_total, result * result);

  __syncthreads();
  if (threadIdx.x % DIMENSIONS == 0) {
    if (blockIdx.x == id){
      d_totals[blockIdx.x] = UINT_MAX;
    }
    else {
      d_totals[blockIdx.x] = s_total;
      atomicMin(d_min, s_total);
    }
  }
}

__global__
void getIndexOf(unsigned int *d_min, unsigned int *d_totals, unsigned short int *d_minIndex, unsigned short int selfIndex){
  if (*d_min == d_totals[blockIdx.x] && selfIndex != blockIdx.x) {
    *d_minIndex = blockIdx.x;
  }
}

void getNearestNeighbors(short int *trainLines, short int *testLines,unsigned int *result, short int id){
  unsigned int *max;
  max = (unsigned int*)malloc(sizeof(unsigned int));
  *max = UINT_MAX;

  unsigned short int *shrt_zero;
  shrt_zero = (unsigned short int*)malloc(sizeof(unsigned short int));
  *shrt_zero = 0;

  unsigned int *d_min;
  unsigned short int *minIndex;
  unsigned short int *d_minIndex;
  minIndex = (unsigned short int*)malloc(sizeof(unsigned short int));

  cudaMalloc((void **)&d_min, sizeof(unsigned int));
  cudaMemcpy(d_min, max, sizeof(unsigned int), cudaMemcpyHostToDevice);

  cudaMalloc((void **)&d_minIndex, sizeof(unsigned short int));
  cudaMemcpy(d_minIndex, shrt_zero, sizeof(unsigned short int), cudaMemcpyHostToDevice);

  // TODO: try short int with sqrft
  unsigned int *d_totals;
  cudaMalloc((void **)&d_totals, BLOCKS * sizeof(unsigned int));

  calculateDifference<<<BLOCKS, DIMENSIONS>>>(trainLines, d_totals, d_min, testLines, id);

  getIndexOf<<<BLOCKS, 1>>>(d_min, d_totals, d_minIndex, id);

  cudaMemcpy(minIndex, d_minIndex, sizeof(unsigned short int), cudaMemcpyDeviceToHost);



  result[id] = *minIndex;
  cudaFree(d_min); cudaFree(d_minIndex); cudaFree(d_totals);
  free(max); free(shrt_zero); free(minIndex);
}

int main(int argc, char *argv[]) {
  readFile(testFilename, testLines);
  readFile(trainFilename, trainLines);


  short int* d_testLines;
  short int* d_trainLines;

  unsigned int* output;
  int lineSize = DIMENSIONS * sizeof(short int);
  int trainLinesSize = BLOCKS * lineSize;
  int testLinesSize = TESTLINES * lineSize;

  output = (unsigned int *)malloc(TESTLINES * sizeof(unsigned int));
  cudaMalloc((void **)&d_testLines, testLinesSize);
  cudaMalloc((void **)&d_trainLines, trainLinesSize);

  cudaMemcpy(d_testLines, testLines, testLinesSize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_trainLines, trainLines, trainLinesSize, cudaMemcpyHostToDevice);

  for (size_t i = 0; i < TESTLINES; i++) {
    getNearestNeighbors(d_trainLines, d_testLines, output, i);
  }

  ofstream outputFile;
  outputFile.open(outputFilename.c_str());
  for (size_t i = 0; i < TESTLINES; i++) {
    outputFile << output[i] << endl;
  }
  free(output);
  cudaFree(d_testLines); cudaFree(d_trainLines);
  outputFile.close();
  return 1;
}
