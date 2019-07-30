#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <string>
#include <vector>
#include <iostream>
#include <math.h>
#include <float.h>

#ifndef BLTiffIO_H
#define BLTiffIO_H

namespace BLTiffIO {
	class TiffInput
	{




			struct TinyTIFFReaderFile; 

	#include <sys/types.h>
	#include <sys/stat.h>

	#ifndef TRUE
	#  define TRUE 1
	#endif
	#ifndef FALSE
	#  define FALSE 0
	#endif


	#ifndef __WINDOWS__
	# if defined(WIN32) || defined(WIN64) || defined(_MSC_VER) || defined(_WIN32)
	#  define __WINDOWS__
	# endif
	#endif

	#ifndef __LINUX__
	# if defined(linux)
	#  define __LINUX__
	# endif
	#endif

	#define __USE_LIBC_FOR_TIFFReader__

	#ifdef __WINDOWS__
	#  ifndef __USE_LIBC_FOR_TIFFReader__
	#    define __USE_WINAPI_FIR_TIFF__
	#  endif
	#endif // __WINDOWS__

	#ifdef __USE_WINAPI_FIR_TIFF__
	#  include <windows.h>
			#  warning COMPILING TinyTIFFReader with WinAPI
	#  define TinyTIFFReader_POSTYPE DWORD
	#else
	#  define TinyTIFFReader_POSTYPE fpos_t
	#endif // __USE_WINAPI_FIR_TIFF__

	#define TIFF_LAST_ERROR_SIZE 1024


	#define TIFF_ORDER_UNKNOWN 0
	#define TIFF_ORDER_BIGENDIAN 1
	#define TIFF_ORDER_LITTLEENDIAN 2


	#define TIFF_FIELD_IMAGEWIDTH 256
	#define TIFF_FIELD_IMAGELENGTH 257
	#define TIFF_FIELD_BITSPERSAMPLE 258
	#define TIFF_FIELD_COMPRESSION 259
	#define TIFF_FIELD_PHOTOMETRICINTERPRETATION 262
	#define TIFF_FIELD_IMAGEDESCRIPTION 270
	#define TIFF_FIELD_STRIPOFFSETS 273
	#define TIFF_FIELD_SAMPLESPERPIXEL 277
	#define TIFF_FIELD_ROWSPERSTRIP 278
	#define TIFF_FIELD_STRIPBYTECOUNTS 279
	#define TIFF_FIELD_XRESOLUTION 282
	#define TIFF_FIELD_YRESOLUTION 283
	#define TIFF_FIELD_PLANARCONFIG 284
	#define TIFF_FIELD_RESOLUTIONUNIT 296
	#define TIFF_FIELD_SAMPLEFORMAT 339

	#define TIFF_TYPE_BYTE 1
	#define TIFF_TYPE_ASCII 2
	#define TIFF_TYPE_SHORT 3
	#define TIFF_TYPE_LONG 4
	#define TIFF_TYPE_RATIONAL 5

	#define TIFF_COMPRESSION_NONE 1
	#define TIFF_COMPRESSION_CCITT 2
	#define TIFF_COMPRESSION_PACKBITS 32773

	#define TIFF_PLANARCONFIG_CHUNKY 1
	#define TIFF_PLANARCONFIG_PLANAR 2




	#define TIFF_HEADER_SIZE 510
	#define TIFF_HEADER_MAX_ENTRIES 16

			int TIFFReader_get_byteorder() {
				union {
					long l;
					char c[4];
				} test;
				test.l = 1;
				if (test.c[3] && !test.c[2] && !test.c[1] && !test.c[0])
					return TIFF_ORDER_BIGENDIAN;

				if (!test.c[3] && !test.c[2] && !test.c[1] && test.c[0])
					return TIFF_ORDER_LITTLEENDIAN;

				return TIFF_ORDER_UNKNOWN;
			}

			struct TinyTIFFReaderFrame {
				uint32_t width;
				uint32_t height;
				uint16_t compression;

				uint32_t rowsperstrip;
				uint32_t* stripoffsets;
				uint32_t* stripbytecounts;
				uint32_t stripcount;
				uint16_t samplesperpixel;
				uint16_t bitspersample;
				uint16_t planarconfiguration;
				uint16_t sampleformat;
				uint32_t imagelength;

				char* description;
			};

			inline TinyTIFFReaderFrame TinyTIFFReader_getEmptyFrame() {
				TinyTIFFReaderFrame d;
				d.width = 0;
				d.height = 0;
				d.stripcount = 0;
				d.compression = TIFF_COMPRESSION_NONE;
				d.rowsperstrip = 0;
				d.stripoffsets = 0;
				d.stripbytecounts = 0;
				d.samplesperpixel = 1;
				d.bitspersample = 0;
				d.planarconfiguration = TIFF_PLANARCONFIG_PLANAR;
				d.sampleformat = 1;
				d.imagelength = 0;
				d.description = 0;
				return d;
			}

			inline void TinyTIFFReader_freeEmptyFrame(TinyTIFFReaderFrame f) {
				if (f.stripoffsets) free(f.stripoffsets);
				f.stripoffsets = NULL;
				if (f.stripbytecounts) free(f.stripbytecounts);
				f.stripbytecounts = NULL;
				//if (f.bitspersample) free(f.bitspersample);
				//f.bitspersample = NULL;
				if (f.description) free(f.description);
				f.description = NULL;
			}


			struct TinyTIFFReaderFile {
	#ifdef __USE_WINAPI_FIR_TIFF__
				HANDLE hFile;
	#else
				FILE* file;
	#endif // __USE_WINAPI_FIR_TIFF__

				char lastError[TIFF_LAST_ERROR_SIZE];
				int wasError;

				uint8_t systembyteorder;
				uint8_t filebyteorder;

				uint32_t firstrecord_offset;
				uint32_t nextifd_offset;

				uint64_t filesize;

				TinyTIFFReaderFrame currentFrame;
			};


			void TinyTIFFReader_fopen(TinyTIFFReaderFile* tiff, const char* filename) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				tiff->hFile = CreateFile(filename,               // name of the write
					GENERIC_READ,          // open for writing
					FILE_SHARE_READ,
					NULL,                   // default security
					OPEN_EXISTING,             // create new file only
					FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,  // normal file
					NULL);                  // no attr. template
	#else
				//tiff->file = fopen(filename, "rb");
				fopen_s(&(tiff->file), filename, "rb");
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			int TinyTIFFReader_fclose(TinyTIFFReaderFile* tiff) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				CloseHandle(tiff->hFile);
				return 0;
	#else
				int r = fclose(tiff->file);
				tiff->file = NULL;
				return r;
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			int TinyTIFFReader_fOK(const TinyTIFFReaderFile* tiff) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				if (tiff->hFile == INVALID_HANDLE_VALUE) return FALSE;
				else return TRUE;
	#else
				if (tiff->file) {
					return TRUE;
				}
				return FALSE;
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			int TinyTIFFReader_fseek_set(TinyTIFFReaderFile* tiff, size_t offset) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				DWORD res = SetFilePointer(tiff->hFile,
					offset,
					NULL,
					FILE_BEGIN);


				return res;
	#else
				return fseek(tiff->file, offset, SEEK_SET);
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			int TinyTIFFReader_fseek_cur(TinyTIFFReaderFile* tiff, size_t offset) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				DWORD res = SetFilePointer(tiff->hFile,
					offset,
					NULL,
					FILE_CURRENT);


				return res;
	#else
				return fseek(tiff->file, offset, SEEK_CUR);
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			size_t TinyTIFFReader_fread(void * ptr, size_t size, size_t count, TinyTIFFReaderFile* tiff) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				DWORD  dwBytesRead = 0;
				if (!ReadFile(tiff->hFile, ptr, size*count, &dwBytesRead, NULL)) {
					return 0;
				}
				return dwBytesRead;
	#else
				return fread(ptr, size, count, tiff->file);
	#endif // __USE_WINAPI_FIR_TIFF__
			}


			inline long int TinyTIFFReader_ftell(TinyTIFFReaderFile * tiff) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				DWORD dwPtr = SetFilePointer(tiff->hFile,
					0,
					NULL,
					FILE_CURRENT);
				return dwPtr;
	#else
				return ftell(tiff->file);
	#endif
			}

			int TinyTIFFReader_fgetpos(TinyTIFFReaderFile* tiff, TinyTIFFReader_POSTYPE* pos) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				*pos = SetFilePointer(tiff->hFile,
					0,
					NULL,
					FILE_CURRENT);
				return 0;
	#else
				return fgetpos(tiff->file, pos);
	#endif // __USE_WINAPI_FIR_TIFF__
			}

			int TinyTIFFReader_fsetpos(TinyTIFFReaderFile* tiff, const TinyTIFFReader_POSTYPE* pos) {
	#ifdef __USE_WINAPI_FIR_TIFF__
				SetFilePointer(tiff->hFile,
					*pos,
					NULL,
					FILE_BEGIN);
				return 0;
	#else
				return fsetpos(tiff->file, pos);
	#endif // __USE_WINAPI_FIR_TIFF__
			}




			const char* TinyTIFFReader_getLastError(TinyTIFFReaderFile* tiff) {
				if (tiff) return tiff->lastError;
				return NULL;
			}

			int TinyTIFFReader_wasError(TinyTIFFReaderFile* tiff) {
				if (tiff) return tiff->wasError;
				return TRUE;
			}

			int TinyTIFFReader_success(TinyTIFFReaderFile* tiff) {
				if (tiff) return !tiff->wasError;
				return FALSE;
			}



			inline static uint32_t TinyTIFFReader_Byteswap32(uint32_t nLongNumber)
			{
				return (((nLongNumber & 0x000000FF) << 24) + ((nLongNumber & 0x0000FF00) << 8) +
					((nLongNumber & 0x00FF0000) >> 8) + ((nLongNumber & 0xFF000000) >> 24));
			}

			inline static uint16_t TinyTIFFReader_Byteswap16(uint16_t nValue)
			{
				return (((nValue >> 8)) | (nValue << 8));
			}

			inline uint32_t TinyTIFFReader_readuint32(TinyTIFFReaderFile* tiff) {
				uint32_t res = 0;
				//fread(&res, 4,1,tiff->file);
				TinyTIFFReader_fread(&res, 4, 1, tiff);
				if (tiff->systembyteorder != tiff->filebyteorder) {
					res = TinyTIFFReader_Byteswap32(res);
				}
				return res;
			}


			inline uint16_t TinyTIFFReader_readuint16(TinyTIFFReaderFile* tiff) {
				uint16_t res = 0;
				//fread(&res, 2,1,tiff->file);
				TinyTIFFReader_fread(&res, 2, 1, tiff);
				if (tiff->systembyteorder != tiff->filebyteorder) {
					res = TinyTIFFReader_Byteswap16(res);
				}
				return res;
			}

			inline uint8_t TinyTIFFReader_readuint8(TinyTIFFReaderFile* tiff) {
				uint8_t res = 0;
				//fread(&res, 1,1,tiff->file);
				TinyTIFFReader_fread(&res, 1, 1, tiff);
				return res;
			}


			struct TinyTIFFReader_IFD {
				uint16_t tag;
				uint16_t type;
				uint32_t count;
				uint32_t value;
				uint32_t value2;

				uint32_t* pvalue;
				uint32_t* pvalue2;
			};

			inline void TinyTIFFReader_freeIFD(TinyTIFFReader_IFD d) {
				if (d.pvalue /*&& d.count>1*/) { free(d.pvalue);  d.pvalue = NULL; }
				if (d.pvalue2 /*&& d.count>1*/) { free(d.pvalue2);  d.pvalue2 = NULL; }
			}

			inline TinyTIFFReader_IFD TinyTIFFReader_readIFD(TinyTIFFReaderFile* tiff) {
				TinyTIFFReader_IFD d;

				d.value = 0;
				d.value2 = 0;

				d.pvalue = 0;
				d.pvalue2 = 0;

				d.count = 1;
				d.tag = TinyTIFFReader_readuint16(tiff);
				d.type = TinyTIFFReader_readuint16(tiff);
				d.count = TinyTIFFReader_readuint32(tiff);
				//uint32_t val=TinyTIFFReader_readuint32(tiff);
				TinyTIFFReader_POSTYPE pos;
				//fgetpos(tiff->file, &pos);
				TinyTIFFReader_fgetpos(tiff, &pos);
				int changedpos = FALSE;
				//printf("    - pos=0x%X   tag=%d type=%d count=%u \n",pos, d.tag, d.type, d.count);
				switch (d.type) {
				case TIFF_TYPE_BYTE:
				case TIFF_TYPE_ASCII:
					if (d.count > 0) {
						d.pvalue = (uint32_t*)calloc(d.count, sizeof(uint32_t));
						if (d.count <= 4) {
							unsigned int i;
							for (i = 0; i < 4; i++) {
								uint32_t v = TinyTIFFReader_readuint8(tiff);
								if (i < d.count) d.pvalue[i] = v;
							}
						}
						else {
							changedpos = TRUE;
							uint32_t offset = TinyTIFFReader_readuint32(tiff);

							if (offset + d.count * 1 <= tiff->filesize) {
								//fseek(tiff->file, offset, SEEK_SET);
								TinyTIFFReader_fseek_set(tiff, offset);
								unsigned int i;
								for (i = 0; i < d.count; i++) {
									d.pvalue[i] = TinyTIFFReader_readuint8(tiff);
								}
							}
						}
					}
					d.pvalue2 = NULL;
					//printf("    - BYTE/CHAR: tag=%d count=%u   val[0]=%u\n",d.tag,d.count, d.pvalue[0]);
					break;
				case TIFF_TYPE_SHORT:
					d.pvalue = (uint32_t*)calloc(d.count, sizeof(uint32_t));
					if (d.count <= 2) {
						unsigned int i;
						for (i = 0; i < 2; i++) {
							uint32_t v = TinyTIFFReader_readuint16(tiff);
							if (i < d.count) d.pvalue[i] = v;
						}
					}
					else {
						changedpos = TRUE;
						uint32_t offset = TinyTIFFReader_readuint32(tiff);
						if (offset + d.count * 2 < tiff->filesize) {
							//fseek(tiff->file, offset, SEEK_SET);
							TinyTIFFReader_fseek_set(tiff, offset);
							unsigned int i;
							for (i = 0; i < d.count; i++) {
								d.pvalue[i] = TinyTIFFReader_readuint16(tiff);
							}
						}
					}
					d.pvalue2 = NULL;
					//printf("    - SHORT: tag=%d count=%u   val[0]=%u\n",d.tag,d.count, d.pvalue[0]);
					break;

				case TIFF_TYPE_LONG:
					d.pvalue = (uint32_t*)calloc(d.count, sizeof(uint32_t));
					if (d.count <= 1) {
						d.pvalue[0] = TinyTIFFReader_readuint32(tiff);
					}
					else {
						changedpos = TRUE;
						uint32_t offset = TinyTIFFReader_readuint32(tiff);
						if (offset + d.count * 4 < tiff->filesize) {
							//fseek(tiff->file, offset, SEEK_SET);
							TinyTIFFReader_fseek_set(tiff, offset);
							uint32_t i;
							for (i = 0; i < d.count; i++) {
								d.pvalue[i] = TinyTIFFReader_readuint32(tiff);
							}
						}
						//printf("    - LONG: pos=0x%X   offset=0x%X   tag=%d count=%u   val[0]=%u\n",pos, offset,d.tag,d.count, d.pvalue[0]);
					}
					d.pvalue2 = NULL;
					//printf("    - LONG: tag=%d count=%u   val[0]=%u\n",d.tag,d.count, d.pvalue[0]);
					break;
				case TIFF_TYPE_RATIONAL: {
					d.pvalue = (uint32_t*)calloc(d.count, sizeof(uint32_t));
					d.pvalue2 = (uint32_t*)calloc(d.count, sizeof(uint32_t));

					changedpos = TRUE;
					uint32_t offset = TinyTIFFReader_readuint32(tiff);
					if (offset + d.count * 4 < tiff->filesize) {
						//fseek(tiff->file, offset, SEEK_SET);
						TinyTIFFReader_fseek_set(tiff, offset);
						uint32_t i;
						for (i = 0; i < d.count; i++) {
							d.pvalue[i] = TinyTIFFReader_readuint32(tiff);
							d.pvalue2[i] = TinyTIFFReader_readuint32(tiff);
						}
					}
					//printf("    - RATIONAL: pos=0x%X   offset=0x%X   tag=%d count=%u   val[0]=%u/%u\n",pos, offset,d.tag,d.count, d.pvalue[0], d.pvalue[1]);
				} break;

				default: d.value = TinyTIFFReader_readuint32(tiff); break;
				}
				if (d.pvalue) d.value = d.pvalue[0];
				if (d.pvalue2) d.value2 = d.pvalue2[0];

				if (changedpos) {
					//fsetpos(tiff->file, &pos);
					TinyTIFFReader_fsetpos(tiff, &pos);
					//fseek(tiff->file, 4, SEEK_CUR);
					TinyTIFFReader_fseek_cur(tiff, 4);
				}
				return d;
			}


			inline void TinyTIFFReader_readNextFrame(TinyTIFFReaderFile* tiff) {

				TinyTIFFReader_freeEmptyFrame(tiff->currentFrame);
				tiff->currentFrame = TinyTIFFReader_getEmptyFrame();
	#ifdef DEBUG_IFDTIMING
				HighResTimer timer;
				timer.start();
	#endif
				if (tiff->nextifd_offset != 0 && tiff->nextifd_offset + 2 < tiff->filesize) {
					//printf("    - seeking=0x%X\n", tiff->nextifd_offset);
					//fseek(tiff->file, tiff->nextifd_offset, SEEK_SET);
					TinyTIFFReader_fseek_set(tiff, tiff->nextifd_offset);
					uint16_t ifd_count = TinyTIFFReader_readuint16(tiff);
					//printf("    - tag_count=%u\n", ifd_count);
					uint16_t i;
					for (i = 0; i < ifd_count; i++) {
	#ifdef DEBUG_IFDTIMING
						timer.start();
	#endif
						TinyTIFFReader_IFD ifd = TinyTIFFReader_readIFD(tiff);
	#ifdef DEBUG_IFDTIMING
						//printf("    - readIFD %d (tag: %u, type: %u, count: %u): %lf us\n", i, ifd.tag, ifd.type, ifd.count, timer.get_time());
	#endif
					//printf("    - readIFD %d (tag: %u, type: %u, count: %u)\n", i, ifd.tag, ifd.type, ifd.count);
						switch (ifd.tag) {
						case TIFF_FIELD_IMAGEWIDTH: tiff->currentFrame.width = ifd.value;  break;
						case TIFF_FIELD_IMAGELENGTH: tiff->currentFrame.imagelength = ifd.value;  break;
						case TIFF_FIELD_BITSPERSAMPLE: {							
							 tiff->currentFrame.bitspersample = ifd.value;
							//tiff->currentFrame.bitspersample = (uint16_t*)malloc(ifd.count * sizeof(uint16_t));
							//memcpy(tiff->currentFrame.bitspersample, ifd.pvalue, ifd.count * sizeof(uint16_t));
						} break;
						case TIFF_FIELD_COMPRESSION: tiff->currentFrame.compression = ifd.value; break;
						case TIFF_FIELD_STRIPOFFSETS: {
							tiff->currentFrame.stripcount = ifd.count;
							tiff->currentFrame.stripoffsets = (uint32_t*)calloc(ifd.count, sizeof(uint32_t));
							memcpy(tiff->currentFrame.stripoffsets, ifd.pvalue, ifd.count * sizeof(uint32_t));
						} break;
						case TIFF_FIELD_SAMPLESPERPIXEL: tiff->currentFrame.samplesperpixel = ifd.value; break;
						case TIFF_FIELD_ROWSPERSTRIP: tiff->currentFrame.rowsperstrip = ifd.value; break;
						case TIFF_FIELD_SAMPLEFORMAT: tiff->currentFrame.sampleformat = ifd.value; break;
						case TIFF_FIELD_IMAGEDESCRIPTION: {
							//printf("TIFF_FIELD_IMAGEDESCRIPTION: (tag: %u, type: %u, count: %u)\n", ifd.tag, ifd.type, ifd.count);
							if (ifd.count > 0) {
								if (tiff->currentFrame.description) free(tiff->currentFrame.description);
								tiff->currentFrame.description = (char*)calloc(ifd.count + 1, sizeof(char));
								for (uint32_t ji = 0; ji < ifd.count + 1; ji++) {
									tiff->currentFrame.description[ji] = '\0';
								}
								for (uint32_t ji = 0; ji < ifd.count; ji++) {
									tiff->currentFrame.description[ji] = (char)ifd.pvalue[ji];
									//printf(" %d[%d]", int(tiff->currentFrame.description[ji]), int(ifd.pvalue[ji]));
								}
								//printf("\n  %s\n", tiff->currentFrame.description);
							}
						} break;
						case TIFF_FIELD_STRIPBYTECOUNTS: {
							tiff->currentFrame.stripcount = ifd.count;
							tiff->currentFrame.stripbytecounts = (uint32_t*)calloc(ifd.count, sizeof(uint32_t));
							memcpy(tiff->currentFrame.stripbytecounts, ifd.pvalue, ifd.count * sizeof(uint32_t));
						} break;
						case TIFF_FIELD_PLANARCONFIG: tiff->currentFrame.planarconfiguration = ifd.value; break;
						default: break;
						}
						TinyTIFFReader_freeIFD(ifd);
						//printf("    - tag=%u\n", ifd.tag);
					}
					tiff->currentFrame.height = tiff->currentFrame.imagelength;
					//printf("      - width=%u\n", tiff->currentFrame.width);
					//printf("      - height=%u\n", tiff->currentFrame.height);
					//fseek(tiff->file, tiff->nextifd_offset+2+12*ifd_count, SEEK_SET);
					TinyTIFFReader_fseek_set(tiff, tiff->nextifd_offset + 2 + 12 * ifd_count);
					tiff->nextifd_offset = TinyTIFFReader_readuint32(tiff);
					//printf("      - nextifd_offset=%lu\n", tiff->nextifd_offset);
				}
				else {
					tiff->wasError = TRUE;
					strcpy_s(tiff->lastError, "no more images in TIF file\0");
				}
			}

			int TinyTIFFReader_getSampleData(TinyTIFFReaderFile* tiff, void* buffer) {
				if (tiff) {
					//tiff->currentFrame.bitspersample[0] = depth;
					if (tiff->currentFrame.compression != TIFF_COMPRESSION_NONE) {
						tiff->wasError = TRUE;
						strcpy_s(tiff->lastError, "the compression of the file is not supported by this library\0");
						return FALSE;
					}
					if (tiff->currentFrame.samplesperpixel > 1 && tiff->currentFrame.planarconfiguration != TIFF_PLANARCONFIG_PLANAR) {
						tiff->wasError = TRUE;
						strcpy_s(tiff->lastError, "only planar TIFF files are supported by this library\0");
						return FALSE;
					}
					if (tiff->currentFrame.width == 0 || tiff->currentFrame.height == 0) {
						tiff->wasError = TRUE;
						strcpy_s(tiff->lastError, "the current frame does not contain images\0");
						return FALSE;
					}
					if (tiff->currentFrame.bitspersample != 8 && tiff->currentFrame.bitspersample != 16 && tiff->currentFrame.bitspersample != 32) {
						tiff->wasError = TRUE;
						::std::cout << " ERROR this library only support 8,16 and 32 bits per sample - Detected : " << tiff->currentFrame.bitspersample << "\n";
						strcpy_s(tiff->lastError, "this library only support 8,16 and 32 bits per sample\0");
						return FALSE;
					}
					TinyTIFFReader_POSTYPE pos;
					//fgetpos(tiff->file, &pos);
					TinyTIFFReader_fgetpos(tiff, &pos);
					tiff->wasError = FALSE;

					//printf("    - stripcount=%u\n", tiff->currentFrame.stripcount);
					if (tiff->currentFrame.stripcount > 0 && tiff->currentFrame.stripbytecounts && tiff->currentFrame.stripoffsets) {
						uint32_t s;
						//printf("    - bitspersample[sample]=%u\n", tiff->currentFrame.bitspersample[sample]);
						if (tiff->currentFrame.bitspersample == 8) {
							for (s = 0; s < tiff->currentFrame.stripcount; s++) {
								//printf("      - s=%u: stripoffset=0x%X stripbytecounts=%u\n", s, tiff->currentFrame.stripoffsets[s], tiff->currentFrame.stripbytecounts[s]);
								uint8_t* tmp = (uint8_t*)calloc(tiff->currentFrame.stripbytecounts[s], sizeof(uint8_t));
								//fseek(tiff->file, tiff->currentFrame.stripoffsets[s], SEEK_SET);
								TinyTIFFReader_fseek_set(tiff, tiff->currentFrame.stripoffsets[s]);
								//fread(tmp, tiff->currentFrame.stripbytecounts[s], 1, tiff->file);
								TinyTIFFReader_fread(tmp, tiff->currentFrame.stripbytecounts[s], 1, tiff);
								uint32_t offset = s*tiff->currentFrame.rowsperstrip*tiff->currentFrame.width;
								//printf("          bufferoffset=%u\n", offset);
								memcpy(&(((uint8_t*)buffer)[offset]), tmp, tiff->currentFrame.stripbytecounts[s]);
								free(tmp);
							}
						}
						else if (tiff->currentFrame.bitspersample == 16) {
							for (s = 0; s < tiff->currentFrame.stripcount; s++) {
								//printf("      - s=%u: stripoffset=0x%X stripbytecounts=%u\n", s, tiff->currentFrame.stripoffsets[s], tiff->currentFrame.stripbytecounts[s]);
								uint16_t* tmp = (uint16_t*)calloc(tiff->currentFrame.stripbytecounts[s], sizeof(uint8_t));
								//fseek(tiff->file, tiff->currentFrame.stripoffsets[s], SEEK_SET);
								TinyTIFFReader_fseek_set(tiff, tiff->currentFrame.stripoffsets[s]);
								//fread(tmp, tiff->currentFrame.stripbytecounts[s], 1, tiff->file);
								TinyTIFFReader_fread(tmp, tiff->currentFrame.stripbytecounts[s], 1, tiff);
								uint32_t offset = s*tiff->currentFrame.rowsperstrip*tiff->currentFrame.width;
								//memcpy(&(((uint8_t*)buffer)[offset*2]), tmp, tiff->currentFrame.stripbytecounts[s]);
								uint32_t pixels = tiff->currentFrame.rowsperstrip*tiff->currentFrame.width;
								uint32_t imagesize = tiff->currentFrame.width*tiff->currentFrame.height;
								if (offset + pixels > imagesize) pixels = imagesize - offset;
								uint32_t x;
								if (tiff->systembyteorder == tiff->filebyteorder) {
									memcpy(&(((uint16_t*)buffer)[offset]), tmp, tiff->currentFrame.stripbytecounts[s]);
								}
								else {
									for (x = 0; x < pixels; x++) {
										((uint16_t*)buffer)[offset + x] = TinyTIFFReader_Byteswap16(tmp[x]);
									}
								}
								free(tmp);
							}
						}
						else if (tiff->currentFrame.bitspersample == 32) {
							for (s = 0; s < tiff->currentFrame.stripcount; s++) {
								//printf("      - s=%u: stripoffset=0x%X stripbytecounts=%u\n", s, tiff->currentFrame.stripoffsets[s], tiff->currentFrame.stripbytecounts[s]);
								uint32_t* tmp = (uint32_t*)calloc(tiff->currentFrame.stripbytecounts[s], sizeof(uint8_t));
								//fseek(tiff->file, tiff->currentFrame.stripoffsets[s], SEEK_SET);
								TinyTIFFReader_fseek_set(tiff, tiff->currentFrame.stripoffsets[s]);
								//fread(tmp, tiff->currentFrame.stripbytecounts[s], 1, tiff->file);
								uint32_t offset = s*tiff->currentFrame.rowsperstrip*tiff->currentFrame.width;
								//memcpy(&(((uint8_t*)buffer)[offset*2]), tmp, tiff->currentFrame.stripbytecounts[s]);
								uint32_t pixels = tiff->currentFrame.rowsperstrip*tiff->currentFrame.width;
								uint32_t imagesize = tiff->currentFrame.width*tiff->currentFrame.height;
								if (offset + pixels > imagesize) pixels = imagesize - offset;
								uint32_t x;
								for (x = 0; x < pixels; x++) {
									((uint32_t*)buffer)[offset + x] = TinyTIFFReader_readuint32(tiff);
								}
								free(tmp);
							}
						}

					}
					else {
						tiff->wasError = TRUE;
						strcpy_s(tiff->lastError, "TIFF format not recognized\0");
					}

					//fsetpos(tiff->file, &pos);
					TinyTIFFReader_fsetpos(tiff, &pos);
					return !tiff->wasError;
				}
				tiff->wasError = TRUE;
				strcpy_s(tiff->lastError, "TIFF file not opened\0");
				return FALSE;
			}
















			TinyTIFFReaderFile* TinyTIFFReader_open(const char* filename) {
				TinyTIFFReaderFile* tiff = (TinyTIFFReaderFile*)malloc(sizeof(TinyTIFFReaderFile));

				tiff->filesize = 0;
				struct stat file;
				if (stat(filename, &file) == 0) {
					tiff->filesize = file.st_size;
				}
				tiff->currentFrame = TinyTIFFReader_getEmptyFrame();


				//tiff->file=v(filename, "rb");
				TinyTIFFReader_fopen(tiff, filename);
				tiff->systembyteorder = TIFFReader_get_byteorder();
				memset(tiff->lastError, 0, TIFF_LAST_ERROR_SIZE);
				tiff->wasError = FALSE;
				if (TinyTIFFReader_fOK(tiff) && tiff->filesize > 0) {
					uint8_t tiffid[3] = { 0,0,0 };
					//fread(tiffid, 1,2,tiff->file);
					TinyTIFFReader_fread(tiffid, 1, 2, tiff);

					//printf("      - head=%s\n", tiffid);
					if (tiffid[0] == 'I' && tiffid[1] == 'I') tiff->filebyteorder = TIFF_ORDER_LITTLEENDIAN;
					else if (tiffid[0] == 'M' && tiffid[1] == 'M') tiff->filebyteorder = TIFF_ORDER_BIGENDIAN;
					else {
						free(tiff);
						return NULL;
					}
					uint16_t magic = TinyTIFFReader_readuint16(tiff);
					//printf("      - magic=%u\n", magic);
					if (magic != 42) {
						free(tiff);
						return NULL;
					}
					tiff->firstrecord_offset = TinyTIFFReader_readuint32(tiff);
					tiff->nextifd_offset = tiff->firstrecord_offset;
					//printf("      - filesize=%u\n", tiff->filesize);
					//printf("      - firstrecord_offset=%4X\n", tiff->firstrecord_offset);
					TinyTIFFReader_readNextFrame(tiff);
				}
				else {
					free(tiff);
					return NULL;
				}

				return tiff;
			}

			void TinyTIFFReader_close(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					TinyTIFFReader_freeEmptyFrame(tiff->currentFrame);
					//fclose(tiff->file);
					TinyTIFFReader_fclose(tiff);
					free(tiff);
				}
			}

			int TinyTIFFReader_hasNext(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					if (tiff->nextifd_offset > 0 && tiff->nextifd_offset < tiff->filesize) return TRUE;
					else return FALSE;
				}
				else {
					return FALSE;
				}
			}

			int TinyTIFFReader_readNext(TinyTIFFReaderFile* tiff) {
				int hasNext = TinyTIFFReader_hasNext(tiff);
				if (hasNext) {
					TinyTIFFReader_readNextFrame(tiff);
				}
				return hasNext;
			}

			uint32_t TinyTIFFReader_getWidth(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					return tiff->currentFrame.width;
				}
				return 0;
			}

			uint32_t TinyTIFFReader_getHeight(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					return tiff->currentFrame.height;
				}
				return 0;
			}

			::std::string TinyTIFFReader_getImageDescription(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					if (tiff->currentFrame.description) return ::std::string(tiff->currentFrame.description);
				}
				return ::std::string();
			}

			uint16_t TinyTIFFReader_getSampleFormat(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					return tiff->currentFrame.sampleformat;
				}
				return 0;
			}

			uint16_t TinyTIFFReader_getBitsPerSample(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					return tiff->currentFrame.bitspersample;
				}
				return 0;
			}

			uint16_t TinyTIFFReader_getSamplesPerPixel(TinyTIFFReaderFile* tiff) {
				if (tiff) {
					return tiff->currentFrame.samplesperpixel;
				}
				return 0;
			}


			uint32_t TinyTIFFReader_countFrames(TinyTIFFReaderFile* tiff) {

				if (tiff) {
					uint32_t frames = 0;
					TinyTIFFReader_POSTYPE pos;
					//printf("    -> countFrames: pos before %ld\n", ftell(tiff->file));
					//fgetpos(tiff->file, &pos);
					TinyTIFFReader_fgetpos(tiff, &pos);

					uint32_t nextOffset = tiff->firstrecord_offset;
					while (nextOffset > 0) {
						//fseek(tiff->file, nextOffset, SEEK_SET);
						TinyTIFFReader_fseek_set(tiff, nextOffset);
						uint16_t count = TinyTIFFReader_readuint16(tiff);
						//fseek(tiff->file, count*12, SEEK_CUR);
						TinyTIFFReader_fseek_cur(tiff, count * 12);
						nextOffset = TinyTIFFReader_readuint32(tiff);
						frames++;
					}


					//fsetpos(tiff->file, &pos);
					TinyTIFFReader_fsetpos(tiff, &pos);
					//printf("    -> countFrames: pos after %ld\n", ftell(tiff->file));
					return frames;
				}
				return 0;
			}


	
		TinyTIFFReaderFile* tiffr = NULL;
		::std::vector<uint16_t> image;
		public:
			int numofframes = 0, height = 0, width = 0, depth = 0, numofpixels = 0, numofchannels = 1, pageNumber = 0;

			TiffInput() {};

			TiffInput(::std::string filename) {
			
				tiffr = TinyTIFFReader_open(filename.c_str());
				if (!tiffr) {
					::std::cout << "    ERROR reading (not existent, not accessible or no TIFF file)\n";
				}
				else {
					width = TinyTIFFReader_getWidth(tiffr);
					height = TinyTIFFReader_getHeight(tiffr);
					numofframes = TinyTIFFReader_countFrames(tiffr);
					numofpixels = width*height;
					numofchannels = TinyTIFFReader_getSamplesPerPixel(tiffr);
					depth = TinyTIFFReader_getBitsPerSample(tiffr);
					size_t bitdepth = 0;
					if (depth == 8)bitdepth = sizeof(uint8_t);
					else if (depth == 16)bitdepth = sizeof(uint16_t);
					else if (depth == 32)bitdepth = sizeof(uint32_t);
					image.resize(width*height);
				}
			

			}


			template <typename vectortype>
			void get1dimage(::std::vector<vectortype>& imageout) {
				imageout.resize(width*height);
				if (!tiffr) {
					::std::cout << "    ERROR Image is not open\n";
				}
				else if(numofchannels>1)::std::cout << "Error: Colour Images Require a 3D array\n";
				else {
					TinyTIFFReader_getSampleData(tiffr, image.data());
					for (int i = 0; i < numofpixels; i++)imageout[i] = (vectortype)image[i];
					TinyTIFFReader_readNext(tiffr);
					pageNumber++;
				}
			}

			template <typename vectortype>
			void get2dimage(::std::vector<::std::vector<vectortype>>& imageout) {
				imageout.resize(width);
				for (int i = 0; i < width; i++)imageout[i].resize(height);

				if (!tiffr) {
					::std::cout << "    ERROR Image is not open\n";
				}
				else if (numofchannels>1)::std::cout << "Error: Colour Images Require a 3D array\n";
				else {
					TinyTIFFReader_getSampleData(tiffr, image.data());
					for (int i = 0; i < numofpixels; i++)imageout[i%width][(int)(i/width)] = (vectortype)image[i];
					TinyTIFFReader_readNext(tiffr);
					pageNumber++;
				}
			}

			~TiffInput() {
				//TinyTIFFReader_close(tiffr);
			}

	};

	class TiffOutput
	{


			#ifndef __WINDOWS__
			# if defined(WIN32) || defined(WIN64) || defined(_MSC_VER) || defined(_WIN32)
			#  define __WINDOWS__
			# endif
			#endif

			#ifndef __LINUX__
			# if defined(linux)
			#  define __LINUX__
			# endif
			#endif

			#define __USE_LIBC_FOR_TIFF__
			#ifdef __WINDOWS__
			#  ifndef __USE_LIBC_FOR_TIFF__
			#    define __USE_WINAPI_FOR_TIFF__
			#  endif
			#endif // __WINDOWS__

			#ifdef __USE_WINAPI_FOR_TIFF__
			#  include <windows.h>
					#  warning COMPILING TinyTIFFWriter with WinAPI
			#endif // __USE_WINAPI_FOR_TIFF__

			#define TIFF_ORDER_UNKNOWN 0
			#define TIFF_ORDER_BIGENDIAN 1
			#define TIFF_ORDER_LITTLEENDIAN 2


			#define TINYTIFFWRITER_DESCRIPTION_SIZE 1024

						int TinyTIFFWriter_getMaxDescriptionTextSize() {
						return TINYTIFFWRITER_DESCRIPTION_SIZE;
					}

					/*! \brief determines the byte order of the system
					\ingroup tinytiffwriter
					\internal

					\return TIFF_ORDER_BIGENDIAN or TIFF_ORDER_LITTLEENDIAN, or TIFF_ORDER_UNKNOWN if the byte order cannot be determined
					*/
					int TIFF_get_byteorder()
					{
						union {
							long l;
							char c[4];
						} test;
						test.l = 1;
						if (test.c[3] && !test.c[2] && !test.c[1] && !test.c[0])
							return TIFF_ORDER_BIGENDIAN;

						if (!test.c[3] && !test.c[2] && !test.c[1] && test.c[0])
							return TIFF_ORDER_LITTLEENDIAN;

						return TIFF_ORDER_UNKNOWN;
					}


					/*! \brief this struct represents a TIFF file
					\ingroup tinytiffwriter
					\internal
					*/
					struct TinyTIFFFile {
			#ifdef __USE_WINAPI_FOR_TIFF__
						/* \brief the windows API file handle */
						HANDLE hFile;
			#else
						/* \brief the libc file handle */
						FILE* file;
			#endif // __USE_WINAPI_FOR_TIFF__
						/* \brief position of the field in the previously written IFD/header, which points to the next frame. This is set to 0, when closing the file to indicate, the last frame! */
						uint32_t lastIFDOffsetField;
						/* \brief file position (from ftell) of the first byte of the previous IFD/frame header */
						long int lastStartPos;
						//uint32_t lastIFDEndAdress;
						uint32_t lastIFDDATAAdress;
						/* \brief counts the entries in the current IFD/frame header */
						uint16_t lastIFDCount;
						/* \brief temporary data array for the current header */
						uint8_t* lastHeader;
						int lastHeaderSize;
						/* \brief current write position in lastHeader */
						uint32_t pos;
						/* \brief width of the frames */
						uint32_t width;
						/* \brief height of the frames */
						uint32_t height;
						/* \brief bits per sample of the frames */
						uint16_t bitspersample;
						uint32_t descriptionOffset;
						uint32_t descriptionSizeOffset;
						/* \brief counter for the frames, written into the file */
						uint64_t frames;
						/* \brief specifies the byte order of the system (and the written file!) */
						uint8_t byteorder;
					};

					/*! \brief wrapper around fopen
					\ingroup tinytiffwriter
					\internal
					*/
					inline void TinyTIFFWriter_fopen(TinyTIFFFile* tiff, const char* filename) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						tiff->hFile = CreateFile(filename,               // name of the write
							GENERIC_WRITE,          // open for writing
							0,                      // do not share
							NULL,                   // default security
							CREATE_NEW,             // create new file only
							FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH,  // normal file
							NULL);                  // no attr. template
			#else
						 fopen_s(&(tiff->file),filename,"wb");
			#endif
					}

					/*! \brief checks whether a file was opened successfully
					\ingroup tinytiffwriter
					\internal
					*/
					inline int TinyTIFFWriter_fOK(TinyTIFFFile* tiff) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						if (tiff->hFile == INVALID_HANDLE_VALUE) return FALSE;
						else return TRUE;
			#else
						if (tiff->file) return TRUE;
						else return FALSE;
			#endif
					}

					/*! \brief wrapper around fclose
					\ingroup tinytiffwriter
					\internal
					*/
					inline int TinyTIFFWriter_fclose(TinyTIFFFile* tiff) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						CloseHandle(tiff->hFile);
						return 0;
			#else
						int r = fclose(tiff->file);
						tiff->file = NULL;
						return r;
			#endif
					}

					/*! \brief wrapper around fwrite
					\ingroup tinytiffwriter
					\internal
					*/
					inline size_t TinyTIFFWriter_fwrite(void * ptr, size_t size, size_t count, TinyTIFFFile* tiff) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						DWORD dwBytesWritten = 0;
						WriteFile(
							tiff->hFile,           // open file handle
							ptr,      // start of data to write
							size*count,  // number of bytes to write
							&dwBytesWritten, // number of bytes that were written
							NULL);
						return dwBytesWritten;
			#else
						return fwrite(ptr, size, count, tiff->file);
			#endif
					}

					/*! \brief wrapper around ftell
					\ingroup tinytiffwriter
					\internal
					*/
					inline long int TinyTIFFWriter_ftell(TinyTIFFFile * tiff) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						DWORD dwPtr = SetFilePointer(tiff->hFile,
							0,
							NULL,
							FILE_CURRENT);
						return dwPtr;
			#else
						return ftell(tiff->file);
			#endif
					}


					/*! \brief wrapper around fseek
					\ingroup tinytiffwriter
					\internal
					*/
					inline int TinyTIFFWriter_fseek_set(TinyTIFFFile* tiff, size_t offset) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						DWORD res = SetFilePointer(tiff->hFile,
							offset,
							NULL,
							FILE_BEGIN);


						return res;
			#else
						return fseek(tiff->file, offset, SEEK_SET);
			#endif // __USE_WINAPI_FOR_TIFF__
					}

					/*! \brief wrapper around fseek(..., FILE_CURRENT)
					\ingroup tinytiffwriter
					\internal
					*/
					inline int TinyTIFFWriter_fseek_cur(TinyTIFFFile* tiff, size_t offset) {
			#ifdef __USE_WINAPI_FOR_TIFF__
						DWORD res = SetFilePointer(tiff->hFile,
							offset,
							NULL,
							FILE_CURRENT);


						return res;
			#else
						return fseek(tiff->file, offset, SEEK_CUR);
			#endif // __USE_WINAPI_FOR_TIFF__
					}





					/*! \brief write a 4-byte word \a data directly into a file \a fileno
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITE32DIRECT(filen, data)  { \
				TinyTIFFWriter_fwrite((void*)(&(data)), 4, 1, filen); \
			}

					/*! \brief write a data word \a data , which is first cast into a 4-byte word directly into a file \a fileno
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITE32DIRECT_CAST(filen, data)  { \
				uint32_t d=data; \
				WRITE32DIRECT((filen), d); \
			}






					/*! \brief write a 2-byte word \a data directly into a file \a fileno
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITE16DIRECT(filen, data)    { \
				TinyTIFFWriter_fwrite((void*)(&(data)), 2, 1, filen); \
			}

					/*! \brief write a data word \a data , which is first cast into a 2-byte word directly into a file \a fileno
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITE16DIRECT_CAST(filen, data)    { \
				uint16_t d=data; \
				WRITE16DIRECT((filen), d); \
			}




					/*! \brief write a data word \a data , which is first cast into a 1-byte word directly into a file \a fileno
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITE8DIRECT(filen, data) {\
				uint8_t ch=data; \
				TinyTIFFWriter_fwrite(&ch, 1, 1, filen);\
			}




					/*! \brief writes a 32-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH32DIRECT_LE(filen, data)  { \
				*((uint32_t*)(&filen->lastHeader[filen->pos]))=data; \
				filen->pos+=4;\
			}
					/*! \brief writes a value, which is cast to a 32-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH32_LE(filen, data)  { \
				uint32_t d=data; \
				WRITEH32DIRECT_LE(filen, d); \
			}

					// write 2-bytes in big endian
					/*! \brief writes a 16-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH16DIRECT_LE(filen, data)    { \
				*((uint16_t*)(&filen->lastHeader[filen->pos]))=data; \
				filen->pos+=2; \
			}

					/*! \brief writes a value, which is cast to a 16-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH16_LE(filen, data)    { \
				uint16_t d=data; \
				WRITEH16DIRECT_LE(filen, d); \
			}


					// write byte
					/*! \brief writes an 8-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH8(filen, data) { filen->lastHeader[filen->pos]=data; filen->pos+=1; }
					/*! \brief writes an 8-bit word at the current position into the current file header and advances the position by 4 bytes
					\ingroup tinytiffwriter
					\internal
					*/
			#define WRITEH8DIRECT(filen, data) { filen->lastHeader[filen->pos]=data; filen->pos+=1; }

					// write 2 bytes
			#define WRITEH16(filen, data)  WRITEH16_LE(filen, data)
			#define WRITEH32(filen, data)  WRITEH32_LE(filen, data)

			#define WRITEH16DIRECT(filen, data)  WRITEH16DIRECT_LE(filen, data)
			#define WRITEH32DIRECT(filen, data)  WRITEH32DIRECT_LE(filen, data)

					/*! \brief starts a new IFD (TIFF frame header)
					\ingroup tinytiffwriter
					\internal
					*/
					inline void TinyTIFFWriter_startIFD(TinyTIFFFile* tiff, int hsize = TIFF_HEADER_SIZE) {
						if (!tiff) return;
						tiff->lastStartPos = TinyTIFFWriter_ftell(tiff);//ftell(tiff->file);
																		//tiff->lastIFDEndAdress=startPos+2+TIFF_HEADER_SIZE;
						tiff->lastIFDDATAAdress = 2 + TIFF_HEADER_MAX_ENTRIES * 12;
						tiff->lastIFDCount = 0;
						if (tiff->lastHeader && hsize != tiff->lastHeaderSize) {
							free(tiff->lastHeader);
							tiff->lastHeader = NULL;
							tiff->lastHeaderSize = 0;
						}
						if (!tiff->lastHeader) {
							tiff->lastHeader = (uint8_t*)calloc(hsize + 2, 1);
							tiff->lastHeaderSize = hsize;
						}
						else {
							memset(tiff->lastHeader, 0, hsize + 2);
						}
						tiff->pos = 2;
					}

					/*! \brief ends the current IFD (TIFF frame header) and writes the header (as a single block of size TIFF_HEADER_SIZE) into the file
					\ingroup tinytiffwriter
					\internal

					This function also sets the pointer to the next IFD, based on the known header size and frame data size.
					*/
					inline void TinyTIFFWriter_endIFD(TinyTIFFFile* tiff, int hsize = TIFF_HEADER_SIZE) {
						if (!tiff) return;
						//long startPos=ftell(tiff->file);

						tiff->pos = 0;
						WRITEH16DIRECT(tiff, tiff->lastIFDCount);

						tiff->pos = 2 + tiff->lastIFDCount * 12; // header start (2byte) + 12 bytes per IFD entry
						WRITEH32(tiff, tiff->lastStartPos + 2 + hsize + tiff->width*tiff->height*(tiff->bitspersample / 8));
						//printf("imagesize = %d\n", tiff->width*tiff->height*(tiff->bitspersample/8));

						//fwrite((void*)tiff->lastHeader, TIFF_HEADER_SIZE+2, 1, tiff->file);
						TinyTIFFWriter_fwrite((void*)tiff->lastHeader, tiff->lastHeaderSize + 2, 1, tiff);
						tiff->lastIFDOffsetField = tiff->lastStartPos + 2 + tiff->lastIFDCount * 12;
						//free(tiff->lastHeader);
						//tiff->lastHeader=NULL;
					}

					/*! \brief write an arbitrary IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntry(TinyTIFFFile* tiff, uint16_t tag, uint16_t type, uint32_t count, uint32_t data) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16DIRECT(tiff, type);
							WRITEH32DIRECT(tiff, count);
							WRITEH32DIRECT(tiff, data);
						}
					}

					/*! \brief write an 8-bit word IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntryBYTE(TinyTIFFFile* tiff, uint16_t tag, uint8_t data) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_BYTE);
							WRITEH32(tiff, 1);
							WRITEH8DIRECT(tiff, data);
							WRITEH8(tiff, 0);
							WRITEH16(tiff, 0);
						}
					}

					/*! \brief write an 16-bit word IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					void TinyTIFFWriter_writeIFDEntrySHORT(TinyTIFFFile* tiff, uint16_t tag, uint16_t data) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_SHORT);
							WRITEH32(tiff, 1);
							WRITEH16DIRECT(tiff, data);
							WRITEH16(tiff, 0);
						}
					}

					/*! \brief write an 32-bit word IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntryLONG(TinyTIFFFile* tiff, uint16_t tag, uint32_t data) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_LONG);
							WRITEH32(tiff, 1);
							WRITEH32DIRECT(tiff, data);
						}
					}

					/*! \brief write an array of 32-bit words as IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntryLONGARRAY(TinyTIFFFile* tiff, uint16_t tag, uint32_t* data, uint32_t N) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_LONG);
							WRITEH32(tiff, N);
							if (N == 1) {
								WRITEH32DIRECT(tiff, *data);
							}
							else {
								WRITEH32DIRECT(tiff, tiff->lastIFDDATAAdress + tiff->lastStartPos);
								int pos = tiff->pos;
								tiff->pos = tiff->lastIFDDATAAdress;
								for (uint32_t i = 0; i < N; i++) {
									WRITEH32DIRECT(tiff, data[i]);
								}
								tiff->lastIFDDATAAdress = tiff->pos;
								tiff->pos = pos;
							}
						}
					}

					/*! \brief write an array of 16-bit words as IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntrySHORTARRAY(TinyTIFFFile* tiff, uint16_t tag, uint16_t* data, uint32_t N) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_SHORT);
							WRITEH32(tiff, N);
							if (N == 1) {
								WRITEH32DIRECT(tiff, *data);
							}
							else {
								WRITEH32DIRECT(tiff, tiff->lastIFDDATAAdress + tiff->lastStartPos);
								int pos = tiff->pos;
								tiff->pos = tiff->lastIFDDATAAdress;
								for (uint32_t i = 0; i < N; i++) {
									WRITEH16DIRECT(tiff, data[i]);
								}
								tiff->lastIFDDATAAdress = tiff->pos;
								tiff->pos = pos;
							}


						}
					}

					/*! \brief write an array of characters (ASCII TEXT) as IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntryASCIIARRAY(TinyTIFFFile* tiff, uint16_t tag, char* data, uint32_t N, int* datapos = NULL, int* sizepos = NULL) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_ASCII);
							if (sizepos) *sizepos = tiff->pos;
							WRITEH32(tiff, N);
							if (N < 4) {
								if (datapos) *datapos = tiff->pos;
								for (uint32_t i = 0; i < 4; i++) {
									if (i < N) {
										WRITEH8DIRECT(tiff, data[i]);
									}
									else {
										WRITEH8DIRECT(tiff, 0);
									}
								}
							}
							else {
								WRITEH32DIRECT(tiff, tiff->lastIFDDATAAdress + tiff->lastStartPos);
								int pos = tiff->pos;
								tiff->pos = tiff->lastIFDDATAAdress;
								if (datapos) *datapos = tiff->pos;
								for (uint32_t i = 0; i < N; i++) {
									WRITEH8DIRECT(tiff, data[i]);
								}
								tiff->lastIFDDATAAdress = tiff->pos;
								tiff->pos = pos;
							}


						}
					}

					/*! \brief write a rational number as IFD entry
					\ingroup tinytiffwriter
					\internal

					\note This function writes into TinyTIFFFile::lastHeader, starting at the position TinyTIFFFile::pos
					*/
					inline void TinyTIFFWriter_writeIFDEntryRATIONAL(TinyTIFFFile* tiff, uint16_t tag, uint32_t numerator, uint32_t denominator) {
						if (!tiff) return;
						if (tiff->lastIFDCount < TIFF_HEADER_MAX_ENTRIES) {
							tiff->lastIFDCount++;
							WRITEH16DIRECT(tiff, tag);
							WRITEH16(tiff, TIFF_TYPE_RATIONAL);
							WRITEH32(tiff, 1);
							WRITEH32DIRECT(tiff, tiff->lastIFDDATAAdress + tiff->lastStartPos);
							//printf("1 - %lx\n", tiff->pos);
							int pos = tiff->pos;
							tiff->pos = tiff->lastIFDDATAAdress;
							//printf("2 - %lx\n", tiff->pos);
							WRITEH32DIRECT(tiff, numerator);
							//printf("3 - %lx\n", tiff->pos);
							WRITEH32DIRECT(tiff, denominator);
							tiff->lastIFDDATAAdress = tiff->pos;
							tiff->pos = pos;
							//printf("4 - %lx\n", tiff->pos);
						}
					}



					TinyTIFFFile* TinyTIFFWriter_open(const char* filename, uint16_t bitsPerSample, uint32_t width, uint32_t height) {
						TinyTIFFFile* tiff = (TinyTIFFFile*)malloc(sizeof(TinyTIFFFile));

						//tiff->file=fopen(filename, "wb");
						TinyTIFFWriter_fopen(tiff, filename);
						tiff->width = width;
						tiff->height = height;
						tiff->bitspersample = bitsPerSample;
						tiff->lastHeader = NULL;
						tiff->lastHeaderSize = 0;
						tiff->byteorder = TIFF_get_byteorder();
						tiff->frames = 0;

						if (TinyTIFFWriter_fOK(tiff)) {
							if (TIFF_get_byteorder() == TIFF_ORDER_BIGENDIAN) {
								WRITE8DIRECT(tiff, 'M');   // write TIFF header for big-endian
								WRITE8DIRECT(tiff, 'M');
							}
							else {
								WRITE8DIRECT(tiff, 'I');   // write TIFF header for little-endian
								WRITE8DIRECT(tiff, 'I');
							}
							WRITE16DIRECT_CAST(tiff, 42);
							tiff->lastIFDOffsetField = TinyTIFFWriter_ftell(tiff);//ftell(tiff->file);
							WRITE32DIRECT_CAST(tiff, 8);      // now write offset to first IFD, which is simply 8 here (in little-endian order)
							return tiff;
						}
						else {
							free(tiff);
							return NULL;
						}
					}
			#ifdef TINYTIFF_WRITE_COMMENTS
					void TinyTIFFWriter_close(TinyTIFFFile* tiff, char* imageDescription) {
			#else
					void TinyTIFFWriter_close(TinyTIFFFile* tiff, char* /*imageDescription*/) {
			#endif
						if (tiff) {
							TinyTIFFWriter_fseek_set(tiff, tiff->lastIFDOffsetField);
							WRITE32DIRECT_CAST(tiff, 0);
			#ifdef TINYTIFF_WRITE_COMMENTS
							if (tiff->descriptionOffset > 0) {
								size_t dlen;
								char description[TINYTIFFWRITER_DESCRIPTION_SIZE + 1];

								if (imageDescription) {
									strcpy(description, imageDescription);
								}
								else {
									for (int i = 0; i < TINYTIFFWRITER_DESCRIPTION_SIZE + 1; i++) description[i] = '\0';
									sprintf(description, "TinyTIFFWriter_version=1.1\nimages=%ld", tiff->frames);
								}
								description[TINYTIFFWRITER_DESCRIPTION_SIZE - 1] = '\0';
								dlen = strlen(description);
								printf("WRITING COMMENT\n***");
								printf(description);
								printf("***\nlen=%ld\n\n", dlen);
								TinyTIFFWriter_fseek_set(tiff, tiff->descriptionOffset);
								TinyTIFFWriter_fwrite(description, 1, dlen + 1, tiff);//<<" / "<<dlen<<"\n";
								TinyTIFFWriter_fseek_set(tiff, tiff->descriptionSizeOffset);
								WRITE32DIRECT_CAST(tiff, (dlen + 1));
							}
			#endif // TINYTIFF_WRITE_COMMENTS
							TinyTIFFWriter_fclose(tiff);
							free(tiff->lastHeader);
							free(tiff);
						}
					}

					void TinyTIFFWriter_close(TinyTIFFFile* tiff, double pixel_width, double pixel_height, double frametime=1, double deltaz=1) {
						if (tiff) {
							char description[TINYTIFFWRITER_DESCRIPTION_SIZE + 1];
							for (int i = 0; i < TINYTIFFWRITER_DESCRIPTION_SIZE + 1; i++) description[i] = '\0';
							char spw[256];
							sprintf_s(description, "TinyTIFFWriter_version=1.1\nimages=%lu", (unsigned long int)tiff->frames);
							if (fabs(pixel_width) > 10.0*DBL_MIN) {
								sprintf_s(spw, "\npixel_width=%lf ", pixel_width);
								strcat_s(description, spw);
							}
							if (fabs(pixel_height) > 10.0*DBL_MIN) {
								sprintf_s(spw, "\npixel_height=%lf ", pixel_height);
								strcat_s(description, spw);
							}
							if (fabs(deltaz) > 10.0*DBL_MIN) {
								sprintf_s(spw, "\ndeltaz=%lf ", deltaz);
								strcat_s(description, spw);
							}
							if (fabs(frametime) > 10.0*DBL_MIN) {
								sprintf_s(spw, "\nframetime=%lg ", frametime);
								strcat_s(description, spw);
							}
							description[TINYTIFFWRITER_DESCRIPTION_SIZE - 1] = '\0';
							TinyTIFFWriter_close(tiff, description);
						}
					}

			#define TINTIFFWRITER_WRITEImageDescriptionTemplate(tiff) \
				if (tiff->frames<=0) {\
					int datapos=0;\
					int sizepos=0;\
					char description[TINYTIFFWRITER_DESCRIPTION_SIZE+1];\
					for (int i=0; i<TINYTIFFWRITER_DESCRIPTION_SIZE+1; i++) description[i]='\0';\
					sprintf(description, "TinyTIFFWriter_version=1.1\n");\
					description[TINYTIFFWRITER_DESCRIPTION_SIZE]='\0';\
					TinyTIFFWriter_writeIFDEntryASCIIARRAY(tiff, TIFF_FIELD_IMAGEDESCRIPTION, description, TINYTIFFWRITER_DESCRIPTION_SIZE, &datapos, &sizepos);\
					tiff->descriptionOffset=tiff->lastStartPos+datapos;\
					tiff->descriptionSizeOffset=tiff->lastStartPos+sizepos;\
				 }



					template <typename vectortype>
					void TinyTIFFWriter_writeImage(TinyTIFFFile* tiff, vectortype* data) {
						
						if (!tiff) {
							::std::cout << "Error: file is not open\n";
							return;
						}
						long pos = ftell(tiff->file);
						int hsize = TIFF_HEADER_SIZE;
			#ifdef TINYTIFF_WRITE_COMMENTS
						if (tiff->frames <= 0) {
							hsize = TIFF_HEADER_SIZE + TINYTIFFWRITER_DESCRIPTION_SIZE + 16;
						}
			#endif // TINYTIFF_WRITE_COMMENTS
						TinyTIFFWriter_startIFD(tiff, hsize);
						TinyTIFFWriter_writeIFDEntryLONG(tiff, TIFF_FIELD_IMAGEWIDTH, tiff->width);
						TinyTIFFWriter_writeIFDEntryLONG(tiff, TIFF_FIELD_IMAGELENGTH, tiff->height);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_BITSPERSAMPLE, tiff->bitspersample);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_COMPRESSION, 1);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_PHOTOMETRICINTERPRETATION, 1);
			#ifdef TINYTIFF_WRITE_COMMENTS
						TINTIFFWRITER_WRITEImageDescriptionTemplate(tiff);
			#endif // TINYTIFF_WRITE_COMMENTS
						TinyTIFFWriter_writeIFDEntryLONG(tiff, TIFF_FIELD_STRIPOFFSETS, pos + 2 + hsize);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_SAMPLESPERPIXEL, 1);
						TinyTIFFWriter_writeIFDEntryLONG(tiff, TIFF_FIELD_ROWSPERSTRIP, tiff->height);
						TinyTIFFWriter_writeIFDEntryLONG(tiff, TIFF_FIELD_STRIPBYTECOUNTS, tiff->width*tiff->height*(tiff->bitspersample / 8));
						TinyTIFFWriter_writeIFDEntryRATIONAL(tiff, TIFF_FIELD_XRESOLUTION, 1, 1);
						TinyTIFFWriter_writeIFDEntryRATIONAL(tiff, TIFF_FIELD_YRESOLUTION, 1, 1);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_PLANARCONFIG, 1);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_RESOLUTIONUNIT, 1);
						TinyTIFFWriter_writeIFDEntrySHORT(tiff, TIFF_FIELD_SAMPLEFORMAT, 1);
						TinyTIFFWriter_endIFD(tiff);
						TinyTIFFWriter_fwrite(data, tiff->width*tiff->height*(tiff->bitspersample / 8), 1, tiff);
						tiff->frames = tiff->frames + 1;



		};
		TinyTIFFFile* tif;
		::std::vector<uint8_t> data8b;
		::std::vector<uint16_t> data16b;
		::std::vector<uint32_t> data32b;
		public:
			
			int depth = 0, numofpixels = 0, width = 0, height = 0;

		TiffOutput() {};

		TiffOutput(::std::string filename,int depthin,int widthin,int heightin){
			depth = depthin;
			width = widthin;
			height = heightin;
			numofpixels = width*height;

			tif = TinyTIFFWriter_open(filename.c_str(), depth, width, height);

			if (depth == 8)data8b.resize(width*height);
			else if (depth == 16)data16b.resize(width*height);
			else if (depth == 32)data32b.resize(width*height);
		};

		template <typename vectortype>
		void Write1DImage(::std::vector<vectortype> datain) {
			if (depth == 8) {
				for (int i = 0; i < numofpixels; i++)data8b[i] = (uint8_t)datain[i];
				TinyTIFFWriter_writeImage(tif, data8b.data());
			}
			else if (depth == 16) {
				for (int i = 0; i < numofpixels; i++)data16b[i] = (uint16_t)datain[i];
				TinyTIFFWriter_writeImage(tif, data16b.data());
			}
			else if (depth == 32) {
				for (int i = 0; i < numofpixels; i++)data32b[i] = (uint32_t)datain[i];
				TinyTIFFWriter_writeImage(tif, data32b.data());
			}
		}

		template <typename vectortype>
		void Write2DImage(::std::vector<::std::vector<vectortype>> datain) {
			if (depth == 8) {
				for (int i = 0; i < numofpixels; i++)data8b[i] = (uint8_t)datain[i%width][(int)(i / width)];
				TinyTIFFWriter_writeImage(tif, data8b.data());
			}
			else if (depth == 16) {
				for (int i = 0; i < numofpixels; i++)data16b[i] = (uint16_t)datain[i%width][(int)(i / width)];
				TinyTIFFWriter_writeImage(tif, data16b.data());
			}
			else if (depth == 32) {
				for (int i = 0; i < numofpixels; i++)data32b[i] = (uint32_t)datain[i%width][(int)(i / width)];
				TinyTIFFWriter_writeImage(tif, data32b.data());
			}
		}

		~TiffOutput() {
			TinyTIFFWriter_close(tif,width,height);
		}

	};

}



#endif






