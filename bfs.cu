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
void calculateDifference(short int *trainLines,unsigned int *diffSquare, short int *testLines, short int id){
  __shared__ unsigned int s_diffSquare;
  s_diffSquare = 0;
  __syncthreads();
  short int other = testLines[id*DIMENSIONS + threadIdx.x];
  short int self = trainLines[blockIdx.x*DIMENSIONS + threadIdx.x];

  int result = other - self;

  atomicAdd(&s_diffSquare, result * result);
  __syncthreads();
  if (threadIdx.x % DIMENSIONS == 0) {
    diffSquare[blockIdx.x] = s_diffSquare;
  }
}

void getNearestNeighbors(short int *trainLines, short int *testLines,unsigned short int *result, short int id){
    unsigned int *d_diffSquare;
    unsigned int *diffSquare;
    diffSquare = (unsigned int *)malloc(BLOCKS * sizeof(unsigned int));
    cudaMalloc((void **)&d_diffSquare, BLOCKS * sizeof(unsigned int));

    calculateDifference<<<BLOCKS, DIMENSIONS>>>(trainLines, d_diffSquare, testLines, id);

    cudaMemcpy(diffSquare, d_diffSquare, BLOCKS * sizeof(unsigned int), cudaMemcpyDeviceToHost);

    int min = INT_MAX;
    int minIndex = -1;
    for (size_t i = 0; i < BLOCKS; i++) {
      if (diffSquare[i] < min) {
        min = diffSquare[i];
        minIndex = i;
      }
    }
    free(diffSquare);
    cudaFree(d_diffSquare);
    result[id] = minIndex;
}

int main(int argc, char *argv[]) {
  readFile(testFilename, testLines);
  readFile(trainFilename, trainLines);


  short int* d_testLines;
  short int* d_trainLines;

  unsigned short int* output;
  int lineSize = DIMENSIONS * sizeof(short int);
  int trainLinesSize = BLOCKS * lineSize;
  int testLinesSize = TESTLINES * lineSize;

  output = (unsigned short int *)malloc(TESTLINES * sizeof(unsigned short int));
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
  return 1;
}
