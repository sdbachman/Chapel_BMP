use bitmap;
use Time;

proc main(args : [] string) {

  var t : Timer;
  t.start();

  var infile = args[1];

  var pixels = readImageBMP(infile);

  t.stop();
  writeln("Elapsed time to load image: ", t.elapsed(), " seconds.");   

}
