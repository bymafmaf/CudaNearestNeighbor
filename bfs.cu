#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>

#include <fstream>

const int N = 512;
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

/*
You can ignore the ewgths and vwghts. They are there as the read function expects those values
row_ptr and col_ind are the CRS entities. nov is the Number of Vertices
*/

int main(int argc, char *argv[]) {
  readFile();



  return 1;
}
