#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>

#include <fstream>

//const int N = 512;
using namespace::std;

const int BLOCKS = 1000;
const int DIMENSIONS = 16;

int inputLines[BLOCKS*DIMENSIONS];
string filename = "test.txt";

void parseLine(string line, int startIndex) {
  int start=0;
  int numIndex = startIndex;
  for (size_t i = 0; i < line.length(); i++) {
    if (line[i] == ',') {
      inputLines[numIndex] = stoi(line.substr(start, i-start));
      numIndex++;
      start = i+1;
    }
  }
  inputLines[numIndex] = stoi(line.substr(start, line.length()-start));
}

void readFile(){
  ifstream inputFile;
  inputFile.open(filename.c_str());
  int ind = 0;
  string line;
  while (getline(inputFile, line)) {
    parseLine(line, ind*DIMENSIONS);
    ind++;
  }
}

__global__
void calculateDifference(int *all, int *diffSquare, int id){
  int self = all[id*DIMENSIONS + threadIdx.x];
  int other = all[blockIdx.x*DIMENSIONS + threadIdx.x];

  int result = other - self;
  diffSquare[blockIdx.x*DIMENSIONS + threadIdx.x] = result * result;
}

int main(int argc, char *argv[]) {
  readFile();
  int* d_inputLines;
  int* d_diffLines;
  int* diffLines;
  int lineSize = DIMENSIONS * sizeof(int);
  int allLinesSize = BLOCKS * lineSize;

  diffLines = (int *)malloc(allLinesSize);
  cudaMalloc((void **)&d_inputLines, allLinesSize);
  cudaMalloc((void **)&d_diffLines, allLinesSize);

  cudaMemcpy(d_inputLines, inputLines, allLinesSize, cudaMemcpyHostToDevice);

  calculateDifference<<<BLOCKS, DIMENSIONS>>>(d_inputLines, d_diffLines, 0);

  cudaMemcpy(diffLines, d_diffLines, allLinesSize, cudaMemcpyDeviceToHost);

  cout << "diff squares between 0 and 1" << endl;
  for (size_t i = 0; i < DIMENSIONS; i++) {
    cout << diffLines[i+16] << ",";
  }
  cout << endl;

  free(diffLines);
  cudaFree(d_diffLines); cudaFree(d_inputLines);
  return 1;
}
