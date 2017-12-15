#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <cmath>
#include <climits>

#include <fstream>

const int BLOCKS = 19000;
const int DIMENSIONS = 16;
const int TESTLINES = 1000;
using namespace::std;

unsigned int inputLines[TESTLINES][DIMENSIONS];
unsigned int trainLines[BLOCKS][DIMENSIONS];

string testFilename = "test.txt";
string trainFilename = "train.txt";

void parseLine(string line, unsigned int lineArr[]) {
  int start=0;
  int numIndex = 0;
  for (size_t i = 0; i < line.length(); i++) {
    if (line[i] == ',') {
      lineArr[numIndex] = stoi(line.substr(start, i-start));
      numIndex++;
      start = i+1;
    }
  }
  lineArr[numIndex] = stoi(line.substr(start, line.length()-start));
}

void readFile(int num, string filename){
  ifstream inputFile;
  inputFile.open(filename.c_str());
  int ind = 0;
  string line;
  while (getline(inputFile, line)) {
    if (num == 0) {
      parseLine(line, inputLines[ind]);
    }
    else {
      parseLine(line, trainLines[ind]);
    }
    ind++;
  }
}

int main(){
  readFile(0, testFilename);
  readFile(1, trainFilename);

  unsigned int result[BLOCKS][DIMENSIONS];
  unsigned int distances[BLOCKS];

  const int selfIndex = 1;

  for (size_t i = 0; i < BLOCKS; i++) {
    for (size_t j = 0; j < DIMENSIONS; j++) {
      int diff = trainLines[i][j] - inputLines[selfIndex][j];
      result[i][j] = diff * diff;
    }
  }
  for (size_t i = 0; i < BLOCKS; i++) {
    unsigned int total = 0;
    for (size_t j = 0; j < DIMENSIONS; j++) {
      total += result[i][j];
    }
    distances[i] = sqrt(total);
  }
  int min = INT_MAX;
  int minIndex = -1;
  distances[selfIndex] = INT_MAX;
  for (size_t i = 0; i < BLOCKS; i++) {
    if (distances[i] < min) {
      min = distances[i];
      minIndex = i;
    }
  }
  cout << "Closest to index " << selfIndex << " is min: " << min << " index: " << minIndex << endl;


  return 0;
}
