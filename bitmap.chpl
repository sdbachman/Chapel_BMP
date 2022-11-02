module bitmap {

// Allow access to stderr, stdout, iomode
private use IO;

//
// Define config-dependent types and params.
//
private config param bitsPerColor = 8;

private param colorMask = (0x1 << bitsPerColor) - 1;

//
// set helper params for colors
//
private param red = 0,        // names for referring to colors
      green = 1,
      blue = 2,
      numColors = 3;

//
// how far to shift a color component when writing the BMP
//
inline proc colorOffset(param color) param {
  return color * bitsPerColor;
}

//
// Read an image from an input BMP file
//
proc readImageBMP(image) throws {
  
  const infile = open(image, iomode.r).reader();
  //var headerSize = 14, dibHeaderSize = 40;

  var zero16, colorPlanes, bitsPerPixel : uint(16);
  var zero32, size, offsetToPixelData, compression : uint(32);
  var dibHeaderSize, pixelsSize, pixelsPerMeter : uint(32);
  var cols, rows : int(32);
 
  infile.readf("BM");
  infile.readBinary(size, ioendian.little);
  infile.readBinary(zero16, ioendian.little);
  infile.readBinary(zero16, ioendian.little);
  infile.readBinary(offsetToPixelData, ioendian.little);

  // Read the DIB header BITMAPINFOHEADER
  infile.readBinary(dibHeaderSize, ioendian.little);
  infile.readBinary(cols, ioendian.little);
  infile.readBinary(rows, ioendian.little); /*neg for swap*/
  rows = -rows;
  infile.readBinary(colorPlanes, ioendian.little); /* 1 color plane */
  infile.readBinary(bitsPerPixel, ioendian.little);
  infile.readBinary(compression, ioendian.little); /* no compression */
  infile.readBinary(pixelsSize, ioendian.little);
  infile.readBinary(pixelsPerMeter, ioendian.little); /*pixels/meter print resolution=72dpi*/
  infile.readBinary(pixelsPerMeter, ioendian.little); /*pixels/meter print resolution=72dpi*/
  infile.readBinary(zero32, ioendian.little); /* colors in palette */
  infile.readBinary(zero32, ioendian.little); /* "important" colors */

  var pixels: [1..rows, 1..cols] int;

  for i in pixels.domain.dim(0) {
    var nbits = 0;
    for j in pixels.domain.dim(1) {
      infile.readbits(pixels[i,j],3*bitsPerColor);
    }
  }  

  return pixels;
}

//
// Convert an image to grayscale
//

proc convert_to_grayscale(pixels) {

  var pixels_gray = pixels;
  var gray : int;

  for i in pixels.domain.dim(0) {
    for j in pixels.domain.dim(1) {
      var p = pixels[i,j];
      var redv = (p >> colorOffset(red)) & colorMask;
      var greenv = (p >> colorOffset(green)) & colorMask;
      var bluev = (p >> colorOffset(blue)) & colorMask;
      
      gray = ((redv + greenv + bluev) / 3.0) : int; 
      pixels_gray[i,j] = gray << (2*bitsPerColor) | gray << (bitsPerColor) | gray;
    }
  }

  return pixels_gray;
}  

//
// write the image as a BMP file
//
proc writeImageBMP(image, pixels) throws {

  const outfile = open(image, iomode.cw).writer();

  const rows = pixels.domain.dim(0).size,
        cols = pixels.domain.dim(1).size,

        headerSize = 14,
        dibHeaderSize = 40,  // always use old BITMAPINFOHEADER
        bitsPerPixel = numColors*bitsPerColor,

        // row size in bytes. Pad each row out to 4 bytes.
        rowQuads = divceil(bitsPerPixel * cols, 32),
        rowSize = 4 * rowQuads,
        rowSizeBits = 8 * rowSize,

        pixelsSize = rowSize * rows,
        size = headerSize + dibHeaderSize + pixelsSize,

        offsetToPixelData = headerSize + dibHeaderSize;

  // Write the BMP image header
  outfile.writef("BM");
  outfile.writeBinary(size:uint(32), ioendian.little);
  outfile.writeBinary(0:uint(16), ioendian.little); /* reserved1 */
  outfile.writeBinary(0:uint(16), ioendian.little); /* reserved2 */
  outfile.writeBinary(offsetToPixelData:uint(32), ioendian.little);

  // Write the DIB header BITMAPINFOHEADER
  outfile.writeBinary(dibHeaderSize:uint(32), ioendian.little);
  outfile.writeBinary(cols:int(32), ioendian.little);
  outfile.writeBinary(-rows:int(32), ioendian.little); /*neg for swap*/
  outfile.writeBinary(1:uint(16), ioendian.little); /* 1 color plane */
  outfile.writeBinary(bitsPerPixel:uint(16), ioendian.little);
  outfile.writeBinary(0:uint(32), ioendian.little); /* no compression */
  outfile.writeBinary(pixelsSize:uint(32), ioendian.little);
  outfile.writeBinary(2835:uint(32), ioendian.little); /*pixels/meter print resolution=72dpi*/
  outfile.writeBinary(2835:uint(32), ioendian.little); /*pixels/meter print resolution=72dpi*/
  outfile.writeBinary(0:uint(32), ioendian.little); /* colors in palette */
  outfile.writeBinary(0:uint(32), ioendian.little); /* "important" colors */

  for i in pixels.domain.dim(0) {
    var nbits = 0;
    for j in pixels.domain.dim(1) {
      var p = pixels[i,j];
      var redv = (p >> colorOffset(red)) & colorMask;
      var greenv = (p >> colorOffset(green)) & colorMask;
      var bluev = (p >> colorOffset(blue)) & colorMask;

      // write 24-bit color value
      outfile.writebits(bluev, bitsPerColor);
      outfile.writebits(greenv, bitsPerColor);
      outfile.writebits(redv, bitsPerColor);
      nbits += numColors * bitsPerColor;
    }
    // write the padding.
    // The padding is only rounding up to 4 bytes so
    // can be written in a single writebits call.
    outfile.writebits(0:uint, (rowSizeBits-nbits):int(8));
  }
}

} /* module bitmap */
