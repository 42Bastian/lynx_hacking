#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint32_t pos = 0;
uint8_t getByte(FILE *in)
{
  int inbyte0;

  inbyte0 = fgetc(in);
  ++pos;
  if ( inbyte0 < 0 ){
    printf("Error\n");
    exit(1);
  }
  return (uint8_t)inbyte0;
}
uint16_t getWord(FILE *in)
{
  return (uint16_t)((getByte(in)<<8)|getByte(in));
}

#define WIDTH  128
#define HEIGHT 100

int main(void)
{
  FILE *in;
  int inbyte;
  uint8_t fb;
  uint16_t word;
  uint16_t color;
  int frame;
  int idx;
  int cnt;
  int totalColor;
  uint8_t vertice_buffer[512];
  int8_t palette_g[16];
  int8_t palette_br[16];
  uint32_t stat[16] = {0};
  uint32_t colorstat[16];
  uint32_t index_stat[255];
  uint8_t cntVert;
  int cntVert0;
  uint32_t totalIndexSave = 0;
  uint32_t size;
  in = fopen("scene1.dat","rb");
  int final = 0;
  frame = 0;
  pos = 0;
  totalColor = 0;

  for(idx = 0; idx < 16; ++idx ){
    palette_g[idx] = -1;
    palette_br[idx] = -1;
  }
  while( final == 0 && !feof(in) ){
    if ( size > 20000 ){
      printf(" dc.b $fe ;- end of file\n");
      printf(";---------- split %d -------\n",size);
      size= 0;
    }
    memset(colorstat, 0, sizeof(colorstat));

    printf("frame%03d:\n",frame);
    fb = getByte(in);
    cnt = 0;
    ++size;
    printf(" dc.b $%02x\n",fb);

    if ( fb & 1 ){
      printf("; /* clear screen */\n");
    }

    if ( fb & 2 ){
      word = getWord(in);
      printf("; %04x\n",word);
      color = word;
      for(cnt = 0, idx = 0; color ; color <<= 1, ++idx){
        if ( color & 0x8000 ){
          //00000RRR 0GGG0BBB

          int r = getByte(in);
          int g = getByte(in);
          int b = (g & 0x7)<<1;
          printf("; r %02x gb %02x\n",r,g);
          g >>= 4;

          palette_g[idx] = (g &7)<<1;
          palette_br[idx] = (b<<4)|((r & 7)<<1);
          ++cnt;
        }
      }
      totalColor += cnt;
    }

    if ( fb & 2 ){
      /* convert ST palette r:g:b to Lynx gbr*/
      size += 1+cnt*3;
      printf(" dc.b %d\n",cnt);
      printf("; palette%03d_off\n",frame);
      printf(" dc.b ");
      for( idx = 0; word ;  ++idx){
        if ( word & 0x8000 ){
          if ( cnt > 1  ){
            printf("%d,$%02X,$%02X, ",idx, palette_g[idx],palette_br[idx] & 0xff);
          } else {
            printf("%d,$%02X,$%02X\n",idx, palette_g[idx],palette_br[idx] & 0xff);
          }
          --cnt;
        }
        word <<= 1;
      }
    }

    if ( fb & 4 ){
      int vert = 0;

      cntVert = getByte(in);

      printf("indexed%03d: dc.b %d\n",frame,cntVert);
      fread(vertice_buffer, 2, cntVert, in);
      pos += 2*cntVert;
      size += cntVert*2;
      printf(";vertices_x\n");
      for(idx = 0; idx < 2*cntVert; idx += 2){
        if ( (idx & 31) == 0 ){
          printf(" dc.b ");
        }
        if ( idx < 2*(cntVert-1) && ((idx & 31) != 30)){
          printf("%3d,",(vertice_buffer[idx]*WIDTH+128)/256);
        } else {
          printf("%3d\n",(vertice_buffer[idx]*WIDTH+128)/256);
        }
      }
      printf(";vertices_y\n");
      for(idx = 0; idx < 2*cntVert; idx += 2){
        if ( (idx & 31) == 0 ){
          printf(" dc.b ");
        }
        if ( idx < 2*(cntVert-1) && ((idx & 31) != 30)){
          printf("%3d,",(vertice_buffer[idx+1]*HEIGHT+100)/200);
        } else {
          printf("%3d\n",(vertice_buffer[idx+1]*HEIGHT+100)/200);
        }
      }
      memset(index_stat,0,sizeof(index_stat));
      while( 1 ){
        fb = getByte(in);

        if ( fb == 0xfd ){
          ++size;
          final = 1;
          printf(" dc.b $00,$ff\n");
          printf(" .end\n");
          break;
        }
        if ( fb == 0xff ){
          ++size;
          printf(" dc.b $00\n");
          break;
        }
        if ( fb == 0xfe ){
          printf("; SKIP %08x\n",pos);
          while( (pos & 0xffff) ){
            (void)getByte(in);
          }
          ++size;
          printf(" dc.b $00\n");
          break;
        }

        int xfb = fb & 0xf;
        printf("; desc%03d_%03d\n"
               " dc.b $%02x\n",frame, vert,fb);

        ++colorstat[(fb>>4)];
        size += 1+(fb & 15);
        printf(" dc.b ");
        ++stat[xfb];
        int lidx = 0;
        for ( fb &= 0xf; fb; --fb){
          idx = getByte(in);
          if ( fb != 1 ){
            printf("%d,",idx);
          } else {
            printf("%d\n",idx);
          }
        }
        ++vert;
      }
    } else {
      printf("; /* non-indexed */\n");
      int vert = 0;
      while( 1 ){
        fb = getByte(in);
        if ( fb == 0xfd ){
          ++size;
          final = 1;
          printf(" dc.b $00,$ff\n");
          printf(" .end\n");
          break;
        }
        if ( fb == 0xff ){
          ++size;
          printf(" dc.b $00\n");
          break;
        }
        if ( fb == 0xfe ){
          printf("; SKIP %08x\n",pos);
          while( (pos & 0xffff) ){
            (void)getByte(in);
          }
          ++size;
          printf(" dc.b $00\n");
          break;
        }

        cntVert = fb & 0xf;
        ++colorstat[(fb>>4)];
        cntVert0 = cntVert;
        fread(vertice_buffer, 2, cntVert, in);
        pos += 2*cntVert;
        ++stat[cntVert];
        for(idx = 0; idx < cntVert*2; idx += 2){
          vertice_buffer[idx] = (vertice_buffer[idx]*WIDTH+128)/256;
          vertice_buffer[idx+1] = (vertice_buffer[idx+1]*HEIGHT+100)/200;
        }
        if ( cntVert <= 33 ){
          size += 1+cntVert*2;
          printf("; desc%03d_%03d\n"
                 " dc.b $%02x\n",frame, vert,fb);//(fb & 0xf0)|(cntVert) );

          printf(";vert%02d_%03d\n dc.b ",vert, frame);
          for(idx = 0; idx < cntVert; ++idx){
            printf(" %d,%d",vertice_buffer[2*idx],vertice_buffer[2*idx+1]);
            if ( idx == (cntVert-1) ){
              printf("\n");
            } else {
              printf(",");
            }
          }
        }
        ++vert;
      }
    }
    printf(";cols: ");
    for(idx = 0; idx < 16; ++idx){
      printf("%02d ",colorstat[idx]);
    }
    printf("\n");
    ++frame;
//->    if ( frame == 500 ) break;
  }
  int total = 0;
  printf("; Polygon sizes:\n");
  for(int i = 0; i < 16; ++i){
    if ( stat[i] ){
      printf("; %2d %5d\n",i, stat[i]);
      total += stat[i];
    }
  }
  printf("; Total: %d\n",total);
  printf("; Total colors: %d\n",totalColor);
  printf("; Total index: %d\n",size);
  for(total = 0, idx = 0; idx < 16; ++idx ){
    if ( palette_g[idx] == -1 ){
      ++total;
    }
  }
  if ( total > 1 ){
    printf("Max. unsed colors: %d\n",total);
  }

  return 0;
}
