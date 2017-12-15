#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <cmath>
#include <climits>

#include <fstream>

const int BLOCKS = 1000;
const int DIMENSIONS = 16;
using namespace::std;

int inputLines[1000][16];
string filename = "test.txt";

void parseLine(string line, int lineArr[]) {
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

void readFile(){
  ifstream inputFile;
  inputFile.open(filename.c_str());
  int ind = 0;
  string line;
  while (getline(inputFile, line)) {
    parseLine(line, inputLines[ind]);
    ind++;
  }
}

int main(){
  readFile();
  unsigned int result[BLOCKS][DIMENSIONS];
  unsigned int distances[BLOCKS];

  const int selfIndex = 0;

  for (size_t i = 0; i < BLOCKS; i++) {
    for (size_t j = 0; j < DIMENSIONS; j++) {
      int diff = inputLines[i][j] - inputLines[selfIndex][j];
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

  cout << "Diff squares between " << selfIndex << " and 1" << endl;
  for (size_t i = 0; i < 16; i++) {
    cout << result[1][i] << ",";
  }
  cout<<endl;

  return 0;
}
