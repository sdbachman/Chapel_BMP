use bitmap;


proc main(args : [] string) {

  var infile = args[1];
  var outfile = args[2];

  var pixels = readImageBMP(infile);
  var pixels_gray = convert_to_grayscale(pixels);
  writeImageBMP(outfile, pixels_gray);
  
}
