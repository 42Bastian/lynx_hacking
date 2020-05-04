#include <stdio.h>
#include <math.h>

#define PI 3.1415926535897935f
int main(void)
{
  float rad;
  int x;

  for(x = 0; x < 32; ++x){
    float si = sin(2.0f*PI/32*x);
    int pen = (int)(8+7*si);
    printf("$%x,",pen);
    if ( (x & 7) == 7 ) printf("\b\n");
  }
  printf("\n");
  return 0;
}
