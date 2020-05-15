/* -*-c++-*- */
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <windows.h>

/*
**
** 990712  42BS  On read-error, re-connecting
** 990713  42BS  IO-Buffer setup
** 180308  42BS  clean up, adapted to USB serial, add read function
** 180309  42BS  fixed CRC calculation
**
*/


int comm_setup(unsigned long Baudrate,
               char *portName,
               unsigned long timeout);


unsigned int blocksize = 1024;
HANDLE hPort = 0;

unsigned char sectorBuffer[2048];
unsigned char lynxcrc[256];
unsigned char imagecrc[256];
unsigned char buffer[256*2048];
unsigned char crctab[256];

void OSerror(char *f,long i);

/* Communication Setup        */
/* Initialize serial Com Port */

int
comm_setup(unsigned long Baudrate,
           char *portName,
           unsigned long timeout)
{
  /*
  ** These statics hold the parameters if a re-init is needed.
  */
  static unsigned long Baudrate_ = 0;
  static unsigned int Port_ = 0;
  static unsigned long timeout_ = 0;


  // Port already open ??
  if ( hPort != 0 ){
    return 0;
  }
  //
  // Open COM Port
  //
  hPort= CreateFile(portName,
                    GENERIC_READ|GENERIC_WRITE,
                    0,
                    NULL,
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL|FILE_FLAG_NO_BUFFERING,
                    NULL
    );

  /* Check for errors */
  if( hPort == INVALID_HANDLE_VALUE ){
    hPort = 0;
    OSerror("failed to open",-1);
    return -1;
  }else{
    /*
    ** port open succesfull, now init.
    */
    DCB dcb;
    // The COMMTIMEOUTS structure is used
    // in the SetCommTimeouts and GetCommTimeouts
    // functions to set and query the time-out
    // parameters for a communications device.
    // The parameters determine the behavior of
    // ReadFile, WriteFile, ReadFileEx, and
    // WriteFileEx operations on the device.
    COMMTIMEOUTS myCOMMTIMEOUTS;

    myCOMMTIMEOUTS.ReadIntervalTimeout=0;
    myCOMMTIMEOUTS.ReadTotalTimeoutConstant=timeout; //old 100 ms 42BS
    myCOMMTIMEOUTS.ReadTotalTimeoutMultiplier=5; //old 0

    myCOMMTIMEOUTS.WriteTotalTimeoutConstant=100; //old 100 ms 42BS
    myCOMMTIMEOUTS.WriteTotalTimeoutMultiplier=50; //old 0

    if( !GetCommState( hPort, &dcb ) ) OSerror("GetCommState",-1);

    memset(&dcb, 0, sizeof(dcb));
    switch ( Baudrate ){
    case   9600 : dcb.BaudRate = CBR_9600; break;
    case  19200 : dcb.BaudRate = CBR_19200; break;
    case  38400 : dcb.BaudRate = CBR_38400; break;
    case  57600 : dcb.BaudRate = CBR_57600; break;
//->    case  62500 : dcb.BaudRate = CBR_62500; break;
    case 115200 : dcb.BaudRate = CBR_115200; break;
    default:
      dcb.BaudRate = Baudrate;
//->      fprintf(stderr,"Unsupported Baudrate\n");
//->      return -1;
    }
    dcb.fBinary = TRUE;
    dcb.fParity   = 0;
    dcb.fOutxCtsFlow = 0;
    dcb.fOutxDsrFlow = 0;
    dcb.fDtrControl = DTR_CONTROL_DISABLE;
    dcb.fRtsControl = RTS_CONTROL_DISABLE;
    dcb.fDsrSensitivity = 0;
    dcb.fTXContinueOnXoff = TRUE;
    dcb.fOutX  = 0;
    dcb.fInX = 0;
    dcb.fErrorChar = 0;
    dcb.fNull = 0;
    dcb.fAbortOnError = 0;
    dcb.XonLim=1000;
    dcb.XoffLim=1000;
    dcb.ByteSize = 8;
    dcb.Parity   = EVENPARITY;
    dcb.StopBits = ONESTOPBIT;
    if( !SetCommState( hPort, &dcb ) ) OSerror("SetCommState",-1);

    if( !GetCommState( hPort, &dcb ) ) OSerror("GetCommState",-1);
    fprintf(stderr, "Baudrate %d\n",dcb.BaudRate);

    // sets the time-out parameters for all
    // read and write operations on a
    // specified communications device.
    if ( !SetCommTimeouts(hPort,&myCOMMTIMEOUTS) )
      OSerror("SetCommTimeouts",-1);

    if ( !SetupComm(hPort,1024*64,256)) OSerror("SetupComm",-1);
  }
  return 0;
}
void
OSerror(char *f,long i)
{
  long err = GetLastError();
  if ( i != -1 ) err = i;
  printf("\nSystem-Error: %s: %ld\n",f,err);
  Sleep(1000);
  exit(-1);
}

void hexdump(const char *buf)
{
  int n;
  for(n = 0; n < blocksize; ++n){
    if ( (n % 16) == 0 ){
      printf("\n");
    }
    printf("%02x ",(unsigned char)buf[n]);
  }
  printf("\n");
}

void hexdump2(const char *left,const char * right)
{
  int n;
  int l;
  for(l = 0,n = 0; n < blocksize*2; ++n){
    if ( (n % 16) == 0 ){
      if ( l ){
        l = 0;
        printf("| ");
      } else {
        printf("\n");
        l = 1;
      }
    }
    if ( l ){
      printf("%02x ",(unsigned char)*left++);
    } else {
      printf("%02x ",(unsigned char)*right++);
    }
  }
  printf("\n");
}

void sendByte(char c)
{
  char dummy;
  long unsigned int n;
  WriteFile(hPort,&c,1,&n,NULL);
  if ( n ){
    do{
      ReadFile(hPort,&dummy,1,&n,NULL);
    } while( dummy != c );
  }
}
int getByte()
{
  long unsigned int n;
  unsigned char c;
//->  long tmo = 1;
//->  do{
  ReadFile(hPort,&c,1,&n,NULL);
//->  } while( n != 1 && --tmo);
  return n == 1 ? c : -1;
}

void sendLynxProgramm()
{
  extern unsigned char sram_lynx[];
  int len;
  long unsigned int dwBytes;
  int rlen;

  len = sram_lynx[4]*256+sram_lynx[5];
  sectorBuffer[0] = (char)0x81;
  sectorBuffer[1] = 'P';
  sectorBuffer[2] = sram_lynx[2];
  sectorBuffer[3] = sram_lynx[3];
  sectorBuffer[4] = (len >> 8) ^ 0xff;
  sectorBuffer[5] = (len & 0xff) ^ 0xff;
  WriteFile(hPort, sectorBuffer,6,&dwBytes,NULL);
  ReadFile(hPort,sectorBuffer,6,&dwBytes,NULL);
  rlen = dwBytes;
  /* Hack for CP2102 adapter */
  int x = 1024;
  for(int i = 0; i < len;){
    int l;
    l = len - i;
    if ( l > x ){
      l = x;
    }
    WriteFile(hPort, sram_lynx+i+10,l,&dwBytes,NULL);
    if (dwBytes != l){
      printf("Error\n");
    }
    ReadFile(hPort,sectorBuffer,l,&dwBytes,NULL);
    rlen += dwBytes;
    i += l;
  }
  do{
    ReadFile(hPort,sectorBuffer,6,&dwBytes,NULL);
    if ( dwBytes >= 0 ){
      rlen += dwBytes;
    }
  } while( dwBytes > 0 );
  len = sram_lynx[4]*256+sram_lynx[5];
//->  printf("Read %d (%d)\n",rlen, len+6);
}

void init_crctab()
{
  int i,o;
  char a;
  for( i = 0; i<256; ++i){
    a = i;
    for(o = 0; o < 8; ++o){
      if ( a < 0 ){
        a = (a<<1) ^ 0x95;
      } else {
        a <<= 1;
      }
    }
    crctab[i] = (unsigned char )a;
  }
}

void getLynxCRC()
{
  int i;
  long unsigned int n;
  sendByte('C');
  sendByte('0');
  i = 0;
  do{
    ReadFile(hPort,lynxcrc+i,256-i,&n,NULL);
    i += n;
  } while ( i < 256 );
}

int checkBlock(int blk)
{
  long len;
  long unsigned int n;

  sendByte('C');
  sendByte('4');
  sendByte(blocksize/256);
  sendByte(blk);

  len = 0;
  do{
    ReadFile(hPort,sectorBuffer,blocksize-len,&n,NULL);
    len += n;
  } while( len < blocksize );

  return (memcmp(sectorBuffer, buffer+blk*blocksize, blocksize) == 0);
}

int clearBlock(int blk, int clear)
{
  int c;

  return 0;
}

int readBlock(int blk)
{
  long len;
  long unsigned int n;
  len = 0;

  sendByte('C');
  sendByte('4');
  sendByte(blocksize/256);
  sendByte(blk);

  do{
    ReadFile(hPort,buffer+blk*blocksize,blocksize-len,&n,NULL);
    len += n;
  } while( len < blocksize );
}

void sendBlock(int blk)
{
  long unsigned int n;
  int c;
  long total;

  sendByte('C');
  sendByte('1');
  sendByte(blocksize/256);
  sendByte(blk);
  Sleep(25);

  do{
    WriteFile(hPort,buffer+blk*blocksize,blocksize,&n,NULL);
    total = 0;
    do{
      ReadFile(hPort,sectorBuffer,blocksize-total,&n,NULL);
      total += n;
    } while( total < blocksize );
    sendByte(imagecrc[blk]);
    do{
      c = getByte();
      if ( c != -1 ){
        printf("(%02x) ",c);
        fflush(stdout);
      }
    } while( c != 0x14 && c != 0x41 );
  } while( c != 0x41 );
  do{
    c = getByte();
    if ( c != -1 ){
      printf("%02x ",c);
      fflush(stdout);
    }
  } while( c != 0x42 );
}

void getImageCRC()
{
  int i,o;
  unsigned char crc;
  unsigned char *p = buffer;

  for(i = 0; i < 256; ++i){
    for(crc = 0,o = 0; o < blocksize; ++o){
      crc ^= *p++;
      crc = crctab[ crc ];
    }
    imagecrc[i] = crc;
    if ( (i % 16) == 0 ){
      putchar('\n');
    }
    printf("%02x ",crc);
  }
  putchar('\n');
}

// Bytes should be 8-bits wide
typedef signed char SBYTE;
typedef unsigned char UBYTE;

// Words should be 16-bits wide
typedef signed short SWORD;
typedef unsigned short UWORD;

// Longs should be 32-bits wide
typedef long SLONG;
//->typedef unsigned long ULONG;

typedef struct
{
  UBYTE   magic[4];
  UWORD   page_size_bank0;
  UWORD   page_size_bank1;
  UWORD   version;
  UBYTE   cartname[32];
  UBYTE   manufname[16];
  UBYTE   rotation;
  UBYTE   spare[5];
}LYNX_HEADER_NEW;

int saveImage(const char *s)
{
  FILE *in;
  int len;
  LYNX_HEADER_NEW header;
  char null[512];
  int blk;
  int size;
  char *p;

  memset(null,0,512);

  p = buffer;
  for(blk = 0; blk < 256; ++blk, p += 1024){
    if ( memcmp(p+512, null, 512) != 0 && memcmp(p, p+512, 512) != 0 ) {
      break;
    }
  }
  size = ( blk == 256 ) ? 512 : 1024;
  size = 1024;//XXX
  printf("Write %dK Image\n",size/4);

  if ( (in = fopen(s,"w")) == (FILE *)NULL){
    fprintf(stderr,"Couldn't open <%s>\n",s);
    return 1;
  }
  memset(&header,0,64);
  memcpy(header.magic,"LYNX",4);
  header.page_size_bank0 = size;
  header.version = 1;
  fwrite(&header,1,64,in);
  if ( size == 1024 ){
    len = fwrite(buffer,1,256*1024,in);
  } else {
    for(blk = 0; blk < 256; ++blk){
      fwrite(buffer+blk*1024,1,512,in);
    }
  }

  fclose(in);
  return 0;
}

int loadImage(const char *s)
{
  FILE *in;
  int len;

  if ( (in = fopen(s,"rb")) == (FILE *)NULL){
    fprintf(stderr,"Couldn't open <%s>\n",s);
    return 1;
  }
  if ( fread(buffer,1,64,in) < 64 ){
    fclose(in);
    return 1;
  }
  if ( buffer[0] == 'L' && buffer[1] == 'Y' &&
       buffer[2] == 'N' && buffer[3] == 'X'){
    len = fread(buffer,1,256*1024,in);
  } else {
    len = fread(buffer+64,1,256*1024-64,in)+64;
  }

  fclose(in);

  if ( len == 128*1024 && (buffer[0] != 0xfb || buffer[0x200] == 0x04)){
    blocksize = 512;
  }
  printf("Imagelength %d/Blocksize %d\n",len,blocksize);
  return 0;
}

void help(void)
{
  fprintf(stderr,
          "sram_up [-p com] [-b baudrate] [-s blocksize] [-l] [-x] [-e] (-r|-f) file)\n"
          " -x           : force writing\n"
          " -r file      : read card and save file with LNX header\n"
          " -e           : erase flash\n"
          " -s blocksize : 512,1024 or 2048, 1024 is default\n"
          " -l           : force upload of loader\n");
  exit(-1);
}
int main(int argc, char **argv)
{
  long dwBytes;
  int fd;
  char *ptr = buffer;
  int len;
  int i,o;
  char portName[10] = "\\\\.\\";
  int baudrate = 62500;
  int readCard = 0;
  int flashCard = 0;
  int force = 0;
  int sendLynx = 0;
  int clear = -1;
  int erase = 0;
  char *filename;
  ++argv; // skip process-name
  --argc;
  if ( argc == 0 ){
    help();
  }

  do{
    if ( !strcmp(*argv,"-b") ){
      baudrate = atoi(argv[1]);
      argv += 2;
      argc -= 2;
    } else if ( !strcmp(*argv,"-p")){
      strcat(portName,argv[1]);
      printf("Port: %s\n",portName);
      argv += 2;
      argc -= 2;
    } else if ( !strcmp(*argv,"-e")){
      argv += 1;
      argc -= 1;
      erase = 1;
    } else if ( !strcmp(*argv,"-r")){
      argv += 1;
      argc -= 1;
      readCard = 1;
      if ( argc != 0 && **argv != '-' ){
        filename = *argv;
        argv += 1;
        argc -= 1;
      } else {
        fprintf(stderr,"Missing file\n");
        return 1;
      }
    } else if ( !strcmp(*argv,"-f")){
      argv += 1;
      argc -= 1;
      flashCard = 1;
        if ( argc != 0 && **argv != '-' ){
        filename = *argv;
        argv += 1;
        argc -= 1;
      } else {
        fprintf(stderr,"Missing file\n");
        return 1;
      }
    } else if ( !strcmp(*argv,"-l")){
      argv += 1;
      argc -= 1;
      sendLynx = 1;
    } else if ( !strcmp(*argv,"-x")){
      argv += 1;
      argc -= 1;
      force = 1;
    } else if ( !strcmp(*argv,"-s")){
      blocksize = atoi(argv[1]);
      argv += 2;
      argc -= 2;
      if ( blocksize != 512 && blocksize != 1024 && blocksize != 2048 ){
        fprintf(stderr, "Wrong blocksize, must be 512,1024 or 2048\n");
        return 1;
      }
    } else if ( !strcmp(*argv,"-h")){
      help();
   } else {
      fprintf(stderr,"Unknown option:%s\n",*argv);
      return 1;
    }
  }  while ( argc > 0 );

  init_crctab();

  if ( readCard == 1 ){
    if ( (fopen(filename,"rb")) != (FILE *)NULL){
      fprintf(stderr,"Error, file exists <%s>\n",filename);
      return 1;
    }
  } else if ( flashCard ){
    if ( loadImage(filename) ){
      return 3;
    }
  }

  if ( comm_setup(baudrate,portName,100) ) return 2;

  int c = 1;
  if ( sendLynx == 0 ){
    sendByte('C');
    sendByte('3');
    c = getByte();
  }
  if ( c != '6' ){
    printf("Uploading programmer...\n");
    sendLynxProgramm();
  }

  if ( erase ){
    printf("Erasing Flash\n");
    sendByte('C');
    sendByte('5');
    do{
      c = getByte();
    } while( c != 0x43 );
  } else if ( readCard == 1 ){
    printf("Read card...\n");
    for(i = 0; i < 256; ++i){
      readBlock(i);
    }
    saveImage(filename);
  } else if ( flashCard ){
    printf("Image CRC...\n");
    getImageCRC();
    int tmo = 0;
    do{
      printf("Get Lynx CRC...\n");
      getLynxCRC();

      for(o = 0,i = 0; i < 256; ++i){
        if ( imagecrc[i] == 0xffu ){
          force |= checkBlock(i) == 0;
        }
        if ( force == 1 || (lynxcrc[i] != imagecrc[i]) ){
          long x;
          printf(" %02x: %02x %c %02x: sending ...",
                 i,lynxcrc[i],
                 lynxcrc[i]==imagecrc[i] ? '=' : '!',imagecrc[i]);
          fflush(stdout);
          sendBlock(i);
          printf("!\n");
          ++o;
        }
      }
      force = 0;
      ++tmo;
      if ( tmo == 3 ){
        printf("error writing\n");
        return -1;
      }
    } while( o );
  }
  return 0;

}
