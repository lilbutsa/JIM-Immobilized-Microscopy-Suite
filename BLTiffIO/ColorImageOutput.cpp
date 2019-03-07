#include "stdafx.h"
#include "BLTiffIO.h"
#include <algorithm>


void BLTiffIO::WriteSinglePage2DColor(std::vector<std::vector<std::vector<uint8>>>& imagein, std::string filename)
{

	std::string outputstr = filename;

	TIFF* output_tiff = TIFFOpen(outputstr.c_str(), "w");

	int height = imagein[0].size();
	int width = imagein.size();
	int totframes = 0;


	tdata_t firstpagebuffer = _TIFFmalloc(3 * sizeof(uint8)*width);




	//TIFFSetField(output_tiff, TIFFTAG_XRESOLUTION, 72.0);
	//TIFFSetField(output_tiff, TIFFTAG_YRESOLUTION, 72.0);



	for (int page = 0; page < 1; page++) {

		TIFFSetField(output_tiff, TIFFTAG_IMAGELENGTH, height);
		TIFFSetField(output_tiff, TIFFTAG_IMAGEWIDTH, width);


		TIFFSetField(output_tiff, TIFFTAG_SAMPLESPERPIXEL, 3);
		TIFFSetField(output_tiff, TIFFTAG_BITSPERSAMPLE, 8);
		TIFFSetField(output_tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
		TIFFSetField(output_tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
		TIFFSetField(output_tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
		TIFFSetField(output_tiff, TIFFTAG_ROWSPERSTRIP, TIFFDefaultStripSize(output_tiff, 0));
		TIFFSetField(output_tiff, TIFFTAG_RESOLUTIONUNIT, 2);

		TIFFSetField(output_tiff, TIFFTAG_SUBFILETYPE, FILETYPE_PAGE);
		TIFFSetField(output_tiff, TIFFTAG_PAGENUMBER, page, totframes);

		TIFFSetDirectory(output_tiff, page);
		//for (int i = 0; i < width; i++)((uint16*)firstpagebuffer)[i] = 10 * i*page;

		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++) {
				((uint8*)firstpagebuffer)[3 * i] = imagein[i][j][0];
				((uint8*)firstpagebuffer)[3 * i + 1] = imagein[i][j][1];
				((uint8*)firstpagebuffer)[3 * i + 2] = imagein[i][j][2];
			}
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}

		TIFFWriteDirectory(output_tiff);

	}
	_TIFFfree(firstpagebuffer);
	TIFFClose(output_tiff);

}