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

unsigned int testLines[TESTLINES*DIMENSIONS];
unsigned int trainLines[BLOCKS*DIMENSIONS];

string testFilename = "test.txt";
string trainFilename = "train.txt";

void parseLine(string line, int startIndex, unsigned int* arr) {
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

void readFile(string filename, unsigned int* arr){
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
void calculateDifference(int *trainLines, float *diffSquare, int *testLines, int id){
  __shared__ unsigned int s_diffSquare;
  s_diffSquare = 0;
  __syncthreads();
  // TODO: use shared memory for testLines
  int other = testLines[id*DIMENSIONS + threadIdx.x];
  int self = trainLines[blockIdx.x*DIMENSIONS + threadIdx.x];

  unsigned int result = other - self;

  atomicAdd(&s_diffSquare, result * result);
  // //s_diffSquare[blockIdx.x] += result;
  //
  __syncthreads();
  if (threadIdx.x % DIMENSIONS == 0) {
    diffSquare[blockIdx.x] = sqrtf(s_diffSquare);
  }
}

int main(int argc, char *argv[]) {
  readFile(testFilename, testLines);
  readFile(trainFilename, trainLines);

  const int selfIndex = 1;

  int* d_testLines;
  int* d_trainLines;
  float* d_diffLines;

  int* diffLines;
  int lineSize = DIMENSIONS * sizeof(unsigned int);
  int trainLinesSize = BLOCKS * lineSize;
  int testLinesSize = TESTLINES * lineSize;

  diffLines = (int *)malloc(BLOCKS * sizeof(float));
  cudaMalloc((void **)&d_testLines, testLinesSize);
  cudaMalloc((void **)&d_diffLines, BLOCKS * sizeof(float));
  cudaMalloc((void **)&d_trainLines, trainLinesSize);

  cudaMemcpy(d_testLines, testLines, testLinesSize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_trainLines, trainLines, trainLinesSize, cudaMemcpyHostToDevice);

  calculateDifference<<<BLOCKS, DIMENSIONS>>>(d_trainLines, d_diffLines, d_testLines, selfIndex);

  cudaMemcpy(diffLines, d_diffLines, BLOCKS * sizeof(float), cudaMemcpyDeviceToHost);

  float min = INT_MAX;
  int minIndex = -1;
  diffLines[selfIndex] = INT_MAX;
  for (size_t i = 0; i < BLOCKS; i++) {
    //cout <<"num: " << i << " : " << diffLines[i] << endl;
    if (diffLines[i] < min) {
      min = diffLines[i];
      minIndex = i;
    }
  }

  cout<< "closest node to " << selfIndex << " is min " << min << " with index: " <<minIndex<<endl;

  free(diffLines);
  cudaFree(d_diffLines); cudaFree(d_testLines);
  return 1;
}
