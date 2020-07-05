
int base = 1;
float PI = 3.141529f;

int[][] dist;
int[][] angle;
int[][] light;

int[] l2;
int[] d2;
int[] a2;

void plot(int x, int y, int col)
{
  fill(0,0,col);
  stroke(0,0,col);
  rect(x*2,y*2,2,2);
}


float distance(int x,int y)
{
  return ((x-40)*(x-40)+(y-25)*(y-25));
}

float atn(float x)
{
  return x*(0.2447 + 0.0663*x);
}

float atn(float x, float y)
{
  if ( y == 0 ) return PI/2;
  float d = x/y;
  float x2=x*x;
  float y2=y*y;
  float xy = x*y;

  //return atan(d);
  if ( d > 1 ){
    return xy/(x2+0.28125*y2);
  } else {
    return PI/2-(xy/(y2+0.28125*x2));
  }
}

int ox = 0;
int oy = 255;

void setup() {
  size(320,204);
  noSmooth();
  rectMode(CORNER);

  l2 = new int[50*80];
  d2 = new int[50*80];
  a2 = new int[50*80];
  int n = 0;
  for(int y = -25; y < 25; ++y){
    for(int x = -40; x < 40; ++x ){
      int d = ((y*y)+(x*x));
      int li;
      // angle
      int ai = 0;
      if ( d > 0 ){
        ai = (32*y*y)/d;
      }
      ai = ai & 31;
      if ( (x < 0) ^ (y < 0) ) ai ^= 31;
      a2[n] = ai;

      // distance
      int di = d != 0 ? int(0x2000/d) : 0;

      d2[n] = di;

      // light
      di = d/32;
      if ( di > 15 ) di = 15;
      l2[n] = di;

      ++n;
    }
  }

  surface.setLocation(1800,100);
  frameRate(20); //<>//
}

void mouseClicked()
{
  if ( mouseButton == LEFT ){
    ++ox;
    ++oy;
  } else {
    --ox;
    --oy;
  }
  println(oy);
}
void draw()
{
  int x,y;
  fill(0,0,0);
  stroke(0,0,0);
  rect(0,0,320,204);

  ++ox;
  ++oy;
  ox &= 0xff;
  oy &= 0xff;
  int n = 0;
  for(y = 49; y >= 0; --y){
    for(x = 79; x >= 0; --x){
      int tx = d2[n]-ox;
      int ty = a2[n]+oy;
      int col;

      col = (tx^ty) & 8;

      if ( col != 0 ){
        col = l2[n];
        plot(2*x,2*y ,col*16);
      } else {
        plot(2*x,2*y , 0);
      }
      ++n;
    }
  }
}
